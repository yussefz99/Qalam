/// Pure Dart. No Flutter rendering import, no stroke parameter, no profile/PII
/// parameter — by construction a caller cannot pass raw geometry or a nickname
/// through this function. This is the ONE chokepoint that turns a deterministic verdict +
/// session state into the whitelisted [TutorFacts] the tutor sees (ADR-014
/// §Decision part 4 / grounding summary part 3; GROUND-02 / non-PII guard).
library;

import '../core/exercise_engine/check_result.dart';
import 'tutor_facts.dart';

/// Build the non-PII [TutorFacts] for one coaching moment.
///
/// The signature is the guard: it accepts the already-derived [result] (a bool +
/// an authored key — see `CheckResult`), the [letterId]/[section] ids, the
/// session's [recentMistakes] (non-PII id strings), and the session [trajectory]
/// (a list of already-derived [AttemptFact] records). It CANNOT accept strokes,
/// `Offset`s, or a profile object — so none can ever reach the model.
///
/// `struggleTags` are derived deterministically from [recentMistakes]: the
/// distinct ids the child has missed more than once this session (the ones worth
/// the tutor's attention), most-recent-first. `strengthTags` are the inverse —
/// the sections passed cleanly (with no miss) across the [trajectory]. Both are
/// pure + deterministic, no PII.
///
/// [clearedTiers] / [clearedCompetencies] are the child's durable graph-position
/// state, read from the Drift `LetterGraphPosition` on resume (D-08 trajectory
/// replay) — pure non-PII id strings. They are passed straight through (no
/// derivation): the source of truth is the persisted position, not the session.
/// They mirror `TutorFactsIn.clearedTiers`/`clearedCompetencies`
/// (`server/app/schema.py`) byte-for-byte — the 422 lockstep (Pitfall 1).
///
/// Phase 17 (17-06, STRK-01 / D-B / GROUND-04): the STRUCTURED `criteria` +
/// `weakestCriterion` and the F6 `expectedWord`/`writtenWord` are read straight
/// off [result] — the validator already serialized the scorer's `LetterScore`
/// into the non-PII `CheckResult`. Deriving them here (NOT via a new parameter)
/// keeps the signature the guard: no stroke/Offset/word parameter exists, so raw
/// geometry can never reach the model. They mirror `TutorFactsIn.criteria` /
/// `weakestCriterion` / `expectedWord` / `writtenWord` (`server/app/schema.py`)
/// byte-for-byte — the 422 lockstep (Pitfall 1).
TutorFacts buildTutorFacts({
  required String letterId,
  required String section,
  required CheckResult result,
  List<String> recentMistakes = const [],
  List<AttemptFact> trajectory = const [],
  List<String> clearedTiers = const [],
  List<String> clearedCompetencies = const [],
  Map<String, Object?>? strokeDiff,
  List<String> legalNextExerciseIds = const [],
}) {
  return TutorFacts(
    letterId: letterId,
    section: section,
    passed: result.passed,
    mistakeId: result.mistakeId,
    struggleTags: _deriveStruggleTags(recentMistakes),
    strengthTags: _deriveStrengthTags(trajectory),
    recentMistakes: List<String>.unmodifiable(recentMistakes),
    trajectory: List<AttemptFact>.unmodifiable(trajectory),
    clearedTiers: List<String>.unmodifiable(clearedTiers),
    clearedCompetencies: List<String>.unmodifiable(clearedCompetencies),
    strokeDiff: strokeDiff,
    // Phase 17 (17-06): the STRUCTURED criteria + derived word facts are DERIVED
    // FROM the already-non-PII [result] (the scorer serialized them into the
    // CheckResult) — NOT new parameters. The signature stays the guard: no
    // stroke/Offset/word parameter can reach the model; only what the validator
    // already froze into the CheckResult travels. Omit-when-null in TutorFacts.
    criteria: result.criteria,
    weakestCriterion: result.weakestCriterion,
    expectedWord: result.expectedWord,
    writtenWord: result.writtenWord,
    // Phase 17.2 (demo): the graph-legal next-exercise candidates — threaded
    // straight through (non-PII curriculum-id strings), so the coach can propose
    // the next exercise FROM the graph. Omit-when-empty is handled in TutorFacts.
    legalNextExerciseIds: List<String>.unmodifiable(legalNextExerciseIds),
  );
}

/// The distinct mistake ids seen 2+ times in [recentMistakes], in order of first
/// appearance (most-recent-first, matching the caller's recency ordering). These
/// are the patterns the tutor should coach against — a one-off slip is not a
/// "struggle".
List<String> _deriveStruggleTags(List<String> recentMistakes) {
  final counts = <String, int>{};
  for (final id in recentMistakes) {
    counts[id] = (counts[id] ?? 0) + 1;
  }
  final tags = <String>[];
  final seen = <String>{};
  for (final id in recentMistakes) {
    if ((counts[id] ?? 0) >= 2 && seen.add(id)) {
      tags.add(id);
    }
  }
  return List<String>.unmodifiable(tags);
}

/// The inverse of struggles: the distinct sections the child passed CLEANLY this
/// session — every attempt in that section in the [trajectory] was a pass (no
/// miss). A section with even one miss is a struggle surface, never a strength.
/// Deterministic, in first-appearance order, no PII.
List<String> _deriveStrengthTags(List<AttemptFact> trajectory) {
  // A section is a strength iff it appears and NONE of its attempts missed.
  final everMissed = <String>{};
  final seenSections = <String>[];
  final seen = <String>{};
  for (final a in trajectory) {
    if (seen.add(a.section)) seenSections.add(a.section);
    if (!a.passed) everMissed.add(a.section);
  }
  final tags = [
    for (final s in seenSections)
      if (!everMissed.contains(s)) s,
  ];
  return List<String>.unmodifiable(tags);
}
