import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../models/user_profile.dart';

/// Header du profil style Tinder avec photo, nom, âge et bouton d'action
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    this.mainPhotoUrl,
    this.completionPercentage = 0.0,
    this.onCompleteProfileTap,
    this.onSettingsTap,
    this.onSafetyTap,
  });
  
  final UserProfile profile;
  final String? mainPhotoUrl;
  final double completionPercentage; // 0.0 à 1.0
  final VoidCallback? onCompleteProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onSafetyTap;
  
  @override
  Widget build(BuildContext context) {
    // Extraire le prénom depuis le username
    final firstName = profile.username.split('_').first.split(' ').first;
    
    return Column(
      children: [
        // AppBar custom avec logo et icônes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo CrewSnow (ou nom)
              Row(
                children: [
                  // TODO: Remplacer par l'image du logo quand elle sera ajoutée
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.ac_unit,
                      color: AppColors.primaryPink,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CrewSnow',
                    style: AppTypography.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Icônes à droite
              Row(
                children: [
                  // Bouclier / Sécurité (TODO pour plus tard)
                  IconButton(
                    icon: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: onSafetyTap ?? () {
                      // TODO: Navigation vers écran safety
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sécurité - À venir')),
                      );
                    },
                    tooltip: 'Sécurité',
                  ),
                  
                  // Roue crantée / Réglages
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: onSettingsTap ?? () => context.push('/profile-settings'),
                    tooltip: 'Réglages',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Bloc principal profil
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo de profil ronde
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: mainPhotoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: mainPhotoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.inputBorder,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.inputBorder,
                            child: const Icon(
                              Icons.person,
                              color: AppColors.textSecondary,
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.inputBorder,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.textSecondary,
                            size: 40,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Texte "Prénom, âge" et bouton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et âge
                    Text(
                      '$firstName, ${profile.age ?? '?'}',
                      style: AppTypography.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Bouton "Compléter mon profil"
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: onCompleteProfileTap ?? () {
                            context.push('/edit-profile');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            '✏️ Compléter mon profil',
                            style: AppTypography.buttonPrimary.copyWith(
                              color: AppColors.primaryPink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

