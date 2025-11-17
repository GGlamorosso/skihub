import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class AppConfig {
  static late Environment _environment;
  static late Map<String, dynamic> _config;

  static Environment get environment => _environment;
  static String get environmentName => _environment.name;
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isProduction => _environment == Environment.production;
  static bool get isStaging => _environment == Environment.staging;

  // App info
  static String get appName => _config['app_name'] as String;
  static String get appVersion => _config['app_version'] as String;
  static String get buildNumber => _config['build_number'] as String;

  // Supabase
  static String get supabaseUrl => _config['supabase_url'] as String;
  static String get supabaseAnonKey => _config['supabase_anon_key'] as String;

  // Analytics
  static String get posthogApiKey => _config['posthog_api_key'] as String;
  static String get posthogHost => _config['posthog_host'] as String;

  // Crash Reporting
  static String get sentryDsn => _config['sentry_dsn'] as String;

  // Feature Flags
  static bool get enableAIFeatures => _config['enable_ai_features'] as bool? ?? true;
  static bool get enablePremiumFeatures => _config['enable_premium_features'] as bool? ?? true;
  static bool get enableTracking => _config['enable_tracking'] as bool? ?? true;
  static bool get enableVideoVerification => _config['enable_video_verification'] as bool? ?? true;
  static bool get stripeEnabled => _config['stripe_enabled'] as bool? ?? false; // Temporairement désactivé pour la beta

  // API Endpoints
  static String get apiBaseUrl => _config['api_base_url'] as String;
  static String get stripePublishableKey => _config['stripe_publishable_key'] as String;

  // Limits & Quotas
  static int get freeSwipesLimit => _config['free_swipes_limit'] as int? ?? 20;
  static int get freeMessagesLimit => _config['free_messages_limit'] as int? ?? 10;
  static int get maxPhotosPerUser => _config['max_photos_per_user'] as int? ?? 6;

  static void initialize(Environment environment) {
    _environment = environment;
    _config = _getConfigForEnvironment(environment);
    
    if (kDebugMode) {
      print('🚀 CrewSnow initialized for ${environment.name}');
      print('📊 Analytics: ${enableAIFeatures ? 'Enabled' : 'Disabled'}');
      print('🤖 AI Features: ${enableAIFeatures ? 'Enabled' : 'Disabled'}');
    }
  }

  static Map<String, dynamic> _getConfigForEnvironment(Environment env) {
    switch (env) {
      case Environment.development:
        return {
          'app_name': 'CrewSnow Dev',
          'app_version': '1.0.0',
          'build_number': '1',
          'supabase_url': 'https://qzpinzxiqupetortbczh.supabase.co',
          'supabase_anon_key': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6cGluenhpcXVwZXRvcnRiY3poIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NDg4NjQsImV4cCI6MjA3ODUyNDg2NH0.fxTSP8j9PhwFsLQrWOOkz-b_KdxfY-gFyWKmJKvbLUw',
          'posthog_api_key': 'phc_dev_test_key',
          'posthog_host': 'https://eu.posthog.com',
          'sentry_dsn': 'https://xxx@sentry.io/xxx',
          'api_base_url': 'https://qzpinzxiqupetortbczh.supabase.co',
          'stripe_publishable_key': 'pk_test_xxx',
          'enable_ai_features': true,
          'enable_premium_features': true,
          'enable_tracking': true,
          'enable_video_verification': true,
          'stripe_enabled': false, // Temporairement désactivé pour la beta
          'free_swipes_limit': 20,
          'free_messages_limit': 10,
          'max_photos_per_user': 6,
        };

      case Environment.staging:
        return {
          'app_name': 'CrewSnow Staging',
          'app_version': '1.0.0',
          'build_number': '1',
          'supabase_url': 'https://qzpinzxiqupetortbczh.supabase.co',
          'supabase_anon_key': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6cGluenhpcXVwZXRvcnRiY3poIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NDg4NjQsImV4cCI6MjA3ODUyNDg2NH0.fxTSP8j9PhwFsLQrWOOkz-b_KdxfY-gFyWKmJKvbLUw',
          'posthog_api_key': 'phc_staging_key',
          'posthog_host': 'https://eu.posthog.com',
          'sentry_dsn': 'https://xxx@sentry.io/xxx',
          'api_base_url': 'https://qzpinzxiqupetortbczh.supabase.co',
          'stripe_publishable_key': 'pk_test_xxx',
          'enable_ai_features': true,
          'enable_premium_features': true,
          'enable_tracking': true,
          'enable_video_verification': true,
          'stripe_enabled': false, // Temporairement désactivé pour la beta
          'free_swipes_limit': 15,
          'free_messages_limit': 8,
          'max_photos_per_user': 4,
        };

      case Environment.production:
        return {
          'app_name': 'CrewSnow',
          'app_version': '1.0.0',
          'build_number': '1',
          'supabase_url': 'https://ahxezvuxxqfwgztivfle.supabase.co',
          'supabase_anon_key': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFoeGV6dnV4eHFmd2d6dGl2ZmxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NDg4MTYsImV4cCI6MjA3ODUyNDgxNn0.JhpXlEW4aDXdFGQCqF-sYgHR1x8ctwMJJz_R3OL8dUs',
          'posthog_api_key': 'phc_prod_live_key',
          'posthog_host': 'https://eu.posthog.com',
          'sentry_dsn': 'https://xxx@sentry.io/xxx',
          'api_base_url': 'https://ahxezvuxxqfwgztivfle.supabase.co',
          'stripe_publishable_key': 'pk_live_xxx',
          'enable_ai_features': true,
          'enable_premium_features': true,
          'enable_tracking': true,
          'enable_video_verification': true,
          'stripe_enabled': false, // Temporairement désactivé pour la beta
          'free_swipes_limit': 20,
          'free_messages_limit': 10,
          'max_photos_per_user': 6,
        };
    }
  }
}
