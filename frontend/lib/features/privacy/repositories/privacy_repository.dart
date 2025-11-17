import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/consent.dart';
import '../../../core/services/supabase_service.dart';

class PrivacyRepository {
  final SupabaseClient _supabase = SupabaseService.client;

  // Get user privacy settings
  Future<PrivacySettings> getUserPrivacySettings(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('''
            is_invisible,
            hide_age,
            hide_level, 
            hide_stats,
            hide_last_active,
            notifications_push,
            notifications_email,
            notifications_marketing
          ''')
          .eq('id', userId)
          .single();

      return PrivacySettings.fromJson({
        'is_invisible': response['is_invisible'] ?? false,
        'hide_age': response['hide_age'] ?? false,
        'hide_level': response['hide_level'] ?? false,
        'hide_stats': response['hide_stats'] ?? false,
        'hide_last_active': response['hide_last_active'] ?? false,
        'notifications_push': response['notifications_push'] ?? true,
        'notifications_email': response['notifications_email'] ?? true,
        'notifications_marketing': response['notifications_marketing'] ?? false,
      });
    } catch (e) {
      throw Exception('Failed to get privacy settings: $e');
    }
  }

  // Update privacy settings
  Future<void> updatePrivacySettings(String userId, PrivacySettings settings) async {
    try {
      final response = await _supabase.functions.invoke(
        'manage-privacy-settings',
        body: {
          'user_id': userId,
          'settings': settings.toMap(),
        },
      );

      if (response.error != null) {
        throw Exception('Failed to update privacy settings: ${response.error}');
      }
    } catch (e) {
      throw Exception('Failed to update privacy settings: $e');
    }
  }

  // Grant consent
  Future<Consent> grantConsent({
    required String userId,
    required String purpose,
    int version = 1,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'manage-consent',
        body: {
          'user_id': userId,
          'action': 'grant',
          'purpose': purpose,
          'version': version,
          'ip_address': ipAddress,
          'user_agent': userAgent,
        },
      );

      if (response.error != null) {
        throw Exception('Failed to grant consent: ${response.error}');
      }

      // Fetch the created consent
      return await getConsent(userId, purpose);
    } catch (e) {
      throw Exception('Failed to grant consent: $e');
    }
  }

  // Revoke consent
  Future<void> revokeConsent({
    required String userId,
    required String purpose,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'manage-consent',
        body: {
          'user_id': userId,
          'action': 'revoke',
          'purpose': purpose,
          'ip_address': ipAddress,
          'user_agent': userAgent,
        },
      );

      if (response.error != null) {
        throw Exception('Failed to revoke consent: ${response.error}');
      }
    } catch (e) {
      throw Exception('Failed to revoke consent: $e');
    }
  }

  // Check specific consent
  Future<bool> checkConsent(String userId, String purpose) async {
    try {
      final response = await _supabase.functions.invoke(
        'manage-consent',
        body: {
          'user_id': userId,
          'action': 'check',
          'purpose': purpose,
        },
      );

      if (response.error != null) {
        throw Exception('Failed to check consent: ${response.error}');
      }

      return response.data['has_consent'] as bool? ?? false;
    } catch (e) {
      return false; // Default to no consent on error
    }
  }

  // Get specific consent details
  Future<Consent> getConsent(String userId, String purpose) async {
    try {
      final response = await _supabase
          .from('consents')
          .select('*')
          .eq('user_id', userId)
          .eq('purpose', purpose)
          .order('version', ascending: false)
          .limit(1)
          .single();

      return Consent.fromJson({
        ...response,
        'granted_at': response['granted_at'],
        'revoked_at': response['revoked_at'],
        'created_at': response['created_at'],
        'updated_at': response['updated_at'],
      });
    } catch (e) {
      throw Exception('Failed to get consent: $e');
    }
  }

  // List all user consents
  Future<List<Consent>> getUserConsents(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'manage-consent',
        body: {
          'user_id': userId,
          'action': 'list',
        },
      );

      if (response.error != null) {
        throw Exception('Failed to list consents: ${response.error}');
      }

      final consentsData = response.data['consents'] as List;
      return consentsData.map((json) => Consent.fromJson({
        ...json,
        'granted_at': json['granted_at'],
        'revoked_at': json['revoked_at'],
        'created_at': json['created_at'],
        'updated_at': json['updated_at'],
      })).toList();
    } catch (e) {
      throw Exception('Failed to list consents: $e');
    }
  }

  // Submit video verification
  Future<VerificationRequest> submitVideoVerification({
    required String userId,
    required String videoPath,
    int? durationSeconds,
    int? sizeBytes,
  }) async {
    try {
      final response = await _supabase
          .from('verification_requests')
          .insert({
            'user_id': userId,
            'video_storage_path': videoPath,
            'video_duration_seconds': durationSeconds,
            'video_size_bytes': sizeBytes,
            'status': 'pending',
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return VerificationRequest.fromJson({
        ...response,
        'submitted_at': response['submitted_at'],
        'reviewed_at': response['reviewed_at'],
        'created_at': response['created_at'],
        'updated_at': response['updated_at'],
      });
    } catch (e) {
      throw Exception('Failed to submit verification: $e');
    }
  }

  // Get verification requests for user
  Future<List<VerificationRequest>> getUserVerificationRequests(String userId) async {
    try {
      final response = await _supabase
          .from('verification_requests')
          .select('*')
          .eq('user_id', userId)
          .order('submitted_at', ascending: false);

      return response.map((json) => VerificationRequest.fromJson({
        ...json,
        'submitted_at': json['submitted_at'],
        'reviewed_at': json['reviewed_at'],
        'created_at': json['created_at'],
        'updated_at': json['updated_at'],
      })).toList();
    } catch (e) {
      throw Exception('Failed to get verification requests: $e');
    }
  }

  // Get latest verification request
  Future<VerificationRequest?> getLatestVerificationRequest(String userId) async {
    try {
      final response = await _supabase
          .from('verification_requests')
          .select('*')
          .eq('user_id', userId)
          .order('submitted_at', ascending: false)
          .limit(1)
          .single();

      return VerificationRequest.fromJson({
        ...response,
        'submitted_at': response['submitted_at'],
        'reviewed_at': response['reviewed_at'],
        'created_at': response['created_at'],
        'updated_at': response['updated_at'],
      });
    } catch (e) {
      return null; // No verification request found
    }
  }

  // Request AI icebreaker
  Future<String> getAIIcebreaker({
    required String userId,
    required String matchId,
    String contextType = 'first_message',
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'ai-icebreaker',
        body: {
          'user_id': userId,
          'match_id': matchId,
          'context_type': contextType,
        },
      );

      if (response.error != null) {
        throw Exception('Failed to get icebreaker: ${response.error}');
      }

      return response.data['suggestion'] as String;
    } catch (e) {
      throw Exception('Failed to get AI icebreaker: $e');
    }
  }

  // Mark AI suggestion as used
  Future<void> markAIInteractionUsed(String interactionId) async {
    try {
      await _supabase
          .from('ai_interactions')
          .update({
            'was_used': true,
            'used_at': DateTime.now().toIso8601String(),
          })
          .eq('id', interactionId);
    } catch (e) {
      // Don't throw - this is analytics only
      print('Failed to mark AI interaction as used: $e');
    }
  }

  // Rate AI interaction
  Future<void> rateAIInteraction({
    required String interactionId,
    required int rating,
    String? feedback,
  }) async {
    try {
      await _supabase
          .from('ai_interactions')
          .update({
            'user_rating': rating,
            'feedback_text': feedback,
          })
          .eq('id', interactionId);
    } catch (e) {
      throw Exception('Failed to rate AI interaction: $e');
    }
  }

  // Get AI interaction history
  Future<List<AIInteraction>> getAIInteractionHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('ai_interactions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => AIInteraction.fromJson({
        ...json,
        'used_at': json['used_at'],
        'created_at': json['created_at'],
      })).toList();
    } catch (e) {
      throw Exception('Failed to get AI history: $e');
    }
  }

  // Stream privacy settings changes
  Stream<PrivacySettings> watchPrivacySettings(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) {
            return const PrivacySettings(
              isInvisible: false,
              hideAge: false,
              hideLevel: false,
              hideStats: false,
              hideLastActive: false,
              notificationsPush: true,
              notificationsEmail: true,
              notificationsMarketing: false,
            );
          }
          
          final user = data.first;
          return PrivacySettings.fromJson({
            'is_invisible': user['is_invisible'] ?? false,
            'hide_age': user['hide_age'] ?? false,
            'hide_level': user['hide_level'] ?? false,
            'hide_stats': user['hide_stats'] ?? false,
            'hide_last_active': user['hide_last_active'] ?? false,
            'notifications_push': user['notifications_push'] ?? true,
            'notifications_email': user['notifications_email'] ?? true,
            'notifications_marketing': user['notifications_marketing'] ?? false,
          });
        });
  }

  // Stream verification status
  Stream<VerificationRequest?> watchVerificationStatus(String userId) {
    return _supabase
        .from('verification_requests')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('submitted_at', ascending: false)
        .limit(1)
        .map((data) {
          if (data.isEmpty) return null;
          
          return VerificationRequest.fromJson({
            ...data.first,
            'submitted_at': data.first['submitted_at'],
            'reviewed_at': data.first['reviewed_at'],
            'created_at': data.first['created_at'],
            'updated_at': data.first['updated_at'],
          });
        });
  }
}
