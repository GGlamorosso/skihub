import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../config/app_config.dart';

class CrashReportingService {
  static bool _isInitialized = false;
  static CrashProvider _provider = CrashProvider.crashlytics;

  static Future<void> initialize({
    bool enableInDevMode = false,
    bool enableUserInteractionLogging = true,
    CrashProvider provider = CrashProvider.crashlytics,
  }) async {
    if (_isInitialized) return;

    _provider = provider;

    // Only enable in release mode or if explicitly enabled
    final shouldEnable = kReleaseMode || enableInDevMode;
    if (!shouldEnable) {
      if (kDebugMode) print('💥 Crash reporting disabled in debug mode');
      return;
    }

    try {
      switch (provider) {
        case CrashProvider.crashlytics:
          await _initializeCrashlytics(enableUserInteractionLogging);
          break;
        case CrashProvider.sentry:
          await _initializeSentry();
          break;
      }

      _isInitialized = true;
      if (kDebugMode) print('💥 Crash reporting initialized ($provider)');
    } catch (e) {
      if (kDebugMode) print('💥 Crash reporting initialization failed: $e');
    }
  }

  static Future<void> _initializeCrashlytics(bool enableUserInteractions) async {
    // Set up Crashlytics
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(kReleaseMode);
    
    // Set up Flutter error handling
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Set up async error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Set custom keys for context
    await FirebaseCrashlytics.instance.setCustomKey('environment', AppConfig.environmentName);
    await FirebaseCrashlytics.instance.setCustomKey('app_version', AppConfig.appVersion);
    await FirebaseCrashlytics.instance.setCustomKey('ai_features_enabled', AppConfig.enableAIFeatures);
  }

  static Future<void> _initializeSentry() async {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.debug = kDebugMode;
        options.environment = AppConfig.environmentName;
        options.release = '${AppConfig.appVersion}+${AppConfig.buildNumber}';
        options.tracesSampleRate = AppConfig.isDevelopment ? 1.0 : 0.1;
        options.profilesSampleRate = AppConfig.isDevelopment ? 1.0 : 0.1;
      },
    );
  }

  // Set user information
  static Future<void> setUser({
    required String userId,
    String? email,
    String? username,
    Map<String, dynamic>? customData,
  }) async {
    if (!_isInitialized) return;

    try {
      switch (_provider) {
        case CrashProvider.crashlytics:
          await FirebaseCrashlytics.instance.setUserIdentifier(userId);
          if (customData != null) {
            for (final entry in customData.entries) {
              await FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value);
            }
          }
          break;
        case CrashProvider.sentry:
          Sentry.configureScope((scope) {
            scope.setUser(SentryUser(
              id: userId,
              email: email,
              username: username,
              data: customData,
            ));
          });
          break;
      }
    } catch (e) {
      if (kDebugMode) print('Error setting user info: $e');
    }
  }

  // Log custom events for debugging
  static Future<void> log(String message, {Map<String, dynamic>? data}) async {
    if (!_isInitialized) return;

    try {
      switch (_provider) {
        case CrashProvider.crashlytics:
          await FirebaseCrashlytics.instance.log('$message ${data ?? ''}');
          break;
        case CrashProvider.sentry:
          Sentry.addBreadcrumb(Breadcrumb(
            message: message,
            data: data,
            timestamp: DateTime.now(),
          ));
          break;
      }
    } catch (e) {
      if (kDebugMode) print('Error logging: $e');
    }
  }

  // Record non-fatal errors
  static Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
    bool fatal = false,
  }) async {
    if (!_isInitialized) return;

    try {
      switch (_provider) {
        case CrashProvider.crashlytics:
          await FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            reason: reason,
            information: context?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
            fatal: fatal,
          );
          break;
        case CrashProvider.sentry:
          await Sentry.captureException(
            error,
            stackTrace: stackTrace,
            withScope: (scope) {
              if (reason != null) scope.setTag('reason', reason);
              if (context != null) {
                for (final entry in context.entries) {
                  scope.setExtra(entry.key, entry.value);
                }
              }
            },
          );
          break;
      }
    } catch (e) {
      if (kDebugMode) print('Error recording error: $e');
    }
  }

  // Record custom events
  static Future<void> recordEvent(String event, {Map<String, dynamic>? parameters}) async {
    if (!_isInitialized) return;

    try {
      switch (_provider) {
        case CrashProvider.crashlytics:
          await FirebaseCrashlytics.instance.log('Event: $event ${parameters ?? ''}');
          break;
        case CrashProvider.sentry:
          await Sentry.captureMessage(
            'Event: $event',
            level: SentryLevel.info,
            withScope: (scope) {
              if (parameters != null) {
                for (final entry in parameters.entries) {
                  scope.setExtra(entry.key, entry.value);
                }
              }
            },
          );
          break;
      }
    } catch (e) {
      if (kDebugMode) print('Error recording event: $e');
    }
  }

  // Test crash reporting (debug only)
  static Future<void> testCrash() async {
    if (kDebugMode) {
      throw Exception('Test crash from CrewSnow app');
    }
  }
}

enum CrashProvider { crashlytics, sentry }

// Extension for easy error reporting
extension ErrorReporting on Object {
  void reportError([StackTrace? stackTrace, Map<String, dynamic>? context]) {
    CrashReportingService.recordError(
      this,
      stackTrace ?? StackTrace.current,
      context: context,
    );
  }

  void reportFatalError([StackTrace? stackTrace, Map<String, dynamic>? context]) {
    CrashReportingService.recordError(
      this,
      stackTrace ?? StackTrace.current,
      fatal: true,
      context: context,
    );
  }
}
