// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Candidate _$CandidateFromJson(Map<String, dynamic> json) => Candidate(
      id: json['id'] as String,
      username: json['username'] as String,
      age: (json['age'] as num).toInt(),
      level: $enumDecode(_$UserLevelEnumMap, json['level']),
      isPremium: json['isPremium'] as bool? ?? false,
      score: (json['score'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      photoUrl: json['photoUrl'] as String?,
      rideStyles: (json['rideStyles'] as List<dynamic>)
          .map((e) => $enumDecode(_$RideStyleEnumMap, e))
          .toList(),
      languages:
          (json['languages'] as List<dynamic>).map((e) => e as String).toList(),
      stationName: json['stationName'] as String,
      availableFrom: DateTime.parse(json['availableFrom'] as String),
      availableTo: DateTime.parse(json['availableTo'] as String),
      boostMultiplier: (json['boostMultiplier'] as num?)?.toDouble() ?? 1.0,
      bio: json['bio'] as String?,
      maxSpeed: (json['maxSpeed'] as num?)?.toInt(),
      isVerified: json['isVerified'] as bool? ?? false,
    );

Map<String, dynamic> _$CandidateToJson(Candidate instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'age': instance.age,
      'level': _$UserLevelEnumMap[instance.level]!,
      'isPremium': instance.isPremium,
      'score': instance.score,
      'distanceKm': instance.distanceKm,
      'photoUrl': instance.photoUrl,
      'rideStyles':
          instance.rideStyles.map((e) => _$RideStyleEnumMap[e]!).toList(),
      'languages': instance.languages,
      'stationName': instance.stationName,
      'availableFrom': instance.availableFrom.toIso8601String(),
      'availableTo': instance.availableTo.toIso8601String(),
      'boostMultiplier': instance.boostMultiplier,
      'bio': instance.bio,
      'maxSpeed': instance.maxSpeed,
      'isVerified': instance.isVerified,
    };

const _$UserLevelEnumMap = {
  UserLevel.beginner: 'beginner',
  UserLevel.intermediate: 'intermediate',
  UserLevel.advanced: 'advanced',
  UserLevel.expert: 'expert',
};

const _$RideStyleEnumMap = {
  RideStyle.alpine: 'alpine',
  RideStyle.freeride: 'freeride',
  RideStyle.freestyle: 'freestyle',
  RideStyle.park: 'park',
  RideStyle.racing: 'racing',
  RideStyle.touring: 'touring',
  RideStyle.powder: 'powder',
  RideStyle.moguls: 'moguls',
};

MatchResult _$MatchResultFromJson(Map<String, dynamic> json) => MatchResult(
      matched: json['matched'] as bool,
      matchId: json['matchId'] as String?,
      quotaInfo: QuotaInfo.fromJson(json['quotaInfo'] as Map<String, dynamic>),
      message: json['message'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$MatchResultToJson(MatchResult instance) =>
    <String, dynamic>{
      'matched': instance.matched,
      'matchId': instance.matchId,
      'quotaInfo': instance.quotaInfo,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
    };

QuotaInfo _$QuotaInfoFromJson(Map<String, dynamic> json) => QuotaInfo(
      swipeRemaining: (json['swipeRemaining'] as num).toInt(),
      messageRemaining: (json['messageRemaining'] as num).toInt(),
      limitReached: json['limitReached'] as bool? ?? false,
      limitType: json['limitType'] as String?,
      resetTime: json['resetTime'] == null
          ? null
          : DateTime.parse(json['resetTime'] as String),
    );

Map<String, dynamic> _$QuotaInfoToJson(QuotaInfo instance) => <String, dynamic>{
      'swipeRemaining': instance.swipeRemaining,
      'messageRemaining': instance.messageRemaining,
      'limitReached': instance.limitReached,
      'limitType': instance.limitType,
      'resetTime': instance.resetTime?.toIso8601String(),
    };

SwipeFilters _$SwipeFiltersFromJson(Map<String, dynamic> json) => SwipeFilters(
      minAge: (json['minAge'] as num?)?.toInt(),
      maxAge: (json['maxAge'] as num?)?.toInt(),
      maxDistance: (json['maxDistance'] as num?)?.toInt(),
      levels: (json['levels'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$UserLevelEnumMap, e))
          .toList(),
      rideStyles: (json['rideStyles'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$RideStyleEnumMap, e))
          .toList(),
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      premiumOnly: json['premiumOnly'] as bool?,
      verifiedOnly: json['verifiedOnly'] as bool?,
      boostedOnly: json['boostedOnly'] as bool?,
    );

Map<String, dynamic> _$SwipeFiltersToJson(SwipeFilters instance) =>
    <String, dynamic>{
      'minAge': instance.minAge,
      'maxAge': instance.maxAge,
      'maxDistance': instance.maxDistance,
      'levels': instance.levels?.map((e) => _$UserLevelEnumMap[e]!).toList(),
      'rideStyles':
          instance.rideStyles?.map((e) => _$RideStyleEnumMap[e]!).toList(),
      'languages': instance.languages,
      'premiumOnly': instance.premiumOnly,
      'verifiedOnly': instance.verifiedOnly,
      'boostedOnly': instance.boostedOnly,
    };
