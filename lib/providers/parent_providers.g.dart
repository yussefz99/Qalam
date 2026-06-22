// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parent_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive — held for the app lifetime.
///
/// PRODUCTION ALWAYS OVERRIDES THIS in main.dart with a fresh LOCKED
/// `ParentGate()` (D-07: starts locked every launch, no boot DB read).
///
/// WR-02: the default is `unlocked: false` (default-DENY). An access-control
/// object must fail safe: any entry point or test that pumps the dashboard
/// without explicitly seeding the gate gets the PIN flow, never the dashboard
/// body. Tests that need the unlocked state opt in explicitly with
/// `parentGateProvider.overrideWith((ref) => ParentGate(unlocked: true))` (see
/// test/screens/parent_dashboard_test.dart). The route-gate test
/// (test/router/parent_gate_test.dart) already overrides this provider
/// explicitly to drive lock/unlock.
///
/// `ParentGate` is a `ChangeNotifier` exposed as a provider value on purpose —
/// the router's `refreshListenable` (Pattern 3). riverpod_lint's
/// `unsupported_provider_value` flags any non-Future/Stream value; the
/// Listenable-as-provider shape is intentional here (see file header).

@ProviderFor(parentGate)
final parentGateProvider = ParentGateProvider._();

/// keepAlive — held for the app lifetime.
///
/// PRODUCTION ALWAYS OVERRIDES THIS in main.dart with a fresh LOCKED
/// `ParentGate()` (D-07: starts locked every launch, no boot DB read).
///
/// WR-02: the default is `unlocked: false` (default-DENY). An access-control
/// object must fail safe: any entry point or test that pumps the dashboard
/// without explicitly seeding the gate gets the PIN flow, never the dashboard
/// body. Tests that need the unlocked state opt in explicitly with
/// `parentGateProvider.overrideWith((ref) => ParentGate(unlocked: true))` (see
/// test/screens/parent_dashboard_test.dart). The route-gate test
/// (test/router/parent_gate_test.dart) already overrides this provider
/// explicitly to drive lock/unlock.
///
/// `ParentGate` is a `ChangeNotifier` exposed as a provider value on purpose —
/// the router's `refreshListenable` (Pattern 3). riverpod_lint's
/// `unsupported_provider_value` flags any non-Future/Stream value; the
/// Listenable-as-provider shape is intentional here (see file header).

final class ParentGateProvider
    extends $FunctionalProvider<ParentGate, ParentGate, ParentGate>
    with $Provider<ParentGate> {
  /// keepAlive — held for the app lifetime.
  ///
  /// PRODUCTION ALWAYS OVERRIDES THIS in main.dart with a fresh LOCKED
  /// `ParentGate()` (D-07: starts locked every launch, no boot DB read).
  ///
  /// WR-02: the default is `unlocked: false` (default-DENY). An access-control
  /// object must fail safe: any entry point or test that pumps the dashboard
  /// without explicitly seeding the gate gets the PIN flow, never the dashboard
  /// body. Tests that need the unlocked state opt in explicitly with
  /// `parentGateProvider.overrideWith((ref) => ParentGate(unlocked: true))` (see
  /// test/screens/parent_dashboard_test.dart). The route-gate test
  /// (test/router/parent_gate_test.dart) already overrides this provider
  /// explicitly to drive lock/unlock.
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

String _$parentGateHash() => r'4151a4bece53cebc6c5ce4974c74a2fd159a3a26';
