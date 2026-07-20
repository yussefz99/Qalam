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

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../curriculum/curriculum_graph.dart';
import '../curriculum/curriculum_graph_walker.dart';
import '../curriculum/selection_policy.dart';
import '../data/curriculum_repository.dart';
import 'tutor_decision.dart';
import 'tutor_facts.dart';

/// The per-letter curriculum-graph asset path (quick task 260718-il4, Stage 1 of
/// all-letters-live). Each live letter has its OWN graph under
/// `assets/curriculum/graphs/<letterId>.json` — so the walker / controller /
/// selection rail work for ANY letter, never a silent baa default.
///
/// NOTE (Stage-1 duplication): the server's `generate.py` and the baa lint still
/// read `assets/curriculum/curriculum_graph.json`; `graphs/baa.json` is a
/// byte-parity copy of it, kept in sync by `graph_asset_parity_test.dart` until
/// Stage 2 unifies the server. This provider reads the per-letter copy.
String kCurriculumGraphAssetFor(String letterId) =>
    'assets/curriculum/graphs/$letterId.json';

/// Loads + parses the per-letter curriculum graph once per letterId (keepAlive,
/// mirroring `appDatabaseProvider`). A [FutureProvider.family] keyed by letterId:
/// `curriculumGraphProvider('baa')` loads baa's graph,
/// `curriculumGraphProvider('thaa')` loads thaa's — the two are DISTINCT graphs
/// (never a shared baa default). The parser ([CurriculumGraph.fromJson]) is
/// pure — the I/O lives HERE (the loader), never inside the pure layer.
///
/// CONTENT RESOLUTION ORDER (finalization Lane A — mirrors the
/// letters/exercises/units repository pattern, D-01/D-02):
///   1. Firestore `graphs/<letterId>` doc (via [CurriculumRepository.getGraphJson])
///   2. the bundled `assets/curriculum/graphs/<letterId>.json` asset fallback.
/// This is what makes "add a letter by only touching the database" true for the
/// progression rail: seeding a graph doc brings a letter live with NO rebuild.
/// A letter with neither source still load-fails harmlessly (the unit degrades
/// to the static flow — the established never-crash posture).
///
/// A `Future`-returning provider (Pitfall 6: never a bare `StreamProvider.future`,
/// which hangs under Riverpod 3). Read it with
/// `ref.watch(curriculumGraphProvider(letterId).future)` or via `.when(...)`.
final curriculumGraphProvider =
    FutureProvider.family<CurriculumGraph, String>((ref, letterId) async {
  ref.keepAlive();
  // 1) Firestore-first (never throws; null → fall through to the bundle).
  final fromFirestore =
      await ref.watch(curriculumRepositoryProvider).getGraphJson(letterId);
  if (fromFirestore != null) return CurriculumGraph.fromJson(fromFirestore);
  // 2) Bundled-asset fallback (cold first run / offline / unseeded letter).
  final raw = await rootBundle.loadString(kCurriculumGraphAssetFor(letterId));
  final decoded = json.decode(raw) as Map<String, Object?>;
  return CurriculumGraph.fromJson(decoded);
});

// ── L3 runtime guard: the seen-letters filter (Plan 25-05 / QP-07 / D-12) ─────
//
// The LAST line of the seen-letters wall. Even if bad data ships to Firestore
// (past L0 audit / L1 lint / L2 seeder), the runtime selector must NEVER present
// a card that demands a letter the child has not yet seen: it SKIPs it and the
// walker advances to the next legal node (D-01), the star stays reachable (D-02),
// and every firing is logged loudly (D-03). L2 refuses at the WRITE; L3 refuses at
// the READ — the same Firestore-first bypass, two surfaces.

/// The owner-approved reach-ahead EXCEPTION ids — now EMPTY. L1
/// (`baaOwnerApprovedExceptions` / `taaOwnerApprovedExceptions` /
/// `thaaOwnerApprovedExceptions` in learned_letters_lint_test.dart) and L2
/// (`OWNER_APPROVED_EXCEPTIONS`, tools/content/validate.py) are ALSO empty, so all
/// four wall layers now refuse EVERY reach-ahead card by design — PARITY across the
/// wall (the whole wall's thesis: refuse the SAME thing, exempt the SAME thing). With
/// the allowlist empty there is nothing to exempt; the L3 guard drops any reach-ahead
/// candidate. The parity is pinned by `test/tutor/l3_learned_letters_parity_test.dart`.
///
/// PROVENANCE (both groups are gone as of 2026-07-20):
///   • ~~4 baa D-09 — owner-approved from device UAT (2026-07-18).~~ EMPTIED
///     2026-07-20 (quick task 260720-up4): those 4 reach-ahead grammar cards were
///     made DORMANT (nodes removed from the baa graph so they never reach runtime),
///     reversing the mother's F1 verdict PENDING her re-confirmation packet.
///   • ~~18 taa/thaa D-16 — kept LIVE by owner decision (2026-07-19).~~ EMPTIED
///     2026-07-20 (quick task 260720-wcs, F2-INTERIM — supersedes D-16): the mother
///     ruled these reach-ahead word questions must become letter-FORM practice she has
///     not yet authored, so the owner made all 18 DORMANT (their nodes removed from the
///     taa/thaa graphs, which drop to 7 all-essential form nodes each). They never reach
///     runtime, so L3 needs no exemption for them. PENDING her re-confirmation packet.
const Set<String> kApprovedReachAheadExceptions = <String>{};

/// The pure L3 seen-letters legality check — the runtime mirror of the L1 lint's
/// `unlearnedFor` (learned_letters_lint_test.dart) + the L2 seeder's
/// `unlearned_letters_for_exercise` (validate.py). Given the child's current unit
/// (its `introOrder`) and each card's `letters[]`, it names the letters a candidate
/// demands that the child has NOT yet seen. Immutable + pure — the I/O that builds
/// it lives in [seenLettersFilterProvider], keeping the pure lib/curriculum/ layer
/// free of this new read (the `durable_layers_no_agent_imports_test.dart` guard).
class SeenLettersFilter {
  const SeenLettersFilter({
    required this.unitIntroOrder,
    required this.introOrder,
    required this.exerciseLetters,
  });

  /// The `introOrder` of the unit under test (its learned set = every letter with
  /// `introOrder <= unitIntroOrder`).
  final int unitIntroOrder;

  /// letters.json `introOrder` — the pedagogical lesson order (alif 1, baa 2 …).
  final Map<String, int> introOrder;

  /// exercises.json per-card `letters[]` — the letters each card demands.
  final Map<String, List<String>> exerciseLetters;

  /// A no-op filter — used when the learned-set data could not be loaded so the
  /// guard degrades to "present everything" (L3 filtering off for the session; the
  /// graph legality rail still holds). `1<<30` learns nothing, so nothing reaches
  /// ahead and nothing is dropped.
  factory SeenLettersFilter.disabled() => const SeenLettersFilter(
        unitIntroOrder: 1 << 30,
        introOrder: <String, int>{},
        exerciseLetters: <String, List<String>>{},
      );

  /// Build the filter for [letterId] from the decoded letters.json / exercises
  /// .json maps. A letter absent from `introOrder` gets the `1<<30` sentinel the
  /// lint uses (`introOrder[l] ?? 1<<30`), so an unknown letter reads as reaching
  /// ahead identically — the predicates agree byte-for-byte.
  factory SeenLettersFilter.fromAssets({
    required String letterId,
    required Map<String, Object?> lettersJson,
    required Map<String, Object?> exercisesJson,
  }) {
    final order = <String, int>{
      for (final l in (lettersJson['letters'] as List<Object?>? ?? const []))
        if (l is Map && l['id'] is String)
          l['id'] as String: (l['introOrder'] as num?)?.toInt() ?? (1 << 30),
    };
    final letters = <String, List<String>>{
      for (final e in (exercisesJson['exercises'] as List<Object?>? ?? const []))
        if (e is Map && e['id'] is String)
          e['id'] as String: <String>[
            for (final x in (e['letters'] as List<Object?>? ?? const []))
              if (x is String) x,
          ],
    };
    return SeenLettersFilter(
      unitIntroOrder: order[letterId] ?? (1 << 30),
      introOrder: order,
      exerciseLetters: letters,
    );
  }

  /// The letters [exerciseId] demands that are NOT yet learned at this unit
  /// (`introOrder > unitIntroOrder`). Empty == within the learned set. An id with
  /// no known `letters[]` reads as legal (mirrors the lint's unknown-id `const []`).
  List<String> unlearnedFor(String exerciseId) {
    final cardLetters = exerciseLetters[exerciseId] ?? const <String>[];
    return <String>[
      for (final l in cardLetters)
        if ((introOrder[l] ?? (1 << 30)) > unitIntroOrder) l,
    ];
  }

  /// True when [exerciseId] is legal to PRESENT at this unit: it does not reach
  /// ahead, OR its id is an owner-approved exception (parity with L1/L2 — a
  /// mother-approved / owner-decision reach-ahead card stays presentable).
  bool isSeenLegal(String exerciseId) =>
      kApprovedReachAheadExceptions.contains(exerciseId) ||
      unlearnedFor(exerciseId).isEmpty;
}

/// Loads the L3 seen-letters learned-set data for [letterId] once (keepAlive) — the
/// letters.json `introOrder` + every card's exercises.json `letters[]`. The new I/O
/// lives HERE in lib/tutor/ (never in the pure lib/curriculum/ spine). NEVER throws:
/// a load/parse failure yields a [SeenLettersFilter.disabled] so the guard can never
/// crash the selection path — a failure only disables L3 filtering for the session
/// (the graph legality rail + L0/L1/L2 build/seed gates still hold).
final seenLettersFilterProvider =
    FutureProvider.family<SeenLettersFilter, String>((ref, letterId) async {
  ref.keepAlive();
  try {
    final lettersRaw =
        await rootBundle.loadString('assets/curriculum/letters.json');
    final exercisesRaw =
        await rootBundle.loadString('assets/curriculum/exercises.json');
    return SeenLettersFilter.fromAssets(
      letterId: letterId,
      lettersJson: json.decode(lettersRaw) as Map<String, Object?>,
      exercisesJson: json.decode(exercisesRaw) as Map<String, Object?>,
    );
  } catch (e) {
    debugPrint(
      '[L3] seen-letters filter for "$letterId" could not load its data: $e — '
      'runtime L3 filtering is DISABLED this session (the graph legality rail '
      'still holds; L0/L1/L2 already gate the content at build + seed).',
    );
    return SeenLettersFilter.disabled();
  }
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
    this.seenFilter,
  })  : _walker = CurriculumGraphWalker(graph),
        _policy = SelectionPolicy(graph);

  /// The single-source graph both paths rail on.
  final CurriculumGraph graph;

  /// The L3 seen-letters guard (Plan 25-05). Null when the learned-set data is not
  /// (yet) loaded — the filter then NO-OPS (every candidate passes; the graph
  /// legality rail still holds). Supplied by [exerciseSelectorProvider] and by the
  /// controller's live selection path, both reading [seenLettersFilterProvider].
  final SeenLettersFilter? seenFilter;

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
    var candidates = out.candidates;

    // L3 guard (Plan 25-05 / D-01 SKIP + D-03 loud log): drop any candidate that
    // demands an UNSEEN letter — the LAST line before an illegal card reaches a
    // child even if bad data shipped past L0/L1/L2. An owner-approved exception
    // (kApprovedReachAheadExceptions — PARITY with L1/L2) is NEVER dropped. Every
    // drop is logged loudly (never a silent swallow — D-03). No new rail: the
    // dropped candidate simply falls out of the SAME set, so the agent-accept check
    // and the walker's `selectFrom` / forward scan below advance to the next LEGAL
    // node (D-01 SKIP). The log names ONLY the exercise id + demanded letter — no
    // strokes, no child id (T-25-05-I).
    final filter = seenFilter;
    if (filter != null && candidates.isNotEmpty) {
      final kept = <String>[];
      for (final id in candidates) {
        final unlearned = filter.unlearnedFor(id);
        if (unlearned.isEmpty || kApprovedReachAheadExceptions.contains(id)) {
          kept.add(id);
        } else {
          debugPrint(
            'L3 guard: $id illegal (demands ${unlearned.join(', ')}), skipped',
          );
        }
      }
      candidates = kept;
    }

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
/// `tutorBrainFactoryProvider`. Exposes the [ExerciseSelector] a letter's unit
/// reads to choose what comes next. A [Provider.family] keyed by letterId (Stage
/// 1 of all-letters-live) so each letter's selector rails on its OWN graph.
/// KeepAlive mirrors `appDatabaseProvider` / `tutorBrainFactoryProvider`.
///
/// It depends on `curriculumGraphProvider(letterId)`; while the graph loads it
/// yields a [_PendingSelector] (a calm no-op that returns null — the unit shows
/// the "preparing" state, never a crash). Once loaded it is a
/// [RouterExerciseSelector] over the parsed per-letter graph.
final exerciseSelectorProvider =
    Provider.family<ExerciseSelector, String>((ref, letterId) {
  final graphAsync = ref.watch(curriculumGraphProvider(letterId));
  // The L3 seen-letters guard (Plan 25-05), null until its data loads (the filter
  // then no-ops). A synchronous `.asData?.value` read — never a blocking `.future`.
  final seenFilter = ref.watch(seenLettersFilterProvider(letterId)).asData?.value;
  return graphAsync.maybeWhen(
    data: (graph) => RouterExerciseSelector(graph, seenFilter: seenFilter),
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
