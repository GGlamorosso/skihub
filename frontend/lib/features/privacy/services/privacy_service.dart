import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/privacy_repository.dart';
import '../models/consent.dart';
import '../../core/services/analytics_service.dart';

part 'privacy_service.g.dart';

class PrivacyService {
  final PrivacyRepository _repository;
  final AnalyticsService _analytics = AnalyticsService();

  PrivacyService(this._repository);

  // Update privacy settings
  Future<void> updatePrivacySettings(String userId, PrivacySettings settings) async {
    try {
      await _repository.updatePrivacySettings(userId, settings);
      
      // Track analytics
      _analytics.track('privacy_settings_updated', {
        'is_invisible': settings.isInvisible,
        'hide_age': settings.hideAge,
        'hide_level': settings.hideLevel,
        'hide_stats': settings.hideStats,
      });
    } catch (e) {
      debugPrint('Privacy settings update error: $e');
      rethrow;
    }
  }

  // Grant consent
  Future<void> grantConsent(String userId, String purpose, {int version = 1}) async {
    try {
      await _repository.grantConsent(
        userId: userId,
        purpose: purpose,
        version: version,
      );
      
      _analytics.track('consent_granted', {
        'purpose': purpose,
        'version': version,
      });
    } catch (e) {
      _analytics.track('consent_grant_failed', {
        'purpose': purpose,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  // Revoke consent
  Future<void> revokeConsent(String userId, String purpose) async {
    try {
      await _repository.revokeConsent(
        userId: userId,
        purpose: purpose,
      );
      
      _analytics.track('consent_revoked', {
        'purpose': purpose,
      });
      
      // Handle side effects
      await _handleConsentRevocation(purpose);
    } catch (e) {
      _analytics.track('consent_revoke_failed', {
        'purpose': purpose,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  // Check if user has specific consent
  Future<bool> hasConsent(String userId, String purpose) async {
    try {
      return await _repository.checkConsent(userId, purpose);
    } catch (e) {
      debugPrint('Error checking consent: $e');
      return false; // Default to no consent
    }
  }

  // Get all user consents
  Future<List<Consent>> getUserConsents(String userId) async {
    try {
      return await _repository.getUserConsents(userId);
    } catch (e) {
      debugPrint('Error getting user consents: $e');
      return [];
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
      final request = await _repository.submitVideoVerification(
        userId: userId,
        videoPath: videoPath,
        durationSeconds: durationSeconds,
        sizeBytes: sizeBytes,
      );
      
      _analytics.track('video_verification_submitted', {
        'duration_seconds': durationSeconds,
        'size_bytes': sizeBytes,
      });
      
      return request;
    } catch (e) {
      _analytics.track('video_verification_failed', {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  // Get AI icebreaker suggestion
  Future<String> getAIIcebreaker({
    required String userId,
    required String matchId,
    String contextType = 'first_message',
  }) async {
    try {
      // Check AI assistance consent first
      final hasConsent = await hasConsent(userId, 'ai_assistance');
      if (!hasConsent) {
        throw Exception('Consentement IA requis pour cette fonctionnalité');
      }

      final suggestion = await _repository.getAIIcebreaker(
        userId: userId,
        matchId: matchId,
        contextType: contextType,
      );
      
      _analytics.track('ai_icebreaker_generated', {
        'match_id': matchId,
        'context_type': contextType,
      });
      
      return suggestion;
    } catch (e) {
      _analytics.track('ai_icebreaker_failed', {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  // Mark AI suggestion as used
  Future<void> useAISuggestion(String interactionId, String suggestion) async {
    try {
      await _repository.markAIInteractionUsed(interactionId);
      
      _analytics.track('ai_suggestion_used', {
        'interaction_id': interactionId,
        'suggestion_length': suggestion.length,
      });
    } catch (e) {
      debugPrint('Error marking AI suggestion as used: $e');
    }
  }

  // Request data export
  Future<void> requestDataExport(String userId) async {
    try {
      // This would trigger a data export process
      // For now, just track the request
      _analytics.track('data_export_requested', {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // In real implementation, this would:
      // 1. Call backend function to generate export
      // 2. Queue email with download link
      // 3. Track progress
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing
    } catch (e) {
      throw Exception('Failed to request data export: $e');
    }
  }

  // Handle consent revocation side effects
  Future<void> _handleConsentRevocation(String purpose) async {
    try {
      switch (purpose) {
        case 'gps_tracking':
          // Stop location tracking
          debugPrint('GPS tracking disabled - stopping location services');
          break;
        case 'ai_moderation':
          // Switch to basic moderation
          debugPrint('AI moderation disabled - switching to basic filtering');
          break;
        case 'marketing':
          // Unsubscribe from marketing
          debugPrint('Marketing consent revoked - updating subscription preferences');
          break;
        default:
          debugPrint('No side effects for purpose: $purpose');
      }
    } catch (e) {
      debugPrint('Error handling consent revocation side effects: $e');
    }
  }
}

// Riverpod providers
@riverpod
PrivacyService privacyService(PrivacyServiceRef ref) {
  return PrivacyService(PrivacyRepository());
}

@riverpod
class PrivacySettings extends _$PrivacySettings {
  @override
  AsyncValue<PrivacySettings> build(String userId) {
    return const AsyncValue.loading();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repository = PrivacyRepository();
      final settings = await repository.getUserPrivacySettings(userId);
      state = AsyncValue.data(settings);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateSettings(PrivacySettings newSettings) async {
    try {
      final service = ref.read(privacyServiceProvider);
      await service.updatePrivacySettings(userId, newSettings);
      state = AsyncValue.data(newSettings);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

@riverpod
class UserConsents extends _$UserConsents {
  @override
  AsyncValue<List<Consent>> build(String userId) {
    return const AsyncValue.loading();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repository = PrivacyRepository();
      final consents = await repository.getUserConsents(userId);
      state = AsyncValue.data(consents);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> grantConsent(String purpose) async {
    try {
      final service = ref.read(privacyServiceProvider);
      await service.grantConsent(userId, purpose);
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> revokeConsent(String purpose) async {
    try {
      final service = ref.read(privacyServiceProvider);
      await service.revokeConsent(userId, purpose);
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

@riverpod
class VerificationStatus extends _$VerificationStatus {
  @override
  AsyncValue<VerificationRequest?> build(String userId) {
    return const AsyncValue.loading();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repository = PrivacyRepository();
      final request = await repository.getLatestVerificationRequest(userId);
      state = AsyncValue.data(request);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> submitVerification({
    required String videoPath,
    int? durationSeconds,
    int? sizeBytes,
  }) async {
    try {
      final service = ref.read(privacyServiceProvider);
      final request = await service.submitVideoVerification(
        userId: userId,
        videoPath: videoPath,
        durationSeconds: durationSeconds,
        sizeBytes: sizeBytes,
      );
      state = AsyncValue.data(request);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
