/// Pure Dart. No cloud-AI / on-device-model package imports, no Firebase, no
/// network. The OFFLINE FLOOR (ADR-014 §Decision part 4 / 14-CONTEXT
/// `offline floor`; TUTOR-02): with zero model loaded, in airplane mode, every
/// coaching moment still yields a grounded, correctly-Arabic authored line and
/// the trace loop never blocks.
///
/// It resolves the SAME authored line `ExerciseController.applyResult` would —
/// `feedback['pass']` on a pass, `feedback[mistakeId]` on a miss, the first
/// non-'pass' authored line as the floor — so the offline brain line is
/// byte-identical to the verdict-side line by construction.
library;

import 'tutor_brain.dart';
import 'tutor_decision.dart';
import 'tutor_facts.dart';

/// The guaranteed-degrade [TutorBrain]. Construct it with the active exercise's
/// signed-off `feedback` map; it speaks one grounded line per [next] call.
class AuthoredFallbackBrain implements TutorBrain {
  const AuthoredFallbackBrain({required this.feedback});

  /// `{ pass: praiseLine, <mistakeId>: fixLine, ... }` — the owner's-mother
  /// signed-off coaching lines for the active exercise (see `Exercise.feedback`).
  final Map<String, String> feedback;

  @override
  Future<TutorDecision> next(TutorFacts facts) async {
    final line = _resolveLine(facts);
    // A PresentActivity carries the line + the current letter so the UI can keep
    // the activity context; on the offline floor the line IS the authored line.
    return PresentActivity(coachingLine: line, letterId: facts.letterId);
  }

  /// Mirror of `ExerciseController.applyResult`'s resolution, kept deterministic:
  ///   • pass            → feedback['pass']
  ///   • miss (known id) → feedback[mistakeId]
  ///   • miss (unknown)  → the first non-'pass' authored line (the floor)
  /// Empty only when nothing is authored at all (then there is nothing to say).
  String _resolveLine(TutorFacts facts) {
    if (facts.passed) return feedback['pass'] ?? '';
    final id = facts.mistakeId;
    final direct = id != null ? feedback[id] : null;
    return direct ?? _firstMiss();
  }

  /// The first non-'pass' authored line — so a miss with an unmatched id still
  /// shows AUTHORED copy, never a generic "try again". Empty if none authored.
  String _firstMiss() {
    for (final entry in feedback.entries) {
      if (entry.key != 'pass') return entry.value;
    }
    return '';
  }
}
