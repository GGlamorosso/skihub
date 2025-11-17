// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quota_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$quotaServiceHash() => r'd9300437429bd8d2397c7d69b5399a52a7c0b55d';

/// See also [quotaService].
@ProviderFor(quotaService)
final quotaServiceProvider = AutoDisposeProvider<QuotaService>.internal(
  quotaService,
  name: r'quotaServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$quotaServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef QuotaServiceRef = AutoDisposeProviderRef<QuotaService>;
String _$premiumRepositoryHash() => r'8bd3c8cfe54bcefc4e59db2ad5ffbd7f04ce9a39';

/// See also [premiumRepository].
@ProviderFor(premiumRepository)
final premiumRepositoryProvider =
    AutoDisposeProvider<PremiumRepository>.internal(
  premiumRepository,
  name: r'premiumRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$premiumRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PremiumRepositoryRef = AutoDisposeProviderRef<PremiumRepository>;
String _$userQuotaStateHash() => r'03b6e51d7dd0c555c165c5fbd844061cc1f79892';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$UserQuotaState
    extends BuildlessAutoDisposeNotifier<QuotaInfo?> {
  late final String userId;

  QuotaInfo? build(
    String userId,
  );
}

/// See also [UserQuotaState].
@ProviderFor(UserQuotaState)
const userQuotaStateProvider = UserQuotaStateFamily();

/// See also [UserQuotaState].
class UserQuotaStateFamily extends Family<QuotaInfo?> {
  /// See also [UserQuotaState].
  const UserQuotaStateFamily();

  /// See also [UserQuotaState].
  UserQuotaStateProvider call(
    String userId,
  ) {
    return UserQuotaStateProvider(
      userId,
    );
  }

  @override
  UserQuotaStateProvider getProviderOverride(
    covariant UserQuotaStateProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userQuotaStateProvider';
}

/// See also [UserQuotaState].
class UserQuotaStateProvider
    extends AutoDisposeNotifierProviderImpl<UserQuotaState, QuotaInfo?> {
  /// See also [UserQuotaState].
  UserQuotaStateProvider(
    String userId,
  ) : this._internal(
          () => UserQuotaState()..userId = userId,
          from: userQuotaStateProvider,
          name: r'userQuotaStateProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userQuotaStateHash,
          dependencies: UserQuotaStateFamily._dependencies,
          allTransitiveDependencies:
              UserQuotaStateFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserQuotaStateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  QuotaInfo? runNotifierBuild(
    covariant UserQuotaState notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(UserQuotaState Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserQuotaStateProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<UserQuotaState, QuotaInfo?>
      createElement() {
    return _UserQuotaStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserQuotaStateProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserQuotaStateRef on AutoDisposeNotifierProviderRef<QuotaInfo?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserQuotaStateProviderElement
    extends AutoDisposeNotifierProviderElement<UserQuotaState, QuotaInfo?>
    with UserQuotaStateRef {
  _UserQuotaStateProviderElement(super.provider);

  @override
  String get userId => (origin as UserQuotaStateProvider).userId;
}

String _$userPremiumStateHash() => r'7e1339e9050ba12619eef7b2f16f1b8205b1246e';

abstract class _$UserPremiumState
    extends BuildlessAutoDisposeNotifier<AsyncValue<bool>> {
  late final String userId;

  AsyncValue<bool> build(
    String userId,
  );
}

/// See also [UserPremiumState].
@ProviderFor(UserPremiumState)
const userPremiumStateProvider = UserPremiumStateFamily();

/// See also [UserPremiumState].
class UserPremiumStateFamily extends Family<AsyncValue<bool>> {
  /// See also [UserPremiumState].
  const UserPremiumStateFamily();

  /// See also [UserPremiumState].
  UserPremiumStateProvider call(
    String userId,
  ) {
    return UserPremiumStateProvider(
      userId,
    );
  }

  @override
  UserPremiumStateProvider getProviderOverride(
    covariant UserPremiumStateProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userPremiumStateProvider';
}

/// See also [UserPremiumState].
class UserPremiumStateProvider extends AutoDisposeNotifierProviderImpl<
    UserPremiumState, AsyncValue<bool>> {
  /// See also [UserPremiumState].
  UserPremiumStateProvider(
    String userId,
  ) : this._internal(
          () => UserPremiumState()..userId = userId,
          from: userPremiumStateProvider,
          name: r'userPremiumStateProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userPremiumStateHash,
          dependencies: UserPremiumStateFamily._dependencies,
          allTransitiveDependencies:
              UserPremiumStateFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserPremiumStateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  AsyncValue<bool> runNotifierBuild(
    covariant UserPremiumState notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(UserPremiumState Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserPremiumStateProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<UserPremiumState, AsyncValue<bool>>
      createElement() {
    return _UserPremiumStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserPremiumStateProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserPremiumStateRef on AutoDisposeNotifierProviderRef<AsyncValue<bool>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserPremiumStateProviderElement
    extends AutoDisposeNotifierProviderElement<UserPremiumState,
        AsyncValue<bool>> with UserPremiumStateRef {
  _UserPremiumStateProviderElement(super.provider);

  @override
  String get userId => (origin as UserPremiumStateProvider).userId;
}

String _$userSubscriptionStateHash() =>
    r'c27d3312cd1b73868b2cdfa36e0a5521df522ee9';

abstract class _$UserSubscriptionState
    extends BuildlessAutoDisposeNotifier<AsyncValue<Subscription?>> {
  late final String userId;

  AsyncValue<Subscription?> build(
    String userId,
  );
}

/// See also [UserSubscriptionState].
@ProviderFor(UserSubscriptionState)
const userSubscriptionStateProvider = UserSubscriptionStateFamily();

/// See also [UserSubscriptionState].
class UserSubscriptionStateFamily extends Family<AsyncValue<Subscription?>> {
  /// See also [UserSubscriptionState].
  const UserSubscriptionStateFamily();

  /// See also [UserSubscriptionState].
  UserSubscriptionStateProvider call(
    String userId,
  ) {
    return UserSubscriptionStateProvider(
      userId,
    );
  }

  @override
  UserSubscriptionStateProvider getProviderOverride(
    covariant UserSubscriptionStateProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userSubscriptionStateProvider';
}

/// See also [UserSubscriptionState].
class UserSubscriptionStateProvider extends AutoDisposeNotifierProviderImpl<
    UserSubscriptionState, AsyncValue<Subscription?>> {
  /// See also [UserSubscriptionState].
  UserSubscriptionStateProvider(
    String userId,
  ) : this._internal(
          () => UserSubscriptionState()..userId = userId,
          from: userSubscriptionStateProvider,
          name: r'userSubscriptionStateProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userSubscriptionStateHash,
          dependencies: UserSubscriptionStateFamily._dependencies,
          allTransitiveDependencies:
              UserSubscriptionStateFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserSubscriptionStateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  AsyncValue<Subscription?> runNotifierBuild(
    covariant UserSubscriptionState notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(UserSubscriptionState Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserSubscriptionStateProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<UserSubscriptionState,
      AsyncValue<Subscription?>> createElement() {
    return _UserSubscriptionStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserSubscriptionStateProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserSubscriptionStateRef
    on AutoDisposeNotifierProviderRef<AsyncValue<Subscription?>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserSubscriptionStateProviderElement
    extends AutoDisposeNotifierProviderElement<UserSubscriptionState,
        AsyncValue<Subscription?>> with UserSubscriptionStateRef {
  _UserSubscriptionStateProviderElement(super.provider);

  @override
  String get userId => (origin as UserSubscriptionStateProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
