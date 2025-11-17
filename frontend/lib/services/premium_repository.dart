import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../utils/error_handler.dart';

class PremiumRepository {
  final SupabaseClient _supabase;
  
  PremiumRepository({SupabaseClient? supabase}) 
      : _supabase = supabase ?? Supabase.instance.client;

  // Get current user's premium status
  Future<bool> isPremiumActive() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('users')
          .select('is_premium, premium_expires_at')
          .eq('id', userId)
          .single();

      final isPremium = response['is_premium'] as bool? ?? false;
      final expiresAt = response['premium_expires_at'] as String?;
      
      if (!isPremium) return false;
      if (expiresAt == null) return isPremium;
      
      final expiryDate = DateTime.parse(expiresAt);
      return DateTime.now().isBefore(expiryDate);
    } catch (e) {
          ErrorHandler.logError(context: 'Failed to check premium status', error: e);
      return false;
    }
  }

  // Get current user's subscription
  Future<Subscription?> getCurrentSubscription() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('subscriptions')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Subscription.fromJson(response);
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to get subscription', error: e);
      return null;
    }
  }

  // Get user's active boosts
  Future<List<Boost>> getActiveBoosts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('boosts')
          .select('''
            *,
            stations:station_id (
              name
            )
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .gte('ends_at', DateTime.now().toIso8601String())
          .order('ends_at');

      return response.map<Boost>((json) {
        final boost = Boost.fromJson(json);
        final stationData = json['stations'] as Map<String, dynamic>?;
        return boost.copyWith(
          stationName: stationData?['name'] as String?,
        );
      }).toList();
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to get active boosts', error: e);
      return [];
    }
  }

  // Get boost history
  Future<List<Boost>> getBoostHistory({int limit = 50}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('boosts')
          .select('''
            *,
            stations:station_id (
              name
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map<Boost>((json) {
        final boost = Boost.fromJson(json);
        final stationData = json['stations'] as Map<String, dynamic>?;
        return boost.copyWith(
          stationName: stationData?['name'] as String?,
        );
      }).toList();
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to get boost history', error: e);
      return [];
    }
  }

  // Create Stripe customer if doesn't exist
  Future<String?> createStripeCustomer() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase.functions.invoke(
        'create-stripe-customer',
        body: {
          'user_id': user.id,
          'email': user.email,
          'metadata': {
            'user_id': user.id,
            'created_at': DateTime.now().toIso8601String(),
          }
        },
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      return response.data['customer_id'] as String?;
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to create Stripe customer', error: e);
      return null;
    }
  }

  // Get premium plans
  Future<List<PremiumPlan>> getPremiumPlans() async {
    // In a real app, this could come from Stripe API or a config table
    return [
      const PremiumPlan(
        id: 'monthly',
        name: 'Premium Mensuel',
        description: 'Accès complet aux fonctionnalités premium',
        amountCents: 999, // 9.99€
        currency: 'EUR',
        interval: 'month',
        features: [
          'Likes illimités',
          'Super likes quotidiens',
          'Voir qui vous a liké',
          'Filtres avancés',
          'Mode invisible',
          'Stats détaillées',
          'Support prioritaire',
        ],
        isPopular: true,
        stripePriceId: null, // EnvConfig.stripePriceMonthly, // Temporairement null car Stripe désactivé
      ),
      const PremiumPlan(
        id: 'yearly',
        name: 'Premium Annuel',
        description: 'Le meilleur rapport qualité-prix',
        amountCents: 7999, // 79.99€
        currency: 'EUR',
        interval: 'year',
        features: [
          'Likes illimités',
          'Super likes quotidiens',
          'Voir qui vous a liké',
          'Filtres avancés',
          'Mode invisible',
          'Stats détaillées',
          'Support prioritaire',
          '4 boosts gratuits par mois',
        ],
        isPopular: false,
        stripePriceId: null, // EnvConfig.stripePriceYearly, // Temporairement null car Stripe désactivé
        discountPercent: 33,
      ),
    ];
  }

  // Get boost plans
  Future<List<PremiumPlan>> getBoostPlans() async {
    return [
      const PremiumPlan(
        id: 'boost_1h',
        name: 'Boost 1h',
        description: 'Visibilité x2 pendant 1 heure',
        amountCents: 199, // 1.99€
        currency: 'EUR',
        interval: 'one_time',
        features: [
          'Visibilité x2 sur votre station',
          'Apparaît en premier dans les résultats',
          'Durée: 1 heure',
        ],
        isPopular: false,
      ),
      const PremiumPlan(
        id: 'boost_24h',
        name: 'Boost 24h',
        description: 'Visibilité x2 pendant une journée complète',
        amountCents: 599, // 5.99€
        currency: 'EUR',
        interval: 'one_time',
        features: [
          'Visibilité x2 sur votre station',
          'Apparaît en premier dans les résultats',
          'Durée: 24 heures',
          'Meilleur rapport qualité-prix',
        ],
        isPopular: true,
      ),
      const PremiumPlan(
        id: 'boost_week',
        name: 'Boost Semaine',
        description: 'Visibilité x2 pour toute votre semaine de ski',
        amountCents: 1999, // 19.99€
        currency: 'EUR',
        interval: 'one_time',
        features: [
          'Visibilité x2 sur votre station',
          'Apparaît en premier dans les résultats',
          'Durée: 7 jours',
          'Idéal pour les vacances',
          'Support prioritaire',
        ],
        isPopular: false,
      ),
    ];
  }

  // Refresh user premium status from database
  Future<void> refreshPremiumStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // This triggers a fresh read from the database
      await _supabase
          .from('users')
          .select('is_premium, premium_expires_at')
          .eq('id', userId)
          .single();
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to refresh premium status', error: e);
    }
  }

  // Listen to subscription changes
  RealtimeChannel subscribeToSubscriptionChanges(
    String userId,
    void Function(Subscription) onUpdate,
  ) {
    return _supabase
        .channel('subscriptions:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'subscriptions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final subscription = Subscription.fromJson(payload.newRecord);
              onUpdate(subscription);
            } catch (e) {
              ErrorHandler.logError(context: 'Failed to parse subscription update', error: e);
            }
          },
        )
        .subscribe();
  }

  // Listen to user premium status changes
  RealtimeChannel subscribeToUserPremiumChanges(
    String userId,
    void Function(bool) onPremiumStatusChange,
  ) {
    return _supabase
        .channel('user_premium:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final isPremium = payload.newRecord['is_premium'] as bool? ?? false;
              onPremiumStatusChange(isPremium);
            } catch (e) {
              ErrorHandler.logError(context: 'Failed to parse premium status update', error: e);
            }
          },
        )
        .subscribe();
  }
}
