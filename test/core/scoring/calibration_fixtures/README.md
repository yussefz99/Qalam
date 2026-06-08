# Calibration fixtures — labeled child-handwriting samples (SC#4)

This directory holds **labeled multi-stroke handwriting samples** that the
[calibration harness](../calibration_harness_test.dart) runs the **real
`scoreLetter`** over to produce a per-letter false-positive / false-negative
confusion table. The fixtures double as **permanent regression tests**: once a
letter's tolerances are tuned, every `good` sample must keep passing and every
named common mistake must keep being rejected.

> **No Python re-implementation.** The harness scores fixtures with the actual
> `lib/core/scoring/letter_scorer.dart` (RESEARCH A3). There is no second copy of
> the scoring math to drift out of sync.

---

## Fixture format

Each sample is a `LabeledSample` (`calibration_fixtures.dart`):

```dart
LabeledSample(
  letterId: 'baa',          // which curriculum letter was shown (a Letter.id)
  label: 'good',            // the human-assigned verdict (see taxonomy below)
  strokes: [                // List<List<List<double>>> — the WHOLE letter
    [ [180.0, 100.0], ... ],//   stroke 1 (the body): per point → [x, y]
    [ [90.0, 170.0] ],      //   stroke 2 (the dot): a single tap
  ],
)
```

- **`strokes`** is the exact type `scoreLetter(childStrokes, letter)` consumes:
  per stroke → per point → `[x, y]`. Coordinates may be in any space — the scorer
  normalizes the whole letter together (combined bounding box) internally, so
  size and offset do not matter, but the **dot's position relative to the body
  does** (the ب↔ت distinction, Pitfall 2).
- A **dot** stroke is a single `[x, y]` tap (`<= 3` points); a **body** stroke is
  a many-point line.

### Label taxonomy

The `label` is one of `kCalibrationLabels` (identical to the authoring screen's
label selector):

| label                | meaning                                            | scorer must |
|----------------------|----------------------------------------------------|-------------|
| `good`               | a clean, correct attempt                           | **accept**  |
| `wrong_order`        | strokes drawn out of sequence (dot before body)    | reject      |
| `wrong_direction`    | a body stroke drawn the wrong way                  | reject      |
| `wrong_count`        | too few / too many strokes (e.g. boat, no dot)     | reject      |
| `scribble`           | not a letter at all                                | reject      |
| `wrong_letter`       | a different letter entirely                         | reject      |
| `taa_when_shown_baa` | right body, dot on the **wrong side** (the ب↔ت slip) | reject    |

`good` is the only **accept** label. Everything else is a named common mistake.

---

## Confusion table: false negatives vs false positives

The harness counts, per letter:

- **False NEGATIVE (FN)** — a `good` sample the scorer **rejected**. The child
  tried in good faith and was wrongly told they failed. *This is the costly one.*
- **False POSITIVE (FP)** — a named-bad sample the scorer **passed**. A real
  mistake slipped through.

The table is printed to the test console when the harness runs, e.g.:

```
=== Calibration confusion table (SC#4) ===
  baa: good=1 FN=0 | bad=3 FP=0
```

---

## Tuning priority — minimize FN for good-faith attempts

When the owner's mother tunes a letter's `tolerances` block in
`assets/curriculum/letters.json` (preset + overrides — no code change, SC#4), the
priority (RESEARCH §Calibration Methodology step 5) is:

1. **Lean encouraging — minimize FALSE NEGATIVES for `good` attempts.** A child
   who genuinely tried should rarely be told they failed (Pitfall 3 > Pitfall 4).
2. **Keep `count` / `order` / identity FIRM.** These are letter-*identity*
   verdicts, not motor-skill leniency — a baa with the dot on top is a different
   letter and must stay rejected.

The loop: run the harness → read the per-letter FN/FP table → adjust the JSON
tolerance → re-run → repeat.

---

## Adding real-tablet captures (Plan 06)

The current fixtures are a **synthetic seed** (hand-crafted, clearly marked in
`calibration_fixtures.dart`). Per RESEARCH (Pitfall 3), synthetic / emulator
strokes are too smooth to *set* tolerances against — they only pin the regression
contract and keep the harness green.

**Plan 06 replaces the seed with real samples** captured on a real Android tablet:

1. Open the dev authoring screen at **`/dev/authoring`** (debug builds only —
   never child-facing, T-02.1-07).
2. Set the **Letter id** and trace a real child's attempt.
3. Pick the matching **Label** from the selector and tap **Export labeled
   fixture**. The screen emits a `{ "letterId", "label", "strokes" }` JSON object
   (the same shape as `LabeledSample`), already combined-bbox normalized.
4. Paste each exported sample into `calibration_fixtures.dart` (target
   **~15–20 samples per letter per label** for a usable boundary).

The harness and this format do **not** change when real samples land — only the
fixture data does.
