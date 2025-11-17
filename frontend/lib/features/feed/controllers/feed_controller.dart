import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/candidate.dart' hide QuotaInfo;
import '../../../models/subscription.dart' show QuotaInfo;
import '../../../services/match_service.dart';
import '../../../utils/error_handler.dart';

/// État du feed de candidats
@immutable
class FeedState {
  const FeedState({
    this.candidates = const [],
    this.currentIndex = 0,
    this.photoUrls = const {},
    this.quotaInfo,
    this.filters,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSwipping = false,
    this.error,
    this.hasMoreCandidates = true,
    this.lastSwipeResult,
  });
  
  final List<Candidate> candidates;
  final int currentIndex;
  final Map<String, String> photoUrls; // candidate_id -> signed_url
  final QuotaInfo? quotaInfo;
  final SwipeFilters? filters;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSwipping;
  final String? error;
  final bool hasMoreCandidates;
  final SwipeResult? lastSwipeResult;
  
  bool get hasError => error != null;
  bool get hasCandidates => candidates.isNotEmpty;
  bool get hasCurrentCandidate => currentIndex < candidates.length;
  Candidate? get currentCandidate => hasCurrentCandidate ? candidates[currentIndex] : null;
  bool get needsMoreCandidates => candidates.length - currentIndex <= 2;
  bool get hasQuotaLimit => quotaInfo?.limitReached == true;
  bool get hasMatch => lastSwipeResult?.matchResult?.matched == true;
  
  FeedState copyWith({
    List<Candidate>? candidates,
    int? currentIndex,
    Map<String, String>? photoUrls,
    QuotaInfo? quotaInfo,
    SwipeFilters? filters,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSwipping,
    String? error,
    bool? hasMoreCandidates,
    SwipeResult? lastSwipeResult,
  }) {
    return FeedState(
      candidates: candidates ?? this.candidates,
      currentIndex: currentIndex ?? this.currentIndex,
      photoUrls: photoUrls ?? this.photoUrls,
      quotaInfo: quotaInfo ?? this.quotaInfo,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSwipping: isSwipping ?? this.isSwipping,
      error: error,
      hasMoreCandidates: hasMoreCandidates ?? this.hasMoreCandidates,
      lastSwipeResult: lastSwipeResult ?? this.lastSwipeResult,
    );
  }
}

/// Controller pour le feed
class FeedController extends StateNotifier<FeedState> {
  FeedController() : super(const FeedState()) {
    _init();
  }
  
  final _matchService = MatchService.instance;
  
  /// Initialisation du feed
  Future<void> _init() async {
    await loadCandidates(refresh: true);
    await _loadQuotas();
  }
  
  /// Charger candidats
  Future<void> loadCandidates({
    bool refresh = false,
    int limit = 10,
  }) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentIndex: 0,
        candidates: [],
        hasMoreCandidates: true,
      );
    } else {
      state = state.copyWith(isLoadingMore: true, error: null);
    }
    
    try {
      final cursor = refresh ? null : _getNextCursor();
      
      final newCandidates = await _matchService.fetchCandidates(
        limit: limit,
        cursor: cursor,
        filters: state.filters,
      );
      
      // Filtrer candidats déjà vus
      final unseenCandidates = newCandidates
          .where((candidate) => !_matchService.hasBeenSeen(candidate.id))
          .toList();
      
      // Pré-charger URLs photos
      final photoUrls = await _matchService.preloadPhotoUrls(unseenCandidates);
      
      final updatedCandidates = refresh 
          ? unseenCandidates
          : [...state.candidates, ...unseenCandidates];
      
      final updatedPhotoUrls = refresh
          ? photoUrls
          : {...state.photoUrls, ...photoUrls};
      
      state = state.copyWith(
        candidates: updatedCandidates,
        photoUrls: updatedPhotoUrls,
        isLoading: false,
        isLoadingMore: false,
        hasMoreCandidates: newCandidates.length >= limit,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: ErrorHandler.getReadableError(e),
      );
      
      ErrorHandler.logError(
        context: 'FeedController.loadCandidates',
        error: e,
        additionalData: {'refresh': refresh, 'limit': limit},
      );
    }
  }
  
  /// Effectuer un swipe
  Future<void> performSwipe({
    required String candidateId,
    required SwipeDirection direction,
  }) async {
    if (state.isSwipping || state.hasQuotaLimit) return;
    
    state = state.copyWith(isSwipping: true, error: null);
    
    try {
      final result = await _matchService.swipe(
        likedId: candidateId,
        direction: direction,
      );
      
      // Marquer comme vu
      _matchService.markAsSeen(candidateId);
      
      // Avancer à la carte suivante
      final newIndex = state.currentIndex + 1;
      
      state = state.copyWith(
        currentIndex: newIndex,
        isSwipping: false,
        quotaInfo: result.quotaInfo,
        lastSwipeResult: result,
      );
      
      // Charger plus de candidats si nécessaire
      if (state.needsMoreCandidates && state.hasMoreCandidates) {
        await loadCandidates();
      }
    } catch (e) {
      state = state.copyWith(
        isSwipping: false,
        error: ErrorHandler.getReadableError(e),
      );
      
      ErrorHandler.logError(
        context: 'FeedController.performSwipe',
        error: e,
        additionalData: {
          'candidate_id': candidateId,
          'direction': direction.name,
        },
      );
    }
  }
  
  /// Like
  Future<void> like(String candidateId) async {
    await performSwipe(candidateId: candidateId, direction: SwipeDirection.like);
  }
  
  /// Dislike (pass)
  Future<void> dislike(String candidateId) async {
    await performSwipe(candidateId: candidateId, direction: SwipeDirection.dislike);
  }
  
  /// Super like
  Future<void> superLike(String candidateId) async {
    await performSwipe(candidateId: candidateId, direction: SwipeDirection.superLike);
  }
  
  /// Appliquer filtres
  Future<void> applyFilters(SwipeFilters filters) async {
    state = state.copyWith(filters: filters);
    await loadCandidates(refresh: true);
  }
  
  /// Reset filtres
  Future<void> resetFilters() async {
    state = state.copyWith(filters: SwipeFilters.defaultFilters());
    await loadCandidates(refresh: true);
  }
  
  /// Refresh feed
  Future<void> refresh() async {
    _matchService.clearSeenProfiles();
    await loadCandidates(refresh: true);
    await _loadQuotas();
  }
  
  /// Charger quotas actuels
  Future<void> _loadQuotas() async {
    try {
      final quotaInfo = await _matchService.getCurrentQuotas();
      state = state.copyWith(quotaInfo: quotaInfo);
    } catch (e) {
      debugPrint('Error loading quotas: $e');
    }
  }
  
  /// Obtenir curseur pour pagination
  String? _getNextCursor() {
    if (state.candidates.isEmpty) return null;
    
    final lastCandidate = state.candidates.last;
    return '${lastCandidate.score}_${lastCandidate.distanceKm}_${lastCandidate.id}';
  }
  
  /// Undo dernier swipe (premium feature)
  Future<void> undoLastSwipe() async {
    // TODO S7: Implémenter undo pour utilisateurs premium
    if (state.currentIndex > 0) {
      state = state.copyWith(
        currentIndex: state.currentIndex - 1,
        lastSwipeResult: null,
      );
    }
  }
  
  /// Clear match result (après affichage modal)
  void clearMatchResult() {
    state = state.copyWith(lastSwipeResult: null);
  }
  
  /// Clear erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Skip candidat actuel sans swipe
  void skipCurrent() {
    if (state.hasCurrentCandidate) {
      final candidateId = state.currentCandidate!.id;
      _matchService.markAsSeen(candidateId);
      
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
      );
      
      // Charger plus si nécessaire
      if (state.needsMoreCandidates && state.hasMoreCandidates) {
        loadCandidates();
      }
    }
  }
}

/// Providers pour le feed
final feedControllerProvider = StateNotifierProvider<FeedController, FeedState>((ref) {
  return FeedController();
});

final currentCandidateProvider = Provider<Candidate?>((ref) {
  return ref.watch(feedControllerProvider).currentCandidate;
});

final quotaInfoProvider = Provider<QuotaInfo?>((ref) {
  return ref.watch(feedControllerProvider).quotaInfo;
});

final feedFiltersProvider = Provider<SwipeFilters?>((ref) {
  return ref.watch(feedControllerProvider).filters;
});

final hasMatchProvider = Provider<bool>((ref) {
  return ref.watch(feedControllerProvider).hasMatch;
});
