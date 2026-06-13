// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod-codegen provider for the pure-Dart PIN service. Codegen is allowed
/// here because no method signature returns a Drift data class — only bool /
/// void / Duration (09-PATTERNS: InvalidTypeException only fires on Drift-typed
/// return values).

@ProviderFor(pinService)
final pinServiceProvider = PinServiceProvider._();

/// Riverpod-codegen provider for the pure-Dart PIN service. Codegen is allowed
/// here because no method signature returns a Drift data class — only bool /
/// void / Duration (09-PATTERNS: InvalidTypeException only fires on Drift-typed
/// return values).

final class PinServiceProvider
    extends $FunctionalProvider<PinService, PinService, PinService>
    with $Provider<PinService> {
  /// Riverpod-codegen provider for the pure-Dart PIN service. Codegen is allowed
  /// here because no method signature returns a Drift data class — only bool /
  /// void / Duration (09-PATTERNS: InvalidTypeException only fires on Drift-typed
  /// return values).
  PinServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinServiceHash();

  @$internal
  @override
  $ProviderElement<PinService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PinService create(Ref ref) {
    return pinService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PinService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PinService>(value),
    );
  }
}

String _$pinServiceHash() => r'bf1dd1c71fbdc18aea66afe776324414e3903658';
