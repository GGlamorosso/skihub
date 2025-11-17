import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/subscription.dart';
import '../../../components/buttons.dart';
import 'premium_screen.dart';

class QuotaModal extends ConsumerWidget {
  final QuotaInfo quotaInfo;
  final QuotaType limitType;
  final VoidCallback? onDismiss;

  const QuotaModal({
    Key? key,
    required this.quotaInfo,
    required this.limitType,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon and title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getLimitColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getLimitIcon(),
                color: _getLimitColor(),
                size: 32,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              _getLimitTitle(),
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              _getLimitMessage(),
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Quota progress
            _buildQuotaProgress(),
            
            const SizedBox(height: 24),
            
            // Reset time info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.refresh,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Reset ${_formatTimeUntilReset()}',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Devenir Premium',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PremiumScreen(
                            fromQuotaLimit: true,
                            limitType: limitType,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDismiss?.call();
                    },
                    child: const Text('Continuer avec la limite'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaProgress() {
    final remaining = limitType == QuotaType.swipe 
        ? quotaInfo.swipeRemaining 
        : quotaInfo.messageRemaining;
    final total = limitType == QuotaType.swipe 
        ? quotaInfo.dailySwipeLimit 
        : quotaInfo.dailyMessageLimit;
    final used = total - remaining;
    final progress = used / total;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Utilisé aujourd\'hui',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$used / $total',
              style: AppTypography.caption.copyWith(
                color: _getLimitColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(_getLimitColor()),
          minHeight: 8,
        ),
      ],
    );
  }

  Color _getLimitColor() {
    switch (limitType) {
      case QuotaType.swipe:
        return AppColors.error;
      case QuotaType.message:
        return AppColors.info;
      case QuotaType.none:
        return AppColors.textSecondary;
    }
  }

  IconData _getLimitIcon() {
    switch (limitType) {
      case QuotaType.swipe:
        return Icons.favorite;
      case QuotaType.message:
        return Icons.message;
      case QuotaType.none:
        return Icons.block;
    }
  }

  String _getLimitTitle() {
    switch (limitType) {
      case QuotaType.swipe:
        return 'Limite de Likes Atteinte';
      case QuotaType.message:
        return 'Limite de Messages Atteinte';
      case QuotaType.none:
        return 'Limite Atteinte';
    }
  }

  String _getLimitMessage() {
    final remaining = limitType == QuotaType.swipe 
        ? quotaInfo.swipeRemaining 
        : quotaInfo.messageRemaining;
    final total = limitType == QuotaType.swipe 
        ? quotaInfo.dailySwipeLimit 
        : quotaInfo.dailyMessageLimit;

    if (limitType == QuotaType.swipe) {
      return 'Vous avez utilisé vos $total likes gratuits pour aujourd\'hui. Passez premium pour des likes illimités et bien plus encore !';
    } else {
      return 'Vous avez envoyé vos $total messages gratuits pour aujourd\'hui. Passez premium pour des messages illimités !';
    }
  }

  String _formatTimeUntilReset() {
    final now = DateTime.now();
    final resetTime = quotaInfo.resetsAt;
    final difference = resetTime.difference(now);
    
    if (difference.inHours > 0) {
      return 'dans ${difference.inHours}h ${difference.inMinutes % 60}min';
    } else if (difference.inMinutes > 0) {
      return 'dans ${difference.inMinutes}min';
    } else {
      return 'maintenant';
    }
  }
}

// Quota limit reached snackbar
class QuotaSnackBar {
  static void show(
    BuildContext context, {
    required QuotaType limitType,
    required QuotaInfo quotaInfo,
  }) {
    final actionText = limitType == QuotaType.swipe ? 'liker' : 'envoyer des messages';
    final limitText = limitType == QuotaType.swipe 
        ? '${quotaInfo.dailySwipeLimit} likes'
        : '${quotaInfo.dailyMessageLimit} messages';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Limite atteinte',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'Vous avez atteint votre limite de $limitText par jour',
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Premium',
          textColor: AppColors.warning,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PremiumScreen(
                  fromQuotaLimit: true,
                  limitType: limitType,
                ),
              ),
            );
          },
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
