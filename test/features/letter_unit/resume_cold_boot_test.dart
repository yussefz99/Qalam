// Phase 18-15 Task 2 — a cold relaunch RESUMES in place (UAT T7).
//
// The LIVE-PATH proof the debug flagged as missing
// (.planning/debug/resume-position-lost-on-relaunch.md): the existing live tests
// pump ONE continuous widget instance through a session and never TEAR DOWN +
// RE-MOUNT LetterUnitScreen — so the "started from scratch on relaunch" regression
// shipped unnoticed. This drives a scored session over a SHARED in-memory Drift
// store (D-09 shape) until the durable cursor is a real mid-unit graph node, then
// FORCE-QUITS (tears the tree down) and RELAUNCHES a fresh LetterUnitScreen over
// the SAME database. It must re-enter PRESENTER mode on the SAVED node — not the
// Meet / section-0 card. A fresh install (no saved position) still starts at Meet.
//
// Pure widget test: no Firebase, no network, a shared in-memory Drift executor,
// the real DriftGraphPositionRepository (the durable store that must survive the
// re-mount — the whole point), graph off disk.

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
import 'package:qalam/features/letter_unit/letter_unit_screen.dart';
import 'package:qalam/features/letter_unit/sections/meet_section.dart';
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

const _start = 'baa.traceLetter.isolated';

CurriculumGraph _fullGraph() => CurriculumGraph.fromJson(
      json.decode(
        File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
      ) as Map<String, Object?>,
    );

class _LineOnlyBrain implements TutorBrain {
  @override
  Future<TutorDecision> next(TutorFacts facts) async => const Say('Nice.');
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
          UnitSection(id: 'forms', exercises: ['baa.traceLetter.initial']),
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
            expected:
                const Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
            check: const Check(base: 'glyph'),
            feedback: const {'pass': 'Beautiful.'},
            signedOff: false,
          ),
        ])
          e.id: e,
      },
      words: const [],
    );

/// Mount a fresh LetterUnitScreen over [db] + [graph]. The graph-position
/// repository is the REAL [DriftGraphPositionRepository] over the shared [db] —
/// the durable store that must survive the tear-down + re-mount (that is the whole
/// point; a new in-memory notifier is torn down + rebuilt, but the Drift row
/// persists). The ProviderScope is built INLINE in the pumpWidget call (mirrors
/// the sibling live tests so riverpod_lint sees the scope's child in context).
Future<void> _mount(
  WidgetTester tester,
  AppDatabase db,
  CurriculumGraph graph,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        graphPositionRepositoryProvider
            .overrideWithValue(DriftGraphPositionRepository(db)),
        curriculumGraphProvider.overrideWith((ref, letterId) async => graph),
        childModelProvider
            .overrideWith((ref) async => ChildModelSnapshot.empty()),
        letterUnitDataProvider('baa').overrideWith((ref) async => _baaData()),
        audioPlayerProvider.overrideWithValue(_CapturingAudioPlayer()),
        tutorBrainFactoryProvider
            .overrideWithValue((Map<String, String> f) => _LineOnlyBrain()),
        ttsCoachSpeakerProvider.overrideWithValue(const NoopTtsCoachSpeaker()),
      ],
      child: const MaterialApp(home: LetterUnitScreen(letterId: 'baa')),
    ),
  );
}

/// The presented graph-node finder, tolerant of the 18-12 epoch suffix.
Finder _graphNode(String id) => find.byWidgetPredicate((w) {
      final k = w.key;
      return k is ValueKey<String> &&
          (k.value == 'graph:$id' || k.value.startsWith('graph:$id#'));
    });

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
      'a force-quit + relaunch mid-unit resumes on the SAVED node (presenter '
      'mode), not the Meet / section-0 card', (tester) async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
    addTearDown(db.close);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final graph = _fullGraph();

    // Seed a position so the session boots on Watch&Trace via the LEGACY walk
    // (currentExerciseId null → selectionActive false), then DRIVE a scored pass
    // so the selector advances + PERSISTS a real forward-node cursor to Drift.
    await DriftGraphPositionRepository(db).setPosition(const GraphPosition(
      childProfileId: 0,
      letterId: 'baa',
      currentExerciseId: null,
      clearedCompetencies: ['recognize'],
    ));

    // ── MOUNT #1 — drive one scored pass ─────────────────────────────────────
    await _mount(tester, db, graph);
    await tester.pumpAndSettle();
    // Watch&Trace opens on the Watch phase — reveal the surface, then PASS.
    await tester.tap(find.text("I'll try"));
    await tester.pumpAndSettle();
    tester.widget<WriteSurface>(find.byType(WriteSurface)).onResult!(
          const CheckResult.pass(),
        );
    await tester.pumpAndSettle(); // brain resolves → selectNext persists the cursor

    // The durable cursor is now a real mid-unit graph node.
    final saved =
        await DriftGraphPositionRepository(db).getPosition('baa', childProfileId: 0);
    final resumedId = saved?.currentExerciseId;
    expect(resumedId, isNotNull,
        reason: 'the session advanced + persisted a cursor');
    expect(graph.isAuthored(resumedId), isTrue,
        reason: 'the persisted cursor is a real graph node');

    // ── FORCE-QUIT — tear the whole tree (and its ProviderScope) down ────────
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    // ── RELAUNCH — a FRESH LetterUnitScreen over the SAME database ────────────
    await _mount(tester, db, graph);
    await tester.pumpAndSettle();

    // It resumes IN PLACE — the presenter renders the SAVED node, not section 0.
    expect(_graphNode(resumedId!), findsOneWidget,
        reason: 'a relaunch resumes on the exact node the child left off (T7)');
    expect(find.byType(MeetSection), findsNothing,
        reason: 'the relaunch must NOT restart at the Meet / section-0 card');
  });

  testWidgets(
      'a fresh install (no saved position) still starts at Meet — the legacy '
      'walk (no false resume)', (tester) async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
    addTearDown(db.close);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await _mount(tester, db, _fullGraph());
    await tester.pumpAndSettle();

    expect(find.byType(MeetSection), findsOneWidget,
        reason: 'a truly-fresh child opens on Meet via the legacy walk');
    // No presenter node renders on a fresh boot (nothing to resume).
    expect(
      find.byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('graph:')),
      findsNothing,
      reason: 'no durable cursor → no presenter resume',
    );
  });
}
