import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/candidate.dart';
import '../../../services/match_service.dart' show SwipeDirection;
import '../controllers/feed_controller.dart';

/// Écran détails complet d'un candidat
class CandidateDetailsScreen extends ConsumerStatefulWidget {
  const CandidateDetailsScreen({
    super.key,
    required this.candidate,
  });
  
  final Candidate candidate;
  
  @override
  ConsumerState<CandidateDetailsScreen> createState() => _CandidateDetailsScreenState();
}

class _CandidateDetailsScreenState extends ConsumerState<CandidateDetailsScreen>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final photoUrl = ref.watch(feedControllerProvider).photoUrls[widget.candidate.id];
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SlideTransition(
        position: _slideAnimation,
        child: Stack(
          children: [
            // Photo plein écran
            _buildFullScreenPhoto(photoUrl),
            
            // Overlay dégradé
            _buildGradientOverlay(),
            
            // Header
            _buildHeader(),
            
            // Informations en bas
            _buildBottomInfo(),
            
            // Actions swipe
            _buildSwipeActions(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFullScreenPhoto(String? photoUrl) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: photoUrl != null
        ? CachedNetworkImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.textSecondary.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryPink),
              ),
            ),
            errorWidget: (context, url, error) => _buildPhotoPlaceholder(),
          )
        : _buildPhotoPlaceholder(),
    );
  }
  
  Widget _buildPhotoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPink.withOpacity(0.3),
            AppColors.primaryPink.withOpacity(0.1),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 120,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'Photo en modération',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGradientOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x40000000),
            Colors.transparent,
            Color(0x80000000),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Bouton retour
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.feed);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Badges
              Row(
                children: [
                  if (widget.candidate.isPremium)
                    _buildBadge(
                      icon: Icons.star,
                      text: 'Premium',
                      color: AppColors.warning,
                    ),
                  
                  if (widget.candidate.isVerified) ...[
                    const SizedBox(width: 8),
                    _buildBadge(
                      icon: Icons.verified,
                      text: 'Vérifié',
                      color: AppColors.success,
                    ),
                  ],
                  
                  if (widget.candidate.isBoosted) ...[
                    const SizedBox(width: 8),
                    _buildBadge(
                      icon: Icons.flash_on,
                      text: 'x${widget.candidate.boostMultiplier.toStringAsFixed(1)}',
                      color: AppColors.primaryPink,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.small.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomInfo() {
    return Positioned(
      bottom: 120, // Au-dessus des boutons swipe
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nom, âge, score
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.candidate.username}, ${widget.candidate.age}',
                    style: AppTypography.h2.copyWith(color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.candidate.scorePercent}% match',
                    style: AppTypography.small.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Niveau et styles
            Text(
              '${widget.candidate.level.displayName} • ${widget.candidate.rideStyles.map((e) => e.displayName).join(', ')}',
              style: AppTypography.body.copyWith(color: Colors.white70),
            ),
            
            const SizedBox(height: 12),
            
            // Bio
            if (widget.candidate.bio?.isNotEmpty == true) ...[
              Text(
                widget.candidate.bio!,
                style: AppTypography.body.copyWith(color: Colors.white),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            
            // Infos pratiques
            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.location_on,
                  text: '${widget.candidate.stationName} • ${widget.candidate.distanceDisplay}',
                ),
                const Spacer(),
                if (widget.candidate.speedDisplay != null)
                  _buildInfoItem(
                    icon: Icons.speed,
                    text: widget.candidate.speedDisplay!,
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Disponibilité
            _buildInfoItem(
              icon: Icons.calendar_today,
              text: 'Dispo ${widget.candidate.availabilityDisplay}',
            ),
            
            const SizedBox(height: 8),
            
            // Langues
            Row(
              children: [
                const Icon(Icons.translate, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.candidate.languages.join(', '),
                    style: AppTypography.caption.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.caption.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
  
  Widget _buildSwipeActions() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pass
              _buildActionButton(
                icon: Icons.close,
                color: AppColors.error,
                onPressed: () => _handleSwipe(SwipeDirection.dislike),
              ),
              
              // Super like
              _buildActionButton(
                icon: Icons.star,
                color: AppColors.warning,
                onPressed: () => _handleSwipe(SwipeDirection.superLike),
              ),
              
              // Like
              _buildActionButton(
                icon: Icons.favorite,
                color: AppColors.success,
                onPressed: () => _handleSwipe(SwipeDirection.like),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
  
  void _handleSwipe(SwipeDirection direction) {
    // Fermer modal avec animation
    _animationController.reverse().then((_) {
      if (context.canPop()) {
        context.pop();
      }
      
      // Effectuer swipe
      ref.read(feedControllerProvider.notifier).performSwipe(
        candidateId: widget.candidate.id,
        direction: direction,
      );
    });
  }
}
