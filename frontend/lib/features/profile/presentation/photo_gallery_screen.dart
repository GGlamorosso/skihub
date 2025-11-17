import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../../router/app_router.dart';

import '../../../components/layout.dart';
import '../../../components/buttons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/user_photo.dart';
import '../../../services/storage_service.dart';
import '../controllers/photos_controller.dart';
import '../../auth/controllers/auth_controller.dart';

/// Écran galerie photos profil
class PhotoGalleryScreen extends ConsumerStatefulWidget {
  const PhotoGalleryScreen({super.key});
  
  @override
  ConsumerState<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends ConsumerState<PhotoGalleryScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }
    
    final photosState = ref.watch(photosControllerProvider(currentUser.id));
    
    return GradientScaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(photosState),
          
          // Stats modération
          _buildModerationStats(photosState),
          
          // Galerie
          Expanded(
            child: _buildPhotoGallery(photosState, currentUser.id),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(PhotosState photosState) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.profile);
              }
            },
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          ),
          const Spacer(),
          Text(
            'Mes Photos',
            style: AppTypography.h3,
          ),
          const Spacer(),
          IconButton(
            onPressed: photosState.canAddMorePhotos ? _addPhoto : null,
            icon: Icon(
              Icons.add_a_photo,
              color: photosState.canAddMorePhotos 
                ? AppColors.primaryPink 
                : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModerationStats(PhotosState photosState) {
    if (photosState.stats.isEmpty) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        children: [
          Text(
            'État de modération',
            style: AppTypography.h3,
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                count: photosState.approvedCount,
                label: 'Approuvées',
                color: AppColors.success,
                icon: Icons.check_circle,
              ),
              _buildStatChip(
                count: photosState.pendingCount,
                label: 'En attente',
                color: AppColors.warning,
                icon: Icons.schedule,
              ),
              _buildStatChip(
                count: photosState.rejectedCount,
                label: 'Rejetées',
                color: AppColors.error,
                icon: Icons.cancel,
              ),
            ],
          ),
          
          if (photosState.pendingCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${photosState.pendingCount} photo${photosState.pendingCount > 1 ? 's' : ''} en cours de modération. Vous serez notifié du résultat.',
                      style: AppTypography.small.copyWith(color: AppColors.warning),
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
  
  Widget _buildStatChip({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: AppTypography.bodyBold.copyWith(color: color),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.small.copyWith(color: color),
        ),
      ],
    );
  }
  
  Widget _buildPhotoGallery(PhotosState photosState, String userId) {
    if (photosState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      );
    }
    
    if (photosState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(photosState.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Réessayer',
              onPressed: () => ref.read(photosControllerProvider(userId).notifier).refresh(),
              width: 200,
            ),
          ],
        ),
      );
    }
    
    if (!photosState.hasPhotos) {
      return _buildEmptyGallery();
    }
    
    return RefreshIndicator(
      onRefresh: () => ref.read(photosControllerProvider(userId).notifier).refresh(),
      color: AppColors.primaryPink,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: photosState.photos.length + (photosState.canAddMorePhotos ? 1 : 0),
        itemBuilder: (context, index) {
          // Bouton ajouter photo
          if (index >= photosState.photos.length) {
            return _buildAddPhotoCard();
          }
          
          final photo = photosState.photos[index];
          return _buildPhotoCard(photo, userId);
        },
      ),
    );
  }
  
  Widget _buildEmptyGallery() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          
          Text(
            'Aucune photo',
            style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Ajoutez des photos pour compléter votre profil !',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          
          const SizedBox(height: 32),
          
          PrimaryButton(
            text: 'Ajouter ma première photo',
            icon: Icons.add_a_photo,
            onPressed: _addPhoto,
            width: 250,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddPhotoCard() {
    return GestureDetector(
      onTap: _addPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inputBorder.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryPink,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 48,
              color: AppColors.primaryPink.withOpacity(0.7),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajouter\nune photo',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryPink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPhotoCard(UserPhoto photo, String userId) {
    return GestureDetector(
      onTap: () => _showPhotoActions(photo, userId),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppColors.cardShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: photo.displayUrl != null
                  ? CachedNetworkImage(
                      imageUrl: photo.displayUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPhotoPlaceholder(isLoading: true),
                      errorWidget: (context, url, error) => _buildPhotoPlaceholder(),
                    )
                  : _buildPhotoPlaceholder(),
              ),
              
              // Badge photo principale
              if (photo.isMain)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Principale',
                          style: AppTypography.small.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Badge statut modération
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: photo.statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        photo.statusIcon,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        photo.statusText,
                        style: AppTypography.small.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Overlay actions
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x80000000)],
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Définir comme principale
                      if (!photo.isMain && photo.canBeMain)
                        _buildActionIcon(
                          icon: Icons.star_outline,
                          onTap: () => _setMainPhoto(photo.id, userId),
                        ),
                      
                      // Remplacer si rejetée
                      if (photo.isRejected)
                        _buildActionIcon(
                          icon: Icons.refresh,
                          onTap: () => _replacePhoto(photo, userId),
                        ),
                      
                      // Supprimer
                      if (photo.canBeDeleted(ref.read(photosControllerProvider(userId)).photos))
                        _buildActionIcon(
                          icon: Icons.delete_outline,
                          onTap: () => _deletePhoto(photo.id, userId),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Upload progress
              if (photo.isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: photo.uploadProgress,
                            color: AppColors.primaryPink,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(photo.uploadProgress * 100).toInt()}%',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPhotoPlaceholder({bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPink.withOpacity(0.1),
            AppColors.inputBorder.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: isLoading
          ? const CircularProgressIndicator(color: AppColors.primaryPink)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 32,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  'En modération',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
      ),
    );
  }
  
  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.primaryPink,
          size: 18,
        ),
      ),
    );
  }
  
  void _addPhoto() {
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
            Text('Ajouter une photo', style: AppTypography.h3),
            const SizedBox(height: 24),
            
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryPink),
              title: Text('Galerie', style: AppTypography.bodyBold),
              subtitle: Text('Choisir une photo existante', style: AppTypography.caption),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryPink),
              title: Text('Appareil photo', style: AppTypography.bodyBold),
              subtitle: Text('Prendre une nouvelle photo', style: AppTypography.caption),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.camera);
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final file = await StorageService.instance.pickImage(source: source);
    if (file != null) {
      final currentUser = ref.read(currentUserProvider)!;
      
      final success = await ref
          .read(photosControllerProvider(currentUser.id).notifier)
          .uploadPhoto(file);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploadée ! Elle sera vérifiée sous peu.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final error = ref.read(photosControllerProvider(currentUser.id)).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Erreur lors de l\'upload'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _showPhotoActions(UserPhoto photo, String userId) {
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
            // Header avec preview
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: photo.statusColor, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: photo.displayUrl != null
                      ? CachedNetworkImage(
                          imageUrl: photo.displayUrl!,
                          fit: BoxFit.cover,
                        )
                      : _buildPhotoPlaceholder(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(photo.statusText, style: AppTypography.bodyBold),
                      Text(photo.statusHelpText, style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Actions disponibles
            if (!photo.isMain && photo.canBeMain) ...[
              ListTile(
                leading: const Icon(Icons.star, color: AppColors.warning),
                title: Text('Définir comme principale', style: AppTypography.bodyBold),
                onTap: () {
                  Navigator.pop(context);
                  _setMainPhoto(photo.id, userId);
                },
              ),
            ],
            
            if (photo.isRejected) ...[
              ListTile(
                leading: const Icon(Icons.refresh, color: AppColors.primaryPink),
                title: Text('Remplacer cette photo', style: AppTypography.bodyBold),
                subtitle: Text('Upload une nouvelle photo', style: AppTypography.caption),
                onTap: () {
                  Navigator.pop(context);
                  _replacePhoto(photo, userId);
                },
              ),
            ],
            
            if (photo.canBeDeleted(ref.read(photosControllerProvider(userId)).photos)) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: Text('Supprimer', style: AppTypography.bodyBold),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePhoto(photo.id, userId);
                },
              ),
            ],
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Future<void> _setMainPhoto(String photoId, String userId) async {
    final success = await ref
        .read(photosControllerProvider(userId).notifier)
        .setMainPhoto(photoId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo principale mise à jour'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final error = ref.read(photosControllerProvider(userId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Erreur lors de la mise à jour'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  void _replacePhoto(UserPhoto photo, String userId) {
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
            Text('Remplacer la photo', style: AppTypography.h3),
            const SizedBox(height: 8),
            Text(
              'Raison du rejet: ${photo.moderationReason ?? "Non conforme"}',
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 24),
            
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryPink),
              title: Text('Galerie', style: AppTypography.bodyBold),
              onTap: () {
                Navigator.pop(context);
                _pickAndReplacePhoto(photo, ImageSource.gallery, userId);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryPink),
              title: Text('Appareil photo', style: AppTypography.bodyBold),
              onTap: () {
                Navigator.pop(context);
                _pickAndReplacePhoto(photo, ImageSource.camera, userId);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickAndReplacePhoto(UserPhoto oldPhoto, ImageSource source, String userId) async {
    final file = await StorageService.instance.pickImage(source: source);
    if (file != null) {
      final success = await ref
          .read(photosControllerProvider(userId).notifier)
          .replaceRejectedPhoto(photoId: oldPhoto.id, newImageFile: file);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo remplacée ! Elle sera vérifiée.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
  
  void _confirmDeletePhoto(String photoId, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette photo'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePhoto(photoId, userId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deletePhoto(String photoId, String userId) async {
    final success = await ref
        .read(photosControllerProvider(userId).notifier)
        .deletePhoto(photoId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo supprimée'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final error = ref.read(photosControllerProvider(userId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Erreur lors de la suppression'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
