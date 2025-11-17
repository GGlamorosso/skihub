// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$privacyServiceHash() => r'20b63dd08bd3beef7fe63a250bbf951a770c4ae0';

/// See also [privacyService].
@ProviderFor(privacyService)
final privacyServiceProvider = AutoDisposeProvider<PrivacyService>.internal(
  privacyService,
  name: r'privacyServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$privacyServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PrivacyServiceRef = AutoDisposeProviderRef<PrivacyService>;
String _$privacySettingsHash() => r'd72f7a7506e464541b446988029dd02ced9c96f6';

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

abstract class _$PrivacySettings
    extends BuildlessAutoDisposeNotifier<AsyncValue<PrivacySettings>> {
  late final String userId;

  AsyncValue<PrivacySettings> build(
    String userId,
  );
}

/// See also [PrivacySettings].
@ProviderFor(PrivacySettings)
const privacySettingsProvider = PrivacySettingsFamily();

/// See also [PrivacySettings].
class PrivacySettingsFamily extends Family<AsyncValue<PrivacySettings>> {
  /// See also [PrivacySettings].
  const PrivacySettingsFamily();

  /// See also [PrivacySettings].
  PrivacySettingsProvider call(
    String userId,
  ) {
    return PrivacySettingsProvider(
      userId,
    );
  }

  @override
  PrivacySettingsProvider getProviderOverride(
    covariant PrivacySettingsProvider provider,
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
  String? get name => r'privacySettingsProvider';
}

/// See also [PrivacySettings].
class PrivacySettingsProvider extends AutoDisposeNotifierProviderImpl<
    PrivacySettings, AsyncValue<PrivacySettings>> {
  /// See also [PrivacySettings].
  PrivacySettingsProvider(
    String userId,
  ) : this._internal(
          () => PrivacySettings()..userId = userId,
          from: privacySettingsProvider,
          name: r'privacySettingsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$privacySettingsHash,
          dependencies: PrivacySettingsFamily._dependencies,
          allTransitiveDependencies:
              PrivacySettingsFamily._allTransitiveDependencies,
          userId: userId,
        );

  PrivacySettingsProvider._internal(
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
  AsyncValue<PrivacySettings> runNotifierBuild(
    covariant PrivacySettings notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(PrivacySettings Function() create) {
    return ProviderOverride(
      origin: this,
      override: PrivacySettingsProvider._internal(
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
  AutoDisposeNotifierProviderElement<PrivacySettings,
      AsyncValue<PrivacySettings>> createElement() {
    return _PrivacySettingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PrivacySettingsProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PrivacySettingsRef
    on AutoDisposeNotifierProviderRef<AsyncValue<PrivacySettings>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _PrivacySettingsProviderElement
    extends AutoDisposeNotifierProviderElement<PrivacySettings,
        AsyncValue<PrivacySettings>> with PrivacySettingsRef {
  _PrivacySettingsProviderElement(super.provider);

  @override
  String get userId => (origin as PrivacySettingsProvider).userId;
}

String _$userConsentsHash() => r'9a17aa76f6e6ad49ba481135382790bbcfac4337';

abstract class _$UserConsents
    extends BuildlessAutoDisposeNotifier<AsyncValue<List<Consent>>> {
  late final String userId;

  AsyncValue<List<Consent>> build(
    String userId,
  );
}

/// See also [UserConsents].
@ProviderFor(UserConsents)
const userConsentsProvider = UserConsentsFamily();

/// See also [UserConsents].
class UserConsentsFamily extends Family<AsyncValue<List<Consent>>> {
  /// See also [UserConsents].
  const UserConsentsFamily();

  /// See also [UserConsents].
  UserConsentsProvider call(
    String userId,
  ) {
    return UserConsentsProvider(
      userId,
    );
  }

  @override
  UserConsentsProvider getProviderOverride(
    covariant UserConsentsProvider provider,
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
  String? get name => r'userConsentsProvider';
}

/// See also [UserConsents].
class UserConsentsProvider extends AutoDisposeNotifierProviderImpl<UserConsents,
    AsyncValue<List<Consent>>> {
  /// See also [UserConsents].
  UserConsentsProvider(
    String userId,
  ) : this._internal(
          () => UserConsents()..userId = userId,
          from: userConsentsProvider,
          name: r'userConsentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userConsentsHash,
          dependencies: UserConsentsFamily._dependencies,
          allTransitiveDependencies:
              UserConsentsFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserConsentsProvider._internal(
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
  AsyncValue<List<Consent>> runNotifierBuild(
    covariant UserConsents notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(UserConsents Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserConsentsProvider._internal(
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
  AutoDisposeNotifierProviderElement<UserConsents, AsyncValue<List<Consent>>>
      createElement() {
    return _UserConsentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserConsentsProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserConsentsRef
    on AutoDisposeNotifierProviderRef<AsyncValue<List<Consent>>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserConsentsProviderElement extends AutoDisposeNotifierProviderElement<
    UserConsents, AsyncValue<List<Consent>>> with UserConsentsRef {
  _UserConsentsProviderElement(super.provider);

  @override
  String get userId => (origin as UserConsentsProvider).userId;
}

String _$verificationStatusHash() =>
    r'db144f98838f27b1ae0143d6d8eeb69b5b5bc00a';

abstract class _$VerificationStatus
    extends BuildlessAutoDisposeNotifier<AsyncValue<VerificationRequest?>> {
  late final String userId;

  AsyncValue<VerificationRequest?> build(
    String userId,
  );
}

/// See also [VerificationStatus].
@ProviderFor(VerificationStatus)
const verificationStatusProvider = VerificationStatusFamily();

/// See also [VerificationStatus].
class VerificationStatusFamily
    extends Family<AsyncValue<VerificationRequest?>> {
  /// See also [VerificationStatus].
  const VerificationStatusFamily();

  /// See also [VerificationStatus].
  VerificationStatusProvider call(
    String userId,
  ) {
    return VerificationStatusProvider(
      userId,
    );
  }

  @override
  VerificationStatusProvider getProviderOverride(
    covariant VerificationStatusProvider provider,
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
  String? get name => r'verificationStatusProvider';
}

/// See also [VerificationStatus].
class VerificationStatusProvider extends AutoDisposeNotifierProviderImpl<
    VerificationStatus, AsyncValue<VerificationRequest?>> {
  /// See also [VerificationStatus].
  VerificationStatusProvider(
    String userId,
  ) : this._internal(
          () => VerificationStatus()..userId = userId,
          from: verificationStatusProvider,
          name: r'verificationStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$verificationStatusHash,
          dependencies: VerificationStatusFamily._dependencies,
          allTransitiveDependencies:
              VerificationStatusFamily._allTransitiveDependencies,
          userId: userId,
        );

  VerificationStatusProvider._internal(
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
  AsyncValue<VerificationRequest?> runNotifierBuild(
    covariant VerificationStatus notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(VerificationStatus Function() create) {
    return ProviderOverride(
      origin: this,
      override: VerificationStatusProvider._internal(
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
  AutoDisposeNotifierProviderElement<VerificationStatus,
      AsyncValue<VerificationRequest?>> createElement() {
    return _VerificationStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VerificationStatusProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin VerificationStatusRef
    on AutoDisposeNotifierProviderRef<AsyncValue<VerificationRequest?>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _VerificationStatusProviderElement
    extends AutoDisposeNotifierProviderElement<VerificationStatus,
        AsyncValue<VerificationRequest?>> with VerificationStatusRef {
  _VerificationStatusProviderElement(super.provider);

  @override
  String get userId => (origin as VerificationStatusProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
