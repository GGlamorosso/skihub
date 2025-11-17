import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../services/payment_service.dart';
import '../repositories/premium_repository.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class BoostScreen extends ConsumerStatefulWidget {
  final String? stationId;
  final String? stationName;

  const BoostScreen({
    super.key,
    this.stationId,
    this.stationName,
  });

  @override
  ConsumerState<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends ConsumerState<BoostScreen> {
  bool _isLoading = false;
  String? _selectedStationId;

  @override
  void initState() {
    super.initState();
    _selectedStationId = widget.stationId;
  }

  @override
  Widget build(BuildContext context) {
    final activeBoosts = ref.watch(activeBoostsProvider('current-user-id'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boost Station'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            _buildHeaderInfo(),
            const SizedBox(height: AppSpacing.xl),
            
            // Active boosts
            activeBoosts.when(
              data: (boosts) => _buildActiveBoosts(boosts),
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Erreur: $err'),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Boost options
            _buildBoostOptions(),
            const SizedBox(height: AppSpacing.xl),
            
            // How it works
            _buildHowItWorks(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: Colors.orange[600],
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Boostez votre visibilité',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Apparaissez en priorité dans les recherches des autres skieurs '
              'de votre station. Plus de matchs, plus de rencontres !',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            if (_selectedStationId != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place, color: Colors.orange[600], size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Station: ${widget.stationName ?? "Station actuelle"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBoosts(List<Boost> boosts) {
    if (boosts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Boosts actifs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...boosts.map((boost) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildActiveBoostCard(boost),
        )),
      ],
    );
  }

  Widget _buildActiveBoostCard(Boost boost) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flash_on,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boost.stationName ?? 'Station',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${boost.multiplierDisplay} visibilité',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getBoostStatusColor(boost).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getBoostStatusColor(boost).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    boost.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getBoostStatusColor(boost),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Time remaining
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Temps restant: ${boost.timeRemainingDisplay}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            // Progress bar
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: _getBoostProgress(boost),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(Colors.orange[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoostOptions() {
    const boostTypes = BoostType.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisir un boost',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...boostTypes.map((boostType) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildBoostOptionCard(boostType),
        )),
      ],
    );
  }

  Widget _buildBoostOptionCard(BoostType boostType) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Icon and multiplier
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: Colors.orange[600],
                    size: 24,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${boostType.multiplier}x',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Boost ${boostType.displayName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    boostType.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '€${boostType.displayPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Purchase button
            AppButton(
              text: 'Acheter',
              onPressed: _isLoading ? null : () => _purchaseBoost(boostType),
              variant: AppButtonVariant.outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Comment ça marche ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            const _InfoStep(
              number: 1,
              title: 'Sélectionnez votre station',
              description: 'Le boost s\'active uniquement dans la station choisie',
            ),
            const SizedBox(height: AppSpacing.lg),
            
            const _InfoStep(
              number: 2,
              title: 'Choisissez la durée',
              description: 'Plus la durée est longue, plus le multiplicateur est élevé',
            ),
            const SizedBox(height: AppSpacing.lg),
            
            const _InfoStep(
              number: 3,
              title: 'Profitez de la visibilité',
              description: 'Votre profil apparaît en priorité dans les résultats',
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600], size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Les boosts peuvent être cumulés avec le statut Premium pour '
                      'une visibilité maximale.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseBoost(BoostType boostType) async {
    if (_selectedStationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une station'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      const userId = 'current-user-id'; // Get from auth
      
      final success = await paymentService.purchaseBoost(
        userId: userId,
        stationId: _selectedStationId!,
        boostType: boostType,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Boost ${boostType.displayName} acheté avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh active boosts
        ref.invalidate(activeBoostsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'achat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getBoostStatusColor(Boost boost) {
    if (boost.isCurrentlyActive) return Colors.green;
    if (boost.isUpcoming) return Colors.orange;
    return Colors.grey;
  }

  double _getBoostProgress(Boost boost) {
    final total = boost.endsAt.difference(boost.startsAt).inMilliseconds;
    final elapsed = DateTime.now().difference(boost.startsAt).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

class _InfoStep extends StatelessWidget {
  final int number;
  final String title;
  final String description;

  const _InfoStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Active boosts widget
class ActiveBoostIndicator extends ConsumerWidget {
  final String userId;

  const ActiveBoostIndicator({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBoosts = ref.watch(activeBoostsProvider(userId));

    return activeBoosts.when(
      data: (boosts) {
        if (boosts.isEmpty) return const SizedBox.shrink();
        
        final activeBoost = boosts.firstOrNull;
        if (activeBoost == null || !activeBoost.isCurrentlyActive) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange[400]!, Colors.orange[600]!],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.flash_on,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Boost ${activeBoost.multiplierDisplay} actif',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}

// Boost countdown widget
class BoostCountdown extends StatefulWidget {
  final Boost boost;

  const BoostCountdown({
    super.key,
    required this.boost,
  });

  @override
  State<BoostCountdown> createState() => _BoostCountdownState();
}

class _BoostCountdownState extends State<BoostCountdown> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange[400]!.withOpacity(0.8 + 0.2 * _animation.value),
                Colors.orange[600]!.withOpacity(0.8 + 0.2 * _animation.value),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Text(
                    'BOOST ACTIF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Encore ${widget.boost.timeRemainingDisplay}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Providers
final activeBoostsProvider = FutureProvider.family<List<Boost>, String>((ref, userId) async {
  final premiumRepository = ref.read(premiumRepositoryProvider);
  return await premiumRepository.getUserActiveBoosts(userId);
});
