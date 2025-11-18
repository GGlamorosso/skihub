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

@JsonSerializable(
  explicitToJson: true,
  includeIfNull: false, // Ne pas inclure les nulls dans le JSON
)
class UserStationStatus {
  final String id;
  final String userId;
  @JsonKey(includeIfNull: false)
  final String? stationId; // ✅ Corrigé : nullable car peut être null si pas de station
  @JsonKey(includeIfNull: false)
  final DateTime? dateFrom; // ✅ Corrigé : nullable
  @JsonKey(includeIfNull: false)
  final DateTime? dateTo; // ✅ Corrigé : nullable
  @JsonKey(includeIfNull: false)
  final int? radiusKm; // ✅ Corrigé : nullable
  final bool isActive;
  final DateTime createdAt;
  @JsonKey(includeIfNull: false)
  final Station? station; // Jointure
  
  const UserStationStatus({
    required this.id,
    required this.userId,
    this.stationId, // ✅ Plus required, peut être null
    this.dateFrom, // ✅ Plus required, peut être null
    this.dateTo, // ✅ Plus required, peut être null
    this.radiusKm, // ✅ Plus required, peut être null
    this.isActive = true,
    required this.createdAt,
    this.station,
  });
  
  factory UserStationStatus.fromJson(Map<String, dynamic> json) => _$UserStationStatusFromJson(json);
  Map<String, dynamic> toJson() => _$UserStationStatusToJson(this);
  
  bool get isCurrentlyActive {
    if (dateFrom == null || dateTo == null) return false;
    final now = DateTime.now();
    return isActive && 
           now.isAfter(dateFrom!.subtract(const Duration(days: 1))) &&
           now.isBefore(dateTo!.add(const Duration(days: 1)));
  }
  
  int get remainingDays {
    if (dateTo == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(dateTo!)) return 0;
    return dateTo!.difference(now).inDays;
  }
  
  String get durationDisplay {
    if (dateFrom == null || dateTo == null) return 'Non défini';
    final duration = dateTo!.difference(dateFrom!).inDays + 1;
    return '$duration jour${duration > 1 ? 's' : ''}';
  }
  
  /// Vérifier si la station est valide (a tous les champs requis)
  bool get isValid {
    return stationId != null && 
           dateFrom != null && 
           dateTo != null && 
           radiusKm != null;
  }
}
