import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../components/layout.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../models/user_profile.dart';
import '../../../../models/candidate.dart' show SwipeFilters;
import '../../../../models/user_profile.dart' show UserLevel, RideStyle;
import '../controllers/profile_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'widgets/profile_section_header.dart';
import 'widgets/profile_list_tile.dart';

/// Écran "Réglages" style Tinder
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});
  
  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  // Filtres de découverte (stockés localement pour l'instant)
  SwipeFilters _discoveryFilters = SwipeFilters.defaultFilters();
  bool _showOnlyWithPhotos = false;
  bool _showOnlyWithBio = false;
  UserLevel? _minLevel;
  Set<RideStyle> _selectedRideTypes = {};
  
  @override
  void initState() {
    super.initState();
    _loadDiscoverySettings();
  }
  
  Future<void> _loadDiscoverySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _discoveryFilters = SwipeFilters(
          minAge: prefs.getInt('discovery_min_age') ?? 18,
          maxAge: prefs.getInt('discovery_max_age') ?? 65,
          maxDistance: prefs.getInt('discovery_max_distance') ?? 50,
          levels: null, // TODO: Charger depuis prefs si nécessaire
          rideStyles: null, // TODO: Charger depuis prefs si nécessaire
        );
        _showOnlyWithPhotos = prefs.getBool('discovery_only_photos') ?? false;
        _showOnlyWithBio = prefs.getBool('discovery_only_bio') ?? false;
      });
    } catch (e) {
      debugPrint('Error loading discovery settings: $e');
    }
  }
  
  Future<void> _saveDiscoverySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('discovery_min_age', _discoveryFilters.minAge ?? 18);
      await prefs.setInt('discovery_max_age', _discoveryFilters.maxAge ?? 65);
      await prefs.setInt('discovery_max_distance', _discoveryFilters.maxDistance ?? 50);
      await prefs.setBool('discovery_only_photos', _showOnlyWithPhotos);
      await prefs.setBool('discovery_only_bio', _showOnlyWithBio);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réglages sauvegardés')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur sauvegarde: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.user;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Réglages',
          style: AppTypography.h2,
        ),
        actions: [
          TextButton(
            onPressed: _saveDiscoverySettings,
            child: Text(
              'OK',
              style: AppTypography.buttonGhost.copyWith(
                color: AppColors.primaryPink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Compte
                  ProfileSectionHeader(title: 'COMPTE'),
                  
                  AppCard(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.phone,
                          label: 'Numéro de téléphone',
                          value: 'Non renseigné', // TODO: Récupérer depuis auth si disponible
                        ),
                        const Divider(height: 1),
                        _buildInfoRow(
                          icon: Icons.email,
                          label: 'Adresse e-mail',
                          value: currentUser?.email ?? profile.email,
                        ),
                        const Divider(height: 1),
                        _buildInfoRow(
                          icon: Icons.link,
                          label: 'Comptes connectés',
                          value: 'Aucun', // TODO: Gérer les comptes connectés
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Section Options de découverte
                  ProfileSectionHeader(title: 'OPTIONS DE DÉCOUVERTE'),
                  
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Distance max
                        Text(
                          'Distance max',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: (_discoveryFilters.maxDistance ?? 50).toDouble(),
                                min: 10,
                                max: 150,
                                divisions: 14,
                                label: '${_discoveryFilters.maxDistance ?? 50} km',
                                activeColor: AppColors.primaryPink,
                                onChanged: (value) {
                                  setState(() {
                                    _discoveryFilters = _discoveryFilters.copyWith(
                                      maxDistance: value.round(),
                                    );
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                '${_discoveryFilters.maxDistance ?? 50} km',
                                style: AppTypography.body,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        
                        const Divider(height: 32),
                        
                        // Âge min/max
                        Text(
                          'Tranche d\'âge',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RangeSlider(
                          values: RangeValues(
                            (_discoveryFilters.minAge ?? 18).toDouble(),
                            (_discoveryFilters.maxAge ?? 65).toDouble(),
                          ),
                          min: 18,
                          max: 80,
                          divisions: 62,
                          activeColor: AppColors.primaryPink,
                          labels: RangeLabels(
                            '${_discoveryFilters.minAge ?? 18} ans',
                            '${_discoveryFilters.maxAge ?? 65} ans',
                          ),
                          onChanged: (values) {
                            setState(() {
                              _discoveryFilters = _discoveryFilters.copyWith(
                                minAge: values.start.round(),
                                maxAge: values.end.round(),
                              );
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_discoveryFilters.minAge ?? 18} ans',
                              style: AppTypography.caption,
                            ),
                            Text(
                              '${_discoveryFilters.maxAge ?? 65} ans',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                        
                        const Divider(height: 32),
                        
                        // Switch: Afficher uniquement avec photo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Afficher uniquement les profils avec photo',
                                style: AppTypography.body,
                              ),
                            ),
                            Switch(
                              value: _showOnlyWithPhotos,
                              onChanged: (value) => setState(() => _showOnlyWithPhotos = value),
                              activeColor: AppColors.primaryPink,
                            ),
                          ],
                        ),
                        
                        const Divider(height: 1),
                        
                        // Switch: Afficher uniquement avec bio
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Afficher uniquement les profils avec bio',
                                style: AppTypography.body,
                              ),
                            ),
                            Switch(
                              value: _showOnlyWithBio,
                              onChanged: (value) => setState(() => _showOnlyWithBio = value),
                              activeColor: AppColors.primaryPink,
                            ),
                          ],
                        ),
                        
                        const Divider(height: 16),
                        
                        // Niveau minimum
                        ProfileListTile(
                          title: 'Niveau minimum',
                          value: _minLevel?.displayName ?? 'Aucun',
                          icon: Icons.trending_up,
                          onTap: () => _showMinLevelSelector(),
                        ),
                        
                        const Divider(height: 1),
                        
                        // Types de ride
                        ProfileListTile(
                          title: 'Types de ride',
                          value: _selectedRideTypes.isEmpty
                              ? 'Tous'
                              : _selectedRideTypes.map((s) => s.displayName).join(', '),
                          icon: Icons.snowboarding,
                          onTap: () => _showRideTypesSelector(),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Section Autres
                  ProfileSectionHeader(title: 'AUTRES'),
                  
                  AppCard(
                    child: Column(
                      children: [
                        ProfileListTile(
                          title: 'Notifications',
                          value: 'Actives',
                          icon: Icons.notifications,
                          onTap: () {
                            // TODO: Navigation vers écran notifications
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notifications - À venir')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ProfileListTile(
                          title: 'Confidentialité',
                          value: null,
                          icon: Icons.lock,
                          onTap: () {
                            // TODO: Navigation vers écran confidentialité
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Confidentialité - À venir')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ProfileListTile(
                          title: 'Aide & Support',
                          value: null,
                          icon: Icons.help_outline,
                          onTap: () {
                            // TODO: Navigation vers aide
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Aide - À venir')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryPink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showMinLevelSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Aucun'),
              trailing: _minLevel == null
                  ? const Icon(Icons.check, color: AppColors.primaryPink)
                  : null,
              onTap: () {
                setState(() => _minLevel = null);
                Navigator.pop(context);
              },
            ),
            ...UserLevel.values.map((level) {
              return ListTile(
                title: Text(level.displayName),
                trailing: _minLevel == level
                    ? const Icon(Icons.check, color: AppColors.primaryPink)
                    : null,
                onTap: () {
                  setState(() => _minLevel = level);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
  
  void _showRideTypesSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: RideStyle.values.map((style) {
            final isSelected = _selectedRideTypes.contains(style);
            return CheckboxListTile(
              title: Text(style.displayName),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedRideTypes.add(style);
                  } else {
                    _selectedRideTypes.remove(style);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

