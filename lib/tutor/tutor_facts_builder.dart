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
/// an authored key — see `CheckResult`), the [letterId]/[section] ids, and the
/// session's [recentMistakes] (non-PII id strings). It CANNOT accept strokes,
/// `Offset`s, or a profile object — so none can ever reach the model.
///
/// `struggleTags` are derived deterministically from [recentMistakes]: the
/// distinct ids the child has missed more than once this session (the ones worth
/// the tutor's attention), most-recent-first. Pure + deterministic, no PII.
TutorFacts buildTutorFacts({
  required String letterId,
  required String section,
  required CheckResult result,
  List<String> recentMistakes = const [],
}) {
  return TutorFacts(
    letterId: letterId,
    section: section,
    passed: result.passed,
    mistakeId: result.mistakeId,
    struggleTags: _deriveStruggleTags(recentMistakes),
    recentMistakes: List<String>.unmodifiable(recentMistakes),
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
