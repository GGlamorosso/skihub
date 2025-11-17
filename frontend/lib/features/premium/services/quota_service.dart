import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/premium_repository.dart';
import '../models/subscription.dart';

part 'quota_service.g.dart';

class QuotaService {
  final PremiumRepository _premiumRepository;
  
  QuotaService(this._premiumRepository);

  // Check if action is allowed and return quota info
  Future<QuotaResult> checkActionQuota(String userId, String action) async {
    try {
      final quotaInfo = await _premiumRepository.checkQuota(userId, action);
      
      return QuotaResult(
        allowed: !quotaInfo.limitReached,
        quotaInfo: quotaInfo,
      );
    } catch (e) {
      debugPrint('Error checking quota: $e');
      // On error, allow the action but log it
      return QuotaResult(
        allowed: true,
        quotaInfo: QuotaInfo(
          swipeRemaining: -1,
          messageRemaining: -1,
          limitReached: false,
          resetsAt: DateTime.now().add(const Duration(hours: 24)),
          isPremium: false,
        ),
        error: e.toString(),
      );
    }
  }

  // Get daily usage summary
  Future<Map<String, dynamic>> getDailyUsageSummary(String userId) async {
    try {
      final quotaInfo = await _premiumRepository.checkQuota(userId, 'summary');
      
      return {
        'swipes_used': quotaInfo.isPremium ? 'Illimité' : '${20 - quotaInfo.swipeRemaining}/20',
        'messages_used': quotaInfo.isPremium ? 'Illimité' : '${10 - quotaInfo.messageRemaining}/10',
        'resets_in': quotaInfo.resetTimeDisplay,
        'is_premium': quotaInfo.isPremium,
      };
    } catch (e) {
      debugPrint('Error getting usage summary: $e');
      return {
        'swipes_used': 'Erreur',
        'messages_used': 'Erreur', 
        'resets_in': 'N/A',
        'is_premium': false,
      };
    }
  }
}

class QuotaResult {
  final bool allowed;
  final QuotaInfo quotaInfo;
  final String? error;

  QuotaResult({
    required this.allowed,
    required this.quotaInfo,
    this.error,
  });

  bool get hasError => error != null;
}

// Riverpod providers
@riverpod
QuotaService quotaService(QuotaServiceRef ref) {
  final premiumRepository = ref.read(premiumRepositoryProvider);
  return QuotaService(premiumRepository);
}

@riverpod
PremiumRepository premiumRepository(PremiumRepositoryRef ref) {
  return PremiumRepository();
}

@riverpod
class UserQuotaState extends _$UserQuotaState {
  @override
  QuotaInfo? build(String userId) {
    // Initial state
    return null;
  }

  Future<void> checkQuota(String action) async {
    try {
      final quotaService = ref.read(quotaServiceProvider);
      final result = await quotaService.checkActionQuota(userId, action);
      state = result.quotaInfo;
    } catch (e) {
      debugPrint('Error updating quota state: $e');
    }
  }

  Future<bool> canPerformAction(String action) async {
    try {
      final quotaService = ref.read(quotaServiceProvider);
      final result = await quotaService.checkActionQuota(userId, action);
      state = result.quotaInfo;
      return result.allowed;
    } catch (e) {
      debugPrint('Error checking action quota: $e');
      return true; // Allow action on error
    }
  }

  void updateQuota(QuotaInfo newQuotaInfo) {
    state = newQuotaInfo;
  }
}

@riverpod
class UserPremiumState extends _$UserPremiumState {
  @override
  AsyncValue<bool> build(String userId) {
    // Start with loading state
    return const AsyncValue.loading();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final premiumRepository = ref.read(premiumRepositoryProvider);
      final isPremium = await premiumRepository.getUserPremiumStatus(userId);
      state = AsyncValue.data(isPremium);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updatePremiumStatus(bool isPremium) async {
    state = AsyncValue.data(isPremium);
  }
}

@riverpod
class UserSubscriptionState extends _$UserSubscriptionState {
  @override
  AsyncValue<Subscription?> build(String userId) {
    return const AsyncValue.loading();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final premiumRepository = ref.read(premiumRepositoryProvider);
      final subscription = await premiumRepository.getUserSubscription(userId);
      state = AsyncValue.data(subscription);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void updateSubscription(Subscription? subscription) {
    state = AsyncValue.data(subscription);
  }
}
