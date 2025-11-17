// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) {
  return _Subscription.fromJson(json);
}

/// @nodoc
mixin _$Subscription {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get stripeSubscriptionId => throw _privateConstructorUsedError;
  String get stripeCustomerId => throw _privateConstructorUsedError;
  String get stripePriceId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get currentPeriodStart => throw _privateConstructorUsedError;
  DateTime get currentPeriodEnd => throw _privateConstructorUsedError;
  bool get cancelAtPeriodEnd => throw _privateConstructorUsedError;
  DateTime? get canceledAt => throw _privateConstructorUsedError;
  int get amountCents => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String get interval => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SubscriptionCopyWith<Subscription> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionCopyWith<$Res> {
  factory $SubscriptionCopyWith(
          Subscription value, $Res Function(Subscription) then) =
      _$SubscriptionCopyWithImpl<$Res, Subscription>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String stripeSubscriptionId,
      String stripeCustomerId,
      String stripePriceId,
      String status,
      DateTime currentPeriodStart,
      DateTime currentPeriodEnd,
      bool cancelAtPeriodEnd,
      DateTime? canceledAt,
      int amountCents,
      String currency,
      String interval,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$SubscriptionCopyWithImpl<$Res, $Val extends Subscription>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? stripeSubscriptionId = null,
    Object? stripeCustomerId = null,
    Object? stripePriceId = null,
    Object? status = null,
    Object? currentPeriodStart = null,
    Object? currentPeriodEnd = null,
    Object? cancelAtPeriodEnd = null,
    Object? canceledAt = freezed,
    Object? amountCents = null,
    Object? currency = null,
    Object? interval = null,
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
      stripeSubscriptionId: null == stripeSubscriptionId
          ? _value.stripeSubscriptionId
          : stripeSubscriptionId // ignore: cast_nullable_to_non_nullable
              as String,
      stripeCustomerId: null == stripeCustomerId
          ? _value.stripeCustomerId
          : stripeCustomerId // ignore: cast_nullable_to_non_nullable
              as String,
      stripePriceId: null == stripePriceId
          ? _value.stripePriceId
          : stripePriceId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      currentPeriodStart: null == currentPeriodStart
          ? _value.currentPeriodStart
          : currentPeriodStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      currentPeriodEnd: null == currentPeriodEnd
          ? _value.currentPeriodEnd
          : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cancelAtPeriodEnd: null == cancelAtPeriodEnd
          ? _value.cancelAtPeriodEnd
          : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
              as bool,
      canceledAt: freezed == canceledAt
          ? _value.canceledAt
          : canceledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      amountCents: null == amountCents
          ? _value.amountCents
          : amountCents // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      interval: null == interval
          ? _value.interval
          : interval // ignore: cast_nullable_to_non_nullable
              as String,
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
abstract class _$$SubscriptionImplCopyWith<$Res>
    implements $SubscriptionCopyWith<$Res> {
  factory _$$SubscriptionImplCopyWith(
          _$SubscriptionImpl value, $Res Function(_$SubscriptionImpl) then) =
      __$$SubscriptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String stripeSubscriptionId,
      String stripeCustomerId,
      String stripePriceId,
      String status,
      DateTime currentPeriodStart,
      DateTime currentPeriodEnd,
      bool cancelAtPeriodEnd,
      DateTime? canceledAt,
      int amountCents,
      String currency,
      String interval,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$SubscriptionImplCopyWithImpl<$Res>
    extends _$SubscriptionCopyWithImpl<$Res, _$SubscriptionImpl>
    implements _$$SubscriptionImplCopyWith<$Res> {
  __$$SubscriptionImplCopyWithImpl(
      _$SubscriptionImpl _value, $Res Function(_$SubscriptionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? stripeSubscriptionId = null,
    Object? stripeCustomerId = null,
    Object? stripePriceId = null,
    Object? status = null,
    Object? currentPeriodStart = null,
    Object? currentPeriodEnd = null,
    Object? cancelAtPeriodEnd = null,
    Object? canceledAt = freezed,
    Object? amountCents = null,
    Object? currency = null,
    Object? interval = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$SubscriptionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      stripeSubscriptionId: null == stripeSubscriptionId
          ? _value.stripeSubscriptionId
          : stripeSubscriptionId // ignore: cast_nullable_to_non_nullable
              as String,
      stripeCustomerId: null == stripeCustomerId
          ? _value.stripeCustomerId
          : stripeCustomerId // ignore: cast_nullable_to_non_nullable
              as String,
      stripePriceId: null == stripePriceId
          ? _value.stripePriceId
          : stripePriceId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      currentPeriodStart: null == currentPeriodStart
          ? _value.currentPeriodStart
          : currentPeriodStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      currentPeriodEnd: null == currentPeriodEnd
          ? _value.currentPeriodEnd
          : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cancelAtPeriodEnd: null == cancelAtPeriodEnd
          ? _value.cancelAtPeriodEnd
          : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
              as bool,
      canceledAt: freezed == canceledAt
          ? _value.canceledAt
          : canceledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      amountCents: null == amountCents
          ? _value.amountCents
          : amountCents // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      interval: null == interval
          ? _value.interval
          : interval // ignore: cast_nullable_to_non_nullable
              as String,
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
class _$SubscriptionImpl extends _Subscription {
  const _$SubscriptionImpl(
      {required this.id,
      required this.userId,
      required this.stripeSubscriptionId,
      required this.stripeCustomerId,
      required this.stripePriceId,
      required this.status,
      required this.currentPeriodStart,
      required this.currentPeriodEnd,
      required this.cancelAtPeriodEnd,
      this.canceledAt,
      required this.amountCents,
      required this.currency,
      required this.interval,
      required this.createdAt,
      required this.updatedAt})
      : super._();

  factory _$SubscriptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String stripeSubscriptionId;
  @override
  final String stripeCustomerId;
  @override
  final String stripePriceId;
  @override
  final String status;
  @override
  final DateTime currentPeriodStart;
  @override
  final DateTime currentPeriodEnd;
  @override
  final bool cancelAtPeriodEnd;
  @override
  final DateTime? canceledAt;
  @override
  final int amountCents;
  @override
  final String currency;
  @override
  final String interval;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Subscription(id: $id, userId: $userId, stripeSubscriptionId: $stripeSubscriptionId, stripeCustomerId: $stripeCustomerId, stripePriceId: $stripePriceId, status: $status, currentPeriodStart: $currentPeriodStart, currentPeriodEnd: $currentPeriodEnd, cancelAtPeriodEnd: $cancelAtPeriodEnd, canceledAt: $canceledAt, amountCents: $amountCents, currency: $currency, interval: $interval, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.stripeSubscriptionId, stripeSubscriptionId) ||
                other.stripeSubscriptionId == stripeSubscriptionId) &&
            (identical(other.stripeCustomerId, stripeCustomerId) ||
                other.stripeCustomerId == stripeCustomerId) &&
            (identical(other.stripePriceId, stripePriceId) ||
                other.stripePriceId == stripePriceId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentPeriodStart, currentPeriodStart) ||
                other.currentPeriodStart == currentPeriodStart) &&
            (identical(other.currentPeriodEnd, currentPeriodEnd) ||
                other.currentPeriodEnd == currentPeriodEnd) &&
            (identical(other.cancelAtPeriodEnd, cancelAtPeriodEnd) ||
                other.cancelAtPeriodEnd == cancelAtPeriodEnd) &&
            (identical(other.canceledAt, canceledAt) ||
                other.canceledAt == canceledAt) &&
            (identical(other.amountCents, amountCents) ||
                other.amountCents == amountCents) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.interval, interval) ||
                other.interval == interval) &&
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
      stripeSubscriptionId,
      stripeCustomerId,
      stripePriceId,
      status,
      currentPeriodStart,
      currentPeriodEnd,
      cancelAtPeriodEnd,
      canceledAt,
      amountCents,
      currency,
      interval,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionImplCopyWith<_$SubscriptionImpl> get copyWith =>
      __$$SubscriptionImplCopyWithImpl<_$SubscriptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionImplToJson(
      this,
    );
  }
}

abstract class _Subscription extends Subscription {
  const factory _Subscription(
      {required final String id,
      required final String userId,
      required final String stripeSubscriptionId,
      required final String stripeCustomerId,
      required final String stripePriceId,
      required final String status,
      required final DateTime currentPeriodStart,
      required final DateTime currentPeriodEnd,
      required final bool cancelAtPeriodEnd,
      final DateTime? canceledAt,
      required final int amountCents,
      required final String currency,
      required final String interval,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$SubscriptionImpl;
  const _Subscription._() : super._();

  factory _Subscription.fromJson(Map<String, dynamic> json) =
      _$SubscriptionImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get stripeSubscriptionId;
  @override
  String get stripeCustomerId;
  @override
  String get stripePriceId;
  @override
  String get status;
  @override
  DateTime get currentPeriodStart;
  @override
  DateTime get currentPeriodEnd;
  @override
  bool get cancelAtPeriodEnd;
  @override
  DateTime? get canceledAt;
  @override
  int get amountCents;
  @override
  String get currency;
  @override
  String get interval;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$SubscriptionImplCopyWith<_$SubscriptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QuotaInfo _$QuotaInfoFromJson(Map<String, dynamic> json) {
  return _QuotaInfo.fromJson(json);
}

/// @nodoc
mixin _$QuotaInfo {
  int get swipeRemaining => throw _privateConstructorUsedError;
  int get messageRemaining => throw _privateConstructorUsedError;
  bool get limitReached => throw _privateConstructorUsedError;
  String? get limitType => throw _privateConstructorUsedError;
  DateTime get resetsAt => throw _privateConstructorUsedError;
  bool get isPremium => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuotaInfoCopyWith<QuotaInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuotaInfoCopyWith<$Res> {
  factory $QuotaInfoCopyWith(QuotaInfo value, $Res Function(QuotaInfo) then) =
      _$QuotaInfoCopyWithImpl<$Res, QuotaInfo>;
  @useResult
  $Res call(
      {int swipeRemaining,
      int messageRemaining,
      bool limitReached,
      String? limitType,
      DateTime resetsAt,
      bool isPremium});
}

/// @nodoc
class _$QuotaInfoCopyWithImpl<$Res, $Val extends QuotaInfo>
    implements $QuotaInfoCopyWith<$Res> {
  _$QuotaInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? swipeRemaining = null,
    Object? messageRemaining = null,
    Object? limitReached = null,
    Object? limitType = freezed,
    Object? resetsAt = null,
    Object? isPremium = null,
  }) {
    return _then(_value.copyWith(
      swipeRemaining: null == swipeRemaining
          ? _value.swipeRemaining
          : swipeRemaining // ignore: cast_nullable_to_non_nullable
              as int,
      messageRemaining: null == messageRemaining
          ? _value.messageRemaining
          : messageRemaining // ignore: cast_nullable_to_non_nullable
              as int,
      limitReached: null == limitReached
          ? _value.limitReached
          : limitReached // ignore: cast_nullable_to_non_nullable
              as bool,
      limitType: freezed == limitType
          ? _value.limitType
          : limitType // ignore: cast_nullable_to_non_nullable
              as String?,
      resetsAt: null == resetsAt
          ? _value.resetsAt
          : resetsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuotaInfoImplCopyWith<$Res>
    implements $QuotaInfoCopyWith<$Res> {
  factory _$$QuotaInfoImplCopyWith(
          _$QuotaInfoImpl value, $Res Function(_$QuotaInfoImpl) then) =
      __$$QuotaInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int swipeRemaining,
      int messageRemaining,
      bool limitReached,
      String? limitType,
      DateTime resetsAt,
      bool isPremium});
}

/// @nodoc
class __$$QuotaInfoImplCopyWithImpl<$Res>
    extends _$QuotaInfoCopyWithImpl<$Res, _$QuotaInfoImpl>
    implements _$$QuotaInfoImplCopyWith<$Res> {
  __$$QuotaInfoImplCopyWithImpl(
      _$QuotaInfoImpl _value, $Res Function(_$QuotaInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? swipeRemaining = null,
    Object? messageRemaining = null,
    Object? limitReached = null,
    Object? limitType = freezed,
    Object? resetsAt = null,
    Object? isPremium = null,
  }) {
    return _then(_$QuotaInfoImpl(
      swipeRemaining: null == swipeRemaining
          ? _value.swipeRemaining
          : swipeRemaining // ignore: cast_nullable_to_non_nullable
              as int,
      messageRemaining: null == messageRemaining
          ? _value.messageRemaining
          : messageRemaining // ignore: cast_nullable_to_non_nullable
              as int,
      limitReached: null == limitReached
          ? _value.limitReached
          : limitReached // ignore: cast_nullable_to_non_nullable
              as bool,
      limitType: freezed == limitType
          ? _value.limitType
          : limitType // ignore: cast_nullable_to_non_nullable
              as String?,
      resetsAt: null == resetsAt
          ? _value.resetsAt
          : resetsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuotaInfoImpl extends _QuotaInfo {
  const _$QuotaInfoImpl(
      {required this.swipeRemaining,
      required this.messageRemaining,
      required this.limitReached,
      this.limitType,
      required this.resetsAt,
      required this.isPremium})
      : super._();

  factory _$QuotaInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuotaInfoImplFromJson(json);

  @override
  final int swipeRemaining;
  @override
  final int messageRemaining;
  @override
  final bool limitReached;
  @override
  final String? limitType;
  @override
  final DateTime resetsAt;
  @override
  final bool isPremium;

  @override
  String toString() {
    return 'QuotaInfo(swipeRemaining: $swipeRemaining, messageRemaining: $messageRemaining, limitReached: $limitReached, limitType: $limitType, resetsAt: $resetsAt, isPremium: $isPremium)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuotaInfoImpl &&
            (identical(other.swipeRemaining, swipeRemaining) ||
                other.swipeRemaining == swipeRemaining) &&
            (identical(other.messageRemaining, messageRemaining) ||
                other.messageRemaining == messageRemaining) &&
            (identical(other.limitReached, limitReached) ||
                other.limitReached == limitReached) &&
            (identical(other.limitType, limitType) ||
                other.limitType == limitType) &&
            (identical(other.resetsAt, resetsAt) ||
                other.resetsAt == resetsAt) &&
            (identical(other.isPremium, isPremium) ||
                other.isPremium == isPremium));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, swipeRemaining, messageRemaining,
      limitReached, limitType, resetsAt, isPremium);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuotaInfoImplCopyWith<_$QuotaInfoImpl> get copyWith =>
      __$$QuotaInfoImplCopyWithImpl<_$QuotaInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuotaInfoImplToJson(
      this,
    );
  }
}

abstract class _QuotaInfo extends QuotaInfo {
  const factory _QuotaInfo(
      {required final int swipeRemaining,
      required final int messageRemaining,
      required final bool limitReached,
      final String? limitType,
      required final DateTime resetsAt,
      required final bool isPremium}) = _$QuotaInfoImpl;
  const _QuotaInfo._() : super._();

  factory _QuotaInfo.fromJson(Map<String, dynamic> json) =
      _$QuotaInfoImpl.fromJson;

  @override
  int get swipeRemaining;
  @override
  int get messageRemaining;
  @override
  bool get limitReached;
  @override
  String? get limitType;
  @override
  DateTime get resetsAt;
  @override
  bool get isPremium;
  @override
  @JsonKey(ignore: true)
  _$$QuotaInfoImplCopyWith<_$QuotaInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Boost _$BoostFromJson(Map<String, dynamic> json) {
  return _Boost.fromJson(json);
}

/// @nodoc
mixin _$Boost {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get stationId => throw _privateConstructorUsedError;
  DateTime get startsAt => throw _privateConstructorUsedError;
  DateTime get endsAt => throw _privateConstructorUsedError;
  double get boostMultiplier => throw _privateConstructorUsedError;
  int get amountPaidCents => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String? get stripePaymentIntentId => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime get createdAt =>
      throw _privateConstructorUsedError; // Station info (from join)
  String? get stationName => throw _privateConstructorUsedError;
  String? get stationCountryCode => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BoostCopyWith<Boost> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BoostCopyWith<$Res> {
  factory $BoostCopyWith(Boost value, $Res Function(Boost) then) =
      _$BoostCopyWithImpl<$Res, Boost>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String stationId,
      DateTime startsAt,
      DateTime endsAt,
      double boostMultiplier,
      int amountPaidCents,
      String currency,
      String? stripePaymentIntentId,
      bool isActive,
      DateTime createdAt,
      String? stationName,
      String? stationCountryCode});
}

/// @nodoc
class _$BoostCopyWithImpl<$Res, $Val extends Boost>
    implements $BoostCopyWith<$Res> {
  _$BoostCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? stationId = null,
    Object? startsAt = null,
    Object? endsAt = null,
    Object? boostMultiplier = null,
    Object? amountPaidCents = null,
    Object? currency = null,
    Object? stripePaymentIntentId = freezed,
    Object? isActive = null,
    Object? createdAt = null,
    Object? stationName = freezed,
    Object? stationCountryCode = freezed,
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
      stationId: null == stationId
          ? _value.stationId
          : stationId // ignore: cast_nullable_to_non_nullable
              as String,
      startsAt: null == startsAt
          ? _value.startsAt
          : startsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endsAt: null == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      boostMultiplier: null == boostMultiplier
          ? _value.boostMultiplier
          : boostMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      amountPaidCents: null == amountPaidCents
          ? _value.amountPaidCents
          : amountPaidCents // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      stripePaymentIntentId: freezed == stripePaymentIntentId
          ? _value.stripePaymentIntentId
          : stripePaymentIntentId // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      stationName: freezed == stationName
          ? _value.stationName
          : stationName // ignore: cast_nullable_to_non_nullable
              as String?,
      stationCountryCode: freezed == stationCountryCode
          ? _value.stationCountryCode
          : stationCountryCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BoostImplCopyWith<$Res> implements $BoostCopyWith<$Res> {
  factory _$$BoostImplCopyWith(
          _$BoostImpl value, $Res Function(_$BoostImpl) then) =
      __$$BoostImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String stationId,
      DateTime startsAt,
      DateTime endsAt,
      double boostMultiplier,
      int amountPaidCents,
      String currency,
      String? stripePaymentIntentId,
      bool isActive,
      DateTime createdAt,
      String? stationName,
      String? stationCountryCode});
}

/// @nodoc
class __$$BoostImplCopyWithImpl<$Res>
    extends _$BoostCopyWithImpl<$Res, _$BoostImpl>
    implements _$$BoostImplCopyWith<$Res> {
  __$$BoostImplCopyWithImpl(
      _$BoostImpl _value, $Res Function(_$BoostImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? stationId = null,
    Object? startsAt = null,
    Object? endsAt = null,
    Object? boostMultiplier = null,
    Object? amountPaidCents = null,
    Object? currency = null,
    Object? stripePaymentIntentId = freezed,
    Object? isActive = null,
    Object? createdAt = null,
    Object? stationName = freezed,
    Object? stationCountryCode = freezed,
  }) {
    return _then(_$BoostImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      stationId: null == stationId
          ? _value.stationId
          : stationId // ignore: cast_nullable_to_non_nullable
              as String,
      startsAt: null == startsAt
          ? _value.startsAt
          : startsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endsAt: null == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      boostMultiplier: null == boostMultiplier
          ? _value.boostMultiplier
          : boostMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      amountPaidCents: null == amountPaidCents
          ? _value.amountPaidCents
          : amountPaidCents // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      stripePaymentIntentId: freezed == stripePaymentIntentId
          ? _value.stripePaymentIntentId
          : stripePaymentIntentId // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      stationName: freezed == stationName
          ? _value.stationName
          : stationName // ignore: cast_nullable_to_non_nullable
              as String?,
      stationCountryCode: freezed == stationCountryCode
          ? _value.stationCountryCode
          : stationCountryCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BoostImpl extends _Boost {
  const _$BoostImpl(
      {required this.id,
      required this.userId,
      required this.stationId,
      required this.startsAt,
      required this.endsAt,
      required this.boostMultiplier,
      required this.amountPaidCents,
      required this.currency,
      this.stripePaymentIntentId,
      required this.isActive,
      required this.createdAt,
      this.stationName,
      this.stationCountryCode})
      : super._();

  factory _$BoostImpl.fromJson(Map<String, dynamic> json) =>
      _$$BoostImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String stationId;
  @override
  final DateTime startsAt;
  @override
  final DateTime endsAt;
  @override
  final double boostMultiplier;
  @override
  final int amountPaidCents;
  @override
  final String currency;
  @override
  final String? stripePaymentIntentId;
  @override
  final bool isActive;
  @override
  final DateTime createdAt;
// Station info (from join)
  @override
  final String? stationName;
  @override
  final String? stationCountryCode;

  @override
  String toString() {
    return 'Boost(id: $id, userId: $userId, stationId: $stationId, startsAt: $startsAt, endsAt: $endsAt, boostMultiplier: $boostMultiplier, amountPaidCents: $amountPaidCents, currency: $currency, stripePaymentIntentId: $stripePaymentIntentId, isActive: $isActive, createdAt: $createdAt, stationName: $stationName, stationCountryCode: $stationCountryCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BoostImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.stationId, stationId) ||
                other.stationId == stationId) &&
            (identical(other.startsAt, startsAt) ||
                other.startsAt == startsAt) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt) &&
            (identical(other.boostMultiplier, boostMultiplier) ||
                other.boostMultiplier == boostMultiplier) &&
            (identical(other.amountPaidCents, amountPaidCents) ||
                other.amountPaidCents == amountPaidCents) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.stripePaymentIntentId, stripePaymentIntentId) ||
                other.stripePaymentIntentId == stripePaymentIntentId) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.stationName, stationName) ||
                other.stationName == stationName) &&
            (identical(other.stationCountryCode, stationCountryCode) ||
                other.stationCountryCode == stationCountryCode));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      stationId,
      startsAt,
      endsAt,
      boostMultiplier,
      amountPaidCents,
      currency,
      stripePaymentIntentId,
      isActive,
      createdAt,
      stationName,
      stationCountryCode);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BoostImplCopyWith<_$BoostImpl> get copyWith =>
      __$$BoostImplCopyWithImpl<_$BoostImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BoostImplToJson(
      this,
    );
  }
}

abstract class _Boost extends Boost {
  const factory _Boost(
      {required final String id,
      required final String userId,
      required final String stationId,
      required final DateTime startsAt,
      required final DateTime endsAt,
      required final double boostMultiplier,
      required final int amountPaidCents,
      required final String currency,
      final String? stripePaymentIntentId,
      required final bool isActive,
      required final DateTime createdAt,
      final String? stationName,
      final String? stationCountryCode}) = _$BoostImpl;
  const _Boost._() : super._();

  factory _Boost.fromJson(Map<String, dynamic> json) = _$BoostImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get stationId;
  @override
  DateTime get startsAt;
  @override
  DateTime get endsAt;
  @override
  double get boostMultiplier;
  @override
  int get amountPaidCents;
  @override
  String get currency;
  @override
  String? get stripePaymentIntentId;
  @override
  bool get isActive;
  @override
  DateTime get createdAt;
  @override // Station info (from join)
  String? get stationName;
  @override
  String? get stationCountryCode;
  @override
  @JsonKey(ignore: true)
  _$$BoostImplCopyWith<_$BoostImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PremiumPlan _$PremiumPlanFromJson(Map<String, dynamic> json) {
  return _PremiumPlan.fromJson(json);
}

/// @nodoc
mixin _$PremiumPlan {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get priceMonthly => throw _privateConstructorUsedError;
  int get priceYearly => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  List<String> get features => throw _privateConstructorUsedError;
  bool get isPopular => throw _privateConstructorUsedError;
  String? get stripePriceIdMonthly => throw _privateConstructorUsedError;
  String? get stripePriceIdYearly => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PremiumPlanCopyWith<PremiumPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PremiumPlanCopyWith<$Res> {
  factory $PremiumPlanCopyWith(
          PremiumPlan value, $Res Function(PremiumPlan) then) =
      _$PremiumPlanCopyWithImpl<$Res, PremiumPlan>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      int priceMonthly,
      int priceYearly,
      String currency,
      List<String> features,
      bool isPopular,
      String? stripePriceIdMonthly,
      String? stripePriceIdYearly});
}

/// @nodoc
class _$PremiumPlanCopyWithImpl<$Res, $Val extends PremiumPlan>
    implements $PremiumPlanCopyWith<$Res> {
  _$PremiumPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? priceMonthly = null,
    Object? priceYearly = null,
    Object? currency = null,
    Object? features = null,
    Object? isPopular = null,
    Object? stripePriceIdMonthly = freezed,
    Object? stripePriceIdYearly = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      priceMonthly: null == priceMonthly
          ? _value.priceMonthly
          : priceMonthly // ignore: cast_nullable_to_non_nullable
              as int,
      priceYearly: null == priceYearly
          ? _value.priceYearly
          : priceYearly // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      features: null == features
          ? _value.features
          : features // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isPopular: null == isPopular
          ? _value.isPopular
          : isPopular // ignore: cast_nullable_to_non_nullable
              as bool,
      stripePriceIdMonthly: freezed == stripePriceIdMonthly
          ? _value.stripePriceIdMonthly
          : stripePriceIdMonthly // ignore: cast_nullable_to_non_nullable
              as String?,
      stripePriceIdYearly: freezed == stripePriceIdYearly
          ? _value.stripePriceIdYearly
          : stripePriceIdYearly // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PremiumPlanImplCopyWith<$Res>
    implements $PremiumPlanCopyWith<$Res> {
  factory _$$PremiumPlanImplCopyWith(
          _$PremiumPlanImpl value, $Res Function(_$PremiumPlanImpl) then) =
      __$$PremiumPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      int priceMonthly,
      int priceYearly,
      String currency,
      List<String> features,
      bool isPopular,
      String? stripePriceIdMonthly,
      String? stripePriceIdYearly});
}

/// @nodoc
class __$$PremiumPlanImplCopyWithImpl<$Res>
    extends _$PremiumPlanCopyWithImpl<$Res, _$PremiumPlanImpl>
    implements _$$PremiumPlanImplCopyWith<$Res> {
  __$$PremiumPlanImplCopyWithImpl(
      _$PremiumPlanImpl _value, $Res Function(_$PremiumPlanImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? priceMonthly = null,
    Object? priceYearly = null,
    Object? currency = null,
    Object? features = null,
    Object? isPopular = null,
    Object? stripePriceIdMonthly = freezed,
    Object? stripePriceIdYearly = freezed,
  }) {
    return _then(_$PremiumPlanImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      priceMonthly: null == priceMonthly
          ? _value.priceMonthly
          : priceMonthly // ignore: cast_nullable_to_non_nullable
              as int,
      priceYearly: null == priceYearly
          ? _value.priceYearly
          : priceYearly // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      features: null == features
          ? _value._features
          : features // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isPopular: null == isPopular
          ? _value.isPopular
          : isPopular // ignore: cast_nullable_to_non_nullable
              as bool,
      stripePriceIdMonthly: freezed == stripePriceIdMonthly
          ? _value.stripePriceIdMonthly
          : stripePriceIdMonthly // ignore: cast_nullable_to_non_nullable
              as String?,
      stripePriceIdYearly: freezed == stripePriceIdYearly
          ? _value.stripePriceIdYearly
          : stripePriceIdYearly // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PremiumPlanImpl extends _PremiumPlan {
  const _$PremiumPlanImpl(
      {required this.id,
      required this.name,
      required this.description,
      required this.priceMonthly,
      required this.priceYearly,
      required this.currency,
      required final List<String> features,
      required this.isPopular,
      this.stripePriceIdMonthly,
      this.stripePriceIdYearly})
      : _features = features,
        super._();

  factory _$PremiumPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$PremiumPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final int priceMonthly;
  @override
  final int priceYearly;
  @override
  final String currency;
  final List<String> _features;
  @override
  List<String> get features {
    if (_features is EqualUnmodifiableListView) return _features;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_features);
  }

  @override
  final bool isPopular;
  @override
  final String? stripePriceIdMonthly;
  @override
  final String? stripePriceIdYearly;

  @override
  String toString() {
    return 'PremiumPlan(id: $id, name: $name, description: $description, priceMonthly: $priceMonthly, priceYearly: $priceYearly, currency: $currency, features: $features, isPopular: $isPopular, stripePriceIdMonthly: $stripePriceIdMonthly, stripePriceIdYearly: $stripePriceIdYearly)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PremiumPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.priceMonthly, priceMonthly) ||
                other.priceMonthly == priceMonthly) &&
            (identical(other.priceYearly, priceYearly) ||
                other.priceYearly == priceYearly) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            const DeepCollectionEquality().equals(other._features, _features) &&
            (identical(other.isPopular, isPopular) ||
                other.isPopular == isPopular) &&
            (identical(other.stripePriceIdMonthly, stripePriceIdMonthly) ||
                other.stripePriceIdMonthly == stripePriceIdMonthly) &&
            (identical(other.stripePriceIdYearly, stripePriceIdYearly) ||
                other.stripePriceIdYearly == stripePriceIdYearly));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      priceMonthly,
      priceYearly,
      currency,
      const DeepCollectionEquality().hash(_features),
      isPopular,
      stripePriceIdMonthly,
      stripePriceIdYearly);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PremiumPlanImplCopyWith<_$PremiumPlanImpl> get copyWith =>
      __$$PremiumPlanImplCopyWithImpl<_$PremiumPlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PremiumPlanImplToJson(
      this,
    );
  }
}

abstract class _PremiumPlan extends PremiumPlan {
  const factory _PremiumPlan(
      {required final String id,
      required final String name,
      required final String description,
      required final int priceMonthly,
      required final int priceYearly,
      required final String currency,
      required final List<String> features,
      required final bool isPopular,
      final String? stripePriceIdMonthly,
      final String? stripePriceIdYearly}) = _$PremiumPlanImpl;
  const _PremiumPlan._() : super._();

  factory _PremiumPlan.fromJson(Map<String, dynamic> json) =
      _$PremiumPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  int get priceMonthly;
  @override
  int get priceYearly;
  @override
  String get currency;
  @override
  List<String> get features;
  @override
  bool get isPopular;
  @override
  String? get stripePriceIdMonthly;
  @override
  String? get stripePriceIdYearly;
  @override
  @JsonKey(ignore: true)
  _$$PremiumPlanImplCopyWith<_$PremiumPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
