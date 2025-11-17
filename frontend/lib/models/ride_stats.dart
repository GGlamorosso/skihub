import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ride_stats.g.dart';

@JsonSerializable()
class RideStats {
  final String id;
  final String userId;
  final DateTime date;
  final double distanceKm;
  final double vmaxKmh;
  final int elevationGainM;
  final int movingTimeMin;
  final int runsCount;
  final String? stationId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Données locales (non DB)
  final String? stationName;
  final bool isSynced;
  
  const RideStats({
    required this.id,
    required this.userId,
    required this.date,
    required this.distanceKm,
    required this.vmaxKmh,
    required this.elevationGainM,
    required this.movingTimeMin,
    required this.runsCount,
    this.stationId,
    required this.createdAt,
    this.updatedAt,
    this.stationName,
    this.isSynced = false,
  });
  
  factory RideStats.fromJson(Map<String, dynamic> json) => _$RideStatsFromJson(json);
  Map<String, dynamic> toJson() => _$RideStatsToJson(this);
  
  RideStats copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? distanceKm,
    double? vmaxKmh,
    int? elevationGainM,
    int? movingTimeMin,
    int? runsCount,
    String? stationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? stationName,
    bool? isSynced,
  }) {
    return RideStats(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      distanceKm: distanceKm ?? this.distanceKm,
      vmaxKmh: vmaxKmh ?? this.vmaxKmh,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      movingTimeMin: movingTimeMin ?? this.movingTimeMin,
      runsCount: runsCount ?? this.runsCount,
      stationId: stationId ?? this.stationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stationName: stationName ?? this.stationName,
      isSynced: isSynced ?? this.isSynced,
    );
  }
  
  /// Distance display
  String get distanceDisplay => '${distanceKm.toStringAsFixed(1)} km';
  
  /// Vitesse max display
  String get speedDisplay => '${vmaxKmh.toStringAsFixed(1)} km/h';
  
  /// Dénivelé display
  String get elevationDisplay => '${elevationGainM.toString()} m';
  
  /// Temps display
  String get timeDisplay {
    final hours = movingTimeMin ~/ 60;
    final minutes = movingTimeMin % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }
  
  /// Vitesse moyenne
  double get averageSpeed {
    if (movingTimeMin == 0) return 0;
    return (distanceKm / movingTimeMin) * 60; // km/h
  }
  
  /// Vitesse moyenne display
  String get averageSpeedDisplay => '${averageSpeed.toStringAsFixed(1)} km/h';
  
  /// Runs par heure
  double get runsPerHour {
    if (movingTimeMin == 0) return 0;
    return (runsCount / movingTimeMin) * 60;
  }
  
  /// Score performance (pour comparaisons)
  double get performanceScore {
    // Score basé sur distance, vitesse, dénivelé
    return (distanceKm * 10) + (vmaxKmh * 0.5) + (elevationGainM * 0.1);
  }
}

@JsonSerializable()
class TrackingSession {
  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<TrackPoint> points;
  final SessionStatus status;
  final String? stationId;
  final double currentDistance;
  final double currentMaxSpeed;
  final int currentElevationGain;
  final int pausedTimeMin;
  
  const TrackingSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    this.points = const [],
    this.status = SessionStatus.active,
    this.stationId,
    this.currentDistance = 0.0,
    this.currentMaxSpeed = 0.0,
    this.currentElevationGain = 0,
    this.pausedTimeMin = 0,
  });
  
  factory TrackingSession.fromJson(Map<String, dynamic> json) => _$TrackingSessionFromJson(json);
  Map<String, dynamic> toJson() => _$TrackingSessionToJson(this);
  
  TrackingSession copyWith({
    String? id,
    String? userId,
    DateTime? startedAt,
    DateTime? endedAt,
    List<TrackPoint>? points,
    SessionStatus? status,
    String? stationId,
    double? currentDistance,
    double? currentMaxSpeed,
    int? currentElevationGain,
    int? pausedTimeMin,
  }) {
    return TrackingSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      points: points ?? this.points,
      status: status ?? this.status,
      stationId: stationId ?? this.stationId,
      currentDistance: currentDistance ?? this.currentDistance,
      currentMaxSpeed: currentMaxSpeed ?? this.currentMaxSpeed,
      currentElevationGain: currentElevationGain ?? this.currentElevationGain,
      pausedTimeMin: pausedTimeMin ?? this.pausedTimeMin,
    );
  }
  
  /// Durée totale session
  Duration get totalDuration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }
  
  /// Temps de mouvement (sans pauses)
  int get movingTimeMin {
    final totalMin = totalDuration.inMinutes;
    return totalMin - pausedTimeMin;
  }
  
  /// Session active
  bool get isActive => status == SessionStatus.active;
  
  /// Session terminée
  bool get isCompleted => status == SessionStatus.completed;
  
  /// Peut être reprise
  bool get canResume => status == SessionStatus.paused;
  
  /// Nombre de points GPS
  int get pointsCount => points.length;
  
  /// Dernier point
  TrackPoint? get lastPoint => points.isNotEmpty ? points.last : null;
  
  /// Convertir en RideStats final
  RideStats toRideStats() {
    return RideStats(
      id: id,
      userId: userId,
      date: startedAt,
      distanceKm: currentDistance,
      vmaxKmh: currentMaxSpeed,
      elevationGainM: currentElevationGain,
      movingTimeMin: movingTimeMin,
      runsCount: _calculateRuns(),
      stationId: stationId,
      createdAt: startedAt,
      updatedAt: endedAt,
    );
  }
  
  /// Calculer nombre de runs (estimation)
  int _calculateRuns() {
    if (points.length < 10) return 1;
    
    // Estimation basée sur variations altitude
    int runs = 0;
    double? lastHighPoint;
    
    for (final point in points) {
      if (point.altitude != null) {
        if (lastHighPoint == null || point.altitude! > lastHighPoint + 50) {
          runs++;
          lastHighPoint = point.altitude;
        }
      }
    }
    
    return runs > 0 ? runs : 1;
  }
}

@JsonSerializable()
class TrackPoint {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed; // m/s
  final double? accuracy;
  final double? heading;
  
  const TrackPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.accuracy,
    this.heading,
  });
  
  factory TrackPoint.fromJson(Map<String, dynamic> json) => _$TrackPointFromJson(json);
  Map<String, dynamic> toJson() => _$TrackPointToJson(this);
  
  /// Vitesse en km/h
  double? get speedKmh {
    if (speed == null) return null;
    return speed! * 3.6;
  }
  
  /// Point valide (précision acceptable)
  bool get isAccurate => accuracy == null || accuracy! < 20; // 20m précision
  
  /// Distance vers autre point
  double distanceTo(TrackPoint other) {
    return _calculateDistance(latitude, longitude, other.latitude, other.longitude);
  }
  
  /// Calcul distance haversine simplifié
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // mètres
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }
  
  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180.0);
  }
}

enum SessionStatus {
  @JsonValue('active')
  active,
  
  @JsonValue('paused')
  paused,
  
  @JsonValue('completed')
  completed,
  
  @JsonValue('cancelled')
  cancelled;
  
  String get displayName {
    switch (this) {
      case SessionStatus.active:
        return 'En cours';
      case SessionStatus.paused:
        return 'En pause';
      case SessionStatus.completed:
        return 'Terminée';
      case SessionStatus.cancelled:
        return 'Annulée';
    }
  }
  
  Color get color {
    switch (this) {
      case SessionStatus.active:
        return const Color(0xFF4CAF50); // Vert
      case SessionStatus.paused:
        return const Color(0xFFFF9800); // Orange
      case SessionStatus.completed:
        return const Color(0xFF2196F3); // Bleu
      case SessionStatus.cancelled:
        return const Color(0xFF9E9E9E); // Gris
    }
  }
}

/// Configuration tracking
class TrackingConfig {
  static const int updateIntervalSeconds = 10;
  static const double distanceFilterMeters = 5.0;
  static const double minSpeedMps = 1.0; // Vitesse minimum pour "mouvement"
  static const double maxReasonableSpeedKmh = 150.0; // Filtre outliers
  static const int maxSessionHours = 12;
  static const int autoSaveIntervalMinutes = 5;
  
  /// Validation point GPS
  static bool isValidPoint(TrackPoint point, TrackPoint? previousPoint) {
    // Vérifier précision
    if (!point.isAccurate) return false;
    
    // Vérifier vitesse raisonnable
    if (point.speedKmh != null && point.speedKmh! > maxReasonableSpeedKmh) {
      return false;
    }
    
    // Vérifier distance par rapport au point précédent
    if (previousPoint != null) {
      final distance = point.distanceTo(previousPoint);
      final timeDiff = point.timestamp.difference(previousPoint.timestamp).inSeconds;
      
      // Si distance > 200m en moins de 10s, probable glitch GPS
      if (timeDiff < updateIntervalSeconds && distance > 200) {
        return false;
      }
    }
    
    return true;
  }
}
