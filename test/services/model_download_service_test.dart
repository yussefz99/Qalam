// Unit tests for ModelDownloadService (Plan 04-03, Task 2, D-05).
//
// The real DigitalInkRecognizerModelManager talks to the platform, so these tests
// inject a MOCKED manager via the overridable `inkModelManagerProvider` seam. They
// prove the three best-effort paths:
//   (a) model already downloaded → isReady true, no fetch attempted;
//   (b) not downloaded → a fetch is attempted and isReady flips true on success;
//   (c) the fetch THROWS → state stays not-ready WITHOUT throwing (D-05 — the child
//       is never hard-blocked).

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalam/services/model_download_service.dart';

class _MockModelManager extends Mock
    implements DigitalInkRecognizerModelManager {}

/// Builds a container with the model manager overridden to [mock], reads the
/// service to trigger build()+_ensureModel(), and pumps the microtask/event queue
/// so the async readiness resolution completes before assertions.
Future<ModelDownloadState> resolveWith(
    DigitalInkRecognizerModelManager mock) async {
  final container = ProviderContainer(
    overrides: [
      inkModelManagerProvider.overrideWithValue(mock),
    ],
  );
  addTearDown(container.dispose);

  // First read primes the not-ready default and kicks off _ensureModel().
  container.read(modelDownloadServiceProvider);
  // Let the async check/download settle.
  await Future<void>.delayed(Duration.zero);
  return container.read(modelDownloadServiceProvider);
}

void main() {
  test('initial state is not-ready (calm "getting ready" prime)', () {
    final mock = _MockModelManager();
    when(() => mock.isModelDownloaded(any()))
        .thenAnswer((_) async => false);
    when(() => mock.downloadModel(any())).thenAnswer((_) async => false);

    final container = ProviderContainer(
      overrides: [inkModelManagerProvider.overrideWithValue(mock)],
    );
    addTearDown(container.dispose);

    // The synchronous default the UI sees on first frame.
    expect(container.read(modelDownloadServiceProvider).isReady, isFalse);
  });

  test('already-downloaded → isReady true WITHOUT a fetch', () async {
    final mock = _MockModelManager();
    when(() => mock.isModelDownloaded(any())).thenAnswer((_) async => true);

    final state = await resolveWith(mock);

    expect(state.isReady, isTrue);
    verifyNever(() => mock.downloadModel(any()));
  });

  test('not-downloaded → fetch attempted, isReady flips true on success',
      () async {
    final mock = _MockModelManager();
    when(() => mock.isModelDownloaded(any())).thenAnswer((_) async => false);
    when(() => mock.downloadModel(any())).thenAnswer((_) async => true);

    final state = await resolveWith(mock);

    expect(state.isReady, isTrue);
    verify(() => mock.downloadModel('ar')).called(1);
  });

  test('download reports failure → stays not-ready (no hard-block)', () async {
    final mock = _MockModelManager();
    when(() => mock.isModelDownloaded(any())).thenAnswer((_) async => false);
    when(() => mock.downloadModel(any())).thenAnswer((_) async => false);

    final state = await resolveWith(mock);

    expect(state.isReady, isFalse);
  });

  test('a thrown fetch leaves state not-ready WITHOUT throwing (D-05)',
      () async {
    final mock = _MockModelManager();
    when(() => mock.isModelDownloaded(any())).thenAnswer((_) async => false);
    when(() => mock.downloadModel(any()))
        .thenThrow(Exception('no network on first run'));

    // resolveWith must not throw — the failure is swallowed best-effort.
    final state = await resolveWith(mock);

    expect(state.isReady, isFalse);
  });

  test('a thrown presence-check also degrades gracefully (D-05)', () async {
    final mock = _MockModelManager();
    when(() => mock.isModelDownloaded(any()))
        .thenThrow(Exception('platform error'));

    final state = await resolveWith(mock);

    expect(state.isReady, isFalse);
  });
}
