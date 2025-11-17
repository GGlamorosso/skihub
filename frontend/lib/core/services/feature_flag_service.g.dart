// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_flag_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$featureFlagServiceHash() =>
    r'9190df92f4363a266b6fae40fd0186b198725e32';

/// See also [featureFlagService].
@ProviderFor(featureFlagService)
final featureFlagServiceProvider =
    AutoDisposeProvider<FeatureFlagService>.internal(
  featureFlagService,
  name: r'featureFlagServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$featureFlagServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FeatureFlagServiceRef = AutoDisposeProviderRef<FeatureFlagService>;
String _$userFeatureFlagsHash() => r'decd75b431850efbcd0f9eb0f79bf7d79189a85e';

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

abstract class _$UserFeatureFlags
    extends BuildlessAutoDisposeNotifier<AsyncValue<Map<String, bool>>> {
  late final String? userId;

  AsyncValue<Map<String, bool>> build(
    String? userId,
  );
}

/// See also [UserFeatureFlags].
@ProviderFor(UserFeatureFlags)
const userFeatureFlagsProvider = UserFeatureFlagsFamily();

/// See also [UserFeatureFlags].
class UserFeatureFlagsFamily extends Family<AsyncValue<Map<String, bool>>> {
  /// See also [UserFeatureFlags].
  const UserFeatureFlagsFamily();

  /// See also [UserFeatureFlags].
  UserFeatureFlagsProvider call(
    String? userId,
  ) {
    return UserFeatureFlagsProvider(
      userId,
    );
  }

  @override
  UserFeatureFlagsProvider getProviderOverride(
    covariant UserFeatureFlagsProvider provider,
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
  String? get name => r'userFeatureFlagsProvider';
}

/// See also [UserFeatureFlags].
class UserFeatureFlagsProvider extends AutoDisposeNotifierProviderImpl<
    UserFeatureFlags, AsyncValue<Map<String, bool>>> {
  /// See also [UserFeatureFlags].
  UserFeatureFlagsProvider(
    String? userId,
  ) : this._internal(
          () => UserFeatureFlags()..userId = userId,
          from: userFeatureFlagsProvider,
          name: r'userFeatureFlagsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userFeatureFlagsHash,
          dependencies: UserFeatureFlagsFamily._dependencies,
          allTransitiveDependencies:
              UserFeatureFlagsFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserFeatureFlagsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String? userId;

  @override
  AsyncValue<Map<String, bool>> runNotifierBuild(
    covariant UserFeatureFlags notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(UserFeatureFlags Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserFeatureFlagsProvider._internal(
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
  AutoDisposeNotifierProviderElement<UserFeatureFlags,
      AsyncValue<Map<String, bool>>> createElement() {
    return _UserFeatureFlagsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserFeatureFlagsProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserFeatureFlagsRef
    on AutoDisposeNotifierProviderRef<AsyncValue<Map<String, bool>>> {
  /// The parameter `userId` of this provider.
  String? get userId;
}

class _UserFeatureFlagsProviderElement
    extends AutoDisposeNotifierProviderElement<UserFeatureFlags,
        AsyncValue<Map<String, bool>>> with UserFeatureFlagsRef {
  _UserFeatureFlagsProviderElement(super.provider);

  @override
  String? get userId => (origin as UserFeatureFlagsProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
