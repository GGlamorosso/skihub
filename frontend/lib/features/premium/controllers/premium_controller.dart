import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../models/subscription.dart';
import '../../../services/premium_repository.dart';
import '../../../services/stripe_service.dart';
import '../../../services/quota_service.dart';
import '../../../utils/error_handler.dart';

part 'premium_controller.freezed.dart';

// Premium state
@freezed
class PremiumState with _$PremiumState {
  const factory PremiumState({
    @Default(false) bool isPremium,
    @Default(false) bool isLoading,
    Subscription? subscription,
    @Default([]) List<Boost> activeBoosts,
    QuotaInfo? quotaInfo,
    String? error,
    @Default(false) bool showPaywall,
    @Default(false) bool quotaModalShown,
  }) = _PremiumState;
}

// Premium controller
class PremiumController extends StateNotifier<PremiumState> {
  final PremiumRepository _premiumRepository;
  final StripeService _stripeService;
  final QuotaService _quotaService;
  
  PremiumController({
    required PremiumRepository premiumRepository,
    required StripeService stripeService,
    required QuotaService quotaService,
  }) : _premiumRepository = premiumRepository,
       _stripeService = stripeService,
       _quotaService = quotaService,
       super(const PremiumState());

  // Initialize premium state
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await Future.wait([
        _loadPremiumStatus(),
        _loadSubscription(),
        _loadActiveBoosts(),
        _loadQuotaInfo(),
      ]);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load premium data: $e',
        isLoading: false,
      );
    }
  }

  // Load premium status
  Future<void> _loadPremiumStatus() async {
    try {
      final isPremium = await _premiumRepository.isPremiumActive();
      state = state.copyWith(isPremium: isPremium);
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to load premium status', error: e);
    }
  }

  // Load subscription
  Future<void> _loadSubscription() async {
    try {
      final subscription = await _premiumRepository.getCurrentSubscription();
      state = state.copyWith(subscription: subscription);
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to load subscription', error: e);
    }
  }

  // Load active boosts
  Future<void> _loadActiveBoosts() async {
    try {
      final boosts = await _premiumRepository.getActiveBoosts();
      state = state.copyWith(activeBoosts: boosts);
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to load active boosts', error: e);
    }
  }

  // Load quota information
  Future<void> _loadQuotaInfo() async {
    try {
      final quotaInfo = await _quotaService.getQuotaInfo();
      state = state.copyWith(quotaInfo: quotaInfo, isLoading: false);
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to load quota info', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  // Check if action is allowed and handle quota
  Future<bool> checkActionQuota(QuotaType actionType) async {
    try {
      final quotaInfo = state.quotaInfo;
      if (quotaInfo == null) {
        await _loadQuotaInfo();
        return false;
      }

      switch (actionType) {
        case QuotaType.swipe:
          if (!quotaInfo.hasSwipes && !state.quotaModalShown) {
            _showQuotaModal(QuotaType.swipe);
            return false;
          }
          return quotaInfo.hasSwipes;
          
        case QuotaType.message:
          if (!quotaInfo.hasMessages && !state.quotaModalShown) {
            _showQuotaModal(QuotaType.message);
            return false;
          }
          return quotaInfo.hasMessages;
          
        case QuotaType.none:
          return true;
      }
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to check action quota', error: e);
      return false;
    }
  }

  // Show quota reached modal
  void _showQuotaModal(QuotaType quotaType) {
    state = state.copyWith(
      showPaywall: true,
      quotaModalShown: true,
    );
  }

  // Update quota info from enhanced response
  void updateQuotaFromResponse(Map<String, dynamic> response) {
    try {
      final quotaInfo = _quotaService.parseQuotaFromResponse(response);
      state = state.copyWith(quotaInfo: quotaInfo);
      
      // Check if limit was just reached
      if (quotaInfo.limitReached && !state.quotaModalShown) {
        _showQuotaModal(quotaInfo.limitType);
      }
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to update quota from response', error: e);
    }
  }

  // Purchase premium subscription
  Future<bool> purchasePremium(String priceId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Ensure customer exists
      await _stripeService.getOrCreateStripeCustomer();
      
      // Create checkout session
      final checkoutUrl = await _stripeService.createSubscriptionCheckout(
        priceId: priceId,
      );
      
      if (checkoutUrl == null) {
        throw Exception('Failed to create checkout session');
      }

      // Launch checkout
      final success = await _stripeService.launchCheckout(checkoutUrl);
      
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to start premium purchase: $e',
        isLoading: false,
      );
      return false;
    }
  }

  // Purchase boost
  Future<bool> purchaseBoost({
    required String boostType,
    required String stationId,
    int? durationHours,
    double? multiplier,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Create boost checkout session
      final checkoutUrl = await _stripeService.createBoostCheckout(
        boostType: boostType,
        stationId: stationId,
        durationHours: durationHours,
        multiplier: multiplier,
      );
      
      if (checkoutUrl == null) {
        throw Exception('Failed to create boost checkout session');
      }

      // Launch checkout
      final success = await _stripeService.launchCheckout(checkoutUrl);
      
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to start boost purchase: $e',
        isLoading: false,
      );
      return false;
    }
  }

  // Handle payment success
  Future<void> handlePaymentSuccess({
    required String sessionId,
    String? type = 'subscription',
  }) async {
    try {
      await _stripeService.handlePaymentSuccess(
        sessionId: sessionId,
        type: type,
      );
      
      // Refresh data after payment success
      await initialize();
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to handle payment success', error: e);
    }
  }

  // Handle payment cancellation
  Future<void> handlePaymentCancel({String? reason}) async {
    try {
      await _stripeService.handlePaymentCancel(reason: reason);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to handle payment cancel', error: e);
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _stripeService.cancelSubscription();
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to cancel subscription: $e',
        isLoading: false,
      );
      return false;
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _stripeService.restorePurchases();
      await initialize(); // Refresh all data
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to restore purchases: $e',
        isLoading: false,
      );
    }
  }

  // Hide paywall
  void hidePaywall() {
    state = state.copyWith(showPaywall: false);
  }

  // Reset quota modal shown flag (for next day)
  void resetQuotaModalFlag() {
    state = state.copyWith(quotaModalShown: false);
  }

  // Refresh all premium data
  Future<void> refresh() async {
    await initialize();
  }

  // Get time until quota reset
  Duration getTimeUntilQuotaReset() {
    final quotaInfo = state.quotaInfo;
    if (quotaInfo == null) return Duration.zero;
    
    final now = DateTime.now();
    return quotaInfo.resetsAt.difference(now);
  }
}

// Providers
final premiumRepositoryProvider = Provider<PremiumRepository>((ref) {
  return PremiumRepository();
});

final stripeServiceProvider = Provider<StripeService>((ref) {
  return StripeService();
});

final quotaServiceProvider = Provider<QuotaService>((ref) {
  final premiumRepository = ref.read(premiumRepositoryProvider);
  return QuotaService(premiumRepository: premiumRepository);
});

final premiumControllerProvider = StateNotifierProvider<PremiumController, PremiumState>((ref) {
  final premiumRepository = ref.read(premiumRepositoryProvider);
  final stripeService = ref.read(stripeServiceProvider);
  final quotaService = ref.read(quotaServiceProvider);
  
  return PremiumController(
    premiumRepository: premiumRepository,
    stripeService: stripeService,
    quotaService: quotaService,
  );
});

// Computed providers
final isPremiumProvider = Provider<bool>((ref) {
  final premiumState = ref.watch(premiumControllerProvider);
  return premiumState.isPremium;
});

final quotaInfoProvider = Provider<QuotaInfo?>((ref) {
  final premiumState = ref.watch(premiumControllerProvider);
  return premiumState.quotaInfo;
});

final activeBoostsProvider = Provider<List<Boost>>((ref) {
  final premiumState = ref.watch(premiumControllerProvider);
  return premiumState.activeBoosts;
});

final showPaywallProvider = Provider<bool>((ref) {
  final premiumState = ref.watch(premiumControllerProvider);
  return premiumState.showPaywall;
});
