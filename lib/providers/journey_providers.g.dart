// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Static mock journey progress provider.
///
/// Returns the Phase 03.1 demo state: alif, baa, taa mastered; thaa current.
/// keepAlive: true — held for the app lifetime (same pattern as curriculumRepository).

@ProviderFor(mockJourneyProgress)
final mockJourneyProgressProvider = MockJourneyProgressProvider._();

/// Static mock journey progress provider.
///
/// Returns the Phase 03.1 demo state: alif, baa, taa mastered; thaa current.
/// keepAlive: true — held for the app lifetime (same pattern as curriculumRepository).

final class MockJourneyProgressProvider
    extends
        $FunctionalProvider<JourneyProgress, JourneyProgress, JourneyProgress>
    with $Provider<JourneyProgress> {
  /// Static mock journey progress provider.
  ///
  /// Returns the Phase 03.1 demo state: alif, baa, taa mastered; thaa current.
  /// keepAlive: true — held for the app lifetime (same pattern as curriculumRepository).
  MockJourneyProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mockJourneyProgressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mockJourneyProgressHash();

  @$internal
  @override
  $ProviderElement<JourneyProgress> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  JourneyProgress create(Ref ref) {
    return mockJourneyProgress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyProgress value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyProgress>(value),
    );
  }
}

String _$mockJourneyProgressHash() =>
    r'e187f674c7c4fb86484f3d2ee707e27fb9e02ccc';
