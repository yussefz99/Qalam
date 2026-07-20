// Quick task 260718-il4 (Stage 1 all-letters-live) — the thaa LIVE-PATH proof.
//
// The whole point of Stage 1: a PROMOTED letter (thaa, ث) runs end-to-end exactly
// like baa. This test mounts a REAL promoted thaa graded node through the LIVE
// `presentGraphExercise` seam — the SAME seam that renders a selected graph node
// on device — and asserts the Phase-19 presentation renders for thaa just as it
// does for baa: the persistent instruction bar (Key('instructionBar')) AND the
// stimulus/write zone (WriteSurface).
//
// LIVE-PATH MOUNT (Phase-15 dead-wire lesson): a bare, stubbed scaffold is exactly
// how "dynamic selection" shipped as dead code in Phase 15. We mount the same wire
// the child walks — never a bare scaffold — so this proves the generic per-type
// presentation "just works" for a promoted letter, not a hand-rigged fixture.
//
// EVERYTHING is loaded from the REAL bundled assets (letters.json, exercises.json,
// units.json, graphs/thaa.json) — the on-device content, not an in-memory fake.

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
import 'package:qalam/features/letter_unit/letter_unit_screen.dart'
    show LetterUnitData;
import 'package:qalam/features/letter_unit/widgets/write_surface.dart'
    show WriteSurface;
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/models/word.dart';
import 'package:qalam/tutor/child_model_providers.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart'
    show curriculumGraphProvider;
import 'package:qalam/tutor/tts_coach_speaker.dart';
import 'package:qalam/providers/tts_providers.dart';

/// The REAL promoted thaa node we present — a well-formed GRADED write-surface
/// node (`writeLetter.writeForm`, mode:write). NOT a teachCard, NOT an
/// `expected:null` placeholder transform node. RETARGETED 2026-07-20 (quick
/// 260720-wcs): the former `completeWord.middle` was made DORMANT (its node removed
/// from the 7-node F2-interim thaa graph), so this now points at a still-live graded
/// form node (one of the 7 kept letter-FORM nodes).
const String kThaaGradedNode = 'thaa.writeLetter.writeForm';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

CurriculumGraph _loadThaaGraph() => CurriculumGraph.fromJson(
      _json('assets/curriculum/graphs/thaa.json').cast<String, Object?>(),
    );

/// The real thaa [Letter] parsed from the bundled letters.json.
Letter _loadThaaLetter() {
  final letters =
      (_json('assets/curriculum/letters.json')['letters'] as List)
          .cast<Map<String, dynamic>>();
  return Letter.fromJson(letters.firstWhere((l) => l['id'] == 'thaa'));
}

/// Every real thaa [Exercise] parsed from the bundled exercises.json, id-keyed.
Map<String, Exercise> _loadThaaExercises() {
  final all = (_json('assets/curriculum/exercises.json')['exercises'] as List)
      .cast<Map<String, dynamic>>();
  return {
    for (final e in all)
      if ((e['id'] as String).startsWith('thaa.'))
        e['id'] as String: Exercise.fromJson(e),
  };
}

/// The real thaa [LetterUnit] parsed from the bundled units.json.
LetterUnit _loadThaaUnit() {
  final units =
      (_json('assets/curriculum/units.json')['units'] as List)
          .cast<Map<String, dynamic>>();
  return LetterUnit.fromJson(units.firstWhere((u) => u['letterId'] == 'thaa'));
}

/// Build a [LetterUnitData] for thaa from the REAL promoted assets — the same
/// shape `letterUnitDataProvider` produces on device.
LetterUnitData _thaaData() => LetterUnitData(
      unit: _loadThaaUnit(),
      letter: _loadThaaLetter(),
      exercises: _loadThaaExercises(),
      words: const <Word>[],
    );

/// The no-op CoachSpeaker (this test asserts presentation, not TTS behaviour).
class _NoopCoachSpeaker implements CoachSpeaker {
  @override
  Future<void> speak(String line) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

/// A clean-root position stub — no Firebase / real repo in this render-only test.
class _NullPositionRepo implements GraphPositionRepository {
  @override
  Future<GraphPosition?> getPosition(String letterId,
          {required int childProfileId}) async =>
      null;
  @override
  Future<void> setPosition(GraphPosition position) async {}
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
      'a PROMOTED thaa graded node mounts + presents through the live '
      'presentGraphExercise seam — instruction bar + stimulus render for thaa '
      'exactly as for baa (Stage 1 all-letters-live)', (tester) async {
    final data = _thaaData();

    // Sanity: the chosen node is a REAL promoted graded thaa write node (not a
    // fallback, not a teachCard, not an expected:null placeholder).
    final node = data.exercise(kThaaGradedNode);
    expect(node, isNotNull,
        reason: '$kThaaGradedNode must be a real promoted thaa exercise');
    expect(node!.surface, isNotNull,
        reason: 'the chosen thaa node must be graded (a write surface), not a '
            'teachCard / placeholder');
    expect(node.surface!.mode, 'write');

    final db =
        AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
    addTearDown(db.close);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          graphPositionRepositoryProvider
              .overrideWithValue(_NullPositionRepo()),
          // The family override returns the THAA graph — the live provider the
          // scaffold reads for its letterId. A thaa unit must rail on the thaa
          // graph, never a silent baa default (per-letter provider, Task 2).
          curriculumGraphProvider
              .overrideWith((ref, letterId) async => _loadThaaGraph()),
          childModelProvider
              .overrideWith((ref) async => ChildModelSnapshot.empty()),
          ttsCoachSpeakerProvider.overrideWithValue(_NoopCoachSpeaker()),
        ],
        child: MaterialApp(
          home: Scaffold(
            // The SAME live seam that renders a selected graph node on device —
            // never a bare scaffold (Phase-15 dead-wire lesson).
            body: presentGraphExercise(
              data: data,
              exerciseId: kThaaGradedNode,
              onNodeResult: (_) {},
              onNext: () {},
              presentEpoch: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // PROOF 1 — the Phase-19 persistent instruction bar renders for thaa.
    expect(find.byKey(const Key('instructionBar')), findsOneWidget,
        reason: 'a promoted thaa graded node must carry the persistent '
            'instruction bar, exactly like baa');

    // PROOF 2 — the stimulus / write zone renders (the child can write thaa).
    expect(find.byType(WriteSurface), findsOneWidget,
        reason: 'a promoted thaa graded write node must present the WriteSurface '
            'stimulus zone — the generic per-type presentation "just works" for '
            'a promoted letter');
  });

  testWidgets(
      'the thaa unit rails on the thaa graph (isAuthored thaa.* true, baa.* '
      'false) — never a silent baa default', (tester) async {
    final graph = _loadThaaGraph();
    expect(graph.letterId, 'thaa');
    expect(graph.isAuthored('thaa.traceLetter.isolated'), isTrue);
    expect(graph.isAuthored(kThaaGradedNode), isTrue);
    expect(graph.isAuthored('baa.traceLetter.isolated'), isFalse,
        reason: 'a thaa unit must never rail on baa exercise ids');
  });
}
