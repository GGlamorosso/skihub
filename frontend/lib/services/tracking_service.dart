import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math' as math;

import '../models/ride_stats.dart';
import '../utils/error_handler.dart';
import 'supabase_service.dart';
import 'local_storage_service.dart';

/// Service de tracking GPS pour sessions de ski
class TrackingService {
  static TrackingService? _instance;
  static TrackingService get instance => _instance ??= TrackingService._();
  
  TrackingService._();
  
  final _supabase = SupabaseService.instance;
  final _localStorage = LocalStorageService.instance;
  
  StreamSubscription<Position>? _positionSubscription;
  TrackingSession? _currentSession;
  Timer? _autoSaveTimer;
  
  // Callbacks pour UI
  Function(TrackingSession)? onSessionUpdate;
  Function(String)? onError;
  
  /// État actuel du tracking
  bool get isTracking => _currentSession?.isActive == true;
  bool get isPaused => _currentSession?.canResume == true;
  TrackingSession? get currentSession => _currentSession;
  
  /// Vérifier permissions GPS
  Future<bool> checkPermissions() async {
    try {
      // Vérifier service location activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Service de localisation désactivé');
      }
      
      // Vérifier permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissions GPS refusées définitivement');
      }
      
      // Pour background tracking, demander always
      if (permission == LocationPermission.whileInUse) {
        final alwaysPermission = await Permission.locationAlways.request();
        if (!alwaysPermission.isGranted) {
          debugPrint('⚠️ Background location not granted');
        }
      }
      
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      ErrorHandler.logError(
        context: 'TrackingService.checkPermissions',
        error: e,
      );
      return false;
    }
  }
  
  /// Vérifier consent GPS utilisateur
  Future<bool> checkGPSConsent() async {
    try {
      // ✅ Corrigé : Utiliser 'gps' au lieu de 'gps_tracking' (format Edge Function)
      final response = await _supabase.callFunction(
        functionName: 'manage-consent',
        body: {
          'action': 'check',
          'purpose': 'gps', // Edge Function accepte 'gps', pas 'gps_tracking'
        },
      );
      
      final data = response.data as Map<String, dynamic>;
      return data['granted'] == true;
    } catch (e) {
      debugPrint('Error checking GPS consent: $e');
      return false;
    }
  }
  
  /// Démarrer session tracking
  Future<bool> startSession({String? stationId}) async {
    try {
      // Vérifications préalables
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        throw Exception('Permissions GPS requises');
      }
      
      final hasConsent = await checkGPSConsent();
      if (!hasConsent) {
        throw Exception('Consent GPS requis');
      }
      
      // Arrêter session précédente si existe
      if (_currentSession != null) {
        await stopSession();
      }
      
      // Créer nouvelle session
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentSession = TrackingSession(
        id: sessionId,
        userId: _supabase.currentUserId!,
        startedAt: DateTime.now(),
        stationId: stationId,
      );
      
      // Sauvegarder localement
      await _localStorage.saveTrackingSession(_currentSession!);
      
      // Démarrer stream GPS
      await _startLocationStream();
      
      // Auto-save périodique
      _startAutoSave();
      
      debugPrint('✅ Tracking session started: $sessionId');
      return true;
    } catch (e) {
      ErrorHandler.logError(
        context: 'TrackingService.startSession',
        error: e,
        additionalData: {'station_id': stationId},
      );
      
      onError?.call(ErrorHandler.getReadableError(e));
      return false;
    }
  }
  
  /// Démarrer stream GPS
  Future<void> _startLocationStream() async {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: TrackingConfig.distanceFilterMeters.toInt(),
    );
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _handleNewPosition,
      onError: (error) {
        ErrorHandler.logError(
          context: 'TrackingService._startLocationStream',
          error: error,
        );
        onError?.call('Erreur GPS: ${ErrorHandler.getReadableError(error)}');
      },
    );
  }
  
  /// Traiter nouvelle position GPS
  void _handleNewPosition(Position position) {
    if (_currentSession == null || !_currentSession!.isActive) return;
    
    final newPoint = TrackPoint(
      timestamp: DateTime.now(),
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speed: position.speed,
      accuracy: position.accuracy,
      heading: position.heading,
    );
    
    // Validation point
    final lastPoint = _currentSession!.lastPoint;
    if (!TrackingConfig.isValidPoint(newPoint, lastPoint)) {
      debugPrint('⚠️ Invalid GPS point filtered');
      return;
    }
    
    // Calculer stats
    final updatedSession = _updateSessionStats(_currentSession!, newPoint);
    _currentSession = updatedSession;
    
    // Notifier UI
    onSessionUpdate?.call(_currentSession!);
    
    // Sauvegarder localement (batch)
    _localStorage.addTrackPoint(_currentSession!.id, newPoint);
  }
  
  /// Mettre à jour stats session
  TrackingSession _updateSessionStats(TrackingSession session, TrackPoint newPoint) {
    final points = [...session.points, newPoint];
    
    double distance = session.currentDistance;
    double maxSpeed = session.currentMaxSpeed;
    int elevationGain = session.currentElevationGain;
    
    // Calculer distance depuis dernier point
    if (session.lastPoint != null) {
      final deltaDistance = newPoint.distanceTo(session.lastPoint!) / 1000; // km
      distance += deltaDistance;
    }
    
    // Mettre à jour vitesse max
    if (newPoint.speedKmh != null) {
      maxSpeed = math.max(maxSpeed, newPoint.speedKmh!);
    }
    
    // Calculer dénivelé positif
    if (newPoint.altitude != null && session.lastPoint?.altitude != null) {
      final deltaElevation = newPoint.altitude! - session.lastPoint!.altitude!;
      if (deltaElevation > 0) {
        elevationGain += deltaElevation.round();
      }
    }
    
    return session.copyWith(
      points: points,
      currentDistance: distance,
      currentMaxSpeed: maxSpeed,
      currentElevationGain: elevationGain,
    );
  }
  
  /// Mettre en pause
  Future<void> pauseSession() async {
    if (_currentSession == null || !_currentSession!.isActive) return;
    
    try {
      // Arrêter GPS stream
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      
      // Mettre à jour statut
      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.paused,
      );
      
      // Sauvegarder
      await _localStorage.saveTrackingSession(_currentSession!);
      
      onSessionUpdate?.call(_currentSession!);
      
      debugPrint('⏸️ Tracking session paused');
    } catch (e) {
      ErrorHandler.logError(
        context: 'TrackingService.pauseSession',
        error: e,
      );
    }
  }
  
  /// Reprendre session
  Future<void> resumeSession() async {
    if (_currentSession == null || !_currentSession!.canResume) return;
    
    try {
      // Calculer temps de pause
      final pauseStart = _currentSession!.points.last.timestamp;
      final pauseTime = DateTime.now().difference(pauseStart).inMinutes;
      
      // Mettre à jour session
      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.active,
        pausedTimeMin: _currentSession!.pausedTimeMin + pauseTime,
      );
      
      // Redémarrer GPS
      await _startLocationStream();
      
      onSessionUpdate?.call(_currentSession!);
      
      debugPrint('▶️ Tracking session resumed');
    } catch (e) {
      ErrorHandler.logError(
        context: 'TrackingService.resumeSession',
        error: e,
      );
    }
  }
  
  /// Arrêter session et synchroniser
  Future<bool> stopSession() async {
    if (_currentSession == null) return true;
    
    try {
      // Arrêter GPS
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      
      // Arrêter auto-save
      _autoSaveTimer?.cancel();
      _autoSaveTimer = null;
      
      // Finaliser session
      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.completed,
        endedAt: DateTime.now(),
      );
      
      // Sauvegarder localement
      await _localStorage.saveTrackingSession(_currentSession!);
      
      // Synchroniser avec backend
      final success = await _syncSessionToBackend(_currentSession!);
      
      if (success) {
        // Nettoyer session locale
        await _localStorage.deleteTrackingSession(_currentSession!.id);
      }
      
      // Notifier UI
      onSessionUpdate?.call(_currentSession!);
      
      // Clear session
      final completedSession = _currentSession!;
      _currentSession = null;
      
      debugPrint('🏁 Tracking session completed: ${completedSession.id}');
      return success;
    } catch (e) {
      ErrorHandler.logError(
        context: 'TrackingService.stopSession',
        error: e,
      );
      
      onError?.call(ErrorHandler.getReadableError(e));
      return false;
    }
  }
  
  /// Synchroniser session avec backend
  Future<bool> _syncSessionToBackend(TrackingSession session) async {
    try {
      final rideStats = session.toRideStats();
      
      // Upsert dans ride_stats_daily
      await _supabase.from('ride_stats_daily').upsert({
        'user_id': rideStats.userId,
        'date': rideStats.date.toIso8601String().split('T')[0],
        'distance_km': rideStats.distanceKm,
        'vmax_kmh': rideStats.vmaxKmh,
        'elevation_gain_m': rideStats.elevationGainM,
        'moving_time_min': rideStats.movingTimeMin,
        'runs_count': rideStats.runsCount,
        'station_id': rideStats.stationId,
        'created_at': rideStats.createdAt.toIso8601String(),
      });
      
      debugPrint('✅ Session synced to backend');
      return true;
    } catch (e) {
      ErrorHandler.logError(
        context: 'TrackingService._syncSessionToBackend',
        error: e,
        additionalData: {
          'session_id': session.id,
          'distance': session.currentDistance,
          'points_count': session.pointsCount,
        },
      );
      
      return false;
    }
  }
  
  /// Auto-save périodique
  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(
      const Duration(minutes: TrackingConfig.autoSaveIntervalMinutes),
      (timer) {
        if (_currentSession != null) {
          _localStorage.saveTrackingSession(_currentSession!);
          debugPrint('💾 Auto-save session: ${_currentSession!.pointsCount} points');
        }
      },
    );
  }
  
  /// Récupérer session sauvegardée (après crash app)
  Future<TrackingSession?> restoreSession() async {
    try {
      final session = await _localStorage.getActiveTrackingSession();
      
      if (session != null) {
        // Vérifier si session pas trop ancienne
        final age = DateTime.now().difference(session.startedAt);
        if (age.inHours > TrackingConfig.maxSessionHours) {
          // Session trop ancienne, l'abandonner
          await _localStorage.deleteTrackingSession(session.id);
          return null;
        }
        
        _currentSession = session;
        debugPrint('🔄 Session restored: ${session.id}');
      }
      
      return session;
    } catch (e) {
      debugPrint('Error restoring session: $e');
      return null;
    }
  }
  
  /// Annuler session courante
  Future<void> cancelSession() async {
    if (_currentSession == null) return;
    
    try {
      // Arrêter GPS
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      
      // Arrêter auto-save
      _autoSaveTimer?.cancel();
      _autoSaveTimer = null;
      
      // Marquer comme annulée
      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.cancelled,
        endedAt: DateTime.now(),
      );
      
      // Supprimer session locale
      await _localStorage.deleteTrackingSession(_currentSession!.id);
      
      // Clear
      _currentSession = null;
      
      debugPrint('❌ Tracking session cancelled');
    } catch (e) {
      debugPrint('Error cancelling session: $e');
    }
  }
  
  /// Obtenir position actuelle
  Future<Position?> getCurrentPosition() async {
    try {
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: settings.accuracy,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }
  
  /// Calculer distance entre deux points
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
  
  /// Cleanup service
  Future<void> dispose() async {
    await _positionSubscription?.cancel();
    _autoSaveTimer?.cancel();
    _currentSession = null;
    onSessionUpdate = null;
    onError = null;
  }
  
  /// Obtenir settings location optimisés
  LocationSettings getOptimizedSettings({bool economyMode = false}) {
    if (economyMode) {
      return const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10, // 10m au lieu de 5m
      );
    }
    
    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: TrackingConfig.distanceFilterMeters.toInt(),
    );
  }
  
  /// Test GPS (pour debug)
  Future<Map<String, dynamic>> testGPS() async {
    try {
      final position = await getCurrentPosition();
      
      if (position == null) {
        return {'success': false, 'error': 'No GPS fix'};
      }
      
      return {
        'success': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'altitude': position.altitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
