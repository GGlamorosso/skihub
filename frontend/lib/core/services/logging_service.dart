import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../config/app_config.dart';
import 'crash_reporting_service.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  late final Logger _logger;

  void initialize() {
    _logger = Logger(
      filter: _LogFilter(),
      printer: _LogPrinter(),
      output: _LogOutput(),
      level: AppConfig.isDevelopment ? Level.debug : Level.warning,
    );

    if (kDebugMode) print('📝 Logging service initialized');
  }

  // Log levels
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error, stackTrace);
  }

  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error, stackTrace);
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error, stackTrace);
    
    // Report warnings to crash reporting in production
    if (kReleaseMode && error != null) {
      CrashReportingService.recordError(error, stackTrace, context: {
        'level': 'warning',
        'message': message,
      });
    }
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error, stackTrace);
    
    // Always report errors to crash reporting
    if (error != null) {
      CrashReportingService.recordError(error, stackTrace, context: {
        'level': 'error',
        'message': message,
      });
    }
  }

  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error, stackTrace);
    
    // Report fatal errors immediately
    if (error != null) {
      CrashReportingService.recordError(error, stackTrace, fatal: true, context: {
        'level': 'fatal',
        'message': message,
      });
    }
  }

  // Feature-specific logging
  void logMatching(String event, {Map<String, dynamic>? context}) {
    info('[MATCHING] $event', context);
  }

  void logChat(String event, {Map<String, dynamic>? context}) {
    info('[CHAT] $event', context);
  }

  void logPremium(String event, {Map<String, dynamic>? context}) {
    info('[PREMIUM] $event', context);
  }

  void logTracking(String event, {Map<String, dynamic>? context}) {
    info('[TRACKING] $event', context);
  }

  void logAI(String event, {Map<String, dynamic>? context}) {
    info('[AI] $event', context);
  }

  void logPrivacy(String event, {Map<String, dynamic>? context}) {
    info('[PRIVACY] $event', context);
  }

  void logAuth(String event, {Map<String, dynamic>? context}) {
    info('[AUTH] $event', context);
  }

  void logNetwork(String event, {Map<String, dynamic>? context}) {
    debug('[NETWORK] $event', context);
  }

  void logPerformance(String metric, double value, {Map<String, String>? tags}) {
    info('[PERFORMANCE] $metric: ${value}ms', tags);
  }
}

class _LogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In release mode, only log warnings and above
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }
    
    // In debug mode, log everything except trace
    return event.level.index >= Level.debug.index;
  }
}

class _LogPrinter extends PrettyPrinter {
  _LogPrinter() : super(
    stackTraceBeginIndex: 0,
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  );

  @override
  List<String> log(LogEvent event) {
    if (kReleaseMode) {
      // Minimal logging in release mode
      return [
        '[${event.level.name.toUpperCase()}] ${event.message}'
      ];
    }
    
    return super.log(event);
  }
}

class _LogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // Print to console in debug mode
    if (kDebugMode) {
      for (final line in event.lines) {
        print(line);
      }
    }
    
    // In release mode, could send to remote logging service
    if (kReleaseMode) {
      _sendToRemoteLogging(event);
    }
  }

  void _sendToRemoteLogging(OutputEvent event) {
    // This could send logs to a remote service like:
    // - Supabase functions
    // - CloudWatch
    // - Datadog
    // - Custom logging service
    
    // For now, just store critical logs
    if (event.level.index >= Level.error.index) {
      // Could store in local database for later upload
    }
  }
}

// Mixin for easy logging in widgets/services
mixin LoggingMixin {
  LoggingService get logger => LoggingService();

  void logDebug(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.debug('[$runtimeType] $message', error, stackTrace);
  }

  void logInfo(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.info('[$runtimeType] $message', error, stackTrace);
  }

  void logWarning(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.warning('[$runtimeType] $message', error, stackTrace);
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.error('[$runtimeType] $message', error, stackTrace);
  }

  void logFatal(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.fatal('[$runtimeType] $message', error, stackTrace);
  }
}

// Performance logging utilities
class PerformanceLogger {
  static final Map<String, Stopwatch> _stopwatches = {};

  static void startTimer(String operation) {
    _stopwatches[operation] = Stopwatch()..start();
  }

  static void endTimer(String operation, {Map<String, String>? tags}) {
    final stopwatch = _stopwatches.remove(operation);
    if (stopwatch != null) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds.toDouble();
      
      LoggingService().logPerformance(operation, duration, tags: tags);
      
      // Log slow operations as warnings
      if (duration > 1000) {
        LoggingService().warning('Slow operation: $operation took ${duration}ms');
      }
    }
  }

  static T measureSync<T>(String operation, T Function() function) {
    startTimer(operation);
    try {
      return function();
    } finally {
      endTimer(operation);
    }
  }

  static Future<T> measureAsync<T>(String operation, Future<T> Function() function) async {
    startTimer(operation);
    try {
      return await function();
    } finally {
      endTimer(operation);
    }
  }
}

// Network request logging
class NetworkLogger {
  static void logRequest(String method, String url, {Map<String, dynamic>? data}) {
    LoggingService().logNetwork('Request: $method $url', context: data);
  }

  static void logResponse(String method, String url, int statusCode, {int? responseTime}) {
    LoggingService().logNetwork('Response: $method $url → $statusCode', context: {
      'status_code': statusCode,
      'response_time_ms': responseTime,
    });
  }

  static void logError(String method, String url, dynamic error) {
    LoggingService().logNetwork('Error: $method $url', context: {
      'error': error.toString(),
    });
  }
}
