import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration d'environnement pour CrewSnow
class EnvConfig {
  static bool get isDevelopment => 
      const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development') == 'development';
  
  static bool get isProduction => 
      const String.fromEnvironment('ENVIRONMENT') == 'production';
  
  // Supabase Configuration
  static String get supabaseUrl {
    const devUrl = 'https://qzpinzxiqupetortbczh.supabase.co';
    const prodUrl = 'https://ahxezvuxxqfwgztivfle.supabase.co';
    
    return const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: devUrl,
    );
  }
  
  static String get supabaseAnonKey {
    const devKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6cGluenhpcXVwZXRvcnRiY3poIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NDg4NjQsImV4cCI6MjA3ODUyNDg2NH0.LRM-2lME0KWXXUkQE8MQgTXDi_lRxdWrt51Xm3i7ONU';
    const prodKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFoeGV6dnV4eHFmd2d6dGl2ZmxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NTg1NzcsImV4cCI6MjA3ODUzNDU3N30.on48UJpIwZBlTest0epe60zWywi_Di2MymXDjvVCXdk';
    
    return const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: devKey,
    );
  }
  
  // Stripe Configuration
  static String get stripePublishableKey {
    const devKey = 'pk_test_51234567890abcdef'; // TODO: Replace with real dev key
    const prodKey = 'pk_live_51234567890abcdef'; // TODO: Replace with real prod key
    
    return const String.fromEnvironment(
      'STRIPE_PUBLISHABLE_KEY',
      defaultValue: devKey,
    );
  }
  
  static String get stripePriceMonthly {
    const devPrice = 'price_1234567890monthly'; // TODO: Replace with real price ID
    const prodPrice = 'price_1234567890monthly_prod';
    
    return const String.fromEnvironment(
      'STRIPE_PRICE_MONTHLY',
      defaultValue: devPrice,
    );
  }
  
  static String get stripePriceYearly {
    const devPrice = 'price_1234567890yearly'; // TODO: Replace with real price ID
    const prodPrice = 'price_1234567890yearly_prod';
    
    return const String.fromEnvironment(
      'STRIPE_PRICE_YEARLY',
      defaultValue: devPrice,
    );
  }
  
  static String get appScheme => 'crewsnow';
  
  // PostHog Configuration (for future use)
  static String get posthogApiKey {
    return const String.fromEnvironment(
      'POSTHOG_API_KEY',
      defaultValue: 'phc_placeholder',
    );
  }
  
  // App Configuration
  static String get appName => 'CrewSnow';
  static String get appVersion => '1.0.0';
  static String get supportEmail => 'support@crewsnow.com';
  
  // Feature Flags
  static bool get enableAppleSignIn => false;
  static bool get enableGoogleSignIn => false;
  static bool get enableTracking => true;
  static bool get enablePremium => true; // S7: Premium features enabled
  static bool get enableBoosts => true; // S7: Boost features enabled
  static bool get enableAnalytics => true;
  
  // Debug
  static bool get enableDebugMode => isDevelopment;
  static bool get enableVerboseLogging => isDevelopment;
  
  /// Load environment from .env file
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // Fichier .env optionnel, continuer avec valeurs par défaut
      print('Warning: .env file not found, using default values');
    }
  }
  
  /// Validation des variables requises
  static void validate() {
    assert(supabaseUrl.isNotEmpty, 'SUPABASE_URL is required');
    assert(supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY is required');
    
    if (isDevelopment) {
      print('🔧 Environment: Development');
      print('🔗 Supabase URL: $supabaseUrl');
      print('🔑 Anon Key: ${supabaseAnonKey.substring(0, 20)}...');
    }
  }
}
