/// Pure Dart. No cloud-AI / on-device-model package imports here or in any
/// sibling spine contract file — this is the swappable seam, not an impl.
///
/// `TutorBrain` is THE one seam of the v2 tutor (ADR-014 §Decision part 4 /
/// 14-CONTEXT `decisions`): one method, FACTS-in to ACTIONS-out. Three
/// implementations plug in behind it — `AuthoredFallbackBrain` (the offline
/// floor, this plan), `GeminiBrain` (cloud, 14-02), `GemmaBrain` (on-device
/// experimental, later). Swapping the backend changes no canvas, scorer, or
/// curriculum code (TUTOR-01).
library;

import 'tutor_decision.dart';
import 'tutor_facts.dart';

/// The single swappable tutor seam. Given a non-PII [TutorFacts] snapshot,
/// answer with exactly one ACTION [TutorDecision]. Implementations never decide
/// pass/fail or the star — the scorer owns the verdict (GROUND-01).
abstract class TutorBrain {
  Future<TutorDecision> next(TutorFacts facts);
}
