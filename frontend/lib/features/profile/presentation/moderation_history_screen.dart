import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../router/app_router.dart';

import '../../../components/layout.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/user_photo.dart';
import '../controllers/photos_controller.dart';
import '../../auth/controllers/auth_controller.dart';

/// Écran historique des modérations
class ModerationHistoryScreen extends ConsumerWidget {
  const ModerationHistoryScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          _buildHeader(context),
          
          // Résumé modération
          _buildModerationSummary(photosState),
          
          // Liste historique
          Expanded(
            child: _buildHistoryList(photosState, currentUser.id, ref),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
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
            'Historique Modération',
            style: AppTypography.h3,
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
  
  Widget _buildModerationSummary(PhotosState photosState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        children: [
          Text(
            'Résumé de modération',
            style: AppTypography.h3,
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                count: photosState.approvedCount,
                label: 'Approuvées',
                color: AppColors.success,
                icon: Icons.check_circle,
              ),
              _buildSummaryItem(
                count: photosState.pendingCount,
                label: 'En attente',
                color: AppColors.warning,
                icon: Icons.schedule,
              ),
              _buildSummaryItem(
                count: photosState.rejectedCount,
                label: 'Rejetées',
                color: AppColors.error,
                icon: Icons.cancel,
              ),
            ],
          ),
          
          if (photosState.pendingCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La modération prend généralement 2-5 minutes. Vous recevrez une notification.',
                      style: AppTypography.small.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (photosState.rejectedCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_outlined, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Photos rejetées : vérifiez que votre visage est visible et respectez nos règles.',
                      style: AppTypography.small.copyWith(color: AppColors.error),
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
  
  Widget _buildSummaryItem({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                count.toString(),
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.small.copyWith(color: color),
        ),
      ],
    );
  }
  
  Widget _buildHistoryList(PhotosState photosState, String userId, WidgetRef ref) {
    if (photosState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      );
    }
    
    if (!photosState.hasPhotos) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun historique',
              style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos photos apparaîtront ici après modération.',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          ],
        ),
      );
    }
    
    // Grouper par statut
    final groupedPhotos = <ModerationStatus, List<UserPhoto>>{};
    for (final photo in photosState.photos) {
      groupedPhotos.putIfAbsent(photo.moderationStatus, () => []).add(photo);
    }
    
    return RefreshIndicator(
      onRefresh: () => ref.read(photosControllerProvider(userId).notifier).refresh(),
      color: AppColors.primaryPink,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Photos rejetées (priorité)
          if (groupedPhotos[ModerationStatus.rejected]?.isNotEmpty == true)
            _buildStatusSection(
              'Photos rejetées',
              groupedPhotos[ModerationStatus.rejected]!,
              AppColors.error,
              Icons.cancel,
              userId,
              ref,
            ),
          
          // Photos en attente
          if (groupedPhotos[ModerationStatus.pending]?.isNotEmpty == true) ...[
            const SizedBox(height: 24),
            _buildStatusSection(
              'En cours de modération',
              groupedPhotos[ModerationStatus.pending]!,
              AppColors.warning,
              Icons.schedule,
              userId,
              ref,
            ),
          ],
          
          // Photos approuvées
          if (groupedPhotos[ModerationStatus.approved]?.isNotEmpty == true) ...[
            const SizedBox(height: 24),
            _buildStatusSection(
              'Photos approuvées',
              groupedPhotos[ModerationStatus.approved]!,
              AppColors.success,
              Icons.check_circle,
              userId,
              ref,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatusSection(
    String title,
    List<UserPhoto> photos,
    Color color,
    IconData icon,
    String userId,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.h3.copyWith(color: color),
            ),
            const Spacer(),
            Text(
              '${photos.length}',
              style: AppTypography.caption.copyWith(color: color),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        ...photos.map((photo) => _buildHistoryItem(photo, userId, ref)),
      ],
    );
  }
  
  Widget _buildHistoryItem(UserPhoto photo, String userId, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: photo.statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Thumbnail
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
                    placeholder: (context, url) => Container(
                      color: AppColors.inputBorder,
                      child: const Icon(Icons.image, color: AppColors.textSecondary),
                    ),
                  )
                : Container(
                    color: AppColors.inputBorder,
                    child: const Icon(Icons.image, color: AppColors.textSecondary),
                  ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(photo.statusIcon, color: photo.statusColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      photo.statusText,
                      style: AppTypography.bodyBold.copyWith(color: photo.statusColor),
                    ),
                    const Spacer(),
                    if (photo.isMain)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Principale',
                          style: AppTypography.small.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  photo.statusHelpText,
                  style: AppTypography.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  'Uploadée le ${photo.createdAt.day}/${photo.createdAt.month}/${photo.createdAt.year}',
                  style: AppTypography.small.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          
          // Actions
          if (photo.isRejected) ...[
            const SizedBox(width: 8),
            Builder(
              builder: (context) => IconButton(
                onPressed: () => _replacePhoto(photo, userId, ref, context),
                icon: const Icon(Icons.refresh, color: AppColors.primaryPink),
                tooltip: 'Remplacer',
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _replacePhoto(UserPhoto photo, String userId, WidgetRef ref, BuildContext context) {
    // Rediriger vers galerie avec action replace
    if (context.canPop()) {
      context.pop();
    }
    context.push('/photo-gallery');
    
    // TODO S5: Passer photoId pour action directe
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Remplacez la photo rejetée dans la galerie'),
        backgroundColor: AppColors.warning,
      ),
    );
  }
}
