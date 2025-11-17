import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/moderation.dart';
import '../../privacy/repositories/privacy_repository.dart';
import '../../core/services/analytics_service.dart';

class ContentModerationService {
  final SupabaseClient _supabase = SupabaseService.client;
  final AnalyticsService _analytics = AnalyticsService();

  // Filter message before sending
  Future<ModerationResult> filterMessage({
    required String userId,
    required String content,
    required String matchId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'ai-message-filter',
        body: {
          'user_id': userId,
          'content': content,
          'match_id': matchId,
        },
      );

      if (response.error != null) {
        throw Exception('Moderation failed: ${response.error}');
      }

      final data = response.data;
      final result = ModerationResult.fromJson(data);

      _analytics.track('message_moderated', {
        'is_blocked': result.isBlocked,
        'needs_review': result.needsReview,
        'confidence_score': result.confidenceScore,
      });

      return result;
    } catch (e) {
      debugPrint('Content moderation error: $e');
      // On error, allow message
      return ModerationResult(
        isSafe: true,
        isBlocked: false,
        needsReview: false,
        confidenceScore: 0.0,
      );
    }
  }

  // Get moderated messages for user (for appeals)
  Future<List<ModeratedMessage>> getModeratedMessages(String userId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
            id,
            content,
            is_blocked,
            needs_review,
            blocked_reason,
            ai_confidence_score,
            created_at,
            match_id
          ''')
          .eq('sender_id', userId)
          .or('is_blocked.eq.true,needs_review.eq.true')
          .order('created_at', ascending: false);

      return response.map((json) => ModeratedMessage.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get moderated messages: $e');
    }
  }

  // Appeal message block
  Future<void> appealMessageBlock({
    required String messageId,
    required String userId,
    String? explanation,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'appeal-moderation',
        body: {
          'message_id': messageId,
          'user_id': userId,
          'explanation': explanation,
        },
      );

      if (response.error != null) {
        throw Exception('Appeal failed: ${response.error}');
      }

      _analytics.track('moderation_appealed', {
        'message_id': messageId,
        'has_explanation': explanation != null,
      });
    } catch (e) {
      throw Exception('Failed to appeal message block: $e');
    }
  }

  // Report user
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
    List<String>? messageIds,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'report-user',
        body: {
          'reporter_id': reporterId,
          'reported_user_id': reportedUserId,
          'reason': reason,
          'description': description,
          'message_ids': messageIds,
        },
      );

      if (response.error != null) {
        throw Exception('Report failed: ${response.error}');
      }

      _analytics.track('user_reported', {
        'reason': reason,
        'has_description': description != null,
        'message_count': messageIds?.length ?? 0,
      });
    } catch (e) {
      throw Exception('Failed to report user: $e');
    }
  }

  // Block user
  Future<void> blockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'block-user',
        body: {
          'user_id': userId,
          'blocked_user_id': blockedUserId,
        },
      );

      if (response.error != null) {
        throw Exception('Block failed: ${response.error}');
      }

      _analytics.track('user_blocked', {
        'blocked_user_id': blockedUserId,
      });
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  // Get blocked users
  Future<List<BlockedUser>> getBlockedUsers(String userId) async {
    try {
      final response = await _supabase
          .from('blocked_users')
          .select('''
            *,
            blocked_user:users!blocked_user_id(id, username)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => BlockedUser.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get blocked users: $e');
    }
  }

  // Unblock user
  Future<void> unblockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    try {
      await _supabase
          .from('blocked_users')
          .delete()
          .eq('user_id', userId)
          .eq('blocked_user_id', blockedUserId);

      _analytics.track('user_unblocked', {
        'blocked_user_id': blockedUserId,
      });
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  // Check if content needs warning
  bool shouldWarnBeforeSending(String content) {
    final lowerContent = content.toLowerCase();
    
    final warningKeywords = [
      'meet', 'rencontrer', 'voir', 'real life',
      'phone', 'number', 'téléphone', 'whatsapp',
      'instagram', 'snap', 'facebook',
    ];

    return warningKeywords.any((keyword) => lowerContent.contains(keyword));
  }

  // Get content warning message
  String getContentWarning(String content) {
    final lowerContent = content.toLowerCase();
    
    if (lowerContent.contains('meet') || lowerContent.contains('rencontrer')) {
      return 'Attention: Rencontrez toujours de nouveaux contacts dans des lieux publics.';
    }
    if (lowerContent.contains('phone') || lowerContent.contains('whatsapp')) {
      return 'Conseil: Apprenez à vous connaître ici avant d\'échanger vos coordonnées.';
    }
    if (lowerContent.contains('instagram') || lowerContent.contains('snap')) {
      return 'Info: Évitez de partager vos réseaux sociaux trop rapidement.';
    }
    
    return 'Veillez à respecter les règles de la communauté.';
  }
}

// Models for the moderation service
class ModerationResult {
  final bool isSafe;
  final bool isBlocked;
  final bool needsReview;
  final double confidenceScore;
  final String? blockedReason;
  final String? suggestedReplacement;

  ModerationResult({
    required this.isSafe,
    required this.isBlocked,
    required this.needsReview,
    required this.confidenceScore,
    this.blockedReason,
    this.suggestedReplacement,
  });

  factory ModerationResult.fromJson(Map<String, dynamic> json) {
    return ModerationResult(
      isSafe: json['is_safe'] as bool,
      isBlocked: json['is_blocked'] as bool,
      needsReview: json['needs_review'] as bool,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      blockedReason: json['blocked_reason'] as String?,
      suggestedReplacement: json['suggested_replacement'] as String?,
    );
  }
}

class ModeratedMessage {
  final String id;
  final String content;
  final bool isBlocked;
  final bool needsReview;
  final String? blockedReason;
  final double? aiConfidenceScore;
  final DateTime createdAt;
  final String matchId;

  ModeratedMessage({
    required this.id,
    required this.content,
    required this.isBlocked,
    required this.needsReview,
    this.blockedReason,
    this.aiConfidenceScore,
    required this.createdAt,
    required this.matchId,
  });

  factory ModeratedMessage.fromJson(Map<String, dynamic> json) {
    return ModeratedMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isBlocked: json['is_blocked'] as bool? ?? false,
      needsReview: json['needs_review'] as bool? ?? false,
      blockedReason: json['blocked_reason'] as String?,
      aiConfidenceScore: (json['ai_confidence_score'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      matchId: json['match_id'] as String,
    );
  }
}

class BlockedUser {
  final String id;
  final String userId;
  final String blockedUserId;
  final String? blockedUsername;
  final DateTime createdAt;

  BlockedUser({
    required this.id,
    required this.userId,
    required this.blockedUserId,
    this.blockedUsername,
    required this.createdAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      blockedUserId: json['blocked_user_id'] as String,
      blockedUsername: json['blocked_user']?['username'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
