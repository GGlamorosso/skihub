import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/premium_repository.dart';
import '../models/subscription.dart';

class StripeService {
  final PremiumRepository _premiumRepository;

  StripeService(this._premiumRepository);

  // Create checkout session and launch
  Future<bool> purchasePremium({
    required String userId,
    required String priceId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final checkoutUrl = await _premiumRepository.createCheckoutSession(
        priceId: priceId,
        userId: userId,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      final uri = Uri.parse(checkoutUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Failed to launch checkout URL');
      }

      return true;
    } catch (e) {
      debugPrint('Stripe purchase error: $e');
      rethrow;
    }
  }

  // Create boost session and launch
  Future<bool> purchaseBoost({
    required String userId,
    required String stationId,
    required BoostType boostType,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final sessionData = await _premiumRepository.createBoostSession(
        userId: userId,
        stationId: stationId,
        boostType: boostType,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      final checkoutUrl = sessionData['checkout_url'] as String;
      final uri = Uri.parse(checkoutUrl);
      
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Failed to launch boost checkout URL');
      }

      return true;
    } catch (e) {
      debugPrint('Boost purchase error: $e');
      rethrow;
    }
  }

  // Open customer portal for subscription management
  Future<bool> openCustomerPortal({
    required String userId,
    String? returnUrl,
  }) async {
    try {
      final portalUrl = await _premiumRepository.createCustomerPortalSession(
        userId: userId,
        returnUrl: returnUrl,
      );

      final uri = Uri.parse(portalUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Failed to launch customer portal');
      }

      return true;
    } catch (e) {
      debugPrint('Customer portal error: $e');
      rethrow;
    }
  }

  // Handle successful payment return
  Future<void> handlePaymentSuccess(String userId) async {
    try {
      // Refresh user premium status
      // This will be handled by the webhook automatically
      // But we can force a refresh here
      await _premiumRepository.getUserPremiumStatus(userId);
      
      debugPrint('Payment success handled for user: $userId');
    } catch (e) {
      debugPrint('Error handling payment success: $e');
    }
  }

  // Handle payment cancellation
  Future<void> handlePaymentCancel() async {
    debugPrint('Payment was canceled by user');
  }

  // Get premium plans configuration
  List<PremiumPlan> getPremiumPlans() {
    return [
      const PremiumPlan(
        id: 'premium_monthly',
        name: 'Premium Mensuel',
        description: 'Accès complet à toutes les fonctionnalités premium',
        priceMonthly: 999, // €9.99
        priceYearly: 9999, // Not applicable for monthly
        currency: 'EUR',
        features: [
          'Swipes illimités',
          'Messages illimités',
          'Voir qui vous a liké',
          'Mode invisible',
          'Filtres avancés',
          'Statistiques détaillées',
          '1 boost gratuit par mois',
        ],
        isPopular: false,
        stripePriceIdMonthly: 'price_monthly_premium',
      ),
      const PremiumPlan(
        id: 'premium_seasonal',
        name: 'Premium Saison',
        description: 'Parfait pour toute la saison de ski',
        priceMonthly: 799, // €7.99/month equivalent
        priceYearly: 3999, // €39.99 for 5 months
        currency: 'EUR',
        features: [
          'Tous les avantages Premium',
          'Économie de 20%',
          'Boosts gratuits inclus',
          'Support prioritaire',
          'Statistiques saison complète',
          'Historique détaillé',
        ],
        isPopular: true,
        stripePriceIdYearly: 'price_seasonal_premium',
      ),
    ];
  }

  // Get boost options
  List<BoostType> getBoostOptions() {
    return BoostType.values;
  }
}
