import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/candidate.dart';
import '../services/match_service.dart' show SwipeDirection;

/// Carte candidat pour le feed Tinder-like
class CandidateCard extends StatefulWidget {
  const CandidateCard({
    super.key,
    required this.candidate,
    this.photoUrl,
    this.onTap,
    this.swipeOffset = Offset.zero,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.showSwipeOverlay = false,
    this.swipeDirection,
  });
  
  final Candidate candidate;
  final String? photoUrl;
  final VoidCallback? onTap;
  final Offset swipeOffset;
  final double rotation;
  final double scale;
  final bool showSwipeOverlay;
  final SwipeDirection? swipeDirection;
  
  @override
  State<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<CandidateCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: widget.scale,
      child: Transform.rotate(
        angle: widget.rotation,
        child: Transform.translate(
          offset: widget.swipeOffset,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildCard(),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildCard() {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPink.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Photo principale
              _buildMainPhoto(),
              
              // Overlay dégradé
              _buildGradientOverlay(),
              
              // Boost badge
              if (widget.candidate.isBoosted) _buildBoostBadge(),
              
              // Premium badge
              if (widget.candidate.isPremium) _buildPremiumBadge(),
              
              // Verified badge
              if (widget.candidate.isVerified) _buildVerifiedBadge(),
              
              // Informations en bas
              _buildInfoSection(),
              
              // Overlay swipe (like/dislike)
              if (widget.showSwipeOverlay) _buildSwipeOverlay(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainPhoto() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: widget.photoUrl != null
        ? CachedNetworkImage(
            imageUrl: widget.photoUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildPhotoPlaceholder(isLoading: true),
            errorWidget: (context, url, error) => _buildPhotoPlaceholder(),
          )
        : _buildPhotoPlaceholder(),
    );
  }
  
  Widget _buildPhotoPlaceholder({bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPink.withOpacity(0.2),
            AppColors.primaryPink.withOpacity(0.05),
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
                  Icons.person_outline,
                  size: 120,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Photo en modération',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
      ),
    );
  }
  
  Widget _buildGradientOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 200,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Color(0x80000000),
              Color(0xCC000000),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBoostBadge() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flash_on, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              'x${widget.candidate.boostMultiplier.toStringAsFixed(1)}',
              style: AppTypography.small.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPremiumBadge() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [AppColors.primaryShadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              'Premium',
              style: AppTypography.small.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerifiedBadge() {
    return Positioned(
      top: widget.candidate.isPremium ? 60 : 16,
      left: 16,
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
    );
  }
  
  Widget _buildInfoSection() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nom et âge
            Text(
              '${widget.candidate.username}, ${widget.candidate.age}',
              style: AppTypography.profileName,
            ),
            
            const SizedBox(height: 8),
            
            // Niveau et score
            Row(
              children: [
                Text(
                  widget.candidate.level.displayName,
                  style: AppTypography.profileInfo,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.candidate.scorePercent}% match',
                    style: AppTypography.small.copyWith(
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Styles de ride
            Text(
              widget.candidate.rideStyles.map((e) => e.displayName).join(' • '),
              style: AppTypography.profileInfo,
            ),
            
            const SizedBox(height: 12),
            
            // Langues et stats
            Row(
              children: [
                // Langues (drapeaux)
                Row(
                  children: widget.candidate.languages.take(3).map((lang) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        _getLanguageFlag(lang),
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  }).toList(),
                ),
                
                const Spacer(),
                
                // Stats vitesse
                if (widget.candidate.speedDisplay != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.speed,
                          color: AppColors.primaryPink,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.candidate.speedDisplay!,
                          style: AppTypography.small.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Distance et station
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${widget.candidate.stationName} • ${widget.candidate.distanceDisplay}',
                    style: AppTypography.profileInfo.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Disponibilité
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Dispo ${widget.candidate.availabilityDisplay}',
                  style: AppTypography.profileInfo.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const Spacer(),
                if (widget.candidate.remainingDays > 0)
                  Text(
                    '${widget.candidate.remainingDays}j restants',
                    style: AppTypography.small.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSwipeOverlay() {
    if (widget.swipeDirection == null) return const SizedBox();
    
    Color overlayColor;
    String overlayText;
    IconData overlayIcon;
    
    switch (widget.swipeDirection!) {
      case SwipeDirection.like:
        overlayColor = AppColors.success;
        overlayText = 'LIKE';
        overlayIcon = Icons.favorite;
        break;
      case SwipeDirection.dislike:
        overlayColor = AppColors.error;
        overlayText = 'PASS';
        overlayIcon = Icons.close;
        break;
      case SwipeDirection.superLike:
        overlayColor = AppColors.warning;
        overlayText = 'SUPER LIKE';
        overlayIcon = Icons.star;
        break;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: overlayColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              overlayIcon,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              overlayText,
              style: AppTypography.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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

/// Carte candidat simplifiée pour preview
class CandidateCardPreview extends StatelessWidget {
  const CandidateCardPreview({
    super.key,
    required this.candidate,
    this.photoUrl,
    this.onTap,
  });
  
  final Candidate candidate;
  final String? photoUrl;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppColors.cardShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Photo
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.inputBorder,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.inputBorder,
                      child: const Icon(
                        Icons.person_outline,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                    ),
              ),
              
              // Overlay info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        candidate.username,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        candidate.level.displayName,
                        style: AppTypography.small.copyWith(
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
