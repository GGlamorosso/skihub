import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../config/app_config.dart';

class PosthogService {
  static final PosthogService _instance = PosthogService._internal();
  factory PosthogService() => _instance;
  PosthogService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Posthog().setup(
        PosthogConfig(
          apiKey: AppConfig.posthogApiKey,
          host: AppConfig.posthogHost,
          captureApplicationLifecycleEvents: true,
          debug: AppConfig.isDevelopment,
          sendFeatureFlagEvent: true,
        ),
      );

      _isInitialized = true;
      if (kDebugMode) print('📊 PostHog analytics initialized');
    } catch (e) {
      if (kDebugMode) print('📊 PostHog initialization failed: $e');
    }
  }

  // User identification
  Future<void> identify({
    required String userId,
    String? email,
    String? username,
    bool? isPremium,
    Map<String, dynamic>? properties,
  }) async {
    if (!_isInitialized) return;

    try {
      final userProperties = {
        'email': email,
        'username': username,
        'is_premium': isPremium,
        'environment': AppConfig.environmentName,
        'app_version': AppConfig.appVersion,
        ...?properties,
      };

      await Posthog().identify(
        userId: userId,
        userProperties: userProperties,
      );
    } catch (e) {
      if (kDebugMode) print('Error identifying user: $e');
    }
  }

  // Track events
  Future<void> track(String event, [Map<String, dynamic>? properties]) async {
    if (!_isInitialized) return;

    try {
      await Posthog().capture(
        eventName: event,
        properties: {
          'timestamp': DateTime.now().toIso8601String(),
          'environment': AppConfig.environmentName,
          'app_version': AppConfig.appVersion,
          ...?properties,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Error tracking event: $e');
    }
  }

  // User journey tracking
  Future<void> trackUserJourney(String step, Map<String, dynamic>? context) async {
    await track('user_journey', {
      'step': step,
      'context': context,
    });
  }

  // App lifecycle events
  Future<void> trackAppLifecycle(String event) async {
    await track('app_lifecycle', {'event': event});
  }

  // Onboarding funnel
  Future<void> trackOnboardingStep(String step, {Map<String, dynamic>? data}) async {
    await track('onboarding_step', {
      'step': step,
      'funnel': 'onboarding',
      ...?data,
    });
  }

  // Matching funnel  
  Future<void> trackMatchingEvent(String event, {Map<String, dynamic>? data}) async {
    await track('matching_event', {
      'event': event,
      'funnel': 'matching',
      ...?data,
    });
  }

  // Premium funnel
  Future<void> trackPremiumEvent(String event, {Map<String, dynamic>? data}) async {
    await track('premium_event', {
      'event': event,
      'funnel': 'premium',
      ...?data,
    });
  }

  // Feature usage
  Future<void> trackFeatureUsage(String feature, {Map<String, dynamic>? context}) async {
    await track('feature_used', {
      'feature': feature,
      'context': context,
    });
  }

  // Screen views
  Future<void> trackScreen(String screenName, {Map<String, dynamic>? properties}) async {
    await track('screen_view', {
      'screen_name': screenName,
      ...?properties,
    });
  }

  // Button/action tracking
  Future<void> trackAction(String action, {Map<String, dynamic>? context}) async {
    await track('user_action', {
      'action': action,
      'context': context,
    });
  }

  // Error tracking  
  Future<void> trackError(String error, {
    String? feature,
    String? severity,
    Map<String, dynamic>? context,
  }) async {
    await track('app_error', {
      'error': error,
      'feature': feature,
      'severity': severity ?? 'medium',
      'context': context,
    });
  }

  // Performance tracking
  Future<void> trackPerformance(String metric, double value, {Map<String, dynamic>? tags}) async {
    await track('performance_metric', {
      'metric': metric,
      'value': value,
      'tags': tags,
    });
  }

  // A/B testing support
  Future<String?> getFeatureFlag(String flagKey) async {
    if (!_isInitialized) return null;

    try {
      return await Posthog().getFeatureFlag(flagKey) as String?;
    } catch (e) {
      if (kDebugMode) print('Error getting feature flag: $e');
      return null;
    }
  }

  Future<bool> isFeatureEnabled(String flagKey) async {
    if (!_isInitialized) return false;

    try {
      return await Posthog().isFeatureEnabled(flagKey);
    } catch (e) {
      if (kDebugMode) print('Error checking feature flag: $e');
      return false;
    }
  }

  // Set super properties (sent with every event)
  Future<void> setSuperProperties(Map<String, dynamic> properties) async {
    try {
      await Posthog().register(properties);
    } catch (e) {
      if (kDebugMode) print('Error setting super properties: $e');
    }
  }

  // Reset user (logout)
  Future<void> reset() async {
    if (!_isInitialized) return;

    try {
      await Posthog().reset();
    } catch (e) {
      if (kDebugMode) print('Error resetting PostHog: $e');
    }
  }

  // Flush events (force send)
  Future<void> flush() async {
    if (!_isInitialized) return;

    try {
      await Posthog().flush();
    } catch (e) {
      if (kDebugMode) print('Error flushing PostHog: $e');
    }
  }
}

// Analytics mixins for easy usage
mixin AnalyticsTrackingMixin {
  PosthogService get analytics => PosthogService();

  void trackScreenView(String screenName, [Map<String, dynamic>? properties]) {
    analytics.trackScreen(screenName, properties: properties);
  }

  void trackButtonTap(String buttonName, [Map<String, dynamic>? context]) {
    analytics.trackAction('button_tap', context: {
      'button': buttonName,
      ...?context,
    });
  }

  void trackError(dynamic error, [String? feature]) {
    analytics.trackError(
      error.toString(),
      feature: feature,
      context: {'widget': runtimeType.toString()},
    );
  }
}

// Extension for widgets
extension WidgetAnalytics on Widget {
  Widget trackScreenView(String screenName) {
    return _AnalyticsWrapper(
      screenName: screenName,
      child: this,
    );
  }
}

class _AnalyticsWrapper extends StatefulWidget {
  final String screenName;
  final Widget child;

  const _AnalyticsWrapper({
    required this.screenName,
    required this.child,
  });

  @override
  State<_AnalyticsWrapper> createState() => _AnalyticsWrapperState();
}

class _AnalyticsWrapperState extends State<_AnalyticsWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PosthogService().trackScreen(widget.screenName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
