/// Pure Dart, no dart:ui, no Flutter imports.
///
/// THE SPINE (Plan 04-02; PER-FORM + multi-criteria in Plan 17-03) — the
/// whole-letter scoring orchestrator.
///
/// `scoreLetter` wraps the per-stroke leaf `scoreStroke`
/// (geometric_stroke_scorer.dart) to evaluate a multi-stroke letter end to end
/// against the reference for the ASKED positional [form] (`resolveReferenceStrokes`,
/// the ONE shared resolver — Pitfall 7). It emits a structured [LetterScore]:
/// FIVE per-criterion results plus the weakest (lowest-score) one — the coaching
/// input D-B requires — while `passed`/`mistakeId` keep their Phase-4 semantics.
///
/// The five criteria are the OWNER-CONFIRMED D-C amendment of 2026-07-05
/// (kinematics DESCOPED — capture has no timestamps; position folded into the
/// firm dot check; strokeCount is the fifth; ADR-017 records it):
///   1. strokeCount (FIRM) — same number of strokes as the reference.
///   2. strokeOrder (FIRM) — the body/dot draw sequence matches.
///   3. shape (SOFT) — the aggregate of every body stroke's `scoreStroke` shape
///                     criterion (worst zone / min score wins).
///   4. direction (SOFT) — the aggregate of every body stroke's direction
///                     criterion.
///   5. dot (FIRM, identity-bearing) — dot count + RELATIVE position (above/below
///                     the body) after WHOLE-letter combined-bbox normalisation,
///                     so baa-dot-below vs taa-dots-above survives (Pitfall 2/3).
/// COUNT/ORDER/DOT stay FIRM (categorical certainlyWrong / 0.0); only shape and
/// direction are soft. `passed` is false iff any FIRM criterion fails OR a soft
/// criterion is certainly-wrong; `mistakeId` is the first failing criterion in
/// the existing section order (verdict parity with Phase 4). An OPTIONAL,
/// ADVISORY-ONLY ML Kit identity gate (D-04) may still REJECT an otherwise-good
/// geometric pass on CONFIDENT disagreement (never rescue; weak evidence ignored,
/// Pitfall 1).
///
/// SECURITY (T-04-03 / T-01-05 / T-17-06): child points live only in local
/// variables here; nothing is printed, logged, or persisted. Only the derived
/// [LetterScore] — verdict + `{criterion, zone, score}` scalars, never a
/// coordinate — leaves this function.
library;

import 'dart:math' as math;

import '../../models/letter.dart';
import '../recognition/handwriting_recognizer.dart';
import 'geometric_stroke_scorer.dart';
import 'reference_resolution.dart';
import 'scoring_models.dart';
import 'shape_match.dart';
import 'tolerances.dart';

/// Confidence at or above which an ML Kit candidate is trusted enough to reject
/// a different-letter identity (D-04). Below this the candidate is advisory-only
/// and NEVER overrides a geometric pass (Pitfall 1).
const double _kIdentityConfidenceFloor = 0.5;

/// A child stroke with this many points or fewer is treated as a dot/tap rather
/// than a body stroke when matching the draw-order sequence. A deliberate body
/// line always carries far more samples than a single tap.
const int _kDotPointCeiling = 3;

/// Scores a whole captured letter against [letter]'s authored reference for the
/// asked positional [form], returning the structured [LetterScore].
///
/// [childStrokes] is the per-letter capture: a list of strokes, each a list of
/// `[x, y]` pixel-coordinate pairs in capture order. [form], when non-null,
/// selects the per-form reference + tolerances via `resolveReferenceStrokes` /
/// `resolveTolerances` (the ONE shared resolver — Pitfall 7); a null/absent form
/// (or an authored-empty per-form list) falls back to the letter's base
/// reference, preserving Phase-4 behavior for the practice path. [recognizer],
/// when supplied, applies the advisory-only ML Kit identity gate AFTER a
/// geometric pass (D-04).
///
/// The returned [LetterScore] `passed` is true when count, order, every body
/// stroke's shape/direction, and the dot predicate all hold (and the identity
/// gate, if present, does not confidently disagree); `mistakeId` is the first
/// failing criterion in the existing section order. [LetterScore.criteria] and
/// [LetterScore.weakest] carry the structured coaching input (D-B).
///
/// [tolerances], when supplied, OVERRIDES the letter's own (and per-form) block
/// — the seam through which the practice flow's per-rep ramp preset (D-18/D-19,
/// Plan 06-04) reaches the scorer. Resolution order: override →
/// contextualForms[form].tolerances → letter.tolerances → normal.
Future<LetterScore> scoreLetter(
  List<List<List<double>>> childStrokes,
  Letter letter, {
  String? form,
  HandwritingRecognizer? recognizer,
  Tolerances? tolerances,
}) async {
  // ── PER-FORM RESOLUTION (Pitfall 7 — the one shared resolver) ───────────────
  final reference = [...resolveReferenceStrokes(letter, form)]
    ..sort((a, b) => a.order.compareTo(b.order));
  final resolvedTolerances = resolveTolerances(letter, form, tolerances);

  // ── 1. strokeCount criterion (FIRM) ─────────────────────────────────────────
  // Firm regardless of how lenient the shape tolerance is (Pitfall 4): a baa is
  // two parts; one stroke (or three) is the wrong letter shape, full stop. A
  // count mismatch short-circuits — only the strokeCount criterion is meaningful
  // (the others can't be aligned to the reference by index).
  if (childStrokes.length != reference.length) {
    const count = CriterionResult(
      criterion: 'strokeCount',
      zone: ShapeZone.certainlyWrong,
      score: 0.0,
    );
    return const LetterScore(
      passed: false,
      mistakeId: MistakeId.wrongStrokeCount,
      criteria: [count],
      weakest: count,
    );
  }

  // ── 2. strokeOrder criterion (FIRM) ─────────────────────────────────────────
  // The reference draw sequence is body strokes first, then dots last (the
  // validator's check 5b). Classify each child stroke as a dot (a tap — very few
  // points) or a body stroke and require the SAME sequence as the reference. A
  // child who taps the dot before drawing the boat fails here.
  // Classify child strokes as dot/body by RELATIVE spatial extent — a stylus dot
  // TAP emits many sample points (not a single point), so a point-count rule
  // misfires and a real dot is mistaken for a body stroke (→ wrongStrokeOrder →
  // "noDot"). A dot is spatially tiny regardless of how many points it carries.
  final childIsDot = _classifyChildDots(childStrokes);
  for (var i = 0; i < reference.length; i++) {
    final refIsDot = reference[i].type == 'dot';
    if (refIsDot != childIsDot[i]) {
      const count = CriterionResult(
        criterion: 'strokeCount',
        zone: ShapeZone.certainlyCorrect,
        score: 1.0,
      );
      const order = CriterionResult(
        criterion: 'strokeOrder',
        zone: ShapeZone.certainlyWrong,
        score: 0.0,
      );
      return const LetterScore(
        passed: false,
        mistakeId: MistakeId.wrongStrokeOrder,
        criteria: [count, order],
        weakest: order,
      );
    }
  }

  // Count + order are firm-passed from here on.
  const countCrit = CriterionResult(
    criterion: 'strokeCount',
    zone: ShapeZone.certainlyCorrect,
    score: 1.0,
  );
  const orderCrit = CriterionResult(
    criterion: 'strokeOrder',
    zone: ShapeZone.certainlyCorrect,
    score: 1.0,
  );

  // ── 3 + 4. SHAPE + DIRECTION criteria (SOFT — aggregated over body strokes) ──
  // Delegate each body stroke to the leaf `scoreStroke` (threaded with the
  // resolved tolerances, SC#4) and aggregate its shape + direction criteria:
  // the WORST zone / MIN score wins (one certainly-wrong body stroke makes the
  // whole letter certainly-wrong for that axis). Dots are not shape/direction
  // scored (a tap has no curve/direction). The first failing body stroke's
  // mistakeId is remembered for verdict parity (scoreStroke already orders
  // direction-then-shape within a stroke).
  var shapeCrit = const CriterionResult(
    criterion: 'shape',
    zone: ShapeZone.certainlyCorrect,
    score: 1.0,
  );
  var directionCrit = const CriterionResult(
    criterion: 'direction',
    zone: ShapeZone.certainlyCorrect,
    score: 1.0,
  );
  MistakeId? bodyMistake;
  for (var i = 0; i < reference.length; i++) {
    if (reference[i].type == 'dot') continue;
    final result =
        scoreStroke(childStrokes[i], reference[i], resolvedTolerances);
    final s = _pickCriterion(result.criteria, 'shape');
    final d = _pickCriterion(result.criteria, 'direction');
    if (s != null) shapeCrit = _worst(shapeCrit, s);
    if (d != null) directionCrit = _worst(directionCrit, d);
    if (!result.passed) {
      bodyMistake ??= result.mistakeId ?? MistakeId.fallback;
      // The firm tooShort floor short-circuits before geometry → empty criteria.
      // Fold it into the shape criterion as certainly-wrong so the aggregate
      // reflects the failure (the mistakeId stays tooShort).
      if (result.criteria.isEmpty) {
        shapeCrit = _worst(
          shapeCrit,
          const CriterionResult(
            criterion: 'shape',
            zone: ShapeZone.certainlyWrong,
            score: 0.0,
          ),
        );
      }
    }
  }

  // ── 5. DOT criterion (FIRM, identity-bearing — Pitfall 3) ───────────────────
  // Normalise the WHOLE letter together (combined bbox) so the dot's position
  // RELATIVE to the body survives normalisation (Pitfall 2). A dot on the wrong
  // side (or a missing/extra dot) is categorically wrong — certainlyWrong / 0.0,
  // never fuzzy. A letter with no dots reports a trivially-satisfied dot criterion.
  final dotMistake = _checkDots(childStrokes, reference);
  final dotCrit = dotMistake != null
      ? const CriterionResult(
          criterion: 'dot',
          zone: ShapeZone.certainlyWrong,
          score: 0.0,
        )
      : const CriterionResult(
          criterion: 'dot',
          zone: ShapeZone.certainlyCorrect,
          score: 1.0,
        );

  final criteria = <CriterionResult>[
    countCrit,
    orderCrit,
    shapeCrit,
    directionCrit,
    dotCrit,
  ];

  // Verdict: first failing criterion in the existing section order. Body strokes
  // (direction-then-shape, already resolved by scoreStroke) precede the dot
  // section, matching Phase-4 precedence.
  MistakeId? mistake = bodyMistake ?? dotMistake;

  // ── IDENTITY (advisory-only ML Kit gate — D-04) ─────────────────────────────
  // Only consulted AFTER a full geometric pass, and only able to REJECT (never
  // rescue). A confidently-different candidate fails as wrongLetterIdentity; a
  // low-confidence or matching candidate leaves the geometric pass intact.
  if (mistake == null && recognizer != null) {
    mistake = await _identityGate(childStrokes, letter, recognizer);
  }

  return LetterScore(
    passed: mistake == null,
    mistakeId: mistake,
    criteria: criteria,
    weakest: _weakest(criteria),
  );
}

/// The first criterion in [criteria] whose `criterion` field equals [name], or
/// null when absent (a stroke that short-circuited before geometry carries none).
CriterionResult? _pickCriterion(List<CriterionResult> criteria, String name) {
  for (final c in criteria) {
    if (c.criterion == name) return c;
  }
  return null;
}

/// The worse of two same-axis criteria: the lower score (a certainly-wrong body
/// stroke drags the letter-level aggregate down). Score and zone are derived
/// from the same distance, so the lower score carries the worse zone.
CriterionResult _worst(CriterionResult a, CriterionResult b) =>
    b.score < a.score ? b : a;

/// The minimum-score criterion in [criteria] — the coaching target (D-B).
CriterionResult _weakest(List<CriterionResult> criteria) {
  var w = criteria.first;
  for (final c in criteria) {
    if (c.score < w.score) w = c;
  }
  return w;
}

/// Classify each child stroke as a dot (true) or a body stroke (false) by RELATIVE
/// spatial extent. A dot TAP is spatially tiny even when the stylus emits many
/// sample points; a body line spans most of the letter. So a stroke is a dot when
/// its bounding-box diagonal is small relative to the largest stroke's — OR when it
/// is a literal 1–3 point tap (the synthetic/clean case). This fixes the on-device
/// bug where a pen-drawn dot (many points, tiny extent) was mistaken for a body
/// stroke and failed stroke-order as "noDot".
List<bool> _classifyChildDots(List<List<List<double>>> strokes) {
  final diags = [for (final s in strokes) _strokeDiagonal(s)];
  final maxDiag = diags.fold<double>(0.0, (m, d) => d > m ? d : m);
  return [
    for (var i = 0; i < strokes.length; i++)
      strokes[i].length <= _kDotPointCeiling ||
          (maxDiag > 0 && diags[i] < 0.3 * maxDiag),
  ];
}

/// Bounding-box diagonal of a stroke (0 for empty/degenerate).
double _strokeDiagonal(List<List<double>> stroke) {
  if (stroke.isEmpty) return 0.0;
  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (final p in stroke) {
    minX = math.min(minX, p[0]);
    maxX = math.max(maxX, p[0]);
    minY = math.min(minY, p[1]);
    maxY = math.max(maxY, p[1]);
  }
  final w = maxX - minX, h = maxY - minY;
  return math.sqrt(w * w + h * h);
}

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
  // Pass the whole multi-stroke letter to the recognizer seam (widened in Plan
  // 04-03): ML Kit recognises a letter from all its strokes together — flattening
  // would collapse the body line and dot into one stroke and degrade recognition.
  final result = await recognizer.identify(childStrokes);

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
