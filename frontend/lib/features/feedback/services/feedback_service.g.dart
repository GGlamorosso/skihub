// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedbackServiceHash() => r'cc51400b118f4ca6ff50eef93b3703b9246dd070';

/// See also [feedbackService].
@ProviderFor(feedbackService)
final feedbackServiceProvider = AutoDisposeProvider<FeedbackService>.internal(
  feedbackService,
  name: r'feedbackServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedbackServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FeedbackServiceRef = AutoDisposeProviderRef<FeedbackService>;
String _$userFeedbackHistoryHash() =>
    r'23ef2dbdf64afa9a26666daaee4afe29b78211a4';

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

abstract class _$UserFeedbackHistory
    extends BuildlessAutoDisposeNotifier<AsyncValue<List<BetaFeedback>>> {
  late final String userId;

  AsyncValue<List<BetaFeedback>> build(
    String userId,
  );
}

/// See also [UserFeedbackHistory].
@ProviderFor(UserFeedbackHistory)
const userFeedbackHistoryProvider = UserFeedbackHistoryFamily();

/// See also [UserFeedbackHistory].
class UserFeedbackHistoryFamily extends Family<AsyncValue<List<BetaFeedback>>> {
  /// See also [UserFeedbackHistory].
  const UserFeedbackHistoryFamily();

  /// See also [UserFeedbackHistory].
  UserFeedbackHistoryProvider call(
    String userId,
  ) {
    return UserFeedbackHistoryProvider(
      userId,
    );
  }

  @override
  UserFeedbackHistoryProvider getProviderOverride(
    covariant UserFeedbackHistoryProvider provider,
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
  String? get name => r'userFeedbackHistoryProvider';
}

/// See also [UserFeedbackHistory].
class UserFeedbackHistoryProvider extends AutoDisposeNotifierProviderImpl<
    UserFeedbackHistory, AsyncValue<List<BetaFeedback>>> {
  /// See also [UserFeedbackHistory].
  UserFeedbackHistoryProvider(
    String userId,
  ) : this._internal(
          () => UserFeedbackHistory()..userId = userId,
          from: userFeedbackHistoryProvider,
          name: r'userFeedbackHistoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userFeedbackHistoryHash,
          dependencies: UserFeedbackHistoryFamily._dependencies,
          allTransitiveDependencies:
              UserFeedbackHistoryFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserFeedbackHistoryProvider._internal(
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
  AsyncValue<List<BetaFeedback>> runNotifierBuild(
    covariant UserFeedbackHistory notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(UserFeedbackHistory Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserFeedbackHistoryProvider._internal(
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
  AutoDisposeNotifierProviderElement<UserFeedbackHistory,
      AsyncValue<List<BetaFeedback>>> createElement() {
    return _UserFeedbackHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserFeedbackHistoryProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserFeedbackHistoryRef
    on AutoDisposeNotifierProviderRef<AsyncValue<List<BetaFeedback>>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserFeedbackHistoryProviderElement
    extends AutoDisposeNotifierProviderElement<UserFeedbackHistory,
        AsyncValue<List<BetaFeedback>>> with UserFeedbackHistoryRef {
  _UserFeedbackHistoryProviderElement(super.provider);

  @override
  String get userId => (origin as UserFeedbackHistoryProvider).userId;
}

String _$quickFeedbackStateHash() =>
    r'072b843f06e8169670b43b0bb40f13bdd1a1f64b';

abstract class _$QuickFeedbackState extends BuildlessAutoDisposeNotifier<bool> {
  late final String userId;

  bool build(
    String userId,
  );
}

/// See also [QuickFeedbackState].
@ProviderFor(QuickFeedbackState)
const quickFeedbackStateProvider = QuickFeedbackStateFamily();

/// See also [QuickFeedbackState].
class QuickFeedbackStateFamily extends Family<bool> {
  /// See also [QuickFeedbackState].
  const QuickFeedbackStateFamily();

  /// See also [QuickFeedbackState].
  QuickFeedbackStateProvider call(
    String userId,
  ) {
    return QuickFeedbackStateProvider(
      userId,
    );
  }

  @override
  QuickFeedbackStateProvider getProviderOverride(
    covariant QuickFeedbackStateProvider provider,
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
  String? get name => r'quickFeedbackStateProvider';
}

/// See also [QuickFeedbackState].
class QuickFeedbackStateProvider
    extends AutoDisposeNotifierProviderImpl<QuickFeedbackState, bool> {
  /// See also [QuickFeedbackState].
  QuickFeedbackStateProvider(
    String userId,
  ) : this._internal(
          () => QuickFeedbackState()..userId = userId,
          from: quickFeedbackStateProvider,
          name: r'quickFeedbackStateProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$quickFeedbackStateHash,
          dependencies: QuickFeedbackStateFamily._dependencies,
          allTransitiveDependencies:
              QuickFeedbackStateFamily._allTransitiveDependencies,
          userId: userId,
        );

  QuickFeedbackStateProvider._internal(
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
  bool runNotifierBuild(
    covariant QuickFeedbackState notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(QuickFeedbackState Function() create) {
    return ProviderOverride(
      origin: this,
      override: QuickFeedbackStateProvider._internal(
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
  AutoDisposeNotifierProviderElement<QuickFeedbackState, bool> createElement() {
    return _QuickFeedbackStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is QuickFeedbackStateProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin QuickFeedbackStateRef on AutoDisposeNotifierProviderRef<bool> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _QuickFeedbackStateProviderElement
    extends AutoDisposeNotifierProviderElement<QuickFeedbackState, bool>
    with QuickFeedbackStateRef {
  _QuickFeedbackStateProviderElement(super.provider);

  @override
  String get userId => (origin as QuickFeedbackStateProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
