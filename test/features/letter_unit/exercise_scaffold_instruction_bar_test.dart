// Phase 19-01 (Wave 0) — QP-01/QP-02 RED contract: the persistent instruction bar.
//
// INTENTIONALLY RED until 19-02. The scaffold does not yet render a persistent
// per-type instruction strip (`Key('instructionBar')`), and the 18-12 "Hear
// again" pill still exists as a SECOND replay affordance. This test names the
// exact D-01/D-02/D-03 contract 19-02 must satisfy with ZERO test edits:
//   • a graded (non-teachCard) question renders ONE instruction bar whose text is
//     the PER-TYPE template (completeWord → "Write the missing letter"), sourced
//     from `exercise.type` — NOT the `say` line (Pitfall 6),
//   • exactly ONE replay affordance on screen (the old "Hear again" pill is gone),
//   • tapping the bar re-speaks the spoken line (re-hear),
//   • the bar is HIDDEN on a teachCard (`_hasInstruction` false).
//
// LIVE-PATH MOUNT (Phase-15 dead-wire lesson): the graded assertions mount the
// real scaffold THROUGH `presentGraphExercise` — the same seam that renders a
// selected graph node on device — never a bare, stubbed scaffold. A bare-scaffold
// test is exactly how the Phase-15 "dynamic selection" shipped as dead code; the
// bar must prove itself on the wire the child actually walks.

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/curriculum/child_model_snapshot.dart';
import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/graph_position_repository.dart';
import 'package:qalam/features/letter_unit/exercise_presenter.dart';
import 'package:qalam/features/letter_unit/letter_unit_screen.dart' show LetterUnitData;
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/models/word.dart';
import 'package:qalam/tutor/child_model_providers.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart' show curriculumGraphProvider;
import 'package:qalam/tutor/tts_coach_speaker.dart';
import 'package:qalam/providers/tts_providers.dart';

/// The per-type instruction-bar template for `completeWord` (UI-SPEC Copywriting
/// Contract). This is what the bar must show — NOT the exercise's `say` line.
const _completeWordTemplate = 'Write the missing letter';

/// A distinct `say` line, deliberately different from the template so the test
/// can prove the bar renders the TEMPLATE, never a transcript of `say`.
const _sayLine = 'Finish the word — write the missing baa, slowly.';

CurriculumGraph _loadGraph() {
  final raw = json.decode(
    File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return CurriculumGraph.fromJson(raw);
}

/// A CoachSpeaker spy over the no-op posture — records every `speak`/`stop` call
/// so the test can prove tapping the bar re-invokes the spoken-line seam.
class _SpyCoachSpeaker implements CoachSpeaker {
  final List<String> speakCalls = <String>[];
  int stopCalls = 0;

  @override
  Future<void> speak(String line) async => speakCalls.add(line);

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<void> dispose() async {}
}

/// The durable resume cursor stub — a clean root (no position) so nothing depends
/// on Firebase / a real repo in this render-only test.
class _NullPositionRepo implements GraphPositionRepository {
  @override
  Future<GraphPosition?> getPosition(String letterId,
          {required int childProfileId}) async =>
      null;

  @override
  Future<void> setPosition(GraphPosition position) async {}
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

/// A graded `completeWord` node — a non-teachCard surface whose per-type bar text
/// ("Write the missing letter") differs from its `say` line.
Exercise _completeWord() => const Exercise(
      id: 'baa.completeWord.middle',
      type: 'completeWord',
      skill: 'spelling',
      prompt: [
        SayPart(_sayLine),
        TextPart(text: 'با_letter_', gaps: [Gap(kind: 'letter', index: 1)]),
      ],
      surface: Surface(mode: 'write', unit: 'glyph'),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'medial')),
      check: Check(base: 'glyph'),
      feedback: {'pass': 'Beautiful.'},
      signedOff: false,
    );

/// A teachCard node (surface == null) — the bar must NOT render here.
Exercise _teachCard() => const Exercise(
      id: 'baa.teachCard.meet',
      type: 'teachCard',
      skill: 'comprehension',
      prompt: [SayPart('Meet the letter baa.')],
      signedOff: false,
    );

LetterUnitData _data(Exercise exercise) => LetterUnitData(
      unit: LetterUnit(
        letterId: 'baa',
        sections: [
          UnitSection(id: 'words', exercises: [exercise.id]),
        ],
      ),
      letter: _baa(),
      exercises: {exercise.id: exercise},
      words: const <Word>[],
    );

/// Pump [exercise] through the LIVE presenter seam (`presentGraphExercise`) with
/// the real graph + a recording TTS spy. Returns the spy so the test can assert
/// the tap-to-replay behaviour.
Future<_SpyCoachSpeaker> _pumpNode(
  WidgetTester tester,
  Exercise exercise,
) async {
  final spy = _SpyCoachSpeaker();
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
  addTearDown(db.close);
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        graphPositionRepositoryProvider.overrideWithValue(_NullPositionRepo()),
        curriculumGraphProvider
            .overrideWith((ref, letterId) async => _loadGraph()),
        childModelProvider.overrideWith((ref) async => ChildModelSnapshot.empty()),
        ttsCoachSpeakerProvider.overrideWithValue(spy),
      ],
      child: MaterialApp(
        home: Scaffold(
          // The SAME live seam that renders a selected graph node on device —
          // never a bare scaffold (Phase-15 dead-wire lesson).
          body: presentGraphExercise(
            data: _data(exercise),
            exerciseId: exercise.id,
            onNodeResult: (_) {},
            onNext: () {},
            presentEpoch: 1,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return spy;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
      'a graded question renders ONE instruction bar with the per-type template '
      '(not the say line) on the live presentGraphExercise path (QP-01)',
      (tester) async {
    await _pumpNode(tester, _completeWord());

    // The persistent instruction strip exists (RED until 19-02 builds it).
    final bar = find.byKey(const Key('instructionBar'));
    expect(bar, findsOneWidget,
        reason: 'every graded non-teachCard question must carry a persistent '
            'instruction bar (D-01) — readable with sound off');

    // Its text is the PER-TYPE template resolved from exercise.type (D-02),
    // NOT the spoken `say` line (Pitfall 6 — the say line is the bubble layer).
    expect(find.descendant(of: bar, matching: find.text(_completeWordTemplate)),
        findsOneWidget,
        reason: 'the bar shows the completeWord template "Write the missing '
            'letter", keyed on exercise.type');
    expect(find.descendant(of: bar, matching: find.text(_sayLine)), findsNothing,
        reason: 'the bar is NOT a transcript of the say line (Pitfall 6)');
  });

  testWidgets(
      'exactly ONE replay affordance — the 18-12 "Hear again" pill is absorbed '
      'into the bar (QP-02, D-03)', (tester) async {
    await _pumpNode(tester, _completeWord());

    // The old standalone pill is GONE — one replay affordance, never two
    // (the Phase-07 double-Hear-button device bug is the cautionary precedent).
    expect(find.text('Hear again'), findsNothing,
        reason: 'the _HearAgainCta pill is folded into the instruction bar');
    expect(find.byKey(const Key('instructionBar')), findsOneWidget,
        reason: 'the bar is the single replay affordance');
  });

  testWidgets('tapping the instruction bar re-speaks the spoken line (QP-02)',
      (tester) async {
    final spy = await _pumpNode(tester, _completeWord());

    // Ignore the auto-speak-once that fires on mount; measure only the tap.
    spy.speakCalls.clear();
    await tester.tap(find.byKey(const Key('instructionBar')));
    await tester.pumpAndSettle();

    expect(spy.speakCalls, isNotEmpty,
        reason: 'the whole bar is one tap target that re-invokes '
            '_speakInstructionThenRelease (re-hear)');
  });

  testWidgets('the instruction bar is HIDDEN on a teachCard (_hasInstruction)',
      (tester) async {
    // A teachCard has no graded surface — the presenter routes it away from the
    // WriteSurface path and the bar must not appear (D-01 / _hasInstruction).
    await _pumpNode(tester, _teachCard());

    expect(find.byKey(const Key('instructionBar')), findsNothing,
        reason: 'teachCard carries no instruction bar (_hasInstruction false)');
  });
}
