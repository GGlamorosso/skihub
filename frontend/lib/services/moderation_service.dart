import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/user_photo.dart';
import '../services/notification_service.dart';
import 'supabase_service.dart';

/// Service pour gestion des notifications de modération
class ModerationService {
  static ModerationService? _instance;
  static ModerationService get instance => _instance ??= ModerationService._();
  
  ModerationService._();
  
  final _supabase = SupabaseService.instance;
  final _notificationService = NotificationService.instance;
  
  /// Initialiser service de modération
  Future<void> initialize() async {
    try {
      await _setupFCM();
      await _setupLocalNotifications();
      
      debugPrint('✅ Moderation service initialized');
    } catch (e) {
      debugPrint('❌ Moderation service initialization failed: $e');
    }
  }
  
  /// Setup Firebase Cloud Messaging
  Future<void> _setupFCM() async {
    try {
      // Demander permissions
      final messaging = FirebaseMessaging.instance;
      
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ FCM permissions granted');
        
        // Obtenir token device
        final token = await messaging.getToken();
        if (token != null) {
          await _registerDeviceToken(token);
        }
        
        // Écouter refresh token
        messaging.onTokenRefresh.listen(_registerDeviceToken);
        
        // Handlers messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        
        // Handler background
        FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      } else {
        debugPrint('❌ FCM permissions denied');
      }
    } catch (e) {
      debugPrint('FCM setup error: $e');
    }
  }
  
  /// Setup notifications locales
  Future<void> _setupLocalNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }
  
  /// Enregistrer token device
  Future<void> _registerDeviceToken(String token) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return;
      
      await _supabase.from('user_devices').upsert({
        'user_id': userId,
        'device_token': token,
        'platform': Platform.operatingSystem,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Device token registered: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('Error registering device token: $e');
    }
  }
  
  /// Gérer message FCM en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    
    switch (type) {
      case 'photo_moderation':
        _handlePhotoModerationNotification(data);
        break;
      case 'new_match':
        _handleNewMatchNotification(data);
        break;
      case 'new_message':
        _handleNewMessageNotification(data);
        break;
      default:
        debugPrint('Unknown FCM message type: $type');
    }
  }
  
  /// Gérer tap sur notification
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    
    switch (type) {
      case 'photo_moderation':
        // Navigation vers galerie photos
        navigatorKey.currentState?.pushNamed('/photo-gallery');
        break;
      case 'new_match':
        // Navigation vers matches
        final matchId = data['match_id'];
        if (matchId != null) {
          navigatorKey.currentState?.pushNamed('/chat/$matchId');
        }
        break;
      case 'new_message':
        // Navigation vers chat
        final matchId = data['match_id'];
        if (matchId != null) {
          navigatorKey.currentState?.pushNamed('/chat/$matchId');
        }
        break;
    }
  }
  
  /// Gérer notification modération photo
  void _handlePhotoModerationNotification(Map<String, dynamic> data) {
    final status = data['moderation_status'] as String?;
    final reason = data['moderation_reason'] as String?;
    final photoId = data['photo_id'] as String?;
    
    if (status == null) return;
    
    String title;
    String body;
    
    switch (status) {
      case 'approved':
        title = '✅ Photo approuvée !';
        body = 'Votre photo est maintenant visible sur votre profil.';
        break;
      case 'rejected':
        title = '❌ Photo rejetée';
        body = reason ?? 'Votre photo ne respecte pas nos règles communautaires.';
        break;
      default:
        return;
    }
    
    // Afficher notification locale
    _notificationService.showNotification(
      id: photoId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      payload: 'photo_moderation:$photoId',
      channelId: 'photo_moderation_channel',
      channelName: 'Modération Photos',
    );
  }
  
  /// Gérer notification nouveau match
  void _handleNewMatchNotification(Map<String, dynamic> data) {
    final matchId = data['match_id'] as String?;
    final otherUserName = data['other_user_name'] as String?;
    
    if (matchId != null && otherUserName != null) {
      _notificationService.showNewMatchNotification(
        matchId: matchId,
        otherUserName: otherUserName,
      );
    }
  }
  
  /// Gérer notification nouveau message
  void _handleNewMessageNotification(Map<String, dynamic> data) {
    final matchId = data['match_id'] as String?;
    final senderName = data['sender_name'] as String?;
    final messageContent = data['message_content'] as String?;
    final unreadCount = int.tryParse(data['unread_count']?.toString() ?? '0');
    
    if (matchId != null && senderName != null && messageContent != null) {
      _notificationService.showNewMessageNotification(
        matchId: matchId,
        senderName: senderName,
        messageContent: messageContent,
        unreadCount: unreadCount,
      );
    }
  }
  
  /// Simuler notification modération (pour tests)
  Future<void> simulateModerationResult({
    required String photoId,
    required ModerationStatus status,
    String? reason,
  }) async {
    final data = {
      'type': 'photo_moderation',
      'photo_id': photoId,
      'moderation_status': status.name,
      if (reason != null) 'moderation_reason': reason,
    };
    
    _handlePhotoModerationNotification(data);
  }
  
  /// Désactiver notifications pour utilisateur
  Future<void> unregisterDevice() async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return;
      
      await _supabase.from('user_devices')
          .delete()
          .eq('user_id', userId);
      
      debugPrint('✅ Device token unregistered');
    } catch (e) {
      debugPrint('Error unregistering device: $e');
    }
  }
}

/// Handler background FCM (fonction top-level requise)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('FCM Background message: ${message.messageId}');
  
  final data = message.data;
  final type = data['type'];
  
  // Pour les messages background, on se contente de logger
  // Les notifications sont gérées par le système
  switch (type) {
    case 'photo_moderation':
      debugPrint('Background photo moderation: ${data['moderation_status']}');
      break;
    case 'new_match':
      debugPrint('Background new match: ${data['match_id']}');
      break;
    case 'new_message':
      debugPrint('Background new message: ${data['match_id']}');
      break;
  }
}

// Global navigator key pour navigation depuis notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
