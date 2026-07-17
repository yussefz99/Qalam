/// Pure Dart. No cloud-AI / Firebase / network / Flutter-render / drift / riverpod
/// import — this is the deterministic SELECTION BRAIN of the durable v1 spine
/// (ADR-014 §4), guarded by the strict `lib/curriculum` ban in
/// `test/tutor/durable_layers_no_agent_imports_test.dart`. The star / selection
/// are never granted off a server response: the policy narrows an ON-DEVICE,
/// graph-legal candidate set (D-06, ADR-014 trust boundary).
///
/// `SelectionPolicy` is the heart of Phase 18 (D-09/D-11). It reads the
/// two-timescale signal (a criterion-tagged SESSION [SessionAttempt] history + the
/// compiled across-session [ChildModelSnapshot]) plus the durable [GraphPosition]
/// and [ArcState], and returns the NARROWED legal candidate set + the arc step +
/// the target criterion + the WHY facts. Both the online router and the offline
/// walker consume the SAME [PolicyOutcome], so offline parity (R6) is guaranteed
/// by construction.
///
///   • Anti-boredom (R1/D-02): `kArcEntryFailStreak` same-criterion fails on the
///     same exercise EXCLUDE that identical exercise from the candidates.
///   • Micro-drill injection (R3): a DOMINANT failing criterion adds its
///     `microDrill.<criterion>` (enrichment — never gates the star).
///   • Remediation arc (R4/D-04): entry → stepDown → rebuild → retryOriginal; a
///     clean win on the ORIGINAL exits, a floor-fail lands a guaranteed-doable
///     trace and ends warm within `kArcMaxAttempts` — never a loop.
///
/// ONE counter (two same-criterion fails, D-02) drives BOTH anti-boredom AND arc
/// entry. Every emitted candidate is re-checked with `isLegalSelection` — the
/// policy NARROWS, never widens, the rail.
library;

import '../tutor/tutor_facts.dart';
import 'arc_state.dart';
import 'child_model_snapshot.dart';
import 'curriculum_graph.dart';
import 'curriculum_graph_walker.dart';
import 'session_attempt.dart';

// Re-export the pure value types so a single `selection_policy.dart` import gives
// callers `ArcState`/`ArcStep`/`kArcEntryFailStreak`/`kArcMaxAttempts`,
// `ChildModelSnapshot`, and `SessionAttempt` (the 18-01 RED contract imports them
// all from here).
export 'arc_state.dart';
export 'child_model_snapshot.dart';
export 'session_attempt.dart';

/// The pure result of one [SelectionPolicy.narrow]. Both the online router and the
/// offline walker consume this SAME shape (D-11).
class PolicyOutcome {
  const PolicyOutcome({
    required this.candidates,
    required this.nextArc,
    this.targetCriterion,
    this.whyFacts = const [],
  });

  /// The narrowed, graph-LEGAL next-exercise ids. Never contains an illegal id
  /// (re-checked with `isLegalSelection`); never contains an exercise the
  /// anti-boredom rule excluded.
  final List<String> candidates;

  /// The arc state to persist/thread for the NEXT attempt: an entered/advanced
  /// arc, a non-active tracking arc (counting toward entry), or null (no arc).
  final ArcState? nextArc;

  /// The criterion the pick TARGETS (the one the child keeps missing), or null.
  final String? targetCriterion;

  /// The non-PII justification facts feeding the WHY line (D-10) — e.g.
  /// `criterion:shape`, `arcStep:entry`, `struggle:baa/dot`. Online the coach LLM
  /// phrases them; offline an authored template does.
  final List<String> whyFacts;

  /// The documented 18-01 convenience view of [nextArc]'s step, or null.
  String? get arcStep => nextArc?.step;
}

/// The deterministic, rail-bounded selection brain (D-09/D-11). Pure: it composes
/// the [CurriculumGraph] rail with the two-timescale signal and the arc state.
class SelectionPolicy {
  const SelectionPolicy(this.graph);

  /// The graph rail — the authority the policy narrows within, never past.
  final CurriculumGraph graph;

  /// Narrow the graph-legal candidate set for the just-finished [facts] at
  /// [position], threading the optional across-session [profile], the durable
  /// [arc], and the criterion-tagged session [sessionHistory] (18-07 supplies it).
  PolicyOutcome narrow(
    TutorFacts facts,
    GraphPosition position, {
    ArcState? arc,
    ChildModelSnapshot? profile,
    List<SessionAttempt>? sessionHistory,
  }) {
    // ── Arc IN PROGRESS: advance the state machine (same output online & offline). ──
    if (arc != null && arc.active) {
      return _advanceArc(facts, position, arc, profile);
    }

    final letterId = position.letterId;
    final current = facts.section;
    final criterion = facts.weakestCriterion;
    final failing = !facts.passed;

    // Base legal set. On a PASS: the forward reach the walker would consider.
    // On a FAIL the menu NEVER advances (owner bug 2026-07-12: a say-carried
    // agent pick legally moved a failing child forward — the forward frontier
    // must not be offered on a fail at all): retry the current card or step one
    // tier down; every id still through the rail.
    final candidates = <String>[];
    if (failing) {
      final rem = graph.remediateOneTier(current);
      if (rem != null && _isLegal(rem, position)) candidates.add(rem);
      if (!candidates.contains(current) && _isLegal(current, position)) {
        candidates.add(current);
      }
      // Safety net: a fail moment must still offer SOMETHING (an illegal/unknown
      // current with no remediation) — degrade to the forward reach rather than
      // an empty menu that would stall the loop.
      if (candidates.isEmpty) candidates.addAll(_legalForward(position));
    } else {
      candidates.addAll(_legalForward(position));
    }

    final why = <String>[];
    String? targetCriterion;
    ArcState? nextArc;

    // ONE counter drives BOTH anti-boredom (R1) and arc entry (R4) — D-02.
    final streak = _effectiveStreak(facts, arc, sessionHistory);

    if (failing && criterion != null && streak >= kArcEntryFailStreak) {
      // Anti-boredom (R1/D-02): a child who fails the same criterion twice never
      // sees the IDENTICAL exercise a third time.
      candidates.removeWhere((id) => id == current);
      // The entry moment steps DOWN immediately (owner directive 2026-07-12:
      // "fail twice → go back" must be the very next card): the criterion's
      // drill for a production miss, else/or the guaranteed-doable floor trace
      // when the child is failing a guided trace itself (_stepDownTarget), joins
      // the menu.
      final down = _stepDownTarget(letterId, criterion, current, position);
      if (down != null &&
          down != current &&
          _isLegal(down, position) &&
          !candidates.contains(down)) {
        candidates.add(down);
      }
      targetCriterion = criterion;
      // Same counter → ENTER the arc (R4/D-02), remembering the original to retry.
      nextArc = ArcState.enter(
        targetCriterion: criterion,
        exerciseToRetry: current,
        failStreak: streak,
      );
      why
        ..add('criterion:$criterion')
        ..add('arcStep:${nextArc.step}')
        ..add('reason:repeated_${criterion}_miss');
    } else if (failing && criterion != null) {
      // Below the streak — track the counter (a non-active arc) for next time.
      nextArc = ArcState.tracking(
        targetCriterion: criterion,
        exerciseToRetry: current,
        failStreak: streak,
      );
      targetCriterion = criterion;
      why.add('criterion:$criterion');
    } else {
      // A pass (or no criterion) clears any tracking.
      nextArc = null;
      if (criterion != null) why.add('criterion:$criterion');
    }

    // Micro-drill injection (R3): a DOMINANT failing criterion adds its
    // `microDrill.<criterion>` (enrichment — never gates the star, D-06).
    if (_criterionDominates(facts) && criterion != null) {
      final drill = graph.drillForCriterion(letterId, criterion);
      if (drill != null && _isLegal(drill, position) && !candidates.contains(drill)) {
        candidates.add(drill);
      }
      targetCriterion ??= criterion;
      if (!why.any((f) => f.contains(criterion))) why.add('criterion:$criterion');
    }

    // Across-session memory (R2): name a stored struggle so the WHY can reference
    // the previous session (D-16).
    if (profile != null) {
      for (final s in profile.struggles) {
        why.add('struggle:$s');
      }
    }

    // Defense in depth (T-18-04-01): the policy NARROWS, never widens — re-check
    // EVERY candidate with isLegalSelection before returning.
    return PolicyOutcome(
      candidates: _legalize(candidates, position),
      nextArc: nextArc,
      targetCriterion: targetCriterion,
      whyFacts: why,
    );
  }

  // ── The remediation arc state machine (R4/D-04). ────────────────────────────
  PolicyOutcome _advanceArc(
    TutorFacts facts,
    GraphPosition position,
    ArcState arc,
    ChildModelSnapshot? profile,
  ) {
    final letterId = position.letterId;
    final criterion = arc.targetCriterion;
    final retry = arc.exerciseToRetry;
    final baseWhy = <String>[
      if (criterion != null) 'criterion:$criterion',
      'arcStep:${arc.step}',
      for (final s in profile?.struggles ?? const <String>[]) 'struggle:$s',
    ];

    // retryOriginal + clean win on the ORIGINAL → EXIT the arc (success).
    if (arc.stepValue == ArcStep.retryOriginal && facts.passed) {
      return PolicyOutcome(
        candidates: _legalForward(position),
        nextArc: arc.exit(),
        targetCriterion: criterion,
        whyFacts: [...baseWhy, 'reason:arc_cleared'],
      );
    }

    // Floor guard (D-04): a floor-fail at retryOriginal — OR the kArcMaxAttempts
    // ceiling — lands a guaranteed-doable trace and ends the arc WARM (no loop).
    final atCeiling = arc.attempts + 1 >= kArcMaxAttempts;
    if (arc.stepValue == ArcStep.retryOriginal || atCeiling) {
      final trace = _floorTrace(letterId, position);
      final cands = _legalize([?trace], position);
      return PolicyOutcome(
        candidates: cands.isEmpty ? _legalForward(position) : cands,
        nextArc: arc.exit(),
        targetCriterion: criterion,
        whyFacts: [...baseWhy, 'reason:floor_trace_success'],
      );
    }

    // Otherwise advance one step, presenting the micro-drill (or the original at
    // rebuild). The switch stays exhaustive over ArcStep (retryOriginal handled
    // above).
    final ArcState next;
    final List<String> stepCands;
    switch (arc.stepValue) {
      case ArcStep.entry:
        next = arc.toStepDown();
        stepCands = _drillOrRetry(letterId, criterion, retry, position);
      case ArcStep.stepDown:
        next = arc.toRebuild();
        stepCands = _drillOrRetry(letterId, criterion, retry, position);
      case ArcStep.rebuild:
        next = arc.toRetryOriginal();
        stepCands = _legalize([?retry], position);
      case ArcStep.retryOriginal:
        next = arc.exit();
        stepCands = _legalForward(position);
    }
    return PolicyOutcome(
      candidates: stepCands.isEmpty ? _legalForward(position) : stepCands,
      nextArc: next,
      targetCriterion: criterion,
      whyFacts: baseWhy,
    );
  }

  /// The same-criterion fail streak (the shared counter, D-02). Reads a threaded
  /// tracking [arc] and the criterion-tagged [sessionHistory] — NEVER
  /// `facts.trajectory` (per-widget-instance & criterion-less). Falls back to the
  /// dominant recent-mistake count for the single-call unit contract.
  int _effectiveStreak(
    TutorFacts facts,
    ArcState? arc,
    List<SessionAttempt>? sessionHistory,
  ) {
    if (facts.passed) return 0;
    final criterion = facts.weakestCriterion;
    final current = facts.section;

    // (1) Threaded tracking arc: the accumulated streak on this exercise + now.
    var arcStreak = 0;
    if (arc != null &&
        !arc.active &&
        arc.exerciseToRetry == current &&
        arc.targetCriterion == criterion) {
      arcStreak = arc.failStreak;
    }
    final threaded = arcStreak + 1;

    // (2) Criterion-tagged SESSION history (18-07 supplies it — the durable
    // source). Trailing same-exercise, same-criterion fails.
    var historyStreak = 0;
    if (sessionHistory != null && sessionHistory.isNotEmpty) {
      for (final a in sessionHistory.reversed) {
        if (a.exerciseId == current &&
            !a.passed &&
            (criterion == null || a.weakestCriterion == criterion)) {
          historyStreak++;
        } else {
          break;
        }
      }
    } else {
      // Single-call fallback (no session store threaded): the dominant recent
      // mistake count — the derived struggle signal, again NOT facts.trajectory.
      final counts = <String, int>{};
      for (final m in facts.recentMistakes) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
      for (final c in counts.values) {
        if (c > historyStreak) historyStreak = c;
      }
    }

    return threaded > historyStreak ? threaded : historyStreak;
  }

  /// A criterion DOMINATES when the child keeps missing — a recent mistake
  /// repeated ≥2 times (mirrors `_deriveStruggleTags`' ">=2 occurrences" idiom).
  bool _criterionDominates(TutorFacts facts) {
    if (facts.passed || facts.weakestCriterion == null) return false;
    final counts = <String, int>{};
    for (final m in facts.recentMistakes) {
      counts[m] = (counts[m] ?? 0) + 1;
    }
    return counts.values.any((c) => c >= 2);
  }

  /// The step-DOWN candidates for an active-arc step: the step-down target
  /// (drill for a production miss, floor trace for a trace miss — see
  /// [_stepDownTarget]) plus the original to retry, rail-checked.
  List<String> _drillOrRetry(
    String letterId,
    String? criterion,
    String? retry,
    GraphPosition position,
  ) {
    // A step DOWN must still step down, never re-present the failing card as its
    // own remediation: land the step-down target first; rebuild → retryOriginal
    // follow.
    final down = _stepDownTarget(letterId, criterion, retry, position);
    return _legalize([?down, ?retry], position);
  }

  /// The arc step-DOWN target. For a PRODUCTION miss it is the criterion's
  /// restored micro-drill (D-18/R3 — just-this-part practice). But when the
  /// exercise the child is failing ([failingId]) is ITSELF a guided trace, the
  /// confidence rebuild is the guaranteed-doable FLOOR TRACE, not a sub-part
  /// drill: a same-criterion trace fail steps down to the floor trace so the arc
  /// re-presents a doable full-letter success (UAT T6 — the floor-trace
  /// step-down + re-present that keeps "Next exercise" alive; do NOT let a
  /// restored micro-drill preempt it). The drill stays a live candidate via the
  /// R3 injection either way (D-18 graph nodes unchanged) — it just never
  /// preempts the floor when the child is already at the trace level.
  String? _stepDownTarget(
    String letterId,
    String? criterion,
    String? failingId,
    GraphPosition position,
  ) {
    final floor = _floorTrace(letterId, position);
    final failingTrace =
        failingId != null && failingId.contains('.traceLetter.');
    if (failingTrace) return floor;
    final drill =
        criterion == null ? null : graph.drillForCriterion(letterId, criterion);
    return drill ?? floor;
  }

  /// The guaranteed-doable trace success the floor guard lands on (D-04) — the
  /// first legal `traceLetter` node for [letterId].
  String? _floorTrace(String letterId, GraphPosition position) {
    for (final n in graph.nodes) {
      if (n.exerciseId.startsWith('$letterId.') &&
          n.exerciseId.contains('.traceLetter.') &&
          _isLegal(n.exerciseId, position)) {
        return n.exerciseId;
      }
    }
    return null;
  }

  /// Every LEGAL node after the child's current position in declaration order.
  List<String> _legalForward(GraphPosition position) {
    final out = <String>[];
    final startIndex =
        graph.nodes.indexWhere((n) => n.exerciseId == position.currentExerciseId);
    final from = startIndex < 0 ? 0 : startIndex + 1;
    for (var i = from; i < graph.nodes.length; i++) {
      final id = graph.nodes[i].exerciseId;
      if (_isLegal(id, position) && !out.contains(id)) out.add(id);
    }
    return out;
  }

  /// Keep only rail-legal, de-duplicated ids (defense in depth, T-18-04-01).
  List<String> _legalize(List<String> ids, GraphPosition position) {
    final out = <String>[];
    for (final id in ids) {
      if (!out.contains(id) && _isLegal(id, position)) out.add(id);
    }
    return out;
  }

  /// The single legality gate — the graph rail is the authority (D-09).
  bool _isLegal(String id, GraphPosition position) => graph.isLegalSelection(
        id,
        clearedTiers: position.clearedTiers,
        clearedCompetencies: position.clearedCompetencies,
      );
}
