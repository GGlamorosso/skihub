import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../privacy/services/privacy_service.dart';
import '../../core/services/analytics_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AnalyticsService _analytics = AnalyticsService();

  // Initialize notification service
  Future<void> initialize() async {
    try {
      await _initializeLocalNotifications();
      await _initializeFirebaseMessaging();
    } catch (e) {
      debugPrint('Notification service initialization error: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for iOS
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission for notifications');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  // Request notification permissions
  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  // Get FCM token for user
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Subscribe to topic based on user preferences
  Future<void> updateNotificationTopics({
    required String userId,
    required bool marketingEnabled,
    required bool matchesEnabled,
    required bool messagesEnabled,
  }) async {
    try {
      final token = await getFCMToken();
      if (token == null) return;

      // Subscribe/unsubscribe to topics
      if (matchesEnabled) {
        await _firebaseMessaging.subscribeToTopic('matches_$userId');
      } else {
        await _firebaseMessaging.unsubscribeFromTopic('matches_$userId');
      }

      if (messagesEnabled) {
        await _firebaseMessaging.subscribeToTopic('messages_$userId');
      } else {
        await _firebaseMessaging.unsubscribeFromTopic('messages_$userId');
      }

      if (marketingEnabled) {
        await _firebaseMessaging.subscribeToTopic('marketing');
      } else {
        await _firebaseMessaging.unsubscribeFromTopic('marketing');
      }

      _analytics.track('notification_preferences_updated', {
        'marketing': marketingEnabled,
        'matches': matchesEnabled,
        'messages': messagesEnabled,
      });
    } catch (e) {
      debugPrint('Error updating notification topics: $e');
    }
  }

  // Show local notification for safety alerts
  Future<void> showSafetyNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'safety_channel',
        'Safety Alerts',
        channelDescription: 'Important safety and moderation notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Colors.red,
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        details,
        payload: payload?.toString(),
      );

      _analytics.track('safety_notification_shown', {
        'type': type,
        'title': title,
      });
    } catch (e) {
      debugPrint('Error showing safety notification: $e');
    }
  }

  // Show verification status notification
  Future<void> showVerificationNotification({
    required String status,
    String? reason,
  }) async {
    String title;
    String body;
    Color color;

    switch (status) {
      case 'approved':
        title = '✅ Profil vérifié !';
        body = 'Félicitations ! Votre identité a été vérifiée avec succès.';
        color = Colors.green;
        break;
      case 'rejected':
        title = '❌ Vérification refusée';
        body = reason ?? 'Votre vérification a été refusée. Veuillez recommencer.';
        color = Colors.red;
        break;
      case 'expired':
        title = '⏰ Vérification expirée';
        body = 'Votre demande de vérification a expiré. Veuillez recommencer.';
        color = Colors.orange;
        break;
      default:
        return;
    }

    await _showColoredNotification(
      title: title,
      body: body,
      color: color,
      channelId: 'verification_status',
      channelName: 'Verification Status',
    );
  }

  // Show content moderation notification
  Future<void> showModerationNotification({
    required String type, // 'message_blocked', 'photo_rejected', etc.
    String? reason,
  }) async {
    String title;
    String body;

    switch (type) {
      case 'message_blocked':
        title = '🚫 Message bloqué';
        body = 'Votre message a été bloqué car il ne respecte pas nos règles communautaires.';
        break;
      case 'photo_rejected':
        title = '📸 Photo rejetée';
        body = reason ?? 'Votre photo a été rejetée lors de la modération.';
        break;
      case 'profile_flagged':
        title = '⚠️ Profil signalé';
        body = 'Votre profil a été signalé. Veuillez consulter nos règles.';
        break;
      default:
        title = '⚠️ Modération';
        body = 'Une action de modération a été effectuée sur votre compte.';
    }

    await _showColoredNotification(
      title: title,
      body: body,
      color: Colors.orange,
      channelId: 'moderation',
      channelName: 'Moderation Alerts',
    );
  }

  // Generic colored notification
  Future<void> _showColoredNotification({
    required String title,
    required String body,
    required Color color,
    required String channelId,
    required String channelName,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: color,
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Error showing colored notification: $e');
    }
  }

  // Handle foreground message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message: ${message.notification?.title}');
    
    final notification = message.notification;
    if (notification != null) {
      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }

    _analytics.track('notification_received_foreground', {
      'type': message.data['type'],
    });
  }

  // Handle background message
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background message: ${message.notification?.title}');
    // Handle background message processing
  }

  // Handle notification tap
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('Notification tapped: ${message.data}');
    
    final type = message.data['type'] as String?;
    final targetId = message.data['target_id'] as String?;

    // Navigate based on notification type
    switch (type) {
      case 'new_match':
        // Navigate to matches screen
        break;
      case 'new_message':
        // Navigate to specific chat
        if (targetId != null) {
          // Navigate to chat with match_id = targetId
        }
        break;
      case 'verification_result':
        // Navigate to profile/verification screen
        break;
      case 'moderation_alert':
        // Navigate to safety/help screen
        break;
    }

    _analytics.track('notification_tapped', {
      'type': type,
      'target_id': targetId,
    });
  }

  // Handle notification response
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    
    // Parse payload and navigate accordingly
    if (response.payload != null) {
      // Handle local notification tap
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  // Show app badge (iOS)
  Future<void> updateAppBadge(int count) async {
    try {
      if (Platform.isIOS) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.setApplicationIconBadgeNumber(count);
      }
    } catch (e) {
      debugPrint('Error updating app badge: $e');
    }
  }
}

// Notification types for type safety
enum NotificationType {
  newMatch('new_match', 'Nouveau match !'),
  newMessage('new_message', 'Nouveau message'),
  verificationApproved('verification_approved', 'Profil vérifié !'),
  verificationRejected('verification_rejected', 'Vérification refusée'),
  photoRejected('photo_rejected', 'Photo rejetée'),
  messageBlocked('message_blocked', 'Message bloqué'),
  premiumExpiring('premium_expiring', 'Premium expire bientôt'),
  boostExpired('boost_expired', 'Boost expiré');

  const NotificationType(this.id, this.defaultTitle);

  final String id;
  final String defaultTitle;
}
