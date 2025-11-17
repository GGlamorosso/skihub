import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/layout.dart';
import '../../../components/chips.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/user_profile.dart' show UserLevel;
import '../controllers/onboarding_controller.dart';

/// Écran 6 – Objectifs & vibe
class ObjectivesScreen extends ConsumerWidget {
  const ObjectivesScreen({super.key});
  
  // Liste des objectifs disponibles
  static const List<String> availableObjectives = [
    'Rider à 2',
    'Agrandir mon groupe',
    'Hors-piste en binôme',
    'Faire des rencontres',
    'After-ski / soirées',
    'Apprendre et progresser',
    'Partager mes spots',
    'Challenges et compétitions',
  ];
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingData = ref.watch(onboardingControllerProvider);
    final selectedObjectives = onboardingData.objectives;
    
    return OnboardingLayout(
      progress: 0.625, // 5/8 étapes environ
      title: 'Tu cherches quoi sur CrewSnow ?',
      subtitle: 'Choisis tes objectifs pour de meilleurs matchs.',
      onNext: () => context.go('/onboarding/languages'),
      onBack: () => context.go('/onboarding/level'),
      isNextEnabled: selectedObjectives.isNotEmpty,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chips d'objectifs
          MultiSelectChips(
            options: availableObjectives,
            selectedOptions: selectedObjectives,
            onChanged: (objectives) {
              ref.read(onboardingControllerProvider.notifier).updateObjectives(objectives);
            },
          ),
          
          const SizedBox(height: 32),
          
          // Preview des objectifs sélectionnés
          if (selectedObjectives.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryPink.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_outlined,
                        color: AppColors.primaryPink,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tes vibes',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedObjectives.join(' • '),
                    style: AppTypography.body.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          const Spacer(),
          
          // Information utilisation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.psychology_outlined,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Algorithme de matching',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'On ne montre pas tout, on s\'en sert surtout pour te proposer des personnes compatibles avec tes objectifs.',
                  style: AppTypography.small.copyWith(
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Suggestions basées sur le niveau
          if (onboardingData.level != null) _buildSuggestions(onboardingData.level!, ref),
        ],
      ),
    );
  }
  
  Widget _buildSuggestions(UserLevel level, WidgetRef ref) {
    List<String> suggestions;
    
    switch (level) {
      case UserLevel.beginner:
        suggestions = [
          'Apprendre et progresser',
          'Rider à 2',
          'Faire des rencontres',
        ];
        break;
      case UserLevel.intermediate:
        suggestions = [
          'Agrandir mon groupe',
          'Hors-piste en binôme',
          'After-ski / soirées',
        ];
        break;
      case UserLevel.advanced:
        suggestions = [
          'Hors-piste en binôme',
          'Partager mes spots',
          'Challenges et compétitions',
        ];
        break;
      case UserLevel.expert:
        suggestions = [
          'Partager mes spots',
          'Challenges et compétitions',
          'Hors-piste en binôme',
        ];
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outlined,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Suggestions pour ton niveau',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) => GestureDetector(
              onTap: () {
                final currentObjectives = ref.read(onboardingControllerProvider).objectives;
                final newObjectives = Set<String>.from(currentObjectives)..add(suggestion);
                ref.read(onboardingControllerProvider.notifier).updateObjectives(newObjectives);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.success.withOpacity(0.5)),
                ),
                child: Text(
                  '+ $suggestion',
                  style: AppTypography.small.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  
  void _handleNext(BuildContext context) {
    context.go('/onboarding/languages');
  }
}
