// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'premium_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PremiumState {
  bool get isPremium => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  Subscription? get subscription => throw _privateConstructorUsedError;
  List<Boost> get activeBoosts => throw _privateConstructorUsedError;
  QuotaInfo? get quotaInfo => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get showPaywall => throw _privateConstructorUsedError;
  bool get quotaModalShown => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PremiumStateCopyWith<PremiumState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PremiumStateCopyWith<$Res> {
  factory $PremiumStateCopyWith(
          PremiumState value, $Res Function(PremiumState) then) =
      _$PremiumStateCopyWithImpl<$Res, PremiumState>;
  @useResult
  $Res call(
      {bool isPremium,
      bool isLoading,
      Subscription? subscription,
      List<Boost> activeBoosts,
      QuotaInfo? quotaInfo,
      String? error,
      bool showPaywall,
      bool quotaModalShown});

  $SubscriptionCopyWith<$Res>? get subscription;
  $QuotaInfoCopyWith<$Res>? get quotaInfo;
}

/// @nodoc
class _$PremiumStateCopyWithImpl<$Res, $Val extends PremiumState>
    implements $PremiumStateCopyWith<$Res> {
  _$PremiumStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPremium = null,
    Object? isLoading = null,
    Object? subscription = freezed,
    Object? activeBoosts = null,
    Object? quotaInfo = freezed,
    Object? error = freezed,
    Object? showPaywall = null,
    Object? quotaModalShown = null,
  }) {
    return _then(_value.copyWith(
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      subscription: freezed == subscription
          ? _value.subscription
          : subscription // ignore: cast_nullable_to_non_nullable
              as Subscription?,
      activeBoosts: null == activeBoosts
          ? _value.activeBoosts
          : activeBoosts // ignore: cast_nullable_to_non_nullable
              as List<Boost>,
      quotaInfo: freezed == quotaInfo
          ? _value.quotaInfo
          : quotaInfo // ignore: cast_nullable_to_non_nullable
              as QuotaInfo?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      showPaywall: null == showPaywall
          ? _value.showPaywall
          : showPaywall // ignore: cast_nullable_to_non_nullable
              as bool,
      quotaModalShown: null == quotaModalShown
          ? _value.quotaModalShown
          : quotaModalShown // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SubscriptionCopyWith<$Res>? get subscription {
    if (_value.subscription == null) {
      return null;
    }

    return $SubscriptionCopyWith<$Res>(_value.subscription!, (value) {
      return _then(_value.copyWith(subscription: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $QuotaInfoCopyWith<$Res>? get quotaInfo {
    if (_value.quotaInfo == null) {
      return null;
    }

    return $QuotaInfoCopyWith<$Res>(_value.quotaInfo!, (value) {
      return _then(_value.copyWith(quotaInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PremiumStateImplCopyWith<$Res>
    implements $PremiumStateCopyWith<$Res> {
  factory _$$PremiumStateImplCopyWith(
          _$PremiumStateImpl value, $Res Function(_$PremiumStateImpl) then) =
      __$$PremiumStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isPremium,
      bool isLoading,
      Subscription? subscription,
      List<Boost> activeBoosts,
      QuotaInfo? quotaInfo,
      String? error,
      bool showPaywall,
      bool quotaModalShown});

  @override
  $SubscriptionCopyWith<$Res>? get subscription;
  @override
  $QuotaInfoCopyWith<$Res>? get quotaInfo;
}

/// @nodoc
class __$$PremiumStateImplCopyWithImpl<$Res>
    extends _$PremiumStateCopyWithImpl<$Res, _$PremiumStateImpl>
    implements _$$PremiumStateImplCopyWith<$Res> {
  __$$PremiumStateImplCopyWithImpl(
      _$PremiumStateImpl _value, $Res Function(_$PremiumStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPremium = null,
    Object? isLoading = null,
    Object? subscription = freezed,
    Object? activeBoosts = null,
    Object? quotaInfo = freezed,
    Object? error = freezed,
    Object? showPaywall = null,
    Object? quotaModalShown = null,
  }) {
    return _then(_$PremiumStateImpl(
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      subscription: freezed == subscription
          ? _value.subscription
          : subscription // ignore: cast_nullable_to_non_nullable
              as Subscription?,
      activeBoosts: null == activeBoosts
          ? _value._activeBoosts
          : activeBoosts // ignore: cast_nullable_to_non_nullable
              as List<Boost>,
      quotaInfo: freezed == quotaInfo
          ? _value.quotaInfo
          : quotaInfo // ignore: cast_nullable_to_non_nullable
              as QuotaInfo?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      showPaywall: null == showPaywall
          ? _value.showPaywall
          : showPaywall // ignore: cast_nullable_to_non_nullable
              as bool,
      quotaModalShown: null == quotaModalShown
          ? _value.quotaModalShown
          : quotaModalShown // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$PremiumStateImpl implements _PremiumState {
  const _$PremiumStateImpl(
      {this.isPremium = false,
      this.isLoading = false,
      this.subscription,
      final List<Boost> activeBoosts = const [],
      this.quotaInfo,
      this.error,
      this.showPaywall = false,
      this.quotaModalShown = false})
      : _activeBoosts = activeBoosts;

  @override
  @JsonKey()
  final bool isPremium;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final Subscription? subscription;
  final List<Boost> _activeBoosts;
  @override
  @JsonKey()
  List<Boost> get activeBoosts {
    if (_activeBoosts is EqualUnmodifiableListView) return _activeBoosts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activeBoosts);
  }

  @override
  final QuotaInfo? quotaInfo;
  @override
  final String? error;
  @override
  @JsonKey()
  final bool showPaywall;
  @override
  @JsonKey()
  final bool quotaModalShown;

  @override
  String toString() {
    return 'PremiumState(isPremium: $isPremium, isLoading: $isLoading, subscription: $subscription, activeBoosts: $activeBoosts, quotaInfo: $quotaInfo, error: $error, showPaywall: $showPaywall, quotaModalShown: $quotaModalShown)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PremiumStateImpl &&
            (identical(other.isPremium, isPremium) ||
                other.isPremium == isPremium) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.subscription, subscription) ||
                other.subscription == subscription) &&
            const DeepCollectionEquality()
                .equals(other._activeBoosts, _activeBoosts) &&
            (identical(other.quotaInfo, quotaInfo) ||
                other.quotaInfo == quotaInfo) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.showPaywall, showPaywall) ||
                other.showPaywall == showPaywall) &&
            (identical(other.quotaModalShown, quotaModalShown) ||
                other.quotaModalShown == quotaModalShown));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isPremium,
      isLoading,
      subscription,
      const DeepCollectionEquality().hash(_activeBoosts),
      quotaInfo,
      error,
      showPaywall,
      quotaModalShown);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PremiumStateImplCopyWith<_$PremiumStateImpl> get copyWith =>
      __$$PremiumStateImplCopyWithImpl<_$PremiumStateImpl>(this, _$identity);
}

abstract class _PremiumState implements PremiumState {
  const factory _PremiumState(
      {final bool isPremium,
      final bool isLoading,
      final Subscription? subscription,
      final List<Boost> activeBoosts,
      final QuotaInfo? quotaInfo,
      final String? error,
      final bool showPaywall,
      final bool quotaModalShown}) = _$PremiumStateImpl;

  @override
  bool get isPremium;
  @override
  bool get isLoading;
  @override
  Subscription? get subscription;
  @override
  List<Boost> get activeBoosts;
  @override
  QuotaInfo? get quotaInfo;
  @override
  String? get error;
  @override
  bool get showPaywall;
  @override
  bool get quotaModalShown;
  @override
  @JsonKey(ignore: true)
  _$$PremiumStateImplCopyWith<_$PremiumStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
