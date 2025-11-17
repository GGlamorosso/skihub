// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      bio: json['bio'] as String?,
      birthDate: json['birthDate'] == null
          ? null
          : DateTime.parse(json['birthDate'] as String),
      age: (json['age'] as num?)?.toInt(),
      level: $enumDecode(_$UserLevelEnumMap, json['level']),
      rideStyles: (json['rideStyles'] as List<dynamic>)
          .map((e) => $enumDecode(_$RideStyleEnumMap, e))
          .toList(),
      languages:
          (json['languages'] as List<dynamic>).map((e) => e as String).toList(),
      objectives: (json['objectives'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isPremium: json['isPremium'] as bool? ?? false,
      premiumExpiresAt: json['premiumExpiresAt'] == null
          ? null
          : DateTime.parse(json['premiumExpiresAt'] as String),
      mainPhotoUrl: json['mainPhotoUrl'] as String?,
      verificationStatus: $enumDecodeNullable(
              _$VerificationStatusEnumMap, json['verificationStatus']) ??
          VerificationStatus.notSubmitted,
      isActive: json['isActive'] as bool? ?? true,
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'bio': instance.bio,
      'birthDate': instance.birthDate?.toIso8601String(),
      'age': instance.age,
      'level': _$UserLevelEnumMap[instance.level]!,
      'rideStyles':
          instance.rideStyles.map((e) => _$RideStyleEnumMap[e]!).toList(),
      'languages': instance.languages,
      'objectives': instance.objectives,
      'isPremium': instance.isPremium,
      'premiumExpiresAt': instance.premiumExpiresAt?.toIso8601String(),
      'mainPhotoUrl': instance.mainPhotoUrl,
      'verificationStatus':
          _$VerificationStatusEnumMap[instance.verificationStatus]!,
      'isActive': instance.isActive,
      'lastActiveAt': instance.lastActiveAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
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

const _$VerificationStatusEnumMap = {
  VerificationStatus.notSubmitted: 'not_submitted',
  VerificationStatus.pending: 'pending',
  VerificationStatus.approved: 'approved',
  VerificationStatus.rejected: 'rejected',
};
