import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../../../core/services/supabase_service.dart';

class PremiumRepository {
  final SupabaseClient _supabase = SupabaseService.client;

  // Get user premium status
  Future<bool> getUserPremiumStatus(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('is_premium, premium_expires_at')
          .eq('id', userId)
          .single();

      final isPremium = response['is_premium'] as bool? ?? false;
      final expiresAt = response['premium_expires_at'] as String?;

      if (!isPremium) return false;
      if (expiresAt == null) return true;

      final expirationDate = DateTime.parse(expiresAt);
      return expirationDate.isAfter(DateTime.now());
    } catch (e) {
      throw Exception('Failed to get premium status: $e');
    }
  }

  // Get user subscription details
  Future<Subscription?> getUserSubscription(String userId) async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;

      return Subscription.fromJson({
        ...response.first,
        'current_period_start': response.first['current_period_start'],
        'current_period_end': response.first['current_period_end'],
        'canceled_at': response.first['canceled_at'],
        'created_at': response.first['created_at'],
        'updated_at': response.first['updated_at'],
      });
    } catch (e) {
      throw Exception('Failed to get subscription: $e');
    }
  }

  // Get user active boosts
  Future<List<Boost>> getUserActiveBoosts(String userId) async {
    try {
      final response = await _supabase
          .from('boosts')
          .select('''
            *,
            stations!inner(name, country_code)
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .gt('ends_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return response.map((json) => Boost.fromJson({
        ...json,
        'station_name': json['stations']['name'],
        'station_country_code': json['stations']['country_code'],
        'starts_at': json['starts_at'],
        'ends_at': json['ends_at'],
        'created_at': json['created_at'],
      })).toList();
    } catch (e) {
      throw Exception('Failed to get active boosts: $e');
    }
  }

  // Get user boost history
  Future<List<Boost>> getUserBoostHistory(String userId, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('boosts')
          .select('''
            *,
            stations!inner(name, country_code)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => Boost.fromJson({
        ...json,
        'station_name': json['stations']['name'],
        'station_country_code': json['stations']['country_code'],
        'starts_at': json['starts_at'],
        'ends_at': json['ends_at'],
        'created_at': json['created_at'],
      })).toList();
    } catch (e) {
      throw Exception('Failed to get boost history: $e');
    }
  }

  // Check quota info via gatekeeper
  Future<QuotaInfo> checkQuota(String userId, String action) async {
    try {
      final response = await _supabase.functions.invoke(
        'gatekeeper',
        body: {
          'user_id': userId,
          'action': action,
        },
      );

      if (response.error != null) {
        throw Exception('Gatekeeper error: ${response.error}');
      }

      final quotaData = response.data['quota_info'];
      return QuotaInfo.fromJson({
        'swipe_remaining': quotaData['swipe_remaining'],
        'message_remaining': quotaData['message_remaining'],
        'limit_reached': quotaData['limit_reached'],
        'limit_type': quotaData['limit_type'],
        'resets_at': quotaData['resets_at'],
        'is_premium': quotaData['is_premium'],
      });
    } catch (e) {
      throw Exception('Failed to check quota: $e');
    }
  }

  // Create Stripe checkout session
  Future<String> createCheckoutSession({
    required String priceId,
    required String userId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-checkout-session',
        body: {
          'price_id': priceId,
          'user_id': userId,
          'success_url': successUrl,
          'cancel_url': cancelUrl,
        },
      );

      if (response.error != null) {
        throw Exception('Checkout session error: ${response.error}');
      }

      return response.data['checkout_url'] as String;
    } catch (e) {
      throw Exception('Failed to create checkout session: $e');
    }
  }

  // Create boost session
  Future<Map<String, dynamic>> createBoostSession({
    required String userId,
    required String stationId,
    required BoostType boostType,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-boost-session',
        body: {
          'user_id': userId,
          'station_id': stationId,
          'boost_type': boostType.name,
          'success_url': successUrl,
          'cancel_url': cancelUrl,
        },
      );

      if (response.error != null) {
        throw Exception('Boost session error: ${response.error}');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create boost session: $e');
    }
  }

  // Create customer portal session
  Future<String> createCustomerPortalSession({
    required String userId,
    String? returnUrl,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'customer-portal',
        body: {
          'user_id': userId,
          'return_url': returnUrl,
        },
      );

      if (response.error != null) {
        throw Exception('Portal session error: ${response.error}');
      }

      return response.data['portal_url'] as String;
    } catch (e) {
      throw Exception('Failed to create portal session: $e');
    }
  }

  // Stream subscription changes
  Stream<Subscription?> watchUserSubscription(String userId) {
    return _supabase
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .map((data) {
          if (data.isEmpty) return null;
          final subscriptionData = data.first;
          return Subscription.fromJson({
            ...subscriptionData,
            'current_period_start': subscriptionData['current_period_start'],
            'current_period_end': subscriptionData['current_period_end'],
            'canceled_at': subscriptionData['canceled_at'],
            'created_at': subscriptionData['created_at'],
            'updated_at': subscriptionData['updated_at'],
          });
        });
  }

  // Stream user premium status
  Stream<bool> watchUserPremiumStatus(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) return false;
          final user = data.first;
          final isPremium = user['is_premium'] as bool? ?? false;
          final expiresAt = user['premium_expires_at'] as String?;

          if (!isPremium) return false;
          if (expiresAt == null) return true;

          final expirationDate = DateTime.parse(expiresAt);
          return expirationDate.isAfter(DateTime.now());
        });
  }

  // Stream active boosts
  Stream<List<Boost>> watchUserActiveBoosts(String userId) {
    return _supabase
        .from('boosts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .eq('is_active', true)
        .gt('ends_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Boost.fromJson({
              ...json,
              'starts_at': json['starts_at'],
              'ends_at': json['ends_at'],
              'created_at': json['created_at'],
            })).toList());
  }
}
