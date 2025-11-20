import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../components/buttons.dart';
import '../../../components/candidate_card.dart';
import '../../../components/bottom_navigation.dart';
import '../../../models/candidate.dart' hide QuotaInfo;
import '../../../models/subscription.dart' show QuotaInfo, QuotaType;
import '../../../models/station.dart';
import '../../../services/match_service.dart';
import '../controllers/feed_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import 'filters_bottom_sheet.dart';
import 'match_modal.dart';

/// Écran Swipe principal (S3 - Backend intégré)
class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});
  
  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _swipeAnimationController;
  late AnimationController _stackAnimationController;
  
  Offset _swipeOffset = Offset.zero;
  double _swipeRotation = 0.0;
  bool _isDragging = false;
  SwipeDirection? _previewDirection;
  
  @override
  void initState() {
    super.initState();
    
    _swipeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _stackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Charger profil et candidats au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).loadProfile();
    });
  }
  
  @override
  void dispose() {
    _swipeAnimationController.dispose();
    _stackAnimationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final currentStation = profileState.currentStation;
    
    // Écouter les matches pour afficher modal
    ref.listen<FeedState>(feedControllerProvider, (previous, current) {
      if (current.hasMatch && previous?.hasMatch != true) {
        if (current.lastSwipeResult?.matchResult != null) {
          _showMatchModal(current.lastSwipeResult!.matchResult!);
        }
      }
    });
    
    return AppScaffold(
      currentIndex: 0, // Feed = index 0
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec station et quotas
              _buildHeader(currentStation, feedState.quotaInfo),
              
              // Zone de swipe principale
              Expanded(
                child: _buildSwipeArea(feedState),
              ),
              
              // Actions en bas
              _buildSwipeActions(feedState),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(UserStationStatus? currentStation, QuotaInfo? quotaInfo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Logo mini
          GestureDetector(
            onTap: () => ref.read(feedControllerProvider.notifier).refresh(),
            child: const Text('❄️', style: TextStyle(fontSize: 24)),
          ),
          
          const Spacer(),
          
          // Station actuelle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [AppColors.cardShadow],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primaryPink,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  currentStation?.station?.name ?? 'Station',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Actions header
          Row(
            children: [
              // Filtres
              GestureDetector(
                onTap: _showFilters,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [AppColors.cardShadow],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.tune,
                          color: AppColors.primaryPink,
                          size: 20,
                        ),
                      ),
                      if (ref.watch(feedFiltersProvider)?.activeFiltersCount != 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Quotas
              if (quotaInfo != null)
                GestureDetector(
                  onTap: _showQuotaInfo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: quotaInfo.limitReached 
                        ? AppColors.error.withOpacity(0.1)
                        : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: quotaInfo.limitReached 
                          ? AppColors.error 
                          : AppColors.inputBorder,
                      ),
                    ),
                    child: Text(
                      '${quotaInfo.swipeRemaining}',
                      style: AppTypography.caption.copyWith(
                        color: quotaInfo.limitReached 
                          ? AppColors.error 
                          : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(width: 12),
              
              // Avatar profil
              GestureDetector(
                onTap: () {
                  // TODO S4: Navigation vers profil
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil S4')),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    shape: BoxShape.circle,
                    boxShadow: [AppColors.cardShadow],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSwipeArea(FeedState feedState) {
    if (feedState.isLoading) {
      return _buildLoadingState();
    }
    
    if (feedState.hasError) {
      return _buildErrorState(feedState.error!);
    }
    
    if (!feedState.hasCandidates || !feedState.hasCurrentCandidate) {
      return _buildNoMoreCandidates();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          // Carte suivante (arrière-plan)
          if (feedState.currentIndex + 1 < feedState.candidates.length)
            _buildBackgroundCard(feedState.candidates[feedState.currentIndex + 1]),
          
          // Carte actuelle avec gestes
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CandidateCard(
              candidate: feedState.currentCandidate!,
              photoUrl: feedState.photoUrls[feedState.currentCandidate!.id],
              swipeOffset: _swipeOffset,
              rotation: _swipeRotation,
              showSwipeOverlay: _isDragging && _previewDirection != null,
              swipeDirection: _previewDirection,
              onTap: () => _showCandidateDetails(feedState.currentCandidate!),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBackgroundCard(Candidate candidate) {
    return Transform.scale(
      scale: 0.95,
      child: Opacity(
        opacity: 0.5,
        child: CandidateCard(
          candidate: candidate,
          photoUrl: ref.watch(feedControllerProvider).photoUrls[candidate.id],
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryPink),
          SizedBox(height: 16),
          Text('Recherche de ton crew...'),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center, style: AppTypography.body),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Réessayer',
            onPressed: () => ref.read(feedControllerProvider.notifier).refresh(),
            width: 200,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoMoreCandidates() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_off_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('Plus de profils pour le moment', style: AppTypography.h3),
          const SizedBox(height: 8),
          Text('Élargis tes critères ou reviens plus tard', style: AppTypography.body),
          const SizedBox(height: 32),
          PrimaryButton(
            text: 'Modifier les filtres',
            onPressed: _showFilters,
            width: 200,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            text: 'Actualiser',
            onPressed: () => ref.read(feedControllerProvider.notifier).refresh(),
            width: 200,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSwipeActions(FeedState feedState) {
    final canSwipe = feedState.hasCurrentCandidate && 
                    !feedState.isSwipping && 
                    !feedState.hasQuotaLimit;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Passer
          SwipeActionButton(
            icon: Icons.close,
            type: SwipeActionType.pass,
            onPressed: canSwipe ? _handlePass : null,
          ),
          
          // Super like
          SwipeActionButton(
            icon: Icons.star,
            type: SwipeActionType.superLike,
            onPressed: canSwipe ? _handleSuperLike : null,
          ),
          
          // Like
          SwipeActionButton(
            icon: Icons.favorite,
            type: SwipeActionType.like,
            onPressed: canSwipe ? _handleLike : null,
          ),
        ],
      ),
    );
  }
  
  // Gestion gestes swipe
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _swipeOffset += details.delta;
      _swipeRotation = _swipeOffset.dx / 1000;
      
      // Déterminer direction preview
      if (_swipeOffset.dx.abs() > 50) {
        _previewDirection = _swipeOffset.dx > 0 ? SwipeDirection.like : SwipeDirection.dislike;
      } else if (_swipeOffset.dy < -50) {
        _previewDirection = SwipeDirection.superLike;
      } else {
        _previewDirection = null;
      }
    });
  }
  
  void _onPanEnd(DragEndDetails details) {
    final threshold = MediaQuery.of(context).size.width * 0.3;
    
    if (_swipeOffset.dx.abs() > threshold || _swipeOffset.dy < -100) {
      // Swipe validé
      if (_swipeOffset.dx > threshold) {
        _performSwipe(SwipeDirection.like);
      } else if (_swipeOffset.dx < -threshold) {
        _performSwipe(SwipeDirection.dislike);
      } else if (_swipeOffset.dy < -100) {
        _performSwipe(SwipeDirection.superLike);
      }
    } else {
      // Reset position
      _resetCardPosition();
    }
  }
  
  void _resetCardPosition() {
    setState(() {
      _swipeOffset = Offset.zero;
      _swipeRotation = 0.0;
      _isDragging = false;
      _previewDirection = null;
    });
  }
  
  void _performSwipe(SwipeDirection direction) {
    final candidate = ref.read(feedControllerProvider).currentCandidate;
    if (candidate != null) {
      ref.read(feedControllerProvider.notifier).performSwipe(
        candidateId: candidate.id,
        direction: direction,
      );
    }
    _resetCardPosition();
  }
  
  void _handleLike() {
    final candidate = ref.read(feedControllerProvider).currentCandidate;
    if (candidate != null) {
      ref.read(feedControllerProvider.notifier).like(candidate.id);
    }
  }
  
  void _handlePass() {
    final candidate = ref.read(feedControllerProvider).currentCandidate;
    if (candidate != null) {
      ref.read(feedControllerProvider.notifier).dislike(candidate.id);
    }
  }
  
  void _handleSuperLike() {
    final candidate = ref.read(feedControllerProvider).currentCandidate;
    if (candidate != null) {
      ref.read(feedControllerProvider.notifier).superLike(candidate.id);
    }
  }
  
  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FiltersBottomSheet(),
    );
  }
  
  void _showQuotaInfo() {
    final quotaInfo = ref.read(feedControllerProvider).quotaInfo;
    if (quotaInfo == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quotas journaliers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getQuotaMessage(quotaInfo)),
            if (_getResetTimeDisplay(quotaInfo) != null) ...[
              const SizedBox(height: 8),
              Text(
                _getResetTimeDisplay(quotaInfo)!,
                style: AppTypography.caption,
              ),
            ],
            if (quotaInfo.limitReached) ...[
              const SizedBox(height: 16),
              const Text('💎 Passe en Premium pour des swipes illimités !'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (quotaInfo.limitReached)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO S7: Navigation vers premium
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium S7')),
                );
              },
              child: const Text('Devenir Premium'),
            ),
        ],
      ),
    );
  }
  
  void _showCandidateDetails(Candidate candidate) {
    // ✅ Naviguer vers l'écran de détails avec le candidat
    context.push(
      '/candidate-details/${candidate.id}',
      extra: candidate, // Passer le candidat complet via extra
    );
  }
  
  void _showMatchModal(MatchResult matchResult) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MatchModal(
        matchResult: matchResult,
        onContinueSwiping: () {
          Navigator.pop(context);
          ref.read(feedControllerProvider.notifier).clearMatchResult();
        },
        onStartChatting: () {
          Navigator.pop(context);
          ref.read(feedControllerProvider.notifier).clearMatchResult();
          // TODO S4: Navigation vers chat
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat S4')),
          );
        },
      ),
    );
  }
  
  String _getQuotaMessage(QuotaInfo quotaInfo) {
    if (quotaInfo.limitReached) {
      if (quotaInfo.limitType == QuotaType.swipe) {
        return 'Limite de swipes atteinte. Plus que ${quotaInfo.swipeRemaining} swipes.';
      } else if (quotaInfo.limitType == QuotaType.message) {
        return 'Limite de messages atteinte. Plus que ${quotaInfo.messageRemaining} messages.';
  }
      return 'Limite quotidienne atteinte.';
  }
  
    if (quotaInfo.swipeRemaining <= 5) {
      return 'Plus que ${quotaInfo.swipeRemaining} swipes aujourd\'hui.';
  }
  
    return '${quotaInfo.swipeRemaining} swipes restants.';
  }
  
  String? _getResetTimeDisplay(QuotaInfo quotaInfo) {
    final now = DateTime.now();
    final diff = quotaInfo.resetsAt.difference(now);
    
    if (diff.inHours > 0) {
      return 'Reset dans ${diff.inHours}h${diff.inMinutes % 60}min';
    } else if (diff.inMinutes > 0) {
      return 'Reset dans ${diff.inMinutes}min';
    }
    
    return 'Reset imminent';
  }
}
