import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../main.dart' show logger;

/// Service de gestion Firebase pour CrewSnow
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();
  
  bool _initialized = false;
  bool get isInitialized => _initialized;
  
  /// Initialise Firebase avec tous les services nécessaires
  Future<void> initialize() async {
    if (_initialized) {
      logger.w('🔥 Firebase already initialized');
      return;
    }
    
    try {
      logger.i('🔥 Initializing Firebase...');
      
      // Firebase est déjà initialisé dans main.dart avec DefaultFirebaseOptions
      // On vérifie juste que c'est bien initialisé
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase must be initialized in main() before calling FirebaseService.initialize()');
      }
      logger.i('🔥 Firebase core already initialized, configuring services...');
      
      // Configure Crashlytics
      await _initializeCrashlytics();
      
      // Configure Firebase Messaging
      await _initializeMessaging();
      
      _initialized = true;
      logger.i('✅ Firebase initialized successfully');
      
    } catch (e, stackTrace) {
      logger.e('❌ Firebase initialization failed: $e\n$stackTrace');
      rethrow;
    }
  }
  
  /// Configure Crashlytics pour la collecte des crashes
  Future<void> _initializeCrashlytics() async {
    try {
      logger.i('📊 Configuring Crashlytics...');
      
      // Pass all uncaught errors from the framework to Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        logger.e('🔥 Flutter Error recorded to Crashlytics: ${errorDetails.exception}\n${errorDetails.stack}');
      };
      
      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        logger.e('🔥 Platform Error recorded to Crashlytics: $error\n$stack');
        return true;
      };
      
      // Set user identifier for debugging
      await FirebaseCrashlytics.instance.setUserIdentifier('dev-user');
      
      logger.i('✅ Crashlytics configured');
      
    } catch (e, stackTrace) {
      logger.e('❌ Crashlytics configuration failed: $e\n$stackTrace');
      // Don't rethrow - Crashlytics failure shouldn't block app initialization
    }
  }
  
  /// Configure Firebase Messaging pour les notifications push
  Future<void> _initializeMessaging() async {
    try {
      logger.i('📱 Configuring Firebase Messaging...');
      
      final messaging = FirebaseMessaging.instance;
      
      // Request permission for notifications
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      logger.i('📱 Notification permission status: ${settings.authorizationStatus}');
      
      // Get FCM token for this device
      final token = await messaging.getToken();
      logger.i('📱 FCM Token: $token');
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        logger.i('📱 Received foreground message: ${message.messageId}');
        logger.i('📱 Message data: ${message.data}');
        
        if (message.notification != null) {
          logger.i('📱 Notification: ${message.notification!.title} - ${message.notification!.body}');
        }
      });
      
      // Handle notification taps when app is terminated
      messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          logger.i('📱 App opened from terminated state by notification: ${message.messageId}');
        }
      });
      
      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        logger.i('📱 App opened from background by notification: ${message.messageId}');
      });
      
      logger.i('✅ Firebase Messaging configured');
      
    } catch (e, stackTrace) {
      logger.e('❌ Firebase Messaging configuration failed: $e\n$stackTrace');
      // Don't rethrow - Messaging failure shouldn't block app initialization
    }
  }
  
  /// Test Crashlytics en forçant un crash de test
  Future<void> testCrashlytics() async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }
    
    logger.w('🧪 Testing Crashlytics - forcing test crash...');
    
    // Force a test crash
    FirebaseCrashlytics.instance.crash();
  }
  
  /// Enregistrer un événement custom dans Crashlytics
  Future<void> logCustomEvent(String event, Map<String, dynamic> parameters) async {
    if (!_initialized) {
      logger.w('🔥 Firebase not initialized, skipping custom event: $event');
      return;
    }
    
    try {
      await FirebaseCrashlytics.instance.log('$event: ${parameters.toString()}');
      logger.d('📊 Custom event logged to Crashlytics: $event');
    } catch (e) {
      logger.e('❌ Failed to log custom event to Crashlytics: $e');
    }
  }
  
  /// Enregistrer une erreur non-fatale dans Crashlytics
  Future<void> recordError(dynamic exception, StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (!_initialized) {
      logger.w('🔥 Firebase not initialized, skipping error recording');
      return;
    }
    
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
      logger.d('📊 Error recorded to Crashlytics: ${exception.toString()}');
    } catch (e) {
      logger.e('❌ Failed to record error to Crashlytics: $e');
    }
  }
}

/// Handler pour les messages Firebase en arrière-plan
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  
  logger.i('📱 Handling background message: ${message.messageId}');
}
