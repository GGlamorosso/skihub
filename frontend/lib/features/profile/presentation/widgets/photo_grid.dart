import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../theme/app_colors.dart';
import '../../../../models/user_photo.dart';

/// Grille de photos 3x3 pour le profil (max 9 photos)
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.photos,
    this.onAddPhoto,
    this.onEditPhoto,
    this.onDeletePhoto,
    this.maxPhotos = 9,
  });
  
  final List<UserPhoto> photos;
  final VoidCallback? onAddPhoto;
  final Function(UserPhoto)? onEditPhoto;
  final Function(UserPhoto)? onDeletePhoto;
  final int maxPhotos;
  
  @override
  Widget build(BuildContext context) {
    final gridSize = (MediaQuery.of(context).size.width - 48) / 3; // 3 colonnes avec padding
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: maxPhotos,
      itemBuilder: (context, index) {
        if (index < photos.length) {
          // Photo existante
          final photo = photos[index];
          return _buildPhotoSlot(
            context,
            size: gridSize,
            photo: photo,
            onEdit: () => onEditPhoto?.call(photo),
            onDelete: () => onDeletePhoto?.call(photo),
          );
        } else {
          // Slot vide
          return _buildEmptySlot(
            context,
            size: gridSize,
            onTap: onAddPhoto,
          );
        }
      },
    );
  }
  
  Widget _buildPhotoSlot(
    BuildContext context, {
    required double size,
    required UserPhoto photo,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: photo.signedUrl != null
              ? CachedNetworkImage(
                  imageUrl: photo.signedUrl!,
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
                      Icons.broken_image,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : Container(
                  color: AppColors.inputBorder,
                  child: const Icon(
                    Icons.image,
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
        
        // Overlay avec bouton modifier
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptySlot(
    BuildContext context, {
    required double size,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inputBorder.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.inputBorder,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: AppColors.textSecondary,
            size: 32,
          ),
        ),
      ),
    );
  }
}

