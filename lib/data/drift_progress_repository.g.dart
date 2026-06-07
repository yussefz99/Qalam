// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_progress_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [ProgressRepository] — keepAlive mirrors the
/// appDatabaseProvider and curriculumRepositoryProvider pattern (D-11).

@ProviderFor(progressRepository)
final progressRepositoryProvider = ProgressRepositoryProvider._();

/// Riverpod provider for [ProgressRepository] — keepAlive mirrors the
/// appDatabaseProvider and curriculumRepositoryProvider pattern (D-11).

final class ProgressRepositoryProvider
    extends
        $FunctionalProvider<
          ProgressRepository,
          ProgressRepository,
          ProgressRepository
        >
    with $Provider<ProgressRepository> {
  /// Riverpod provider for [ProgressRepository] — keepAlive mirrors the
  /// appDatabaseProvider and curriculumRepositoryProvider pattern (D-11).
  ProgressRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProgressRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProgressRepository create(Ref ref) {
    return progressRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressRepository>(value),
    );
  }
}

String _$progressRepositoryHash() =>
    r'eb9fc8dcc51f379088e3b31d9fe0422cac1043bc';
