/// Pure Dart, no dart:ui, no Flutter imports.
///
/// THE SPINE (Plan 04-02) — the whole-letter scoring orchestrator.
///
/// `scoreLetter` wraps the per-stroke leaf `scoreStroke`
/// (geometric_stroke_scorer.dart) to evaluate a multi-stroke letter end to end:
///   1. COUNT  — child must draw the same number of strokes as the reference.
///   2. ORDER  — the body/dot draw sequence must match the reference's.
///   3. SHAPE  — each body stroke is delegated to `scoreStroke`, threaded with
///               the letter's per-letter `Tolerances` (SC#4 — data, not consts).
///   4. DOT    — dot count + RELATIVE position (above/below the body) checked
///               after normalising the WHOLE letter together (combined bbox), so
///               a baa-dot-below vs taa-dots-above distinction survives
///               (Pitfall 2 — the ب/ت/ث distinction).
///   5. IDENTITY — an OPTIONAL, ADVISORY-ONLY ML Kit gate (D-04): rejects only a
///               CONFIDENTLY-different letter on an otherwise-good geometric
///               pass; weak/low-confidence evidence is ignored, never overriding
///               a pass (Pitfall 1).
///
/// First-failing-predicate, returns a [LetterResult] — the same shape as
/// `scoreStroke`'s [StrokeResult], one level up.
///
/// SECURITY (T-04-03 / T-01-05): child points live only in local variables here;
/// nothing is printed, logged, or persisted. Only the derived [LetterResult]
/// leaves this function.

import 'dart:math' as math;

import '../../models/letter.dart';
import '../recognition/handwriting_recognizer.dart';
import 'geometric_stroke_scorer.dart';
import 'scoring_models.dart';
import 'tolerances.dart';

/// Confidence at or above which an ML Kit candidate is trusted enough to reject
/// a different-letter identity (D-04). Below this the candidate is advisory-only
/// and NEVER overrides a geometric pass (Pitfall 1).
const double _kIdentityConfidenceFloor = 0.5;

/// A child stroke with this many points or fewer is treated as a dot/tap rather
/// than a body stroke when matching the draw-order sequence. A deliberate body
/// line always carries far more samples than a single tap.
const int _kDotPointCeiling = 3;

/// Scores a whole captured letter against [letter]'s authored reference.
///
/// [childStrokes] is the per-letter capture: a list of strokes, each a list of
/// `[x, y]` pixel-coordinate pairs in capture order. [recognizer], when supplied,
/// applies the advisory-only ML Kit identity gate AFTER a geometric pass (D-04).
///
/// Returns [LetterResult.pass] when count, order, every body stroke's shape, and
/// the dot predicate all hold (and the identity gate, if present, does not
/// confidently disagree); otherwise the first failing [MistakeId].
Future<LetterResult> scoreLetter(
  List<List<List<double>>> childStrokes,
  Letter letter, {
  HandwritingRecognizer? recognizer,
}) async {
  final reference = [...letter.referenceStrokes]
    ..sort((a, b) => a.order.compareTo(b.order));
  final tolerances = letter.tolerances ?? Tolerances.normal;

  // ── 1. COUNT ───────────────────────────────────────────────────────────────
  // Firm regardless of how lenient the shape tolerance is (Pitfall 4): a baa is
  // two parts; one stroke (or three) is the wrong letter shape, full stop.
  if (childStrokes.length != reference.length) {
    return const LetterResult.fail(MistakeId.wrongStrokeCount);
  }

  // ── 2. ORDER ─────────────────────────────────────────────────────────────��─
  // The reference draw sequence is body strokes first, then dots last (the
  // validator's check 5b). Classify each child stroke as a dot (a tap — very few
  // points) or a body stroke and require the SAME sequence as the reference. A
  // child who taps the dot before drawing the boat fails here.
  for (var i = 0; i < reference.length; i++) {
    final refIsDot = reference[i].type == 'dot';
    final childIsDot = _looksLikeDot(childStrokes[i]);
    if (refIsDot != childIsDot) {
      return const LetterResult.fail(MistakeId.wrongStrokeOrder);
    }
  }

  // ── 3. SHAPE (per body stroke) ───────────────────────────────────────────────
  // Delegate each body stroke to the leaf scorer, threaded with the letter's
  // tolerances (SC#4). Dots are not shape-scored (a tap has no direction/curve).
  for (var i = 0; i < reference.length; i++) {
    if (reference[i].type == 'dot') continue;
    final result = scoreStroke(childStrokes[i], reference[i], tolerances);
    if (!result.passed) {
      return LetterResult.fail(result.mistakeId ?? MistakeId.fallback);
    }
  }

  // ── 4. DOT (count + relative position) ───────────────────────────────────────
  // Normalise the WHOLE letter together (combined bbox) so the dot's position
  // RELATIVE to the body survives normalisation (Pitfall 2). Then check the dot
  // sits on the correct side of the body (below for baa, above for taa/thaa).
  final dotResult = _checkDots(childStrokes, reference);
  if (dotResult != null) {
    return LetterResult.fail(dotResult);
  }

  // ── 5. IDENTITY (advisory-only ML Kit gate — D-04) ───────────────────────────
  // Only consulted AFTER a full geometric pass, and only able to REJECT (never
  // rescue). A confidently-different candidate fails as wrongLetterIdentity; a
  // low-confidence or matching candidate leaves the geometric pass intact.
  if (recognizer != null) {
    final identity = await _identityGate(childStrokes, letter, recognizer);
    if (identity != null) {
      return LetterResult.fail(identity);
    }
  }

  return const LetterResult.pass();
}

/// True if [stroke] is a single tap (a dot) rather than a drawn body stroke.
bool _looksLikeDot(List<List<double>> stroke) =>
    stroke.length <= _kDotPointCeiling;

/// Checks every reference dot against the child's matching stroke: the child must
/// also have drawn a dot there (count) and it must sit on the SAME side of the
/// body as the reference dot (relative position). Returns [MistakeId.dotMisplaced]
/// on the first mismatch, or null when all dots are correct.
///
/// Whole-letter combined-bbox normalisation (mirroring authoring_export's
/// `_combinedBounds`) keeps the dot's position relative to the body intact — a
/// per-stroke normalisation would erase exactly the up/down signal that
/// distinguishes baa (dot below) from taa (dots above).
MistakeId? _checkDots(
  List<List<List<double>>> childStrokes,
  List<StrokeSpec> reference,
) {
  final dotIndices = <int>[
    for (var i = 0; i < reference.length; i++)
      if (reference[i].type == 'dot') i,
  ];
  if (dotIndices.isEmpty) return null;

  // Body centroid (combined-bbox space) anchors "above" vs "below".
  final childBounds = _combinedBounds(childStrokes);
  final bodyIndices = <int>[
    for (var i = 0; i < reference.length; i++)
      if (reference[i].type != 'dot') i,
  ];
  final childBodyY = _centroidY(
    [for (final i in bodyIndices) ...childStrokes[i]],
    childBounds,
  );

  // The reference's own body/dot geometry tells us the EXPECTED side.
  final refBodyY = _centroidY(
    [for (final i in bodyIndices) ...reference[i].points],
    _refBounds(reference),
  );

  for (final i in dotIndices) {
    final refDotY = _centroidY(reference[i].points, _refBounds(reference));
    final childDotY = _centroidY(childStrokes[i], childBounds);

    // y increases DOWNWARD. "below the body" => dotY > bodyY.
    final refDotBelow = refDotY > refBodyY;
    final childDotBelow = childDotY > childBodyY;
    if (refDotBelow != childDotBelow) {
      return MistakeId.dotMisplaced;
    }
  }
  return null;
}

/// Mean y of [points] expressed in 0..1 against [bounds] (combined-bbox space).
double _centroidY(List<List<double>> points, _Bounds bounds) {
  if (points.isEmpty) return 0.5;
  final h = bounds.maxY - bounds.minY;
  if (h <= 0) return 0.5;
  var sum = 0.0;
  for (final p in points) {
    sum += (p[1] - bounds.minY) / h;
  }
  return sum / points.length;
}

/// Combined bounding box over every point of every child stroke (Pitfall 2 —
/// the same whole-letter normalisation authoring_export uses).
_Bounds _combinedBounds(List<List<List<double>>> strokes) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (final stroke in strokes) {
    for (final p in stroke) {
      minX = math.min(minX, p[0]);
      maxX = math.max(maxX, p[0]);
      minY = math.min(minY, p[1]);
      maxY = math.max(maxY, p[1]);
    }
  }
  return _Bounds(minX, minY, maxX, maxY);
}

/// Combined bounding box over every reference stroke point.
_Bounds _refBounds(List<StrokeSpec> reference) =>
    _combinedBounds([for (final s in reference) s.points]);

/// Consults the ML Kit [recognizer] as an advisory-only identity gate (D-04).
///
/// Returns [MistakeId.wrongLetterIdentity] ONLY when the recognizer is confident
/// (>= [_kIdentityConfidenceFloor]) that the child wrote a DIFFERENT letter than
/// [letter]. A low-confidence verdict, a matching candidate, or no candidate is
/// ignored (returns null) so the geometric pass stands (Pitfall 1).
Future<MistakeId?> _identityGate(
  List<List<List<double>>> childStrokes,
  Letter letter,
  HandwritingRecognizer recognizer,
) async {
  // Flatten the whole letter into one point list for the recognizer seam.
  final flat = <List<double>>[for (final stroke in childStrokes) ...stroke];
  final result = await recognizer.identify(flat);

  final candidate = result.topCandidate;
  if (candidate == null) return null; // no opinion → trust geometry
  if (result.confidence < _kIdentityConfidenceFloor) return null; // weak → ignore
  if (candidate == letter.char) return null; // agrees → no conflict

  return MistakeId.wrongLetterIdentity;
}

/// Mutable bounding box helper (pure value type, no Flutter).
class _Bounds {
  final double minX, minY, maxX, maxY;
  const _Bounds(this.minX, this.minY, this.maxX, this.maxY);
}
