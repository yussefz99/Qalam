// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive — held for the app lifetime; overridden at boot with the real
/// seed value (main.dart, Wave 2).

@ProviderFor(onboardingGate)
final onboardingGateProvider = OnboardingGateProvider._();

/// keepAlive — held for the app lifetime; overridden at boot with the real
/// seed value (main.dart, Wave 2).

final class OnboardingGateProvider
    extends $FunctionalProvider<OnboardingGate, OnboardingGate, OnboardingGate>
    with $Provider<OnboardingGate> {
  /// keepAlive — held for the app lifetime; overridden at boot with the real
  /// seed value (main.dart, Wave 2).
  OnboardingGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingGateHash();

  @$internal
  @override
  $ProviderElement<OnboardingGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OnboardingGate create(Ref ref) {
    return onboardingGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingGate>(value),
    );
  }
}

String _$onboardingGateHash() => r'c6888488f4749ef0d1aa488dc724c24907f54b62';
