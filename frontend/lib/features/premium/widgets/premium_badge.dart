import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quota_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class PremiumBadge extends ConsumerWidget {
  final String? userId;
  final double? size;
  final bool showText;

  const PremiumBadge({
    super.key,
    this.userId,
    this.size = 16,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) return const SizedBox.shrink();

    final isPremium = ref.watch(userPremiumStateProvider(userId!));

    return isPremium.when(
      data: (premium) => premium ? _buildBadge() : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: showText 
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            )
          : null,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
        ),
        borderRadius: BorderRadius.circular(showText ? 8 : 20),
      ),
      child: showText
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.white, size: size),
                const SizedBox(width: 2),
                const Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Icon(
              Icons.star,
              color: Colors.white,
              size: size,
            ),
    );
  }
}

class PremiumProfileBadge extends StatelessWidget {
  final bool isPremium;
  final bool isBooster;

  const PremiumProfileBadge({
    super.key,
    required this.isPremium,
    this.isBooster = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPremium && !isBooster) return const SizedBox.shrink();

    final badges = <Widget>[];

    if (isPremium) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.amber, Colors.orange],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.white, size: 12),
              SizedBox(width: 2),
              Text(
                'Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isBooster) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange[400]!, Colors.orange[600]!],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flash_on, color: Colors.white, size: 12),
              SizedBox(width: 2),
              Text(
                'Boost',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badges
          .expand((badge) => [badge, const SizedBox(width: 4)])
          .take(badges.length * 2 - 1)
          .toList(),
    );
  }
}

class PremiumFeatureGate extends ConsumerWidget {
  final String userId;
  final Widget child;
  final Widget? fallback;
  final VoidCallback? onUpgradeNeeded;
  final String featureName;

  const PremiumFeatureGate({
    super.key,
    required this.userId,
    required this.child,
    this.fallback,
    this.onUpgradeNeeded,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(userPremiumStateProvider(userId));

    return isPremium.when(
      data: (premium) => premium 
          ? child 
          : fallback ?? _buildUpgradePrompt(context),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => child, // Show feature on error
    );
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.amber),
        borderRadius: BorderRadius.circular(8),
        color: Colors.amber[50],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber[700], size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '$featureName - Premium requis',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onUpgradeNeeded,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.amber[700]!),
                foregroundColor: Colors.amber[700],
              ),
              child: const Text('Passer Premium'),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingText;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (loadingText != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        loadingText!,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PaymentErrorHandler {
  static void handleError(BuildContext context, dynamic error) {
    String message = 'Une erreur est survenue';
    
    if (error.toString().contains('user_cancelled')) {
      message = 'Achat annulé';
    } else if (error.toString().contains('network_error')) {
      message = 'Erreur de connexion. Vérifiez votre internet.';
    } else if (error.toString().contains('item_unavailable')) {
      message = 'Produit non disponible';
    } else if (error.toString().contains('payment_invalid')) {
      message = 'Méthode de paiement invalide';
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () {
              // Could trigger retry logic
            },
          ),
        ),
      );
    }
  }

  static void handleSuccess(BuildContext context, String type) {
    final message = type == 'boost' 
        ? 'Boost activé avec succès !' 
        : 'Premium activé avec succès !';

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
