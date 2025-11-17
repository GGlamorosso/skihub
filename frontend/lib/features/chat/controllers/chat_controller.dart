import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/match.dart';
import '../../../services/chat_service.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/error_handler.dart';

/// État d'une conversation
@immutable
class ChatState {
  const ChatState({
    this.match,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMoreMessages = true,
    this.isTyping = false,
    this.realtimeConnected = false,
  });
  
  final Match? match;
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final bool isLoadingMore;
  final String? error;
  final bool hasMoreMessages;
  final bool isTyping;
  final bool realtimeConnected;
  
  bool get hasError => error != null;
  bool get hasMessages => messages.isNotEmpty;
  bool get canLoadMore => hasMoreMessages && !isLoadingMore;
  
  ChatState copyWith({
    Match? match,
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isLoadingMore,
    String? error,
    bool? hasMoreMessages,
    bool? isTyping,
    bool? realtimeConnected,
  }) {
    return ChatState(
      match: match ?? this.match,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isTyping: isTyping ?? this.isTyping,
      realtimeConnected: realtimeConnected ?? this.realtimeConnected,
    );
  }
}

/// Controller pour une conversation
class ChatController extends StateNotifier<ChatState> {
  ChatController(this.matchId) : super(const ChatState()) {
    _init();
  }
  
  final String matchId;
  final _chatService = ChatService.instance;
  RealtimeChannel? _realtimeChannel;
  
  /// Initialisation
  Future<void> _init() async {
    await _loadMatchDetails();
    await _loadMessages(refresh: true);
    _subscribeToRealtime();
  }
  
  @override
  void dispose() {
    _unsubscribeFromRealtime();
    super.dispose();
  }
  
  /// Charger détails du match
  Future<void> _loadMatchDetails() async {
    try {
      final match = await _chatService.getMatchDetails(matchId);
      if (match != null) {
        state = state.copyWith(match: match);
      }
    } catch (e) {
      debugPrint('Error loading match details: $e');
    }
  }
  
  /// Charger messages
  Future<void> _loadMessages({
    bool refresh = false,
    int limit = 50,
  }) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        messages: [],
        hasMoreMessages: true,
      );
    } else {
      state = state.copyWith(isLoadingMore: true, error: null);
    }
    
    try {
      final before = refresh ? null : state.messages.first.createdAt;
      
      final newMessages = await _chatService.getMessages(
        matchId: matchId,
        limit: limit,
        before: before,
      );
      
      final updatedMessages = refresh 
          ? newMessages
          : [...newMessages, ...state.messages];
      
      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        isLoadingMore: false,
        hasMoreMessages: newMessages.length >= limit,
      );
      
      // Marquer comme lu si c'est un refresh (ouverture conversation)
      if (refresh) {
        await _chatService.markMessagesAsRead(matchId: matchId);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: ErrorHandler.getReadableError(e),
      );
      
      ErrorHandler.logError(
        context: 'ChatController._loadMessages',
        error: e,
        additionalData: {'match_id': matchId, 'refresh': refresh},
      );
    }
  }
  
  /// Envoyer message
  Future<bool> sendMessage(String content) async {
    if (content.trim().isEmpty) return false;
    
    state = state.copyWith(isSending: true, error: null);
    
    try {
      final response = await _chatService.sendMessage(
        matchId: matchId,
        content: content.trim(),
      );
      
      if (response.success) {
        // Ajouter message à la liste locale (sera confirmé par Realtime)
        final tempMessage = Message(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
          matchId: matchId,
          senderId: SupabaseService.instance.currentUserId!,
          content: content.trim(),
          createdAt: DateTime.now(),
          status: MessageStatus.sending,
        );
        
        final updatedMessages = [...state.messages, tempMessage];
        
        state = state.copyWith(
          messages: updatedMessages,
          isSending: false,
        );
        
        return true;
      } else {
        state = state.copyWith(
          isSending: false,
          error: response.error ?? 'Erreur envoi message',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: ErrorHandler.getReadableError(e),
      );
      
      ErrorHandler.logError(
        context: 'ChatController.sendMessage',
        error: e,
        additionalData: {'match_id': matchId, 'content_length': content.length},
      );
      
      return false;
    }
  }
  
  /// S'abonner au Realtime
  void _subscribeToRealtime() {
    try {
      _realtimeChannel = _chatService.subscribeToMessages(
        matchId: matchId,
        onNewMessage: _handleNewMessage,
        onMessageUpdate: _handleMessageUpdate,
      );
      
      state = state.copyWith(realtimeConnected: true);
    } catch (e) {
      debugPrint('Error subscribing to realtime: $e');
      state = state.copyWith(realtimeConnected: false);
    }
  }
  
  /// Se désabonner du Realtime
  void _unsubscribeFromRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    state = state.copyWith(realtimeConnected: false);
  }
  
  /// Gérer nouveau message Realtime
  void _handleNewMessage(Message message) {
    // Éviter doublons (message déjà dans la liste)
    final existingIndex = state.messages.indexWhere((m) => m.id == message.id);
    
    if (existingIndex == -1) {
      // Nouveau message
      final updatedMessages = [...state.messages, message];
      state = state.copyWith(messages: updatedMessages);
      
      // Marquer comme lu si conversation ouverte
      _chatService.markMessagesAsRead(matchId: matchId);
    } else {
      // Remplacer message temporaire par le vrai
      final updatedMessages = [...state.messages];
      updatedMessages[existingIndex] = message;
      state = state.copyWith(messages: updatedMessages);
    }
  }
  
  /// Gérer mise à jour message (statut lu, etc.)
  void _handleMessageUpdate(Message message) {
    final messageIndex = state.messages.indexWhere((m) => m.id == message.id);
    
    if (messageIndex != -1) {
      final updatedMessages = [...state.messages];
      updatedMessages[messageIndex] = message;
      state = state.copyWith(messages: updatedMessages);
    }
  }
  
  /// Charger plus de messages (scroll vers le haut)
  Future<void> loadMoreMessages() async {
    if (!state.canLoadMore || state.messages.isEmpty) return;
    
    await _loadMessages(limit: 30);
  }
  
  /// Refresh conversation
  Future<void> refresh() async {
    await _loadMessages(refresh: true);
  }
  
  /// Clear erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Indicateur typing (future)
  void setTyping(bool isTyping) {
    state = state.copyWith(isTyping: isTyping);
  }
  
  /// Obtenir autres utilisateur
  String? get otherUserId {
    final currentUserId = SupabaseService.instance.currentUserId;
    if (currentUserId == null || state.match == null) return null;
    
    return state.match!.getOtherUserId(currentUserId);
  }
  
  /// Obtenir nom autre utilisateur
  String get otherUserName {
    return state.match?.otherUser?.username ?? 'Utilisateur';
  }
}

/// Provider pour chat controller (par match ID)
final chatControllerProvider = StateNotifierProvider.family<ChatController, ChatState, String>((ref, matchId) {
  return ChatController(matchId);
});

/// Provider pour état typing
final isTypingProvider = Provider.family<bool, String>((ref, matchId) {
  return ref.watch(chatControllerProvider(matchId)).isTyping;
});

/// Provider pour connexion Realtime
final realtimeConnectedProvider = Provider.family<bool, String>((ref, matchId) {
  return ref.watch(chatControllerProvider(matchId)).realtimeConnected;
});
