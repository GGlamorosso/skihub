import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../utils/error_handler.dart';
import '../services/premium_repository.dart';

class QuotaService {
  final SupabaseClient _supabase;
  final PremiumRepository _premiumRepository;
  
  QuotaService({
    SupabaseClient? supabase,
    PremiumRepository? premiumRepository,
  }) : _supabase = supabase ?? Supabase.instance.client,
        _premiumRepository = premiumRepository ?? PremiumRepository();

  // Free user daily limits
  static const int freeDailySwipeLimit = 20;
  static const int freeDailyMessageLimit = 50;
  
  // Premium user limits (much higher)
  static const int premiumDailySwipeLimit = 999;
  static const int premiumDailyMessageLimit = 999;

  // Get current quota status
  Future<QuotaInfo> getQuotaInfo() async {
    try {
      final isPremium = await _premiumRepository.isPremiumActive();
      
      if (isPremium) {
        // Premium users have effectively unlimited quotas
        return QuotaInfo(
          swipeRemaining: premiumDailySwipeLimit,
          messageRemaining: premiumDailyMessageLimit,
          limitReached: false,
          limitType: QuotaType.none,
          dailySwipeLimit: premiumDailySwipeLimit,
          dailyMessageLimit: premiumDailyMessageLimit,
          resetsAt: _getNextDayReset(),
        );
      }

      // Get usage from enhanced endpoints
      final swipeUsage = await _getSwipeUsageToday();
      final messageUsage = await _getMessageUsageToday();
      
      final swipeRemaining = (freeDailySwipeLimit - swipeUsage).clamp(0, freeDailySwipeLimit);
      final messageRemaining = (freeDailyMessageLimit - messageUsage).clamp(0, freeDailyMessageLimit);
      
      bool limitReached = false;
      QuotaType limitType = QuotaType.none;
      
      if (swipeRemaining <= 0) {
        limitReached = true;
        limitType = QuotaType.swipe;
      } else if (messageRemaining <= 0) {
        limitReached = true;
        limitType = QuotaType.message;
      }

      return QuotaInfo(
        swipeRemaining: swipeRemaining,
        messageRemaining: messageRemaining,
        limitReached: limitReached,
        limitType: limitType,
        dailySwipeLimit: freeDailySwipeLimit,
        dailyMessageLimit: freeDailyMessageLimit,
        resetsAt: _getNextDayReset(),
      );
    } catch (e) {
          ErrorHandler.logError(context: 'Failed to get quota info', error: e);
      // Return safe defaults
      return QuotaInfo(
        swipeRemaining: 0,
        messageRemaining: 0,
        limitReached: true,
        limitType: QuotaType.swipe,
        dailySwipeLimit: freeDailySwipeLimit,
        dailyMessageLimit: freeDailyMessageLimit,
        resetsAt: _getNextDayReset(),
      );
    }
  }

  // Check if user can perform swipe action
  Future<bool> canSwipe() async {
    try {
      final quotaInfo = await getQuotaInfo();
      return quotaInfo.hasSwipes;
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to check swipe quota', error: e);
      return false;
    }
  }

  // Check if user can send message
  Future<bool> canSendMessage() async {
    try {
      final quotaInfo = await getQuotaInfo();
      return quotaInfo.hasMessages;
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to check message quota', error: e);
      return false;
    }
  }

  // Parse quota info from enhanced endpoint response
  QuotaInfo parseQuotaFromResponse(Map<String, dynamic> response) {
    try {
      final quotaData = response['quota_info'] as Map<String, dynamic>?;
      if (quotaData == null) {
        // Fallback if quota_info not present
        return QuotaInfo(
          swipeRemaining: freeDailySwipeLimit,
          messageRemaining: freeDailyMessageLimit,
          limitReached: false,
          limitType: QuotaType.none,
          dailySwipeLimit: freeDailySwipeLimit,
          dailyMessageLimit: freeDailyMessageLimit,
          resetsAt: _getNextDayReset(),
        );
      }

      return QuotaInfo.fromJson(quotaData);
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to parse quota info', error: e);
      // Return conservative defaults
      return QuotaInfo(
        swipeRemaining: 0,
        messageRemaining: 0,
        limitReached: true,
        limitType: QuotaType.swipe,
        dailySwipeLimit: freeDailySwipeLimit,
        dailyMessageLimit: freeDailyMessageLimit,
        resetsAt: _getNextDayReset(),
      );
    }
  }

  // Get swipe usage today (fallback method)
  Future<int> _getSwipeUsageToday() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await _supabase
          .from('likes')
          .select('id')
          .eq('liker_id', userId)
          .gte('created_at', startOfDay.toIso8601String());

      return response.length;
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to get swipe usage', error: e);
      return freeDailySwipeLimit; // Assume limit reached on error
    }
  }

  // Get message usage today (fallback method)
  Future<int> _getMessageUsageToday() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('sender_id', userId)
          .gte('created_at', startOfDay.toIso8601String());

      return response.length;
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to get message usage', error: e);
      return freeDailyMessageLimit; // Assume limit reached on error
    }
  }

  // Get next day reset time
  DateTime _getNextDayReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow;
  }

  // Check quota before action and return appropriate response
  Future<QuotaCheckResult> checkQuotaForSwipe() async {
    try {
      final quotaInfo = await getQuotaInfo();
      
      if (quotaInfo.hasSwipes) {
        return QuotaCheckResult.allowed(quotaInfo);
      } else {
        return QuotaCheckResult.blocked(
          quotaInfo,
          'Vous avez atteint votre limite de ${quotaInfo.dailySwipeLimit} likes par jour.',
        );
      }
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to check swipe quota', error: e);
      return QuotaCheckResult.error('Erreur lors de la vérification des quotas');
    }
  }

  // Check quota before sending message
  Future<QuotaCheckResult> checkQuotaForMessage() async {
    try {
      final quotaInfo = await getQuotaInfo();
      
      if (quotaInfo.hasMessages) {
        return QuotaCheckResult.allowed(quotaInfo);
      } else {
        return QuotaCheckResult.blocked(
          quotaInfo,
          'Vous avez atteint votre limite de ${quotaInfo.dailyMessageLimit} messages par jour.',
        );
      }
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to check message quota', error: e);
      return QuotaCheckResult.error('Erreur lors de la vérification des quotas');
    }
  }

  // Get quota usage statistics for analytics
  Future<Map<String, dynamic>> getQuotaUsageStats({int days = 7}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      // Get daily usage for the period
      final response = await _supabase.functions.invoke(
        'get-quota-usage-stats',
        body: {
          'user_id': userId,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      return response.data as Map<String, dynamic>? ?? {};
    } catch (e) {
      ErrorHandler.logError(context: 'Failed to get quota usage stats', error: e);
      return {};
    }
  }
}

// Result class for quota checks
class QuotaCheckResult {
  final bool isAllowed;
  final QuotaInfo? quotaInfo;
  final String? message;
  final String? error;

  const QuotaCheckResult._({
    required this.isAllowed,
    this.quotaInfo,
    this.message,
    this.error,
  });

  factory QuotaCheckResult.allowed(QuotaInfo quotaInfo) => 
      QuotaCheckResult._(isAllowed: true, quotaInfo: quotaInfo);

  factory QuotaCheckResult.blocked(QuotaInfo quotaInfo, String message) => 
      QuotaCheckResult._(
        isAllowed: false, 
        quotaInfo: quotaInfo, 
        message: message,
      );

  factory QuotaCheckResult.error(String error) => 
      QuotaCheckResult._(isAllowed: false, error: error);
}
