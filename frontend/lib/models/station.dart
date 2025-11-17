import 'package:json_annotation/json_annotation.dart';

part 'station.g.dart';

@JsonSerializable()
class Station {
  final String id;
  final String name;
  final String countryCode;
  final String region;
  final double latitude;
  final double longitude;
  final int elevationM;
  final String? officialWebsite;
  final int seasonStartMonth;
  final int seasonEndMonth;
  final bool isActive;
  final DateTime createdAt;
  
  const Station({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.elevationM,
    this.officialWebsite,
    required this.seasonStartMonth,
    required this.seasonEndMonth,
    this.isActive = true,
    required this.createdAt,
  });
  
  factory Station.fromJson(Map<String, dynamic> json) => _$StationFromJson(json);
  Map<String, dynamic> toJson() => _$StationToJson(this);
  
  String get displayName => '$name, $countryCode';
  String get altitudeDisplay => '${elevationM}m';
  
  String get flag {
    switch (countryCode) {
      case 'FR': return '🇫🇷';
      case 'CH': return '🇨🇭';
      case 'AT': return '🇦🇹';
      case 'IT': return '🇮🇹';
      case 'ES': return '🇪🇸';
      case 'DE': return '🇩🇪';
      case 'AD': return '🇦🇩';
      default: return '⛷️';
    }
  }
}

@JsonSerializable()
class UserStationStatus {
  final String id;
  final String userId;
  final String stationId;
  final DateTime dateFrom;
  final DateTime dateTo;
  final int radiusKm;
  final bool isActive;
  final DateTime createdAt;
  final Station? station; // Jointure
  
  const UserStationStatus({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.dateFrom,
    required this.dateTo,
    required this.radiusKm,
    this.isActive = true,
    required this.createdAt,
    this.station,
  });
  
  factory UserStationStatus.fromJson(Map<String, dynamic> json) => _$UserStationStatusFromJson(json);
  Map<String, dynamic> toJson() => _$UserStationStatusToJson(this);
  
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(dateFrom.subtract(const Duration(days: 1))) &&
           now.isBefore(dateTo.add(const Duration(days: 1)));
  }
  
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(dateTo)) return 0;
    return dateTo.difference(now).inDays;
  }
  
  String get durationDisplay {
    final duration = dateTo.difference(dateFrom).inDays + 1;
    return '$duration jour${duration > 1 ? 's' : ''}';
  }
}
