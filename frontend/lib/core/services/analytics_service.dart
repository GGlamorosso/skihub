import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Initialize analytics (PostHog, Firebase, etc.)
  Future<void> initialize() async {
    try {
      // Initialize your analytics provider here
      debugPrint('Analytics service initialized');
    } catch (e) {
      debugPrint('Analytics initialization error: $e');
    }
  }

  // Track premium events
  void trackPremiumScreenViewed() {
    track('premium_screen_viewed');
  }

  void trackPremiumPlanSelected(String planId) {
    track('premium_plan_selected', {'plan_id': planId});
  }

  void trackPremiumPurchaseStarted({
    required String planId,
    required String method,
  }) {
    track('premium_purchase_started', {
      'plan_id': planId,
      'payment_method': method,
    });
  }

  void trackPremiumPurchaseSuccess({
    required String planId,
    required String method,
    required double amount,
  }) {
    track('premium_purchase_success', {
      'plan_id': planId,
      'payment_method': method,
      'amount': amount,
    });
  }

  void trackPremiumPurchaseFailed({
    required String planId,
    required String error,
  }) {
    track('premium_purchase_failed', {
      'plan_id': planId,
      'error': error,
    });
  }

  // Track quota events
  void trackQuotaLimitReached(String type, int remaining) {
    track('quota_limit_reached', {
      'type': type,
      'remaining': remaining,
    });
  }

  void trackQuotaModalShown({
    required String type,
    required int remaining,
  }) {
    track('quota_modal_shown', {
      'type': type,
      'remaining': remaining,
    });
  }

  void trackQuotaUpgradeClicked() {
    track('quota_upgrade_clicked');
  }

  // Track boost events
  void trackBoostScreenViewed() {
    track('boost_screen_viewed');
  }

  void trackBoostPurchaseStarted(BoostType boostType) {
    track('boost_purchase_started', {
      'boost_type': boostType.name,
      'duration_hours': boostType.durationHours,
      'price': boostType.displayPrice,
    });
  }

  void trackBoostActivated({
    required String stationId,
    required BoostType boostType,
  }) {
    track('boost_activated', {
      'station_id': stationId,
      'boost_type': boostType.name,
      'multiplier': boostType.multiplier,
    });
  }

  void trackBoostExpired({
    required String stationId,
    required BoostType boostType,
  }) {
    track('boost_expired', {
      'station_id': stationId,
      'boost_type': boostType.name,
    });
  }

  // Track feature usage
  void trackPremiumFeatureUsed(String featureName) {
    track('premium_feature_used', {'feature': featureName});
  }

  void trackPremiumFeatureBlocked(String featureName) {
    track('premium_feature_blocked', {'feature': featureName});
  }

  // Track user journey
  void trackUserJourney({
    required String event,
    required String userId,
    Map<String, dynamic>? properties,
  }) {
    track(event, {
      'user_id': userId,
      ...?properties,
    });
  }

  // Core tracking method
  void track(String event, [Map<String, dynamic>? properties]) {
    try {
      debugPrint('Analytics: $event ${properties ?? ''}');
      
      // Implement your analytics provider here
      // PostHog.capture(event, properties: properties);
      // FirebaseAnalytics.instance.logEvent(name: event, parameters: properties);
      
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // Set user properties
  void setUserProperties({
    required String userId,
    required bool isPremium,
    String? subscriptionType,
    DateTime? premiumSince,
  }) {
    try {
      // Set user properties in analytics
      final properties = {
        'user_id': userId,
        'is_premium': isPremium,
        'subscription_type': subscriptionType,
        'premium_since': premiumSince?.toIso8601String(),
      };
      
      debugPrint('User properties set: $properties');
      
    } catch (e) {
      debugPrint('User properties error: $e');
    }
  }

  // Revenue tracking
  void trackRevenue({
    required String event,
    required double amount,
    required String currency,
    String? productId,
    Map<String, dynamic>? properties,
  }) {
    track(event, {
      'revenue': amount,
      'currency': currency,
      'product_id': productId,
      ...?properties,
    });
  }
}

// Extensions for easy usage
extension AnalyticsExtensions on AnalyticsService {
  // Premium shortcuts
  void premiumViewed() => trackPremiumScreenViewed();
  void premiumSelected(String planId) => trackPremiumPlanSelected(planId);
  void premiumSuccess(String planId, String method, double amount) => 
      trackPremiumPurchaseSuccess(planId: planId, method: method, amount: amount);
  void premiumFailed(String planId, String error) => 
      trackPremiumPurchaseFailed(planId: planId, error: error);

  // Quota shortcuts
  void quotaHit(String type, int remaining) => trackQuotaLimitReached(type, remaining);
  void quotaModalShown(String type, int remaining) => 
      trackQuotaModalShown(type: type, remaining: remaining);
  void quotaUpgrade() => trackQuotaUpgradeClicked();

  // Boost shortcuts
  void boostViewed() => trackBoostScreenViewed();
  void boostStarted(BoostType type) => trackBoostPurchaseStarted(type);
  void boostActive(String stationId, BoostType type) => 
      trackBoostActivated(stationId: stationId, boostType: type);
}

enum BoostType {
  hourly, daily, weekly;
  
  String get name => toString().split('.').last;
  
  int get durationHours {
    switch (this) {
      case hourly: return 1;
      case daily: return 24;
      case weekly: return 168;
    }
  }
  
  double get displayPrice {
    switch (this) {
      case hourly: return 2.99;
      case daily: return 9.99;
      case weekly: return 19.99;
    }
  }
  
  double get multiplier {
    switch (this) {
      case hourly: return 2.0;
      case daily: return 3.0;  
      case weekly: return 5.0;
    }
  }
}
