/// Pure Dart aside from `foundation` (debugPrint). No cloud-AI / on-device-model
/// package imports.
///
/// The native function-call dispatcher (ADR-014 §Decision part 3 / grounding
/// summary part 5). It maps each ACTION the tutor chose to ONE imperative call on
/// a [TutorController] — a closed `switch` over the 4 ACTION tools. Two grounding
/// rules are encoded here by construction:
///
///   1. There is NO "set verdict" / "award star" branch. The dispatcher can only
///      ever drive the 4 ACTION methods below; it physically cannot flip a fail
///      to a pass (GROUND-01). The scorer owns the verdict at
///      `ExerciseController.applyResult`.
///   2. An unrecognized tool name is a logged no-op — never a throw, never a
///      crash (grounding summary part 5).
///
/// The Phase 11 kill-shot lesson lives here too: this dispatches IMPERATIVELY.
/// The `StrokeCanvas` is never rebuilt from agent state — the controller adapter
/// only writes a coaching LINE (14-01 Task 3 wires it into `tutorLineProvider`).
library;

import 'package:flutter/foundation.dart';

import 'tutor_decision.dart';

/// The imperative surface the tutor drives. Deliberately the 4 ACTION verbs and
/// NOTHING else — notably no `setVerdict`/`awardStar`. An adapter implements this
/// (14-01 Task 3) to write the line into the tutor-owned provider.
abstract class TutorController {
  void say(String text);
  void presentActivity(String letterId, String coachingLine);
  void giveHint();
  void advance();
}

/// Dispatch a typed [decision] (carrying its payload) to [controller]. The
/// closed `switch` over the sealed [TutorDecision] is exhaustive — the analyzer
/// guarantees no fifth shape can be added without updating this seam.
void dispatchTutorDecision(TutorDecision decision, TutorController controller) {
  switch (decision) {
    case Say(:final text):
      controller.say(text);
    case PresentActivity(:final coachingLine, :final letterId):
      controller.presentActivity(letterId, coachingLine);
    case GiveHint():
      controller.giveHint();
    case Advance():
      controller.advance();
  }
}

/// Dispatch by raw tool NAME — the entry point GeminiBrain's function-call loop
/// uses (14-02). This is the closed grounding switch over [TutorTool.all]; an
/// unrecognized name (e.g. a hallucinated `set_verdict`) is a logged no-op.
///
/// The payload-bearing names (`say`/`present_activity`) accept optional
/// [text]/[letterId] extracted from the model's function-call args; they default
/// to empty so a malformed call degrades to a quiet no-op rather than a crash.
void dispatchTutorToolName(
  String name,
  TutorController controller, {
  String text = '',
  String letterId = '',
  String coachingLine = '',
}) {
  switch (name) {
    case TutorTool.say:
      controller.say(text);
    case TutorTool.presentActivity:
      controller.presentActivity(letterId, coachingLine);
    case TutorTool.giveHint:
      controller.giveHint();
    case TutorTool.advance:
      controller.advance();
    default:
      // Unrecognized tool — never a verdict path, never a crash (GROUND-01).
      debugPrint('TutorDispatcher: ignoring unrecognized tool "$name"');
  }
}
