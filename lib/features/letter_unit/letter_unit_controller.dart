// LetterUnitController — the unit-level sequencing + DURABLE resume + mastery
// state machine for the baa Letter Unit (Plan 07-06, rewired in 15-05 for
// DYN-02). Riverpod-only (CLAUDE.md Decided: Riverpod, never BLoC/GetX).
//
// Phase 15 rewire (DYN-02 / Open Q1 / D-06 / D-08 / Pitfall 2):
//   • RESUME is now DURABLE. The old in-memory `_resumeByLetter` map (lost on an
//     app restart) is replaced by the Drift `LetterGraphPosition` table via
//     `graphPositionRepository` — re-entering the unit after a relaunch restores
//     the child's graph position (D-08). `getPosition` is a Future (Pitfall 6).
//   • SELECTION is graph-driven. The next step is chosen by the `ExerciseSelector`
//     router (online RemoteAgent plan.nextExerciseId when graph-legal, else the
//     offline CurriculumGraphWalker) — a FAIL re-surfaces a remediation (one tier
//     down within the competency), NOT the next linear section (Pitfall 5). The
//     selected exercise id is persisted as the resume cursor.
//   • The STAR is gated strictly on real mastery. The old
//     `state.atMastery → recordMastery(cleanReps:0)` auto-write FIRED ON MERE
//     NAVIGATION (Pitfall 2). It is DELETED. `recordMasteryIfMet` now records
//     mastery ONLY when `isMasteryMet(graph, perExerciseCleanReps)` is true — the
//     on-device condition over the essential 70/30 core (D-06, ADR-014 trust
//     boundary). A clicked-through unit with unmet reps records NOTHING.
//
// The section index/visited state is kept so the rich Phase-07 sections + the R→L
// ribbon still render; the graph position is the durable resume + mastery source
// layered beside it.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../curriculum/curriculum_graph.dart';
import '../../curriculum/curriculum_graph_walker.dart' show GraphPosition;
import '../../curriculum/mastery_condition.dart'
    show isMasteryMet, isMasteryMetForPresented;
import '../../data/app_database.dart';
import '../../data/drift_progress_repository.dart';
import '../../data/graph_position_repository.dart' as repo;
import '../../tutor/exercise_selector_provider.dart';
import '../../tutor/tutor_decision.dart';
import '../../tutor/tutor_facts.dart';

/// The immutable unit state: the section [index] within the [total] sections,
/// the set of [visited] section indices (for the ribbon's done dots), and the
/// durable graph [currentExerciseId] + cleared competency/tier state (the resume
/// cursor restored from Drift).
class LetterUnitState {
  const LetterUnitState({
    required this.index,
    required this.total,
    required this.visited,
    this.currentExerciseId,
    this.clearedCompetencies = const [],
    this.clearedTiers = const [],
    this.masteryRecorded = false,
  });

  /// The current section index (0-based; 0 = Meet … total-1 = Mastery).
  final int index;

  /// How many sections this unit has (baa = 6).
  final int total;

  /// Every section index the child has visited this unit (resume + ribbon).
  final Set<int> visited;

  /// The graph exercise the child is currently on — the durable resume cursor
  /// (null at the graph root before any node is entered).
  final String? currentExerciseId;

  /// The competency ids cleared so far (durable forward-progress state).
  final List<String> clearedCompetencies;

  /// The إملاء tiers cleared so far (durable ramp-progress state).
  final List<String> clearedTiers;

  /// True once the quiet star has been recorded for this unit (idempotency
  /// guard — the star is information, recorded at most once; CLAUDE.md Decided).
  final bool masteryRecorded;

  /// True when the child is on the final (Mastery) section.
  bool get atMastery => total > 0 && index == total - 1;

  LetterUnitState copyWith({
    int? index,
    int? total,
    Set<int>? visited,
    String? currentExerciseId,
    List<String>? clearedCompetencies,
    List<String>? clearedTiers,
    bool? masteryRecorded,
  }) {
    return LetterUnitState(
      index: index ?? this.index,
      total: total ?? this.total,
      visited: visited ?? this.visited,
      currentExerciseId: currentExerciseId ?? this.currentExerciseId,
      clearedCompetencies: clearedCompetencies ?? this.clearedCompetencies,
      clearedTiers: clearedTiers ?? this.clearedTiers,
      masteryRecorded: masteryRecorded ?? this.masteryRecorded,
    );
  }

  static const LetterUnitState empty =
      LetterUnitState(index: 0, total: 0, visited: {0});
}

/// Drives one letter unit's sequencing + DURABLE resume + the mastery-gated star.
/// Construct per letterId via the [letterUnitControllerProvider] family (the
/// family arg is the letterId); call [start] once the section order is known,
/// then [goTo] / [advance] / [back] to navigate.
class LetterUnitController extends Notifier<LetterUnitState> {
  /// The family argument — which letter's unit this controller drives.
  LetterUnitController(this._argLetterId);

  final String _argLetterId;

  late String _letterId = _argLetterId;

  @override
  LetterUnitState build() => LetterUnitState.empty;

  /// Initialise the controller for [letterId] with [total] sections. Reads the
  /// DURABLE graph position from Drift (D-08) and resumes at [resumeSection] if
  /// forced, else the section the persisted cursor implies, else 0.
  Future<void> start({
    required String letterId,
    required int total,
    int? resumeSection,
  }) async {
    _letterId = letterId;
    // 1) Read the durable graph position from Drift (Pitfall 6: a Future read).
    repo.GraphPosition? saved;
    try {
      saved = await ref.read(repo.graphPositionRepositoryProvider).getPosition(letterId);
    } catch (_) {
      saved = null; // a read failure degrades to a clean start (never crashes).
    }
    // 2) Resolve the resume section. An explicit resumeSection wins; otherwise
    // the count of visited (cleared) competencies/tiers is a coarse position hint.
    final hint = _sectionHintFor(saved, total);
    final start = (resumeSection ?? hint ?? 0).clamp(0, total > 0 ? total - 1 : 0);
    final visited = <int>{for (var i = 0; i <= start; i++) i};
    state = LetterUnitState(
      index: start,
      total: total,
      visited: visited,
      currentExerciseId: saved?.currentExerciseId,
      clearedCompetencies: saved?.clearedCompetencies ?? const [],
      clearedTiers: saved?.clearedTiers ?? const [],
      masteryRecorded: false,
    );
    // 3) Persist the (re)entered position so a relaunch resumes here.
    await _persist();
  }

  /// Jump to section [n] (clamped). Marks it visited + persists the resume cursor.
  /// NOTE: this is NAVIGATION only — it never records mastery (Pitfall 2).
  void goTo(int n) {
    final total = state.total;
    if (total <= 0) return;
    final next = n.clamp(0, total - 1);
    final visited = {...state.visited, next};
    state = state.copyWith(index: next, visited: visited);
    _persist();
  }

  /// Advance to the next section (a section's onAdvance / a clean pass).
  void advance() => goTo(state.index + 1);

  /// Step back one section (the app bar back button). Never below 0.
  void back() => goTo(state.index - 1);

  /// Pick the NEXT graph exercise via the selection router (DYN-02). On a pass it
  /// advances forward; on a fail it re-surfaces a remediation (one tier down) —
  /// NEVER the next linear section (Pitfall 5). Updates + persists the cursor.
  /// Returns the selected exercise id (or null when the graph is exhausted).
  String? selectNext(TutorFacts facts, {TutorDecision? decision}) {
    final selector = ref.read(exerciseSelectorProvider);
    final position = GraphPosition(
      letterId: _letterId,
      currentExerciseId: state.currentExerciseId ?? facts.section,
      clearedCompetencies: state.clearedCompetencies,
      clearedTiers: state.clearedTiers,
    );
    final next = selector.selectNext(facts, position, decision: decision);
    if (next != null) {
      state = state.copyWith(currentExerciseId: next);
      _persist();
    }
    return next;
  }

  /// Mark a graph node as cleared (its competency + tier added to cleared state)
  /// when the child's clean-rep count for [exerciseId] reaches its minCleanReps
  /// threshold. This is the T1 write path: the forward-progress state
  /// (`clearedCompetencies` / `clearedTiers`) only grows when a node is
  /// genuinely completed — never on mere navigation (Pitfall 2).
  ///
  /// Reads the graph and the current Drift rep count; no-ops gracefully if
  /// either is unavailable. Idempotent: adding a competency/tier already in the
  /// cleared list is a no-op (dedup).
  Future<void> markNodeCleared(String exerciseId) async {
    final CurriculumGraph graph;
    try {
      graph = await ref.read(curriculumGraphProvider.future);
    } catch (_) {
      return; // graph not loaded — skip silently, never crash.
    }
    final node = graph.nodes
        .cast<GraphNode?>()
        .firstWhere((n) => n?.exerciseId == exerciseId, orElse: () => null);
    if (node == null) return; // unknown id — not a graph node, nothing to clear.

    // Check whether the child has actually reached the threshold for this node.
    int reps;
    try {
      reps = await ref.read(appDatabaseProvider).getExerciseCleanReps(
            letterId: _letterId,
            exerciseId: exerciseId,
          );
    } catch (_) {
      reps = 0;
    }
    if (reps < node.minCleanReps) return; // threshold not yet met — skip.

    // Dedup-add the competency and (non-null) tier to the cleared lists.
    final comps = [...state.clearedCompetencies];
    if (!comps.contains(node.competency)) comps.add(node.competency);

    final tiers = [...state.clearedTiers];
    if (node.tier != null && !tiers.contains(node.tier)) {
      tiers.add(node.tier!);
    }

    state = state.copyWith(
      clearedCompetencies: comps,
      clearedTiers: tiers,
    );
    await _persist();
  }

  /// Record mastery ONLY when the on-device condition is met (D-06, Pitfall 2):
  /// every essential node that this unit PRESENTS AND RECORDS has reached the
  /// owner-mother's clean-reps. A clicked-through unit with unmet reps records
  /// NOTHING. Idempotent (the star is information, recorded at most once). Never
  /// reads a server response (ADR-014 trust boundary).
  ///
  /// INTERIM (T5): the 6-section baa unit surfaces only a subset (~7) of the
  /// graph's 15 essential nodes. The scoped condition `isMasteryMetForPresented`
  /// evaluates over the intersection of `graph.essentialNodes` and the exercises
  /// the baa unit actually presents and records. The star fires when the child
  /// genuinely completes the presented essential exercises — not blocked by
  /// essential nodes the current UI never exercises. Surfacing the remaining
  /// essential exercises is a content-coverage task for the owner/mother and a
  /// later phase. The original `isMasteryMet` semantics are not modified.
  Future<bool> recordMasteryIfMet() async {
    if (state.masteryRecorded) return true;
    final CurriculumGraph graph;
    final Map<String, int> reps;
    try {
      graph = await ref.read(curriculumGraphProvider.future);
      reps = await ref.read(appDatabaseProvider).exerciseCleanRepsFor(_letterId);
    } catch (_) {
      return false; // can't evaluate → never grant the star off a guess.
    }
    // T5 (INTERIM): scope the mastery gate to the exercises the unit presents.
    // The baa unit surfaces baa.teachCard.meet, baa.traceLetter.isolated,
    // baa.traceLetter.initial, baa.traceLetter.medial, baa.connectWord.baab,
    // baa.writeWord.dictation, and baa.writeLetter.fromSound — 7 of 15 essential
    // nodes. The star reflects mastery of what is taught here; the other 8
    // essential nodes belong to a later content-coverage expansion.
    final presented = _presentedExerciseIds();
    final masteryMet = presented.isNotEmpty
        ? isMasteryMetForPresented(graph, reps, presented)
        : isMasteryMet(graph, reps); // fallback: if no presented set, full check.
    if (!masteryMet) return false;
    state = state.copyWith(masteryRecorded: true);
    try {
      // The recorded cleanReps is the essential-core minimum the child actually
      // met — never the cleanReps:0 navigation write the old bug stamped.
      final met = _essentialFloor(graph, reps);
      await ref.read(progressRepositoryProvider).recordMastery(
            letterId: _letterId,
            cleanReps: met,
          );
    } catch (_) {
      // A failed LOCAL write must never crash the celebration — the child still
      // sees their star; the mastery row can be re-recorded on re-entry.
      state = state.copyWith(masteryRecorded: false);
      return false;
    }
    return true;
  }

  /// The exercise ids this unit's 6 sections actually present and score (T5
  /// scoped mastery). These are the GRAPH node ids — never the synthetic per-word
  /// ids like `baa.writeWord.door`. Only ids whose clean-reps the scaffold
  /// actually increments belong here.
  ///
  /// INTERIM: this set is baa-specific. A later phase should derive it from the
  /// unit config so it stays in sync automatically. For now it is explicit and
  /// correct for the signed baa graph.
  Set<String> _presentedExerciseIds() => const {
        'baa.teachCard.meet',
        'baa.traceLetter.isolated',
        'baa.traceLetter.initial',
        'baa.traceLetter.medial',
        'baa.connectWord.baab',
        'baa.writeWord.dictation',
        'baa.writeLetter.fromSound',
      };

  /// The smallest essential clean-rep count the child has banked (a real,
  /// non-zero progress value to record — never the old cleanReps:0).
  int _essentialFloor(CurriculumGraph graph, Map<String, int> reps) {
    var min = 0;
    var first = true;
    for (final node in graph.essentialNodes) {
      final r = reps[node.exerciseId] ?? 0;
      if (first || r < min) {
        min = r;
        first = false;
      }
    }
    return min;
  }

  /// Persist the current graph position to Drift (the durable resume cursor).
  Future<void> _persist() async {
    try {
      await ref.read(repo.graphPositionRepositoryProvider).setPosition(
            repo.GraphPosition(
              letterId: _letterId,
              currentExerciseId: state.currentExerciseId,
              clearedCompetencies: state.clearedCompetencies,
              clearedTiers: state.clearedTiers,
            ),
          );
    } catch (_) {
      // A failed local persist must never crash navigation — resume simply falls
      // back to the last successfully written position (or the graph root).
    }
  }

  /// A coarse resume-section hint from the durable position: more cleared
  /// competencies → further along the unit. Null when nothing is cleared (start
  /// at section 0). This keeps the rich section UI resuming sensibly while the
  /// graph position is the source of truth for selection + mastery.
  int? _sectionHintFor(repo.GraphPosition? saved, int total) {
    if (saved == null || total <= 0) return null;
    final cleared = saved.clearedCompetencies.length;
    if (cleared <= 0) return null;
    // Map cleared-competency count onto the section ribbon (clamped one short of
    // Mastery so resume never lands on the star section by navigation alone).
    return cleared.clamp(0, total - 2 < 0 ? 0 : total - 2);
  }
}

/// The per-letter unit controller (keep-alive so resume survives navigation).
/// Read `.notifier` to call [LetterUnitController.start] / advance / back /
/// selectNext / recordMasteryIfMet.
final letterUnitControllerProvider =
    NotifierProvider.family<LetterUnitController, LetterUnitState, String>(
  LetterUnitController.new,
);
