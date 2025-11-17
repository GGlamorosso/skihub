// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_assistant_button.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$consentCheckHash() => r'6b3f5c2c6da0948c32df9c1aa41d8fd63cc9ec00';

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

/// See also [consentCheck].
@ProviderFor(consentCheck)
const consentCheckProvider = ConsentCheckFamily();

/// See also [consentCheck].
class ConsentCheckFamily extends Family<AsyncValue<bool>> {
  /// See also [consentCheck].
  const ConsentCheckFamily();

  /// See also [consentCheck].
  ConsentCheckProvider call(
    String userId,
    String purpose,
  ) {
    return ConsentCheckProvider(
      userId,
      purpose,
    );
  }

  @override
  ConsentCheckProvider getProviderOverride(
    covariant ConsentCheckProvider provider,
  ) {
    return call(
      provider.userId,
      provider.purpose,
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
  String? get name => r'consentCheckProvider';
}

/// See also [consentCheck].
class ConsentCheckProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [consentCheck].
  ConsentCheckProvider(
    String userId,
    String purpose,
  ) : this._internal(
          (ref) => consentCheck(
            ref as ConsentCheckRef,
            userId,
            purpose,
          ),
          from: consentCheckProvider,
          name: r'consentCheckProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$consentCheckHash,
          dependencies: ConsentCheckFamily._dependencies,
          allTransitiveDependencies:
              ConsentCheckFamily._allTransitiveDependencies,
          userId: userId,
          purpose: purpose,
        );

  ConsentCheckProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.purpose,
  }) : super.internal();

  final String userId;
  final String purpose;

  @override
  Override overrideWith(
    FutureOr<bool> Function(ConsentCheckRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConsentCheckProvider._internal(
        (ref) => create(ref as ConsentCheckRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        purpose: purpose,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _ConsentCheckProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConsentCheckProvider &&
        other.userId == userId &&
        other.purpose == purpose;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, purpose.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ConsentCheckRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `purpose` of this provider.
  String get purpose;
}

class _ConsentCheckProviderElement
    extends AutoDisposeFutureProviderElement<bool> with ConsentCheckRef {
  _ConsentCheckProviderElement(super.provider);

  @override
  String get userId => (origin as ConsentCheckProvider).userId;
  @override
  String get purpose => (origin as ConsentCheckProvider).purpose;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
