// Phase 18-12 — a same-id re-present must force a FRESH MOUNT (UAT T3 + T6).
//
// Two UAT gaps share ONE mechanism: exercise_presenter keyed the scaffold by
// ValueKey('graph:$exerciseId') ALONE, so re-presenting the SAME graph-node id
// (a first-fail retry-in-place, OR an active-arc pass re-present of the floor
// trace) reused the existing Element — `_ExerciseScaffoldState.initState()`
// (the ONLY place that resets the controller phase to idle, clears the canvas,
// and re-arms the instruction hold) never re-ran, so the CTA tap was a SILENT
// no-op. On the fail path the child still had "Clear"; on the active-arc PASS
// path the only CTA was a single "Next exercise" → a permanent dead button that
// forced a force-quit.
//
// These are LIVE-PATH widget tests (project lesson: any wire-into-the-live-path
// change needs live-path proof) — driven through the REAL LetterUnitScreen /
// _UnitShell, not a bare ExerciseScaffold. The fix folds a monotonic
// presentation epoch into the presenter key so every advance yields a DIFFERENT
// key → a fresh mount → initState resets phase + canvas + instruction hold. The
// same epoch covers both triggers (see retry-does-nothing-after-fail.md
// §Resolution + app-stuck-and-teacher-margin-not-understood.md §Resolution
// cause 1 — identical mechanism, different trigger paths).
//
// Pure widget test: no Firebase, no network, an in-memory Drift db, graph off disk.

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/curriculum/child_model_snapshot.dart';
import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/graph_position_repository.dart';
import 'package:qalam/features/letter_unit/exercise_controller.dart';
import 'package:qalam/features/letter_unit/letter_unit_screen.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/providers/audio_providers.dart';
import 'package:qalam/providers/tts_providers.dart';
import 'package:qalam/tutor/child_model_providers.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart';
import 'package:qalam/tutor/tts_coach_speaker.dart';
import 'package:qalam/tutor/tutor_brain.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts.dart';
import 'package:qalam/tutor/tutor_providers.dart';

const _start = 'baa.traceLetter.isolated'; // seeded cursor / the floor trace
const _forward = 'baa.traceLetter.initial'; // the walker pick after the 1st pass

CurriculumGraph _loadGraph() {
  final raw = json.decode(
    File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return CurriculumGraph.fromJson(raw);
}

/// A brain with a coaching line but NO next-exercise plan — the offline walker /
/// policy drives selection (the retry-in-place + arc are offline-parity behaviors).
class _LineOnlyBrain implements TutorBrain {
  @override
  Future<TutorDecision> next(TutorFacts facts) async =>
      const Say('Deeper curve — try again, slower.');
}

class _SeededPositionRepo implements GraphPositionRepository {
  GraphPosition _pos = const GraphPosition(
    childProfileId: 0,
    letterId: 'baa',
    currentExerciseId: _start,
    clearedCompetencies: ['recognize'],
    clearedTiers: [],
  );
  @override
  Future<GraphPosition?> getPosition(String letterId,
          {required int childProfileId}) async =>
      _pos;
  @override
  Future<void> setPosition(GraphPosition position) async => _pos = position;
}

class _CapturingAudioPlayer implements LetterAudioPlayer {
  @override
  Future<void> playLetter(String assetPath) async {}
}

Letter _baa() {
  const body = StrokeSpec(
    order: 1,
    label: 'boat',
    type: 'curve',
    points: [
      [0.2, 0.4],
      [0.5, 0.6],
      [0.8, 0.4],
    ],
    direction: 'rightToLeft',
  );
  const dot = StrokeSpec(
    order: 2,
    label: 'dot',
    type: 'dot',
    points: [
      [0.5, 0.75],
    ],
    direction: 'none',
  );
  return Letter(
    id: 'baa',
    char: 'ب',
    name: const LetterName(ar: 'باء', display: 'baa'),
    introOrder: 2,
    forms: const LetterForms(
        isolated: 'ب', initial: 'بـ', medial: 'ـبـ', final_: 'ـب'),
    referenceStrokes: const [body, dot],
    cleanRepsToAdvance: 1,
    commonMistakes: const [],
    mistakesStatus: 'placeholder',
    signedOff: false,
    contextualForms: const {'isolated': Form(referenceStrokes: [body, dot])},
  );
}

LetterUnitData _baaData() => LetterUnitData(
      unit: const LetterUnit(
        letterId: 'baa',
        sections: [
          UnitSection(id: 'meet', exercises: ['baa.teachCard.meet']),
          UnitSection(id: 'watchTrace', exercises: [_start]),
          UnitSection(id: 'forms', exercises: [_forward]),
          UnitSection(id: 'words', exercises: ['baa.connectWord.baab']),
          UnitSection(id: 'listenWrite', exercises: ['baa.writeWord.dictation']),
          UnitSection(id: 'mastery', exercises: []),
        ],
      ),
      letter: _baa(),
      exercises: {
        for (final e in [
          Exercise(
            id: _start,
            type: 'traceLetter',
            skill: 'formation',
            prompt: const [SayPart('Trace baa.')],
            surface: const Surface(
                mode: 'trace', unit: 'glyph', guideForm: 'isolated', demo: true),
            expected: const Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
            check: const Check(base: 'glyph'),
            feedback: const {'pass': 'Beautiful.', 'shallowBowl': 'Deeper curve.'},
            signedOff: false,
          ),
        ])
          e.id: e,
      },
      words: const [],
    );

/// A fail on the shape criterion — carries the weakest criterion so the policy
/// counts a SAME-criterion streak (two of these enter the remediation arc).
CheckResult _shapeFail() => const CheckResult.fail(
      'shallowBowl',
      weakestCriterion: 'shape',
      criteria: [
        {'criterion': 'shape', 'zone': 'certainlyWrong', 'score': 0.0},
      ],
    );

/// The `ValueKey('graph:<id>#<epoch>')` value currently on screen for [id]
/// (matches with OR without the epoch suffix so the finder survives the fix),
/// or null when that node is not presented.
String? _presentedGraphKey(WidgetTester tester, String id) {
  final matches = find
      .byWidgetPredicate((w) {
        final k = w.key;
        return k is ValueKey<String> &&
            (k.value == 'graph:$id' || k.value.startsWith('graph:$id#'));
      })
      .evaluate()
      .map((e) => (e.widget.key as ValueKey<String>).value)
      .toSet();
  return matches.isEmpty ? null : matches.first;
}

ExercisePhase _phase(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(LetterUnitScreen)),
  );
  return container.read(exerciseControllerProvider).phase;
}

Future<void> _pumpScreen(WidgetTester tester) async {
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
  addTearDown(db.close);
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        graphPositionRepositoryProvider.overrideWithValue(_SeededPositionRepo()),
        curriculumGraphProvider
            .overrideWith((ref, letterId) async => _loadGraph()),
        childModelProvider.overrideWith((ref) async => ChildModelSnapshot.empty()),
        letterUnitDataProvider('baa').overrideWith((ref) async => _baaData()),
        audioPlayerProvider.overrideWithValue(_CapturingAudioPlayer()),
        tutorBrainFactoryProvider
            .overrideWithValue((Map<String, String> f) => _LineOnlyBrain()),
        ttsCoachSpeakerProvider.overrideWithValue(const NoopTtsCoachSpeaker()),
      ],
      child: const MaterialApp(home: LetterUnitScreen(letterId: 'baa')),
    ),
  );
  await tester.pumpAndSettle();
}

/// Enter the trace phase, PASS once, tap Next → the shell swaps into the
/// presenter on the walker's forward pick (_forward). The child is now in
/// selection mode with a fresh presented node.
Future<void> _enterPresenterOnForward(WidgetTester tester) async {
  // 18-15: a seeded real-node cursor RESUMES straight into the presenter, so the
  // trace surface is already on screen — the legacy Watch&Trace "I'll try" gate is
  // bypassed. Guarded so the helper still works for a legacy watch-first setup.
  if (find.text("I'll try").evaluate().isNotEmpty) {
    await tester.tap(find.text("I'll try"));
    await tester.pumpAndSettle();
  }
  tester.widget<WriteSurface>(find.byType(WriteSurface)).onResult!(
        const CheckResult.pass(),
      );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next exercise'));
  await tester.pumpAndSettle();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
      'UAT T3 — a first-fail retry-in-place RE-MOUNTS the same node: '
      '"Try again" resets the canvas/phase (not a silent no-op)',
      (tester) async {
    await _pumpScreen(tester);
    await _enterPresenterOnForward(tester);

    // The presenter is on the forward node in the fresh (idle) state.
    final before = _presentedGraphKey(tester, _forward);
    expect(before, isNotNull,
        reason: 'the child is on the forward node after the first pass');

    // ONE wrong attempt (below the anti-boredom streak, no criterion) → the
    // selection resolves to the SAME id (retry-in-place on a non-tiered node).
    tester.widget<WriteSurface>(find.byType(WriteSurface)).onResult!(
          const CheckResult.fail('shallowBowl'),
        );
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget,
        reason: 'the scorer caught the miss — the fix CTA is shown');
    expect(_phase(tester), ExercisePhase.fix);

    // Tap "Try again" — advanceOnFix routes it to _advanceSelection, which
    // resolves to the SAME forward id.
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    // The presenter key for the SAME id CHANGED (the epoch differs) — a fresh
    // Element mounted, so initState re-ran.
    final after = _presentedGraphKey(tester, _forward);
    expect(after, isNotNull,
        reason: 'the same node is re-presented (retry-in-place)');
    expect(after, isNot(before),
        reason: 'a same-id re-present must produce a DIFFERENT key (the epoch) '
            'so Flutter remounts the scaffold instead of a silent update');

    // The fresh mount reset the phase to idle — the child can write again.
    expect(_phase(tester), ExercisePhase.idle,
        reason: 'initState re-armed the exercise — never stuck in fix');
    expect(find.text('Try again'), findsNothing);
    expect(find.text('Done'), findsOneWidget,
        reason: 'the idle CTA is back — the canvas is writable for a new attempt');
  });

  testWidgets(
      'UAT T6 — an ACTIVE-ARC same-id pass RE-MOUNTS the floor trace: '
      '"Next exercise" is not a permanent dead button (no force-quit)',
      (tester) async {
    await _pumpScreen(tester);
    await _enterPresenterOnForward(tester);

    // Two same-criterion (shape) fails on the forward node → the arc ENTERS and
    // steps DOWN to the floor trace (a DIFFERENT id — that transition remounts
    // fine; it is the SUBSEQUENT same-id pass re-present that used to stick).
    for (var i = 0; i < 2; i++) {
      tester.widget<WriteSurface>(find.byType(WriteSurface)).onResult!(_shapeFail());
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    // The child is now on the floor trace inside an ACTIVE arc.
    final onFloor = _presentedGraphKey(tester, _start);
    expect(onFloor, isNotNull,
        reason: 'the arc stepped down to the guaranteed-doable floor trace');
    expect(_presentedGraphKey(tester, _forward), isNull,
        reason: 'the identical failed exercise is not shown a third time (R1)');

    // PASS the floor trace. Inside the active arc the selection re-presents the
    // SAME floor-trace id; the pass-phase CTA is ONLY "Next exercise".
    tester.widget<WriteSurface>(find.byType(WriteSurface)).onResult!(
          const CheckResult.pass(),
        );
    await tester.pumpAndSettle();
    final beforeNext = _presentedGraphKey(tester, _start);
    expect(beforeNext, isNotNull);
    expect(find.text('Next exercise'), findsOneWidget,
        reason: 'the lone pass-phase CTA (no Clear escape) — the stuck surface');

    // Tap the lone "Next exercise" — it resolves to the SAME floor-trace id.
    await tester.tap(find.text('Next exercise'));
    await tester.pumpAndSettle();

    // The scaffold RE-MOUNTED (key epoch changed) — the button is NOT a
    // permanent no-op; the child moves on without a force-quit.
    final afterNext = _presentedGraphKey(tester, _start);
    expect(afterNext, isNotNull,
        reason: 'the floor trace is re-presented (the arc re-presents it)');
    expect(afterNext, isNot(beforeNext),
        reason: 'a same-id pass re-present must remount (the epoch differs) — '
            'this is the T6 stuck-with-no-escape fix');
    expect(_phase(tester), ExercisePhase.idle,
        reason: 'the fresh mount reset the phase — the dead-button stuck state '
            'is broken');
    expect(find.text('Done'), findsOneWidget,
        reason: 'the idle CTA is back — the child can write the re-presented trace');
  });
}
