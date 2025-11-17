import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/match.dart';
import '../../../services/chat_service.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/error_handler.dart';

/// État des matches
@immutable
class MatchesState {
  const MatchesState({
    this.matches = const [],
    this.photoUrls = const {},
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMoreMatches = true,
    this.totalUnreadCount = 0,
  });
  
  final List<Match> matches;
  final Map<String, String> photoUrls; // user_id -> photo_url
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMoreMatches;
  final int totalUnreadCount;
  
  bool get hasError => error != null;
  bool get hasMatches => matches.isNotEmpty;
  bool get hasUnreadMessages => totalUnreadCount > 0;
  
  MatchesState copyWith({
    List<Match>? matches,
    Map<String, String>? photoUrls,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMoreMatches,
    int? totalUnreadCount,
  }) {
    return MatchesState(
      matches: matches ?? this.matches,
      photoUrls: photoUrls ?? this.photoUrls,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMoreMatches: hasMoreMatches ?? this.hasMoreMatches,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
    );
  }
}

/// Controller pour les matches
class MatchesController extends StateNotifier<MatchesState> {
  MatchesController() : super(const MatchesState()) {
    _init();
  }
  
  final _chatService = ChatService.instance;
  
  /// Initialisation
  Future<void> _init() async {
    await loadMatches(refresh: true);
    await _loadTotalUnreadCount();
  }
  
  /// Charger matches
  Future<void> loadMatches({
    bool refresh = false,
    int limit = 20,
  }) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        matches: [],
        hasMoreMatches: true,
      );
    } else {
      state = state.copyWith(isLoadingMore: true, error: null);
    }
    
    try {
      final offset = refresh ? 0 : state.matches.length;
      
      final newMatches = await _chatService.getMatches(
        limit: limit,
        offset: offset,
      );
      
      // Charger photos des autres utilisateurs
      final photoUrls = await _loadMatchPhotos(newMatches);
      
      final updatedMatches = refresh 
          ? newMatches
          : [...state.matches, ...newMatches];
      
      final updatedPhotoUrls = refresh
          ? photoUrls
          : {...state.photoUrls, ...photoUrls};
      
      state = state.copyWith(
        matches: updatedMatches,
        photoUrls: updatedPhotoUrls,
        isLoading: false,
        isLoadingMore: false,
        hasMoreMatches: newMatches.length >= limit,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: ErrorHandler.getReadableError(e),
      );
      
      ErrorHandler.logError(
        context: 'MatchesController.loadMatches',
        error: e,
        additionalData: {'refresh': refresh, 'limit': limit},
      );
    }
  }
  
  /// Charger photos des matches
  Future<Map<String, String>> _loadMatchPhotos(List<Match> matches) async {
    final Map<String, String> urls = {};
    
    for (final match in matches) {
      if (match.otherUser != null) {
        try {
          final photoUrl = await _chatService.getOtherUserPhotoUrl(match.otherUser!.id);
          if (photoUrl != null) {
            urls[match.otherUser!.id] = photoUrl;
          }
        } catch (e) {
          debugPrint('Error loading photo for ${match.otherUser!.id}: $e');
        }
      }
    }
    
    return urls;
  }
  
  /// Charger nombre total de messages non lus
  Future<void> _loadTotalUnreadCount() async {
    try {
      final count = await _chatService.getTotalUnreadCount();
      state = state.copyWith(totalUnreadCount: count);
    } catch (e) {
      debugPrint('Error loading total unread count: $e');
    }
  }
  
  /// Marquer match comme lu
  Future<void> markMatchAsRead(String matchId) async {
    try {
      final success = await _chatService.markMessagesAsRead(matchId: matchId);
      
      if (success) {
        // Mettre à jour état local
        final updatedMatches = state.matches.map((match) {
          if (match.id == matchId) {
            return Match(
              id: match.id,
              user1Id: match.user1Id,
              user2Id: match.user2Id,
              createdAt: match.createdAt,
              lastMessageAt: match.lastMessageAt,
              unreadCount: 0, // Reset unread
              isActive: match.isActive,
              otherUser: match.otherUser,
              lastMessage: match.lastMessage,
              otherUserPhotoUrl: match.otherUserPhotoUrl,
            );
          }
          return match;
        }).toList();
        
        // Recalculer total unread
        final newTotalUnread = updatedMatches
            .fold<int>(0, (sum, match) => sum + match.unreadCount);
        
        state = state.copyWith(
          matches: updatedMatches,
          totalUnreadCount: newTotalUnread,
        );
      }
    } catch (e) {
      debugPrint('Error marking match as read: $e');
    }
  }
  
  /// Ajouter nouveau match (depuis feed)
  void addNewMatch(Match match) {
    final updatedMatches = [match, ...state.matches];
    state = state.copyWith(
      matches: updatedMatches,
      totalUnreadCount: state.totalUnreadCount + 1,
    );
  }
  
  /// Mettre à jour dernier message d'un match
  void updateLastMessage(String matchId, Message message) {
    final updatedMatches = state.matches.map((match) {
      if (match.id == matchId) {
        return Match(
          id: match.id,
          user1Id: match.user1Id,
          user2Id: match.user2Id,
          createdAt: match.createdAt,
          lastMessageAt: message.createdAt,
          unreadCount: match.unreadCount + (message.senderId != SupabaseService.instance.currentUserId ? 1 : 0),
          isActive: match.isActive,
          otherUser: match.otherUser,
          lastMessage: message,
          otherUserPhotoUrl: match.otherUserPhotoUrl,
        );
      }
      return match;
    }).toList();
    
    // Réordonner par dernière activité
    updatedMatches.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    
    state = state.copyWith(matches: updatedMatches);
  }
  
  /// Bloquer un match
  Future<void> blockMatch(String matchId) async {
    try {
      final success = await _chatService.blockMatch(matchId);
      
      if (success) {
        final updatedMatches = state.matches
            .where((match) => match.id != matchId)
            .toList();
        
        state = state.copyWith(matches: updatedMatches);
      }
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.getReadableError(e));
    }
  }
  
  /// Supprimer un match
  Future<void> deleteMatch(String matchId) async {
    try {
      final success = await _chatService.deleteMatch(matchId);
      
      if (success) {
        final updatedMatches = state.matches
            .where((match) => match.id != matchId)
            .toList();
        
        state = state.copyWith(matches: updatedMatches);
      }
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.getReadableError(e));
    }
  }
  
  /// Refresh matches
  Future<void> refresh() async {
    await loadMatches(refresh: true);
    await _loadTotalUnreadCount();
  }
  
  /// Clear erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Récupérer match par ID
  Match? getMatchById(String matchId) {
    try {
      return state.matches.firstWhere((match) => match.id == matchId);
    } catch (e) {
      return null;
    }
  }
}

/// Providers pour les matches
final matchesControllerProvider = StateNotifierProvider<MatchesController, MatchesState>((ref) {
  return MatchesController();
});

final totalUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(matchesControllerProvider).totalUnreadCount;
});

final hasUnreadMessagesProvider = Provider<bool>((ref) {
  return ref.watch(matchesControllerProvider).hasUnreadMessages;
});
