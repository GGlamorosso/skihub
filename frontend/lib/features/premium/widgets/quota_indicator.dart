import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../services/quota_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class QuotaIndicator extends ConsumerWidget {
  final String userId;
  final String type; // 'swipe' or 'message'
  final bool showText;

  const QuotaIndicator({
    super.key,
    required this.userId,
    required this.type,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotaState = ref.watch(userQuotaStateProvider(userId));

    if (quotaState == null) {
      return const SizedBox.shrink();
    }

    if (quotaState.isPremium) {
      return _buildPremiumIndicator();
    }

    final remaining = type == 'swipe' 
        ? quotaState.swipeRemaining 
        : quotaState.messageRemaining;
    final total = type == 'swipe' ? 20 : 10;
    final used = total - remaining;
    final progress = used / total;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getProgressColor(progress).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getProgressColor(progress).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type == 'swipe' ? Icons.favorite : Icons.message,
            size: 16,
            color: _getProgressColor(progress),
          ),
          if (showText) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$remaining/$total',
              style: TextStyle(
                fontSize: 12,
                color: _getProgressColor(progress),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 40,
            height: 4,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(_getProgressColor(progress)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 16,
            color: Colors.white,
          ),
          if (showText) ...[
            const SizedBox(width: AppSpacing.xs),
            const Text(
              'Premium',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.5) return Colors.green;
    if (progress < 0.8) return Colors.orange;
    return Colors.red;
  }
}

class QuotaModal extends ConsumerWidget {
  final String userId;
  final QuotaInfo quotaInfo;
  final VoidCallback? onUpgradeTapped;

  const QuotaModal({
    super.key,
    required this.userId,
    required this.quotaInfo,
    this.onUpgradeTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.block,
                size: 40,
                color: Colors.orange[600],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Title
            const Text(
              'Limite atteinte',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Message
            Text(
              quotaInfo.limitMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Reset time
            Text(
              'Renouvellement dans ${quotaInfo.resetTimeDisplay}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onUpgradeTapped?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Devenir Premium'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DailyUsageCard extends ConsumerWidget {
  final String userId;

  const DailyUsageCard({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotaState = ref.watch(userQuotaStateProvider(userId));

    if (quotaState == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Utilisation quotidienne',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (quotaState.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Swipes usage
            _buildUsageRow(
              icon: Icons.favorite,
              label: 'Swipes',
              remaining: quotaState.swipeRemaining,
              total: 20,
              isPremium: quotaState.isPremium,
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Messages usage
            _buildUsageRow(
              icon: Icons.message,
              label: 'Messages',
              remaining: quotaState.messageRemaining,
              total: 10,
              isPremium: quotaState.isPremium,
            ),
            
            if (!quotaState.isPremium) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Renouvellement dans ${quotaState.resetTimeDisplay}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow({
    required IconData icon,
    required String label,
    required int remaining,
    required int total,
    required bool isPremium,
  }) {
    if (isPremium) {
      return Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          const Text(
            'Illimité',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final used = total - remaining;
    final progress = used / total;

    return Row(
      children: [
        Icon(icon, size: 20, color: _getProgressColor(progress)),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(_getProgressColor(progress)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$remaining/$total',
          style: TextStyle(
            fontSize: 12,
            color: _getProgressColor(progress),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.5) return Colors.green;
    if (progress < 0.8) return Colors.orange;
    return Colors.red;
  }
}
