import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../components/layout.dart';
import '../../../components/buttons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../controllers/onboarding_controller.dart';

/// Écran 8 – GPS & Tracker
class GpsTrackerScreen extends ConsumerStatefulWidget {
  const GpsTrackerScreen({super.key});
  
  @override
  ConsumerState<GpsTrackerScreen> createState() => _GpsTrackerScreenState();
}

class _GpsTrackerScreenState extends ConsumerState<GpsTrackerScreen> {
  bool _isRequestingPermission = false;
  
  @override
  Widget build(BuildContext context) {
    final onboardingData = ref.watch(onboardingControllerProvider);
    final enableTracking = onboardingData.enableTracking;
    
    return OnboardingLayout(
      progress: 0.875, // 7/8 étapes
      title: 'On track tes runs ?',
      subtitle: 'Stats de vitesse, distance et dénivelé sur ton profil.',
      onNext: _handleNext,
      onBack: () => context.go('/onboarding/station-dates'),
      nextText: 'Continuer',
      isLoading: _isRequestingPermission,
      content: Column(
        children: [
          // Illustration GPS
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryPink.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.my_location_outlined,
                size: 48,
                color: AppColors.primaryPink,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Toggle tracker
          SwitchListTile(
            value: enableTracking,
            onChanged: (value) => _toggleTracking(value),
            title: Text(
              'Activer le tracker ski',
              style: AppTypography.bodyBold,
            ),
            subtitle: Text(
              'Calcule automatiquement tes stats pendant tes sessions',
              style: AppTypography.caption,
            ),
            activeThumbColor: AppColors.primaryPink,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          
          const SizedBox(height: 24),
          
          // Avantages tracker
          if (enableTracking) ...[
            Container(
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
                        Icons.analytics_outlined,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Avec le tracker activé',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  ..._buildTrackingFeatures(),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_disabled_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tracker désactivé',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu peux l\'activer plus tard dans les paramètres. Pas de stats automatiques pour l\'instant.',
                    style: AppTypography.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const Spacer(),
          
          // Information confidentialité
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
                      Icons.privacy_tip_outlined,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Confidentialité GPS',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Si tu actives le GPS, on calcule ta vitesse max, ta distance, et on l\'affiche sur ton profil. Tu peux désactiver ça à tout moment.',
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
  
  List<Widget> _buildTrackingFeatures() {
    final features = [
      'Distance parcourue par session',
      'Vitesse maximum atteinte',
      'Dénivelé total gravi',
      'Nombre de descentes',
      'Temps de ride effectif',
      'Historique et comparaisons',
    ];
    
    return features.map((feature) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: AppTypography.small.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      ),
    )).toList();
  }
  
  void _toggleTracking(bool value) async {
    if (value) {
      // Si activation, demander permission
      await _requestLocationPermission();
    } else {
      // Si désactivation, juste mettre à jour l'état
      ref.read(onboardingControllerProvider.notifier).updateTracking(false);
    }
  }
  
  Future<void> _requestLocationPermission() async {
    setState(() => _isRequestingPermission = true);
    
    try {
      // Demander permission location
      final status = await Permission.location.request();
      
      if (status.isGranted) {
        ref.read(onboardingControllerProvider.notifier).updateTracking(true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 GPS activé ! Tes stats seront trackées.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (status.isDenied) {
        _showPermissionDialog();
      } else if (status.isPermanentlyDenied) {
        _showSettingsDialog();
      }
    } catch (e) {
      _showError('Erreur lors de la demande de permission');
    } finally {
      setState(() => _isRequestingPermission = false);
    }
  }
  
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission GPS'),
        content: const Text(
          'Pour tracker tes sessions de ski, CrewSnow a besoin d\'accéder à ta localisation.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(onboardingControllerProvider.notifier).updateTracking(false);
            },
            child: const Text('Plus tard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestLocationPermission();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
  
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission refusée'),
        content: const Text(
          'Tu as refusé l\'accès à la localisation. Pour l\'activer, va dans Paramètres > CrewSnow > Localisation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
  
  void _handleNext() {
    context.go('/onboarding/complete');
  }
}
