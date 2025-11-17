import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'stripe_service.dart';
import 'in_app_purchase_service.dart';
import '../models/subscription.dart';
import '../repositories/premium_repository.dart';

enum PaymentMethod { stripe, inAppPurchase, auto }

class PaymentService {
  final StripeService _stripeService;
  final InAppPurchaseService _inAppPurchaseService;
  final PremiumRepository _premiumRepository;
  
  PaymentService(
    this._stripeService,
    this._inAppPurchaseService,
    this._premiumRepository,
  );

  // Determine best payment method for platform
  PaymentMethod getBestPaymentMethod() {
    if (kIsWeb) return PaymentMethod.stripe;
    if (Platform.isIOS || Platform.isAndroid) {
      return PaymentMethod.inAppPurchase; // Preferred for mobile
    }
    return PaymentMethod.stripe;
  }

  // Purchase premium with auto method selection
  Future<bool> purchasePremium({
    required String userId,
    required String planId,
    PaymentMethod? method,
  }) async {
    final paymentMethod = method ?? getBestPaymentMethod();
    
    switch (paymentMethod) {
      case PaymentMethod.stripe:
        return _purchasePremiumStripe(userId, planId);
        
      case PaymentMethod.inAppPurchase:
        return _purchasePremiumInApp(userId, planId);
        
      case PaymentMethod.auto:
        return purchasePremium(userId: userId, planId: planId); // Recursive with auto-selection
    }
  }

  // Purchase boost with auto method selection
  Future<bool> purchaseBoost({
    required String userId,
    required String stationId,
    required BoostType boostType,
    PaymentMethod? method,
  }) async {
    final paymentMethod = method ?? getBestPaymentMethod();
    
    switch (paymentMethod) {
      case PaymentMethod.stripe:
        return _purchaseBoostStripe(userId, stationId, boostType);
        
      case PaymentMethod.inAppPurchase:
        return _purchaseBoostInApp(userId, stationId, boostType);
        
      case PaymentMethod.auto:
        return purchaseBoost(
          userId: userId, 
          stationId: stationId, 
          boostType: boostType,
        );
    }
  }

  // Stripe implementation
  Future<bool> _purchasePremiumStripe(String userId, String planId) async {
    try {
      final priceId = _getPriceIdForPlan(planId);
      return await _stripeService.purchasePremium(
        userId: userId,
        priceId: priceId,
      );
    } catch (e) {
      debugPrint('Stripe premium purchase error: $e');
      rethrow;
    }
  }

  Future<bool> _purchaseBoostStripe(String userId, String stationId, BoostType boostType) async {
    try {
      return await _stripeService.purchaseBoost(
        userId: userId,
        stationId: stationId,
        boostType: boostType,
      );
    } catch (e) {
      debugPrint('Stripe boost purchase error: $e');
      rethrow;
    }
  }

  // In-App Purchase implementation
  Future<bool> _purchasePremiumInApp(String userId, String planId) async {
    try {
      final productId = _getProductIdForPlan(planId);
      return await _inAppPurchaseService.purchasePremiumSubscription(
        productId: productId,
        userId: userId,
      );
    } catch (e) {
      debugPrint('In-app premium purchase error: $e');
      rethrow;
    }
  }

  Future<bool> _purchaseBoostInApp(String userId, String stationId, BoostType boostType) async {
    try {
      final productId = _getBoostProductId(boostType);
      return await _inAppPurchaseService.purchaseBoost(
        productId: productId,
        userId: userId,
        stationId: stationId,
      );
    } catch (e) {
      debugPrint('In-app boost purchase error: $e');
      rethrow;
    }
  }

  // Restore purchases (primarily for iOS)
  Future<void> restorePurchases() async {
    try {
      if (getBestPaymentMethod() == PaymentMethod.inAppPurchase) {
        await _inAppPurchaseService.restorePurchases();
      } else {
        // For Stripe, we can check existing subscriptions
        debugPrint('Stripe purchases are automatically restored via account');
      }
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      rethrow;
    }
  }

  // Handle purchase updates (for in-app purchases)
  void handlePurchaseUpdate(List<PurchaseDetails> purchases, String userId) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
          _handleSuccessfulPurchase(purchase, userId);
          break;
        case PurchaseStatus.error:
          _handlePurchaseError(purchase);
          break;
        case PurchaseStatus.pending:
          _handlePendingPurchase(purchase);
          break;
        case PurchaseStatus.canceled:
          _handleCanceledPurchase(purchase);
          break;
        case PurchaseStatus.restored:
          _handleRestoredPurchase(purchase, userId);
          break;
      }
    }
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchase, String userId) async {
    try {
      debugPrint('Purchase successful: ${purchase.productID}');
      
      // Complete the purchase on backend
      await _inAppPurchaseService.completePurchase(
        purchase: purchase,
        userId: userId,
      );

      // Refresh premium status
      // This will be handled by real-time subscriptions or manual refresh
    } catch (e) {
      debugPrint('Error handling successful purchase: $e');
    }
  }

  void _handlePurchaseError(PurchaseDetails purchase) {
    debugPrint('Purchase error: ${purchase.error}');
    if (purchase.error != null) {
      _inAppPurchaseService.handlePurchaseError(purchase.error!);
    }
  }

  void _handlePendingPurchase(PurchaseDetails purchase) {
    debugPrint('Purchase pending: ${purchase.productID}');
    // Show loading state or pending message
  }

  void _handleCanceledPurchase(PurchaseDetails purchase) {
    debugPrint('Purchase canceled: ${purchase.productID}');
  }

  void _handleRestoredPurchase(PurchaseDetails purchase, String userId) async {
    debugPrint('Purchase restored: ${purchase.productID}');
    // Treat as successful purchase
    _handleSuccessfulPurchase(purchase, userId);
  }

  // Helper methods
  String _getPriceIdForPlan(String planId) {
    switch (planId) {
      case 'premium_monthly':
        return 'price_monthly_premium';
      case 'premium_seasonal':
        return 'price_seasonal_premium';
      default:
        throw Exception('Unknown plan ID: $planId');
    }
  }

  String _getProductIdForPlan(String planId) {
    return planId; // Same as plan ID for simplicity
  }

  String _getBoostProductId(BoostType boostType) {
    switch (boostType) {
      case BoostType.hourly:
        return 'boost_1hour';
      case BoostType.daily:
        return 'boost_24hour';
      case BoostType.weekly:
        return 'boost_1week';
    }
  }

  // Check if in-app purchases are supported
  bool get isInAppPurchaseSupported {
    return Platform.isIOS || Platform.isAndroid;
  }

  // Check if Stripe is required (web or fallback)
  bool get isStripeRequired {
    return kIsWeb || !isInAppPurchaseSupported;
  }
}

// Riverpod provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  final premiumRepository = ref.read(premiumRepositoryProvider);
  final stripeService = StripeService(premiumRepository);
  final inAppPurchaseService = InAppPurchaseService(premiumRepository);
  
  return PaymentService(stripeService, inAppPurchaseService, premiumRepository);
});

// Payment state management
class PaymentState {
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final List<ProductDetails> products;

  PaymentState({
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.products = const [],
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    bool? isInitialized,
    List<ProductDetails>? products,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
      products: products ?? this.products,
    );
  }
}
