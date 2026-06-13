// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parent_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive — held for the app lifetime; overridden at boot in main.dart with a
/// fresh locked `ParentGate()` (starts locked every launch — D-07, no boot DB
/// read needed).
///
/// `ParentGate` is a `ChangeNotifier` exposed as a provider value on purpose —
/// the router's `refreshListenable` (Pattern 3). riverpod_lint's
/// `unsupported_provider_value` flags any non-Future/Stream value; the
/// Listenable-as-provider shape is intentional here (see file header).

@ProviderFor(parentGate)
final parentGateProvider = ParentGateProvider._();

/// keepAlive — held for the app lifetime; overridden at boot in main.dart with a
/// fresh locked `ParentGate()` (starts locked every launch — D-07, no boot DB
/// read needed).
///
/// `ParentGate` is a `ChangeNotifier` exposed as a provider value on purpose —
/// the router's `refreshListenable` (Pattern 3). riverpod_lint's
/// `unsupported_provider_value` flags any non-Future/Stream value; the
/// Listenable-as-provider shape is intentional here (see file header).

final class ParentGateProvider
    extends $FunctionalProvider<ParentGate, ParentGate, ParentGate>
    with $Provider<ParentGate> {
  /// keepAlive — held for the app lifetime; overridden at boot in main.dart with a
  /// fresh locked `ParentGate()` (starts locked every launch — D-07, no boot DB
  /// read needed).
  ///
  /// `ParentGate` is a `ChangeNotifier` exposed as a provider value on purpose —
  /// the router's `refreshListenable` (Pattern 3). riverpod_lint's
  /// `unsupported_provider_value` flags any non-Future/Stream value; the
  /// Listenable-as-provider shape is intentional here (see file header).
  ParentGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'parentGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$parentGateHash();

  @$internal
  @override
  $ProviderElement<ParentGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ParentGate create(Ref ref) {
    return parentGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ParentGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ParentGate>(value),
    );
  }
}

String _$parentGateHash() => r'2d459cf2139760399156dcf0bb18103e4774ed71';
