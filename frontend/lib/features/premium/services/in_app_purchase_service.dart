import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import '../repositories/premium_repository.dart';
import '../models/subscription.dart';

class InAppPurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final PremiumRepository _premiumRepository;
  
  InAppPurchaseService(this._premiumRepository);

  static const Set<String> _productIds = {
    // Subscriptions
    'premium_monthly',
    'premium_seasonal',
    // Boosts (one-time purchases)
    'boost_1hour',
    'boost_24hour', 
    'boost_1week',
  };

  Future<bool> initialize() async {
    try {
      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('In-app purchases not available');
        return false;
      }

      // Enable pending purchases on Android
      if (Platform.isAndroid) {
        final androidAddition = _inAppPurchase.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        androidAddition.enablePendingPurchases();
      }

      return true;
    } catch (e) {
      debugPrint('Error initializing in-app purchases: $e');
      return false;
    }
  }

  // Get available products
  Future<List<ProductDetails>> getAvailableProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails(_productIds);
      
      if (response.error != null) {
        throw Exception('Failed to query products: ${response.error}');
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      return response.productDetails;
    } catch (e) {
      debugPrint('Error getting available products: $e');
      rethrow;
    }
  }

  // Purchase premium subscription
  Future<bool> purchasePremiumSubscription({
    required String productId,
    required String userId,
  }) async {
    try {
      final products = await getAvailableProducts();
      final product = products.where((p) => p.id == productId).firstOrNull;

      if (product == null) {
        throw Exception('Product not found: $productId');
      }

      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: userId, // Important for server-side validation
      );

      final result = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return result;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      rethrow;
    }
  }

  // Purchase boost (consumable)
  Future<bool> purchaseBoost({
    required String productId,
    required String userId,
    required String stationId,
  }) async {
    try {
      final products = await getAvailableProducts();
      final product = products.where((p) => p.id == productId).firstOrNull;

      if (product == null) {
        throw Exception('Product not found: $productId');
      }

      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: userId,
      );

      final result = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      return result;
    } catch (e) {
      debugPrint('Error purchasing boost: $e');
      rethrow;
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      rethrow;
    }
  }

  // Handle purchase updates
  Stream<List<PurchaseDetails>> get purchaseStream => _inAppPurchase.purchaseStream;

  // Verify and complete purchase
  Future<void> completePurchase({
    required PurchaseDetails purchase,
    required String userId,
  }) async {
    try {
      if (purchase.pendingCompletePurchase) {
        // Verify purchase on backend
        final isValid = await _verifyPurchaseOnBackend(purchase, userId);
        
        if (isValid) {
          // Complete the purchase
          await _inAppPurchase.completePurchase(purchase);
          
          // Update local premium status
          // This will be done via real-time subscription or polling
          debugPrint('Purchase completed successfully: ${purchase.productID}');
        } else {
          throw Exception('Purchase verification failed');
        }
      }
    } catch (e) {
      debugPrint('Error completing purchase: $e');
      rethrow;
    }
  }

  // Verify purchase on backend
  Future<bool> _verifyPurchaseOnBackend(PurchaseDetails purchase, String userId) async {
    try {
      // This would call a backend function to verify the receipt
      // with Apple/Google and activate the premium features
      
      final response = await _premiumRepository._supabase.functions.invoke(
        'verify-purchase',
        body: {
          'user_id': userId,
          'product_id': purchase.productID,
          'purchase_token': purchase.verificationData.serverVerificationData,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );

      if (response.error != null) {
        throw Exception('Verification failed: ${response.error}');
      }

      return response.data['valid'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error verifying purchase: $e');
      return false;
    }
  }

  // Handle purchase errors
  void handlePurchaseError(IAPError error) {
    debugPrint('Purchase error: ${error.code} - ${error.message}');
    
    switch (error.code) {
      case 'user_cancelled':
        debugPrint('User cancelled the purchase');
        break;
      case 'network_error':
        debugPrint('Network error during purchase');
        break;
      case 'item_unavailable':
        debugPrint('Product is not available');
        break;
      case 'payment_invalid':
        debugPrint('Payment method is invalid');
        break;
      default:
        debugPrint('Unknown purchase error: ${error.message}');
    }
  }

  // Get product display info
  Map<String, dynamic> getProductDisplayInfo(ProductDetails product) {
    return {
      'id': product.id,
      'title': product.title,
      'description': product.description,
      'price': product.price,
      'currency': product.currencyCode,
      'currency_symbol': product.currencySymbol,
    };
  }

  // Check if product is subscription
  bool isSubscriptionProduct(String productId) {
    return productId.contains('premium');
  }

  // Check if product is consumable (boost)
  bool isConsumableProduct(String productId) {
    return productId.contains('boost');
  }

  void dispose() {
    // Clean up any listeners if needed
  }
}
