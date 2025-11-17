import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../components/layout.dart';
import '../../../components/buttons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../controllers/onboarding_controller.dart';

/// Écran 4 – Ajout photo principale
class PhotoScreen extends ConsumerStatefulWidget {
  const PhotoScreen({super.key});
  
  @override
  ConsumerState<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends ConsumerState<PhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final onboardingData = ref.watch(onboardingControllerProvider);
    final hasPhoto = onboardingData.photoFile != null;
    
    return OnboardingLayout(
      progress: 0.375, // 3/8 étapes environ
      title: 'Montre-nous ta meilleure photo 🎿',
      subtitle: 'Pas de casque intégral ni de lunettes noires seulement, on veut te voir 😉',
      onNext: () => context.go('/onboarding/level'),
      onBack: () => context.go('/onboarding/age'),
      isNextEnabled: hasPhoto,
      isLoading: _isLoading,
      content: Column(
        children: [
          // Zone photo principale
          GestureDetector(
            onTap: () => _showImageSourceDialog(),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasPhoto ? AppColors.success : AppColors.inputBorder,
                  width: 3,
                ),
                boxShadow: hasPhoto ? [AppColors.cardShadow] : null,
              ),
              child: ClipOval(
                child: hasPhoto
                  ? Image.file(
                      onboardingData.photoFile!,
                      fit: BoxFit.cover,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 48,
                          color: AppColors.textSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajouter\nune photo',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Boutons d'action
          if (!hasPhoto) ...[
            PrimaryButton(
              text: 'Choisir dans la galerie',
              icon: Icons.photo_library_outlined,
              onPressed: () => _pickImage(ImageSource.gallery),
              isLoading: _isLoading,
            ),
            
            const SizedBox(height: 16),
            
            SecondaryButton(
              text: 'Prendre une photo',
              icon: Icons.camera_alt_outlined,
              onPressed: () => _pickImage(ImageSource.camera),
            ),
          ] else ...[
            // Photo sélectionnée, proposer de changer
            SecondaryButton(
              text: 'Changer de photo',
              icon: Icons.edit_outlined,
              onPressed: () => _showImageSourceDialog(),
            ),
            
            const SizedBox(height: 16),
            
            // Aperçu réussi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outlined,
                    color: AppColors.success,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Super photo ! Elle sera vérifiée pour la sécurité de tous.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const Spacer(),
          
          // Avertissement modération
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.security_outlined,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Modération des photos',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Les photos sont vérifiées automatiquement pour la sécurité de tous. Assure-toi que ton visage est bien visible !',
                  style: AppTypography.small.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final file = File(image.path);
        
        // Vérifier taille (max 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          _showError('La photo est trop lourde (max 5MB)');
          return;
        }
        
        // Sauvegarder dans l'état onboarding
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
    context.go('/onboarding/level');
  }
}
