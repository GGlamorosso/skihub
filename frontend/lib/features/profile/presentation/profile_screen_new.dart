import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/bottom_navigation.dart';
import '../../../../components/layout.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../models/user_profile.dart';
import '../controllers/profile_controller.dart';
import 'widgets/profile_header.dart';

/// Écran de profil principal style Tinder
class ProfileScreenNew extends ConsumerStatefulWidget {
  const ProfileScreenNew({super.key});
  
  @override
  ConsumerState<ProfileScreenNew> createState() => _ProfileScreenNewState();
}

class _ProfileScreenNewState extends ConsumerState<ProfileScreenNew> {
  @override
  void initState() {
    super.initState();
    
    // Charger profil au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).loadProfile();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    final photoUrls = profileState.photoUrls;
    
    if (profileState.isLoading) {
      return const AppScaffold(
        currentIndex: 3,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (profile == null) {
      return AppScaffold(
        currentIndex: 3,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Profil non trouvé', style: AppTypography.h3),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(profileControllerProvider.notifier).loadProfile(),
                  child: const Text('Recharger'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Calculer le pourcentage de complétion
    final completionPercentage = _calculateCompletionPercentage(profile);
    
    // Récupérer la photo principale
    final mainPhotoUrl = photoUrls.values.isNotEmpty 
        ? photoUrls.values.first 
        : profile.mainPhotoUrl;
    
    return AppScaffold(
      currentIndex: 3, // Profile = index 3
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header avec logo, icônes, photo et bouton
              ProfileHeader(
                profile: profile,
                mainPhotoUrl: mainPhotoUrl,
                completionPercentage: completionPercentage,
                onCompleteProfileTap: () => context.push('/edit-profile'),
                onSettingsTap: () => context.push('/profile-settings'),
              ),
              
              const SizedBox(height: 32),
              
              // Cartes promo (exemples)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildPromoCard(
                      context,
                      icon: Icons.location_on,
                      title: 'Active ton Tracker',
                      subtitle: 'Enregistre tes sessions de ski',
                      onTap: () => context.push('/tracker'),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildPromoCard(
                      context,
                      icon: Icons.group_add,
                      title: 'Invite tes potes',
                      subtitle: 'Partage CrewSnow avec tes amis',
                      onTap: () {
                        // TODO: Logique d'invitation
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invitation - À venir')),
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
      ),
    );
  }
  
  /// Calculer le pourcentage de complétion du profil
  double _calculateCompletionPercentage(UserProfile profile) {
    int filledFields = 0;
    int totalFields = 8; // Nombre total de champs importants
    
    if (profile.bio != null && profile.bio!.isNotEmpty) filledFields++;
    if (profile.birthDate != null) filledFields++;
    if (profile.rideStyles.isNotEmpty) filledFields++;
    if (profile.languages.isNotEmpty) filledFields++;
    if (profile.objectives.isNotEmpty) filledFields++;
    if (profile.mainPhotoUrl != null) filledFields++;
    // Station active (vérifiée via controller)
    // Niveau (toujours présent)
    filledFields += 2; // Niveau et station comptent toujours
    
    return (filledFields / totalFields).clamp(0.0, 1.0);
  }
  
  /// Carte promo cliquable
  Widget _buildPromoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

