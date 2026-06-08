# Phase 4: Scoring Quality & Calibration - Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 14 (8 new, 6 modified)
**Analogs found:** 14 / 14 (every file has a close in-repo analog — Phase 4 is composition, not green-field)

> This phase composes existing pieces. Almost every primitive already exists in the
> codebase; the work is **wrapping `scoreStroke` in a letter-level orchestrator**,
> **moving thresholds to data**, **implementing the `HandwritingRecognizer` seam**,
> **extending the authoring screen for labeled capture**, and **standing up a
> fixture-driven calibration harness**. Match house style exactly — these analogs ARE
> the house style.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/core/scoring/letter_scorer.dart` (NEW) | service (pure-Dart scorer) | transform / request-response | `lib/core/scoring/geometric_stroke_scorer.dart` | exact (same dir, same purity, wraps it) |
| `lib/core/scoring/scoring_models.dart` (MODIFY) | model | transform | itself (extend `MistakeId`, add `LetterResult`) | exact |
| `lib/core/scoring/tolerances.dart` (NEW) | model / config | transform | threshold consts block in `geometric_stroke_scorer.dart` + `Tolerances.fromJson` shape of `StrokeSpec.fromJson` | role-match |
| `lib/models/letter.dart` (MODIFY) | model | transform | itself (`StrokeSpec` / `CommonMistake` / `AudioRef` nested-model pattern) | exact |
| `assets/curriculum/letters.json` (MODIFY) | config / data | — | the existing `alif` entry (signed-off, 3 mistakes) | exact |
| `lib/core/recognition/ml_kit_recognizer.dart` (NEW) | service (platform plugin) | event-driven / request-response | `lib/core/recognition/handwriting_recognizer.dart` (interface it implements) | exact (interface seam) |
| `lib/services/model_download_service.dart` (NEW) | service / provider | file-I/O + network (once) | `PracticeSessionController` (Riverpod async-load + best-effort try/catch) in `practice_providers.dart` | role-match |
| `lib/features/practice/widgets/stroke_canvas.dart` (MODIFY) | component | event-driven (capture) | itself (the `_completedStrokes.clear()` accumulation bug) | exact |
| `lib/features/practice/practice_screen.dart` (MODIFY) | controller (UI) | request-response | itself (`_onStrokeSubmitted` → scorer call) | exact |
| `lib/dev/authoring_screen.dart` (MODIFY) | component (dev seam) | file-I/O (export) | itself (extend with label selector) | exact |
| `lib/dev/authoring_export.dart` (MODIFY/REUSE) | utility (pure-Dart) | transform | itself (combined-bbox normalize) | exact |
| `test/core/scoring/letter_scorer_test.dart` (NEW) | test | — | `geometric_stroke_scorer_test.dart` + `mistake_mapping_test.dart` | exact |
| `test/core/scoring/calibration_harness_test.dart` (NEW) | test (harness) | batch | `geometric_stroke_scorer_test.dart` (fixture-driven group structure) | role-match |
| `test/core/scoring/calibration_fixtures/` (NEW) | test fixtures | — | `test/core/scoring/scoring_fixtures.dart` | role-match |

---

## Pattern Assignments

### `lib/core/scoring/letter_scorer.dart` (NEW — service, transform) — THE SPINE

**Analog:** `lib/core/scoring/geometric_stroke_scorer.dart` (the leaf it wraps) + `stroke_validation.dart` (dot/order contract to reuse).

**Imports pattern** — pure Dart, no `dart:ui`/Flutter (copy this exact header discipline from `scoring_models.dart:1` and `geometric_stroke_scorer.dart:1-5`):
```dart
import 'dart:math' as math;            // only if needed
import '../../models/letter.dart';
import '../recognition/handwriting_recognizer.dart';
import 'geometric_stroke_scorer.dart'; // delegate body strokes to scoreStroke
import 'scoring_models.dart';
import 'stroke_resampler.dart';
import 'stroke_validation.dart';        // reuse dot/order semantics — do NOT re-derive
```

**Core pattern — first-failing-predicate, returns a result object** (mirror `scoreStroke`, `geometric_stroke_scorer.dart:35-59`; the orchestrator is the same shape one level up):
```dart
// Source to replicate: geometric_stroke_scorer.dart:35-59
StrokeResult scoreStroke(List<List<double>> childStroke, StrokeSpec reference) {
  if (strokeLengthBelowThreshold(childStroke)) {
    return const StrokeResult(passed: false, mistakeId: MistakeId.tooShort);
  }
  final normalised = normalizeToUnitBox(resample(childStroke, _kResampleN));
  if (strokeDirectionInverted(normalised, reference)) {
    return const StrokeResult(passed: false, mistakeId: MistakeId.wrongDirection);
  }
  if (strokeCurvatureExceedsThreshold(normalised)) {
    return const StrokeResult(passed: false, mistakeId: MistakeId.tooCurved);
  }
  return const StrokeResult(passed: true);
}
```

**New orchestrator skeleton** (count → order → per-stroke → dot → ML Kit gate; partition body vs dot exactly as the validator does — see `stroke_validation.dart:121` `stroke.type == 'dot'` and `:234-248` "dots come after body strokes"):
```dart
LetterResult scoreLetter(List<List<List<double>>> childStrokes, Letter letter,
    {HandwritingRecognizer? recognizer}) {
  final body = letter.referenceStrokes.where((s) => s.type != 'dot').toList();
  final dots = letter.referenceStrokes.where((s) => s.type == 'dot').toList();
  // 1. COUNT — firm even when shape is lenient (Pitfall 4)
  if (childStrokes.length != letter.referenceStrokes.length) {
    return LetterResult.fail(MistakeId.wrongStrokeCount);
  }
  // 2. ORDER + per-stroke shape — delegate each body stroke to scoreStroke(...)
  //    parameterised by letter.tolerances (NOT the file-level consts).
  // 3. DOT predicate — count + RELATIVE position (normalise whole letter together;
  //    do NOT normalise a dot in isolation — Pitfall 2). This is the ب/ت/ث distinction.
  // 4. ML Kit identity gate — only AFTER a geometric PASS, advisory only (D-04).
  return LetterResult.pass();
}
```

**Normalization reuse — combined bbox (Pitfall 2):** do NOT normalise each stroke independently; normalise the whole letter together so the dot's position relative to the body survives. The exact combined-bbox math already exists in `authoring_export.dart:63-75` (`_combinedBounds`) and `:90-109` (`normalizeToStrokeSpecs`) — replicate that approach, not the per-stroke `normalizeToUnitBox`.

**Tolerances are read, never hardcoded:** `scoreStroke` currently closes over file-level consts (`_kResampleN` etc. at `geometric_stroke_scorer.dart:16-26`). Phase 4 threads `letter.tolerances` (numeric) into the predicates. Keep the doc-comment rationale (lines 11-26) alongside the JSON values.

---

### `lib/core/scoring/scoring_models.dart` (MODIFY — model)

**Analog:** itself. Extend the `MistakeId` enum keeping the **enum-name == `commonMistakes[].check` contract** documented at `scoring_models.dart:7-9`.

**Existing enum** (`scoring_models.dart:10-15`) — the comment that governs every new value:
```dart
// The enum value names intentionally mirror the authored commonMistakes[].check
// strings in letters.json — breaking one requires changing the other.
enum MistakeId {
  tooShort,        // check: "strokeLengthBelowThreshold"
  wrongDirection,  // check: "strokeDirectionInverted"
  tooCurved,       // check: "strokeCurvatureExceedsThreshold"
  fallback,
}
```

**Add (each needs an authored `commonMistakes[].check` + `feedback` in letters.json AND an l10n string):**
```dart
  wrongStrokeCount,    // check: "strokeCountMismatch"
  wrongStrokeOrder,    // check: "strokeOrderWrong"
  dotMisplaced,        // check: "dotPositionWrong" / "dotCountWrong"
  wrongLetterIdentity, // check: "letterIdentityMismatch"  (ML Kit gate, D-04)
```

**Add `LetterResult`** mirroring the `StrokeResult` value-class shape (`scoring_models.dart:17-25`): a `bool passed` + nullable `MistakeId? mistakeId`, `const` constructor. Add `.fail(id)` / `.pass()` factories for the orchestrator's readability.

**Wire into 3 downstream switches** when you add enum values (Dart exhaustiveness will force you):
1. `feedbackForMistake` const map — `geometric_stroke_scorer.dart:69-73`.
2. `_feedbackString` switch — `practice_screen.dart:1117-1132`.
3. The `mistake_mapping_test.dart` assertions (see test section).

---

### `lib/core/scoring/tolerances.dart` (NEW — model/config)

**Analog:** the threshold-consts block in `geometric_stroke_scorer.dart:11-26` (the values move here) + `StrokeSpec.fromJson` (`letter.dart:55-70`) for the `fromJson` parsing idiom.

**Behavior-preserving anchor (LOCKED — A5):** the `normal` preset MUST equal today's constants so the data refactor doesn't shift alif:
```dart
// from geometric_stroke_scorer.dart:16,21,26
const int _kMinRawPoints = 10;     // → normal.minRawPoints
const int _kResampleN = 32;        // → normal.resampleN
const double _kMaxCurvature = 0.25;// → normal.maxCurvature
```

**Shape (D-03 leading hypothesis — preset + optional numeric overrides):** `Tolerances` class with named `_presets` map (`loose`/`normal`/`strict`) and a `fromJson` that reads `preset` then applies `overrides`. Keep it pure Dart. Preserve each const's doc-comment rationale alongside the value.

---

### `lib/models/letter.dart` (MODIFY — model)

**Analog:** itself — the nested-model pattern is established by `StrokeSpec` / `CommonMistake` / `AudioRef`, each a `const`-constructor class with a `fromJson` factory, parsed in `Letter.fromJson` (`letter.dart:133-154`).

**`Letter` gains a `tolerances` field** following the `audio` precedent exactly — `audio` is nullable and parsed defensively (`letter.dart:117`, `:136`, `:152`):
```dart
// pattern from letter.dart:117 + :136 + :152 (AudioRef precedent)
final AudioRef? audio;
// ...
final audioJson = json['audio'] as Map<String, dynamic>?;
// ...
audio: audioJson != null ? AudioRef.fromJson(audioJson) : null,
```
Add `final Tolerances? tolerances;` parsed the same way (nullable → letters without a block fall back to `normal`). This keeps existing Phase-2 entries parsing — same backward-compat instinct as `StrokeSpec.type`'s `?? 'line'` default (`letter.dart:64-66`).

---

### `assets/curriculum/letters.json` (MODIFY — config/data)

**Analog:** the existing `alif` entry — the ONLY signed-off letter (`signedOff: true`, 1 stroke, 3 mistakes). baa/taa/thaa are empty placeholders today (`strokes: 0`, `mistakes: 0`, `signedOff: false`) — verified across all 28 letters; only alif is authored.

**Two changes:**
1. **Author baa/taa/thaa** (D-01 gate) — `referenceStrokes` (body line + dot, exported from the extended authoring screen), `commonMistakes` (the mother's voice, incl. the new count/order/dot checks), flip `signedOff: false → true` ONLY after her sign-off. `mistakesStatus: "placeholder" → "authored"`.
2. **Add `tolerances`** per letter (D-03). Shape to replicate (from RESEARCH §Code Examples):
```jsonc
"commonMistakes": [
  { "id": "wrong_stroke_count", "check": "strokeCountMismatch",
    "feedback": "Baa is two parts — the boat, then one dot underneath." },
  { "id": "dot_wrong", "check": "dotPositionWrong",
    "feedback": "Baa's dot goes under the boat, not on top." }
],
"tolerances": { "preset": "normal", "overrides": { "maxCurvature": 0.30 } },
"signedOff": false
```
**Contract:** every `check` string above MUST equal a `MistakeId` enum value's documented check-name (see scoring_models). The load-time validator `validateReferenceStrokes` (`stroke_validation.dart:213`) already guards the strokes — extend coverage to baa/taa/thaa + the `tolerances` block (V5 input validation).

---

### `lib/core/recognition/ml_kit_recognizer.dart` (NEW — service, platform plugin)

**Analog:** `lib/core/recognition/handwriting_recognizer.dart` (the entire interface it implements — only 11 lines):
```dart
// Source: handwriting_recognizer.dart:1-11 (implement this verbatim seam)
abstract interface class HandwritingRecognizer {
  Future<RecognitionResult> identify(List<List<double>> strokePoints);
}
class RecognitionResult {
  final String? topCandidate;
  final double confidence;
  const RecognitionResult({this.topCandidate, this.confidence = 0.0});
}
```

**Core pattern (D-04 advisory gate, never co-judge):** build an ML Kit `Ink` from the accumulated strokes, call `DigitalInkRecognizer.recognize`, map the top `RecognitionCandidate{text, score}` → `RecognitionResult`. The orchestrator (not this class) decides: reject ONLY when confidently a *different* letter; a low confidence is **ignored** (Pitfall 1 — don't gate the pass on `candidates.first.score`).

**Note the interface seam mismatch the planner must resolve:** the current `identify(List<List<double>> strokePoints)` signature takes ONE stroke's points, but a whole letter (baa) is multi-stroke. Plan to widen the seam to `List<List<List<double>>>` (whole letter) or build the `Ink` from accumulated strokes upstream — flag as a Claude's-discretion interface decision.

**Add to pubspec:** `google_mlkit_digital_ink_recognition: ^0.14.2` (verify version at plan time per STACK.md). Confirm `minSdkVersion ≥ 21`.

---

### `lib/services/model_download_service.dart` (NEW — service/provider, D-05)

**Analog:** `PracticeSessionController` in `practice_providers.dart` — the project's Riverpod async-service idiom. Replicate three things from it:

1. **`@riverpod` annotation + `part 'x.g.dart'`** codegen pattern (`practice_providers.dart:14,20,90-91`):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'model_download_service.g.dart';
@riverpod
class ModelDownloadService extends _$ModelDownloadService { ... }
```
2. **Best-effort try/catch — a failure must never hard-block the child** (`practice_providers.dart:148-157` records mastery but celebrates regardless). Mirror this for the model fetch: on download failure, surface a calm "getting ready" state, never an error/hard-block (D-05).
3. **Prime-then-update-after-async-load** (`practice_providers.dart:97-103,107-123`): `build()` returns an immediate default (`isReady: false`), kicks off the background fetch, updates state when cached.

**New concerns not in the analog:** `path_provider` for the model dir + `DigitalInkRecognizerModelManager.isModelDownloaded` check before any `recognize`. Background fetch on first launch (D-05), fully offline after.

---

### `lib/features/practice/widgets/stroke_canvas.dart` (MODIFY — component, capture) — STRUCTURAL TRAP

**Analog:** itself. This is the single largest structural item (RESEARCH Pitfall 1). Today it **discards prior strokes on every pointer-down** and forwards exactly one stroke:
```dart
// Source: stroke_canvas.dart:88-96 — the accumulation bug
void _onDown(PointerDownEvent event) {
  if (!_accept(event.kind)) return;
  final Offset local = _localPos(event.position);
  setState(() {
    _completedStrokes.clear();        // ⚠ wipes prior strokes — no multi-stroke letter survives
    _activePoints = <Offset>[local];
  });
}
// Source: stroke_canvas.dart:115-126 — forwards ONE stroke, then clears
void _commitStroke() {
  ...
  _completedStrokes..clear()..add(active);   // ⚠ single-stroke only
  widget.onStrokeSubmitted(List<Offset>.unmodifiable(active));
}
```
**Change:** accumulate completed strokes into a whole-letter `List<List<Offset>>` (do NOT `.clear()` on each down), and add a **letter-complete signal** (count-reached vs explicit "Done" — Open Q1, planner decides). Keep the in-memory-only / never-logged discipline (the SECURITY header at `stroke_canvas.dart:14-18` is binding — T-01-05). The painter already supports multi-stroke (`_completedStrokes` is a list; `_buildScaledPath` at `:226-245` already lifts pen between strokes for "baa body + dot").

---

### `lib/features/practice/practice_screen.dart` (MODIFY — controller/UI)

**Analog:** itself. Today it scores ONE stroke against `referenceStrokes.first`:
```dart
// Source: practice_screen.dart:222-225 — hardcodes .first (single-stroke assumption)
onStrokeSubmitted: (List<Offset> pts) =>
    letter.referenceStrokes.isEmpty
        ? Future<void>.value()
        : onStrokeSubmitted(pts, letter.referenceStrokes.first),
// Source: practice_screen.dart:77-93 — the score call to convert
final StrokeResult result = scoreStroke(childStroke, referenceStroke);
await ref.read(...).onStrokeResult(result);
```
**Change:** call `scoreLetter(accumulatedStrokes, letter)` once after the letter-complete signal instead of `scoreStroke(..., referenceStrokes.first)`. Keep the Offset→`List<List<double>>` conversion idiom (`:81-84`) and the **SECURITY guard** (raw points stay local, only the result enters the controller — `:88-93`). Preserve the `_kThinkBeat` UX beat (`:417-424`).

**Add `_feedbackString` cases** for the 4 new `MistakeId`s (`practice_screen.dart:1117-1132`) — every new case maps to an l10n string, never a generic fallback (Pitfall 7). Mirror the existing authored-string pattern exactly:
```dart
case MistakeId.tooShort:
  return l10n?.practiceFeedbackTooShort ?? 'Your alif needs to be taller — ...';
```

**Per-stroke vs whole-letter feedback (Open Q2):** keep per-stroke shape feedback immediate, but count/order/identity are whole-letter verdicts surfaced after the last stroke. Planner specifies the `PracticeSessionController` state-machine change — note `onStrokeResult` (`practice_providers.dart:141-174`) currently resets the streak on any miss.

---

### `lib/dev/authoring_screen.dart` + `authoring_export.dart` (MODIFY — dev seam, D-02)

**Analog:** themselves. The capture+tag+normalize+export plumbing is exactly the labeled-sample-capture base. Reuse:

- **Capture surface** — `_CaptureSurface` Listener (`authoring_screen.dart:250-284`): converts global→local, samples points, captures ALL pointers (fine for an internal tool). In-memory-only (SECURITY header `:11-14`).
- **Combined-bbox normalize** — `normalizeToStrokeSpecs` / `_combinedBounds` (`authoring_export.dart:63-109`): the SAME whole-letter normalization the orchestrator's dot-position check needs (Pitfall 2). Pure Dart, already unit-testable.
- **Per-stroke tagging table** — `_TagAndExportPanel` (`authoring_screen.dart:324-418`): the dropdown pattern for `_types`/`_directions` (`:31-38`).

**Extend with a LABEL SELECTOR** for the failure taxonomy: `good`, `wrong_order`, `wrong_direction`, `wrong_count`, `scribble`, `wrong_letter`, `taa_when_shown_baa` (D-01). Export labeled coordinate sets as fixture files (not the `referenceStrokes` fragment). Keep it behind the existing `/dev/authoring` route (`app_router.dart:59-62`) + `kDebugMode` — NEVER child-facing (T-02.1-07). Only labeled fixture coordinates (test data) are written; nothing transmitted (T-01-05).

---

### `test/core/scoring/letter_scorer_test.dart` (NEW — test)

**Analog:** `geometric_stroke_scorer_test.dart` (group/test structure, inline reference builder, latency assert) + `mistake_mapping_test.dart` (inline `Letter` builder, authored-string assertions). Replicate the group structure:
```dart
// Source: geometric_stroke_scorer_test.dart:30-62 — group-per-category, expect(passed)+expect(mistakeId)
group('GeometricStrokeScorer — alif failure cases', () {
  test('tooShort → passed false, mistakeId == MistakeId.tooShort', () {
    final result = scoreStroke(tooShort, alifRefStroke());
    expect(result.passed, isFalse);
    expect(result.mistakeId, equals(MistakeId.tooShort));
  });
});
```
**Build for baa:** inline `Letter`/`StrokeSpec` builders matching the letters.json baa entry (mirror `mistake_mapping_test.dart:19-68`). Cover SC#1 (wrong count, wrong order, taa-when-shown-baa dot), SC#2 via a **mocktail fake `HandwritingRecognizer`** (no real ML Kit in unit tests), and the D-04 no-override rule (a good geometric pass + a wrong ML Kit candidate still passes). Add a **whole-letter latency assert** mirroring `geometric_stroke_scorer_test.dart:64-76` (< 50 ms / sub-300 ms budget). Add `mocktail: ^1.0.5` (STACK.md).

---

### `test/core/scoring/calibration_harness_test.dart` + `calibration_fixtures/` (NEW — harness + fixtures)

**Analog:** `scoring_fixtures.dart` (the synthetic-fixture file shape) + `geometric_stroke_scorer_test.dart` (fixture-driven group runner).

**Fixture shape to replicate** (`scoring_fixtures.dart:11-47`): named `List<List<double>>` point lists with a doc-comment stating the expected verdict:
```dart
// Source: scoring_fixtures.dart:9-14
/// A straight vertical stroke, top→bottom, full height.
final List<List<double>> cleanAlif = List<List<double>>.generate(
  21, (i) => [50.0, i * 10.0],
);
```
**Calibration fixtures differ:** real-tablet captured (NOT synthetic — emulator/mouse rejected for tolerance-setting, Pitfall 3), multi-stroke (`List<List<List<double>>>`), grouped per letter per label category, each carrying its label so the harness can compute a confusion table. File format + location are Claude's-discretion (CONTEXT). The harness runs the REAL `scoreLetter` over every labeled fixture and asserts per-letter FP/FN (NOT a Python re-implementation — A3). Fixtures become permanent regression tests (SC#4): `good` keeps passing, every named common mistake stays rejected.

> **Known gotcha (MEMORY):** golden tests can fail locally from font rendering, not regressions — but the scoring/calibration tests here are pure-Dart numeric, not goldens, so this does not apply to them.

---

## Shared Patterns

### Predicate-name == `commonMistakes[].check` contract (THE central cross-cutting rule)
**Source:** `scoring_models.dart:7-15` (enum + comment), `geometric_stroke_scorer.dart:68-82` (`feedbackForMistake` map), `letter.dart:73-89` (`CommonMistake`).
**Apply to:** every new failure category (count, order, dot, identity).
```dart
// The mapping that binds enum ↔ data ↔ predicate function name:
const checkNames = {
  MistakeId.tooShort: 'strokeLengthBelowThreshold',
  MistakeId.wrongDirection: 'strokeDirectionInverted',
  MistakeId.tooCurved: 'strokeCurvatureExceedsThreshold',
};
// For each MistakeId added: (1) enum value, (2) check string in letters.json,
// (3) named predicate function (or orchestrator branch), (4) authored feedback,
// (5) l10n string, (6) entry in this map.
```

### Pure-Dart discipline (no `dart:ui`, no Flutter in core/scoring)
**Source:** `scoring_models.dart:1` ("Pure Dart, no dart:ui, no Flutter imports"), `stroke_resampler.dart:3`, `authoring_export.dart:6`.
**Apply to:** `letter_scorer.dart`, `tolerances.dart` — so the calibration harness runs them headless over fixtures (no device, no Python bridge).

### In-memory-only stroke discipline (child-safety, T-01-05 / T-03-01)
**Source:** SECURITY headers in `stroke_canvas.dart:14-18`, `practice_screen.dart:22-24`, `practice_providers.dart:5-12`, `authoring_screen.dart:11-14`.
**Apply to:** the modified canvas (accumulation must not persist/log points), the model-download service, and the labeled-capture mode (only fixture coordinates as test data; nothing transmitted; never printed).

### Authored feedback only — never a generic message (Pitfall 7 / PLAT-03)
**Source:** `geometric_stroke_scorer.dart:68-82` + `practice_screen.dart:1117-1132` (`_feedbackString`).
**Apply to:** every new `MistakeId`. No failure path may return `MistakeId.fallback` for a real letter; the mother authors the copy (her voice). Design-kit rules: coral not red, no emoji, Western numerals, no `letterSpacing` on Arabic.

### Load-time curriculum validation (V5 input validation)
**Source:** `validateReferenceStrokes` / `validateStroke` (`stroke_validation.dart:83,213`) — returns violation strings, never throws.
**Apply to:** baa/taa/thaa strokes + the new `tolerances` block (reject malformed/out-of-range). The dot/order semantics here (`:121` dot = 1 point + `tap`; `:223-248` order 1..N, dots last) are the contract the orchestrator REUSES rather than re-derives.

### Best-effort async, never hard-block the child
**Source:** `practice_providers.dart:148-157` (records mastery but celebrates regardless of DB failure).
**Apply to:** `model_download_service.dart` — a fetch failure shows a calm "getting ready" state (D-05), never an error or hard-block.

---

## No Analog Found

None. Every Phase 4 file has a close in-repo analog. The two items with the *weakest* analogs (still role-matches) are:

| File | Role | Data Flow | Note |
|------|------|-----------|------|
| `lib/services/model_download_service.dart` | service/provider | file-I/O + network | No existing service touches network or `path_provider` (the app is fully on-device today). Riverpod-shape analog is `PracticeSessionController`; the network/filesystem specifics come from STACK.md + the ML Kit plugin docs, not from existing code. |
| `test/core/scoring/calibration_harness_test.dart` | test/harness | batch | No existing test is a confusion-table batch runner; closest is the fixture-driven group structure in `geometric_stroke_scorer_test.dart`. The FP/FN reporting logic is new (but pure-Dart over the real scorer — no Python). |

---

## Metadata

**Analog search scope:** `lib/core/scoring/`, `lib/core/recognition/`, `lib/services/`, `lib/models/`, `lib/features/practice/`, `lib/dev/`, `lib/providers/`, `lib/router/`, `assets/curriculum/`, `test/core/scoring/`.
**Files scanned:** 13 source/test files read in full + `letters.json` (all 28 entries summarized) + router dev-route section.
**Pattern extraction date:** 2026-06-08
**Cross-reference:** This map builds on `04-RESEARCH.md` (which already characterized every file with exact paths/line numbers) and `04-CONTEXT.md` decisions D-01…D-06.
