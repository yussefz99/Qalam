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
TutorFacts buildTutorFacts({
  required String letterId,
  required String section,
  required CheckResult result,
  List<String> recentMistakes = const [],
  List<AttemptFact> trajectory = const [],
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
