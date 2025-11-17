import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../components/buttons.dart';
import '../../../models/candidate.dart';

/// Modal de match avec animation
class MatchModal extends StatefulWidget {
  const MatchModal({
    super.key,
    required this.matchResult,
    required this.onContinueSwiping,
    required this.onStartChatting,
  });
  
  final MatchResult matchResult;
  final VoidCallback onContinueSwiping;
  final VoidCallback onStartChatting;
  
  @override
  State<MatchModal> createState() => _MatchModalState();
}

class _MatchModalState extends State<MatchModal>
    with TickerProviderStateMixin {
  
  late AnimationController _scaleController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _heartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: const Interval(0.3, 1.0, curve: Curves.bounceOut),
    ));
    
    // Démarrer animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _heartController.forward();
    });
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    _heartController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.backgroundGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animation cœurs
                  AnimatedBuilder(
                    animation: _heartAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _heartAnimation.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Cœur principal
                            Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                gradient: AppColors.buttonGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.favorite,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            
                            // Particules autour
                            ...List.generate(8, (index) {
                              final angle = (index * 45) * (3.14159 / 180);
                              return Transform.translate(
                                offset: Offset(
                                  60 * _heartAnimation.value * (index % 2 == 0 ? 1 : -1) * 0.5,
                                  60 * _heartAnimation.value * (index % 3 == 0 ? 1 : -1) * 0.5,
                                ),
                                child: Opacity(
                                  opacity: 1.0 - _heartAnimation.value,
                                  child: const Icon(
                                    Icons.favorite,
                                    size: 16,
                                    color: AppColors.primaryPink,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Titre
                  Text(
                    'C\'est un match ! 🎉',
                    style: AppTypography.h1.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Message
                  Text(
                    widget.matchResult.message ?? 
                    'Vous vous êtes likés mutuellement !',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Preview profils (si disponible)
                  // TODO S3: Afficher photos des deux profils
                  
                  const SizedBox(height: 32),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: 'Continuer le swipe',
                          onPressed: widget.onContinueSwiping,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          text: 'Parler maintenant',
                          onPressed: widget.onStartChatting,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Modal pour détails candidat
class CandidateDetailsModal extends StatelessWidget {
  const CandidateDetailsModal({
    super.key,
    required this.candidate,
    this.photoUrl,
  });
  
  final Candidate candidate;
  final String? photoUrl;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header avec photo
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Photo principale
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.inputBorder,
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                          )
                        : Container(
                            color: AppColors.inputBorder,
                            child: const Center(
                              child: Icon(Icons.person_outline, size: 80),
                            ),
                          ),
                    ),
                  ),
                  
                  // Bouton fermer
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Informations détaillées
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom, âge, niveau
                    Text(
                      '${candidate.username}, ${candidate.age}',
                      style: AppTypography.h2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      candidate.level.displayName,
                      style: AppTypography.body.copyWith(
                        color: AppColors.primaryPink,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Bio
                    if (candidate.bio?.isNotEmpty == true) ...[
                      Text(
                        candidate.bio!,
                        style: AppTypography.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Stats et infos
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.location_on,
                          text: candidate.distanceDisplay,
                        ),
                        const SizedBox(width: 8),
                        if (candidate.speedDisplay != null)
                          _buildInfoChip(
                            icon: Icons.speed,
                            text: candidate.speedDisplay!,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Styles et langues
                    Text(
                      'Styles: ${candidate.rideStyles.map((e) => e.displayName).join(', ')}',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Langues: ${candidate.languages.join(', ')}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryPink),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.small.copyWith(
              color: AppColors.primaryPink,
            ),
          ),
        ],
      ),
    );
  }
}
