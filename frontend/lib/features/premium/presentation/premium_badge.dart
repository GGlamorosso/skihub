import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../controllers/premium_controller.dart';

class PremiumBadge extends ConsumerWidget {
  final BadgeSize size;
  final bool showLabel;
  final Color? color;

  const PremiumBadge({
    Key? key,
    this.size = BadgeSize.medium,
    this.showLabel = false,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    
    if (!isPremium) {
      return const SizedBox.shrink();
    }

    final badgeColor = color ?? AppColors.warning;
    final iconSize = _getIconSize();
    
    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.diamond,
            color: Colors.white,
            size: iconSize,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              'Premium',
              style: _getTextStyle(),
            ),
          ],
        ],
      ),
    );
  }

  double _getIconSize() {
    switch (size) {
      case BadgeSize.small:
        return 12;
      case BadgeSize.medium:
        return 16;
      case BadgeSize.large:
        return 20;
    }
  }

  EdgeInsets _getPadding() {
    if (!showLabel) {
      switch (size) {
        case BadgeSize.small:
          return const EdgeInsets.all(4);
        case BadgeSize.medium:
          return const EdgeInsets.all(6);
        case BadgeSize.large:
          return const EdgeInsets.all(8);
      }
    }

    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case BadgeSize.small:
        return 8;
      case BadgeSize.medium:
        return 10;
      case BadgeSize.large:
        return 12;
    }
  }

  TextStyle _getTextStyle() {
    const baseStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    switch (size) {
      case BadgeSize.small:
        return baseStyle.copyWith(fontSize: 10);
      case BadgeSize.medium:
        return baseStyle.copyWith(fontSize: 12);
      case BadgeSize.large:
        return baseStyle.copyWith(fontSize: 14);
    }
  }
}

enum BadgeSize { small, medium, large }

// Boost badge for profiles
class BoostBadge extends ConsumerWidget {
  final String? stationId;
  final BadgeSize size;

  const BoostBadge({
    Key? key,
    this.stationId,
    this.size = BadgeSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBoosts = ref.watch(activeBoostsProvider);
    
    final relevantBoost = stationId != null
        ? activeBoosts.where((boost) => boost.stationId == stationId).firstOrNull
        : activeBoosts.firstOrNull;
    
    if (relevantBoost == null || !relevantBoost.isCurrentlyActive) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning, AppColors.warning.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flash_on,
            color: Colors.white,
            size: _getIconSize(),
          ),
          const SizedBox(width: 4),
          Text(
            'x${relevantBoost.boostMultiplier.toStringAsFixed(1)}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: _getFontSize(),
            ),
          ),
        ],
      ),
    );
  }

  double _getIconSize() {
    switch (size) {
      case BadgeSize.small:
        return 10;
      case BadgeSize.medium:
        return 14;
      case BadgeSize.large:
        return 18;
    }
  }

  double _getFontSize() {
    switch (size) {
      case BadgeSize.small:
        return 9;
      case BadgeSize.medium:
        return 11;
      case BadgeSize.large:
        return 13;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 4, vertical: 2);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case BadgeSize.small:
        return 6;
      case BadgeSize.medium:
        return 8;
      case BadgeSize.large:
        return 10;
    }
  }
}

// Premium feature gate widget
class PremiumFeatureGate extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;
  final String featureName;
  final VoidCallback? onPremiumRequired;

  const PremiumFeatureGate({
    Key? key,
    required this.child,
    this.fallback,
    required this.featureName,
    this.onPremiumRequired,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    
    if (isPremium) {
      return child;
    }

    if (fallback != null) {
      return fallback!;
    }

    return GestureDetector(
      onTap: onPremiumRequired ?? () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PremiumScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.lock,
              color: AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              '$featureName Premium',
              style: AppTypography.subtitle2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Passez premium pour déverrouiller',
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: 'Voir Premium',
              onPressed: onPremiumRequired ?? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PremiumScreen(),
                  ),
                );
              },
              size: ButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }
}
