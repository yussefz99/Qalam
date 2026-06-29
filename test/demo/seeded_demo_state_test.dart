// DEMO-01 (Plan 16-06, Task 1) — the reliable seeded demo state that fires the
// D-12 hero moment on cue: child is mid-unit on a form they are WOBBLING on (a
// hard tiered form), so a fail there triggers backward remediation
// (remediateOneTier → an easier same-competency exercise re-surfaces).
//
// CRITICAL (ADR-014 / anti-gamification): the seed sets a STARTING state with
// reps BELOW mastery — it must NEVER pre-award a star. isMasteryMet /
// isMasteryMetForPresented (the scorer/mastery rule) owns the star. These tests
// assert the seed leaves the star UNEARNED.
//
// Shape mirrors graph_position_repository_test.dart: an in-memory AppDatabase
// (NativeDatabase.memory()) + a DriftGraphPositionRepository over it. The seed
// itself only touches the durable graph position + the per-exercise rep counts
// (non-PII ids/counts), never strokes / names (GROUND-02 / T-16-06-03).

import 'dart:convert';

// Hide the Drift query-builder matchers that collide with flutter_test's
// isNull/isNotNull (same idiom as the sibling Drift tests).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/curriculum/curriculum_graph_walker.dart' show GraphPosition;
import 'package:qalam/curriculum/mastery_condition.dart'
    show isMasteryMetForPresented;
import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/graph_position_repository.dart';
import 'package:qalam/demo/seeded_demo_state.dart';

/// The presented-essential set the baa unit actually scores (mirrors
/// LetterUnitController._presentedExerciseIds — the intersection the scoped
/// mastery gate evaluates over). The seed must leave at least one of these BELOW
/// its minCleanReps so the star stays unearned.
const Set<String> _presentedBaaEssentials = {
  'baa.teachCard.meet',
  'baa.traceLetter.isolated',
  'baa.traceLetter.initial',
  'baa.traceLetter.medial',
  'baa.connectWord.baab',
  'baa.writeWord.dictation',
  'baa.writeLetter.fromSound',
};

/// Load the real single-source curriculum graph asset (the SAME file the app
/// rails on) so the test exercises the walker against the shipped baa graph.
Future<CurriculumGraph> _loadGraph() async {
  final raw = await rootBundle.loadString(kSeedDemoGraphAsset);
  return CurriculumGraph.fromJson(json.decode(raw) as Map<String, Object?>);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late GraphPositionRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftGraphPositionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('(a) seedDemoState places the child on the wobble form mid-unit', () async {
    await seedDemoState(repo, db: db);

    final pos = await repo.getPosition(kSeedDemoLetterId);
    expect(pos, isNotNull, reason: 'the seed must write a graph position');
    expect(pos!.currentExerciseId, kSeedDemoWobbleExerciseId,
        reason: 'the cursor must sit on the wobble form so the next fail fires '
            'backward remediation');
    // The wobble form is a HARD tiered node (so a fail can step DOWN a tier).
    expect(pos.clearedCompetencies, isNotEmpty,
        reason: 'the child is mid-unit — prereqs of the wobble competency are '
            'cleared so the wobble form is graph-legal');
    expect(pos.clearedTiers, isNotEmpty,
        reason: 'lower tiers are cleared so the wobble tier is reachable and '
            'the easier remediation tier is legal');
  });

  test('(b) seedDemoState is idempotent — re-running resets to the same state',
      () async {
    await seedDemoState(repo, db: db);
    final first = await repo.getPosition(kSeedDemoLetterId);
    final firstReps = await db.exerciseCleanRepsFor(kSeedDemoLetterId);

    // Re-run: the demo must reset to the SAME reliable starting state.
    await seedDemoState(repo, db: db);
    final second = await repo.getPosition(kSeedDemoLetterId);
    final secondReps = await db.exerciseCleanRepsFor(kSeedDemoLetterId);

    expect(second!.currentExerciseId, first!.currentExerciseId);
    expect(second.clearedCompetencies, first.clearedCompetencies);
    expect(second.clearedTiers, first.clearedTiers);
    expect(secondReps, firstReps,
        reason: 're-seeding must overwrite to the identical rep state');
  });

  test('(c) the seeded reps are BELOW mastery — the star is the scorer\'s to '
      'earn, never pre-awarded (ADR-014 / T-16-06-01)', () async {
    await seedDemoState(repo, db: db);

    final graph = await _loadGraph();
    final reps = await db.exerciseCleanRepsFor(kSeedDemoLetterId);

    expect(
      isMasteryMetForPresented(graph, reps, _presentedBaaEssentials),
      isFalse,
      reason: 'the seed sets a STARTING state below mastery — completing the '
          'remediation + the form is what earns the one quiet star',
    );

    // Concretely: the wobble form itself is below its threshold (so finishing
    // it is the act that crosses mastery), proving the seed never pre-awards.
    final wobbleNode = graph.nodes
        .cast<GraphNode?>()
        .firstWhere((n) => n?.exerciseId == kSeedDemoWobbleExerciseId,
            orElse: () => null);
    expect(wobbleNode, isNotNull);
    expect((reps[kSeedDemoWobbleExerciseId] ?? 0) < wobbleNode!.minCleanReps,
        isTrue,
        reason: 'the wobble form must still need clean reps — the star is '
            'unearned until the child completes it');
  });

  test('(d) a fail at the seeded position reaches an EASIER same-competency tier '
      'via the walker (backward remediation reachable — D-12)', () async {
    await seedDemoState(repo, db: db);

    final graph = await _loadGraph();
    final pos = await repo.getPosition(kSeedDemoLetterId);

    // remediateOneTier is the backward move the walker takes on a fail.
    final remediated = graph.remediateOneTier(pos!.currentExerciseId!);
    expect(remediated, isNotNull,
        reason: 'a fail on the wobble form must step DOWN to an easier exercise '
            '(the visible dynamism), never a dead end');

    // The re-surfaced exercise is the SAME competency, a LOWER tier (easier).
    final wobbleTier = graph.tierOf(pos.currentExerciseId!);
    final remediatedTier = graph.tierOf(remediated!);
    expect(graph.competencyOf(remediated), graph.competencyOf(pos.currentExerciseId!),
        reason: 'remediation stays within the same competency');
    expect(graph.tiers.indexOf(remediatedTier!) <
            graph.tiers.indexOf(wobbleTier!),
        isTrue,
        reason: 'the re-surfaced exercise is an EASIER (lower) tier');

    // And it is graph-LEGAL given the seeded cleared state (a real reachable
    // remediation, not an off-graph step).
    expect(
      graph.isLegalSelection(
        remediated,
        clearedTiers: pos.clearedTiers,
        clearedCompetencies: pos.clearedCompetencies,
      ),
      isTrue,
      reason: 'the seeded cleared state makes the remediation reachable on cue',
    );
  });
}
