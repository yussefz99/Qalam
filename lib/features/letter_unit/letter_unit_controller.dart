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

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exercise_engine/check_result.dart';
import '../../curriculum/curriculum_graph.dart';
import '../../data/curriculum_repository.dart';
import '../../curriculum/curriculum_graph_walker.dart' show GraphPosition;
import '../../curriculum/mastery_condition.dart'
    show isMasteryMet, isMasteryMetForPresented;
import '../../curriculum/selection_policy.dart';
import '../../data/app_database.dart';
import '../../data/drift_progress_repository.dart';
import '../../data/graph_position_repository.dart' as repo;
import '../../providers/profile_providers.dart';
import '../../tutor/child_model_providers.dart';
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
    this.selectionActive = false,
    this.masteryEvaluationFailed = false,
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

  /// True once the SELECTION drives what the child sees next (18-07): it flips on
  /// the first scored feedback moment of the session. While true the shell renders
  /// the selected graph node via the exercise presenter (instead of the fixed
  /// `_section(index)` walk), and the section ribbon FOLLOWS the presented node.
  final bool selectionActive;

  /// True when the LAST mastery evaluation could not run (graph or reps
  /// unreadable — e.g. a missing graph for this letter). The SURFACED degraded
  /// state (finalization Lane A): the old silent swallow-and-return-false hid a
  /// missing graph forever, which read on-device as a permanent silent freeze.
  /// The screen renders the honest "not yet" state off this; it never grants
  /// the star (fail-safe).
  final bool masteryEvaluationFailed;

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
    bool? selectionActive,
    bool? masteryEvaluationFailed,
  }) {
    return LetterUnitState(
      index: index ?? this.index,
      total: total ?? this.total,
      visited: visited ?? this.visited,
      currentExerciseId: currentExerciseId ?? this.currentExerciseId,
      clearedCompetencies: clearedCompetencies ?? this.clearedCompetencies,
      clearedTiers: clearedTiers ?? this.clearedTiers,
      masteryRecorded: masteryRecorded ?? this.masteryRecorded,
      selectionActive: selectionActive ?? this.selectionActive,
      masteryEvaluationFailed:
          masteryEvaluationFailed ?? this.masteryEvaluationFailed,
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

  /// The in-file child this unit belongs to (ADR-018 / D-13 / Pitfall 4). Cached
  /// ONCE at [start] from `childProfileProvider` — NEVER re-read inline on the
  /// scored-feedback hot path (an async FutureProvider read mid-feedback would
  /// stall the pass CTA). Every keyed DB write/read in this controller uses this
  /// cached value. Defaults to [kUnassignedChildProfileId] until [start] resolves
  /// the real id (a child never scores before [start] runs). It is a LOCAL int;
  /// it NEVER enters TutorFacts / the coach payload (the ADR-017 wire boundary).
  int _childProfileId = kUnassignedChildProfileId;

  /// The cached in-file child id (ADR-018) — read by the screen's scored-feedback
  /// write path (`_onNodePassed`) so the per-exercise clean-rep increment keys by
  /// the SAME child the controller resolved at [start], with no inline
  /// FutureProvider read on the hot path (Pitfall 4).
  int childProfileId() => _childProfileId;

  // ── 18-07: the two-timescale selection context (survives scaffold key swaps) ──

  /// The criterion-tagged, session-scoped attempt store (0b) — the
  /// `SelectionPolicy` fail-streak source. Lives on the CONTROLLER so it SURVIVES
  /// scaffold key changes + section swaps (today's per-scaffold `_trajectory`
  /// dies on every FormsSection/ListenWriteSection key swap — audit finding 1.4).
  final List<SessionAttempt> _sessionHistory = [];

  /// The durable remediation-arc cursor (D-12) — loaded from Drift on [start],
  /// advanced + re-persisted each feedback moment. Null when no arc is in progress.
  ArcState? _sessionArc;

  /// The compiled across-session profile mirror (R2 / 18-06) — read NON-BLOCKING
  /// at [start] (a fast local Drift read; the Firestore refresh is fire-and-forget
  /// inside childModelProvider). NEVER awaited on the selection path (Req 6).
  ChildModelSnapshot? _profileSnapshot;

  /// The current feedback moment's narrow outcome (18-07). `SelectionPolicy.narrow`
  /// is invoked ONCE per moment ([beginSelection]) and cached here so [selectNext]
  /// reuses its nextArc — never a second narrow inside the controller.
  PolicyOutcome? _pendingNarrow;

  /// The in-flight selection Future for the current moment (18-07) — the pass-CTA
  /// AWAITS this so the content swap reads a FRESH cursor, never a stale one (the
  /// fire-and-forget race, audit finding §5). Null before the first scored attempt.
  Future<String?>? _nextReady;

  /// The pass/continue CTA awaits this to read the freshly-selected cursor (18-07,
  /// consumed by the presenter in Task 3). Null before the first scored attempt.
  /// A METHOD (not a getter) so it stays clear of the notifier-property lint.
  Future<String?>? nextReady() => _nextReady;

  /// The read-only, criterion-tagged session attempt store (18-07) — exposed for
  /// the fail-path live proof (a FAILED attempt appends here).
  List<SessionAttempt> sessionHistory() =>
      List<SessionAttempt>.unmodifiable(_sessionHistory);

  /// 18-16: the CURRENT feedback moment's GENUINE remediation-arc step (from the
  /// policy outcome cached in [beginSelection], BEFORE [selectNext] consumes it) —
  /// `entry`/`stepDown`/`rebuild`/`retryOriginal`, or null when no arc is in
  /// progress. Only a genuine arc (entering or advancing) is surfaced: a mere
  /// TRACKING arc (a first fail counting toward entry) carries NO `arcStep:`
  /// why-fact, so this returns null and a single fail never narrates a step-down.
  /// The scaffold threads this into the child-facing Teacher's Margin at verdict
  /// time so the step-down narrates from the REAL arc state — no micro-drill pick
  /// required (the drills are parked out of the live graph, D-03).
  String? pendingArcStep() {
    final out = _pendingNarrow;
    if (out == null) return null;
    final genuineArc = out.whyFacts.any((f) => f.startsWith('arcStep:'));
    return genuineArc ? out.arcStep : null;
  }

  /// 18-16: the CURRENT moment's non-PII policy WHY facts (`criterion:*` /
  /// `arcStep:*` / `struggle:*`) from the cached policy outcome, or empty. The
  /// margin names the arc's target part from these (never child data / geometry).
  List<String> pendingWhyFacts() => _pendingNarrow?.whyFacts ?? const [];

  /// The across-session profile as the non-PII wire map (R2), or null when there
  /// is no across-session signal yet (cold boot / empty) so the payload omits it.
  Map<String, Object?>? profileFacts() {
    final p = _profileSnapshot;
    if (p == null) return null;
    if (p.strengths.isEmpty && p.struggles.isEmpty && p.perCriterion.isEmpty) {
      return null;
    }
    return p.toMap();
  }

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
    // 0) Resolve the in-file child ONCE (ADR-018 / Pitfall 4). A best-effort read
    // of the single child profile; a null/missing profile (fresh install before
    // onboarding, or a headless widget test) degrades to the unassigned sentinel.
    // This is the ONLY childProfileProvider read in the controller — every keyed
    // DB call below uses the cached [_childProfileId], never an inline async read
    // on the scored-feedback hot path.
    try {
      final profile = await ref.read(childProfileProvider.future);
      _childProfileId = profile?.id ?? kUnassignedChildProfileId;
    } catch (e) {
      // D-03 loud-degrade: a missing/unreadable profile (fresh install, headless
      // test) degrades to the unassigned sentinel — the unit still opens; keyed
      // writes just key to the sentinel until a real profile resolves.
      debugPrint(
        '[LetterUnit] could not resolve the child profile for "$letterId": $e — '
        'using the unassigned sentinel id (the unit still opens).',
      );
      _childProfileId = kUnassignedChildProfileId;
    }
    // 0a) 260718-nft: WARM the per-letter curriculum graph UNCONDITIONALLY, so the
    // scaffold's synchronous `.asData?.value` reads ([_isGraphRailed],
    // [beginSelection], [_legalNextExerciseIds]) see the loaded graph on the child's
    // FIRST attempt of a first visit. Before this, the graph future was awaited ONLY
    // when a saved cursor existed (step 1b) — so a first visit read `.asData` as null
    // and the whole session raced to the STATIC section fallback even for a promoted
    // graph letter (owner on-device thaa test, 2026-07-18). GUARDED + never-throw: a
    // missing graph asset (alif/taa) load-fails harmlessly here → `.asData` stays
    // null → those letters degrade to the static flow exactly as before, no crash.
    try {
      await ref.read(curriculumGraphProvider(letterId).future);
    } catch (e) {
      // No graph for this letter (or a load failure) — the graph-railed reads see
      // null and the letter keeps the static flow. Never crash the unit-open path,
      // but say so LOUDLY (finalization Lane A): a silently-missing graph is the
      // exact failure that froze alif/taa progression on device with no log.
      debugPrint(
        '[LetterUnit] no curriculum graph for "$letterId" '
        '(Firestore doc + bundled asset both unavailable): $e — '
        'this letter degrades to the static section flow and CANNOT record '
        'graph mastery until a graph is seeded.',
      );
    }
    // 0c) 25-05 (L3): WARM the seen-letters filter so the runtime guard has its
    // learned-set data (letters.json introOrder + exercises.json letters[]) ready
    // by the child's FIRST scored moment — the selection path reads it NON-blocking
    // (`.asData?.value`, never awaited). Never-throw by construction (the provider
    // degrades to a no-op filter on any load failure), so this only kicks off the
    // background load; a failure simply disables L3 filtering for the session (the
    // graph legality rail still holds). Fire-and-forget — never blocks unit open.
    ref.read(seenLettersFilterProvider(letterId));
    // 1) Read the durable graph position from Drift (Pitfall 6: a Future read).
    repo.GraphPosition? saved;
    try {
      saved = await ref
          .read(repo.graphPositionRepositoryProvider)
          .getPosition(letterId, childProfileId: _childProfileId);
    } catch (e) {
      // D-03 loud-degrade: a durable-position read failure degrades to a clean
      // start (never crashes) — say so, it means resume is lost this open.
      debugPrint(
        '[LetterUnit] durable graph position for "$letterId" could not be read: '
        '$e — starting clean (resume cursor unavailable this open).',
      );
      saved = null;
    }
    // 1b) 18-15 (UAT T7): RESTORE selection mode from the durable cursor. The
    // durable cursor is read back correctly above, but `selectionActive` is
    // session-scoped (never persisted) and `start()` reset it to false on every
    // cold relaunch — so the screen fell back to the legacy `_section` walk even
    // though the child was mid-unit (resume-position-lost-on-relaunch.md). Restore
    // it iff the saved cursor is a REAL authored graph node: a best-effort, GUARDED
    // graph read validates it (a load failure → no resume, never a crash — the
    // never-throw posture). A null / empty / stale / unauthored id degrades to
    // false so a truly-fresh child keeps the legacy walk (no false resume) and a
    // corrupt id never forces the presenter into a dead-end (T-18-15-01).
    final savedCursor = saved?.currentExerciseId;
    var restoreSelection = false;
    if (savedCursor != null && savedCursor.trim().isNotEmpty) {
      try {
        final graph = await ref.read(curriculumGraphProvider(_letterId).future);
        restoreSelection = graph.isAuthored(savedCursor);
      } catch (e) {
        // D-03 loud-degrade: the graph could not validate the saved cursor → no
        // selection resume (never a crash); the child keeps the legacy walk.
        debugPrint(
          '[LetterUnit] could not validate the saved cursor "$savedCursor" for '
          '"$_letterId": $e — no selection resume this open (legacy walk).',
        );
        restoreSelection = false;
      }
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
      // Restored from the durable cursor: the screen re-enters presenter mode on
      // the exact node the child left off (18-15). false for a truly-fresh child.
      selectionActive: restoreSelection,
    );
    // 3) Persist the (re)entered position so a relaunch resumes here.
    await _persist();
    // 4) 18-07: load the two-timescale selection context — the durable arc
    // (D-12 resume) + the across-session profile mirror (R2) — NON-BLOCKING
    // (fire-and-forget). The selection path NEVER waits on these (Req 6); each
    // moment reads whatever has resolved (null = no signal, never a false one).
    unawaited(_loadSelectionContext(letterId));
  }

  /// 18-07: load the durable remediation arc (D-12) + the across-session profile
  /// mirror (R2), both best-effort and NON-BLOCKING. A read failure (e.g. no
  /// Firebase in a widget test, or a cold-boot empty mirror) degrades to null —
  /// never a crash, never a false struggle. Fire-and-forget from [start].
  Future<void> _loadSelectionContext(String letterId) async {
    try {
      _sessionArc = await ref
          .read(arcStateRepositoryProvider)
          .getArc(letterId, childProfileId: _childProfileId);
    } catch (e) {
      // D-03 loud-degrade: no durable arc (no Firebase in a test / cold boot) →
      // null (no arc in progress); the selection path never waits on this.
      debugPrint(
        '[LetterUnit] remediation arc for "$letterId" could not load: $e — '
        'no arc in progress this session (never a false step-down).',
      );
      _sessionArc = null;
    }
    try {
      // The mirror read is a fast LOCAL Drift read (offline-safe); the Firestore
      // refresh is fired fire-and-forget INSIDE childModelProvider — never awaited
      // here (Req 6 / D-16), so the selection path is never blocked on a round-trip.
      _profileSnapshot = await ref.read(childModelProvider.future);
    } catch (e) {
      // D-03 loud-degrade: no across-session mirror (cold boot / empty) → null
      // (no across-session signal); the payload simply omits the profile.
      debugPrint(
        '[LetterUnit] across-session profile for "$letterId" could not load: $e '
        '— no across-session signal this session (never a false struggle).',
      );
      _profileSnapshot = null;
    }
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

  /// BEGIN a feedback moment (18-07). Records the scored attempt in the
  /// session-scoped, criterion-tagged store (0b — survives scaffold key swaps),
  /// then invokes `SelectionPolicy.narrow` ONCE (pure, microseconds — no network)
  /// with the durable arc + the profile mirror + the session history, caching the
  /// outcome for [selectNext]. Returns the policy-narrowed graph-legal candidates
  /// so the coach proposes FROM the policy-legal set (facts.legalNextExerciseIds —
  /// the wire narrows to what the policy allows, not a raw isLegalSelection sweep).
  ///
  /// Best-effort + synchronous: a bare scaffold (never [start]ed, `total == 0`) or
  /// an unloaded graph returns `const []` so the practice path degrades cleanly.
  List<String> beginSelection(
    CheckResult result,
    String section, {
    List<String> recentMistakes = const [],
  }) {
    if (state.total == 0) return const []; // not started (bare scaffold) — no-op.
    // 0b: the criterion-tagged attempt store — the fail-streak source.
    _sessionHistory.add(SessionAttempt(
      exerciseId: section,
      passed: result.passed,
      weakestCriterion: result.weakestCriterion,
    ));
    final graph = ref.read(curriculumGraphProvider(_letterId)).asData?.value;
    if (graph == null) {
      _pendingNarrow = null;
      return const [];
    }
    // Keep the durable cursor in sync with the node the child is ACTUALLY on, so
    // the forward walk starts from HERE and the policy's remediation/anti-boredom
    // read the SAME node the forward reach does (facts.section == the cursor).
    if (graph.isAuthored(section) && state.currentExerciseId != section) {
      state = state.copyWith(currentExerciseId: section);
    }
    final current = state.currentExerciseId ?? section;
    final facts = TutorFacts(
      letterId: _letterId,
      section: current,
      passed: result.passed,
      mistakeId: result.mistakeId,
      weakestCriterion: result.weakestCriterion,
      criteria: result.criteria,
      recentMistakes: List<String>.unmodifiable(recentMistakes),
    );
    final out = SelectionPolicy(graph).narrow(
      facts,
      _positionFor(current),
      arc: _sessionArc,
      profile: _profileSnapshot,
      sessionHistory: _sessionHistory,
    );
    _pendingNarrow = out;
    return out.candidates;
  }

  /// Pick the NEXT graph exercise for a scored feedback moment (18-07 — CLOSES the
  /// Phase-15 dead wire). It routes the coach's [decision] through the
  /// candidate-aware [RouterExerciseSelector] over the SAME policy-narrowed
  /// candidate set this moment produced: the agent's pick is honored ONLY when it
  /// is a policy candidate AND graph-legal, else it degrades to the walker (R5).
  /// Runs on pass AND fail (a fail enters the arc / remediation). Persists the
  /// arc this moment produced (D-12 resume) + the resume cursor. Exposed as
  /// [nextReady] so the pass-CTA can AWAIT the fresh cursor (audit finding §5).
  /// Never blocks on the profile refresh (fire-and-forget, 18-06 / Req 6).
  Future<String?> selectNext(TutorFacts facts, {TutorDecision? decision}) {
    final future = _selectNext(facts, decision: decision);
    _nextReady = future;
    return future;
  }

  /// 19 review WR-04: the verdict-time selection continuation, owned by the
  /// CONTROLLER — never gated on the presenting scaffold's `mounted` flag or
  /// its lifetime. The scaffold calls this SYNCHRONOUSLY at the scored moment
  /// with the in-flight coach future, so:
  ///   • [_nextReady] is set IMMEDIATELY — a fast "Try again"/"Next exercise"
  ///     tap awaits THIS moment's pick, never a stale prior future; and
  ///   • the continuation (arc advance + D-12 persist + cursor swap) runs on
  ///     the controller even when the 18-12 epoch remount disposes the
  ///     scaffold before a slow coach call resolves — the D-02 "fail the same
  ///     criterion twice → the very next card steps down" guarantee (owner
  ///     directive 2026-07-12) no longer degrades to retry-in-place under
  ///     fast taps + coach latency.
  /// A failed coach call degrades to the walker/policy path (no decision) so
  /// [_nextReady] always completes — never a dangling rejected future under
  /// the pass-CTA's await.
  Future<String?> selectNextWhenDecided(
    TutorFacts facts,
    Future<TutorDecision> decision,
  ) {
    final future = decision.then<String?>(
      (d) => _selectNext(facts, decision: d),
      onError: (Object _) => _selectNext(facts),
    );
    _nextReady = future;
    return future;
  }

  Future<String?> _selectNext(TutorFacts facts, {TutorDecision? decision}) async {
    if (state.total == 0) return null; // not started (bare scaffold) — no-op.
    final CurriculumGraph graph;
    try {
      graph = await ref.read(curriculumGraphProvider(_letterId).future);
    } catch (e) {
      // D-03 loud-degrade (never a silent swallow): the graph could not load, so
      // this selection is skipped and the unit stays put (never a crash). Say so —
      // a silently-dropped selection reads on device as a frozen "Next" button.
      debugPrint(
        '[LetterUnit] selection for "$_letterId" could not load the graph: $e — '
        'skipping this selection (the unit stays put, never a crash).',
      );
      return null;
    }
    // Select FROM the current graph-node cursor (kept in sync by beginSelection),
    // not the coach's exercise-type label — so this narrow matches beginSelection's
    // candidate set exactly (the agent pick was validated against it).
    final current = state.currentExerciseId ?? facts.section;
    final selFacts = TutorFacts(
      letterId: facts.letterId,
      section: current,
      passed: facts.passed,
      mistakeId: facts.mistakeId,
      weakestCriterion: facts.weakestCriterion,
      criteria: facts.criteria,
      recentMistakes: facts.recentMistakes,
    );
    final position = _positionFor(current);
    // Route the pick through the candidate-aware selector (Task 1) with THIS
    // moment's arc / profile / session context — the router narrows to the SAME
    // candidate set beginSelection produced (online↔offline parity, D-11).
    // 25-05 (L3): thread the seen-letters guard onto the LIVE selection path (the
    // provider `exerciseSelectorProvider` is NOT what renders — this controller is,
    // so the guard MUST be wired HERE or it is a dead wire, the Phase-15 lesson). A
    // synchronous `.asData?.value` read (never a blocking `.future`): null until the
    // filter warms (in `start`), and the router then no-ops. The router SKIPs any
    // reach-ahead candidate (except the 22 owner-approved ids) and logs it loudly.
    final seenFilter =
        ref.read(seenLettersFilterProvider(_letterId)).asData?.value;
    final selector = RouterExerciseSelector(
      graph,
      arc: _sessionArc,
      profile: _profileSnapshot,
      sessionHistory: _sessionHistory,
      seenFilter: seenFilter,
    );
    final next = selector.selectNext(selFacts, position, decision: decision);
    // Persist + advance the arc this moment produced (D-12). Fire-and-forget: the
    // pick is what the child feels; the arc write must never add latency.
    final nextArc = _pendingNarrow?.nextArc;
    _sessionArc = nextArc;
    _pendingNarrow = null;
    if (nextArc != null) unawaited(_persistArc(nextArc));
    if (next != null) {
      // Flip into selection mode (the shell renders the selected node next) and
      // advance the durable cursor to it. selectionActive is sticky for the
      // session — the first scored moment hands control to the selector.
      state = state.copyWith(currentExerciseId: next, selectionActive: true);
      await _persist();
    } else {
      // Graph exhausted for this cleared state — mark selection active so the
      // shell routes to Mastery (never a null dead-end / a silent stall).
      state = state.copyWith(selectionActive: true);
    }
    return next;
  }

  /// The child's current durable [GraphPosition] for [section] (the cursor + the
  /// cleared competency/tier state) — the rail the policy + walker narrow within.
  GraphPosition _positionFor(String section) => GraphPosition(
        letterId: _letterId,
        currentExerciseId: state.currentExerciseId ?? section,
        clearedCompetencies: state.clearedCompetencies,
        clearedTiers: state.clearedTiers,
      );

  /// Persist the remediation arc to Drift (D-12 resume). Never throws — a failed
  /// local write just means the arc restarts warm on the next entry.
  Future<void> _persistArc(ArcState arc) async {
    try {
      await ref
          .read(arcStateRepositoryProvider)
          .setArc(_letterId, arc, childProfileId: _childProfileId);
    } catch (e) {
      // D-03 loud-degrade: a failed local arc persist must never crash selection
      // (resume just restarts the arc warm on the next entry) — but say so.
      debugPrint(
        '[LetterUnit] could not persist the remediation arc for "$_letterId": $e '
        '— the arc restarts warm on the next entry (selection unaffected).',
      );
    }
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
      graph = await ref.read(curriculumGraphProvider(_letterId).future);
    } catch (e) {
      // D-03 loud-degrade: the graph could not load, so this node-clear is skipped
      // (the cleared state simply does not grow — never a crash). Say so.
      debugPrint(
        '[LetterUnit] node-clear for "$exerciseId" ("$_letterId") could not load '
        'the graph: $e — skipping the clear (cleared state unchanged, no crash).',
      );
      return;
    }
    final node = graph.nodes
        .cast<GraphNode?>()
        .firstWhere((n) => n?.exerciseId == exerciseId, orElse: () => null);
    if (node == null) return; // unknown id — not a graph node, nothing to clear.

    // Check whether the child has actually reached the threshold for this node.
    int reps;
    try {
      reps = await ref.read(appDatabaseProvider).getExerciseCleanReps(
            childProfileId: _childProfileId,
            letterId: _letterId,
            exerciseId: exerciseId,
          );
    } catch (e) {
      // D-03 loud-degrade: the clean-rep read failed, so treat as 0 (the node just
      // will not clear yet — never a crash, never a false clear). Say so.
      debugPrint(
        '[LetterUnit] clean-rep read for "$exerciseId" ("$_letterId") failed: $e '
        '— treating as 0 reps (the node stays uncleared until the read recovers).',
      );
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
  /// LETTER-GENERIC (finalization Lane A — owner mandate: no letter-id literal
  /// in logic). The scoped presented set is DERIVED per-letter from the unit
  /// CONFIG ∩ the graph's essential core ([_presentedExerciseIds]); a unit with
  /// no declared subset falls back to the FULL-graph `isMasteryMet` over that
  /// letter's OWN essential nodes. A failed evaluation is LOUD (debugPrint) and
  /// SURFACED (`state.masteryEvaluationFailed`) — never a silent freeze — and
  /// fail-safe (the star is never granted off a guess).
  Future<bool> recordMasteryIfMet() async {
    if (state.masteryRecorded) return true;
    final CurriculumGraph graph;
    final Map<String, int> reps;
    try {
      graph = await ref.read(curriculumGraphProvider(_letterId).future);
      reps = await ref
          .read(appDatabaseProvider)
          .exerciseCleanRepsFor(_letterId, childProfileId: _childProfileId);
    } catch (e) {
      // Fail-safe: never grant the star off a guess — but say so LOUDLY and
      // surface the degraded state (Lane A kills the old silent swallow-catch
      // that hid a missing graph forever = the invisible on-device freeze).
      debugPrint(
        '[LetterUnit] mastery gate for "$_letterId" could not evaluate '
        '(graph or clean-reps unreadable): $e — the star stays locked; '
        'seed graphs/$_letterId to Firestore or bundle the asset.',
      );
      state = state.copyWith(masteryEvaluationFailed: true);
      return false;
    }
    // Scope the mastery gate to the exercises the unit DECLARES it presents
    // (its `presentedEssentials` config ∩ the graph's essential core). Empty →
    // the full-graph check over this letter's own essentials.
    final presented = await _presentedExerciseIds(graph);
    final masteryMet = presented.isNotEmpty
        ? isMasteryMetForPresented(graph, reps, presented)
        : isMasteryMet(graph, reps); // fallback: if no presented set, full check.
    // The evaluation ran — clear any earlier surfaced failure (self-healing).
    if (state.masteryEvaluationFailed) {
      state = state.copyWith(masteryEvaluationFailed: false);
    }
    if (!masteryMet) return false;
    state = state.copyWith(masteryRecorded: true);
    try {
      // The recorded cleanReps is the essential-core minimum the child actually
      // met — never the cleanReps:0 navigation write the old bug stamped.
      // Scoped to the SAME presented set the gate used (19 review WR-01): a
      // floor over ALL essential nodes reads 0 off the unpresented ones and
      // stamps "Mastered · 0 clean reps" on the parent dashboard.
      final met = _essentialFloor(graph, reps, presented);
      await ref.read(progressRepositoryProvider).recordMastery(
            childProfileId: _childProfileId,
            letterId: _letterId,
            cleanReps: met,
          );
    } catch (e) {
      // A failed LOCAL write must never crash the unit — but it is LOUD, and
      // the caller (the screen) shows the honest "not yet" state instead of a
      // star that persisted nothing (Lane A: child-visible state never
      // diverges from persisted state). Re-entry re-attempts the write.
      debugPrint(
        '[LetterUnit] mastery for "$_letterId" was MET but the local write '
        'failed: $e — no star until the row persists (retried on re-entry).',
      );
      state = state.copyWith(masteryRecorded: false);
      return false;
    }
    return true;
  }

  /// The exercise ids this unit actually presents and scores, DERIVED from live
  /// data (finalization Lane A — replaces the hardcoded baa 8-id set): the unit
  /// config's `presentedEssentials` declaration intersected with the graph's
  /// essential core. These are GRAPH node ids — never the synthetic per-word
  /// ids like `baa.writeWord.door`.
  ///
  /// Empty when the unit declares no subset (the promotion pipeline emits
  /// none), when the unit is missing, or when the read fails — all of which
  /// fall back to the FULL-graph `isMasteryMet` over this letter's own
  /// essential nodes (the 260718-il4 owner-amendment behavior for every
  /// non-legacy letter). Only baa's units.json entry declares a subset today
  /// (its legacy 6-section shell surfaces 8 of the 16 graph essentials);
  /// `seeded_demo_state.dart`'s `_presentedEssentials` mirrors that DATA
  /// declaration, not this code.
  Future<Set<String>> _presentedExerciseIds(CurriculumGraph graph) async {
    List<String> declared;
    try {
      final unit =
          await ref.read(curriculumRepositoryProvider).getUnit(_letterId);
      declared = unit?.presentedEssentials ?? const [];
    } catch (e) {
      // A unit-config read failure degrades to the full-graph gate (stricter,
      // never looser) — loud, not silent.
      debugPrint(
        '[LetterUnit] could not read the unit config for "$_letterId" '
        '($e) — mastery falls back to the full-graph essential check.',
      );
      declared = const [];
    }
    if (declared.isEmpty) return const {};
    final essentials = {for (final n in graph.essentialNodes) n.exerciseId};
    return declared.where(essentials.contains).toSet();
  }

  /// The smallest essential clean-rep count the child has banked (a real,
  /// non-zero progress value to record — never the old cleanReps:0).
  ///
  /// Scoped to [presented] — the SAME set the scoped mastery gate evaluated
  /// (19 review WR-01): unpresented essential nodes sit at 0 reps by design,
  /// so an unscoped floor was 0 on every scoped-mastery star. An empty
  /// [presented] (the full-graph `isMasteryMet` fallback) floors over ALL
  /// essential nodes, matching the gate that fired.
  int _essentialFloor(
    CurriculumGraph graph,
    Map<String, int> reps,
    Set<String> presented,
  ) {
    int? min;
    for (final node in graph.essentialNodes) {
      if (presented.isNotEmpty && !presented.contains(node.exerciseId)) {
        continue;
      }
      final r = reps[node.exerciseId] ?? 0;
      if (min == null || r < min) min = r;
    }
    return min ?? 0;
  }

  /// Persist the current graph position to Drift (the durable resume cursor).
  Future<void> _persist() async {
    try {
      await ref.read(repo.graphPositionRepositoryProvider).setPosition(
            repo.GraphPosition(
              childProfileId: _childProfileId,
              letterId: _letterId,
              currentExerciseId: state.currentExerciseId,
              clearedCompetencies: state.clearedCompetencies,
              clearedTiers: state.clearedTiers,
            ),
          );
    } catch (e) {
      // D-03 loud-degrade: a failed local position persist must never crash
      // navigation — resume falls back to the last written position (or the graph
      // root) — but say so; a silent persist failure loses the resume cursor.
      debugPrint(
        '[LetterUnit] could not persist the graph position for "$_letterId": $e '
        '— resume falls back to the last written position (navigation unaffected).',
      );
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
