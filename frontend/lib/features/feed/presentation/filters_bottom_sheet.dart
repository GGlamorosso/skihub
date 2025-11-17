import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/layout.dart';
import '../../../components/buttons.dart';
import '../../../components/chips.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/candidate.dart';
import '../../../models/user_profile.dart';
import '../controllers/feed_controller.dart';

/// Bottom sheet pour filtres de matching
class FiltersBottomSheet extends ConsumerStatefulWidget {
  const FiltersBottomSheet({super.key});
  
  @override
  ConsumerState<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends ConsumerState<FiltersBottomSheet> {
  late SwipeFilters _filters;
  
  @override
  void initState() {
    super.initState();
    
    // Charger filtres actuels ou défaut
    final currentFilters = ref.read(feedFiltersProvider);
    _filters = currentFilters ?? SwipeFilters.defaultFilters();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.inputBorder),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                const Spacer(),
                Text('Filtres', style: AppTypography.h3),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Reset',
                    style: AppTypography.buttonGhost,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu filtres
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Âge
                  _buildAgeSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Distance
                  _buildDistanceSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Niveau
                  _buildLevelSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Styles de ride
                  _buildRideStylesSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Langues
                  _buildLanguagesSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Options premium
                  _buildPremiumOptionsSection(),
                ],
              ),
            ),
          ),
          
          // Boutons action
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.inputBorder),
              ),
            ),
            child: Column(
              children: [
                // Résumé filtres actifs
                if (_filters.activeFiltersCount > 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_filters.activeFiltersCount} filtre${_filters.activeFiltersCount > 1 ? 's' : ''} actif${_filters.activeFiltersCount > 1 ? 's' : ''}',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Boutons
                PrimaryButton(
                  text: 'Appliquer les filtres',
                  onPressed: _applyFilters,
                ),
                
                const SizedBox(height: 12),
                
                SecondaryButton(
                  text: 'Annuler',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Âge', style: AppTypography.h3),
        const SizedBox(height: 12),
        
        RangeSlider(
          values: RangeValues(
            _filters.minAge?.toDouble() ?? 18,
            _filters.maxAge?.toDouble() ?? 65,
          ),
          min: 16,
          max: 80,
          divisions: 32,
          activeColor: AppColors.primaryPink,
          labels: RangeLabels(
            '${_filters.minAge ?? 18} ans',
            '${_filters.maxAge ?? 65} ans',
          ),
          onChanged: (values) {
            setState(() {
              _filters = _filters.copyWith(
                minAge: values.start.round(),
                maxAge: values.end.round(),
              );
            });
          },
        ),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_filters.minAge ?? 18} ans', style: AppTypography.caption),
            Text('${_filters.maxAge ?? 65} ans', style: AppTypography.caption),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDistanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Distance maximum', style: AppTypography.h3),
        const SizedBox(height: 12),
        
        Slider(
          value: _filters.maxDistance?.toDouble() ?? 50,
          min: 5,
          max: 100,
          divisions: 19,
          activeColor: AppColors.primaryPink,
          label: '${_filters.maxDistance ?? 50} km',
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(maxDistance: value.round());
            });
          },
        ),
        
        Text('${_filters.maxDistance ?? 50} km', style: AppTypography.caption),
      ],
    );
  }
  
  Widget _buildLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Niveaux', style: AppTypography.h3),
        const SizedBox(height: 8),
        Text('Laisse vide pour tous les niveaux', style: AppTypography.caption),
        const SizedBox(height: 12),
        
        MultiSelectChips(
          options: UserLevel.values.map((e) => e.displayName).toList(),
          selectedOptions: _filters.levels?.map((e) => e.displayName).toSet() ?? {},
          onChanged: (levelNames) {
            final levels = levelNames.map((name) {
              return UserLevel.values.firstWhere((e) => e.displayName == name);
            }).toList();
            
            setState(() {
              _filters = _filters.copyWith(
                levels: levels.isEmpty ? null : levels,
              );
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildRideStylesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Styles de ride', style: AppTypography.h3),
        const SizedBox(height: 8),
        Text('Styles en commun avec toi', style: AppTypography.caption),
        const SizedBox(height: 12),
        
        MultiSelectChips(
          options: RideStyle.values.map((e) => e.displayName).toList(),
          selectedOptions: _filters.rideStyles?.map((e) => e.displayName).toSet() ?? {},
          onChanged: (styleNames) {
            final styles = styleNames.map((name) {
              return RideStyle.values.firstWhere((e) => e.displayName == name);
            }).toList();
            
            setState(() {
              _filters = _filters.copyWith(
                rideStyles: styles.isEmpty ? null : styles,
              );
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildLanguagesSection() {
    const availableLanguages = [
      'Français', 'Anglais', 'Espagnol', 'Italien', 
      'Allemand', 'Russe', 'Japonais', 'Chinois'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Langues', style: AppTypography.h3),
        const SizedBox(height: 8),
        Text('Langues parlées en commun', style: AppTypography.caption),
        const SizedBox(height: 12),
        
        MultiSelectChips(
          options: availableLanguages,
          selectedOptions: _filters.languages?.toSet() ?? {},
          onChanged: (languages) {
            setState(() {
              _filters = _filters.copyWith(
                languages: languages.isEmpty ? null : languages.toList(),
              );
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildPremiumOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Options', style: AppTypography.h3),
        const SizedBox(height: 12),
        
        // Premium uniquement
        SwitchListTile(
          value: _filters.premiumOnly ?? false,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(premiumOnly: value);
            });
          },
          title: Text('Premium uniquement', style: AppTypography.bodyBold),
          subtitle: Text('Utilisateurs Premium seulement', style: AppTypography.caption),
          activeThumbColor: AppColors.primaryPink,
          contentPadding: EdgeInsets.zero,
        ),
        
        // Vérifiés uniquement
        SwitchListTile(
          value: _filters.verifiedOnly ?? false,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(verifiedOnly: value);
            });
          },
          title: Text('Vérifiés uniquement', style: AppTypography.bodyBold),
          subtitle: Text('Profils avec vérification vidéo', style: AppTypography.caption),
          activeThumbColor: AppColors.success,
          contentPadding: EdgeInsets.zero,
        ),
        
        // Boostés uniquement
        SwitchListTile(
          value: _filters.boostedOnly ?? false,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(boostedOnly: value);
            });
          },
          title: Text('Boostés uniquement', style: AppTypography.bodyBold),
          subtitle: Text('Utilisateurs avec boost actif', style: AppTypography.caption),
          activeThumbColor: AppColors.warning,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
  
  void _resetFilters() {
    setState(() {
      _filters = SwipeFilters.defaultFilters();
    });
  }
  
  void _applyFilters() {
    ref.read(feedControllerProvider.notifier).applyFilters(_filters);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _filters.activeFiltersCount > 0
            ? 'Filtres appliqués (${_filters.activeFiltersCount})'
            : 'Filtres supprimés',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
