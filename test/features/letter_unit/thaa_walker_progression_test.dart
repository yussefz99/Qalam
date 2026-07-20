// Quick task 260718-nft — the thaa WALKER-PROGRESSION proof (the day's hard lesson).
//
// The owner tested thaa on device: the Phase-19 PRESENTATION was right, but the
// PROGRESSION was the OLD static section walk. `thaa_unit_live_path_test.dart`
// already pins that a promoted thaa node RENDERS through the live seam — but a
// presentation-only test is EXACTLY how this bug shipped (a rendered scaffold that
// never actually advanced graph-driven). So this test does the thing that test did
// NOT: it drives SCORED RESULTS through the scaffold's REAL apply path
// (`WriteSurface.onResult == _onResult`, the same seam the child's canvas fires) and
// asserts WHAT THE CHILD ADVANCES TO — the WALKER's pick, never the static section
// successor.
//
// ROOT CAUSE this pins (fixed in 260718-nft): `_isAgentPath => letter.id == 'baa'`
// gated BOTH the server/agent legs AND the graph SELECTION (beginSelection /
// selectNextWhenDecided) — so for a non-baa graph letter the walker never ran,
// `selectionActive` never flipped, and the screen stayed on the static walk. The
// fix splits an [_isGraphRailed] axis (any loaded graph letter) off [_isAgentPath]
// (baa-only). thaa has NO agent — its offline CurriculumGraphWalker supplies
// selection, driven here through the AuthoredFallbackBrain (plan == null → walker).
//
// EVERYTHING loads from the REAL bundled assets (letters.json, exercises.json,
// graphs/thaa.json) — the on-device content, not an in-memory fake.

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
// The walker's PURE GraphPosition (letterId + cursor + cleared state) — aliased so
// it never collides with the repo's durable GraphPosition (which carries a
// childProfileId). The seed uses the repo type; the walker/policy use this one.
import 'package:qalam/curriculum/curriculum_graph_walker.dart'
    show CurriculumGraphWalker;
import 'package:qalam/curriculum/curriculum_graph_walker.dart' as walker
    show GraphPosition;
import 'package:qalam/curriculum/selection_policy.dart' show SelectionPolicy;
import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/graph_position_repository.dart';
import 'package:qalam/features/letter_unit/letter_unit_controller.dart';
import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/features/letter_unit/widgets/teacher_margin_panel.dart'
    show TeacherMarginPanel;
import 'package:qalam/features/letter_unit/widgets/write_surface.dart'
    show WriteSurface;
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/tutor/child_model_providers.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart'
    show curriculumGraphProvider;
import 'package:qalam/tutor/tts_coach_speaker.dart';
import 'package:qalam/tutor/tutor_facts.dart';
import 'package:qalam/providers/tts_providers.dart';

// ── The two cursor nodes we drive scored attempts from ────────────────────────

/// The PASS-path cursor: a thaa node whose walker forward pick is deterministic
/// and legal once `recognize` is cleared. `traceLetter.isolated` (positionalForms,
/// tier null) → the walker walks to `traceLetter.initial` (the next legal node).
const String kPassCursor = 'thaa.traceLetter.isolated';

/// The FAIL-path cursor. RETARGETED 2026-07-20 (quick 260720-wcs, F2-interim): the
/// former ramp node `writeWord.dictation` was made DORMANT (its node removed from the
/// 7-node thaa graph). thaa is now FORM-ONLY (all 7 kept nodes are tier-null
/// recognize/positionalForms), so there is no lower إملاء tier to step down to — the
/// walker's fail behavior on a tier-null form node is DRILL-IN-PLACE at the floor.
/// `traceLetter.medial` (positionalForms, tier null) is a legal live form node.
const String kFailCursor = 'thaa.traceLetter.medial';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

CurriculumGraph _loadThaaGraph() => CurriculumGraph.fromJson(
      _json('assets/curriculum/graphs/thaa.json').cast<String, Object?>(),
    );

/// The real thaa [Letter] parsed from the bundled letters.json.
Letter _loadThaaLetter() {
  final letters = (_json('assets/curriculum/letters.json')['letters'] as List)
      .cast<Map<String, dynamic>>();
  return Letter.fromJson(letters.firstWhere((l) => l['id'] == 'thaa'));
}

/// One real thaa [Exercise] parsed from the bundled exercises.json.
Exercise _loadThaaExercise(String id) {
  final all = (_json('assets/curriculum/exercises.json')['exercises'] as List)
      .cast<Map<String, dynamic>>();
  return Exercise.fromJson(all.firstWhere((e) => e['id'] == id));
}

/// The no-op CoachSpeaker (this test asserts progression, not TTS).
class _NoopCoachSpeaker implements CoachSpeaker {
  @override
  Future<void> speak(String line) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

/// A durable resume cursor seeded so the child is ON [currentExerciseId] with the
/// given cleared state — the rail the policy + walker narrow within.
class _SeededPositionRepo implements GraphPositionRepository {
  _SeededPositionRepo(this._pos);
  GraphPosition _pos;

  @override
  Future<GraphPosition?> getPosition(String letterId,
          {required int childProfileId}) async =>
      _pos;

  @override
  Future<void> setPosition(GraphPosition position) async => _pos = position;
}

/// Pump the real ExerciseScaffold on [exerciseId] with a STARTED thaa controller
/// seeded at [seed], the real thaa graph, an in-memory db, and an empty profile.
/// Returns the started controller so the test reads its durable cursor after a
/// scored attempt — the SAME durable cursor the screen swaps the presenter to.
Future<LetterUnitController> _pumpThaa(
  WidgetTester tester, {
  required String exerciseId,
  required GraphPosition seed,
}) async {
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
  addTearDown(db.close);
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        graphPositionRepositoryProvider
            .overrideWithValue(_SeededPositionRepo(seed)),
        // The family override returns the THAA graph — the live provider the
        // scaffold + controller read for their letterId (per-letter, never a baa
        // default). The walker rails on THIS graph.
        curriculumGraphProvider
            .overrideWith((ref, letterId) async => _loadThaaGraph()),
        childModelProvider
            .overrideWith((ref) async => ChildModelSnapshot.empty()),
        ttsCoachSpeakerProvider.overrideWithValue(_NoopCoachSpeaker()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ExerciseScaffold(
            exercise: _loadThaaExercise(exerciseId),
            letter: _loadThaaLetter(),
            graphExerciseId: exerciseId,
            // The selection-driven presenter advances on a fail too (the
            // remediation after a scored miss) — mirror it here.
            advanceOnFix: true,
          ),
        ),
      ),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ExerciseScaffold)),
  );
  // Start the unit controller (the screen normally does this) so selection runs.
  // start() now WARMS the thaa graph unconditionally (260718-nft), so the
  // scaffold's synchronous graph reads see it on the FIRST attempt.
  final controller = container.read(letterUnitControllerProvider('thaa').notifier);
  await controller.start(letterId: 'thaa', total: 6);
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
      'a thaa PASS advances the durable cursor to the WALKER\'s nextForward '
      'through the live scaffold apply path — NOT the static section successor',
      (tester) async {
    // Seed the child ON the pass cursor with `recognize` cleared (so the
    // positionalForms forward nodes are legal candidates).
    const seed = GraphPosition(
      childProfileId: 0,
      letterId: 'thaa',
      currentExerciseId: kPassCursor,
      clearedCompetencies: ['recognize'],
      clearedTiers: [],
    );
    final controller =
        await _pumpThaa(tester, exerciseId: kPassCursor, seed: seed);

    // Sanity: the seeded cursor is the pass cursor before the attempt. (A real
    // authored seeded cursor RESUMES selection mode on start() — 18-15 resume-in-
    // place — so selectionActive is already true here; that is expected. The pin
    // below is the CURSOR ADVANCE the scored PASS drives.)
    expect(controller.state.currentExerciseId, kPassCursor);

    // Compute the WALKER's expected forward pick INDEPENDENTLY from the graph —
    // the offline CurriculumGraphWalker over the same seeded position on a pass.
    // This is what a thaa child (no agent) must advance to.
    final graph = _loadThaaGraph();
    final walker = CurriculumGraphWalker(graph);
    const passFacts = TutorFacts(
      letterId: 'thaa',
      section: kPassCursor,
      passed: true,
    );
    final walkerPick = walker.selectNext(passFacts, _asWalkerPos(seed));
    expect(walkerPick, isNotNull,
        reason: 'the walker must have a legal forward pick from $kPassCursor');
    // The walker's pick must DIFFER from the current node — a real advance, and
    // from a static "same section" no-op.
    expect(walkerPick, isNot(kPassCursor));

    // Drive a scored PASS through the public seam (== the canvas completion path).
    final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
    ws.onResult!(const CheckResult.pass());
    await tester.pumpAndSettle(); // brain resolves → selection threads the walker.

    // THE PIN: the durable cursor the child ACTUALLY advances to IS the walker's
    // forward pick — graph-driven progression, not the static section walk. And
    // selection is now ACTIVE (the screen enters the presenter on this node).
    expect(controller.state.currentExerciseId, walkerPick,
        reason: 'a thaa PASS must walk to the graph\'s nextForward on the LIVE '
            'apply path — the walker ran, not the static section successor');
    expect(controller.state.selectionActive, isTrue,
        reason: 'the first scored thaa moment hands control to the selector '
            '(selectionActive) — the fix for the static-walk device bug');
  });

  testWidgets(
      'a thaa FAIL drills in place at the form-only floor on the live scaffold '
      'apply path — the walker ran, NEVER the static forward section walk',
      (tester) async {
    // F2-interim (quick 260720-wcs): thaa is now FORM-ONLY — all 7 kept nodes are
    // tier-null recognize/positionalForms, so there is NO lower إملاء tier to step
    // down to. The walker's fail behavior on a tier-null form node is therefore
    // DRILL-IN-PLACE at the floor (`remediateOneTier == null` → re-present the same
    // legal node). That is STILL a walker decision and it is the OPPOSITE of the old
    // device bug (a fail advancing to the next STATIC section). Seed on a legal form
    // node with `recognize` cleared. (The tier-step-down remediation invariant itself
    // is covered by the walker/remediation_arc tests on ramp-bearing graphs.)
    const seed = GraphPosition(
      childProfileId: 0,
      letterId: 'thaa',
      currentExerciseId: kFailCursor,
      clearedCompetencies: ['recognize'],
      clearedTiers: [],
    );
    final controller =
        await _pumpThaa(tester, exerciseId: kFailCursor, seed: seed);

    expect(controller.state.currentExerciseId, kFailCursor);

    final graph = _loadThaaGraph();
    final walker = CurriculumGraphWalker(graph);

    // thaa is form-only: no ramp tier below a positionalForms node → no remediation.
    expect(graph.remediateOneTier(kFailCursor), isNull,
        reason: '$kFailCursor is a tier-null form node — thaa has no إملاء ramp '
            'to step down to after the F2-interim dormancy');

    // The walker's fail pick from a tier-null form node = drill in place (the same
    // legal node). Compute it independently from the graph.
    const failFacts = TutorFacts(
      letterId: 'thaa',
      section: kFailCursor,
      passed: false,
      mistakeId: 'missingDot',
      weakestCriterion: 'dot',
    );
    final walkerFailPick = walker.selectNext(failFacts, _asWalkerPos(seed));
    expect(walkerFailPick, kFailCursor,
        reason: 'a form-node fail drills in place at the floor (walker)');

    // Contrast: a PASS from the same node ADVANCES (the forward walk's move). So the
    // fail STAYING put is exactly what distinguishes the walker from the static walk.
    const passFacts =
        TutorFacts(letterId: 'thaa', section: kFailCursor, passed: true);
    final walkerForward = walker.selectNext(passFacts, _asWalkerPos(seed));
    expect(walkerForward, isNot(kFailCursor),
        reason: 'a pass advances — so drill-in-place on a fail is distinguishable '
            'from a forward section step');

    // The SelectionPolicy narrows to a fail candidate set that CONTAINS the
    // drill-in-place node (retry-in-place, never the forward frontier on a fail).
    final outcome = SelectionPolicy(graph).narrow(failFacts, _asWalkerPos(seed));
    expect(outcome.candidates, contains(kFailCursor),
        reason: 'the fail candidate set is remediation + retry-in-place, never '
            'the forward frontier');

    // Drive a scored FAIL through the public seam (the canvas miss path).
    final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
    ws.onResult!(const CheckResult.fail('missingDot', weakestCriterion: 'dot'));
    await tester.pumpAndSettle();

    // THE PIN: a thaa fail drills in place on the LIVE apply path (the walker's fail
    // pick) — NOT the forward section successor. The walker ran, not the static walk.
    expect(controller.state.currentExerciseId, walkerFailPick,
        reason: 'a thaa FAIL drills in place on the live path (walker), never the '
            'static forward section walk');
    expect(controller.state.currentExerciseId, isNot(walkerForward),
        reason: 'a fail must NOT advance forward like the old static-walk bug');
    expect(controller.state.selectionActive, isTrue);
  });

  testWidgets(
      'baa regression: a thaa mount NEVER builds the agent legs (teacher\'s '
      'margin / Teacher\'s Eye) — those stay gated to baa (_isAgentPath)',
      (tester) async {
    const seed = GraphPosition(
      childProfileId: 0,
      letterId: 'thaa',
      currentExerciseId: kPassCursor,
      clearedCompetencies: ['recognize'],
      clearedTiers: [],
    );
    await _pumpThaa(tester, exerciseId: kPassCursor, seed: seed);

    // The child-facing Teacher's Margin is built ONLY on the agent path
    // (`_isAgentPath && !_isTeachCard`) — a thaa mount (letter.id != 'baa') must
    // NOT build it. This is the byte-identical-baa guard: splitting the SELECTION
    // gate off [_isAgentPath] left the agent/teacher-eye legs baa-only.
    expect(find.byType(TeacherMarginPanel), findsNothing,
        reason: 'the agent-only Teacher\'s Margin never renders for a non-baa '
            'letter — the agent legs stay gated to baa');

    // The WriteSurface still renders (thaa is graph-railed + graded) — proving the
    // scaffold IS live for thaa, just without the agent legs.
    expect(find.byType(WriteSurface), findsOneWidget);
  });
}

/// Adapt the seeded durable [GraphPosition] (the repo shape) to the walker's pure
/// [walker.GraphPosition] value type (letterId + cursor + cleared state).
walker.GraphPosition _asWalkerPos(GraphPosition seed) => walker.GraphPosition(
      letterId: seed.letterId,
      currentExerciseId: seed.currentExerciseId!,
      clearedCompetencies: seed.clearedCompetencies,
      clearedTiers: seed.clearedTiers,
    );
