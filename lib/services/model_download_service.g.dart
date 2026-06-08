// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_download_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The ML Kit model manager, exposed as an overridable provider so unit tests can
/// inject a fake without a device (Riverpod's idiomatic seam). Production code
/// uses the real on-device manager.

@ProviderFor(inkModelManager)
final inkModelManagerProvider = InkModelManagerProvider._();

/// The ML Kit model manager, exposed as an overridable provider so unit tests can
/// inject a fake without a device (Riverpod's idiomatic seam). Production code
/// uses the real on-device manager.

final class InkModelManagerProvider
    extends
        $FunctionalProvider<
          DigitalInkRecognizerModelManager,
          DigitalInkRecognizerModelManager,
          DigitalInkRecognizerModelManager
        >
    with $Provider<DigitalInkRecognizerModelManager> {
  /// The ML Kit model manager, exposed as an overridable provider so unit tests can
  /// inject a fake without a device (Riverpod's idiomatic seam). Production code
  /// uses the real on-device manager.
  InkModelManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inkModelManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inkModelManagerHash();

  @$internal
  @override
  $ProviderElement<DigitalInkRecognizerModelManager> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DigitalInkRecognizerModelManager create(Ref ref) {
    return inkModelManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DigitalInkRecognizerModelManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DigitalInkRecognizerModelManager>(
        value,
      ),
    );
  }
}

String _$inkModelManagerHash() => r'c28bf0ed90e84c85ccd05d701af4ad38ff688ecd';

/// Riverpod service that background-fetches the ML Kit Arabic model best-effort.
///
/// keepAlive — the model is an app-lifetime resource; we never want the fetch
/// torn down and restarted when a single screen disposes.
///
/// `build()` primes an immediate `isReady: false` (the UI must always have a
/// valid value), then kicks off the check-then-fetch in the background and flips
/// `isReady` to true once the model is cached (prime-then-update-after-async-load,
/// mirroring PracticeSessionController).

@ProviderFor(ModelDownloadService)
final modelDownloadServiceProvider = ModelDownloadServiceProvider._();

/// Riverpod service that background-fetches the ML Kit Arabic model best-effort.
///
/// keepAlive — the model is an app-lifetime resource; we never want the fetch
/// torn down and restarted when a single screen disposes.
///
/// `build()` primes an immediate `isReady: false` (the UI must always have a
/// valid value), then kicks off the check-then-fetch in the background and flips
/// `isReady` to true once the model is cached (prime-then-update-after-async-load,
/// mirroring PracticeSessionController).
final class ModelDownloadServiceProvider
    extends $NotifierProvider<ModelDownloadService, ModelDownloadState> {
  /// Riverpod service that background-fetches the ML Kit Arabic model best-effort.
  ///
  /// keepAlive — the model is an app-lifetime resource; we never want the fetch
  /// torn down and restarted when a single screen disposes.
  ///
  /// `build()` primes an immediate `isReady: false` (the UI must always have a
  /// valid value), then kicks off the check-then-fetch in the background and flips
  /// `isReady` to true once the model is cached (prime-then-update-after-async-load,
  /// mirroring PracticeSessionController).
  ModelDownloadServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelDownloadServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelDownloadServiceHash();

  @$internal
  @override
  ModelDownloadService create() => ModelDownloadService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelDownloadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelDownloadState>(value),
    );
  }
}

String _$modelDownloadServiceHash() =>
    r'f43629250f7e46a4e5c1ac358e31d8dc16f12e7a';

/// Riverpod service that background-fetches the ML Kit Arabic model best-effort.
///
/// keepAlive — the model is an app-lifetime resource; we never want the fetch
/// torn down and restarted when a single screen disposes.
///
/// `build()` primes an immediate `isReady: false` (the UI must always have a
/// valid value), then kicks off the check-then-fetch in the background and flips
/// `isReady` to true once the model is cached (prime-then-update-after-async-load,
/// mirroring PracticeSessionController).

abstract class _$ModelDownloadService extends $Notifier<ModelDownloadState> {
  ModelDownloadState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ModelDownloadState, ModelDownloadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ModelDownloadState, ModelDownloadState>,
              ModelDownloadState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
