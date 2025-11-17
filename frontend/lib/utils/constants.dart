/// Constantes globales de l'application CrewSnow

class AppConstants {
  // App Info
  static const String appName = 'CrewSnow';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Tu ne skies plus jamais seul.';
  
  // URLs
  static const String supportEmail = 'support@crewsnow.com';
  static const String privacyPolicyUrl = 'https://crewsnow.com/privacy';
  static const String termsOfServiceUrl = 'https://crewsnow.com/terms';
  
  // Contraintes métier
  static const int minAge = 16;
  static const int maxAge = 99;
  static const int maxPhotoSizeMB = 5;
  static const int maxUsernameLength = 30;
  static const int maxBioLength = 500;
  
  // Onboarding
  static const int totalOnboardingSteps = 8;
  
  // Limitations gratuites (pour S7)
  static const int freeSwipesPerDay = 10;
  static const int freeMessagesPerDay = 50;
  
  // Limitations premium
  static const int premiumSwipesPerDay = 100;
  static const int premiumMessagesPerDay = 500;
  
  // Durées
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 2);
  
  // Assets paths
  static const String assetsImages = 'assets/images/';
  static const String assetsIcons = 'assets/icons/';
  static const String assetsAnimations = 'assets/animations/';
}

class StoragePaths {
  static const String profilePhotos = 'profile_photos';
  static const String verificationVideos = 'verification_videos';
  static const String exports = 'exports';
  
  static String userProfilePhoto(String userId, String fileName) =>
      '$profilePhotos/$userId/$fileName';
      
  static String userVerificationVideo(String userId, String fileName) =>
      '$verificationVideos/$userId/$fileName';
}

class DatabaseTables {
  static const String users = 'users';
  static const String profilePhotos = 'profile_photos';
  static const String stations = 'stations';
  static const String userStationStatus = 'user_station_status';
  static const String likes = 'likes';
  static const String matches = 'matches';
  static const String messages = 'messages';
  static const String boosts = 'boosts';
  static const String subscriptions = 'subscriptions';
  static const String rideStatsDaily = 'ride_stats_daily';
  static const String consents = 'consents';
  static const String dailyUsage = 'daily_usage';
}

class EdgeFunctions {
  static const String matchCandidates = 'match-candidates';
  static const String swipeEnhanced = 'swipe-enhanced';
  static const String sendMessageEnhanced = 'send-message-enhanced';
  static const String gatekeeper = 'gatekeeper';
  static const String analyticsPosthog = 'analytics-posthog';
  static const String exportUserData = 'export-user-data';
  static const String manageConsent = 'manage-consent';
  static const String deleteUserAccount = 'delete-user-account';
  static const String stripeWebhookEnhanced = 'stripe-webhook-enhanced';
  static const String createStripeCustomer = 'create-stripe-customer';
}

class ValidationRegex {
  static final email = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  static final username = RegExp(r'^[a-zA-Z0-9_]{3,30}$');
  static final password = RegExp(r'^.{8,}$');
}
