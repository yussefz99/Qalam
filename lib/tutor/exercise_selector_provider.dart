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
  RouterExerciseSelector(this.graph) : _walker = CurriculumGraphWalker(graph);

  /// The single-source graph both paths rail on.
  final CurriculumGraph graph;

  final CurriculumGraphWalker _walker;

  /// Pick the next exercise. With no [decision] (offline / no server reply) this
  /// is exactly the offline walker. With a [decision] whose `plan.nextExerciseId`
  /// is graph-legal it accepts the agent's choice (online); an illegal/absent
  /// proposal falls to the walker.
  ///
  /// Graph-legality re-check (T-15-05-T) uses the child's cleared state from
  /// [position]: authored membership + tier reachability + prerequisites — the
  /// SAME rules the server's G5/G6 rail applies (so client and server agree).
  @override
  String? selectNext(
    TutorFacts facts,
    GraphPosition position, {
    TutorDecision? decision,
  }) {
    final proposed = decision?.plan?.nextExerciseId;
    if (proposed != null &&
        graph.isLegalSelection(
          proposed,
          clearedTiers: position.clearedTiers,
          clearedCompetencies: position.clearedCompetencies,
        )) {
      // ONLINE: the agent proposed a graph-legal next exercise — accept it.
      return proposed;
    }
    // OFFLINE / illegal / absent: the deterministic walker (advance on pass,
    // remediate one tier down on fail; never the linear walk — Pitfall 5).
    return _walker.selectNext(facts, position);
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
