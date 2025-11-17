// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RideStats _$RideStatsFromJson(Map<String, dynamic> json) => RideStats(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      vmaxKmh: (json['vmaxKmh'] as num).toDouble(),
      elevationGainM: (json['elevationGainM'] as num).toInt(),
      movingTimeMin: (json['movingTimeMin'] as num).toInt(),
      runsCount: (json['runsCount'] as num).toInt(),
      stationId: json['stationId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      stationName: json['stationName'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$RideStatsToJson(RideStats instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'date': instance.date.toIso8601String(),
      'distanceKm': instance.distanceKm,
      'vmaxKmh': instance.vmaxKmh,
      'elevationGainM': instance.elevationGainM,
      'movingTimeMin': instance.movingTimeMin,
      'runsCount': instance.runsCount,
      'stationId': instance.stationId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'stationName': instance.stationName,
      'isSynced': instance.isSynced,
    };

TrackingSession _$TrackingSessionFromJson(Map<String, dynamic> json) =>
    TrackingSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      points: (json['points'] as List<dynamic>?)
              ?.map((e) => TrackPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      status: $enumDecodeNullable(_$SessionStatusEnumMap, json['status']) ??
          SessionStatus.active,
      stationId: json['stationId'] as String?,
      currentDistance: (json['currentDistance'] as num?)?.toDouble() ?? 0.0,
      currentMaxSpeed: (json['currentMaxSpeed'] as num?)?.toDouble() ?? 0.0,
      currentElevationGain:
          (json['currentElevationGain'] as num?)?.toInt() ?? 0,
      pausedTimeMin: (json['pausedTimeMin'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TrackingSessionToJson(TrackingSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'points': instance.points,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'stationId': instance.stationId,
      'currentDistance': instance.currentDistance,
      'currentMaxSpeed': instance.currentMaxSpeed,
      'currentElevationGain': instance.currentElevationGain,
      'pausedTimeMin': instance.pausedTimeMin,
    };

const _$SessionStatusEnumMap = {
  SessionStatus.active: 'active',
  SessionStatus.paused: 'paused',
  SessionStatus.completed: 'completed',
  SessionStatus.cancelled: 'cancelled',
};

TrackPoint _$TrackPointFromJson(Map<String, dynamic> json) => TrackPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TrackPointToJson(TrackPoint instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'altitude': instance.altitude,
      'speed': instance.speed,
      'accuracy': instance.accuracy,
      'heading': instance.heading,
    };
