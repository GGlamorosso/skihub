import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../components/layout.dart';
import '../../../components/chips.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/user_profile.dart';
import '../controllers/onboarding_controller.dart';

/// Écran 5 – Style de ride & niveau
class LevelStyleScreen extends ConsumerStatefulWidget {
  const LevelStyleScreen({super.key});
  
  @override
  ConsumerState<LevelStyleScreen> createState() => _LevelStyleScreenState();
}

class _LevelStyleScreenState extends ConsumerState<LevelStyleScreen> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final onboardingData = ref.watch(onboardingControllerProvider);
    final selectedLevel = onboardingData.level;
    final selectedStyles = onboardingData.rideStyles;
    
    final canContinue = selectedLevel != null && selectedStyles.isNotEmpty;
    
    return OnboardingLayout(
      progress: 0.5, // 4/8 étapes environ
      title: 'Comment tu rides ?',
      subtitle: 'Choisis ton niveau et tes styles préférés.',
      onNext: _handleNext,
      onBack: () => context.go('/onboarding/photo'),
      isNextEnabled: canContinue,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Niveau
            Text(
              'Ton niveau',
              style: AppTypography.h3,
            ),
            const SizedBox(height: 16),
            
            SingleSelectChips(
              options: UserLevel.values.map((e) => e.displayName).toList(),
              selectedOption: selectedLevel?.displayName,
              onChanged: (levelName) {
                final level = UserLevel.values.firstWhere(
                  (e) => e.displayName == levelName,
                );
                ref.read(onboardingControllerProvider.notifier).updateLevel(level);
              },
              wrap: true,
            ),
            
            const SizedBox(height: 32),
            
            // Section 2: Styles de ride
            Text(
              'Ce que tu adores faire',
              style: AppTypography.h3,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu peux en choisir plusieurs',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 16),
            
            MultiSelectChips(
              options: RideStyle.values.map((e) => e.displayName).toList(),
              selectedOptions: selectedStyles.map((e) => e.displayName).toSet(),
              onChanged: (styleNames) {
                final styles = styleNames.map((name) {
                  return RideStyle.values.firstWhere(
                    (e) => e.displayName == name,
                  );
                }).toSet();
                
                ref.read(onboardingControllerProvider.notifier).updateRideStyles(styles);
              },
            ),
            
            const SizedBox(height: 40),
            
            // Preview du profil
            if (selectedLevel != null && selectedStyles.isNotEmpty) ...[
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
                          Icons.visibility_outlined,
                          color: AppColors.primaryPink,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Aperçu de ton profil',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      '${onboardingData.firstName ?? 'Prénom'}, ${onboardingData.age ?? '?'}',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    Text(
                      '${selectedLevel.displayName} • ${selectedStyles.map((e) => e.displayName).join(', ')}',
                      style: AppTypography.body.copyWith(
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const Spacer(),
            
            // Information matching
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
                        Icons.people_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Comment ça marche ?',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'On te propose des personnes avec un niveau proche et des styles compatibles. Plus vous avez de points communs, plus le match est probable !',
                    style: AppTypography.small.copyWith(
                      color: Colors.blue.shade600,
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
  
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choisir une photo',
              style: AppTypography.h3,
            ),
            const SizedBox(height: 24),
            
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryPink),
              title: Text('Galerie', style: AppTypography.bodyBold),
              subtitle: Text('Choisir une photo existante', style: AppTypography.caption),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryPink),
              title: Text('Appareil photo', style: AppTypography.bodyBold),
              subtitle: Text('Prendre une nouvelle photo', style: AppTypography.caption),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final file = File(image.path);
        
        // Vérifier taille
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          _showError('La photo est trop lourde (max 5MB)');
          return;
        }
        
        ref.read(onboardingControllerProvider.notifier).updatePhoto(file);
      }
    } catch (e) {
      _showError('Erreur lors de la sélection de la photo');
    } finally {
      setState(() => _isLoading = false);
    }
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
    context.go('/onboarding/objectives');
  }
}
