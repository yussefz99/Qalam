// DEMO-01 (Plan 16-06, Task 1) — the reliable seeded demo state that fires the
// D-12 hero moment on cue.
//
// The hero moment: the child is mid-unit, parked on a form they are WOBBLING on
// (`baa.writeWord.dictation` — the hardest `copyWrite` tier, `ghayrManzur`). A
// fail there triggers the offline walker's `remediateOneTier`, which re-surfaces
// an EASIER same-competency exercise (`baa.writeWord.copy`, the `manzur` tier) —
// the visible dynamism. Completing the remediation + the wobble form then crosses
// the on-device mastery condition for exactly ONE quiet star.
//
// ANTI-GAMIFICATION / ADR-014 (T-16-06-01): the seed sets a STARTING state with
// reps BELOW mastery. It NEVER pre-awards a star — `isMasteryMet` /
// `isMasteryMetForPresented` (the scorer/mastery rule) owns the star. The seeded
// wobble form sits one clean-rep short of its threshold, so finishing it in the
// demo is the act that earns the star.
//
// DEMO/DEBUG-GATED (T-16-06-03): this is wired in `lib/main.dart` behind the
// existing `--dart-define=DEMO=true` flag (and only in `kDebugMode`), never on the
// child-facing default boot. It writes ONLY non-PII graph state — the durable
// graph position (ids) + per-exercise clean-rep counts (ids/counts). No strokes,
// no nickname, no geometry (GROUND-02).
//
// IDEMPOTENT: re-running overwrites to the identical reliable starting state, so
// the demo can be re-armed between runs on stage.

import '../data/app_database.dart';
import '../data/graph_position_repository.dart';

/// The single-source curriculum-graph asset the seed's hero moment rides (the
/// SAME file the app + walker rail on — D-04).
const String kSeedDemoGraphAsset = 'assets/curriculum/curriculum_graph.json';

/// The letter the demo seeds.
const String kSeedDemoLetterId = 'baa';

/// The WOBBLE form the seed parks the child on: the hardest `copyWrite` tier
/// (`ghayrManzur`). A fail here steps DOWN one tier (→ `baa.writeWord.copy`,
/// `manzur`) — the backward-remediation hero moment (D-12).
const String kSeedDemoWobbleExerciseId = 'baa.writeWord.dictation';

/// The clean-rep target the seed parks the wobble form one short of. The baa
/// graph sets `minCleanReps: 3` for the essential nodes; the wobble form is
/// seeded at [_wobbleSeedReps] (below 3) so the star is the scorer's to earn.
const int _masteryThreshold = 3;
const int _wobbleSeedReps = 2;

/// The presented-essential exercises the baa unit scores (mirrors
/// `LetterUnitController._presentedExerciseIds`). The seed banks each of these at
/// the mastery threshold EXCEPT the wobble form, which is parked one short — so
/// the star stays unearned until the child finishes the wobble form on stage.
const List<String> _presentedEssentials = [
  'baa.teachCard.meet',
  'baa.traceLetter.isolated',
  'baa.traceLetter.initial',
  'baa.traceLetter.medial',
  'baa.connectWord.baab',
  'baa.writeWord.dictation', // the wobble form — seeded BELOW threshold.
  'baa.writeLetter.fromSound',
];

/// The competencies already cleared at the seeded position. `copyWrite` (the
/// wobble form's competency) has prerequisites `recognize` → `positionalForms`;
/// clearing both makes the wobble form graph-legal AND makes the `manzur`
/// remediation target legal (backward remediation passes — Pitfall 3).
const List<String> _seededClearedCompetencies = ['recognize', 'positionalForms'];

/// The إملاء tiers already cleared. Clearing `manqul` + `manzur` makes the
/// wobble's `ghayrManzur` tier reachable AND keeps the easier `manzur`
/// remediation target legal (a lower tier of a reached competency is reachable).
const List<String> _seededClearedTiers = ['manqul', 'manzur'];

/// Seed the reliable demo starting state for the D-12 hero moment.
///
/// Writes (idempotently):
///   1. a durable [GraphPosition] for baa whose cursor is the WOBBLE form, with
///      the prereq competencies + lower tiers cleared (so the wobble form is
///      legal and the easier remediation tier is reachable on a fail), via
///      [GraphPositionRepository.setPosition]; and
///   2. per-exercise clean-rep counts that bank every presented essential at the
///      mastery threshold EXCEPT the wobble form (parked one short), via
///      [AppDatabase.setExerciseCleanReps].
///
/// The seed NEVER records mastery / awards a star — the scorer owns it (ADR-014).
/// Re-running overwrites to the identical state (idempotent).
///
/// Inject [repo] for tests; pass the same-backing [db] so the rep counts and the
/// graph position are written to one store.
Future<void> seedDemoState(
  GraphPositionRepository positionRepo, {
  required AppDatabase db,
}) async {
  // ADR-018: seed the CURRENT in-file child (the demo boots one profile). Resolve
  // its id from the db (the unassigned sentinel when none exists yet) so the seed
  // writes exactly the rows the live unit — reading under the SAME child — resumes
  // on. Only non-PII graph state (ids/counts) is written (GROUND-02).
  final profile = await db.getProfile();
  final childProfileId = profile?.id ?? kUnassignedChildProfileId;

  // 1) Bank the per-exercise clean reps (write-through, idempotent overwrite).
  //    Every presented essential is at the threshold except the wobble form,
  //    which is parked one short so finishing it earns the one quiet star.
  for (final exerciseId in _presentedEssentials) {
    final reps = exerciseId == kSeedDemoWobbleExerciseId
        ? _wobbleSeedReps
        : _masteryThreshold;
    await db.setExerciseCleanReps(
      childProfileId: childProfileId,
      letterId: kSeedDemoLetterId,
      exerciseId: exerciseId,
      cleanReps: reps,
    );
  }

  // 2) Park the durable resume cursor on the wobble form with the prereq
  //    competencies + lower tiers cleared (legal wobble + reachable remediation).
  await positionRepo.setPosition(
    GraphPosition(
      childProfileId: childProfileId,
      letterId: kSeedDemoLetterId,
      currentExerciseId: kSeedDemoWobbleExerciseId,
      clearedCompetencies: _seededClearedCompetencies,
      clearedTiers: _seededClearedTiers,
    ),
  );
}
