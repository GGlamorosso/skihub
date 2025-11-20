import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../components/layout.dart';
import '../../../components/candidate_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/user_profile.dart';
import '../../../models/candidate.dart';
import '../../../models/user_photo.dart';
import '../../../services/photo_repository.dart';
import '../../../services/supabase_service.dart';
import '../controllers/profile_controller.dart';
import 'widgets/profile_section_header.dart';
import 'widgets/profile_list_tile.dart';
import 'widgets/photo_grid.dart';

/// Écran "Informations" avec onglets "Modifier" et "Aperçu"
class EditProfileScreenNew extends ConsumerStatefulWidget {
  const EditProfileScreenNew({super.key});
  
  @override
  ConsumerState<EditProfileScreenNew> createState() => _EditProfileScreenNewState();
}

class _EditProfileScreenNewState extends ConsumerState<EditProfileScreenNew>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers pour les champs
  final _bioController = TextEditingController();
  bool _smartPhotos = false;
  
  // Données temporaires (non sauvegardées tant que "OK" n'est pas cliqué)
  UserLevel? _tempLevel;
  Set<RideStyle> _tempRideStyles = {};
  Set<String> _tempLanguages = {};
  Set<String> _tempObjectives = {};
  
  // Photos
  List<UserPhoto> _photos = [];
  bool _isLoadingPhotos = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Charger profil et photos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
      _loadPhotos();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProfileData() async {
    final profile = ref.read(profileControllerProvider).profile;
    if (profile != null) {
      setState(() {
        _bioController.text = profile.bio ?? '';
        _tempLevel = profile.level;
        _tempRideStyles = profile.rideStyles.toSet();
        _tempLanguages = profile.languages.toSet();
        _tempObjectives = profile.objectives.toSet();
      });
    }
  }
  
  Future<void> _loadPhotos() async {
    setState(() => _isLoadingPhotos = true);
    try {
      final userId = SupabaseService.instance.currentUserId;
      if (userId != null) {
        final photos = await PhotoRepository.instance.fetchPhotos(userId);
        setState(() {
          _photos = photos;
          _isLoadingPhotos = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingPhotos = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement photos: $e')),
        );
      }
    }
  }
  
  Future<void> _handleSave() async {
    try {
      final success = await ref.read(profileControllerProvider.notifier).updateProfile(
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        level: _tempLevel,
        rideStyles: _tempRideStyles.toList(),
        languages: _tempLanguages.toList(),
        objectives: _tempObjectives.toList(),
      );
      
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la sauvegarde')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Informations')),
        body: const Center(child: Text('Profil non chargé')),
      );
    }
    
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
          'Informations',
          style: AppTypography.h2,
        ),
        actions: [
          TextButton(
            onPressed: profileState.isUpdating ? null : _handleSave,
            child: Text(
              'OK',
              style: AppTypography.buttonGhost.copyWith(
                color: AppColors.primaryPink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryPink,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryPink,
          tabs: const [
            Tab(text: 'Modifier'),
            Tab(text: 'Aperçu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEditTab(profile),
          _buildPreviewTab(profile),
        ],
      ),
    );
  }
  
  /// Onglet "Modifier"
  Widget _buildEditTab(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: MÉDIA
          ProfileSectionHeader(
            title: 'MÉDIA',
            actionButton: TextButton(
              onPressed: _handleAddPhoto,
              child: Text(
                'AJOUTER',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryPink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          Text(
            'Ajoute jusqu\'à 9 photos de ski pour montrer qui tu es',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (_isLoadingPhotos)
            const Center(child: CircularProgressIndicator())
          else
            PhotoGrid(
              photos: _photos,
              onAddPhoto: _handleAddPhoto,
              onEditPhoto: _handleEditPhoto,
              onDeletePhoto: _handleDeletePhoto,
            ),
          
          const SizedBox(height: 32),
          
          // Section 2: OPTIONS DES PHOTOS
          ProfileSectionHeader(title: 'OPTIONS DES PHOTOS'),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Photos',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nous réorganisons automatiquement tes photos pour maximiser tes likes',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _smartPhotos,
                onChanged: (value) => setState(() => _smartPhotos = value),
                activeColor: AppColors.primaryPink,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Section 3: À PROPOS DE MOI
          ProfileSectionHeader(
            title: 'À PROPOS DE MOI',
            badge: 'IMPORTANT',
            badgeColor: AppColors.warning,
          ),
          
          TextField(
            controller: _bioController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Raconte-nous qui tu es...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryPink, width: 2),
              ),
              counterText: '${_bioController.text.length}/500',
            ),
            onChanged: (value) => setState(() {}), // Pour mettre à jour le compteur
          ),
          
          const SizedBox(height: 32),
          
          // Section 4: FUN FACTS
          ProfileSectionHeader(title: 'FUN FACTS'),
          
          InkWell(
            onTap: () {
              // TODO: Bottom sheet pour choisir des fun facts
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fun Facts - À venir')),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: AppCard(
              child: Row(
                children: [
                  const Icon(Icons.emoji_emotions_outlined, color: AppColors.primaryPink),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Choisir des Fun Facts sur moi',
                      style: AppTypography.body,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Section 5: Champs profil
          ProfileSectionHeader(title: 'PROFIL'),
          
          ProfileListTile(
            title: 'Niveau',
            value: _tempLevel?.displayName ?? 'Non renseigné',
            icon: Icons.trending_up,
            onTap: () => _showLevelSelector(),
          ),
          
          ProfileListTile(
            title: 'Styles de ride',
            value: _tempRideStyles.isEmpty
                ? null
                : _tempRideStyles.map((s) => s.displayName).join(', '),
            icon: Icons.snowboarding,
            onTap: () => _showRideStylesSelector(),
          ),
          
          ProfileListTile(
            title: 'Langues',
            value: _tempLanguages.isEmpty ? null : _tempLanguages.join(', '),
            icon: Icons.language,
            onTap: () => _showLanguagesSelector(),
          ),
          
          ProfileListTile(
            title: 'Objectifs',
            value: _tempObjectives.isEmpty ? null : _tempObjectives.join(', '),
            icon: Icons.flag,
            onTap: () => _showObjectivesSelector(),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  /// Onglet "Aperçu" - Affiche la carte comme dans le feed
  Widget _buildPreviewTab(UserProfile profile) {
    // Convertir UserProfile en Candidate pour réutiliser CandidateCard
    final candidate = _profileToCandidate(profile);
    final photoUrl = ref.read(profileControllerProvider).photoUrls.values.isNotEmpty
        ? ref.read(profileControllerProvider).photoUrls.values.first
        : null;
    
    return Container(
      color: Colors.black,
      child: Center(
        child: CandidateCard(
          candidate: candidate,
          photoUrl: photoUrl,
        ),
      ),
    );
  }
  
  /// Convertir UserProfile en Candidate pour l'aperçu
  Candidate _profileToCandidate(UserProfile profile) {
    return Candidate(
      id: profile.id,
      username: profile.username,
      age: profile.age ?? 25,
      level: profile.level,
      isPremium: profile.isPremium,
      score: 10.0, // Score max pour soi-même
      distanceKm: 0.0,
      photoUrl: profile.mainPhotoUrl,
      rideStyles: profile.rideStyles,
      languages: profile.languages,
      stationName: 'Ma station', // TODO: Récupérer depuis currentStation
      availableFrom: DateTime.now(),
      availableTo: DateTime.now().add(const Duration(days: 7)),
      boostMultiplier: 1.0,
      bio: profile.bio,
      maxSpeed: null,
      isVerified: profile.verificationStatus == VerificationStatus.approved,
    );
  }
  
  // Handlers pour les actions
  Future<void> _handleAddPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null && mounted) {
      try {
        final result = await PhotoRepository.instance.uploadPhoto(
          imageFile: File(image.path),
          isMain: _photos.isEmpty, // Première photo = photo principale
        );
        
        if (result.photo != null) {
          await _loadPhotos();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo ajoutée')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.error ?? 'Erreur upload')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
  
  void _handleEditPhoto(UserPhoto photo) {
    // TODO: Modal pour modifier/supprimer photo
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Ouvrir sélecteur d'image
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                // TODO: Supprimer photo
                await _loadPhotos();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleDeletePhoto(UserPhoto photo) {
    _handleEditPhoto(photo);
  }
  
  // Sélecteurs pour les champs
  void _showLevelSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserLevel.values.map((level) {
            return ListTile(
              title: Text(level.displayName),
              trailing: _tempLevel == level
                  ? const Icon(Icons.check, color: AppColors.primaryPink)
                  : null,
              onTap: () {
                setState(() => _tempLevel = level);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showRideStylesSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: RideStyle.values.map((style) {
            final isSelected = _tempRideStyles.contains(style);
            return CheckboxListTile(
              title: Text(style.displayName),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _tempRideStyles.add(style);
                  } else {
                    _tempRideStyles.remove(style);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showLanguagesSelector() {
    // Liste des langues disponibles
    final availableLanguages = ['fr', 'en', 'de', 'it', 'es', 'pt', 'nl', 'sv', 'no', 'da', 'ru', 'ja', 'ko', 'zh'];
    final languageNames = {
      'fr': 'Français',
      'en': 'Anglais',
      'de': 'Allemand',
      'it': 'Italien',
      'es': 'Espagnol',
      'pt': 'Portugais',
      'nl': 'Néerlandais',
      'sv': 'Suédois',
      'no': 'Norvégien',
      'da': 'Danois',
      'ru': 'Russe',
      'ja': 'Japonais',
      'ko': 'Coréen',
      'zh': 'Chinois',
    };
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableLanguages.map((lang) {
            final isSelected = _tempLanguages.contains(lang);
            return CheckboxListTile(
              title: Text(languageNames[lang] ?? lang),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _tempLanguages.add(lang);
                  } else {
                    _tempLanguages.remove(lang);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showObjectivesSelector() {
    final availableObjectives = [
      'Faire des runs tranquilles',
      'Envoyer du gros',
      'After-ski',
      'Soirées',
      'Rencontrer des gens',
      'Progresser techniquement',
      'Découvrir de nouvelles stations',
    ];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableObjectives.map((obj) {
            final isSelected = _tempObjectives.contains(obj);
            return CheckboxListTile(
              title: Text(obj),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _tempObjectives.add(obj);
                  } else {
                    _tempObjectives.remove(obj);
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

