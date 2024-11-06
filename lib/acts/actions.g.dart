// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$startActByV2Hash() => r'b509fdc4f82f17319ff6ec0455855f6172aaa91f';

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

/// See also [startActByV2].
@ProviderFor(startActByV2)
const startActByV2Provider = StartActByV2Family();

/// See also [startActByV2].
class StartActByV2Family extends Family<AsyncValue<void>> {
  /// See also [startActByV2].
  const StartActByV2Family();

  /// See also [startActByV2].
  StartActByV2Provider call(
    int memId,
  ) {
    return StartActByV2Provider(
      memId,
    );
  }

  @override
  StartActByV2Provider getProviderOverride(
    covariant StartActByV2Provider provider,
  ) {
    return call(
      provider.memId,
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
  String? get name => r'startActByV2Provider';
}

/// See also [startActByV2].
class StartActByV2Provider extends AutoDisposeFutureProvider<void> {
  /// See also [startActByV2].
  StartActByV2Provider(
    int memId,
  ) : this._internal(
          (ref) => startActByV2(
            ref as StartActByV2Ref,
            memId,
          ),
          from: startActByV2Provider,
          name: r'startActByV2Provider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$startActByV2Hash,
          dependencies: StartActByV2Family._dependencies,
          allTransitiveDependencies:
              StartActByV2Family._allTransitiveDependencies,
          memId: memId,
        );

  StartActByV2Provider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.memId,
  }) : super.internal();

  final int memId;

  @override
  Override overrideWith(
    FutureOr<void> Function(StartActByV2Ref provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StartActByV2Provider._internal(
        (ref) => create(ref as StartActByV2Ref),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        memId: memId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _StartActByV2ProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StartActByV2Provider && other.memId == memId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, memId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StartActByV2Ref on AutoDisposeFutureProviderRef<void> {
  /// The parameter `memId` of this provider.
  int get memId;
}

class _StartActByV2ProviderElement
    extends AutoDisposeFutureProviderElement<void> with StartActByV2Ref {
  _StartActByV2ProviderElement(super.provider);

  @override
  int get memId => (origin as StartActByV2Provider).memId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
