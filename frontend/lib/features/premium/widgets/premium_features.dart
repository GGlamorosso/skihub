import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quota_service.dart';
import '../models/subscription.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class WhoLikedMeScreen extends ConsumerStatefulWidget {
  final String userId;

  const WhoLikedMeScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<WhoLikedMeScreen> createState() => _WhoLikedMeScreenState();
}

class _WhoLikedMeScreenState extends ConsumerState<WhoLikedMeScreen> {
  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(userPremiumStateProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qui m\'a liké'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isPremium.when(
        data: (premium) => premium
            ? _buildLikesList()
            : _buildPremiumRequired(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildLikesList() {
    return const Center(
      child: Text('Liste des personnes qui vous ont liké'),
    );
  }

  Widget _buildPremiumRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.amber[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star,
                size: 60,
                color: Colors.amber[600],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            const Text(
              'Fonctionnalité Premium',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            
            Text(
              'Découvrez qui vous a liké avec Premium.\n'
              'Connectez-vous plus facilement !',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to premium screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Passer Premium',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InvisibleModeToggle extends ConsumerWidget {
  final String userId;

  const InvisibleModeToggle({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(userPremiumStateProvider(userId));

    return isPremium.when(
      data: (premium) => premium
          ? _buildToggle()
          : _buildPremiumRequired(),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildToggle() {
    return SwitchListTile(
      title: const Text('Mode invisible'),
      subtitle: const Text('Naviguez sans être vu dans les résultats'),
      value: false, // Get from user settings
      onChanged: (value) {
        // Update invisible mode
      },
      activeThumbColor: AppColors.primary,
    );
  }

  Widget _buildPremiumRequired() {
    return ListTile(
      leading: Icon(Icons.visibility_off, color: Colors.grey[400]),
      title: const Text('Mode invisible'),
      subtitle: const Text('Fonctionnalité Premium'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: Colors.amber[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Premium',
          style: TextStyle(
            fontSize: 10,
            color: Colors.amber[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () {
        // Navigate to premium screen
      },
    );
  }
}

class AdvancedFilters extends ConsumerWidget {
  final String userId;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const AdvancedFilters({
    super.key,
    required this.userId,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(userPremiumStateProvider(userId));

    return isPremium.when(
      data: (premium) => premium
          ? _buildAdvancedFilters()
          : _buildBasicFilters(),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => _buildBasicFilters(),
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtres avancés',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Age range
        const Text('Âge', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        RangeSlider(
          values: const RangeValues(18, 35),
          min: 18,
          max: 65,
          divisions: 47,
          labels: const RangeLabels('18', '35'),
          onChanged: (values) {
            onFiltersChanged({
              'age_min': values.start.round(),
              'age_max': values.end.round(),
            });
          },
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Distance
        const Text('Distance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Slider(
          value: 25,
          min: 1,
          max: 100,
          divisions: 99,
          label: '25 km',
          onChanged: (value) {
            onFiltersChanged({'max_distance': value.round()});
          },
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Level filter
        const Text('Niveau', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: ['Débutant', 'Intermédiaire', 'Avancé', 'Expert']
              .map((level) => FilterChip(
                    label: Text(level),
                    selected: false,
                    onSelected: (selected) {
                      // Handle level selection
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBasicFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Filtres',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Premium pour plus',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.amber[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Basic level filter only
        const Text('Niveau', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        DropdownButton<String>(
          value: 'Tous',
          isExpanded: true,
          items: ['Tous', 'Débutant', 'Intermédiaire', 'Avancé', 'Expert']
              .map((level) => DropdownMenuItem(value: level, child: Text(level)))
              .toList(),
          onChanged: (value) {
            onFiltersChanged({'level': value});
          },
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Upgrade prompt
        GestureDetector(
          onTap: () {
            // Navigate to premium screen
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber),
              borderRadius: BorderRadius.circular(8),
              color: Colors.amber[50],
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber[700]),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Débloquez les filtres avancés avec Premium',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: Colors.amber[700]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PremiumTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  const PremiumTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      decoration: BoxDecoration(
        color: Colors.amber[700],
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      child: child,
    );
  }
}
