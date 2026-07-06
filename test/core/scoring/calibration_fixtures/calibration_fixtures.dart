/// Labeled multi-stroke calibration fixtures for the confusion-table harness.
///
/// THE FIXTURE FORMAT (D-02, Plan 04-05) — each [LabeledSample] is one captured
/// attempt at one letter, carrying:
///   * [letterId]  — which curriculum letter was shown (e.g. "baa").
///   * [label]     — the failure taxonomy verdict the human assigned at capture
///                   time (`good`, or a named common mistake — see
///                   [kCalibrationLabels]).
///   * [strokes]   — the whole-letter capture as `List<List<List<double>>>`
///                   (per stroke → per point → `[x, y]`), the exact type the
///                   real `scoreLetter` takes as its `childStrokes` argument.
///
/// The harness (calibration_harness_test.dart) runs the REAL `scoreLetter` over
/// every sample and builds a per-letter false-positive / false-negative table.
/// A `good` sample the scorer REJECTS is a false NEGATIVE; a named-bad sample the
/// scorer PASSES is a false POSITIVE.
///
/// ⚠ SYNTHETIC SEED ⚠
/// Every fixture below is HAND-CRAFTED, not captured from a real tablet. Per
/// RESEARCH §Calibration Methodology (Pitfall 3), synthetic / emulator strokes
/// are too smooth to SET tolerances against — they would tune the scorer too
/// strict. They are used here ONLY to make the harness green and pin the
/// regression contract (known-good accepted, known-bad rejected). The
/// real-tablet child samples (exported from the authoring screen's labeled
/// capture mode, Task 1) REPLACE this seed in Plan 06; the harness and format do
/// not change — only the fixture data does.
///
/// Pure Dart — no Flutter imports — so the harness runs headless.
library;

/// The calibration failure taxonomy (mirrors `kCalibrationLabels` in
/// lib/dev/authoring_screen.dart — the label selector offers exactly these).
/// `good` is the only "accept" label; everything else is a named common mistake
/// the scorer must keep rejecting.
const List<String> kCalibrationLabels = <String>[
  'good',
  'wrong_order',
  'wrong_direction',
  'wrong_count',
  'scribble',
  'wrong_letter',
  'taa_when_shown_baa',
];

/// One labeled whole-letter capture.
class LabeledSample {
  /// Which letter was shown (matches a `Letter.id`).
  final String letterId;

  /// The human-assigned verdict — one of [kCalibrationLabels] (base seed) or one
  /// of the per-form synthetic labels in [kPerFormLabels] (Plan 17-09).
  final String label;

  /// The whole-letter capture: per stroke → per point → `[x, y]` (pixel space;
  /// `scoreLetter` normalizes internally).
  final List<List<List<double>>> strokes;

  /// The ASKED positional form this sample is offered FOR — one of
  /// `isolated` / `initial` / `medial` / `final`, or null for the base/isolated
  /// reference. Threaded verbatim into `scoreLetter(strokes, letter, form:)` by
  /// the harness so the sample is scored against the SAME per-form reference the
  /// scorer resolves (`resolveReferenceStrokes`, Plan 17-03). A null [form]
  /// preserves every existing base-seed sample unchanged (base referenceStrokes).
  ///
  /// The F5 form-confusion trap uses this field to offer the ISOLATED bowl for
  /// the `medial` / `final` slot — the cell the harness asserts to zero.
  final String? form;

  const LabeledSample({
    required this.letterId,
    required this.label,
    required this.strokes,
    this.form,
  });

  /// True for the single "accept" label — used by the harness to decide whether
  /// a rejection is a false NEGATIVE (good rejected) or a correct rejection.
  bool get isGood => label == 'good';
}

// ── baa fixtures (the D-01 calibration letter) ───────────────────────────────
//
// baa = a right→left body line ("the boat") + one dot BELOW it. The shapes below
// reuse the exact synthetic captures already proven in letter_scorer_test.dart
// so the expected verdicts are grounded in the live contract, not re-guessed.

/// A good-faith baa body: a right→left line with a modest downward bow, 20 pts.
/// (Identical shape to letter_scorer_test.dart's `goodBaa()[0]`.)
List<List<double>> _baaBody() => List<List<double>>.generate(
      20,
      (i) => [180.0 - i * 8, 100.0 + (i < 10 ? i * 2.0 : (19 - i) * 2.0)],
    );

/// The dot BELOW the body (the baa identity).
List<List<double>> _dotBelow() => const [
      [90.0, 170.0],
    ];

/// The dot ABOVE the body (the taa pattern — wrong for baa).
List<List<double>> _dotAbove() => const [
      [90.0, 40.0],
    ];

/// The synthetic baa seed — one sample per relevant taxonomy label.
///
/// Coverage encodes each NAMED common mistake for baa as a regression fixture:
///   * good               — boat + dot below, drawn cleanly      → must PASS
///   * wrong_count         — only the boat (no dot)                → wrongStrokeCount
///   * wrong_order         — dot tapped BEFORE the boat            → wrongStrokeOrder
///   * taa_when_shown_baa  — right boat, dot ABOVE (the ب↔ت slip) → dotMisplaced
final List<LabeledSample> baaSamples = <LabeledSample>[
  // ── good (must be ACCEPTED) ──
  LabeledSample(
    letterId: 'baa',
    label: 'good',
    strokes: [_baaBody(), _dotBelow()],
  ),

  // ── wrong_count: the boat alone, child forgot the dot ──
  LabeledSample(
    letterId: 'baa',
    label: 'wrong_count',
    strokes: [_baaBody()],
  ),

  // ── wrong_order: dot tapped first, then the boat ──
  LabeledSample(
    letterId: 'baa',
    label: 'wrong_order',
    strokes: [_dotBelow(), _baaBody()],
  ),

  // ── taa_when_shown_baa: right boat, but the dot sits ABOVE (taa, not baa) ──
  LabeledSample(
    letterId: 'baa',
    label: 'taa_when_shown_baa',
    strokes: [_baaBody(), _dotAbove()],
  ),
];

// ── PER-FORM fixtures (Plan 17-09 — CONTEXT increment 5, D-D/D-E) ─────────────
//
// The base seed above pins the Phase-4 regression contract (form: null → base
// reference). This section extends the harness to the PER-FORM dimension: baa's
// four positional forms (isolated / initial / medial / final) plus taa (the D-E
// generalization proof — SAME bowl skeleton, dots differ), each scored against
// the REAL authored `contextualForms` reference the scorer resolves.
//
// ⚠ STILL SYNTHETIC (Pitfall 4). Every sample below is perturbed FROM the
// authored `assets/curriculum/letters.json` per-form points using the
// shape_match_test.dart technique (midpoint-densify to clear the raw-point
// floor + a deterministic ±~0.012 child-hand wobble + a collinear flat body) —
// never an invented shape. They are a REGRESSION SEED only: they pin
// good→PASS / named-bad→expected-MistakeId and the F5 form-confusion cell at
// zero. The PRODUCTION soft-band thresholds come from the owner's-mother-
// labelled real-child captures (D-D), a deferred production gate recorded in
// 17-10's HUMAN-UAT — NOT from these numbers.

/// The per-form synthetic labels (harness-internal; distinct from the
/// authoring-screen [kCalibrationLabels]). Each maps to an expected `MistakeId`
/// in the harness `_expectedRejection` table.
const List<String> kPerFormLabels = <String>[
  'good', // the form's own reference, shaky-but-correct → must PASS
  'flatBody', // collinear body → tooCurved (shape certainly-wrong)
  'dotAbove', // the one dot placed ABOVE the body → dotMisplaced
  'missingDot', // body only, dot forgotten → wrongStrokeCount
  'wrongDotCount', // taa with a single dot (2 strokes, expects 3) → wrongStrokeCount
  'formConfusion', // the F5 trap: isolated bowl offered for medial/final → tooCurved
];

// ── REAL authored per-form reference points (letters.json baa.contextualForms
//    + taa.contextualForms.isolated, verified this session) ──────────────────
// Exported so the harness Letter builders and these fixtures share ONE source of
// the authored points (never two copies that could drift). Bodies sweep
// rightToLeft; dots are single-point taps.

/// baa isolated "bowl" (the boat) — 12 pts.
const List<List<double>> kBaaIsolatedBowl = <List<double>>[
  [0.608, 0.447], [0.619, 0.486], [0.620, 0.524], [0.594, 0.552],
  [0.551, 0.565], [0.511, 0.569], [0.474, 0.570], [0.436, 0.566],
  [0.407, 0.559], [0.386, 0.530], [0.381, 0.498], [0.382, 0.460],
];

/// baa initial "head" (low hump at the start of a word) — 9 pts.
const List<List<double>> kBaaInitialHead = <List<double>>[
  [0.55, 0.455], [0.565, 0.494], [0.571, 0.53], [0.555, 0.564],
  [0.512, 0.579], [0.471, 0.583], [0.407, 0.581], [0.359, 0.579],
  [0.313, 0.57],
];

/// baa medial "tooth" (a little tooth between two letters) — 8 pts.
const List<List<double>> kBaaMedialTooth = <List<double>>[
  [0.628, 0.571], [0.573, 0.578], [0.518, 0.564], [0.506, 0.490],
  [0.480, 0.569], [0.433, 0.575], [0.388, 0.574], [0.342, 0.570],
];

/// baa final "bowl_tail" (the full bowl at the end of a word) — 11 pts.
const List<List<double>> kBaaFinalBowlTail = <List<double>>[
  [0.702, 0.584], [0.653, 0.572], [0.605, 0.567], [0.560, 0.556],
  [0.573, 0.493], [0.528, 0.560], [0.481, 0.577], [0.425, 0.580],
  [0.382, 0.575], [0.343, 0.548], [0.316, 0.498],
];

/// The one dot BELOW each baa form's body (the baa identity, per form).
const List<double> kBaaIsolatedDot = [0.498, 0.644];
const List<double> kBaaInitialDot = [0.467, 0.672];
const List<double> kBaaMedialDot = [0.495, 0.841];
const List<double> kBaaFinalDot = [0.447, 0.643];

/// taa isolated "bowl" — BYTE-IDENTICAL to [kBaaIsolatedBowl] in letters.json:
/// this IS the D-E point (taa shares baa's skeleton; only the dots differ).
const List<List<double>> kTaaIsolatedBowl = kBaaIsolatedBowl;

/// taa's TWO dots, ABOVE the body (the taa identity vs baa's one-dot-below).
const List<double> kTaaDot1 = [0.44, 0.327];
const List<double> kTaaDot2 = [0.56, 0.327];

// ── Perturbation helpers (shape_match_test.dart technique — build FROM the
//    authored reference, never invent) ─────────────────────────────────────

/// Midpoint-densifies an authored polyline so a child-capture fixture clears the
/// firm raw-point floor (minRawPoints 10) without changing the curve's shape
/// (arc-length resampling makes the two polylines geometrically identical).
List<List<double>> _densify(List<List<double>> pts) => <List<double>>[
      for (var i = 0; i < pts.length - 1; i++) ...[
        pts[i],
        [(pts[i][0] + pts[i + 1][0]) / 2, (pts[i][1] + pts[i + 1][1]) / 2],
      ],
      pts.last,
    ];

/// The deterministic ±~0.012 wobble of a real-but-unsteady child hand.
List<List<double>> _shake(List<List<double>> pts) => <List<double>>[
      for (var i = 0; i < pts.length; i++)
        [
          pts[i][0] + (i.isEven ? 0.012 : -0.010),
          pts[i][1] + (i % 3 == 0 ? -0.011 : 0.009),
        ],
    ];

/// A shaky-but-correct child body for [body]: densified (clears the raw-point
/// floor) then wobbled. Passes the shape criterion against its own reference.
List<List<double>> _goodBody(List<List<double>> body) => _shake(_densify(body));

/// A collinear FLAT line spanning [body]'s x-range at its mean y — the "it's a
/// line, not a boat" wrong shape. Still sweeps rightToLeft (maxX→minX) so the
/// DIRECTION criterion passes and SHAPE is the sole failure (→ tooCurved). 16
/// points clears the raw-point floor.
List<List<double>> _flatBody(List<List<double>> body) {
  var minX = double.infinity, maxX = double.negativeInfinity, sumY = 0.0;
  for (final p in body) {
    if (p[0] < minX) minX = p[0];
    if (p[0] > maxX) maxX = p[0];
    sumY += p[1];
  }
  final y = sumY / body.length;
  const n = 16;
  return [for (var i = 0; i < n; i++) [maxX - i * (maxX - minX) / (n - 1), y]];
}

/// A dot placed clearly ABOVE any baa body (y 0.30 < every body's top ≈ 0.45),
/// keeping the authored x — the taa-slip that makes baa's dot land on the wrong
/// side (→ dotMisplaced).
List<List<double>> _dotAboveBody(List<double> authoredDot) => [
      [authoredDot[0], 0.30],
    ];

/// The four labelled samples for one baa positional [form]: a good-faith
/// attempt plus the three named-bad body/dot slips, all grounded in the form's
/// own authored [body] + [dotBelow].
List<LabeledSample> _baaFormSamples(
  String form,
  List<List<double>> body,
  List<double> dotBelow,
) =>
    <LabeledSample>[
      // good — the form's own reference, shaky-but-correct → must PASS.
      LabeledSample(
        letterId: 'baa',
        label: 'good',
        form: form,
        strokes: [
          _goodBody(body),
          [dotBelow],
        ],
      ),
      // flatBody — a collinear body → shape certainly-wrong → tooCurved.
      LabeledSample(
        letterId: 'baa',
        label: 'flatBody',
        form: form,
        strokes: [
          _flatBody(body),
          [dotBelow],
        ],
      ),
      // dotAbove — good body, the one dot placed ABOVE → dotMisplaced.
      LabeledSample(
        letterId: 'baa',
        label: 'dotAbove',
        form: form,
        strokes: [
          _goodBody(body),
          _dotAboveBody(dotBelow),
        ],
      ),
      // missingDot — the body alone, dot forgotten → wrongStrokeCount.
      LabeledSample(
        letterId: 'baa',
        label: 'missingDot',
        form: form,
        strokes: [
          _goodBody(body),
        ],
      ),
    ];

/// The per-form baa samples for all four positional forms.
final List<LabeledSample> baaInitialSamples =
    _baaFormSamples('initial', kBaaInitialHead, kBaaInitialDot);
final List<LabeledSample> baaMedialSamples =
    _baaFormSamples('medial', kBaaMedialTooth, kBaaMedialDot);
final List<LabeledSample> baaFinalSamples =
    _baaFormSamples('final', kBaaFinalBowlTail, kBaaFinalDot);
final List<LabeledSample> baaIsolatedFormSamples =
    _baaFormSamples('isolated', kBaaIsolatedBowl, kBaaIsolatedDot);

/// The F5 FORM-CONFUSION trap (the cell the harness asserts to ZERO): the
/// ISOLATED bowl strokes — a correct isolated baa — offered for the MEDIAL and
/// the FINAL slot. The dot stays correctly BELOW, so the DOT check passes and
/// the SHAPE criterion (a full bowl is not the little medial tooth / the final
/// bowl_tail) is the sole failure → tooCurved. This moves the F5 form-blind
/// verdict from the LLM eval into the Dart scorer, where D-A says it belongs.
final List<LabeledSample> baaFormConfusionSamples = <LabeledSample>[
  // isolated-bowl-for-medial: a full bowl where the little tooth belongs.
  LabeledSample(
    letterId: 'baa',
    label: 'formConfusion',
    form: 'medial',
    strokes: [
      _goodBody(kBaaIsolatedBowl),
      [kBaaIsolatedDot],
    ],
  ),
  // isolated-bowl-for-final: a plain isolated bowl offered for the final bowl_tail.
  LabeledSample(
    letterId: 'baa',
    label: 'formConfusion',
    form: 'final',
    strokes: [
      _goodBody(kBaaIsolatedBowl),
      [kBaaIsolatedDot],
    ],
  ),
];

/// taa (D-E proof): the isolated form — the SAME bowl skeleton as baa, but TWO
/// dots ABOVE instead of one dot below.
final List<LabeledSample> taaSamples = <LabeledSample>[
  // good — the bowl + both dots above → must PASS against the taa reference.
  LabeledSample(
    letterId: 'taa',
    label: 'good',
    form: 'isolated',
    strokes: [
      _goodBody(kTaaIsolatedBowl),
      [kTaaDot1],
      [kTaaDot2],
    ],
  ),
  // wrongDotCount — the bowl + a SINGLE dot (2 strokes where taa expects 3).
  // The scorer's FIRM strokeCount check fires first (a missing dot IS a
  // stroke-count mismatch), so the authored `dotCountWrong` slip surfaces as
  // MistakeId.wrongStrokeCount — the id the scorer deterministically emits.
  LabeledSample(
    letterId: 'taa',
    label: 'wrongDotCount',
    form: 'isolated',
    strokes: [
      _goodBody(kTaaIsolatedBowl),
      [kTaaDot1],
    ],
  ),
];

/// All labeled samples across all letters, grouped by letter id. The base baa
/// seed (form: null) pins the Phase-4 regression contract; the per-form groups
/// (Plan 17-09) add the letter × form dimension. Plan 06 adds real-tablet
/// captures here without touching the harness.
final Map<String, List<LabeledSample>> calibrationSamplesByLetter =
    <String, List<LabeledSample>>{
  'baa': <LabeledSample>[
    ...baaSamples, // the untouched Phase-4 base seed (form: null)
    ...baaIsolatedFormSamples,
    ...baaInitialSamples,
    ...baaMedialSamples,
    ...baaFinalSamples,
    ...baaFormConfusionSamples, // the F5 trap
  ],
  'taa': taaSamples,
};
