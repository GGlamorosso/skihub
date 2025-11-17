import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../widgets/quota_indicator.dart';
import '../widgets/premium_screen.dart';
import 'quota_service.dart';

class QuotaManager {
  static bool _isModalShown = false;
  
  // Hook for swipe actions
  static Future<bool> checkSwipeQuota({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required String targetUserId,
  }) async {
    try {
      // Reset modal flag for new day
      final now = DateTime.now();
      final lastReset = DateTime(now.year, now.month, now.day);
      if (now.isAfter(lastReset.add(const Duration(days: 1)))) {
        _isModalShown = false;
      }

      final quotaService = ref.read(quotaServiceProvider);
      final result = await quotaService.checkActionQuota(userId, 'swipe');
      
      // Update quota state
      ref.read(userQuotaStateProvider(userId).notifier).updateQuota(result.quotaInfo);
      
      if (!result.allowed && !_isModalShown && context.mounted) {
        _isModalShown = true;
        _showQuotaModal(context, result.quotaInfo, 'swipe');
        return false;
      }
      
      return result.allowed;
    } catch (e) {
      debugPrint('Error checking swipe quota: $e');
      return true; // Allow on error
    }
  }

  // Hook for message actions
  static Future<bool> checkMessageQuota({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required String matchId,
  }) async {
    try {
      final quotaService = ref.read(quotaServiceProvider);
      final result = await quotaService.checkActionQuota(userId, 'message');
      
      // Update quota state
      ref.read(userQuotaStateProvider(userId).notifier).updateQuota(result.quotaInfo);
      
      if (!result.allowed && context.mounted) {
        _showQuotaModal(context, result.quotaInfo, 'message');
        return false;
      }
      
      return result.allowed;
    } catch (e) {
      debugPrint('Error checking message quota: $e');
      return true; // Allow on error
    }
  }

  // Show quota limit modal
  static void _showQuotaModal(
    BuildContext context, 
    QuotaInfo quotaInfo, 
    String action,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuotaModal(
        userId: 'current-user-id', // Get from auth
        quotaInfo: quotaInfo,
        onUpgradeTapped: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PremiumScreen(),
            ),
          );
        },
      ),
    );
  }

  // Show quota toast for messages
  static void showMessageQuotaToast(BuildContext context, QuotaInfo quotaInfo) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.message, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Limite de ${quotaInfo.messageRemaining} messages atteinte. '
                'Renouvellement dans ${quotaInfo.resetTimeDisplay}',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[600],
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Premium',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PremiumScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  // Insert feed card for premium upgrade
  static Widget buildPremiumFeedCard() {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.star_border,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Passez Premium pour continuer à swiper',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Swipes illimités, voir qui vous a liké, et bien plus',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to premium screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Voir les plans Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reset modal flag (call when switching days)
  static void resetModalFlag() {
    _isModalShown = false;
  }
}
