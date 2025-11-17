// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'consent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Consent _$ConsentFromJson(Map<String, dynamic> json) {
  return _Consent.fromJson(json);
}

/// @nodoc
mixin _$Consent {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get purpose => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  bool get granted => throw _privateConstructorUsedError;
  DateTime? get grantedAt => throw _privateConstructorUsedError;
  DateTime? get revokedAt => throw _privateConstructorUsedError;
  String? get ipAddress => throw _privateConstructorUsedError;
  String? get userAgent => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ConsentCopyWith<Consent> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConsentCopyWith<$Res> {
  factory $ConsentCopyWith(Consent value, $Res Function(Consent) then) =
      _$ConsentCopyWithImpl<$Res, Consent>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String purpose,
      int version,
      bool granted,
      DateTime? grantedAt,
      DateTime? revokedAt,
      String? ipAddress,
      String? userAgent,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$ConsentCopyWithImpl<$Res, $Val extends Consent>
    implements $ConsentCopyWith<$Res> {
  _$ConsentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? purpose = null,
    Object? version = null,
    Object? granted = null,
    Object? grantedAt = freezed,
    Object? revokedAt = freezed,
    Object? ipAddress = freezed,
    Object? userAgent = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      purpose: null == purpose
          ? _value.purpose
          : purpose // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      granted: null == granted
          ? _value.granted
          : granted // ignore: cast_nullable_to_non_nullable
              as bool,
      grantedAt: freezed == grantedAt
          ? _value.grantedAt
          : grantedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      revokedAt: freezed == revokedAt
          ? _value.revokedAt
          : revokedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      ipAddress: freezed == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      userAgent: freezed == userAgent
          ? _value.userAgent
          : userAgent // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConsentImplCopyWith<$Res> implements $ConsentCopyWith<$Res> {
  factory _$$ConsentImplCopyWith(
          _$ConsentImpl value, $Res Function(_$ConsentImpl) then) =
      __$$ConsentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String purpose,
      int version,
      bool granted,
      DateTime? grantedAt,
      DateTime? revokedAt,
      String? ipAddress,
      String? userAgent,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$ConsentImplCopyWithImpl<$Res>
    extends _$ConsentCopyWithImpl<$Res, _$ConsentImpl>
    implements _$$ConsentImplCopyWith<$Res> {
  __$$ConsentImplCopyWithImpl(
      _$ConsentImpl _value, $Res Function(_$ConsentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? purpose = null,
    Object? version = null,
    Object? granted = null,
    Object? grantedAt = freezed,
    Object? revokedAt = freezed,
    Object? ipAddress = freezed,
    Object? userAgent = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ConsentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      purpose: null == purpose
          ? _value.purpose
          : purpose // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      granted: null == granted
          ? _value.granted
          : granted // ignore: cast_nullable_to_non_nullable
              as bool,
      grantedAt: freezed == grantedAt
          ? _value.grantedAt
          : grantedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      revokedAt: freezed == revokedAt
          ? _value.revokedAt
          : revokedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      ipAddress: freezed == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      userAgent: freezed == userAgent
          ? _value.userAgent
          : userAgent // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConsentImpl extends _Consent {
  const _$ConsentImpl(
      {required this.id,
      required this.userId,
      required this.purpose,
      required this.version,
      required this.granted,
      this.grantedAt,
      this.revokedAt,
      this.ipAddress,
      this.userAgent,
      required this.createdAt,
      required this.updatedAt})
      : super._();

  factory _$ConsentImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConsentImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String purpose;
  @override
  final int version;
  @override
  final bool granted;
  @override
  final DateTime? grantedAt;
  @override
  final DateTime? revokedAt;
  @override
  final String? ipAddress;
  @override
  final String? userAgent;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Consent(id: $id, userId: $userId, purpose: $purpose, version: $version, granted: $granted, grantedAt: $grantedAt, revokedAt: $revokedAt, ipAddress: $ipAddress, userAgent: $userAgent, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConsentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.purpose, purpose) || other.purpose == purpose) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.granted, granted) || other.granted == granted) &&
            (identical(other.grantedAt, grantedAt) ||
                other.grantedAt == grantedAt) &&
            (identical(other.revokedAt, revokedAt) ||
                other.revokedAt == revokedAt) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.userAgent, userAgent) ||
                other.userAgent == userAgent) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      purpose,
      version,
      granted,
      grantedAt,
      revokedAt,
      ipAddress,
      userAgent,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ConsentImplCopyWith<_$ConsentImpl> get copyWith =>
      __$$ConsentImplCopyWithImpl<_$ConsentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConsentImplToJson(
      this,
    );
  }
}

abstract class _Consent extends Consent {
  const factory _Consent(
      {required final String id,
      required final String userId,
      required final String purpose,
      required final int version,
      required final bool granted,
      final DateTime? grantedAt,
      final DateTime? revokedAt,
      final String? ipAddress,
      final String? userAgent,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$ConsentImpl;
  const _Consent._() : super._();

  factory _Consent.fromJson(Map<String, dynamic> json) = _$ConsentImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get purpose;
  @override
  int get version;
  @override
  bool get granted;
  @override
  DateTime? get grantedAt;
  @override
  DateTime? get revokedAt;
  @override
  String? get ipAddress;
  @override
  String? get userAgent;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ConsentImplCopyWith<_$ConsentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PrivacySettings _$PrivacySettingsFromJson(Map<String, dynamic> json) {
  return _PrivacySettings.fromJson(json);
}

/// @nodoc
mixin _$PrivacySettings {
  bool get isInvisible => throw _privateConstructorUsedError;
  bool get hideAge => throw _privateConstructorUsedError;
  bool get hideLevel => throw _privateConstructorUsedError;
  bool get hideStats => throw _privateConstructorUsedError;
  bool get hideLastActive => throw _privateConstructorUsedError;
  bool get notificationsPush => throw _privateConstructorUsedError;
  bool get notificationsEmail => throw _privateConstructorUsedError;
  bool get notificationsMarketing => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PrivacySettingsCopyWith<PrivacySettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrivacySettingsCopyWith<$Res> {
  factory $PrivacySettingsCopyWith(
          PrivacySettings value, $Res Function(PrivacySettings) then) =
      _$PrivacySettingsCopyWithImpl<$Res, PrivacySettings>;
  @useResult
  $Res call(
      {bool isInvisible,
      bool hideAge,
      bool hideLevel,
      bool hideStats,
      bool hideLastActive,
      bool notificationsPush,
      bool notificationsEmail,
      bool notificationsMarketing});
}

/// @nodoc
class _$PrivacySettingsCopyWithImpl<$Res, $Val extends PrivacySettings>
    implements $PrivacySettingsCopyWith<$Res> {
  _$PrivacySettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInvisible = null,
    Object? hideAge = null,
    Object? hideLevel = null,
    Object? hideStats = null,
    Object? hideLastActive = null,
    Object? notificationsPush = null,
    Object? notificationsEmail = null,
    Object? notificationsMarketing = null,
  }) {
    return _then(_value.copyWith(
      isInvisible: null == isInvisible
          ? _value.isInvisible
          : isInvisible // ignore: cast_nullable_to_non_nullable
              as bool,
      hideAge: null == hideAge
          ? _value.hideAge
          : hideAge // ignore: cast_nullable_to_non_nullable
              as bool,
      hideLevel: null == hideLevel
          ? _value.hideLevel
          : hideLevel // ignore: cast_nullable_to_non_nullable
              as bool,
      hideStats: null == hideStats
          ? _value.hideStats
          : hideStats // ignore: cast_nullable_to_non_nullable
              as bool,
      hideLastActive: null == hideLastActive
          ? _value.hideLastActive
          : hideLastActive // ignore: cast_nullable_to_non_nullable
              as bool,
      notificationsPush: null == notificationsPush
          ? _value.notificationsPush
          : notificationsPush // ignore: cast_nullable_to_non_nullable
              as bool,
      notificationsEmail: null == notificationsEmail
          ? _value.notificationsEmail
          : notificationsEmail // ignore: cast_nullable_to_non_nullable
              as bool,
      notificationsMarketing: null == notificationsMarketing
          ? _value.notificationsMarketing
          : notificationsMarketing // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PrivacySettingsImplCopyWith<$Res>
    implements $PrivacySettingsCopyWith<$Res> {
  factory _$$PrivacySettingsImplCopyWith(_$PrivacySettingsImpl value,
          $Res Function(_$PrivacySettingsImpl) then) =
      __$$PrivacySettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isInvisible,
      bool hideAge,
      bool hideLevel,
      bool hideStats,
      bool hideLastActive,
      bool notificationsPush,
      bool notificationsEmail,
      bool notificationsMarketing});
}

/// @nodoc
class __$$PrivacySettingsImplCopyWithImpl<$Res>
    extends _$PrivacySettingsCopyWithImpl<$Res, _$PrivacySettingsImpl>
    implements _$$PrivacySettingsImplCopyWith<$Res> {
  __$$PrivacySettingsImplCopyWithImpl(
      _$PrivacySettingsImpl _value, $Res Function(_$PrivacySettingsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInvisible = null,
    Object? hideAge = null,
    Object? hideLevel = null,
    Object? hideStats = null,
    Object? hideLastActive = null,
    Object? notificationsPush = null,
    Object? notificationsEmail = null,
    Object? notificationsMarketing = null,
  }) {
    return _then(_$PrivacySettingsImpl(
      isInvisible: null == isInvisible
          ? _value.isInvisible
          : isInvisible // ignore: cast_nullable_to_non_nullable
              as bool,
      hideAge: null == hideAge
          ? _value.hideAge
          : hideAge // ignore: cast_nullable_to_non_nullable
              as bool,
      hideLevel: null == hideLevel
          ? _value.hideLevel
          : hideLevel // ignore: cast_nullable_to_non_nullable
              as bool,
      hideStats: null == hideStats
          ? _value.hideStats
          : hideStats // ignore: cast_nullable_to_non_nullable
              as bool,
      hideLastActive: null == hideLastActive
          ? _value.hideLastActive
          : hideLastActive // ignore: cast_nullable_to_non_nullable
              as bool,
      notificationsPush: null == notificationsPush
          ? _value.notificationsPush
          : notificationsPush // ignore: cast_nullable_to_non_nullable
              as bool,
      notificationsEmail: null == notificationsEmail
          ? _value.notificationsEmail
          : notificationsEmail // ignore: cast_nullable_to_non_nullable
              as bool,
      notificationsMarketing: null == notificationsMarketing
          ? _value.notificationsMarketing
          : notificationsMarketing // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PrivacySettingsImpl extends _PrivacySettings {
  const _$PrivacySettingsImpl(
      {required this.isInvisible,
      required this.hideAge,
      required this.hideLevel,
      required this.hideStats,
      required this.hideLastActive,
      required this.notificationsPush,
      required this.notificationsEmail,
      required this.notificationsMarketing})
      : super._();

  factory _$PrivacySettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrivacySettingsImplFromJson(json);

  @override
  final bool isInvisible;
  @override
  final bool hideAge;
  @override
  final bool hideLevel;
  @override
  final bool hideStats;
  @override
  final bool hideLastActive;
  @override
  final bool notificationsPush;
  @override
  final bool notificationsEmail;
  @override
  final bool notificationsMarketing;

  @override
  String toString() {
    return 'PrivacySettings(isInvisible: $isInvisible, hideAge: $hideAge, hideLevel: $hideLevel, hideStats: $hideStats, hideLastActive: $hideLastActive, notificationsPush: $notificationsPush, notificationsEmail: $notificationsEmail, notificationsMarketing: $notificationsMarketing)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrivacySettingsImpl &&
            (identical(other.isInvisible, isInvisible) ||
                other.isInvisible == isInvisible) &&
            (identical(other.hideAge, hideAge) || other.hideAge == hideAge) &&
            (identical(other.hideLevel, hideLevel) ||
                other.hideLevel == hideLevel) &&
            (identical(other.hideStats, hideStats) ||
                other.hideStats == hideStats) &&
            (identical(other.hideLastActive, hideLastActive) ||
                other.hideLastActive == hideLastActive) &&
            (identical(other.notificationsPush, notificationsPush) ||
                other.notificationsPush == notificationsPush) &&
            (identical(other.notificationsEmail, notificationsEmail) ||
                other.notificationsEmail == notificationsEmail) &&
            (identical(other.notificationsMarketing, notificationsMarketing) ||
                other.notificationsMarketing == notificationsMarketing));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      isInvisible,
      hideAge,
      hideLevel,
      hideStats,
      hideLastActive,
      notificationsPush,
      notificationsEmail,
      notificationsMarketing);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PrivacySettingsImplCopyWith<_$PrivacySettingsImpl> get copyWith =>
      __$$PrivacySettingsImplCopyWithImpl<_$PrivacySettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PrivacySettingsImplToJson(
      this,
    );
  }
}

abstract class _PrivacySettings extends PrivacySettings {
  const factory _PrivacySettings(
      {required final bool isInvisible,
      required final bool hideAge,
      required final bool hideLevel,
      required final bool hideStats,
      required final bool hideLastActive,
      required final bool notificationsPush,
      required final bool notificationsEmail,
      required final bool notificationsMarketing}) = _$PrivacySettingsImpl;
  const _PrivacySettings._() : super._();

  factory _PrivacySettings.fromJson(Map<String, dynamic> json) =
      _$PrivacySettingsImpl.fromJson;

  @override
  bool get isInvisible;
  @override
  bool get hideAge;
  @override
  bool get hideLevel;
  @override
  bool get hideStats;
  @override
  bool get hideLastActive;
  @override
  bool get notificationsPush;
  @override
  bool get notificationsEmail;
  @override
  bool get notificationsMarketing;
  @override
  @JsonKey(ignore: true)
  _$$PrivacySettingsImplCopyWith<_$PrivacySettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VerificationRequest _$VerificationRequestFromJson(Map<String, dynamic> json) {
  return _VerificationRequest.fromJson(json);
}

/// @nodoc
mixin _$VerificationRequest {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get videoStoragePath => throw _privateConstructorUsedError;
  int? get videoDurationSeconds => throw _privateConstructorUsedError;
  int? get videoSizeBytes => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get submittedAt => throw _privateConstructorUsedError;
  DateTime? get reviewedAt => throw _privateConstructorUsedError;
  String? get reviewerId => throw _privateConstructorUsedError;
  String? get rejectionReason => throw _privateConstructorUsedError;
  double? get verificationScore => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VerificationRequestCopyWith<VerificationRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VerificationRequestCopyWith<$Res> {
  factory $VerificationRequestCopyWith(
          VerificationRequest value, $Res Function(VerificationRequest) then) =
      _$VerificationRequestCopyWithImpl<$Res, VerificationRequest>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String videoStoragePath,
      int? videoDurationSeconds,
      int? videoSizeBytes,
      String status,
      DateTime submittedAt,
      DateTime? reviewedAt,
      String? reviewerId,
      String? rejectionReason,
      double? verificationScore,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$VerificationRequestCopyWithImpl<$Res, $Val extends VerificationRequest>
    implements $VerificationRequestCopyWith<$Res> {
  _$VerificationRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? videoStoragePath = null,
    Object? videoDurationSeconds = freezed,
    Object? videoSizeBytes = freezed,
    Object? status = null,
    Object? submittedAt = null,
    Object? reviewedAt = freezed,
    Object? reviewerId = freezed,
    Object? rejectionReason = freezed,
    Object? verificationScore = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      videoStoragePath: null == videoStoragePath
          ? _value.videoStoragePath
          : videoStoragePath // ignore: cast_nullable_to_non_nullable
              as String,
      videoDurationSeconds: freezed == videoDurationSeconds
          ? _value.videoDurationSeconds
          : videoDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      videoSizeBytes: freezed == videoSizeBytes
          ? _value.videoSizeBytes
          : videoSizeBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      submittedAt: null == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reviewedAt: freezed == reviewedAt
          ? _value.reviewedAt
          : reviewedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reviewerId: freezed == reviewerId
          ? _value.reviewerId
          : reviewerId // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectionReason: freezed == rejectionReason
          ? _value.rejectionReason
          : rejectionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      verificationScore: freezed == verificationScore
          ? _value.verificationScore
          : verificationScore // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VerificationRequestImplCopyWith<$Res>
    implements $VerificationRequestCopyWith<$Res> {
  factory _$$VerificationRequestImplCopyWith(_$VerificationRequestImpl value,
          $Res Function(_$VerificationRequestImpl) then) =
      __$$VerificationRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String videoStoragePath,
      int? videoDurationSeconds,
      int? videoSizeBytes,
      String status,
      DateTime submittedAt,
      DateTime? reviewedAt,
      String? reviewerId,
      String? rejectionReason,
      double? verificationScore,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$VerificationRequestImplCopyWithImpl<$Res>
    extends _$VerificationRequestCopyWithImpl<$Res, _$VerificationRequestImpl>
    implements _$$VerificationRequestImplCopyWith<$Res> {
  __$$VerificationRequestImplCopyWithImpl(_$VerificationRequestImpl _value,
      $Res Function(_$VerificationRequestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? videoStoragePath = null,
    Object? videoDurationSeconds = freezed,
    Object? videoSizeBytes = freezed,
    Object? status = null,
    Object? submittedAt = null,
    Object? reviewedAt = freezed,
    Object? reviewerId = freezed,
    Object? rejectionReason = freezed,
    Object? verificationScore = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$VerificationRequestImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      videoStoragePath: null == videoStoragePath
          ? _value.videoStoragePath
          : videoStoragePath // ignore: cast_nullable_to_non_nullable
              as String,
      videoDurationSeconds: freezed == videoDurationSeconds
          ? _value.videoDurationSeconds
          : videoDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      videoSizeBytes: freezed == videoSizeBytes
          ? _value.videoSizeBytes
          : videoSizeBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      submittedAt: null == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reviewedAt: freezed == reviewedAt
          ? _value.reviewedAt
          : reviewedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reviewerId: freezed == reviewerId
          ? _value.reviewerId
          : reviewerId // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectionReason: freezed == rejectionReason
          ? _value.rejectionReason
          : rejectionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      verificationScore: freezed == verificationScore
          ? _value.verificationScore
          : verificationScore // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VerificationRequestImpl extends _VerificationRequest {
  const _$VerificationRequestImpl(
      {required this.id,
      required this.userId,
      required this.videoStoragePath,
      this.videoDurationSeconds,
      this.videoSizeBytes,
      required this.status,
      required this.submittedAt,
      this.reviewedAt,
      this.reviewerId,
      this.rejectionReason,
      this.verificationScore,
      required this.createdAt,
      required this.updatedAt})
      : super._();

  factory _$VerificationRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$VerificationRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String videoStoragePath;
  @override
  final int? videoDurationSeconds;
  @override
  final int? videoSizeBytes;
  @override
  final String status;
  @override
  final DateTime submittedAt;
  @override
  final DateTime? reviewedAt;
  @override
  final String? reviewerId;
  @override
  final String? rejectionReason;
  @override
  final double? verificationScore;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'VerificationRequest(id: $id, userId: $userId, videoStoragePath: $videoStoragePath, videoDurationSeconds: $videoDurationSeconds, videoSizeBytes: $videoSizeBytes, status: $status, submittedAt: $submittedAt, reviewedAt: $reviewedAt, reviewerId: $reviewerId, rejectionReason: $rejectionReason, verificationScore: $verificationScore, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerificationRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.videoStoragePath, videoStoragePath) ||
                other.videoStoragePath == videoStoragePath) &&
            (identical(other.videoDurationSeconds, videoDurationSeconds) ||
                other.videoDurationSeconds == videoDurationSeconds) &&
            (identical(other.videoSizeBytes, videoSizeBytes) ||
                other.videoSizeBytes == videoSizeBytes) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt) &&
            (identical(other.reviewerId, reviewerId) ||
                other.reviewerId == reviewerId) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason) &&
            (identical(other.verificationScore, verificationScore) ||
                other.verificationScore == verificationScore) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      videoStoragePath,
      videoDurationSeconds,
      videoSizeBytes,
      status,
      submittedAt,
      reviewedAt,
      reviewerId,
      rejectionReason,
      verificationScore,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VerificationRequestImplCopyWith<_$VerificationRequestImpl> get copyWith =>
      __$$VerificationRequestImplCopyWithImpl<_$VerificationRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VerificationRequestImplToJson(
      this,
    );
  }
}

abstract class _VerificationRequest extends VerificationRequest {
  const factory _VerificationRequest(
      {required final String id,
      required final String userId,
      required final String videoStoragePath,
      final int? videoDurationSeconds,
      final int? videoSizeBytes,
      required final String status,
      required final DateTime submittedAt,
      final DateTime? reviewedAt,
      final String? reviewerId,
      final String? rejectionReason,
      final double? verificationScore,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$VerificationRequestImpl;
  const _VerificationRequest._() : super._();

  factory _VerificationRequest.fromJson(Map<String, dynamic> json) =
      _$VerificationRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get videoStoragePath;
  @override
  int? get videoDurationSeconds;
  @override
  int? get videoSizeBytes;
  @override
  String get status;
  @override
  DateTime get submittedAt;
  @override
  DateTime? get reviewedAt;
  @override
  String? get reviewerId;
  @override
  String? get rejectionReason;
  @override
  double? get verificationScore;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$VerificationRequestImplCopyWith<_$VerificationRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AIInteraction _$AIInteractionFromJson(Map<String, dynamic> json) {
  return _AIInteraction.fromJson(json);
}

/// @nodoc
mixin _$AIInteraction {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get matchId => throw _privateConstructorUsedError;
  String get interactionType => throw _privateConstructorUsedError;
  String? get promptUsed => throw _privateConstructorUsedError;
  String? get aiResponse => throw _privateConstructorUsedError;
  bool get wasUsed => throw _privateConstructorUsedError;
  DateTime? get usedAt => throw _privateConstructorUsedError;
  int? get userRating => throw _privateConstructorUsedError;
  String? get feedbackText => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AIInteractionCopyWith<AIInteraction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AIInteractionCopyWith<$Res> {
  factory $AIInteractionCopyWith(
          AIInteraction value, $Res Function(AIInteraction) then) =
      _$AIInteractionCopyWithImpl<$Res, AIInteraction>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String? matchId,
      String interactionType,
      String? promptUsed,
      String? aiResponse,
      bool wasUsed,
      DateTime? usedAt,
      int? userRating,
      String? feedbackText,
      DateTime createdAt});
}

/// @nodoc
class _$AIInteractionCopyWithImpl<$Res, $Val extends AIInteraction>
    implements $AIInteractionCopyWith<$Res> {
  _$AIInteractionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? matchId = freezed,
    Object? interactionType = null,
    Object? promptUsed = freezed,
    Object? aiResponse = freezed,
    Object? wasUsed = null,
    Object? usedAt = freezed,
    Object? userRating = freezed,
    Object? feedbackText = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      matchId: freezed == matchId
          ? _value.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String?,
      interactionType: null == interactionType
          ? _value.interactionType
          : interactionType // ignore: cast_nullable_to_non_nullable
              as String,
      promptUsed: freezed == promptUsed
          ? _value.promptUsed
          : promptUsed // ignore: cast_nullable_to_non_nullable
              as String?,
      aiResponse: freezed == aiResponse
          ? _value.aiResponse
          : aiResponse // ignore: cast_nullable_to_non_nullable
              as String?,
      wasUsed: null == wasUsed
          ? _value.wasUsed
          : wasUsed // ignore: cast_nullable_to_non_nullable
              as bool,
      usedAt: freezed == usedAt
          ? _value.usedAt
          : usedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      userRating: freezed == userRating
          ? _value.userRating
          : userRating // ignore: cast_nullable_to_non_nullable
              as int?,
      feedbackText: freezed == feedbackText
          ? _value.feedbackText
          : feedbackText // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AIInteractionImplCopyWith<$Res>
    implements $AIInteractionCopyWith<$Res> {
  factory _$$AIInteractionImplCopyWith(
          _$AIInteractionImpl value, $Res Function(_$AIInteractionImpl) then) =
      __$$AIInteractionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String? matchId,
      String interactionType,
      String? promptUsed,
      String? aiResponse,
      bool wasUsed,
      DateTime? usedAt,
      int? userRating,
      String? feedbackText,
      DateTime createdAt});
}

/// @nodoc
class __$$AIInteractionImplCopyWithImpl<$Res>
    extends _$AIInteractionCopyWithImpl<$Res, _$AIInteractionImpl>
    implements _$$AIInteractionImplCopyWith<$Res> {
  __$$AIInteractionImplCopyWithImpl(
      _$AIInteractionImpl _value, $Res Function(_$AIInteractionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? matchId = freezed,
    Object? interactionType = null,
    Object? promptUsed = freezed,
    Object? aiResponse = freezed,
    Object? wasUsed = null,
    Object? usedAt = freezed,
    Object? userRating = freezed,
    Object? feedbackText = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$AIInteractionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      matchId: freezed == matchId
          ? _value.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String?,
      interactionType: null == interactionType
          ? _value.interactionType
          : interactionType // ignore: cast_nullable_to_non_nullable
              as String,
      promptUsed: freezed == promptUsed
          ? _value.promptUsed
          : promptUsed // ignore: cast_nullable_to_non_nullable
              as String?,
      aiResponse: freezed == aiResponse
          ? _value.aiResponse
          : aiResponse // ignore: cast_nullable_to_non_nullable
              as String?,
      wasUsed: null == wasUsed
          ? _value.wasUsed
          : wasUsed // ignore: cast_nullable_to_non_nullable
              as bool,
      usedAt: freezed == usedAt
          ? _value.usedAt
          : usedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      userRating: freezed == userRating
          ? _value.userRating
          : userRating // ignore: cast_nullable_to_non_nullable
              as int?,
      feedbackText: freezed == feedbackText
          ? _value.feedbackText
          : feedbackText // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AIInteractionImpl extends _AIInteraction {
  const _$AIInteractionImpl(
      {required this.id,
      required this.userId,
      this.matchId,
      required this.interactionType,
      this.promptUsed,
      this.aiResponse,
      required this.wasUsed,
      this.usedAt,
      this.userRating,
      this.feedbackText,
      required this.createdAt})
      : super._();

  factory _$AIInteractionImpl.fromJson(Map<String, dynamic> json) =>
      _$$AIInteractionImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String? matchId;
  @override
  final String interactionType;
  @override
  final String? promptUsed;
  @override
  final String? aiResponse;
  @override
  final bool wasUsed;
  @override
  final DateTime? usedAt;
  @override
  final int? userRating;
  @override
  final String? feedbackText;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'AIInteraction(id: $id, userId: $userId, matchId: $matchId, interactionType: $interactionType, promptUsed: $promptUsed, aiResponse: $aiResponse, wasUsed: $wasUsed, usedAt: $usedAt, userRating: $userRating, feedbackText: $feedbackText, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AIInteractionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.matchId, matchId) || other.matchId == matchId) &&
            (identical(other.interactionType, interactionType) ||
                other.interactionType == interactionType) &&
            (identical(other.promptUsed, promptUsed) ||
                other.promptUsed == promptUsed) &&
            (identical(other.aiResponse, aiResponse) ||
                other.aiResponse == aiResponse) &&
            (identical(other.wasUsed, wasUsed) || other.wasUsed == wasUsed) &&
            (identical(other.usedAt, usedAt) || other.usedAt == usedAt) &&
            (identical(other.userRating, userRating) ||
                other.userRating == userRating) &&
            (identical(other.feedbackText, feedbackText) ||
                other.feedbackText == feedbackText) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      matchId,
      interactionType,
      promptUsed,
      aiResponse,
      wasUsed,
      usedAt,
      userRating,
      feedbackText,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AIInteractionImplCopyWith<_$AIInteractionImpl> get copyWith =>
      __$$AIInteractionImplCopyWithImpl<_$AIInteractionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AIInteractionImplToJson(
      this,
    );
  }
}

abstract class _AIInteraction extends AIInteraction {
  const factory _AIInteraction(
      {required final String id,
      required final String userId,
      final String? matchId,
      required final String interactionType,
      final String? promptUsed,
      final String? aiResponse,
      required final bool wasUsed,
      final DateTime? usedAt,
      final int? userRating,
      final String? feedbackText,
      required final DateTime createdAt}) = _$AIInteractionImpl;
  const _AIInteraction._() : super._();

  factory _AIInteraction.fromJson(Map<String, dynamic> json) =
      _$AIInteractionImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String? get matchId;
  @override
  String get interactionType;
  @override
  String? get promptUsed;
  @override
  String? get aiResponse;
  @override
  bool get wasUsed;
  @override
  DateTime? get usedAt;
  @override
  int? get userRating;
  @override
  String? get feedbackText;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$AIInteractionImplCopyWith<_$AIInteractionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
