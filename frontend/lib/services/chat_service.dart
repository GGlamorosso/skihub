import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match.dart';
import '../models/user_profile.dart';
import '../models/subscription.dart' show QuotaInfo;
import '../utils/error_handler.dart';
import 'supabase_service.dart';
import 'quota_service.dart';

/// Service pour gestion du chat et matches
class ChatService {
  static ChatService? _instance;
  static ChatService get instance => _instance ??= ChatService._();
  
  ChatService._();
  
  final _supabase = SupabaseService.instance;
  final _quotaService = QuotaService();
  RealtimeChannel? _messagesChannel;
  
  /// Récupérer liste des matches avec derniers messages
  Future<List<Match>> getMatches({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.currentUserId!;
      
      final response = await _supabase.from('matches')
          .select('''
            *,
            user1:users!matches_user1_id_fkey(id, username, level),
            user2:users!matches_user2_id_fkey(id, username, level),
            last_message:messages(content, created_at, sender_id)
          ''')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .eq('is_active', true)
          .order('last_message_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      final List<Match> matches = [];
      
      for (final matchData in response) {
        // Déterminer l'autre utilisateur
        final isUser1 = matchData['user1_id'] == userId;
        final otherUserData = isUser1 ? matchData['user2'] : matchData['user1'];
        
        // Créer UserProfile pour l'autre utilisateur
        UserProfile? otherUser;
        if (otherUserData != null) {
          otherUser = UserProfile(
            id: otherUserData['id'],
            username: otherUserData['username'],
            email: '', // Non exposé dans matches
            level: UserLevel.values.firstWhere(
              (level) => level.name == otherUserData['level'],
              orElse: () => UserLevel.intermediate,
            ),
            rideStyles: [],
            languages: [],
            objectives: [],
            lastActiveAt: DateTime.now(),
            createdAt: DateTime.now(),
          );
        }
        
        // Créer Message si disponible
        Message? lastMessage;
        if (matchData['last_message'] != null) {
          final msgData = matchData['last_message'];
          lastMessage = Message(
            id: 'temp-id',
            matchId: matchData['id'],
            senderId: msgData['sender_id'],
            content: msgData['content'],
            createdAt: DateTime.parse(msgData['created_at']),
          );
        }
        
        final match = Match(
          id: matchData['id'],
          user1Id: matchData['user1_id'],
          user2Id: matchData['user2_id'],
          createdAt: DateTime.parse(matchData['created_at']),
          lastMessageAt: matchData['last_message_at'] != null
              ? DateTime.parse(matchData['last_message_at'])
              : null,
          unreadCount: matchData['unread_count'] ?? 0,
          isActive: matchData['is_active'] ?? true,
          otherUser: otherUser,
          lastMessage: lastMessage,
        );
        
        matches.add(match);
      }
      
      return matches;
    } catch (e) {
      ErrorHandler.logError(
        context: 'ChatService.getMatches',
        error: e,
        additionalData: {'limit': limit, 'offset': offset},
      );
      
      throw Exception(ErrorHandler.getReadableError(e));
    }
  }
  
  /// Récupérer messages d'une conversation
  Future<List<Message>> getMessages({
    required String matchId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      var query = _supabase.from('messages')
          .select()
          .eq('match_id', matchId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      // TODO: Implémenter pagination avec before (lt non disponible dans cette version)
      // if (before != null) {
      //   query = query.lt('created_at', before.toIso8601String());
      // }
      
      final response = await query;
      
      return (response as List)
          .map((json) => Message.fromJson(json))
          .toList()
          .reversed
          .toList(); // Inverser pour avoir chronologique
    } catch (e) {
      ErrorHandler.logError(
        context: 'ChatService.getMessages',
        error: e,
        additionalData: {'match_id': matchId, 'limit': limit},
      );
      
      throw Exception(ErrorHandler.getReadableError(e));
    }
  }
  
  /// Envoyer un message
  Future<SendMessageResult> sendMessage({
    required String matchId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check quota before sending message
      final quotaCheck = await _quotaService.checkQuotaForMessage();
      if (!quotaCheck.isAllowed) {
        return SendMessageResult.quotaExceeded(
          quotaInfo: quotaCheck.quotaInfo!,
          message: quotaCheck.message ?? 'Message quota exceeded',
        );
      }
      
      final request = SendMessageRequest(
        matchId: matchId,
        content: content,
        type: type,
        metadata: metadata,
      );
      
      final response = await _supabase.callFunction(
        functionName: 'send-message-enhanced',
        body: request.toJson(),
      );
      
      if (response.status != 200) {
        throw Exception('Send message failed: ${response.status}');
      }
      
      final data = response.data as Map<String, dynamic>;
      
      // Parse quota info from response
      final quotaInfo = _quotaService.parseQuotaFromResponse(data);
      
      // Parse message response
      final messageResponse = SendMessageResponse.fromJson(data);
      
      return SendMessageResult.success(
        messageResponse: messageResponse,
        quotaInfo: quotaInfo,
      );
    } catch (e) {
      ErrorHandler.logError(
        context: 'ChatService.sendMessage',
        error: e,
        additionalData: {
          'match_id': matchId,
          'content_length': content.length,
          'type': type.name,
        },
      );
      
      return SendMessageResult.error(ErrorHandler.getReadableError(e));
    }
  }
  
  /// S'abonner aux nouveaux messages d'un match
  RealtimeChannel subscribeToMessages({
    required String matchId,
    required Function(Message) onNewMessage,
    required Function(Message) onMessageUpdate,
  }) {
    // Désabonner canal précédent si existe
    _messagesChannel?.unsubscribe();
    
    _messagesChannel = _supabase.subscribeToTable(
      table: 'messages',
      filter: 'match_id=eq.$matchId',
      onInsert: (payload) {
        try {
          final message = Message.fromJson(payload.newRecord);
          onNewMessage(message);
        } catch (e) {
          debugPrint('Error parsing new message: $e');
        }
      },
      onUpdate: (payload) {
        try {
          final message = Message.fromJson(payload.newRecord);
          onMessageUpdate(message);
        } catch (e) {
          debugPrint('Error parsing updated message: $e');
        }
      },
      onDelete: (payload) {
        // Messages supprimés (rare)
        debugPrint('Message deleted: ${payload.oldRecord}');
      },
    );
    
    return _messagesChannel!;
  }
  
  /// Se désabonner des messages
  void unsubscribeFromMessages() {
    _messagesChannel?.unsubscribe();
    _messagesChannel = null;
  }
  
  /// Marquer messages comme lus
  Future<bool> markMessagesAsRead({
    required String matchId,
  }) async {
    try {
      await _supabase.rpc('mark_match_read', params: {
        'p_match_id': matchId,
      });
      
      return true;
    } catch (e) {
      ErrorHandler.logError(
        context: 'ChatService.markMessagesAsRead',
        error: e,
        additionalData: {'match_id': matchId},
      );
      
      return false;
    }
  }
  
  /// Récupérer détails complets d'un match
  Future<Match?> getMatchDetails(String matchId) async {
    try {
      final userId = _supabase.currentUserId!;
      
      final response = await _supabase.from('matches')
          .select('''
            *,
            user1:users!matches_user1_id_fkey(*),
            user2:users!matches_user2_id_fkey(*),
            messages(*)
          ''')
          .eq('id', matchId)
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .single();
      
      // Traiter réponse similaire à getMatches mais pour un seul match
      final isUser1 = response['user1_id'] == userId;
      final otherUserData = isUser1 ? response['user2'] : response['user1'];
      
      UserProfile? otherUser;
      if (otherUserData != null) {
        otherUser = UserProfile.fromJson(otherUserData);
      }
      
      return Match(
        id: response['id'],
        user1Id: response['user1_id'],
        user2Id: response['user2_id'],
        createdAt: DateTime.parse(response['created_at']),
        lastMessageAt: response['last_message_at'] != null
            ? DateTime.parse(response['last_message_at'])
            : null,
        unreadCount: response['unread_count'] ?? 0,
        isActive: response['is_active'] ?? true,
        otherUser: otherUser,
      );
    } catch (e) {
      ErrorHandler.logError(
        context: 'ChatService.getMatchDetails',
        error: e,
        additionalData: {'match_id': matchId},
      );
      
      return null;
    }
  }
  
  /// Récupérer photo URL de l'autre utilisateur
  Future<String?> getOtherUserPhotoUrl(String otherUserId) async {
    try {
      final response = await _supabase.from('profile_photos')
          .select('storage_path')
          .eq('user_id', otherUserId)
          .eq('is_main', true)
          .eq('moderation_status', 'approved')
          .single();
      
      final storagePath = response['storage_path'] as String;
      
      return await _supabase.getSignedUrl(
        bucket: 'profile_photos',
        path: storagePath,
        expiresIn: 3600,
      );
    } catch (e) {
      debugPrint('Error getting other user photo: $e');
      return null;
    }
  }
  
  /// Obtenir nombre total de matches non lus
  Future<int> getTotalUnreadCount() async {
    try {
      final userId = _supabase.currentUserId!;
      
      final response = await _supabase.rpc('get_total_unread_count', params: {
        'p_user_id': userId,
      });
      
      return response as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting total unread count: $e');
      return 0;
    }
  }
  
  /// Bloquer un match
  Future<bool> blockMatch(String matchId) async {
    try {
      await _supabase.from('matches')
          .update({'is_active': false})
          .eq('id', matchId);
      
      return true;
    } catch (e) {
      ErrorHandler.logError(
        context: 'ChatService.blockMatch',
        error: e,
        additionalData: {'match_id': matchId},
      );
      
      return false;
    }
  }
  
  /// Supprimer un match (soft delete)
  Future<bool> deleteMatch(String matchId) async {
    try {
      await _supabase.from('matches')
          .update({'is_active': false})
          .eq('id', matchId);
      
      return true;
    } catch (e) {
      ErrorHandler.logError(
        context: 'ChatService.deleteMatch',
        error: e,
        additionalData: {'match_id': matchId},
      );
      
      return false;
    }
  }
}

/// Result of sending a message with quota information
class SendMessageResult {
  final bool success;
  final SendMessageResponse? messageResponse;
  final QuotaInfo? quotaInfo;
  final String? message;
  final String? error;
  final bool quotaExceeded;

  const SendMessageResult._({
    required this.success,
    this.messageResponse,
    this.quotaInfo,
    this.message,
    this.error,
    this.quotaExceeded = false,
  });

  factory SendMessageResult.success({
    required SendMessageResponse messageResponse,
    required QuotaInfo quotaInfo,
  }) => SendMessageResult._(
    success: true,
    messageResponse: messageResponse,
    quotaInfo: quotaInfo,
  );

  factory SendMessageResult.quotaExceeded({
    required QuotaInfo quotaInfo,
    required String message,
  }) => SendMessageResult._(
    success: false,
    quotaInfo: quotaInfo,
    message: message,
    quotaExceeded: true,
  );

  factory SendMessageResult.error(String error) => SendMessageResult._(
    success: false,
    error: error,
  );
}
