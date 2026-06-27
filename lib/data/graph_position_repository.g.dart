// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph_position_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [GraphPositionRepository] — keepAlive mirrors the
/// appDatabaseProvider / progressRepositoryProvider pattern (D-11).

@ProviderFor(graphPositionRepository)
final graphPositionRepositoryProvider = GraphPositionRepositoryProvider._();

/// Riverpod provider for [GraphPositionRepository] — keepAlive mirrors the
/// appDatabaseProvider / progressRepositoryProvider pattern (D-11).

final class GraphPositionRepositoryProvider
    extends
        $FunctionalProvider<
          GraphPositionRepository,
          GraphPositionRepository,
          GraphPositionRepository
        >
    with $Provider<GraphPositionRepository> {
  /// Riverpod provider for [GraphPositionRepository] — keepAlive mirrors the
  /// appDatabaseProvider / progressRepositoryProvider pattern (D-11).
  GraphPositionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'graphPositionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$graphPositionRepositoryHash();

  @$internal
  @override
  $ProviderElement<GraphPositionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GraphPositionRepository create(Ref ref) {
    return graphPositionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GraphPositionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GraphPositionRepository>(value),
    );
  }
}

String _$graphPositionRepositoryHash() =>
    r'5c0826846d88e4ff4e869da0ebbffdc4c5f0ae80';
