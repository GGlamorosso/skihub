import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import 'posthog_service.dart';

part 'feature_flag_service.g.dart';

class FeatureFlagService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PosthogService _analytics = PosthogService();
  
  Map<String, bool> _cachedFlags = {};
  DateTime? _lastFetch;

  // Get feature flag value
  Future<bool> isEnabled(String flagKey, {String? userId}) async {
    try {
      // Check cache first (valid for 5 minutes)
      if (_lastFetch != null && 
          DateTime.now().difference(_lastFetch!).inMinutes < 5 &&
          _cachedFlags.containsKey(flagKey)) {
        return _cachedFlags[flagKey] ?? false;
      }

      // Try PostHog first (real-time A/B testing)
      if (userId != null) {
        final posthogFlag = await _analytics.isFeatureEnabled(flagKey);
        _cachedFlags[flagKey] = posthogFlag;
        return posthogFlag;
            }

      // Fallback to Supabase feature flags
      final response = await _supabase.rpc('is_feature_enabled', params: {
        'flag_key': flagKey,
        'target_user_id': userId,
        'user_environment': AppConfig.environmentName,
      });

      final isEnabled = response as bool? ?? false;
      _cachedFlags[flagKey] = isEnabled;
      _lastFetch = DateTime.now();

      return isEnabled;
    } catch (e) {
      if (kDebugMode) print('Feature flag error for $flagKey: $e');
      
      // Fallback to app config defaults
      return _getDefaultValue(flagKey);
    }
  }

  // Get all feature flags for user
  Future<Map<String, bool>> getAllFlags({String? userId}) async {
    try {
      final response = await _supabase.rpc('get_user_feature_flags', params: {
        'target_user_id': userId,
        'user_environment': AppConfig.environmentName,
      });

      final flags = <String, bool>{};
      for (final row in response as List) {
        flags[row['flag_key']] = row['is_enabled'] as bool;
      }

      _cachedFlags = flags;
      _lastFetch = DateTime.now();
      
      return flags;
    } catch (e) {
      if (kDebugMode) print('Error getting all feature flags: $e');
      return _getDefaultFlags();
    }
  }

  // Check if specific features are enabled
  Future<bool> isAIEnabled({String? userId}) async {
    return await isEnabled('ai_assistant', userId: userId) && AppConfig.enableAIFeatures;
  }

  Future<bool> isPremiumEnabled({String? userId}) async {
    return await isEnabled('premium_features', userId: userId) && AppConfig.enablePremiumFeatures;
  }

  Future<bool> isTrackingEnabled({String? userId}) async {
    return await isEnabled('live_tracking', userId: userId) && AppConfig.enableTracking;
  }

  Future<bool> isVideoVerificationEnabled({String? userId}) async {
    return await isEnabled('video_verification', userId: userId) && AppConfig.enableVideoVerification;
  }

  Future<bool> isInvisibleModeEnabled({String? userId}) async {
    return await isEnabled('invisible_mode', userId: userId);
  }

  Future<bool> isSafetyCenterEnabled({String? userId}) async {
    return await isEnabled('safety_center', userId: userId);
  }

  Future<bool> isEnhancedModerationEnabled({String? userId}) async {
    return await isEnabled('enhanced_moderation', userId: userId);
  }

  // Beta/experimental features
  Future<bool> isAdvancedMatchingEnabled({String? userId}) async {
    return await isEnabled('advanced_matching', userId: userId);
  }

  Future<bool> isGroupChatEnabled({String? userId}) async {
    return await isEnabled('group_chat', userId: userId);
  }

  Future<bool> isSocialFeedEnabled({String? userId}) async {
    return await isEnabled('social_feed', userId: userId);
  }

  // A/B test variants
  Future<String> getOnboardingVariant({String? userId}) async {
    final isV2 = await isEnabled('onboarding_v2', userId: userId);
    return isV2 ? 'v2' : 'v1';
  }

  Future<String> getPaywallVariant({String? userId}) async {
    final isVariantA = await isEnabled('paywall_design_a', userId: userId);
    return isVariantA ? 'design_a' : 'design_b';
  }

  // Clear cache (call after user login/logout)
  void clearCache() {
    _cachedFlags.clear();
    _lastFetch = null;
  }

  // Refresh flags from server
  Future<void> refresh({String? userId}) async {
    clearCache();
    await getAllFlags(userId: userId);
  }

  // Default values based on app config
  bool _getDefaultValue(String flagKey) {
    switch (flagKey) {
      case 'ai_assistant':
        return AppConfig.enableAIFeatures;
      case 'premium_features':
        return AppConfig.enablePremiumFeatures;
      case 'video_verification':
        return AppConfig.enableVideoVerification;
      case 'live_tracking':
        return AppConfig.enableTracking;
      case 'invisible_mode':
        return true;
      case 'safety_center':
        return true;
      case 'enhanced_moderation':
        return true;
      case 'user_reporting':
        return true;
      default:
        return false;
    }
  }

  Map<String, bool> _getDefaultFlags() {
    return {
      'ai_assistant': AppConfig.enableAIFeatures,
      'premium_features': AppConfig.enablePremiumFeatures,
      'video_verification': AppConfig.enableVideoVerification,
      'live_tracking': AppConfig.enableTracking,
      'invisible_mode': true,
      'safety_center': true,
      'enhanced_moderation': true,
      'user_reporting': true,
      'advanced_matching': false,
      'group_chat': false,
      'social_feed': false,
      'onboarding_v2': false,
      'paywall_design_a': true,
    };
  }
}

// Riverpod providers
@riverpod
FeatureFlagService featureFlagService(FeatureFlagServiceRef ref) {
  return FeatureFlagService();
}

@riverpod
class UserFeatureFlags extends _$UserFeatureFlags {
  @override
  AsyncValue<Map<String, bool>> build(String? userId) {
    return const AsyncValue.loading();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(featureFlagServiceProvider);
      final flags = await service.getAllFlags(userId: userId);
      state = AsyncValue.data(flags);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> isEnabled(String flagKey) async {
    try {
      final service = ref.read(featureFlagServiceProvider);
      return await service.isEnabled(flagKey, userId: userId);
    } catch (e) {
      return false;
    }
  }
}
