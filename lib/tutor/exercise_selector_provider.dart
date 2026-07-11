/// The selection-seam Riverpod wiring (Plan 15-05 / DYN-02 / Open Q1). This is
/// the ONE switch point where next-exercise SELECTION is routed online↔offline —
/// the sibling of `tutorBrainFactoryProvider` (which routes COACHING). The two
/// degrade on SEPARATE axes (Pitfall 5): coaching falls to `AuthoredFallbackBrain`,
/// selection falls to `CurriculumGraphWalker`. Riverpod-only (CLAUDE.md Decided —
/// no BLoC/GetX).
///
/// SELECTION vs COACHING (different axes):
///   • COACHING  — `TutorBrain.next(facts)` → a coaching LINE (the words). Online
///                 RemoteAgentBrain, offline AuthoredFallbackBrain.
///   • SELECTION — `ExerciseSelector.selectNext(facts, position)` → the next
///                 exercise ID (what comes next). Online the agent's
///                 `plan.nextExerciseId` (when graph-legal), offline the walker.
///
/// ONLINE selection is UNTRUSTED (T-15-05-T): the agent's proposed
/// `plan.nextExerciseId` is re-checked CLIENT-SIDE against the SAME graph
/// legality rules the server's G5/G6 rail applies (`CurriculumGraph.isLegalSelection`
/// — authored + tier-reachable + prereqs-met). An illegal / absent / off-graph
/// proposal degrades to the offline `CurriculumGraphWalker` — NEVER the old fixed
/// 6-section linear sequence (Pitfall 5).
///
/// NOTE on layering: this router lives in `lib/tutor/` (NOT `lib/curriculum/`) on
/// purpose — `lib/curriculum/` is the pure on-device spine (no Riverpod, no
/// network, no agent import; guarded by `durable_layers_no_agent_imports_test.dart`).
/// The router is the seam that COMBINES the pure walker with the (network) agent
/// decision, so it belongs beside `tutor_providers.dart`.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../curriculum/curriculum_graph.dart';
import '../curriculum/curriculum_graph_walker.dart';
import '../curriculum/selection_policy.dart';
import 'tutor_decision.dart';
import 'tutor_facts.dart';

/// The bundled single-source curriculum-graph asset (the SAME file the server's
/// G5/G6 rail derives its copy from — D-04, single source of truth).
const String kCurriculumGraphAsset = 'assets/curriculum/curriculum_graph.json';

/// Loads + parses the single-source curriculum graph once (keepAlive, mirroring
/// `appDatabaseProvider`). The parser ([CurriculumGraph.fromJson]) is pure — the
/// `rootBundle` read lives HERE (the loader), never inside the pure layer.
///
/// A `Future`-returning provider (Pitfall 6: never a bare `StreamProvider.future`,
/// which hangs under Riverpod 3). Read it with `ref.watch(curriculumGraphProvider.future)`
/// or via `.when(...)`.
final curriculumGraphProvider = FutureProvider<CurriculumGraph>((ref) async {
  ref.keepAlive();
  final raw = await rootBundle.loadString(kCurriculumGraphAsset);
  final decoded = json.decode(raw) as Map<String, Object?>;
  return CurriculumGraph.fromJson(decoded);
});

/// The online↔offline SELECTION router behind the [ExerciseSelector] seam.
///
/// It walks the SAME [CurriculumGraph] the offline walker uses. The ONLY
/// difference from the bare walker is that — when an agent decision is supplied
/// AND its `plan.nextExerciseId` is graph-legal for the child's current cleared
/// state — it accepts the agent's choice (the online path). Otherwise it
/// delegates to the offline [CurriculumGraphWalker] (Pitfall 5: selection
/// degrades independently of coaching; it never reverts to the linear walk).
class RouterExerciseSelector implements ExerciseSelector {
  RouterExerciseSelector(
    this.graph, {
    this.arc,
    this.profile,
    this.sessionHistory,
  })  : _walker = CurriculumGraphWalker(graph),
        _policy = SelectionPolicy(graph);

  /// The single-source graph both paths rail on.
  final CurriculumGraph graph;

  /// The durable remediation-arc cursor for the current moment (18-07 threads it
  /// from Drift via [ArcStateRepository]); null when no arc is in progress.
  final ArcState? arc;

  /// The compiled across-session profile mirror (18-06); null when unavailable
  /// (cold boot / offline). Only narrows the WHY, never widens the rail.
  final ChildModelSnapshot? profile;

  /// The criterion-tagged in-session attempt store (18-07) — the fail-streak
  /// source that drives anti-boredom + arc entry. Null for a single-shot call.
  final List<SessionAttempt>? sessionHistory;

  final CurriculumGraphWalker _walker;
  final SelectionPolicy _policy;

  /// Pick the next exercise. It first NARROWS to the pure [SelectionPolicy]'s
  /// graph-legal candidate set (anti-boredom + arc + micro-drill, all re-checked
  /// against `isLegalSelection`), then:
  ///   • ONLINE — accepts the agent's `plan.nextExerciseId` ONLY when it is BOTH
  ///     a policy candidate AND graph-legal (the trust boundary is unchanged: the
  ///     policy narrows, the rail decides legality — T-18-07-01). Any illegal /
  ///     off-set / absent proposal is rejected.
  ///   • OFFLINE / rejected — degrades to the walker's deterministic pick over the
  ///     SAME narrowed candidate set (`selectFrom`), so the offline floor is
  ///     identical to the online degrade by construction (D-11, offline parity).
  /// Never the old fixed linear sequence (Pitfall 5); never an out-of-rail id.
  @override
  String? selectNext(
    TutorFacts facts,
    GraphPosition position, {
    TutorDecision? decision,
  }) {
    final out = _policy.narrow(
      facts,
      position,
      arc: arc,
      profile: profile,
      sessionHistory: sessionHistory,
    );
    final candidates = out.candidates;

    final proposed = decision?.plan?.nextExerciseId;
    if (proposed != null &&
        candidates.contains(proposed) &&
        graph.isLegalSelection(
          proposed,
          clearedTiers: position.clearedTiers,
          clearedCompetencies: position.clearedCompetencies,
        )) {
      // ONLINE: the agent proposed a policy-legal candidate — accept it.
      return proposed;
    }
    // OFFLINE / illegal / off-set / absent: the deterministic walker over the
    // SAME narrowed candidate set (never the linear walk — Pitfall 5).
    return _walker.selectFrom(candidates, facts, position);
  }
}

/// The OFFLINE authored WHY template (D-10). Turns the pure policy's non-PII
/// [whyFacts] (`criterion:<name>`, `arcStep:<step>`, `struggle:<letter/criterion>`)
/// into one short, warm, child-facing sentence NAMING the criterion + arc step —
/// the offline floor's answer to "why this next?" when no coach line is available.
///
/// It is the selection-side twin of `AuthoredFallbackBrain`: deterministic, fully
/// offline, zero model. Online the coach LLM phrases the same facts (18-08); this
/// is the guaranteed-degrade line. Empty only when there is nothing to justify.
String authoredWhyLine(List<String> whyFacts) {
  String? valueFor(String key) {
    for (final f in whyFacts) {
      if (f.startsWith('$key:')) return f.substring(key.length + 1);
    }
    return null;
  }

  final criterion = valueFor('criterion');
  final arcStep = valueFor('arcStep');
  if (criterion == null && arcStep == null) return '';

  // A friendly label per scorer criterion (the tutor's voice — specific, calm).
  const label = <String, String>{
    'shape': 'the bowl',
    'dot': 'the dot',
    'direction': 'the direction',
    'strokeOrder': 'the stroke order',
    'strokeCount': 'the strokes',
  };
  final what = criterion == null ? 'this' : (label[criterion] ?? criterion);

  switch (arcStep) {
    case 'entry':
    case 'stepDown':
      return "Let's work on $what — one small step at a time.";
    case 'rebuild':
      return "You're getting $what — let's build it back up.";
    case 'retryOriginal':
      return "Now let's try $what again — slower this time.";
    default:
      return "Let's practice $what next.";
  }
}

/// THE single SELECTION switch point (DYN-02) — the sibling of
/// `tutorBrainFactoryProvider`. Exposes the [ExerciseSelector] the baa unit reads
/// to choose what comes next. KeepAlive mirrors `appDatabaseProvider` /
/// `tutorBrainFactoryProvider`.
///
/// It depends on [curriculumGraphProvider]; while the graph loads it yields a
/// [_PendingSelector] (a calm no-op that returns null — the unit shows the
/// "preparing" state, never a crash). Once loaded it is a [RouterExerciseSelector]
/// over the parsed graph.
final exerciseSelectorProvider = Provider<ExerciseSelector>((ref) {
  final graphAsync = ref.watch(curriculumGraphProvider);
  return graphAsync.maybeWhen(
    data: RouterExerciseSelector.new,
    orElse: () => const _PendingSelector(),
  );
});

/// The calm no-op selector used while the graph is still loading (or failed to
/// load). It returns null so the unit degrades to its "preparing" state rather
/// than crashing — never the old fixed linear walk.
class _PendingSelector implements ExerciseSelector {
  const _PendingSelector();

  @override
  String? selectNext(
    TutorFacts facts,
    GraphPosition position, {
    TutorDecision? decision,
  }) =>
      null;
}
