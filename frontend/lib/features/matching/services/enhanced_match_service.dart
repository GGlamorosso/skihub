import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../premium/services/quota_manager.dart';
import '../../premium/models/subscription.dart';
import '../../../core/services/supabase_service.dart';

class EnhancedMatchService {
  final SupabaseClient _supabase = SupabaseService.client;

  // Enhanced swipe with quota checking
  Future<SwipeResult> swipeWithQuota({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required String targetUserId,
    required bool isLike,
  }) async {
    try {
      // Check quota first
      if (isLike) {
        final canSwipe = await QuotaManager.checkSwipeQuota(
          context: context,
          ref: ref,
          userId: userId,
          targetUserId: targetUserId,
        );

        if (!canSwipe) {
          return SwipeResult(
            success: false,
            quotaLimited: true,
            message: 'Limite de swipes quotidiens atteinte',
          );
        }
      }

      // Perform the swipe
      if (isLike) {
        final response = await _supabase.functions.invoke(
          'gatekeeper',
          body: {
            'user_id': userId,
            'action': 'swipe',
            'target_id': targetUserId,
          },
        );

        if (response.error != null) {
          throw Exception(response.error.toString());
        }

        final data = response.data;
        final quotaInfo = QuotaInfo.fromJson(data['quota_info']);
        
        // Update quota state
        ref.read(userQuotaStateProvider(userId).notifier).updateQuota(quotaInfo);

        return SwipeResult(
          success: data['success'] ?? true,
          quotaLimited: false,
          likeId: data['action_result']?['like_id'],
          quotaInfo: quotaInfo,
        );
      } else {
        // Dislike - no quota needed, just track for analytics
        return SwipeResult(success: true, quotaLimited: false);
      }
    } catch (e) {
      debugPrint('Enhanced swipe error: $e');
      return SwipeResult(
        success: false,
        quotaLimited: false,
        message: 'Erreur lors du swipe: $e',
      );
    }
  }

  // Get potential matches with premium filtering
  Future<List<Map<String, dynamic>>> getPotentialMatches({
    required String userId,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // Check if user has premium for advanced filters
      final isPremium = await _checkUserPremium(userId);
      
      String functionName = isPremium ? 'get-matches-premium' : 'get-matches-basic';
      
      final response = await _supabase.functions.invoke(
        functionName,
        body: {
          'user_id': userId,
          'limit': limit,
          'filters': filters,
        },
      );

      if (response.error != null) {
        throw Exception(response.error.toString());
      }

      return List<Map<String, dynamic>>.from(response.data['matches'] ?? []);
    } catch (e) {
      debugPrint('Error getting potential matches: $e');
      rethrow;
    }
  }

  // Get who liked me (premium feature)
  Future<List<Map<String, dynamic>>> getWhoLikedMe({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final isPremium = await _checkUserPremium(userId);
      if (!isPremium) {
        throw Exception('Premium feature - upgrade required');
      }

      final response = await _supabase
          .from('likes')
          .select('''
            *,
            liker:users!inner(id, username, level, ride_styles, languages)
          ''')
          .eq('liked_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting who liked me: $e');
      rethrow;
    }
  }

  Future<bool> _checkUserPremium(String userId) async {
    final response = await _supabase
        .from('users')
        .select('is_premium, premium_expires_at')
        .eq('id', userId)
        .single();

    final isPremium = response['is_premium'] as bool? ?? false;
    final expiresAt = response['premium_expires_at'] as String?;

    if (!isPremium) return false;
    if (expiresAt == null) return true;

    return DateTime.parse(expiresAt).isAfter(DateTime.now());
  }
}

class SwipeResult {
  final bool success;
  final bool quotaLimited;
  final String? message;
  final String? likeId;
  final QuotaInfo? quotaInfo;

  SwipeResult({
    required this.success,
    required this.quotaLimited,
    this.message,
    this.likeId,
    this.quotaInfo,
  });
}
