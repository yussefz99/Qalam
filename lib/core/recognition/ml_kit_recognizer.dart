/// MlKitRecognizer — the on-device ML Kit Digital Ink implementation of the
/// [HandwritingRecognizer] seam (Plan 04-03, D-04).
///
/// PURPOSE: a COARSE safety net (SC#2). It answers one question — *"does this look
/// like a completely different letter / a scribble?"* — that the geometric scorer
/// cannot. It does NOT judge stroke count, order, direction, or shape; those stay
/// with the geometric scorer.
///
/// ADVISORY-ONLY (D-04 / Pitfall 1): this class NEVER returns a pass/fail verdict.
/// It only reports the recogniser's top candidate and a confidence. The
/// orchestrator ([scoreLetter]) decides whether to act on it, and only ever to
/// REJECT a confidently-different letter on an otherwise-good geometric pass —
/// never to rescue a geometric failure, and never gating a pass on weak evidence.
/// If ML Kit under-recognises an isolated ب/ت/ث (RESEARCH A4), this degrades to
/// "no opinion" (null candidate, confidence 0) so the geometric pass stands.
///
/// ON-DEVICE / OFFLINE: recognition runs entirely on-device via the official
/// `google_mlkit_digital_ink_recognition` plugin (CLAUDE.md: VALIDATED on-device
/// path, no network round-trip for scoring). The one-time Arabic model fetch is
/// owned by ModelDownloadService (D-05), not this class.
///
/// SECURITY (T-04-07 / T-01-05): child strokes are converted to an ML Kit `Ink`
/// in memory and handed to the on-device recogniser only. Nothing is transmitted,
/// printed, logged, or persisted. No PII flows through here.
library;

import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

import 'handwriting_recognizer.dart';

/// The BCP-47 language tag for the ML Kit Arabic-script model (RESEARCH A4).
/// Verified on-tablet later (Plan 06); the gate degrades gracefully if `ar`
/// under-recognises isolated letters (advisory-only by design).
const String kArabicModelCode = 'ar';

/// ML Kit's `RecognitionCandidate.score` is sparse and inverted ("more likely
/// candidates get lower values", and the field is unpopulated for models without
/// it). It is therefore unsafe to treat as a 0..1 confidence directly. Because the
/// gate is advisory-only (D-04), we map "the recogniser returned a best candidate"
/// to this single fixed confidence — high enough to clear the orchestrator's floor
/// (so a confidently-different letter can be flagged) but assigned to the TOP
/// candidate regardless of raw score, so the policy decision stays entirely in the
/// orchestrator. We never invent a finer confidence from an unreliable signal.
const double _kTopCandidateConfidence = 0.9;

/// On-device ML Kit implementation of [HandwritingRecognizer].
///
/// Construct with an injected [DigitalInkRecognizer] (defaults to the Arabic
/// model) so unit tests can supply a fake without a device. The pure
/// [inkFromStrokes] and [resultFromCandidates] helpers carry all the
/// device-independent logic and are unit-tested directly.
class MlKitRecognizer implements HandwritingRecognizer {
  MlKitRecognizer({DigitalInkRecognizer? recognizer})
      : _recognizer =
            recognizer ?? DigitalInkRecognizer(languageCode: kArabicModelCode);

  final DigitalInkRecognizer _recognizer;

  @override
  Future<RecognitionResult> identify(
      List<List<List<double>>> letterStrokes) async {
    if (letterStrokes.isEmpty) {
      return const RecognitionResult();
    }
    try {
      final ink = inkFromStrokes(letterStrokes);
      final candidates = await _recognizer.recognize(ink);
      return resultFromCandidates(candidates);
    } catch (_) {
      // Recognition failed (model not present yet, platform error, …). Degrade to
      // "no opinion" so the geometric pass stands (D-04 / Pitfall 1) — never a
      // false rejection, never a thrown error into the scoring path.
      return const RecognitionResult();
    }
  }

  /// Releases the underlying recogniser's native resources.
  Future<void> close() => _recognizer.close();
}

/// Builds an ML Kit [Ink] from a whole captured letter (pure, device-independent).
///
/// Each child stroke (a list of `[x, y]` pairs) becomes one ML Kit [Stroke]; each
/// `[x, y]` pair becomes a [StrokePoint]. A monotonically increasing synthetic
/// timestamp `t` is supplied because the capture seam carries only coordinates —
/// ML Kit only needs a consistent ordering, not real wall-clock times. Malformed
/// points (fewer than two coordinates) are skipped defensively.
Ink inkFromStrokes(List<List<List<double>>> letterStrokes) {
  final ink = Ink();
  var t = 0;
  for (final stroke in letterStrokes) {
    final mlStroke = Stroke();
    for (final point in stroke) {
      if (point.length < 2) continue;
      mlStroke.points.add(StrokePoint(x: point[0], y: point[1], t: t));
      t++;
    }
    ink.strokes.add(mlStroke);
  }
  return ink;
}

/// Maps ML Kit's ordered candidate list to a [RecognitionResult] (pure).
///
/// ML Kit returns candidates best-first. We report the top candidate's text and a
/// fixed advisory confidence (see [_kTopCandidateConfidence] — the raw score is
/// unreliable). An empty list maps to a null candidate with confidence 0 so the
/// orchestrator degrades to "no opinion" (D-04 / Pitfall 1). This function makes
/// NO pass/fail decision.
RecognitionResult resultFromCandidates(List<RecognitionCandidate> candidates) {
  if (candidates.isEmpty) {
    return const RecognitionResult();
  }
  final top = candidates.first;
  if (top.text.isEmpty) {
    return const RecognitionResult();
  }
  return RecognitionResult(
    topCandidate: top.text,
    confidence: _kTopCandidateConfidence,
  );
}
