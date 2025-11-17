import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String username;
  final String email;
  final String? bio;
  final DateTime? birthDate;
  final int? age;
  final UserLevel level;
  final List<RideStyle> rideStyles;
  final List<String> languages;
  final List<String> objectives;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final String? mainPhotoUrl;
  final VerificationStatus verificationStatus;
  final bool isActive;
  final DateTime lastActiveAt;
  final DateTime createdAt;
  
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.bio,
    this.birthDate,
    this.age,
    required this.level,
    required this.rideStyles,
    required this.languages,
    required this.objectives,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.mainPhotoUrl,
    this.verificationStatus = VerificationStatus.notSubmitted,
    this.isActive = true,
    required this.lastActiveAt,
    required this.createdAt,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
  
  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? bio,
    DateTime? birthDate,
    int? age,
    UserLevel? level,
    List<RideStyle>? rideStyles,
    List<String>? languages,
    List<String>? objectives,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    String? mainPhotoUrl,
    VerificationStatus? verificationStatus,
    bool? isActive,
    DateTime? lastActiveAt,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      level: level ?? this.level,
      rideStyles: rideStyles ?? this.rideStyles,
      languages: languages ?? this.languages,
      objectives: objectives ?? this.objectives,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      mainPhotoUrl: mainPhotoUrl ?? this.mainPhotoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isActive: isActive ?? this.isActive,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum UserLevel {
  @JsonValue('beginner')
  beginner,
  @JsonValue('intermediate') 
  intermediate,
  @JsonValue('advanced')
  advanced,
  @JsonValue('expert')
  expert;
  
  String get displayName {
    switch (this) {
      case UserLevel.beginner:
        return 'Débutant';
      case UserLevel.intermediate:
        return 'Intermédiaire';
      case UserLevel.advanced:
        return 'Confirmé';
      case UserLevel.expert:
        return 'Expert';
    }
  }
}

enum RideStyle {
  @JsonValue('alpine')
  alpine,
  @JsonValue('freeride')
  freeride,
  @JsonValue('freestyle')
  freestyle,
  @JsonValue('park')
  park,
  @JsonValue('racing')
  racing,
  @JsonValue('touring')
  touring,
  @JsonValue('powder')
  powder,
  @JsonValue('moguls')
  moguls;
  
  String get displayName {
    switch (this) {
      case RideStyle.alpine:
        return 'Piste';
      case RideStyle.freeride:
        return 'Hors-piste';
      case RideStyle.freestyle:
        return 'Freestyle';
      case RideStyle.park:
        return 'Snowpark';
      case RideStyle.racing:
        return 'Course';
      case RideStyle.touring:
        return 'Rando';
      case RideStyle.powder:
        return 'Poudreuse';
      case RideStyle.moguls:
        return 'Bosses';
    }
  }
  
  IconData get icon {
    switch (this) {
      case RideStyle.alpine:
        return Icons.downhill_skiing;
      case RideStyle.freeride:
        return Icons.terrain;
      case RideStyle.freestyle:
        return Icons.sports_gymnastics;
      case RideStyle.park:
        return Icons.park;
      case RideStyle.racing:
        return Icons.speed;
      case RideStyle.touring:
        return Icons.hiking;
      case RideStyle.powder:
        return Icons.ac_unit;
      case RideStyle.moguls:
        return Icons.waves;
    }
  }
}

enum VerificationStatus {
  @JsonValue('not_submitted')
  notSubmitted,
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected;
  
  String get displayName {
    switch (this) {
      case VerificationStatus.notSubmitted:
        return 'Non soumis';
      case VerificationStatus.pending:
        return 'En cours';
      case VerificationStatus.approved:
        return 'Vérifié';
      case VerificationStatus.rejected:
        return 'Rejeté';
    }
  }
}
