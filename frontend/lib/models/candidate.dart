import 'package:json_annotation/json_annotation.dart';
import 'user_profile.dart';

part 'candidate.g.dart';

@JsonSerializable()
class Candidate {
  final String id;
  final String username;
  final int age;
  final UserLevel level;
  final bool isPremium;
  final double score;
  final double distanceKm;
  final String? photoUrl;
  final List<RideStyle> rideStyles;
  final List<String> languages;
  final String stationName;
  final DateTime availableFrom;
  final DateTime availableTo;
  final double boostMultiplier;
  final String? bio;
  final int? maxSpeed;
  final bool isVerified;
  
  const Candidate({
    required this.id,
    required this.username,
    required this.age,
    required this.level,
    this.isPremium = false,
    required this.score,
    required this.distanceKm,
    this.photoUrl,
    required this.rideStyles,
    required this.languages,
    required this.stationName,
    required this.availableFrom,
    required this.availableTo,
    this.boostMultiplier = 1.0,
    this.bio,
    this.maxSpeed,
    this.isVerified = false,
  });
  
  factory Candidate.fromJson(Map<String, dynamic> json) => _$CandidateFromJson(json);
  Map<String, dynamic> toJson() => _$CandidateToJson(this);
  
  /// Compatibilité niveau (pour affichage)
  String get levelCompatibility {
    // Logic pour afficher compatibilité niveau
    return level.displayName;
  }
  
  /// Styles communs pour affichage
  List<RideStyle> getCommonStyles(List<RideStyle> userStyles) {
    return rideStyles.where((style) => userStyles.contains(style)).toList();
  }
  
  /// Langues communes pour affichage
  List<String> getCommonLanguages(List<String> userLanguages) {
    return languages.where((lang) => userLanguages.contains(lang)).toList();
  }
  
  /// Distance display
  String get distanceDisplay {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toInt()}m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
  
  /// Période disponibilité
  String get availabilityDisplay {
    final start = availableFrom;
    final end = availableTo;
    
    if (start.year == end.year && start.month == end.month) {
      return '${start.day}-${end.day}/${start.month}';
    }
    
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }
  
  /// Score display (sur 100)
  int get scorePercent => (score * 10).round().clamp(0, 100);
  
  /// Est-ce un boost actif
  bool get isBoosted => boostMultiplier > 1.0;
  
  /// Vitesse display
  String? get speedDisplay {
    if (maxSpeed == null) return null;
    return '$maxSpeed km/h';
  }
  
  /// Jours restants de disponibilité
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(availableTo)) return 0;
    return availableTo.difference(now).inDays;
  }
  
  /// Est disponible maintenant
  bool get isCurrentlyAvailable {
    final now = DateTime.now();
    return now.isAfter(availableFrom.subtract(const Duration(days: 1))) &&
           now.isBefore(availableTo.add(const Duration(days: 1)));
  }
}

@JsonSerializable()
class MatchResult {
  final bool matched;
  final String? matchId;
  final QuotaInfo quotaInfo;
  final String? message;
  final DateTime timestamp;
  
  const MatchResult({
    required this.matched,
    this.matchId,
    required this.quotaInfo,
    this.message,
    required this.timestamp,
  });
  
  factory MatchResult.fromJson(Map<String, dynamic> json) => _$MatchResultFromJson(json);
  Map<String, dynamic> toJson() => _$MatchResultToJson(this);
  
  bool get isSuccess => matched;
  bool get hasQuotaIssue => quotaInfo.limitReached;
}

@JsonSerializable()
class QuotaInfo {
  final int swipeRemaining;
  final int messageRemaining;
  final bool limitReached;
  final String? limitType; // 'swipe' ou 'message'
  final DateTime? resetTime;
  
  const QuotaInfo({
    required this.swipeRemaining,
    required this.messageRemaining,
    this.limitReached = false,
    this.limitType,
    this.resetTime,
  });
  
  factory QuotaInfo.fromJson(Map<String, dynamic> json) => _$QuotaInfoFromJson(json);
  Map<String, dynamic> toJson() => _$QuotaInfoToJson(this);
  
  /// Pourcentage quota swipe utilisé
  double get swipeUsagePercent {
    const maxFree = 10; // Constante, peut venir de config
    const maxPremium = 100;
    
    // Estimation basée sur remaining (à ajuster selon backend)
    final estimated = maxFree - swipeRemaining;
    return (estimated / maxFree).clamp(0.0, 1.0);
  }
  
  /// Message quota pour UI
  String get quotaMessage {
    if (limitReached) {
      if (limitType == 'swipe') {
        return 'Limite de swipes atteinte. Plus que $swipeRemaining swipes.';
      } else if (limitType == 'message') {
        return 'Limite de messages atteinte. Plus que $messageRemaining messages.';
      }
      return 'Limite quotidienne atteinte.';
    }
    
    if (swipeRemaining <= 5) {
      return 'Plus que $swipeRemaining swipes aujourd\'hui.';
    }
    
    return '$swipeRemaining swipes restants.';
  }
  
  /// Temps avant reset
  String? get resetTimeDisplay {
    if (resetTime == null) return null;
    
    final now = DateTime.now();
    final diff = resetTime!.difference(now);
    
    if (diff.inHours > 0) {
      return 'Reset dans ${diff.inHours}h${diff.inMinutes % 60}min';
    } else if (diff.inMinutes > 0) {
      return 'Reset dans ${diff.inMinutes}min';
    }
    
    return 'Reset imminent';
  }
}

@JsonSerializable()
class SwipeFilters {
  final int? minAge;
  final int? maxAge;
  final int? maxDistance;
  final List<UserLevel>? levels;
  final List<RideStyle>? rideStyles;
  final List<String>? languages;
  final bool? premiumOnly;
  final bool? verifiedOnly;
  final bool? boostedOnly;
  
  const SwipeFilters({
    this.minAge,
    this.maxAge,
    this.maxDistance,
    this.levels,
    this.rideStyles,
    this.languages,
    this.premiumOnly,
    this.verifiedOnly,
    this.boostedOnly,
  });
  
  factory SwipeFilters.fromJson(Map<String, dynamic> json) => _$SwipeFiltersFromJson(json);
  Map<String, dynamic> toJson() => _$SwipeFiltersToJson(this);
  
  /// Filtres par défaut
  factory SwipeFilters.defaultFilters() {
    return const SwipeFilters(
      minAge: 18,
      maxAge: 65,
      maxDistance: 50,
      premiumOnly: false,
      verifiedOnly: false,
      boostedOnly: false,
    );
  }
  
  /// Copie avec modifications
  SwipeFilters copyWith({
    int? minAge,
    int? maxAge,
    int? maxDistance,
    List<UserLevel>? levels,
    List<RideStyle>? rideStyles,
    List<String>? languages,
    bool? premiumOnly,
    bool? verifiedOnly,
    bool? boostedOnly,
  }) {
    return SwipeFilters(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistance: maxDistance ?? this.maxDistance,
      levels: levels ?? this.levels,
      rideStyles: rideStyles ?? this.rideStyles,
      languages: languages ?? this.languages,
      premiumOnly: premiumOnly ?? this.premiumOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      boostedOnly: boostedOnly ?? this.boostedOnly,
    );
  }
  
  /// Convertir en paramètres pour Edge Function
  Map<String, dynamic> toApiParams() {
    final params = <String, dynamic>{};
    
    if (minAge != null) params['min_age'] = minAge;
    if (maxAge != null) params['max_age'] = maxAge;
    if (maxDistance != null) params['max_distance'] = maxDistance;
    if (levels != null) params['levels'] = levels!.map((e) => e.name).toList();
    if (rideStyles != null) params['ride_styles'] = rideStyles!.map((e) => e.name).toList();
    if (languages != null) params['languages'] = languages;
    if (premiumOnly == true) params['premium_only'] = true;
    if (verifiedOnly == true) params['verified_only'] = true;
    if (boostedOnly == true) params['boosted_only'] = true;
    
    return params;
  }
  
  /// Nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    
    if (minAge != null && minAge != 18) count++;
    if (maxAge != null && maxAge != 65) count++;
    if (maxDistance != null && maxDistance != 50) count++;
    if (levels?.isNotEmpty == true) count++;
    if (rideStyles?.isNotEmpty == true) count++;
    if (languages?.isNotEmpty == true) count++;
    if (premiumOnly == true) count++;
    if (verifiedOnly == true) count++;
    if (boostedOnly == true) count++;
    
    return count;
  }
}
