// ModelDownloadService — best-effort, one-time fetch of the ML Kit Arabic model
// (Plan 04-03, Task 2, D-05).
//
// On first launch the ~20 MB Arabic-script ink model is not yet on the device.
// This service checks for it and, if absent, kicks off a BACKGROUND download,
// exposing `isReady` so the practice flow can show a calm "getting ready" state
// until the model is cached. Fully offline thereafter (D-05).
//
// BEST-EFFORT, NEVER HARD-BLOCK (D-05 / practice_providers.dart:148-157 idiom):
// a download failure (no network on first run, platform error, …) must NEVER
// throw or block the child — it leaves the service in a calm not-ready state.
// The ML Kit identity gate is advisory-only (D-04), so the geometric scorer keeps
// working with or without the model; "not ready" simply means the SC#2 scribble
// net abstains until the model arrives, never a broken lesson.
//
// SECURITY (T-04-07 / T-01-05): no child data flows through here — this service
// only manages a model file. Nothing is logged or transmitted beyond the single
// Google-infrastructure model fetch via DigitalInkRecognizerModelManager
// (T-04-05: no custom model URLs).

import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/recognition/ml_kit_recognizer.dart' show kArabicModelCode;

part 'model_download_service.g.dart';

/// The ML Kit model manager, exposed as an overridable provider so unit tests can
/// inject a fake without a device (Riverpod's idiomatic seam). Production code
/// uses the real on-device manager.
@Riverpod(keepAlive: true)
DigitalInkRecognizerModelManager inkModelManager(Ref ref) =>
    DigitalInkRecognizerModelManager();

/// Immutable snapshot of the model-download state.
///
/// [isReady] is true only once the Arabic model is confirmed downloaded and
/// cached. While false, the UI shows a calm "getting ready" state; the lesson
/// still runs (the ML Kit gate is advisory-only — D-04).
class ModelDownloadState {
  const ModelDownloadState({required this.isReady});

  /// True when the Arabic ink model is downloaded and ready on-device.
  final bool isReady;

  ModelDownloadState copyWith({bool? isReady}) =>
      ModelDownloadState(isReady: isReady ?? this.isReady);
}

/// Riverpod service that background-fetches the ML Kit Arabic model best-effort.
///
/// keepAlive — the model is an app-lifetime resource; we never want the fetch
/// torn down and restarted when a single screen disposes.
///
/// `build()` primes an immediate `isReady: false` (the UI must always have a
/// valid value), then kicks off the check-then-fetch in the background and flips
/// `isReady` to true once the model is cached (prime-then-update-after-async-load,
/// mirroring PracticeSessionController).
@Riverpod(keepAlive: true)
class ModelDownloadService extends _$ModelDownloadService {
  @override
  ModelDownloadState build() {
    // Prime an immediate not-ready default, then resolve readiness in the
    // background. The UI reads state.isReady so it must always be valid.
    _ensureModel();
    return const ModelDownloadState(isReady: false);
  }

  /// Checks for the Arabic model and, if absent, attempts a one-time background
  /// download. BEST-EFFORT (D-05): any failure leaves the service not-ready and
  /// NEVER throws — the child is never hard-blocked.
  Future<void> _ensureModel() async {
    final manager = ref.read(inkModelManagerProvider);
    try {
      // Pitfall 5 — verify presence before relying on the model (T-04-05).
      final alreadyDownloaded =
          await manager.isModelDownloaded(kArabicModelCode);
      if (alreadyDownloaded) {
        state = state.copyWith(isReady: true);
        return;
      }

      // Not present — attempt the one-time fetch from Google's infrastructure.
      final ok = await manager.downloadModel(kArabicModelCode);
      if (ok) {
        state = state.copyWith(isReady: true);
      }
      // If the download reports failure (returns false), stay not-ready: a calm
      // "getting ready" state, retried on next launch. No throw, no hard-block.
    } catch (_) {
      // Swallow — surface a not-ready state, never an error (D-05). The next
      // launch tries again; the geometric scorer works regardless.
    }
  }
}
