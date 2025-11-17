import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/ride_stats.dart';
import '../../../services/tracking_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../utils/error_handler.dart';

/// État du tracking
@immutable
class TrackingState {
  const TrackingState({
    this.currentSession,
    this.isTracking = false,
    this.isPaused = false,
    this.hasPermissions = false,
    this.hasConsent = false,
    this.economyMode = false,
    this.error,
    this.lastGPSTest,
  });
  
  final TrackingSession? currentSession;
  final bool isTracking;
  final bool isPaused;
  final bool hasPermissions;
  final bool hasConsent;
  final bool economyMode;
  final String? error;
  final Map<String, dynamic>? lastGPSTest;
  
  bool get hasError => error != null;
  bool get canStartTracking => hasPermissions && hasConsent && !isTracking;
  bool get canPauseTracking => isTracking && !isPaused;
  bool get canResumeTracking => isTracking && isPaused;
  bool get canStopTracking => isTracking;
  bool get hasActiveSession => currentSession != null;
  
  // Stats temps réel
  double get currentDistance => currentSession?.currentDistance ?? 0.0;
  double get currentMaxSpeed => currentSession?.currentMaxSpeed ?? 0.0;
  int get currentElevationGain => currentSession?.currentElevationGain ?? 0;
  Duration get sessionDuration => currentSession?.totalDuration ?? Duration.zero;
  int get pointsCollected => currentSession?.pointsCount ?? 0;
  
  TrackingState copyWith({
    TrackingSession? currentSession,
    bool? isTracking,
    bool? isPaused,
    bool? hasPermissions,
    bool? hasConsent,
    bool? economyMode,
    String? error,
    Map<String, dynamic>? lastGPSTest,
  }) {
    return TrackingState(
      currentSession: currentSession ?? this.currentSession,
      isTracking: isTracking ?? this.isTracking,
      isPaused: isPaused ?? this.isPaused,
      hasPermissions: hasPermissions ?? this.hasPermissions,
      hasConsent: hasConsent ?? this.hasConsent,
      economyMode: economyMode ?? this.economyMode,
      error: error,
      lastGPSTest: lastGPSTest ?? this.lastGPSTest,
    );
  }
}

/// Controller pour tracking
class TrackingController extends StateNotifier<TrackingState> {
  TrackingController() : super(const TrackingState()) {
    _init();
  }
  
  final _trackingService = TrackingService.instance;
  final _localStorage = LocalStorageService.instance;
  
  /// Initialisation
  Future<void> _init() async {
    await _localStorage.initialize();
    await _checkPermissionsAndConsent();
    await _restoreSessionIfExists();
    
    // Setup callbacks
    _trackingService.onSessionUpdate = _handleSessionUpdate;
    _trackingService.onError = _handleTrackingError;
  }
  
  @override
  void dispose() {
    _trackingService.dispose();
    super.dispose();
  }
  
  /// Vérifier permissions et consents
  Future<void> _checkPermissionsAndConsent() async {
    try {
      final hasPermissions = await _trackingService.checkPermissions();
      final hasConsent = await _trackingService.checkGPSConsent();
      
      state = state.copyWith(
        hasPermissions: hasPermissions,
        hasConsent: hasConsent,
      );
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.getReadableError(e));
    }
  }
  
  /// Restaurer session après crash app
  Future<void> _restoreSessionIfExists() async {
    try {
      final session = await _trackingService.restoreSession();
      
      if (session != null) {
        state = state.copyWith(
          currentSession: session,
          isTracking: session.isActive,
          isPaused: session.canResume,
        );
        
        // Si session active, redémarrer tracking
        if (session.isActive) {
          await _trackingService.startSession(stationId: session.stationId);
        }
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
  }
  
  /// Démarrer tracking
  Future<bool> startTracking({String? stationId}) async {
    state = state.copyWith(error: null);
    
    try {
      final success = await _trackingService.startSession(stationId: stationId);
      
      if (success) {
        state = state.copyWith(
          isTracking: true,
          isPaused: false,
        );
      }
      
      return success;
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.getReadableError(e));
      return false;
    }
  }
  
  /// Mettre en pause
  Future<void> pauseTracking() async {
    try {
      await _trackingService.pauseSession();
      state = state.copyWith(isPaused: true);
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.getReadableError(e));
    }
  }
  
  /// Reprendre
  Future<void> resumeTracking() async {
    try {
      await _trackingService.resumeSession();
      state = state.copyWith(isPaused: false);
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.getReadableError(e));
    }
  }
  
  /// Arrêter et synchroniser
  Future<bool> stopTracking() async {
    state = state.copyWith(error: null);
    
    try {
      final success = await _trackingService.stopSession();
      
      state = state.copyWith(
        isTracking: false,
        isPaused: false,
        currentSession: null,
      );
      
      return success;
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.getReadableError(e));
      return false;
    }
  }
  
  /// Annuler session
  Future<void> cancelTracking() async {
    try {
      await _trackingService.cancelSession();
      
      state = state.copyWith(
        isTracking: false,
        isPaused: false,
        currentSession: null,
      );
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.getReadableError(e));
    }
  }
  
  /// Toggle mode économie
  void toggleEconomyMode() {
    state = state.copyWith(economyMode: !state.economyMode);
    
    // TODO: Appliquer nouveaux settings GPS si session active
    debugPrint('Economy mode: ${state.economyMode}');
  }
  
  /// Demander permissions
  Future<bool> requestPermissions() async {
    try {
      final granted = await _trackingService.checkPermissions();
      state = state.copyWith(hasPermissions: granted);
      return granted;
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.getReadableError(e));
      return false;
    }
  }
  
  /// Test GPS
  Future<void> testGPS() async {
    try {
      final result = await _trackingService.testGPS();
      state = state.copyWith(lastGPSTest: result);
      
      if (!result['success']) {
        state = state.copyWith(error: result['error']);
      }
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.getReadableError(e));
    }
  }
  
  /// Handle session updates depuis service
  void _handleSessionUpdate(TrackingSession session) {
    state = state.copyWith(currentSession: session);
  }
  
  /// Handle erreurs tracking
  void _handleTrackingError(String error) {
    state = state.copyWith(error: error);
  }
  
  /// Clear erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Refresh permissions et consent
  Future<void> refreshPermissions() async {
    await _checkPermissionsAndConsent();
  }
}

/// Providers pour tracking
final trackingControllerProvider = StateNotifierProvider<TrackingController, TrackingState>((ref) {
  return TrackingController();
});

final isTrackingProvider = Provider<bool>((ref) {
  return ref.watch(trackingControllerProvider).isTracking;
});

final currentSessionProvider = Provider<TrackingSession?>((ref) {
  return ref.watch(trackingControllerProvider).currentSession;
});

final trackingPermissionsProvider = Provider<bool>((ref) {
  return ref.watch(trackingControllerProvider).hasPermissions;
});

final trackingConsentProvider = Provider<bool>((ref) {
  return ref.watch(trackingControllerProvider).hasConsent;
});
