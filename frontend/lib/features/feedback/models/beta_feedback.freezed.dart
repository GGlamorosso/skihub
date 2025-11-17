// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'beta_feedback.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BetaFeedback _$BetaFeedbackFromJson(Map<String, dynamic> json) {
  return _BetaFeedback.fromJson(json);
}

/// @nodoc
mixin _$BetaFeedback {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get subject => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int? get rating => throw _privateConstructorUsedError;
  FeedbackCategory get category => throw _privateConstructorUsedError;
  String? get appVersion => throw _privateConstructorUsedError;
  Map<String, dynamic>? get deviceInfo => throw _privateConstructorUsedError;
  String? get screenshotUrl => throw _privateConstructorUsedError;
  FeedbackStatus get status => throw _privateConstructorUsedError;
  FeedbackPriority get priority => throw _privateConstructorUsedError;
  String? get assignedTo => throw _privateConstructorUsedError;
  DateTime? get processedAt => throw _privateConstructorUsedError;
  String? get response => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BetaFeedbackCopyWith<BetaFeedback> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BetaFeedbackCopyWith<$Res> {
  factory $BetaFeedbackCopyWith(
          BetaFeedback value, $Res Function(BetaFeedback) then) =
      _$BetaFeedbackCopyWithImpl<$Res, BetaFeedback>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String? subject,
      String description,
      int? rating,
      FeedbackCategory category,
      String? appVersion,
      Map<String, dynamic>? deviceInfo,
      String? screenshotUrl,
      FeedbackStatus status,
      FeedbackPriority priority,
      String? assignedTo,
      DateTime? processedAt,
      String? response,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$BetaFeedbackCopyWithImpl<$Res, $Val extends BetaFeedback>
    implements $BetaFeedbackCopyWith<$Res> {
  _$BetaFeedbackCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? subject = freezed,
    Object? description = null,
    Object? rating = freezed,
    Object? category = null,
    Object? appVersion = freezed,
    Object? deviceInfo = freezed,
    Object? screenshotUrl = freezed,
    Object? status = null,
    Object? priority = null,
    Object? assignedTo = freezed,
    Object? processedAt = freezed,
    Object? response = freezed,
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
      subject: freezed == subject
          ? _value.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as FeedbackCategory,
      appVersion: freezed == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceInfo: freezed == deviceInfo
          ? _value.deviceInfo
          : deviceInfo // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      screenshotUrl: freezed == screenshotUrl
          ? _value.screenshotUrl
          : screenshotUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as FeedbackStatus,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as FeedbackPriority,
      assignedTo: freezed == assignedTo
          ? _value.assignedTo
          : assignedTo // ignore: cast_nullable_to_non_nullable
              as String?,
      processedAt: freezed == processedAt
          ? _value.processedAt
          : processedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      response: freezed == response
          ? _value.response
          : response // ignore: cast_nullable_to_non_nullable
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
abstract class _$$BetaFeedbackImplCopyWith<$Res>
    implements $BetaFeedbackCopyWith<$Res> {
  factory _$$BetaFeedbackImplCopyWith(
          _$BetaFeedbackImpl value, $Res Function(_$BetaFeedbackImpl) then) =
      __$$BetaFeedbackImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String? subject,
      String description,
      int? rating,
      FeedbackCategory category,
      String? appVersion,
      Map<String, dynamic>? deviceInfo,
      String? screenshotUrl,
      FeedbackStatus status,
      FeedbackPriority priority,
      String? assignedTo,
      DateTime? processedAt,
      String? response,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$BetaFeedbackImplCopyWithImpl<$Res>
    extends _$BetaFeedbackCopyWithImpl<$Res, _$BetaFeedbackImpl>
    implements _$$BetaFeedbackImplCopyWith<$Res> {
  __$$BetaFeedbackImplCopyWithImpl(
      _$BetaFeedbackImpl _value, $Res Function(_$BetaFeedbackImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? subject = freezed,
    Object? description = null,
    Object? rating = freezed,
    Object? category = null,
    Object? appVersion = freezed,
    Object? deviceInfo = freezed,
    Object? screenshotUrl = freezed,
    Object? status = null,
    Object? priority = null,
    Object? assignedTo = freezed,
    Object? processedAt = freezed,
    Object? response = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$BetaFeedbackImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      subject: freezed == subject
          ? _value.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as FeedbackCategory,
      appVersion: freezed == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceInfo: freezed == deviceInfo
          ? _value._deviceInfo
          : deviceInfo // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      screenshotUrl: freezed == screenshotUrl
          ? _value.screenshotUrl
          : screenshotUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as FeedbackStatus,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as FeedbackPriority,
      assignedTo: freezed == assignedTo
          ? _value.assignedTo
          : assignedTo // ignore: cast_nullable_to_non_nullable
              as String?,
      processedAt: freezed == processedAt
          ? _value.processedAt
          : processedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      response: freezed == response
          ? _value.response
          : response // ignore: cast_nullable_to_non_nullable
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
class _$BetaFeedbackImpl extends _BetaFeedback {
  const _$BetaFeedbackImpl(
      {required this.id,
      required this.userId,
      this.subject,
      required this.description,
      this.rating,
      required this.category,
      this.appVersion,
      final Map<String, dynamic>? deviceInfo,
      this.screenshotUrl,
      required this.status,
      required this.priority,
      this.assignedTo,
      this.processedAt,
      this.response,
      required this.createdAt,
      required this.updatedAt})
      : _deviceInfo = deviceInfo,
        super._();

  factory _$BetaFeedbackImpl.fromJson(Map<String, dynamic> json) =>
      _$$BetaFeedbackImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String? subject;
  @override
  final String description;
  @override
  final int? rating;
  @override
  final FeedbackCategory category;
  @override
  final String? appVersion;
  final Map<String, dynamic>? _deviceInfo;
  @override
  Map<String, dynamic>? get deviceInfo {
    final value = _deviceInfo;
    if (value == null) return null;
    if (_deviceInfo is EqualUnmodifiableMapView) return _deviceInfo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? screenshotUrl;
  @override
  final FeedbackStatus status;
  @override
  final FeedbackPriority priority;
  @override
  final String? assignedTo;
  @override
  final DateTime? processedAt;
  @override
  final String? response;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'BetaFeedback(id: $id, userId: $userId, subject: $subject, description: $description, rating: $rating, category: $category, appVersion: $appVersion, deviceInfo: $deviceInfo, screenshotUrl: $screenshotUrl, status: $status, priority: $priority, assignedTo: $assignedTo, processedAt: $processedAt, response: $response, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BetaFeedbackImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion) &&
            const DeepCollectionEquality()
                .equals(other._deviceInfo, _deviceInfo) &&
            (identical(other.screenshotUrl, screenshotUrl) ||
                other.screenshotUrl == screenshotUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.assignedTo, assignedTo) ||
                other.assignedTo == assignedTo) &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt) &&
            (identical(other.response, response) ||
                other.response == response) &&
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
      subject,
      description,
      rating,
      category,
      appVersion,
      const DeepCollectionEquality().hash(_deviceInfo),
      screenshotUrl,
      status,
      priority,
      assignedTo,
      processedAt,
      response,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BetaFeedbackImplCopyWith<_$BetaFeedbackImpl> get copyWith =>
      __$$BetaFeedbackImplCopyWithImpl<_$BetaFeedbackImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BetaFeedbackImplToJson(
      this,
    );
  }
}

abstract class _BetaFeedback extends BetaFeedback {
  const factory _BetaFeedback(
      {required final String id,
      required final String userId,
      final String? subject,
      required final String description,
      final int? rating,
      required final FeedbackCategory category,
      final String? appVersion,
      final Map<String, dynamic>? deviceInfo,
      final String? screenshotUrl,
      required final FeedbackStatus status,
      required final FeedbackPriority priority,
      final String? assignedTo,
      final DateTime? processedAt,
      final String? response,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$BetaFeedbackImpl;
  const _BetaFeedback._() : super._();

  factory _BetaFeedback.fromJson(Map<String, dynamic> json) =
      _$BetaFeedbackImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String? get subject;
  @override
  String get description;
  @override
  int? get rating;
  @override
  FeedbackCategory get category;
  @override
  String? get appVersion;
  @override
  Map<String, dynamic>? get deviceInfo;
  @override
  String? get screenshotUrl;
  @override
  FeedbackStatus get status;
  @override
  FeedbackPriority get priority;
  @override
  String? get assignedTo;
  @override
  DateTime? get processedAt;
  @override
  String? get response;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$BetaFeedbackImplCopyWith<_$BetaFeedbackImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QuickFeedback _$QuickFeedbackFromJson(Map<String, dynamic> json) {
  return _QuickFeedback.fromJson(json);
}

/// @nodoc
mixin _$QuickFeedback {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  bool get positive => throw _privateConstructorUsedError;
  String get context => throw _privateConstructorUsedError;
  String? get sessionId => throw _privateConstructorUsedError;
  Map<String, dynamic>? get deviceInfo => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuickFeedbackCopyWith<QuickFeedback> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuickFeedbackCopyWith<$Res> {
  factory $QuickFeedbackCopyWith(
          QuickFeedback value, $Res Function(QuickFeedback) then) =
      _$QuickFeedbackCopyWithImpl<$Res, QuickFeedback>;
  @useResult
  $Res call(
      {String id,
      String userId,
      bool positive,
      String context,
      String? sessionId,
      Map<String, dynamic>? deviceInfo,
      DateTime createdAt});
}

/// @nodoc
class _$QuickFeedbackCopyWithImpl<$Res, $Val extends QuickFeedback>
    implements $QuickFeedbackCopyWith<$Res> {
  _$QuickFeedbackCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? positive = null,
    Object? context = null,
    Object? sessionId = freezed,
    Object? deviceInfo = freezed,
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
      positive: null == positive
          ? _value.positive
          : positive // ignore: cast_nullable_to_non_nullable
              as bool,
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: freezed == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceInfo: freezed == deviceInfo
          ? _value.deviceInfo
          : deviceInfo // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuickFeedbackImplCopyWith<$Res>
    implements $QuickFeedbackCopyWith<$Res> {
  factory _$$QuickFeedbackImplCopyWith(
          _$QuickFeedbackImpl value, $Res Function(_$QuickFeedbackImpl) then) =
      __$$QuickFeedbackImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      bool positive,
      String context,
      String? sessionId,
      Map<String, dynamic>? deviceInfo,
      DateTime createdAt});
}

/// @nodoc
class __$$QuickFeedbackImplCopyWithImpl<$Res>
    extends _$QuickFeedbackCopyWithImpl<$Res, _$QuickFeedbackImpl>
    implements _$$QuickFeedbackImplCopyWith<$Res> {
  __$$QuickFeedbackImplCopyWithImpl(
      _$QuickFeedbackImpl _value, $Res Function(_$QuickFeedbackImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? positive = null,
    Object? context = null,
    Object? sessionId = freezed,
    Object? deviceInfo = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$QuickFeedbackImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      positive: null == positive
          ? _value.positive
          : positive // ignore: cast_nullable_to_non_nullable
              as bool,
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: freezed == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceInfo: freezed == deviceInfo
          ? _value._deviceInfo
          : deviceInfo // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuickFeedbackImpl implements _QuickFeedback {
  const _$QuickFeedbackImpl(
      {required this.id,
      required this.userId,
      required this.positive,
      required this.context,
      this.sessionId,
      final Map<String, dynamic>? deviceInfo,
      required this.createdAt})
      : _deviceInfo = deviceInfo;

  factory _$QuickFeedbackImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuickFeedbackImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final bool positive;
  @override
  final String context;
  @override
  final String? sessionId;
  final Map<String, dynamic>? _deviceInfo;
  @override
  Map<String, dynamic>? get deviceInfo {
    final value = _deviceInfo;
    if (value == null) return null;
    if (_deviceInfo is EqualUnmodifiableMapView) return _deviceInfo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'QuickFeedback(id: $id, userId: $userId, positive: $positive, context: $context, sessionId: $sessionId, deviceInfo: $deviceInfo, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuickFeedbackImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.positive, positive) ||
                other.positive == positive) &&
            (identical(other.context, context) || other.context == context) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            const DeepCollectionEquality()
                .equals(other._deviceInfo, _deviceInfo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, positive, context,
      sessionId, const DeepCollectionEquality().hash(_deviceInfo), createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuickFeedbackImplCopyWith<_$QuickFeedbackImpl> get copyWith =>
      __$$QuickFeedbackImplCopyWithImpl<_$QuickFeedbackImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuickFeedbackImplToJson(
      this,
    );
  }
}

abstract class _QuickFeedback implements QuickFeedback {
  const factory _QuickFeedback(
      {required final String id,
      required final String userId,
      required final bool positive,
      required final String context,
      final String? sessionId,
      final Map<String, dynamic>? deviceInfo,
      required final DateTime createdAt}) = _$QuickFeedbackImpl;

  factory _QuickFeedback.fromJson(Map<String, dynamic> json) =
      _$QuickFeedbackImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  bool get positive;
  @override
  String get context;
  @override
  String? get sessionId;
  @override
  Map<String, dynamic>? get deviceInfo;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$QuickFeedbackImplCopyWith<_$QuickFeedbackImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FeedbackMetrics _$FeedbackMetricsFromJson(Map<String, dynamic> json) {
  return _FeedbackMetrics.fromJson(json);
}

/// @nodoc
mixin _$FeedbackMetrics {
  int get totalFeedback => throw _privateConstructorUsedError;
  int get newFeedback => throw _privateConstructorUsedError;
  int get resolvedFeedback => throw _privateConstructorUsedError;
  double get averageRating => throw _privateConstructorUsedError;
  Map<String, int> get categoryBreakdown => throw _privateConstructorUsedError;
  Map<String, int> get statusBreakdown => throw _privateConstructorUsedError;
  DateTime get lastUpdated => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FeedbackMetricsCopyWith<FeedbackMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedbackMetricsCopyWith<$Res> {
  factory $FeedbackMetricsCopyWith(
          FeedbackMetrics value, $Res Function(FeedbackMetrics) then) =
      _$FeedbackMetricsCopyWithImpl<$Res, FeedbackMetrics>;
  @useResult
  $Res call(
      {int totalFeedback,
      int newFeedback,
      int resolvedFeedback,
      double averageRating,
      Map<String, int> categoryBreakdown,
      Map<String, int> statusBreakdown,
      DateTime lastUpdated});
}

/// @nodoc
class _$FeedbackMetricsCopyWithImpl<$Res, $Val extends FeedbackMetrics>
    implements $FeedbackMetricsCopyWith<$Res> {
  _$FeedbackMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalFeedback = null,
    Object? newFeedback = null,
    Object? resolvedFeedback = null,
    Object? averageRating = null,
    Object? categoryBreakdown = null,
    Object? statusBreakdown = null,
    Object? lastUpdated = null,
  }) {
    return _then(_value.copyWith(
      totalFeedback: null == totalFeedback
          ? _value.totalFeedback
          : totalFeedback // ignore: cast_nullable_to_non_nullable
              as int,
      newFeedback: null == newFeedback
          ? _value.newFeedback
          : newFeedback // ignore: cast_nullable_to_non_nullable
              as int,
      resolvedFeedback: null == resolvedFeedback
          ? _value.resolvedFeedback
          : resolvedFeedback // ignore: cast_nullable_to_non_nullable
              as int,
      averageRating: null == averageRating
          ? _value.averageRating
          : averageRating // ignore: cast_nullable_to_non_nullable
              as double,
      categoryBreakdown: null == categoryBreakdown
          ? _value.categoryBreakdown
          : categoryBreakdown // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      statusBreakdown: null == statusBreakdown
          ? _value.statusBreakdown
          : statusBreakdown // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeedbackMetricsImplCopyWith<$Res>
    implements $FeedbackMetricsCopyWith<$Res> {
  factory _$$FeedbackMetricsImplCopyWith(_$FeedbackMetricsImpl value,
          $Res Function(_$FeedbackMetricsImpl) then) =
      __$$FeedbackMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int totalFeedback,
      int newFeedback,
      int resolvedFeedback,
      double averageRating,
      Map<String, int> categoryBreakdown,
      Map<String, int> statusBreakdown,
      DateTime lastUpdated});
}

/// @nodoc
class __$$FeedbackMetricsImplCopyWithImpl<$Res>
    extends _$FeedbackMetricsCopyWithImpl<$Res, _$FeedbackMetricsImpl>
    implements _$$FeedbackMetricsImplCopyWith<$Res> {
  __$$FeedbackMetricsImplCopyWithImpl(
      _$FeedbackMetricsImpl _value, $Res Function(_$FeedbackMetricsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalFeedback = null,
    Object? newFeedback = null,
    Object? resolvedFeedback = null,
    Object? averageRating = null,
    Object? categoryBreakdown = null,
    Object? statusBreakdown = null,
    Object? lastUpdated = null,
  }) {
    return _then(_$FeedbackMetricsImpl(
      totalFeedback: null == totalFeedback
          ? _value.totalFeedback
          : totalFeedback // ignore: cast_nullable_to_non_nullable
              as int,
      newFeedback: null == newFeedback
          ? _value.newFeedback
          : newFeedback // ignore: cast_nullable_to_non_nullable
              as int,
      resolvedFeedback: null == resolvedFeedback
          ? _value.resolvedFeedback
          : resolvedFeedback // ignore: cast_nullable_to_non_nullable
              as int,
      averageRating: null == averageRating
          ? _value.averageRating
          : averageRating // ignore: cast_nullable_to_non_nullable
              as double,
      categoryBreakdown: null == categoryBreakdown
          ? _value._categoryBreakdown
          : categoryBreakdown // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      statusBreakdown: null == statusBreakdown
          ? _value._statusBreakdown
          : statusBreakdown // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedbackMetricsImpl extends _FeedbackMetrics {
  const _$FeedbackMetricsImpl(
      {required this.totalFeedback,
      required this.newFeedback,
      required this.resolvedFeedback,
      required this.averageRating,
      required final Map<String, int> categoryBreakdown,
      required final Map<String, int> statusBreakdown,
      required this.lastUpdated})
      : _categoryBreakdown = categoryBreakdown,
        _statusBreakdown = statusBreakdown,
        super._();

  factory _$FeedbackMetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedbackMetricsImplFromJson(json);

  @override
  final int totalFeedback;
  @override
  final int newFeedback;
  @override
  final int resolvedFeedback;
  @override
  final double averageRating;
  final Map<String, int> _categoryBreakdown;
  @override
  Map<String, int> get categoryBreakdown {
    if (_categoryBreakdown is EqualUnmodifiableMapView)
      return _categoryBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_categoryBreakdown);
  }

  final Map<String, int> _statusBreakdown;
  @override
  Map<String, int> get statusBreakdown {
    if (_statusBreakdown is EqualUnmodifiableMapView) return _statusBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_statusBreakdown);
  }

  @override
  final DateTime lastUpdated;

  @override
  String toString() {
    return 'FeedbackMetrics(totalFeedback: $totalFeedback, newFeedback: $newFeedback, resolvedFeedback: $resolvedFeedback, averageRating: $averageRating, categoryBreakdown: $categoryBreakdown, statusBreakdown: $statusBreakdown, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedbackMetricsImpl &&
            (identical(other.totalFeedback, totalFeedback) ||
                other.totalFeedback == totalFeedback) &&
            (identical(other.newFeedback, newFeedback) ||
                other.newFeedback == newFeedback) &&
            (identical(other.resolvedFeedback, resolvedFeedback) ||
                other.resolvedFeedback == resolvedFeedback) &&
            (identical(other.averageRating, averageRating) ||
                other.averageRating == averageRating) &&
            const DeepCollectionEquality()
                .equals(other._categoryBreakdown, _categoryBreakdown) &&
            const DeepCollectionEquality()
                .equals(other._statusBreakdown, _statusBreakdown) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalFeedback,
      newFeedback,
      resolvedFeedback,
      averageRating,
      const DeepCollectionEquality().hash(_categoryBreakdown),
      const DeepCollectionEquality().hash(_statusBreakdown),
      lastUpdated);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedbackMetricsImplCopyWith<_$FeedbackMetricsImpl> get copyWith =>
      __$$FeedbackMetricsImplCopyWithImpl<_$FeedbackMetricsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedbackMetricsImplToJson(
      this,
    );
  }
}

abstract class _FeedbackMetrics extends FeedbackMetrics {
  const factory _FeedbackMetrics(
      {required final int totalFeedback,
      required final int newFeedback,
      required final int resolvedFeedback,
      required final double averageRating,
      required final Map<String, int> categoryBreakdown,
      required final Map<String, int> statusBreakdown,
      required final DateTime lastUpdated}) = _$FeedbackMetricsImpl;
  const _FeedbackMetrics._() : super._();

  factory _FeedbackMetrics.fromJson(Map<String, dynamic> json) =
      _$FeedbackMetricsImpl.fromJson;

  @override
  int get totalFeedback;
  @override
  int get newFeedback;
  @override
  int get resolvedFeedback;
  @override
  double get averageRating;
  @override
  Map<String, int> get categoryBreakdown;
  @override
  Map<String, int> get statusBreakdown;
  @override
  DateTime get lastUpdated;
  @override
  @JsonKey(ignore: true)
  _$$FeedbackMetricsImplCopyWith<_$FeedbackMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
