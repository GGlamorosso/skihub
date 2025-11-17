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
  SubscriptionStatus get status => throw _privateConstructorUsedError;
  DateTime get currentPeriodStart => throw _privateConstructorUsedError;
  DateTime get currentPeriodEnd => throw _privateConstructorUsedError;
  bool get cancelAtPeriodEnd => throw _privateConstructorUsedError;
  DateTime? get canceledAt => throw _privateConstructorUsedError;
  int get amountCents => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String get interval =>
      throw _privateConstructorUsedError; // 'month' or 'year'
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
      SubscriptionStatus status,
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
              as SubscriptionStatus,
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
      SubscriptionStatus status,
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
              as SubscriptionStatus,
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
class _$SubscriptionImpl implements _Subscription {
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
      required this.updatedAt});

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
  final SubscriptionStatus status;
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
// 'month' or 'year'
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

abstract class _Subscription implements Subscription {
  const factory _Subscription(
      {required final String id,
      required final String userId,
      required final String stripeSubscriptionId,
      required final String stripeCustomerId,
      required final String stripePriceId,
      required final SubscriptionStatus status,
      required final DateTime currentPeriodStart,
      required final DateTime currentPeriodEnd,
      required final bool cancelAtPeriodEnd,
      final DateTime? canceledAt,
      required final int amountCents,
      required final String currency,
      required final String interval,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$SubscriptionImpl;

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
  SubscriptionStatus get status;
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
  @override // 'month' or 'year'
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
  QuotaType get limitType => throw _privateConstructorUsedError;
  int get dailySwipeLimit => throw _privateConstructorUsedError;
  int get dailyMessageLimit => throw _privateConstructorUsedError;
  DateTime get resetsAt => throw _privateConstructorUsedError;

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
      QuotaType limitType,
      int dailySwipeLimit,
      int dailyMessageLimit,
      DateTime resetsAt});
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
    Object? limitType = null,
    Object? dailySwipeLimit = null,
    Object? dailyMessageLimit = null,
    Object? resetsAt = null,
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
      limitType: null == limitType
          ? _value.limitType
          : limitType // ignore: cast_nullable_to_non_nullable
              as QuotaType,
      dailySwipeLimit: null == dailySwipeLimit
          ? _value.dailySwipeLimit
          : dailySwipeLimit // ignore: cast_nullable_to_non_nullable
              as int,
      dailyMessageLimit: null == dailyMessageLimit
          ? _value.dailyMessageLimit
          : dailyMessageLimit // ignore: cast_nullable_to_non_nullable
              as int,
      resetsAt: null == resetsAt
          ? _value.resetsAt
          : resetsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
      QuotaType limitType,
      int dailySwipeLimit,
      int dailyMessageLimit,
      DateTime resetsAt});
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
    Object? limitType = null,
    Object? dailySwipeLimit = null,
    Object? dailyMessageLimit = null,
    Object? resetsAt = null,
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
      limitType: null == limitType
          ? _value.limitType
          : limitType // ignore: cast_nullable_to_non_nullable
              as QuotaType,
      dailySwipeLimit: null == dailySwipeLimit
          ? _value.dailySwipeLimit
          : dailySwipeLimit // ignore: cast_nullable_to_non_nullable
              as int,
      dailyMessageLimit: null == dailyMessageLimit
          ? _value.dailyMessageLimit
          : dailyMessageLimit // ignore: cast_nullable_to_non_nullable
              as int,
      resetsAt: null == resetsAt
          ? _value.resetsAt
          : resetsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuotaInfoImpl implements _QuotaInfo {
  const _$QuotaInfoImpl(
      {required this.swipeRemaining,
      required this.messageRemaining,
      required this.limitReached,
      required this.limitType,
      required this.dailySwipeLimit,
      required this.dailyMessageLimit,
      required this.resetsAt});

  factory _$QuotaInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuotaInfoImplFromJson(json);

  @override
  final int swipeRemaining;
  @override
  final int messageRemaining;
  @override
  final bool limitReached;
  @override
  final QuotaType limitType;
  @override
  final int dailySwipeLimit;
  @override
  final int dailyMessageLimit;
  @override
  final DateTime resetsAt;

  @override
  String toString() {
    return 'QuotaInfo(swipeRemaining: $swipeRemaining, messageRemaining: $messageRemaining, limitReached: $limitReached, limitType: $limitType, dailySwipeLimit: $dailySwipeLimit, dailyMessageLimit: $dailyMessageLimit, resetsAt: $resetsAt)';
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
            (identical(other.dailySwipeLimit, dailySwipeLimit) ||
                other.dailySwipeLimit == dailySwipeLimit) &&
            (identical(other.dailyMessageLimit, dailyMessageLimit) ||
                other.dailyMessageLimit == dailyMessageLimit) &&
            (identical(other.resetsAt, resetsAt) ||
                other.resetsAt == resetsAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, swipeRemaining, messageRemaining,
      limitReached, limitType, dailySwipeLimit, dailyMessageLimit, resetsAt);

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

abstract class _QuotaInfo implements QuotaInfo {
  const factory _QuotaInfo(
      {required final int swipeRemaining,
      required final int messageRemaining,
      required final bool limitReached,
      required final QuotaType limitType,
      required final int dailySwipeLimit,
      required final int dailyMessageLimit,
      required final DateTime resetsAt}) = _$QuotaInfoImpl;

  factory _QuotaInfo.fromJson(Map<String, dynamic> json) =
      _$QuotaInfoImpl.fromJson;

  @override
  int get swipeRemaining;
  @override
  int get messageRemaining;
  @override
  bool get limitReached;
  @override
  QuotaType get limitType;
  @override
  int get dailySwipeLimit;
  @override
  int get dailyMessageLimit;
  @override
  DateTime get resetsAt;
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
      throw _privateConstructorUsedError; // Computed fields
  String? get stationName => throw _privateConstructorUsedError;
  Duration? get remainingDuration => throw _privateConstructorUsedError;

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
      Duration? remainingDuration});
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
    Object? remainingDuration = freezed,
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
      remainingDuration: freezed == remainingDuration
          ? _value.remainingDuration
          : remainingDuration // ignore: cast_nullable_to_non_nullable
              as Duration?,
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
      Duration? remainingDuration});
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
    Object? remainingDuration = freezed,
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
      remainingDuration: freezed == remainingDuration
          ? _value.remainingDuration
          : remainingDuration // ignore: cast_nullable_to_non_nullable
              as Duration?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BoostImpl implements _Boost {
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
      this.remainingDuration});

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
// Computed fields
  @override
  final String? stationName;
  @override
  final Duration? remainingDuration;

  @override
  String toString() {
    return 'Boost(id: $id, userId: $userId, stationId: $stationId, startsAt: $startsAt, endsAt: $endsAt, boostMultiplier: $boostMultiplier, amountPaidCents: $amountPaidCents, currency: $currency, stripePaymentIntentId: $stripePaymentIntentId, isActive: $isActive, createdAt: $createdAt, stationName: $stationName, remainingDuration: $remainingDuration)';
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
            (identical(other.remainingDuration, remainingDuration) ||
                other.remainingDuration == remainingDuration));
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
      remainingDuration);

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

abstract class _Boost implements Boost {
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
      final Duration? remainingDuration}) = _$BoostImpl;

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
  @override // Computed fields
  String? get stationName;
  @override
  Duration? get remainingDuration;
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
  int get amountCents => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String get interval => throw _privateConstructorUsedError;
  List<String> get features => throw _privateConstructorUsedError;
  bool get isPopular => throw _privateConstructorUsedError;
  String? get stripePriceId => throw _privateConstructorUsedError;
  int? get discountPercent => throw _privateConstructorUsedError;

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
      int amountCents,
      String currency,
      String interval,
      List<String> features,
      bool isPopular,
      String? stripePriceId,
      int? discountPercent});
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
    Object? amountCents = null,
    Object? currency = null,
    Object? interval = null,
    Object? features = null,
    Object? isPopular = null,
    Object? stripePriceId = freezed,
    Object? discountPercent = freezed,
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
      features: null == features
          ? _value.features
          : features // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isPopular: null == isPopular
          ? _value.isPopular
          : isPopular // ignore: cast_nullable_to_non_nullable
              as bool,
      stripePriceId: freezed == stripePriceId
          ? _value.stripePriceId
          : stripePriceId // ignore: cast_nullable_to_non_nullable
              as String?,
      discountPercent: freezed == discountPercent
          ? _value.discountPercent
          : discountPercent // ignore: cast_nullable_to_non_nullable
              as int?,
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
      int amountCents,
      String currency,
      String interval,
      List<String> features,
      bool isPopular,
      String? stripePriceId,
      int? discountPercent});
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
    Object? amountCents = null,
    Object? currency = null,
    Object? interval = null,
    Object? features = null,
    Object? isPopular = null,
    Object? stripePriceId = freezed,
    Object? discountPercent = freezed,
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
      features: null == features
          ? _value._features
          : features // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isPopular: null == isPopular
          ? _value.isPopular
          : isPopular // ignore: cast_nullable_to_non_nullable
              as bool,
      stripePriceId: freezed == stripePriceId
          ? _value.stripePriceId
          : stripePriceId // ignore: cast_nullable_to_non_nullable
              as String?,
      discountPercent: freezed == discountPercent
          ? _value.discountPercent
          : discountPercent // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PremiumPlanImpl implements _PremiumPlan {
  const _$PremiumPlanImpl(
      {required this.id,
      required this.name,
      required this.description,
      required this.amountCents,
      required this.currency,
      required this.interval,
      required final List<String> features,
      required this.isPopular,
      this.stripePriceId,
      this.discountPercent})
      : _features = features;

  factory _$PremiumPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$PremiumPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final int amountCents;
  @override
  final String currency;
  @override
  final String interval;
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
  final String? stripePriceId;
  @override
  final int? discountPercent;

  @override
  String toString() {
    return 'PremiumPlan(id: $id, name: $name, description: $description, amountCents: $amountCents, currency: $currency, interval: $interval, features: $features, isPopular: $isPopular, stripePriceId: $stripePriceId, discountPercent: $discountPercent)';
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
            (identical(other.amountCents, amountCents) ||
                other.amountCents == amountCents) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.interval, interval) ||
                other.interval == interval) &&
            const DeepCollectionEquality().equals(other._features, _features) &&
            (identical(other.isPopular, isPopular) ||
                other.isPopular == isPopular) &&
            (identical(other.stripePriceId, stripePriceId) ||
                other.stripePriceId == stripePriceId) &&
            (identical(other.discountPercent, discountPercent) ||
                other.discountPercent == discountPercent));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      amountCents,
      currency,
      interval,
      const DeepCollectionEquality().hash(_features),
      isPopular,
      stripePriceId,
      discountPercent);

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

abstract class _PremiumPlan implements PremiumPlan {
  const factory _PremiumPlan(
      {required final String id,
      required final String name,
      required final String description,
      required final int amountCents,
      required final String currency,
      required final String interval,
      required final List<String> features,
      required final bool isPopular,
      final String? stripePriceId,
      final int? discountPercent}) = _$PremiumPlanImpl;

  factory _PremiumPlan.fromJson(Map<String, dynamic> json) =
      _$PremiumPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  int get amountCents;
  @override
  String get currency;
  @override
  String get interval;
  @override
  List<String> get features;
  @override
  bool get isPopular;
  @override
  String? get stripePriceId;
  @override
  int? get discountPercent;
  @override
  @JsonKey(ignore: true)
  _$$PremiumPlanImplCopyWith<_$PremiumPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
