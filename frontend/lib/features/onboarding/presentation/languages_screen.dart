import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/layout.dart';
import '../../../components/chips.dart';
import '../../../components/buttons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../controllers/onboarding_controller.dart';

/// Écran 7 – Langues parlées
class LanguagesScreen extends ConsumerStatefulWidget {
  const LanguagesScreen({super.key});
  
  @override
  ConsumerState<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends ConsumerState<LanguagesScreen> {
  final _customLanguageController = TextEditingController();
  bool _showCustomInput = false;
  
  // Langues disponibles avec drapeaux
  static const Map<String, String> availableLanguages = {
    'Français': '🇫🇷',
    'Anglais': '🇬🇧',
    'Espagnol': '🇪🇸',
    'Italien': '🇮🇹',
    'Allemand': '🇩🇪',
    'Russe': '🇷🇺',
    'Japonais': '🇯🇵',
    'Chinois': '🇨🇳',
    'Portugais': '🇵🇹',
    'Néerlandais': '🇳🇱',
  };
  
  @override
  void dispose() {
    _customLanguageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final onboardingData = ref.watch(onboardingControllerProvider);
    final selectedLanguages = onboardingData.languages;
    
    return OnboardingLayout(
      progress: 0.75, // 6/8 étapes environ
      title: 'Tu parles quelles langues ?',
      subtitle: 'Ça aide pour les matchs internationaux.',
      onNext: _handleNext,
      onBack: () => context.go('/onboarding/objectives'),
      isNextEnabled: selectedLanguages.isNotEmpty,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Langues principales
          MultiSelectChips(
            options: availableLanguages.keys.toList(),
            selectedOptions: selectedLanguages,
            onChanged: (languages) {
              ref.read(onboardingControllerProvider.notifier).updateLanguages(languages);
            },
          ),
          
          const SizedBox(height: 24),
          
          // Bouton pour ajouter langue personnalisée
          GestureDetector(
            onTap: () {
              setState(() {
                _showCustomInput = !_showCustomInput;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primaryPink.withOpacity(0.5),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showCustomInput ? Icons.remove : Icons.add,
                    color: AppColors.primaryPink,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ajouter une autre langue',
                    style: AppTypography.buttonGhost,
                  ),
                ],
              ),
            ),
          ),
          
          // Champ langue personnalisée
          if (_showCustomInput) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customLanguageController,
                    decoration: const InputDecoration(
                      labelText: 'Langue personnalisée',
                      hintText: 'Ex: Arabe, Hindi...',
                      prefixIcon: Icon(Icons.language_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onFieldSubmitted: _addCustomLanguage,
                  ),
                ),
                const SizedBox(width: 8),
                CircularIconButton(
                  icon: Icons.add,
                  onPressed: _addCustomLanguage,
                  size: 48,
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Aperçu sélection avec drapeaux
          if (selectedLanguages.isNotEmpty) ...[
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
                        Icons.translate_outlined,
                        color: AppColors.primaryPink,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tes langues',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: selectedLanguages.map((language) {
                      final flag = availableLanguages[language] ?? '🌍';
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(flag, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            language,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryPink,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          const Spacer(),
          
          // Information sur l'utilisation
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
                      Icons.info_outlined,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pourquoi les langues ?',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Les stations de ski sont très internationales ! Parler la même langue facilite les rencontres et les sorties groupe.',
                  style: AppTypography.small.copyWith(
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _addCustomLanguage([String? value]) {
    final language = value ?? _customLanguageController.text.trim();
    if (language.isNotEmpty && language.length >= 2) {
      final currentLanguages = ref.read(onboardingControllerProvider).languages;
      final newLanguages = Set<String>.from(currentLanguages)..add(language);
      
      ref.read(onboardingControllerProvider.notifier).updateLanguages(newLanguages);
      _customLanguageController.clear();
      setState(() => _showCustomInput = false);
    }
  }
  
  void _handleNext() {
    context.go('/onboarding/station-dates');
  }
}
