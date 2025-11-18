// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'station.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Station _$StationFromJson(Map<String, dynamic> json) => Station(
      id: json['id'] as String,
      name: json['name'] as String,
      countryCode: json['countryCode'] as String,
      region: json['region'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      elevationM: (json['elevationM'] as num).toInt(),
      officialWebsite: json['officialWebsite'] as String?,
      seasonStartMonth: (json['seasonStartMonth'] as num).toInt(),
      seasonEndMonth: (json['seasonEndMonth'] as num).toInt(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$StationToJson(Station instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'countryCode': instance.countryCode,
      'region': instance.region,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'elevationM': instance.elevationM,
      'officialWebsite': instance.officialWebsite,
      'seasonStartMonth': instance.seasonStartMonth,
      'seasonEndMonth': instance.seasonEndMonth,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };

UserStationStatus _$UserStationStatusFromJson(Map<String, dynamic> json) =>
    UserStationStatus(
      id: json['id'] as String,
      userId: json['userId'] as String,
      stationId: json['stationId'] as String?,
      dateFrom: json['dateFrom'] == null
          ? null
          : DateTime.parse(json['dateFrom'] as String),
      dateTo: json['dateTo'] == null
          ? null
          : DateTime.parse(json['dateTo'] as String),
      radiusKm: (json['radiusKm'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      station: json['station'] == null
          ? null
          : Station.fromJson(json['station'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserStationStatusToJson(UserStationStatus instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'userId': instance.userId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('stationId', instance.stationId);
  writeNotNull('dateFrom', instance.dateFrom?.toIso8601String());
  writeNotNull('dateTo', instance.dateTo?.toIso8601String());
  writeNotNull('radiusKm', instance.radiusKm);
  val['isActive'] = instance.isActive;
  val['createdAt'] = instance.createdAt.toIso8601String();
  writeNotNull('station', instance.station?.toJson());
  return val;
}
