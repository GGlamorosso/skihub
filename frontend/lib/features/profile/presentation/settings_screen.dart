import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/layout.dart';
import '../../../components/bottom_navigation.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../controllers/profile_controller.dart';
import '../../auth/controllers/auth_controller.dart';

/// Écran des paramètres utilisateur
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.user;
    
    return AppScaffold(
      currentIndex: 3, // Profile = index 3
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: profileState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : profile == null
                ? _buildErrorState()
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                                onPressed: () => context.pop(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Paramètres',
                                style: AppTypography.h1,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Informations personnelles
                          _buildSection(
                            title: 'Informations personnelles',
                            children: [
                              _buildInfoRow(
                                icon: Icons.person,
                                label: 'Nom d\'utilisateur',
                                value: profile.username,
                              ),
                              _buildInfoRow(
                                icon: Icons.email,
                                label: 'Email',
                                value: currentUser?.email ?? (profile.email.isNotEmpty ? profile.email : 'Non disponible'),
                              ),
                              _buildInfoRow(
                                icon: Icons.cake,
                                label: 'Date de naissance',
                                value: profile.birthDate != null
                                    ? '${profile.birthDate!.day}/${profile.birthDate!.month}/${profile.birthDate!.year}'
                                    : 'Non renseignée',
                              ),
                              _buildInfoRow(
                                icon: Icons.trending_up,
                                label: 'Niveau',
                                value: profile.level.displayName,
                              ),
                              if (profile.age != null)
                                _buildInfoRow(
                                  icon: Icons.calendar_today,
                                  label: 'Âge',
                                  value: '${profile.age} ans',
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Préférences
                          _buildSection(
                            title: 'Préférences',
                            children: [
                              if (profile.rideStyles.isNotEmpty)
                                _buildInfoRow(
                                  icon: Icons.snowboarding,
                                  label: 'Styles de ride',
                                  value: profile.rideStyles.map((s) => s.displayName).join(', '),
                                ),
                              if (profile.languages.isNotEmpty)
                                _buildInfoRow(
                                  icon: Icons.language,
                                  label: 'Langues',
                                  value: profile.languages.join(', '),
                                ),
                              if (profile.objectives.isNotEmpty)
                                _buildInfoRow(
                                  icon: Icons.flag,
                                  label: 'Objectifs',
                                  value: profile.objectives.join(', '),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Compte
                          _buildSection(
                            title: 'Compte',
                            children: [
                              _buildInfoRow(
                                icon: Icons.star,
                                label: 'Statut Premium',
                                value: profile.isPremium ? 'Actif' : 'Inactif',
                              ),
                              _buildInfoRow(
                                icon: Icons.verified,
                                label: 'Vérification',
                                value: _getVerificationStatus(profile.verificationStatus.name),
                              ),
                              _buildInfoRow(
                                icon: Icons.access_time,
                                label: 'Membre depuis',
                                value: '${profile.createdAt.day}/${profile.createdAt.month}/${profile.createdAt.year}',
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Actions
                          _buildSection(
                            title: 'Actions',
                            children: [
                              _buildActionTile(
                                icon: Icons.edit,
                                title: 'Modifier mon profil',
                                onTap: () => context.push('/edit-profile'),
                              ),
                              _buildActionTile(
                                icon: Icons.location_on,
                                title: 'Modifier ma station',
                                onTap: () => context.push('/edit-station'),
                              ),
                              _buildActionTile(
                                icon: Icons.photo_library,
                                title: 'Gérer mes photos',
                                onTap: () => context.push('/photo-gallery'),
                              ),
                              _buildActionTile(
                                icon: Icons.logout,
                                title: 'Déconnexion',
                                onTap: _handleSignOut,
                                isDestructive: true,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Erreur de chargement', style: AppTypography.h3),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(profileControllerProvider.notifier).loadProfile(),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(
              color: AppColors.primaryPink,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
  
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.primaryPink,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body.copyWith(
                  color: isDestructive ? AppColors.error : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
  
  String _getVerificationStatus(String status) {
    switch (status) {
      case 'approved':
        return 'Vérifié ✓';
      case 'pending':
        return 'En attente';
      case 'rejected':
        return 'Refusé';
      default:
        return 'Non soumis';
    }
  }
  
  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/auth');
      }
    }
  }
}

