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

  /// The human-assigned verdict — one of [kCalibrationLabels].
  final String label;

  /// The whole-letter capture: per stroke → per point → `[x, y]` (pixel space;
  /// `scoreLetter` normalizes internally).
  final List<List<List<double>>> strokes;

  const LabeledSample({
    required this.letterId,
    required this.label,
    required this.strokes,
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

/// All labeled samples across all letters, grouped by letter id. Plan 06 adds
/// real-tablet captures for baa/taa/thaa/alif here without touching the harness.
final Map<String, List<LabeledSample>> calibrationSamplesByLetter =
    <String, List<LabeledSample>>{
  'baa': baaSamples,
};
