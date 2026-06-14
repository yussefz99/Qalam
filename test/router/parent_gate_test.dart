// RED — implemented in 09-03 (ParentGate provider + /parent route + PIN flow).
//
// Plan 09-01 (Wave 0) — the /parent route-gate contract (S1-11, T-09-03).
//
// INTENTIONALLY RED at Wave 0: references the not-yet-built parentGateProvider /
// ParentGate from package:qalam/providers/parent_providers.dart and the
// ParentDashboardScreen. A later plan (09-03) builds the gate + wires the
// '/parent' route (mirroring the onboarding gate in app_router.dart) and turns
// this green. Do NOT add a lib/ stub here.
//
// Encodes the T-09-03 elevation-of-privilege mitigation as executable
// assertions (mirrors onboarding_gate_test.dart's router + refreshListenable
// shape):
//   * default-deny — '/parent' while LOCKED does NOT render the dashboard
//     summary; the child sees the PIN flow instead (a child cannot bypass it);
//   * reachable only AFTER the gate flips unlocked (correct PIN);
//   * "Done" relocks (per-entry, D-07) and a second entry re-prompts the PIN;
//   * the PIN entry field is OBSCURED (obscureText == true) and numeric.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/providers/parent_providers.dart';
import 'package:qalam/screens/parent_dashboard_screen.dart';

import 'package:drift/native.dart';
import 'dart:io';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// The real shipped curriculum (28 lessons) so the dashboard denominator
/// resolves the same way it would in production (never hardcoded 28).
CurriculumRepository _shippedCurriculum() {
  final lettersJson = File('assets/curriculum/letters.json').readAsStringSync();
  final lessonsJson = File('assets/curriculum/lessons.json').readAsStringSync();
  return CurriculumRepository.fromStrings(lettersJson, lessonsJson);
}

/// Router exposing the single '/parent' route whose widget shows the PIN flow
/// or the dashboard depending on the gate (RESEARCH Pattern 3 — one route, no
/// sub-routes, no redirect loop).
GoRouter _parentRouter(ParentGate gate, {String initialLocation = '/parent'}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: gate,
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (c, s) => const Scaffold(body: Text('home'))),
      GoRoute(
        path: '/parent',
        builder: (c, s) => const ParentDashboardScreen(),
      ),
    ],
  );
}

Widget _harness({
  required GoRouter router,
  required AppDatabase db,
  required ParentGate gate,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) => db),
      curriculumRepositoryProvider.overrideWithValue(_shippedCurriculum()),
      parentGateProvider.overrideWith((ref) => gate),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late NativeDatabase executor;

  setUp(() {
    executor = NativeDatabase.memory();
    db = AppDatabase(executor);
    addTearDown(() => executor.close());
  });

  testWidgets(
      'LOCKED: navigating to /parent does NOT render the dashboard summary '
      '(default-deny, T-09-03)', (tester) async {
    final gate = ParentGate(unlocked: false);
    final router = _parentRouter(gate);
    await tester.pumpWidget(_harness(router: router, db: db, gate: gate));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // The summary line must NOT be visible while the gate is locked — the child
    // sees the PIN flow, never the progress data.
    expect(find.text(l10n.parentSummary(0, 28)), findsNothing,
        reason: 'a locked /parent must not leak the dashboard summary');
  });

  testWidgets('the PIN entry field is OBSCURED and numeric (T-09-03)',
      (tester) async {
    final gate = ParentGate(unlocked: false);
    final router = _parentRouter(gate);
    await tester.pumpWidget(_harness(router: router, db: db, gate: gate));
    await tester.pumpAndSettle();

    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields, isNotEmpty,
        reason: 'a locked /parent must show a PIN entry field');
    expect(fields.any((f) => f.obscureText == true), isTrue,
        reason: 'the PIN field must be obscured (never shows the digits)');
    expect(
      fields.any((f) => f.keyboardType == TextInputType.number),
      isTrue,
      reason: 'the PIN field must be numeric',
    );
  });

  testWidgets(
      'UNLOCKED: /parent renders the dashboard once the gate flips unlocked',
      (tester) async {
    final gate = ParentGate(unlocked: true);
    final router = _parentRouter(gate);
    await tester.pumpWidget(_harness(router: router, db: db, gate: gate));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // With no progress seeded, the unlocked dashboard shows the empty state —
    // proving the dashboard (not the PIN flow) is rendered.
    expect(find.text(l10n.parentEmptyTitle), findsOneWidget,
        reason: 'an unlocked /parent must render the dashboard');
  });

  testWidgets(
      'LIVE unlock(): the boundary swaps from the PIN flow to the dashboard '
      'when the gate notifies (device-UAT regression)', (tester) async {
    // Start LOCKED and pump — the PIN flow is shown. Then flip the SAME gate
    // instance via unlock() (what the PIN screen does after a correct PIN) and
    // pump WITHOUT re-navigating. The boundary must rebuild and show the
    // dashboard. This drives the live notifyListeners() path that the
    // "start already unlocked" test above never exercised — the gap that let a
    // ChangeNotifier-as-provider-value miss its rebuild and leave the screen
    // stuck on the confirm step on a real device.
    final gate = ParentGate(unlocked: false);
    final router = _parentRouter(gate);
    await tester.pumpWidget(_harness(router: router, db: db, gate: gate));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // Locked: the PIN flow is up, the dashboard empty-state is not.
    expect(find.text(l10n.parentEmptyTitle), findsNothing,
        reason: 'while locked the dashboard must not render');

    // Flip the live gate exactly as a correct PIN would, no re-navigation.
    gate.unlock();
    await tester.pumpAndSettle();

    expect(find.text(l10n.parentEmptyTitle), findsOneWidget,
        reason:
            'a live unlock() must rebuild the boundary into the dashboard — '
            'not leave the screen stuck on the PIN flow');
  });

  testWidgets(
      'Done relocks the gate (per-entry, D-07) and a second entry re-prompts '
      'the PIN', (tester) async {
    final gate = ParentGate(unlocked: true);
    final router = _parentRouter(gate);
    await tester.pumpWidget(_harness(router: router, db: db, gate: gate));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // Tap "Done" → the gate relocks and we return to Home.
    await tester.tap(find.text(l10n.commonDone));
    await tester.pumpAndSettle();
    expect(gate.unlocked, isFalse,
        reason: 'Done must relock the gate on exit (D-07)');

    // Re-entering /parent must re-prompt the PIN, not show the dashboard.
    router.go('/parent');
    await tester.pumpAndSettle();
    expect(find.text(l10n.parentEmptyTitle), findsNothing,
        reason: 'a second entry must re-prompt the PIN (per-entry, D-07)');
  });
}
