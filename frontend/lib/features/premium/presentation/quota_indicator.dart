import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/subscription.dart';
import '../controllers/premium_controller.dart';

class QuotaIndicator extends ConsumerWidget {
  final QuotaType quotaType;
  final bool showLabel;
  final bool compact;

  const QuotaIndicator({
    Key? key,
    required this.quotaType,
    this.showLabel = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotaInfo = ref.watch(quotaInfoProvider);
    final isPremium = ref.watch(isPremiumProvider);
    
    if (isPremium || quotaInfo == null) {
      return _buildPremiumIndicator();
    }

    return _buildQuotaProgress(context, quotaInfo);
  }

  Widget _buildPremiumIndicator() {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.diamond,
            color: AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Premium',
            style: AppTypography.caption.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond, color: AppColors.warning, size: 16),
          const SizedBox(width: 6),
          Text(
            'Illimité',
            style: AppTypography.caption.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaProgress(BuildContext context, QuotaInfo quotaInfo) {
    final remaining = quotaType == QuotaType.swipe 
        ? quotaInfo.swipeRemaining 
        : quotaInfo.messageRemaining;
    final total = quotaType == QuotaType.swipe 
        ? quotaInfo.dailySwipeLimit 
        : quotaInfo.dailyMessageLimit;
    final progress = remaining / total;
    
    final color = _getProgressColor(progress);
    final label = quotaType == QuotaType.swipe ? 'Likes' : 'Messages';

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 4,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$remaining',
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$label restants',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$remaining / $total',
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
        
        if (showLabel && remaining <= 5) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.warning_amber,
                color: AppColors.warning,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Limite bientôt atteinte',
                style: AppTypography.caption.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
        
        if (showLabel && remaining == 0) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.block,
                color: AppColors.error,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Limite atteinte - Reset ${_formatTimeUntilReset(quotaInfo.resetsAt)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress > 0.5) return AppColors.success;
    if (progress > 0.2) return AppColors.warning;
    return AppColors.error;
  }

  String _formatTimeUntilReset(DateTime resetTime) {
    final now = DateTime.now();
    final difference = resetTime.difference(now);
    
    if (difference.inHours > 0) {
      return 'dans ${difference.inHours}h${difference.inMinutes % 60}min';
    } else {
      return 'dans ${difference.inMinutes}min';
    }
  }
}

// Quota warning widget for feed
class QuotaWarningCard extends ConsumerWidget {
  final QuotaType quotaType;

  const QuotaWarningCard({
    Key? key,
    required this.quotaType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotaInfo = ref.watch(quotaInfoProvider);
    final isPremium = ref.watch(isPremiumProvider);
    
    if (isPremium || quotaInfo == null) {
      return const SizedBox.shrink();
    }

    final isLimitReached = quotaType == QuotaType.swipe 
        ? quotaInfo.swipeRemaining <= 0
        : quotaInfo.messageRemaining <= 0;

    if (!isLimitReached) {
      return const SizedBox.shrink();
    }

    final actionText = quotaType == QuotaType.swipe ? 'liker' : 'envoyer des messages';
    final limitText = quotaType == QuotaType.swipe 
        ? '${quotaInfo.dailySwipeLimit} likes'
        : '${quotaInfo.dailyMessageLimit} messages';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.diamond, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Limite atteinte',
                      style: AppTypography.subtitle1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Vous avez atteint votre limite de $limitText par jour',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Plus tard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'Devenir Premium',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PremiumScreen(
                          fromQuotaLimit: true,
                          limitType: quotaType,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
