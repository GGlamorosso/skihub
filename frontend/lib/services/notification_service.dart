import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service pour notifications locales
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  /// Initialiser service notifications
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Configuration Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuration iOS
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
      
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      _isInitialized = true;
      debugPrint('✅ Notifications service initialized');
    } catch (e) {
      debugPrint('❌ Notifications initialization failed: $e');
    }
  }
  
  /// Demander permissions notifications
  Future<bool> requestPermissions() async {
    try {
      final status = await Permission.notification.request();
      
      if (status.isGranted) {
        debugPrint('✅ Notification permissions granted');
        return true;
      } else {
        debugPrint('❌ Notification permissions denied');
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }
  
  /// Notification nouveau match
  Future<void> showNewMatchNotification({
    required String matchId,
    required String otherUserName,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'matches_channel',
        'Nouveaux Matches',
        channelDescription: 'Notifications pour nouveaux matches',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFFF4B8A),
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.show(
        matchId.hashCode,
        'Nouveau match ! 🎉',
        'Vous avez matché avec $otherUserName',
        details,
        payload: 'match:$matchId',
      );
    } catch (e) {
      debugPrint('Error showing match notification: $e');
    }
  }
  
  /// Afficher une notification générique
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel',
    String channelName = 'Notifications',
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifications générales',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFF4B8A),
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }
  
  /// Notification nouveau message
  Future<void> showNewMessageNotification({
    required String matchId,
    required String senderName,
    required String messageContent,
    int? unreadCount,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      final androidDetails = AndroidNotificationDetails(
        'messages_channel',
        'Messages',
        channelDescription: 'Notifications pour nouveaux messages',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFF4B8A),
        groupKey: 'messages',
        setAsGroupSummary: false,
        styleInformation: BigTextStyleInformation(
          messageContent,
          contentTitle: senderName,
        ),
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.show(
        matchId.hashCode + 1000, // Éviter conflit avec match notifications
        senderName,
        messageContent.length > 50 
          ? '${messageContent.substring(0, 50)}...'
          : messageContent,
        details,
        payload: 'message:$matchId',
      );
      
      // Groupe summary pour Android (si plusieurs messages)
      if (unreadCount != null && unreadCount > 1) {
        await _showGroupSummaryNotification(unreadCount);
      }
    } catch (e) {
      debugPrint('Error showing message notification: $e');
    }
  }
  
  /// Notification groupe (Android)
  Future<void> _showGroupSummaryNotification(int messageCount) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'messages_channel',
        'Messages',
        channelDescription: 'Notifications pour nouveaux messages',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFF4B8A),
        groupKey: 'messages',
        setAsGroupSummary: true,
        styleInformation: InboxStyleInformation(
          [],
          contentTitle: 'CrewSnow',
          summaryText: '$messageCount nouveaux messages',
        ),
      );
      
      final details = NotificationDetails(android: androidDetails);
      
      await _notifications.show(
        0, // ID fixe pour summary
        'CrewSnow',
        '$messageCount nouveaux messages',
        details,
      );
    } catch (e) {
      debugPrint('Error showing group summary: $e');
    }
  }
  
  /// Supprimer notification spécifique
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }
  
  /// Supprimer toutes notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }
  
  /// Supprimer notifications d'un match
  Future<void> cancelMatchNotifications(String matchId) async {
    try {
      await _notifications.cancel(matchId.hashCode); // Match notification
      await _notifications.cancel(matchId.hashCode + 1000); // Message notification
    } catch (e) {
      debugPrint('Error canceling match notifications: $e');
    }
  }
  
  /// Gérer tap sur notification
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    
    try {
      if (payload.startsWith('match:')) {
        final matchId = payload.substring(6);
        // TODO S4: Navigation vers match/chat
        debugPrint('Navigate to match: $matchId');
      } else if (payload.startsWith('message:')) {
        final matchId = payload.substring(8);
        // TODO S4: Navigation vers chat
        debugPrint('Navigate to chat: $matchId');
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }
  
  /// Mettre à jour badge app (iOS)
  Future<void> updateAppBadge(int count) async {
    try {
      if (count > 0) {
        await _notifications.show(
          -1, // ID spécial badge
          '',
          '',
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: false,
              presentBadge: true,
              presentSound: false,
              badgeNumber: null, // Sera le count
            ),
          ),
        );
      } else {
        await _notifications.cancel(-1);
      }
    } catch (e) {
      debugPrint('Error updating app badge: $e');
    }
  }
  
  /// Vérifier si notifications activées
  Future<bool> areNotificationsEnabled() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking notification status: $e');
      return false;
    }
  }
  
  /// Programmer notification rappel (future feature)
  Future<void> scheduleReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      await _notifications.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders_channel',
            'Rappels',
            channelDescription: 'Rappels CrewSnow',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
    }
  }
}
