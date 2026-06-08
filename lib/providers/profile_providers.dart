// Plan 05-02 — child-profile read provider + onboarding redirect gate (S1-02).
//
// Two pieces:
//  1. childProfileProvider — an invalidatable async read of the single profile.
//     NOT keepAlive on purpose: Wave 2 calls `ref.invalidate(childProfileProvider)`
//     after the onboarding write so the Home greeting re-reads the new profile.
//  2. OnboardingGate — a ChangeNotifier the router uses as `refreshListenable`.
//     Seeded at boot (main.dart override) with the result of a one-time
//     hasProfile() read; `markProfileCreated()` flips it after onboarding so the
//     redirect re-runs and moves the child off /onboarding (no loop — Pattern 3).
//
// KNOWN ANALYZER NOTE: riverpod_lint emits one `unsupported_provider_value`
// warning for `onboardingGate` below, because `OnboardingGate` is a
// ChangeNotifier rather than Future/Stream state. That is intentional — it is
// the router's `refreshListenable` (Pattern 3), the exact shape prescribed by
// 05-PATTERNS.md. The riverpod_lint plugin does NOT honor inline `// ignore:`
// or `// ignore_for_file:` for this diagnostic in the current toolchain, so the
// warning is left visible and documented rather than suppressed. It is a
// plugin false-positive for a deliberate design, not a defect.
//
// NOTE (deviation, Rule 3): `childProfileProvider` is a HAND-WRITTEN
// `FutureProvider`, not `@riverpod` codegen. riverpod_generator 4.0.3 throws
// `InvalidTypeException: The type is invalid and cannot be converted to code.`
// when a functional provider's return type is a Drift-generated data class
// (`ChildProfile`, declared in app_database.g.dart). The manual FutureProvider
// is the idiomatic Riverpod escape hatch and preserves the exact Wave-0 test
// contract: `childProfileProvider.overrideWith((ref) async => profile)` and a
// value type of `ChildProfile?`. `onboardingGate` (return type is a plain
// hand-written class) stays on codegen.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/app_database.dart';
import '../data/child_profile_repository.dart';

part 'profile_providers.g.dart';

/// Invalidatable async read of the single child profile.
///
/// A plain `FutureProvider` (NOT keepAlive) so Wave 2 can
/// `ref.invalidate(childProfileProvider)` after the onboarding write, forcing
/// Home to re-read. Resolves to `null` when no profile exists yet.
final childProfileProvider = FutureProvider<ChildProfile?>(
  (ref) => ref.watch(childProfileRepositoryProvider).getProfile(),
);

/// The router's `refreshListenable` for the onboarding redirect gate.
///
/// Seeded at boot from a one-time `AppDatabase.hasProfile()` read (overridden in
/// main.dart). `markProfileCreated()` flips the flag and notifies so the
/// GoRouter redirect re-runs and lets the child off /onboarding.
class OnboardingGate extends ChangeNotifier {
  OnboardingGate(this._hasProfile);
  bool _hasProfile;
  bool get hasProfile => _hasProfile;

  void markProfileCreated() {
    _hasProfile = true;
    notifyListeners();
  }
}

/// keepAlive — held for the app lifetime; overridden at boot with the real
/// seed value (main.dart, Wave 2).
///
/// `OnboardingGate` is a `ChangeNotifier` exposed as a provider value on
/// purpose — it is the router's `refreshListenable` (Pattern 3), not async
/// state. riverpod_lint's `unsupported_provider_value` flags any non-Future/
/// Stream value; the Listenable-as-provider shape is intentional here, so the
/// diagnostic is ignored for this one declaration.
@Riverpod(keepAlive: true)
OnboardingGate onboardingGate(Ref ref) => OnboardingGate(false);
