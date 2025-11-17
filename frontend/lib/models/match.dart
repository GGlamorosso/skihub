import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user_profile.dart';
import 'subscription.dart' show QuotaInfo;

part 'match.g.dart';

@JsonSerializable()
class Match {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isActive;
  
  // Données jointes
  final UserProfile? otherUser;
  final Message? lastMessage;
  final String? otherUserPhotoUrl;
  
  const Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isActive = true,
    this.otherUser,
    this.lastMessage,
    this.otherUserPhotoUrl,
  });
  
  factory Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);
  Map<String, dynamic> toJson() => _$MatchToJson(this);
  
  /// Obtenir l'autre utilisateur du match
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }
  
  /// Temps depuis dernier message
  String get lastActivityDisplay {
    if (lastMessageAt == null) {
      return 'Nouveau match';
    }
    
    final now = DateTime.now();
    final diff = now.difference(lastMessageAt!);
    
    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'il y a ${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return 'il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'il y a ${diff.inDays}j';
    } else {
      return '${lastMessageAt!.day}/${lastMessageAt!.month}';
    }
  }
  
  /// A des messages non lus
  bool get hasUnreadMessages => unreadCount > 0;
  
  /// Badge unread
  String get unreadBadge {
    if (unreadCount == 0) return '';
    if (unreadCount > 99) return '99+';
    return unreadCount.toString();
  }
  
  /// Est récent (moins de 24h)
  bool get isRecent {
    final now = DateTime.now();
    return now.difference(createdAt).inHours < 24;
  }
  
  /// Preview message pour liste
  String get messagePreview {
    if (lastMessage == null) {
      return 'Nouveau match ! Dites-vous bonjour 👋';
    }
    
    return lastMessage!.content.length > 50
        ? '${lastMessage!.content.substring(0, 50)}...'
        : lastMessage!.content;
  }
}

@JsonSerializable()
class Message {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  
  const Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.type = MessageType.text,
    this.metadata,
  });
  
  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
  
  /// Est-ce que le message est du current user
  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }
  
  /// Temps d'affichage
  String get timeDisplay {
    final now = DateTime.now();
    final messageTime = createdAt;
    
    if (now.difference(messageTime).inDays == 0) {
      // Aujourd'hui
      return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(messageTime).inDays == 1) {
      // Hier
      return 'Hier ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Date complète
      return '${messageTime.day}/${messageTime.month} ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    }
  }
  
  /// Couleur statut
  Color get statusColor {
    switch (status) {
      case MessageStatus.sending:
        return Colors.orange;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.blue;
      case MessageStatus.read:
        return Colors.green;
      case MessageStatus.failed:
        return Colors.red;
    }
  }
  
  /// Icône statut
  IconData get statusIcon {
    switch (status) {
      case MessageStatus.sending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }
}

enum MessageStatus {
  @JsonValue('sending')
  sending,
  
  @JsonValue('sent')
  sent,
  
  @JsonValue('delivered')
  delivered,
  
  @JsonValue('read')
  read,
  
  @JsonValue('failed')
  failed;
}

enum MessageType {
  @JsonValue('text')
  text,
  
  @JsonValue('image')
  image,
  
  @JsonValue('system')
  system;
}

@JsonSerializable()
class SendMessageRequest {
  final String matchId;
  final String content;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  
  const SendMessageRequest({
    required this.matchId,
    required this.content,
    this.type = MessageType.text,
    this.metadata,
  });
  
  factory SendMessageRequest.fromJson(Map<String, dynamic> json) => _$SendMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);
}

@JsonSerializable()
class SendMessageResponse {
  final Message message;
  @JsonKey(fromJson: _quotaInfoFromJson, toJson: _quotaInfoToJson)
  final QuotaInfo quotaInfo;
  final bool success;
  final String? error;
  
  const SendMessageResponse({
    required this.message,
    required this.quotaInfo,
    this.success = true,
    this.error,
  });
  
  factory SendMessageResponse.fromJson(Map<String, dynamic> json) => _$SendMessageResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SendMessageResponseToJson(this);
}

// Helper functions for QuotaInfo serialization
QuotaInfo _quotaInfoFromJson(Map<String, dynamic> json) {
  return QuotaInfo.fromJson(json);
  throw ArgumentError('Invalid QuotaInfo JSON');
}

Map<String, dynamic> _quotaInfoToJson(QuotaInfo quotaInfo) {
  // QuotaInfo is a Freezed class, use copyWith to get a map
  // For now, return a basic map structure
  return {
    'swipeRemaining': quotaInfo.swipeRemaining,
    'messageRemaining': quotaInfo.messageRemaining,
    'limitReached': quotaInfo.limitReached,
    'limitType': quotaInfo.limitType.name,
    'dailySwipeLimit': quotaInfo.dailySwipeLimit,
    'dailyMessageLimit': quotaInfo.dailyMessageLimit,
    'resetsAt': quotaInfo.resetsAt.toIso8601String(),
  };
}
