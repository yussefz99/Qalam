// ignore_for_file: scoped_providers_should_specify_dependencies

// Wave-0 validation scaffold — live Journey map (Plan 06-06).
//
// INTENTIONALLY RED at Wave 0: journey_screen.dart still reads the Phase-03.1
// mockJourneyProgressProvider and carries a hardcoded letter list whose ids
// drift from assets/curriculum/letters.json in 19 of 28 cases (RESEARCH
// Pitfall 1 — e.g. 'dal' vs canonical 'daal', 'haa' vs 'haa_c'). Tasks 2/3 of
// this plan swap in progressionProvider + canonical ids and turn this green.
//
// Contracts proven here:
//   - Canonical lighting: a mastered 'daal'/'raa'/'haa_c' LIGHTS its node —
//     the drift regression test. Mastering all 28 letters.json ids lights all
//     28 nodes ("28 of 28 mastered").
//   - Tap matrix (D-07 / S1-09): complete + current + skipped-but-unlocked
//     nodes navigate /practice?lesson=<owning lesson>; genuinely locked nodes
//     (prerequisite unpassed, at/after start) are inert and keep the muted
//     visibly-unavailable treatment.
//   - D-15: arriving with highlightId, the just-mastered node's gold star
//     badge settles in (scale 0→1 over durCheer), then rests.
//   - "N of 28 mastered" reads the LIVE mastered count — quiet information,
//     never gold (T-06-09 / PLAT-03).
//
// Letter ids in this file are CANONICAL letters.json ids ONLY (daal, raa,
// haa_c, taa_h, ...) — sourced from the shipped asset itself so the 03.1
// drift cannot re-enter via the tests.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/features/journey/journey_screen.dart';
import 'package:qalam/features/journey/widgets/journey_node_widget.dart';
import 'package:qalam/models/journey_progress.dart';
import 'package:qalam/models/lesson.dart';
import 'package:qalam/models/lesson_progression.dart';
import 'package:qalam/providers/progression_providers.dart';
import 'package:qalam/theme/colors.dart';
import 'package:qalam/theme/dimens.dart';

// ---------------------------------------------------------------------------
// Fixtures + helpers
// ---------------------------------------------------------------------------

/// The real shipped curriculum (28 lessons, canonical letter ids) loaded from
/// disk — same idiom as progression_providers_test.dart.
CurriculumRepository _shippedCurriculum() {
  final lettersJson = File('assets/curriculum/letters.json').readAsStringSync();
  final lessonsJson = File('assets/curriculum/lessons.json').readAsStringSync();
  return CurriculumRepository.fromStrings(lettersJson, lessonsJson);
}

late CurriculumRepository _curriculum;
late List<Lesson> _ordered;

/// Compute a live progression snapshot from the SHIPPED lesson catalog —
/// the same engine progressionProvider uses in production.
ProgressionSnapshot _snapshot(String startingLessonId, Set<String> mastered) =>
    ProgressionSnapshot.compute(_ordered, startingLessonId, mastered);

/// All 28 canonical letter ids, derived from the shipped catalog itself
/// (every lesson item of type 'letter').
Set<String> _allCanonicalLetterIds() => {
      for (final lesson in _ordered)
        for (final item in lesson.items)
          if (item.type == 'letter') item.ref,
    };

/// Builds the journey screen inside a GoRouter so context.go works and the
/// `?highlight=` query param flows in exactly as app_router.dart wires it.
Widget _build({required ProgressionSnapshot snapshot, String? highlight}) {
  final router = GoRouter(
    initialLocation:
        highlight == null ? '/journey' : '/journey?highlight=$highlight',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/journey',
        builder: (context, state) => JourneyScreen(
          highlightId: state.uri.queryParameters['highlight'],
        ),
      ),
      GoRoute(
        path: '/practice',
        builder: (context, state) => Scaffold(
          body: Text(
            'Practice ${state.uri.queryParameters['lesson'] ?? '<none>'}',
          ),
        ),
      ),
      GoRoute(
        path: '/unit',
        builder: (context, state) => Scaffold(
          body: Text('Unit ${state.uri.queryParameters['letter'] ?? '<none>'}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      curriculumRepositoryProvider.overrideWithValue(_curriculum),
      progressionProvider.overrideWith((ref) async => snapshot),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Pumps the journey at tablet size. NEVER pumpAndSettle here — the current
/// node's pulse glow repeats forever, so settle never returns.
Future<void> _pumpJourney(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(widget);
  // Pump until the overridden async FutureProviders resolve and the map
  // renders. A fixed pump count races full-suite CPU contention (the
  // `(ref) async => snapshot` override completes on a microtask whose rebuild
  // can slip frames under parallel test load), so pump in a bounded loop until
  // a node appears. NEVER pumpAndSettle — the current node's pulse glow repeats
  // forever, so settle never returns.
  for (var i = 0; i < 60 && _noNodesYet(tester); i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// True until the first [JourneyNodeWidget] has rendered.
bool _noNodesYet(WidgetTester tester) =>
    tester.widgetList(find.byType(JourneyNodeWidget)).isEmpty;

/// Finder for the node showing [glyph] — glyphs are unique per letter (unlike
/// display names: both haa_c and haa_f display as 'Haa').
Finder _node(String glyph) => find.byWidgetPredicate(
      (w) => w is JourneyNodeWidget && w.glyph == glyph,
    );

JourneyNodeWidget _nodeWidget(WidgetTester tester, String glyph) =>
    tester.widget<JourneyNodeWidget>(_node(glyph));

/// Taps a node and pumps through the go_router page transition.
Future<void> _tapNode(WidgetTester tester, String glyph) async {
  await tester.tap(_node(glyph), warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 200));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    _curriculum = _shippedCurriculum();
    final lessons = await _curriculum.getLessons();
    _ordered = [...lessons]..sort((a, b) => a.order.compareTo(b.order));
  });

  group('JourneyScreen live data — canonical letter ids (drift regression)',
      () {
    // -------------------------------------------------------------------
    // Test 1: a mastered 'daal' lights the daal node. This is THE drift
    // regression: the 03.1 screen keys that node 'dal', which never matches.
    // -------------------------------------------------------------------
    testWidgets('mastered daal renders the daal node complete (Test 1)',
        (WidgetTester tester) async {
      await _pumpJourney(
        tester,
        _build(snapshot: _snapshot('lesson_01', {'daal'})),
      );

      expect(
        _nodeWidget(tester, 'د').state,
        JourneyNodeState.complete,
        reason: 'mastered canonical id "daal" must light the د node — '
            'the 03.1 hardcoded "dal" id silently never lights (Pitfall 1).',
      );

      // Live header count — quiet information, never gold (T-06-09).
      final header = find.text('1 of 28 mastered');
      expect(header, findsOneWidget,
          reason: 'the header must read the LIVE mastered count.');
      final headerText = tester.widget<Text>(header);
      expect(
        headerText.style?.color,
        isNot(QalamColors.reward),
        reason: '"N of 28" is plain information — gold is reward-exclusive.',
      );
    });

    // -------------------------------------------------------------------
    // Test 2: drifted-family ids — haa_c (ح) vs haa_f (ه), raa, taa_h.
    // -------------------------------------------------------------------
    testWidgets(
        'haa_c / raa / taa_h light their own nodes and no lookalikes (Test 2)',
        (WidgetTester tester) async {
      await _pumpJourney(
        tester,
        _build(snapshot: _snapshot('lesson_01', {'haa_c', 'raa', 'taa_h'})),
      );

      expect(_nodeWidget(tester, 'ح').state, JourneyNodeState.complete,
          reason: 'canonical "haa_c" must light the ح node.');
      expect(_nodeWidget(tester, 'ر').state, JourneyNodeState.complete,
          reason: 'canonical "raa" must light the ر node.');
      expect(_nodeWidget(tester, 'ط').state, JourneyNodeState.complete,
          reason: 'canonical "taa_h" must light the ط node.');

      // The lookalike-named letters must NOT light.
      expect(_nodeWidget(tester, 'ه').state,
          isNot(JourneyNodeState.complete),
          reason: 'haa_f (ه) is not mastered — must not light from haa_c.');
      expect(_nodeWidget(tester, 'ت').state,
          isNot(JourneyNodeState.complete),
          reason: 'taa (ت) is not mastered — must not light from taa_h.');

      expect(find.text('3 of 28 mastered'), findsOneWidget);
    });

    // -------------------------------------------------------------------
    // Test 3: every canonical letters.json id lights its node — 28/28.
    // Any single surviving drifted id breaks this count.
    // -------------------------------------------------------------------
    testWidgets('all 28 canonical ids mastered → 28 complete nodes (Test 3)',
        (WidgetTester tester) async {
      final all = _allCanonicalLetterIds();
      expect(all, hasLength(28),
          reason: 'shipped catalog must reference 28 letters.');

      await _pumpJourney(
        tester,
        _build(snapshot: _snapshot('lesson_01', all)),
      );

      final completeCount = tester
          .widgetList<JourneyNodeWidget>(find.byType(JourneyNodeWidget))
          .where((w) => w.state == JourneyNodeState.complete)
          .length;
      expect(completeCount, 28,
          reason: 'every node id must equal a letters.json id — any drifted '
              'id leaves its node unlit.');
      expect(find.text('28 of 28 mastered'), findsOneWidget);
    });
  });

  group('JourneyScreen tap matrix — D-07 / S1-09', () {
    // Scenario: startingLessonId = lesson_03, mastered = {taa}.
    //   alif/baa  → skipped-before-start: future visual, UNLOCKED (D-05)
    //   taa       → complete (lesson_03 passed)
    //   thaa      → today / current (lesson_04, unlocked by lesson_03 pass)
    //   jeem onwards → genuinely locked (lesson_05 requires lesson_04)
    ProgressionSnapshot scenario() => _snapshot('lesson_03', {'taa'});

    testWidgets('complete node tap → its Letter Unit (taa, Phase 8) (Test 4)',
        (WidgetTester tester) async {
      await _pumpJourney(tester, _build(snapshot: scenario()));

      expect(_nodeWidget(tester, 'ت').state, JourneyNodeState.complete);
      await _tapNode(tester, 'ت');

      // Phase 8: the first three letters (alif/baa/taa) open their full Letter
      // Unit; a complete one replays its own unit.
      expect(find.text('Unit taa'), findsOneWidget,
          reason: 'a complete first-3 node replays ITS OWN Letter Unit.');
    });

    testWidgets('current thaa node tap → its Letter Unit (Stage 1) (Test 5)',
        (WidgetTester tester) async {
      await _pumpJourney(tester, _build(snapshot: scenario()));

      expect(_nodeWidget(tester, 'ث').state, JourneyNodeState.current);
      await _tapNode(tester, 'ث');

      // Stage 1 all-letters-live (quick task 260718-il4): thaa now has a FULL
      // live Letter Unit, so its Journey node opens /unit?letter=thaa (like
      // alif/baa/taa) rather than the generic /practice?lesson= path it used
      // before its unit existed.
      expect(find.text('Unit thaa'), findsOneWidget,
          reason: 'the thaa node opens its own Letter Unit now that Stage 1 '
              'promoted it (was Practice lesson_04 before the unit existed).');
    });

    testWidgets(
        'skipped-but-unlocked node keeps the future visual and IS tappable (Test 6)',
        (WidgetTester tester) async {
      await _pumpJourney(tester, _build(snapshot: scenario()));

      // D-07: skipped letters keep the future visual — no new visual state.
      expect(_nodeWidget(tester, 'ا').state, JourneyNodeState.future,
          reason: 'skipped-before-start alif keeps the future visual (D-07).');

      await _tapNode(tester, 'ا');
      expect(find.text('Unit alif'), findsOneWidget,
          reason: 'skipped-but-unlocked alif is revisitable and (Phase 8) opens '
              'its Letter Unit.');
    });

    testWidgets(
        'genuinely locked node is inert and visibly unavailable (Test 7)',
        (WidgetTester tester) async {
      await _pumpJourney(tester, _build(snapshot: scenario()));

      // jeem's lesson_05 requires lesson_04 (unpassed) → locked (S1-09).
      final jeem = _nodeWidget(tester, 'ج');
      expect(jeem.onTap, isNull,
          reason: 'locked nodes must be inert (S1-09).');
      expect(
        jeem.state,
        anyOf(JourneyNodeState.future, JourneyNodeState.locked),
        reason: 'locked nodes keep the muted locked/future treatment — '
            'visibly unavailable (S1-09).',
      );

      await _tapNode(tester, 'ج');
      expect(find.textContaining('Practice'), findsNothing,
          reason: 'tapping a locked node must not navigate.');
      expect(find.text('1 of 28 mastered'), findsOneWidget,
          reason: 'still on the journey after tapping a locked node.');
    });
  });

  group('JourneyScreen highlight arrival — D-15', () {
    testWidgets(
        'highlight=alif settles the gold star on the alif node, then rests (Test 8)',
        (WidgetTester tester) async {
      await _pumpJourney(
        tester,
        _build(
          snapshot: _snapshot('lesson_01', {'alif'}),
          highlight: 'alif',
        ),
      );

      // The settling-star emphasis is present on the alif node specifically.
      final settle = find.descendant(
        of: _node('ا'),
        matching: find.byKey(const Key('journeyHighlightSettle')),
      );
      expect(settle, findsOneWidget,
          reason: 'arriving via ?highlight=alif must play the settling star '
              'on the just-mastered alif node (D-15).');

      // After durCheer the star has fully settled (scale 1.0) — one-shot.
      await tester.pump(QalamMotion.durCheer);
      await tester.pump(const Duration(milliseconds: 50));
      final scaleTransition = tester.widget<ScaleTransition>(
        find.descendant(of: settle, matching: find.byType(ScaleTransition)),
      );
      expect(scaleTransition.scale.value, closeTo(1.0, 0.01),
          reason: 'the star settles to rest after durCheer (700ms) — '
              'dignified, one-shot, no looping hype.');
    });

    testWidgets(
        'unknown highlight id is a silent no-op — V5 degradation (Test 9)',
        (WidgetTester tester) async {
      // '?highlight=' is externally influenceable (T-06-03): an id that
      // matches no rendered node must change nothing — no settle, no crash.
      await _pumpJourney(
        tester,
        _build(
          snapshot: _snapshot('lesson_01', {'alif'}),
          highlight: 'not_a_letter',
        ),
      );

      expect(find.byKey(const Key('journeyHighlightSettle')), findsNothing,
          reason: 'unknown highlight ids must not start the settle (catalog '
              'allowlist — T-06-03).');
      // The map still renders normally.
      expect(_nodeWidget(tester, 'ا').state, JourneyNodeState.complete);
      expect(find.text('1 of 28 mastered'), findsOneWidget);
    });

    testWidgets(
        'highlight on a NON-complete node is also a no-op (Test 10)',
        (WidgetTester tester) async {
      // baa is current (not mastered) — highlighting it must not conjure a
      // gold star: the badge is mastery information only.
      await _pumpJourney(
        tester,
        _build(
          snapshot: _snapshot('lesson_01', {'alif'}),
          highlight: 'baa',
        ),
      );

      expect(find.byKey(const Key('journeyHighlightSettle')), findsNothing,
          reason: 'only a COMPLETE node can settle its star (gold = real '
              'mastery, never speculative).');
    });
  });
}
