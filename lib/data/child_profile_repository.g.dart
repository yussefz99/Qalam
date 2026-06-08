// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child_profile_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [ChildProfileRepository] — keepAlive mirrors the
/// appDatabaseProvider / progressRepository pattern (D-11).

@ProviderFor(childProfileRepository)
final childProfileRepositoryProvider = ChildProfileRepositoryProvider._();

/// Riverpod provider for [ChildProfileRepository] — keepAlive mirrors the
/// appDatabaseProvider / progressRepository pattern (D-11).

final class ChildProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ChildProfileRepository,
          ChildProfileRepository,
          ChildProfileRepository
        >
    with $Provider<ChildProfileRepository> {
  /// Riverpod provider for [ChildProfileRepository] — keepAlive mirrors the
  /// appDatabaseProvider / progressRepository pattern (D-11).
  ChildProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'childProfileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$childProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChildProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChildProfileRepository create(Ref ref) {
    return childProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChildProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChildProfileRepository>(value),
    );
  }
}

String _$childProfileRepositoryHash() =>
    r'3b689e35b1f44015343b707b7d21294a4cfafff5';
