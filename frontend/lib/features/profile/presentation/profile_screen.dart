import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../components/layout.dart';
import '../../../components/buttons.dart';
import '../../../components/bottom_navigation.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/user_profile.dart';
import '../../../models/station.dart';
import '../../../services/storage_service.dart';
import '../controllers/profile_controller.dart';
import '../../auth/controllers/auth_controller.dart';

/// Écran de profil utilisateur
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _bioController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Charger profil au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).loadProfile();
    });
  }
  
  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    final currentStation = profileState.currentStation;
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
                PrimaryButton(
                  text: 'Recharger',
                  onPressed: () => ref.read(profileControllerProvider.notifier).loadProfile(),
                  width: 200,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return AppScaffold(
      currentIndex: 3, // Profile = index 3
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header avec actions
              _buildHeader(),
              
              const SizedBox(height: 20),
              
              // Photo principale et infos de base
              _buildProfileHeader(profile, photoUrls),
              
              const SizedBox(height: 24),
              
              // Informations détaillées
              _buildProfileDetails(profile),
              
              const SizedBox(height: 24),
              
              // Station actuelle
              if (currentStation != null) _buildCurrentStation(currentStation),
              
              const SizedBox(height: 24),
              
              // Actions
              _buildProfileActions(),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mon Profil',
            style: AppTypography.h1,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () => context.push('/settings'),
            tooltip: 'Paramètres',
          ),
        ],
      ),
    );
  }
  
  
  Widget _buildProfileHeader(UserProfile profile, Map<String, String> photoUrls) {
    return AppCard(
      child: Column(
        children: [
          // Photo principale
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryPink,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: profile.mainPhotoUrl != null && photoUrls.containsKey(profile.mainPhotoUrl)
                    ? Image.network(
                        photoUrls[profile.mainPhotoUrl]!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPhotoPlaceholder();
                        },
                      )
                    : _buildPhotoPlaceholder(),
                ),
              ),
              
              // Badge vérifié
              if (profile.verificationStatus == VerificationStatus.approved)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              
              // Bouton édition photo
              if (_isEditing)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _editPhoto,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Nom et âge
          Text(
            '${profile.username}, ${profile.age ?? '?'}',
            style: AppTypography.h2,
          ),
          
          const SizedBox(height: 8),
          
          // Niveau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              profile.level.displayName,
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Premium badge
          if (profile.isPremium) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Premium',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPhotoPlaceholder() {
    return Container(
      color: AppColors.inputBorder.withOpacity(0.3),
      child: const Center(
        child: Icon(
          Icons.person_outline,
          size: 48,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
  
  Widget _buildProfileDetails(UserProfile profile) {
    return Column(
      children: [
        // Bio
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryPink),
                  const SizedBox(width: 8),
                  Text('À propos', style: AppTypography.h3),
                ],
              ),
              const SizedBox(height: 12),
              
              if (_isEditing) ...[
                TextFormField(
                  controller: _bioController..text = profile.bio ?? '',
                  decoration: const InputDecoration(
                    hintText: 'Raconte-nous qui tu es...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
              ] else ...[
                Text(
                  profile.bio?.isNotEmpty == true 
                    ? profile.bio! 
                    : 'Aucune description pour le moment.',
                  style: AppTypography.body,
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Styles de ride
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.snowboarding, color: AppColors.primaryPink),
                  const SizedBox(width: 8),
                  Text('Styles de ride', style: AppTypography.h3),
                ],
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.rideStyles.map((style) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.primaryPink.withOpacity(0.3)),
                  ),
                  child: Text(
                    style.displayName,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Langues
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.translate, color: AppColors.primaryPink),
                  const SizedBox(width: 8),
                  Text('Langues parlées', style: AppTypography.h3),
                ],
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: profile.languages.map((language) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getLanguageFlag(language), style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(language, style: AppTypography.caption),
                  ],
                )).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCurrentStation(UserStationStatus stationStatus) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primaryPink),
              const SizedBox(width: 8),
              Text('Station actuelle', style: AppTypography.h3),
              const Spacer(),
              if (stationStatus.isCurrentlyActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Actif',
                    style: AppTypography.small.copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (stationStatus.station != null) ...[
            Text(
              '${stationStatus.station!.flag} ${stationStatus.station!.name}',
              style: AppTypography.bodyBold,
            ),
            const SizedBox(height: 4),
            Text(
              '${stationStatus.station!.region} • ${stationStatus.station!.altitudeDisplay}',
              style: AppTypography.caption,
            ),
          ],
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Icon(Icons.date_range, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                // ✅ Corrigé : Gérer les nulls
                stationStatus.dateFrom != null && stationStatus.dateTo != null
                  ? '${stationStatus.dateFrom!.day}/${stationStatus.dateFrom!.month} - ${stationStatus.dateTo!.day}/${stationStatus.dateTo!.month}'
                  : 'Dates non définies',
                style: AppTypography.caption,
              ),
              const Spacer(),
              const Icon(Icons.radar, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 4),
              Text(
                // ✅ Corrigé : Gérer les nulls
                '${stationStatus.radiusKm ?? 0} km',
                style: AppTypography.caption,
              ),
            ],
          ),
          
          if (stationStatus.remainingDays > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Plus que ${stationStatus.remainingDays} jour${stationStatus.remainingDays > 1 ? 's' : ''}',
              style: AppTypography.small.copyWith(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildProfileActions() {
    return Column(
      children: [
        PrimaryButton(
          text: 'Mes photos',
          icon: Icons.photo_library,
          onPressed: () => context.push('/photo-gallery'),
        ),
        
        const SizedBox(height: 12),
        
        SecondaryButton(
          text: 'Modifier ma station',
          icon: Icons.edit_location,
          onPressed: () => context.push('/edit-station'),
        ),
        
        const SizedBox(height: 12),
        
        SecondaryButton(
          text: 'Paramètres',
          icon: Icons.settings,
          onPressed: () {
            // TODO S8: Naviguer vers paramètres
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Paramètres S8')),
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        GhostButton(
          text: 'Se déconnecter',
          onPressed: () => _handleSignOut(),
        ),
      ],
    );
  }
  
  void _editPhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Changer de photo', style: AppTypography.h3),
            const SizedBox(height: 24),
            
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryPink),
              title: Text('Galerie', style: AppTypography.bodyBold),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryPink),
              title: Text('Appareil photo', style: AppTypography.bodyBold),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final file = await StorageService.instance.pickImage(source: source);
    if (file != null) {
      final success = await ref.read(profileControllerProvider.notifier)
          .uploadPhoto(file, isMain: true);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo mise à jour ! Elle sera vérifiée.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'upload'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _handleSignOut() async {
    final confirm = await showDialog<bool>(
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
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).signOut();
      ref.read(profileControllerProvider.notifier).reset();
      context.go('/auth');
    }
  }
  
  String _getLanguageFlag(String language) {
    const flags = {
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
    
    return flags[language] ?? '🌍';
  }
}
