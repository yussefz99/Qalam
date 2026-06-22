/// Pure Dart, no Flutter and no cloud-AI / on-device-model package imports.
///
/// `TutorDecision` is the **ACTIONS-out** side of the `TutorBrain` seam
/// (ADR-014 §Decision part 4 / 14-CONTEXT `decisions`). A brain — authored,
/// Gemini, or Gemma — answers `next(facts)` with exactly ONE of four ACTION
/// shapes. There is, by construction, NO "set verdict" / "award star" decision:
/// the deterministic scorer owns pass/fail + the mastery star (GROUND-01); the
/// agent only chooses WORDS and the next exercise.
///
/// The four ACTION tool NAMES live here as the single source of truth
/// ([TutorTool]) so the dispatcher, the FunctionDeclarations (14-02), and these
/// shapes can never drift apart. (See ADR-014 `Decision part 4`.)
library;

/// The four — and only four — ACTION tool names. Pinned here once; the dispatcher
/// switches over these, GeminiBrain's `FunctionCallingConfig.any({...})` pins the
/// model to exactly this set (14-02), and every [TutorDecision] reports one of
/// them via [TutorDecision.toolName].
abstract final class TutorTool {
  const TutorTool._();

  static const String presentActivity = 'present_activity';
  static const String say = 'say';
  static const String giveHint = 'give_hint';
  static const String advance = 'advance';

  /// The closed action space. There is no fifth tool, and notably no verdict/star
  /// tool — those are FACTS the scorer injects, never actions the agent takes.
  static const Set<String> all = {presentActivity, say, giveHint, advance};
}

/// One ACTION the tutor chose. Sealed: the dispatcher's `switch` is exhaustive
/// over exactly these four subtypes, and the analyzer enforces that no fifth
/// shape can be added without updating every consumer.
sealed class TutorDecision {
  const TutorDecision();

  /// The ACTION tool this decision corresponds to — always one of [TutorTool].
  String get toolName;
}

/// `present_activity{coachingLine, letterId}` — show/refresh the current activity
/// for [letterId] while speaking [coachingLine]. The grounded coaching line.
final class PresentActivity extends TutorDecision {
  const PresentActivity({required this.coachingLine, required this.letterId});

  final String coachingLine;
  final String letterId;

  @override
  String get toolName => TutorTool.presentActivity;
}

/// `say{text}` — speak a single coaching line, no activity change.
final class Say extends TutorDecision {
  const Say(this.text);

  final String text;

  @override
  String get toolName => TutorTool.say;
}

/// `give_hint{}` — surface the next authored hint for the current activity.
final class GiveHint extends TutorDecision {
  const GiveHint();

  @override
  String get toolName => TutorTool.giveHint;
}

/// `advance{}` — move to the next exercise. (The scorer still gates whether a
/// section may advance; this is the agent REQUESTING it, never overriding it.)
final class Advance extends TutorDecision {
  const Advance();

  @override
  String get toolName => TutorTool.advance;
}
