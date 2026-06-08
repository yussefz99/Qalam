// Phase 4: MlKitRecognizer (ml_kit_recognizer.dart) implements this interface.
// Phase 3 deliberately left it unimplemented (D-16) — the geometric scorer never
// needs the network; the ML Kit gate (D-04) is advisory-only and lives behind here.
//
// The seam takes a WHOLE multi-stroke letter, not a single stroke: a baa is a body
// line PLUS a dot, and ML Kit recognises a letter from all of its strokes together
// (each child stroke becomes one ML Kit `Stroke` in the `Ink`). The signature was
// widened from `List<List<double>>` (one stroke) to `List<List<List<double>>>`
// (a list of strokes, each a list of `[x, y]` pairs) in Plan 04-03 — the documented
// Claude's-discretion interface decision (CONTEXT). The orchestrator (scoreLetter)
// applies the D-04 advisory rule; this seam only reports identity, never a verdict.
abstract interface class HandwritingRecognizer {
  /// Reports the most likely letter identity for a whole captured letter.
  ///
  /// [letterStrokes] is the per-letter capture: a list of strokes, each a list of
  /// `[x, y]` pixel-coordinate pairs in capture order. Returns the top candidate
  /// and a 0..1 confidence; an empty/failed recognition returns a null candidate
  /// with confidence 0 so the caller can degrade to "no opinion" (D-04 / Pitfall 1).
  Future<RecognitionResult> identify(List<List<List<double>>> letterStrokes);
}

/// The advisory output of a [HandwritingRecognizer] — a reported identity, never a
/// pass/fail verdict. [topCandidate] is the recogniser's best guess at the letter
/// (e.g. `'ب'`), or null when it has no opinion. [confidence] is a 0..1 trust value;
/// the orchestrator ignores anything below its floor (Pitfall 1 — weak evidence
/// never overrides a geometric pass).
class RecognitionResult {
  final String? topCandidate;
  final double confidence;
  const RecognitionResult({this.topCandidate, this.confidence = 0.0});
}
