// `/unit?letter=` route contract — Plan 07-06 Task 2.
//
// The Letter Unit deep-link: `/unit?letter=baa` builds a LetterUnitScreen for
// that letter; an empty/missing id degrades to the built unit (`baa`) rather
// than erroring; an unknown id degrades to the calm "preparing" panel (the
// loader returns null) — never a crash or an arbitrary load (T-07-06-01).
//
// This mirrors the production `/unit` builder in lib/router/app_router.dart 1:1
// (the same inline-rule approach as test/router/onboarding_gate_test.dart), so
// the test pins the ROUTE BEHAVIOR independent of the full gated router (which
// needs Firebase + the onboarding/parent providers to boot).

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/data/drift_progress_repository.dart';
import 'package:qalam/data/progress_repository.dart';
import 'package:qalam/features/letter_unit/letter_unit_screen.dart';
import 'package:qalam/features/letter_unit/sections/meet_section.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/providers/audio_providers.dart';

import '../features/letter_unit/section_test_support.dart';

class _CapturingAudioPlayer implements LetterAudioPlayer {
  @override
  Future<void> playLetter(String assetPath) async {}
}

class _FakeProgressRepository implements ProgressRepository {
  @override
  Future<void> recordMastery(
          {required String letterId, required int cleanReps}) async {}
  @override
  Future<bool> isMastered(String letterId) async => false;
  @override
  Future<void> setCleanReps(
          {required String letterId, required int cleanReps}) async {}
  @override
  Future<int> getCleanReps(String letterId) async => 0;
  @override
  Stream<Set<String>> watchMasteredLetterIds() =>
      Stream.value(const <String>{});
  @override
  Stream<int> watchCleanReps(String letterId) => Stream.value(0);
  // D-15 fold (19-04): folded aggregate accessors — no persisted reps here.
  @override
  Future<int> letterCleanReps(String letterId) async => 0;
  @override
  Stream<int> watchLetterCleanReps(String letterId) => Stream.value(0);
  @override
  Future<void> setLetterCleanReps(
          {required String letterId, required int cleanReps}) async {}
}

LetterUnitData _baaData() {
  final exercises = <Exercise>[meetExercise(), traceIsolatedExercise()];
  return LetterUnitData(
    unit: const LetterUnit(
      letterId: 'baa',
      sections: [
        UnitSection(id: 'meet', exercises: ['baa.teachCard.meet']),
        UnitSection(id: 'watchTrace', exercises: ['baa.traceLetter.isolated']),
        UnitSection(id: 'mastery', exercises: []),
      ],
    ),
    letter: baaLetter(),
    exercises: {for (final e in exercises) e.id: e},
    words: const [],
  );
}

/// The production `/unit` builder, copied 1:1 from app_router.dart.
GoRoute _unitRoute() => GoRoute(
      path: '/unit',
      builder: (context, state) {
        final raw = state.uri.queryParameters['letter'];
        final letterId = (raw == null || raw.trim().isEmpty) ? 'baa' : raw;
        return LetterUnitScreen(
          key: ValueKey<String>('unit:$letterId'),
          letterId: letterId,
        );
      },
    );

GoRouter _router({required String initialLocation}) => GoRouter(
      initialLocation: initialLocation,
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (c, s) => const _Page('home')),
        GoRoute(path: '/practice', builder: (c, s) => const _Page('practice')),
        _unitRoute(),
      ],
      errorBuilder: (context, state) => const _SentinelError(),
    );

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  LetterUnitData? Function(String id)? data,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(_CapturingAudioPlayer()),
        progressRepositoryProvider.overrideWithValue(_FakeProgressRepository()),
        // Override the data loader for the letters under test.
        letterUnitDataProvider('baa')
            .overrideWith((ref) async => data?.call('baa') ?? _baaData()),
        letterUnitDataProvider('zzz')
            .overrideWith((ref) async => data?.call('zzz')),
      ],
      child: _Harness(router: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  String locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('Test 1: /unit?letter=baa builds a LetterUnitScreen for baa',
      (tester) async {
    final router = _router(initialLocation: '/unit?letter=baa');
    await _pump(tester, router);

    expect(find.byType(_SentinelError), findsNothing);
    expect(locationOf(router), '/unit');
    expect(find.byType(LetterUnitScreen), findsOneWidget);
    // The shell starts on Meet for the resolved baa unit.
    expect(find.byType(MeetSection), findsOneWidget);
  });

  testWidgets('Test 2: a missing letter degrades to the built unit (baa)',
      (tester) async {
    final router = _router(initialLocation: '/unit');
    await _pump(tester, router);

    expect(find.byType(_SentinelError), findsNothing);
    expect(find.byType(LetterUnitScreen), findsOneWidget);
    // Empty id → baa (the built unit) → Meet renders, no error.
    expect(find.byType(MeetSection), findsOneWidget);
  });

  testWidgets(
      'Test 3: an unknown letter degrades to the calm preparing panel (no crash)',
      (tester) async {
    final router = _router(initialLocation: '/unit?letter=zzz');
    // 'zzz' resolves to null data → the calm "preparing" panel.
    await _pump(tester, router, data: (id) => id == 'baa' ? _baaData() : null);

    expect(find.byType(_SentinelError), findsNothing);
    expect(find.byType(LetterUnitScreen), findsOneWidget);
    // No section is shown — the calm preparing panel is, never a raw error.
    expect(find.byType(MeetSection), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Test 4: the home/journey deep-link target /unit?letter=baa resolves',
      (tester) async {
    final router = _router(initialLocation: '/');
    await _pump(tester, router);

    // Navigate the way home/journey do (context.go('/unit?letter=baa')).
    router.go('/unit?letter=baa');
    await tester.pumpAndSettle();

    expect(find.byType(_SentinelError), findsNothing);
    expect(locationOf(router), '/unit');
    expect(
      router.routerDelegate.currentConfiguration.uri.queryParameters['letter'],
      'baa',
    );
    expect(find.byType(LetterUnitScreen), findsOneWidget);
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.router});
  final GoRouter router;
  @override
  Widget build(BuildContext context) {
    // MaterialApp.router (not WidgetsApp.router) so the unit shell's Scaffold +
    // Material widgets get MaterialLocalizations + a Theme.
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _Page extends StatelessWidget {
  const _Page(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}

class _SentinelError extends StatelessWidget {
  const _SentinelError();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
