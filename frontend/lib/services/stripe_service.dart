import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/env_config.dart';
import '../utils/error_handler.dart';

class StripeService {
  final SupabaseClient _supabase;
  
  StripeService({SupabaseClient? supabase}) 
      : _supabase = supabase ?? Supabase.instance.client;

  // Create checkout session for subscription
  Future<String?> createSubscriptionCheckout({
    required String priceId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase.functions.invoke(
        'create-checkout-session',
        body: {
          'price_id': priceId,
          'customer_email': user.email,
          'success_url': successUrl ?? '${EnvConfig.appScheme}://payment-success',
          'cancel_url': cancelUrl ?? '${EnvConfig.appScheme}://payment-cancel',
          'metadata': {
            'user_id': user.id,
            'subscription_type': 'premium',
          },
        },
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      return response.data['checkout_url'] as String?;
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to create checkout session', error: e);
      return null;
    }
  }

  // Create checkout session for boost
  Future<String?> createBoostCheckout({
    required String boostType,
    required String stationId,
    int? durationHours,
    double? multiplier,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase.functions.invoke(
        'create-boost-session',
        body: {
          'boost_type': boostType,
          'station_id': stationId,
          'duration_hours': durationHours ?? 24,
          'boost_multiplier': multiplier ?? 2.0,
          'customer_email': user.email,
          'success_url': '${EnvConfig.appScheme}://boost-success',
          'cancel_url': '${EnvConfig.appScheme}://boost-cancel',
          'metadata': {
            'user_id': user.id,
            'station_id': stationId,
            'boost_type': boostType,
          },
        },
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      return response.data['checkout_url'] as String?;
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to create boost checkout', error: e);
      return null;
    }
  }

  // Launch checkout in browser
  Future<bool> launchCheckout(String checkoutUrl) async {
    try {
      final uri = Uri.parse(checkoutUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        throw Exception('Could not launch checkout URL');
      }
      
      return true;
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to launch checkout', error: e);
      return false;
    }
  }

  // Create customer portal session for subscription management
  Future<String?> createCustomerPortalSession({String? returnUrl}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase.functions.invoke(
        'create-customer-portal-session',
        body: {
          'return_url': returnUrl ?? '${EnvConfig.appScheme}://account',
        },
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      return response.data['portal_url'] as String?;
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to create customer portal session', error: e);
      return null;
    }
  }

  // Get Stripe customer ID or create if doesn't exist
  Future<String?> getOrCreateStripeCustomer() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Check if customer ID already exists
      final userResponse = await _supabase
          .from('users')
          .select('stripe_customer_id')
          .eq('id', userId)
          .single();

      final existingCustomerId = userResponse['stripe_customer_id'] as String?;
      if (existingCustomerId != null) {
        return existingCustomerId;
      }

      // Create new customer
      final user = _supabase.auth.currentUser!;
      final response = await _supabase.functions.invoke(
        'create-stripe-customer',
        body: {
          'user_id': user.id,
          'email': user.email,
          'metadata': {
            'user_id': user.id,
            'created_from': 'mobile_app',
          },
        },
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      return response.data['customer_id'] as String?;
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to get or create Stripe customer', error: e);
      return null;
    }
  }

  // Cancel subscription (redirect to customer portal)
  Future<bool> cancelSubscription() async {
    try {
      final portalUrl = await createCustomerPortalSession();
      if (portalUrl == null) return false;
      
      return await launchCheckout(portalUrl);
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to cancel subscription', error: e);
      return false;
    }
  }

  // Restore purchases (for mobile stores)
  Future<void> restorePurchases() async {
    try {
      // For In-App Purchases, this would restore from the store
      // For Stripe, we refresh the user's subscription status
      await refreshSubscriptionStatus();
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to restore purchases', error: e);
    }
  }

  // Refresh subscription status from backend
  Future<void> refreshSubscriptionStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Call edge function to sync with Stripe
      await _supabase.functions.invoke(
        'sync-subscription-status',
        body: {'user_id': userId},
      );
      
      // Wait a moment for the webhook to process
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to refresh subscription status', error: e);
    }
  }

  // Handle payment success callback
  Future<void> handlePaymentSuccess({
    required String sessionId,
    String? type = 'subscription',
  }) async {
    try {
      // Log success event for analytics
      await _supabase.functions.invoke(
        'log-payment-event',
        body: {
          'event': 'payment_success',
          'session_id': sessionId,
          'type': type,
          'user_id': _supabase.auth.currentUser?.id,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Refresh user status
      await refreshSubscriptionStatus();
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to handle payment success', error: e);
    }
  }

  // Handle payment cancellation
  Future<void> handlePaymentCancel({String? reason}) async {
    try {
      // Log cancel event for analytics
      await _supabase.functions.invoke(
        'log-payment-event',
        body: {
          'event': 'payment_cancel',
          'reason': reason ?? 'user_cancelled',
          'user_id': _supabase.auth.currentUser?.id,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to handle payment cancel', error: e);
    }
  }

  // Get subscription usage analytics
  Future<Map<String, dynamic>> getSubscriptionAnalytics() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase.functions.invoke(
        'get-subscription-analytics',
        body: {'user_id': userId},
      );

      return response.data as Map<String, dynamic>? ?? {};
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to get subscription analytics', error: e);
      return {};
    }
  }
}
