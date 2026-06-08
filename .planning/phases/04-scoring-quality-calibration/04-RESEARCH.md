# Phase 4: Scoring Quality & Calibration - Research

**Researched:** 2026-06-08
**Domain:** On-device geometric handwriting scoring (Flutter/Dart, pure-Dart scorer) + ML Kit Digital Ink coarse identity gate + per-letter tolerance calibration against real child samples
**Confidence:** HIGH on existing-code characterization (read every file), HIGH on ML Kit API shape (STACK.md + pub.dev verified), MEDIUM on calibration methodology (synthesized — sample sizes are a recommendation, not a measured fact)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Calibrate **alif + the baa-family (baa ب, taa ت, thaa ث)**. The mother must author + sign off reference strokes and `commonMistakes` for baa/taa/thaa **inside Phase 4** (they are `signedOff: false` placeholders today). Treat authoring + sign-off as a gate, mirroring the alif sign-off pattern from Phase 02.1. Calibration must explicitly include "wrote taa when shown baa" (right body, wrong dot count) as a labeled failure category.
- **D-02 (OPEN RESEARCH DIRECTIVE — resolved below):** Final calibration-sample-collection method was deferred to research. Required outputs: capture-fidelity differences (emulator/mouse vs real-tablet finger vs real-tablet stylus), minimum viable sample sizes per letter per category, feasibility-ranked options, recommended protocol. Leading hypothesis to confirm or beat: real children on a real Android tablet, captured via an in-app tool extended from the Phase 02.1 authoring screen, labeled live by the mother. **Reject emulator/mouse data for setting tolerances** (it tunes the scorer too strict — Pitfall 3); emulator is fine only for deterministic unit tests. In-memory-only capture discipline (T-01-05) holds — only labeled fixture coordinates intended as test data are persisted; nothing transmitted.
- **D-03 (OPEN RESEARCH/PLANNER DECISION — analyzed below):** Exact tolerance-schema form deferred. LOCKED regardless of form: (1) per-letter; (2) data, not code — editable in bundled curriculum JSON, no recompile (SC#4); (3) teacher-legible. Leading hypothesis: named strictness presets (`loose`/`normal`/`strict`) expanding to numeric thresholds, plus optional per-letter numeric overrides. Researcher decides which knobs need tuning (candidates: max-curvature, min stroke length, direction strictness, shape-distance threshold, dot position/size tolerance).
- **D-04:** ML Kit is a **coarse safety net only.** It catches "wrote a completely different letter / scribble" (SC#2) and nothing finer. The **geometric scorer remains the sole judge** of shape, order, count, and dot quality. ML Kit rejects **only** when it is confidently a *different* letter; it **never overrides a good-faith correct geometric pass**. Co-judge model was explicitly declined (it would cause ب/ت/ث false rejections).
- **D-05:** ML Kit model download is a **background fetch on first launch** (right after install/onboarding). Cache the ~few-MB Arabic model. If the child reaches a practice screen before the model is cached, show a calm "getting ready" state (no error, no hard block). Fully offline after the one-time fetch. Lazy "download on first practice with a wait" was declined.
- **D-06:** Phase 3's D-15/D-16 stand. Phase 3 shipped the lenient first-cut scorer and left the `HandwritingRecognizer` seam unimplemented. Phase 4 owns the per-letter tuning + the ML Kit implementation + the model download.

### Claude's Discretion
- Shape-distance algorithm for whole-letter scoring (resampled point distance vs Procrustes/Fréchet) — planner/researcher choice; calibration tunes it regardless.
- Riverpod wiring for the letter-level scoring orchestrator above per-stroke `scoreStroke` (currently called once per stroke in `practice_screen.dart`).
- The labeled-fixture file format and where calibration fixtures live in the repo.
- ML Kit package selection/version (verify against `.planning/research/STACK.md` at plan time).

### Deferred Ideas (OUT OF SCOPE)
- Calibrating the remaining 24 letters + words → Phase 7 (full curriculum + sign-off). Phase 4 establishes the *method* on alif + baa-family; Phase 7 applies it.
- Gentle "show me again" auto-replay after repeated misses (Phase 3 D-05 nice-to-have) → optional UX polish.
- Updating design assets to drop the legacy star-counter/weekly-tally chrome → housekeeping.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| S1-05 (deepened) | Instant on-device feedback on shape AND stroke order; evaluates stroke count, order, direction, shape; names the specific fix from curriculum `commonMistakes`; < ~300 ms after stylus-up; fully offline; custom geometric scorer with ML Kit as **secondary letter-identity check only** | Existing `scoreStroke` does single-stroke shape/direction/length. Phase 4 adds the **letter-level orchestrator** (count → order → per-stroke → dot) plus the ML Kit identity gate. See §Existing Scorer Characterization, §ML Kit Identity Check, §Architecture Patterns. |
| PLAT-03 (deepened) | Not-points-chasing, on-brand; failures always map to authored named fixes, never a generic "try again" | The predicate-name == `commonMistakes[].check` contract must extend to the new count/order/dot predicates so every new failure category has authored feedback. See §Common Pitfalls (Pitfall 7), §Code Examples. |
</phase_requirements>

## Summary

Phase 4 is a **deepening + extension** phase, not a rebuild. The Phase 3 scorer (`scoreStroke`) is a working **single-stroke** evaluator: it runs three named predicates (length, direction, curvature) against one resampled+normalized stroke and returns the first failing `MistakeId`. Phase 4 must wrap it in a **letter-level orchestrator** that handles multi-stroke letters (stroke **count**, stroke **order**, a **dot/tap** predicate), move the three hardcoded threshold constants out of `geometric_stroke_scorer.dart` into **per-letter curriculum data** on the `Letter` model, implement the `MlKitRecognizer` against the existing `HandwritingRecognizer` seam as a coarse identity gate (D-04) with a one-time background model download (D-05), and calibrate per-letter false-negative/false-positive rates separately against **real-tablet child samples** captured by extending the Phase 02.1 authoring screen.

The single sharpest finding from reading the code: **the current capture surface (`StrokeCanvas`) discards prior strokes on every new pointer-down** (`_onDown` calls `_completedStrokes.clear()`) and forwards exactly one stroke per `onStrokeSubmitted`. `practice_screen.dart` then scores against `letter.referenceStrokes.first` only. There is **no multi-stroke accumulation anywhere today.** Making SC#1 real (reject wrong stroke *count* / *order* on baa = body + dot) therefore requires changing the capture→accumulate→orchestrate path, not just adding a predicate. This is the largest structural item in the phase and the planner should treat it as the spine.

The second sharp finding: the existing `stroke_validation.dart` (the Phase 02.1 "crown jewel" validator) **already encodes the dot/order semantics the orchestrator needs** — `type == "dot"` ⇒ exactly one point + direction `tap`; ORDER must be 1..N contiguous; **dots come after body strokes**. The orchestrator should reuse this contract rather than re-deriving it. And `normalizeToUnitBox` (the SC#3 size/offset-invariance mechanism) is already proven by the `smallCorrect` fixture passing — Phase 4 *verifies* it is sufficient and adds a multi-stroke-aware normalization decision (normalize each stroke independently vs the whole letter together).

**Primary recommendation:** Build a pure-Dart `LetterScorer.scoreLetter(List<List<List<double>>> childStrokes, Letter letter)` orchestrator above the existing per-stroke `scoreStroke`; extend `MistakeId` + the `commonMistakes[].check` contract with `wrongStrokeCount` / `wrongStrokeOrder` / `dotMisplaced` / `wrongLetterIdentity`; add a `tolerances` block to `Letter` driven by named presets in `letters.json` (D-03); implement `MlKitRecognizer` as an advisory identity gate (D-04) behind a model-download service (D-05); and stand up a **pure-Dart fixture-driven calibration harness** (Flutter test, not Python — see §Calibration) that runs the scorer over labeled real-tablet samples and reports per-letter FP/FN. Capture real-tablet samples by extending the existing dev authoring screen into a labeled-sample mode (D-02 hypothesis confirmed).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Per-stroke shape/direction/length scoring | Pure-Dart core (`lib/core/scoring`) | — | Already there (`scoreStroke`); fast, unit-testable, no Flutter deps. Stays the leaf. |
| Letter-level orchestration (count, order, dot) | Pure-Dart core (new `LetterScorer`) | — | Same purity discipline; sits above `scoreStroke`. Must be pure so the calibration harness runs it headless over fixtures. |
| ML Kit coarse identity gate | Device platform plugin (`lib/core/recognition`) | Pure-Dart orchestrator consults it | Recognition needs the native ML Kit plugin; the *gating decision* (advisory only, D-04) is policy that lives in/near the orchestrator. Keep the orchestrator pure by injecting the recognizer through the existing `HandwritingRecognizer` interface. |
| Per-letter tolerances | Curriculum data (`assets/curriculum/letters.json` → `Letter`) | Pure-Dart scorer reads them | SC#4 — data not code. Mother edits JSON; scorer is a pure reader. |
| Model download + cache | Device/service layer (Riverpod service) | Practice flow shows "getting ready" | Network + filesystem (path_provider) + lifecycle; not scoring logic. |
| Sample capture | Dev seam (extend `lib/dev/authoring_screen.dart`) | Pure-Dart export/normalize (`authoring_export.dart`) | Capture is a Flutter widget; normalization is already pure and reusable. |
| Calibration harness (run scorer over labeled samples, report FP/FN) | Pure-Dart test tooling (`test/` or `tool/`) | — | Pure scorer means the harness is a plain Dart/Flutter-test program — no device, no Python bridge needed. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `google_mlkit_digital_ink_recognition` | ^0.14.2 | On-device Arabic letter **identity** recognition (D-04 coarse gate) | Owner-validated (CLAUDE.md: ML Kit Digital Ink is DECIDED). Prescribed in STACK.md. Returns `List<RecognitionCandidate>{text, score}` only — exactly the coarse identity signal D-04 wants, nothing finer. [CITED: .planning/research/STACK.md] [VERIFIED: pub.dev v0.14.2, published ~4 months ago, Android minSdk 21] |
| `path_provider` | ^2.1.0 | Locate the downloaded ML Kit model + app dirs | Already prescribed in STACK.md; needed by the model-download service. [CITED: .planning/research/STACK.md] |
| `flutter_riverpod` / `riverpod_annotation` | ^3.3.1 / ^4.0.2 | DI for the model-download service + scorer orchestrator wiring | Project standard (Riverpod only — CLAUDE.md). Already in use (`practice_providers.g.dart`). [CITED: CLAUDE.md, STACK.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter_test` | SDK | Unit tests for the orchestrator + the calibration harness | Pure-Dart scorer + fixtures = headless test runs. Already the only test dep. |
| `mocktail` | ^1.0.5 | Mock the `HandwritingRecognizer` in orchestrator tests (no device ML Kit in unit tests) | STACK.md-recommended; no codegen. Inject a fake recognizer to test the D-04 gating policy deterministically. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Resampled-point distance for whole-letter shape | Procrustes / Fréchet / DTW | The existing scorer uses chord-perpendicular curvature + direction-sign, NOT a path-distance metric. Adding a true shape-distance metric (DTW over the resampled, normalized stroke vs reference) is a Claude's-discretion upgrade that gives a single tunable `shapeDistanceThreshold` knob — recommended as the cleanest tolerance lever, but calibration tunes whatever metric is chosen. Keep it pure-Dart and resampled-N-aware so it stays sub-300 ms. |
| Pure-Dart calibration harness | Python harness over exported fixtures | CLAUDE.md prefers Python for backend/tooling, BUT the scorer is **Dart** — a Python harness would have to re-implement the scorer (drift risk) or shell out. A `flutter test`-based harness runs the *real* scorer over fixtures with zero re-implementation. **Recommend Dart harness** here despite the Python preference, precisely because the thing being measured is Dart. (Python stays right for the Phase-7+ Cloud Functions tutor.) |
| Extending the dev authoring screen for capture | New standalone capture app | The authoring screen already has the exact Listener + normalize + export plumbing (`authoring_screen.dart` + `authoring_export.dart`), runs on a real tablet, and is a non-child-facing dev route. Reuse it (D-02 hypothesis confirmed). |

**Installation:**
```bash
flutter pub add google_mlkit_digital_ink_recognition
# path_provider, flutter_riverpod, riverpod_annotation, mocktail already present or in STACK.md
```
After adding, confirm `minSdkVersion` resolves to ≥ 21 (the plugin raises it; `android/app/build.gradle.kts` currently uses `flutter.minSdkVersion`). [VERIFIED: minSdk is `flutter.minSdkVersion` in build.gradle.kts — confirm the Flutter default meets 21 at plan time]

**Version verification:** `google_mlkit_digital_ink_recognition 0.14.2` confirmed current on pub.dev (published ~4 months before research date). STACK.md (2026-05-30) prescribes the same version. Re-run `flutter pub outdated` at plan time.

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `google_mlkit_digital_ink_recognition` | pub.dev | mature (Google-maintained `flutter-ml/google_ml_kit_flutter`) | high (official ML Kit Flutter family) | github.com/flutter-ml/google_ml_kit_flutter | n/a (Dart/pub, slopcheck is npm/PyPI/crates) | **Approved** — owner-validated (CLAUDE.md DECIDED), prescribed in STACK.md, official Google package |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*slopcheck targets npm/PyPI/crates and was unavailable; this is a pub.dev (Dart) package. Legitimacy is instead established by: (1) CLAUDE.md DECIDED + owner-validated; (2) STACK.md prescription with verified version; (3) it is part of the official Google `google_ml_kit_flutter` family. Planner does not need a human-verify checkpoint for this single, already-decided package.*

## Architecture Patterns

### System Architecture Diagram

```
  Child draws (stylus)
        │
        ▼
  StrokeCanvas (Listener + CustomPainter)         lib/features/practice/widgets/stroke_canvas.dart
   - filters PointerDeviceKind.stylus              ⚠ TODAY: clears prior strokes on pointer-down,
   - emits ONE completed stroke per pen-up            forwards ONE stroke. Phase 4 must accumulate.
        │
        ▼  (List<Offset> per stroke)  ── accumulate into List<List<Offset>> (whole letter)
        │
        ▼
  practice_screen._onStrokeSubmitted  ──▶  NEW: LetterScorer.scoreLetter(childStrokes, letter)
        │                                          lib/core/scoring/letter_scorer.dart  (pure Dart)
        │                                            │
        │        ┌───────────────────────────────────┼───────────────────────────────┐
        │        ▼                ▼                    ▼                ▼                ▼
        │   count check     order check         per-stroke scoreStroke()      dot/tap predicate
        │   (#strokes vs    (draw order vs      (existing — shape/dir/len      (position+count of
        │    referenceStrokes) referenceStrokes  per body stroke)               dots vs reference)
        │    .length)        order)                   │
        │        │                │                    │                │                │
        │        └────────────────┴──────── first failing MistakeId ───┴────────────────┘
        │                                  │ (geometric verdict)
        │                                  ▼
        │        ┌─── if geometric PASS ──▶ consult MlKitRecognizer.identify(ink)  (D-04 advisory)
        │        │                            lib/core/recognition/ml_kit_recognizer.dart
        │        │                            - builds Ink from accumulated strokes
        │        │                            - returns {topCandidate, confidence}
        │        │                            - reject ONLY if confidently a DIFFERENT letter
        │        ▼
        ▼   StrokeResult / LetterResult (passed + mistakeId)
        │   → feedbackForMistake(id, letter) → authored commonMistakes[].feedback (l10n)
        ▼
  PracticeSessionController.onStrokeResult  (unchanged state machine: pass→praise/celebrate, fail→showFix)

  ── Per-letter tolerances flow: letters.json → Letter.tolerances → LetterScorer (reads, never hardcodes)
  ── Model download (D-05): ModelDownloadService (Riverpod) fetches ar model on first launch; "getting ready" gate in practice flow
```

### Recommended Project Structure
```
lib/core/scoring/
├── geometric_stroke_scorer.dart   # EXISTING — per-stroke scoreStroke (thresholds move OUT to data)
├── letter_scorer.dart             # NEW — scoreLetter orchestrator (count/order/per-stroke/dot)
├── scoring_models.dart            # EXTEND — MistakeId gains count/order/dot/identity; add LetterResult
├── stroke_resampler.dart          # EXISTING — resample + normalizeToUnitBox (verify sufficiency)
├── stroke_validation.dart         # EXISTING — reuse dot/order contract in the orchestrator
└── tolerances.dart                # NEW — preset→numeric expansion (D-03)
lib/core/recognition/
├── handwriting_recognizer.dart    # EXISTING interface seam
└── ml_kit_recognizer.dart         # NEW — implements identify() via google_mlkit (D-04)
lib/services/
└── model_download_service.dart    # NEW — background ar-model fetch + isReady (D-05)
lib/models/letter.dart             # EXTEND — Letter gains `tolerances` field
assets/curriculum/letters.json     # EXTEND — baa/taa/thaa authored; per-letter tolerances added
lib/dev/authoring_screen.dart      # EXTEND — labeled-sample capture mode (D-02)
test/core/scoring/
├── letter_scorer_test.dart        # NEW — count/order/dot orchestration + named-fix mapping
├── calibration_fixtures/          # NEW — labeled real-tablet samples per letter per category
└── calibration_harness_test.dart  # NEW — runs scorer over fixtures, asserts per-letter FP/FN
```

### Pattern 1: Predicate-name == `commonMistakes[].check` contract (EXISTING — must extend)
**What:** Every failure category is a named predicate whose function name equals the `check` string in `letters.json`, so `feedbackForMistake` can map a `MistakeId` to authored copy. Breaking one requires updating the other.
**When to use:** Every new failure category Phase 4 adds (count, order, dot, identity).
**Example:**
```dart
// Source: lib/core/scoring/geometric_stroke_scorer.dart:68-82 (existing) + scoring_models.dart:10-15
enum MistakeId {
  tooShort,        // check: "strokeLengthBelowThreshold"
  wrongDirection,  // check: "strokeDirectionInverted"
  tooCurved,       // check: "strokeCurvatureExceedsThreshold"
  // NEW for Phase 4 — each needs an authored commonMistakes[].check + feedback:
  wrongStrokeCount,   // check: "strokeCountMismatch"
  wrongStrokeOrder,   // check: "strokeOrderWrong"
  dotMisplaced,       // check: "dotPositionWrong" / "dotCountWrong"
  wrongLetterIdentity,// check: "letterIdentityMismatch"  (ML Kit gate, D-04)
  fallback,
}
```

### Pattern 2: Pure-Dart orchestrator over the existing per-stroke leaf
**What:** `scoreLetter` is pure (no `dart:ui`, no Flutter), takes the accumulated child strokes + the `Letter`, runs the firm checks (count, then order) before delegating each body stroke to the existing `scoreStroke`, then the dot predicate, then consults the injected `HandwritingRecognizer` only on a geometric pass.
**When to use:** The spine of the phase.
**Example:**
```dart
// Pattern (to author in lib/core/scoring/letter_scorer.dart) — pure Dart
LetterResult scoreLetter(List<List<List<double>>> childStrokes, Letter letter,
    {HandwritingRecognizer? recognizer}) {
  final body = letter.referenceStrokes.where((s) => s.type != 'dot').toList();
  final dots = letter.referenceStrokes.where((s) => s.type == 'dot').toList();
  // 1. COUNT (firm — Pitfall 4 says order/count stay firm even when shape is lenient)
  if (childStrokes.length != letter.referenceStrokes.length) {
    return LetterResult.fail(MistakeId.wrongStrokeCount);
  }
  // 2. ORDER + per-stroke shape (delegate body strokes to existing scoreStroke)
  // 3. DOT predicate (count + position vs reference — the ب/ت/ث distinction)
  // 4. ML Kit identity gate (advisory — reject ONLY if confidently a different letter, D-04)
}
```

### Pattern 3: ML Kit as advisory gate, never a co-judge (D-04)
**What:** Build an `Ink` from the accumulated strokes, call `DigitalInkRecognizer.recognize`, and reject **only** when the top candidate is confidently a *different* letter than the lesson's. A correct geometric pass is never overridden; low ML Kit confidence is ignored (Pitfall 1).
**When to use:** SC#2 (scribble / wrong-letter). Only after the geometric verdict is a pass.
**Anti-pattern:** Gating the pass on `candidates.first.score` (Pitfall 1 — over-trusting ML Kit).

### Anti-Patterns to Avoid
- **Hardcoded thresholds in `.dart`:** the three constants in `geometric_stroke_scorer.dart` (`_kMinRawPoints`, `_kResampleN`, `_kMaxCurvature`) must move to per-letter data (SC#4 / Pitfall 6). Keep the doc-comment rationale alongside the JSON values.
- **One global tolerance for all letters:** Pitfall 4. Tolerances are per-`Letter`.
- **ML Kit as co-judge:** explicitly declined (D-04); causes ب/ت/ث false rejections.
- **Tuning on emulator/mouse strokes:** Pitfall 3 + owner's instinct + D-02 — too smooth, tunes the scorer too strict, rejects real kids. Emulator is for deterministic unit tests only.
- **Generic failure messages:** Pitfall 7 — every new failure category must map to authored `commonMistakes[].feedback`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Letter **identity** recognition | A bespoke Arabic shape classifier | `google_mlkit_digital_ink_recognition` (ar model) | On-device, owner-validated, offline after one download. Reinventing it is the whole reason ML Kit was chosen. |
| Stroke resampling + normalization | New normalization math | Existing `resample` + `normalizeToUnitBox` in `stroke_resampler.dart` | Already proven (the `smallCorrect` fixture passes — SC#3 mechanism exists). |
| Dot / order semantics | Re-deriving "dots come last, order is 1..N, dot = 1 point + tap" | Existing `stroke_validation.dart` contract | The Phase 02.1 validator already encodes exactly this; reuse it in the orchestrator. |
| Sample capture + normalize + export | A new capture app | Extend `authoring_screen.dart` + reuse `authoring_export.dart` | Same Listener capture, same normalization, real-tablet, dev-only route. |
| Running the scorer over labeled samples | A Python re-implementation of the Dart scorer | A `flutter test` calibration harness over fixtures | The scorer is Dart; re-implementing in Python guarantees drift. Measure the real scorer. |

**Key insight:** Nearly every primitive this phase needs already exists in the codebase. Phase 4 is composition + calibration + the ML Kit plug-in, not green-field algorithm work.

## Runtime State Inventory

> This is partly a schema-extension/calibration phase. Inventory of state beyond source files:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **Drift `LetterMastery` table** (Phase 3, `lib/data/drift_progress_repository.dart`) records mastery by `letterId` + `cleanReps`. Tuning tolerances does **not** invalidate stored mastery (it is a derived pass count, not a stroke recording). | None — tolerance changes are forward-only; past mastery rows stay valid. |
| Live service config | **ML Kit `ar` model** is downloaded-and-cached on device (not in git, not bundled). Currently **not downloaded at all** (no `MlKitRecognizer`, package not in pubspec yet). | Phase 4 adds the download service (D-05). First-launch fetch; verify `isModelDownloaded` before recognition. |
| OS-registered state | None — no OS-level registrations involve scoring. | None — verified: no task scheduler / launchd / pm2 usage in repo. |
| Secrets/env vars | None — scoring is fully on-device, no API keys (tutor is v2, never client-side per CLAUDE.md). | None. |
| Build artifacts | **`tools/` has stale `candidate_paths.json` / `authoring_hints.json`** from the abandoned outline-extraction approach (superseded by Phase 02.1 authoring — see `reference_path.dart` doc). The new baa/taa/thaa strokes come from in-app authoring, NOT from these files. | None for scoring; do not resurrect the outline extractor. Calibration fixtures are NEW files. |

## Common Pitfalls

### Pitfall 1: Multi-stroke capture gap (the structural trap)
**What goes wrong:** A planner adds a count/order predicate but the capture surface still forwards one stroke at a time and clears the previous (`StrokeCanvas._onDown` → `_completedStrokes.clear()`; `_commitStroke` forwards a single stroke). The orchestrator never receives a whole letter, so count/order checks have nothing to bite on — SC#1 silently can't work on baa.
**Why it happens:** Phase 3 only ever scored alif (one stroke), so single-stroke capture was sufficient and `practice_screen.dart` hardcodes `letter.referenceStrokes.first`.
**How to avoid:** Make the capture→accumulate path explicit. Accumulate `List<Offset>` strokes into a whole-letter `List<List<Offset>>` (with a "letter complete" signal — e.g. stroke count reached, or an explicit "done" affordance), then call `scoreLetter` once. Decide the completion trigger deliberately (count-reached vs explicit button) and document it.
**Warning signs:** `referenceStrokes.first` still in the score path; no `List<List<Offset>>` anywhere; baa "passes" with one stroke.

### Pitfall 2: Over-normalization hides real errors (SC#3 tension)
**What goes wrong:** `normalizeToUnitBox` scales each stroke into a unit box. Normalizing a **dot** (single point or tiny cluster) or normalizing each stroke *independently* can erase the very position information that distinguishes baa (dot below) from taa (two dots above) — making the dot-count/position distinction impossible and over-passing wrong-dot attempts (Pitfall 4 direction).
**Why it happens:** The existing normalization is per-stroke and aimed at a single body stroke (alif). For multi-stroke letters, relative position between body and dot matters.
**How to avoid:** Normalize the **whole letter together** (combined bbox — exactly what `authoring_export.dart._combinedBounds` already does for authoring) so the dot's position relative to the body is preserved, then score the dot's relative position against the reference. Do NOT normalize the dot in isolation. Verify with a "taa-when-shown-baa" fixture (D-01).
**Warning signs:** baa and taa both pass the same dotted input; dot position never enters the verdict.

### Pitfall 3: Too strict — false negatives that make a child quit (the worst outcome)
**What goes wrong:** Tolerances set by adult/emulator feel reject good-faith child attempts. With no gamification cushion, frustration → disengagement.
**Why it happens:** Geometric distance is easy to write strictly; developers test on clean adult/mouse strokes.
**How to avoid:** Tune FN **separately** and **per-letter** against real-tablet child samples (D-02). When borderline, lean encouraging for good-faith attempts (CONTEXT specifics). Keep order/count firm while shape tolerance is generous (Pitfall 4 balance).
**Warning signs:** Pass rate near 0% on real child samples; a capable child failing a letter an adult calls correct.

### Pitfall 4: Too lenient — false positives that pass sloppy work
**What goes wrong:** Over-correcting Pitfall 3, the scorer passes scribbles / wrong-order / wrong-dot. Since the gate is the *only* quality signal (no points), a broken gate hollows out the product.
**How to avoid:** Tune FP separately from FN. Keep **order and count firm** even when shape is lenient — they are unambiguous and pedagogically central. ML Kit identity gate catches scribbles/wrong-letter (SC#2/D-04).
**Warning signs:** "wrote taa when shown baa" passes; a scribble passes; one global tolerance for all letters.

### Pitfall 5: ML Kit model not present on first run / wrong locale
**What goes wrong:** Recognition is called before the `ar` model is downloaded → failure; or the wrong BCP-47 identifier is used.
**How to avoid:** D-05 — background-fetch on first launch, check `isModelDownloaded` before any `recognize`, show "getting ready" if not yet cached. Confirm the exact Arabic model identifier (`ar`) against `DigitalInkRecognitionModelIdentifier` on the **target tablet**, not the emulator. Fully offline after the one-time fetch.
**Warning signs:** Recognition throws on a fresh install with no network; works only because dev already had the model cached.

### Pitfall 6: Pedagogy invented in code instead of held from the mother's spec
**What goes wrong:** Tolerances or baa/taa/thaa stroke shapes get guessed in Dart instead of authored + signed off by the mother (D-01).
**How to avoid:** baa/taa/thaa authoring is a **gate inside Phase 4**, via the authoring screen, signed off like alif in Phase 02.1. Tolerances are data she edits. `signedOff: false` must flip to `true` only after her sign-off; the load-time validator (`validateReferenceStrokes`) guards the data.
**Warning signs:** baa ships `signedOff: false`; tolerance numbers chosen "by feel" in code.

### Pitfall 7: Anti-gamification eroded by a generic failure message
**What goes wrong:** A new failure category (count/order/dot/identity) has no authored feedback, so it falls through to the generic fallback ("Something looks off…") — violating PLAT-03 / the tutor voice.
**How to avoid:** Every new `MistakeId` gets a `commonMistakes[].check` + warm, specific, authored `feedback` in `letters.json` AND an l10n string (mirror `practice_screen.dart._feedbackString`). The mother authors the copy (her voice). No `letterSpacing` on Arabic; coral not red; no emoji (design kit).
**Warning signs:** A failure path returns `MistakeId.fallback`; new failure copy written by a developer, not authored.

## Code Examples

### Reading per-letter tolerances (D-03 — data not code)
```jsonc
// Source: proposed extension to assets/curriculum/letters.json (Letter gains "tolerances")
// Leading hypothesis (D-03): named preset + optional numeric overrides.
{
  "id": "baa",
  "referenceStrokes": [ /* body (line) + dot (tap) — authored by the mother (D-01) */ ],
  "commonMistakes": [
    { "id": "wrong_stroke_count", "check": "strokeCountMismatch",
      "feedback": "Baa is two parts — the boat, then one dot underneath." },
    { "id": "dot_wrong",          "check": "dotPositionWrong",
      "feedback": "Baa's dot goes under the boat, not on top." }
    /* + the existing length/direction/curvature checks for the body */
  ],
  "tolerances": {
    "preset": "normal",                 // loose | normal | strict — teacher-legible
    "overrides": { "maxCurvature": 0.30 } // optional numeric knobs for power use
  },
  "signedOff": false   // flips true only after the mother signs off (D-01 gate)
}
```

### Preset → numeric expansion (pure Dart)
```dart
// Pattern (to author in lib/core/scoring/tolerances.dart)
class Tolerances {
  final int minRawPoints;
  final int resampleN;
  final double maxCurvature;
  // candidate knobs (D-03): + minStrokeLength, directionStrictness, shapeDistanceThreshold, dotPositionTolerance
  static const _presets = {
    'loose':  Tolerances(minRawPoints: 8,  resampleN: 32, maxCurvature: 0.35),
    'normal': Tolerances(minRawPoints: 10, resampleN: 32, maxCurvature: 0.25), // == today's constants
    'strict': Tolerances(minRawPoints: 12, resampleN: 32, maxCurvature: 0.18),
  };
  factory Tolerances.fromJson(Map<String, dynamic> j) { /* preset then apply overrides */ }
}
```
Note: `normal` deliberately equals the current hardcoded values (`_kMinRawPoints=10`, `_kResampleN=32`, `_kMaxCurvature=0.25`) so the refactor is behavior-preserving for alif before calibration moves them.

### Existing per-stroke verdict (the leaf the orchestrator wraps)
```dart
// Source: lib/core/scoring/geometric_stroke_scorer.dart:35-59 (verbatim, abridged)
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
Phase 4 parameterizes the threshold constants from `letter.tolerances` and calls this per body stroke from `scoreLetter`.

## Calibration Methodology (resolves D-02)

**Recommended protocol (confirms the leading hypothesis):**

1. **Capture surface:** Extend `lib/dev/authoring_screen.dart` into a **labeled-sample mode** — same Listener capture + `authoring_export.dart` normalization (combined-bbox), plus a label selector. Labels (the failure taxonomy): `good`, `wrong_order`, `wrong_direction`, `wrong_count`, `scribble`, `wrong_letter`, and the D-01-specific `taa_when_shown_baa` (right body, wrong dot count). Runs on a **real Android tablet**, dev route only, non-child-facing.
2. **Who captures/labels:** Real children draw; the **owner's mother labels live** (she is the pedagogical authority). In-memory-only discipline (T-01-05): only the labeled fixture coordinates intended as test data are written out (as fixture files), nothing transmitted.
3. **Capture fidelity (D-02 required output):**
   - **Emulator/mouse:** strokes are too smooth and deliberate — *no jitter, even sampling, adult motor control*. Tunes the scorer **too strict** → rejects real kids (Pitfall 3). **Use for deterministic unit tests only, never for tolerance-setting.** [VERIFIED: `StrokeCanvas._accept` already special-cases mouse/touch behind `kDebugMode` — emulator capture is a debug affordance, not production fidelity.]
   - **Real-tablet finger:** fatter contact, more jitter, lower effective resolution than stylus; closest to how many 5-year-olds will actually use the app if no stylus. Pressure is irrelevant to this geometric scorer (CONTEXT D-02 confirms).
   - **Real-tablet stylus:** the target modality; finer path, still child-jittery. This is the gold standard for tolerance-setting.
   - **Sampling rate** differs by source (event coalescing on the emulator vs the digitizer rate on the tablet), which changes raw point counts and therefore the `minRawPoints` predicate — another reason to set `minRawPoints` from real-tablet data.
4. **Minimum viable sample sizes (recommendation, MEDIUM confidence):** To estimate a per-letter pass/fail boundary that separates FN from FP *separately*, target **~15–20 samples per letter per label category** (CONTEXT's own figure). For the 4 calibration letters × ~7 categories that is ~420–560 fixtures — feasible in a single session with a few children. This is enough to see the boundary, not enough for statistical CIs; treat tolerances as "tuned, then watched in playtest," not "proven."
5. **The tuning loop (FN and FP separately, per-letter):**
   - Run the **calibration harness** (a `flutter test`) over all labeled fixtures for a letter.
   - Report a per-letter confusion table: for each `tolerances.preset`/override, count **false negatives** (`good` samples the scorer rejected) and **false positives** (`wrong_*`/`scribble`/`taa_when_shown_baa` samples the scorer passed).
   - The mother + owner adjust the JSON tolerance (preset or override), re-run, repeat. **Lean toward minimizing FN for good-faith attempts** while keeping order/count/identity firm (CONTEXT specifics + Pitfall 3 > Pitfall 4 priority).
6. **Fixtures become permanent regression tests** (SC#4): the labeled coordinate sets are committed as test fixtures; the harness asserts the final tuned tolerances keep `good` passing and every named common mistake rejected.

**Feasibility-ranked options:**
| Rank | Option | Pro | Con |
|------|--------|-----|-----|
| 1 (recommend) | In-app capture on real tablet, mother labels live | Correct fidelity, single source of truth, fixtures = regression tests | Needs real children + a tablet session |
| 2 | Offline paper + manual coordinate entry | Works without children present | Loses real digitizer fidelity; tedious; error-prone |
| 3 | Synthetic hand-crafted fixtures | Deterministic, no logistics | Adult-imagined, not real child motor variance — risks Pitfall 3 mis-tune |
| ✗ reject for tolerances | Emulator/mouse capture | Easy | Too smooth → too strict (D-02, Pitfall 3). OK only for unit tests. |

## State of the Art

| Old Approach (Phase 3) | Current Approach (Phase 4) | When Changed | Impact |
|--------------------------|----------------------------|--------------|--------|
| Single-stroke `scoreStroke` against `referenceStrokes.first` | Whole-letter `scoreLetter` orchestrator (count/order/per-stroke/dot) | This phase | SC#1 becomes real on multi-stroke letters |
| Thresholds hardcoded in `geometric_stroke_scorer.dart` | Per-letter `tolerances` in `letters.json` (preset + overrides) | This phase | SC#4 — mother tunes without recompile |
| `HandwritingRecognizer` seam unimplemented (D-16) | `MlKitRecognizer` as advisory identity gate + model download | This phase | SC#2 — scribble/wrong-letter caught |
| Tolerances set by adult/synthetic feel | Calibrated against labeled real-tablet child samples, FN/FP separately per-letter | This phase | Pitfalls 3 & 4 addressed with data |

**Deprecated/outdated:**
- The `tools/extract_reference_paths.py` outline-extraction pipeline is **abandoned** (superseded by Phase 02.1 in-app authoring — see `reference_path.dart` doc). Do not use it to author baa/taa/thaa.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ~15–20 samples per letter per category is the minimum viable size | Calibration | Too few → noisy tolerance boundary; mitigated by "tune then watch in playtest" framing. Mother can request more. |
| A2 | Whole-letter (combined-bbox) normalization is the right SC#3 approach for dotted letters | Pitfall 2, Architecture | If per-stroke normalization turns out sufficient, this is over-engineered; verify with the taa-vs-baa fixture early. |
| A3 | A Dart `flutter test` harness is the right calibration tool (over a Python harness, despite CLAUDE.md's Python preference) | Standard Stack, Calibration | If the owner strongly prefers Python tooling, the harness would need to shell out to the scorer or accept re-implementation drift. Flag at planning. |
| A4 | The Arabic ML Kit model identifier is `ar` and covers letter-level (not just word) input for ب/ت/ث | ML Kit, Pitfall 5 | If `ar` under-recognizes isolated single letters, the D-04 identity gate is weaker than hoped — but D-04 only needs "is this a *completely different* letter," a low bar. Verify on tablet. |
| A5 | `normal` preset == today's constants makes the refactor behavior-preserving | Code Examples | If alif behavior shifts after the data refactor, the existing `geometric_stroke_scorer_test.dart` fixtures will catch it (they pin cleanAlif/smallCorrect/tooShort/inverted/curved). Low risk. |

## Open Questions

1. **Whole-letter completion trigger.** How does the app know the child finished a multi-stroke letter (to run `scoreLetter` once)? Count-reached vs an explicit "Done" affordance.
   - What we know: capture forwards one stroke per pen-up; the session state machine scores per stroke today.
   - What's unclear: the UX for "I've drawn all the strokes."
   - Recommendation: planner decides (Claude's-discretion: Riverpod orchestrator wiring). Count-reached is lowest-friction for a 2-part letter; revisit for letters with optional connectors later.

2. **Per-stroke feedback vs whole-letter feedback.** Today each stroke fails/passes independently and the streak resets on any miss. For multi-stroke letters, does feedback fire per stroke or only after the whole letter?
   - Recommendation: keep per-stroke shape feedback immediate (it's the warm coaching beat), but count/order/identity are necessarily whole-letter verdicts — surface them after the last stroke. Planner to specify the state-machine change.

3. **ML Kit `ar` single-letter recognition quality on the target tablet.** A5/A4 — needs an on-device spike, not desk research.
   - Recommendation: add a small "ML Kit identity spike on tablet" task early in the phase to de-risk D-04 before building the gate around it.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | everything | ✓ | Dart `^3.11.5` (pubspec) / STACK.md targets 3.44.x | — |
| `google_mlkit_digital_ink_recognition` | D-04 identity gate | ✗ (not yet in pubspec) | add ^0.14.2 | none — required for SC#2; `flutter pub add` |
| Real Android tablet | D-02 sample capture, D-04/Pitfall 5 on-device verify | ? (owner-dependent) | — | If unavailable: capture is blocked for tolerance-setting (emulator rejected). **This gates calibration** — confirm tablet + child access at planning. |
| ML Kit `ar` model | recognition at runtime | downloaded on device (D-05), ~few MB | n/a | "getting ready" state until cached; offline after |
| Network (once) | first ML Kit model download | needed once | — | D-05 background fetch; offline thereafter |

**Missing dependencies with no fallback:**
- A **real Android tablet + access to real children** for D-02 tolerance-setting capture. Emulator/mouse is explicitly rejected for tolerances. If this is unavailable, the phase can still build the orchestrator, the schema, the ML Kit gate, and synthetic unit tests, but **tolerance calibration (the heart of the phase) cannot be completed** — flag to the owner at planning. (Option-2/3 fallbacks exist but degrade fidelity.)

**Missing dependencies with fallback:**
- `google_mlkit_digital_ink_recognition` — add via `flutter pub add` (trivial).
- ML Kit `ar` model — downloaded at runtime (D-05).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) — only test dep present |
| Config file | none — standard `flutter test` discovery under `test/` |
| Quick run command | `flutter test test/core/scoring/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req / SC | Behavior | Test Type | Automated Command | File Exists? |
|----------|----------|-----------|-------------------|-------------|
| SC#1 | wrong stroke **count** rejected with named fix | unit | `flutter test test/core/scoring/letter_scorer_test.dart` | ❌ Wave 0 |
| SC#1 | wrong stroke **order** rejected with named fix | unit | `flutter test test/core/scoring/letter_scorer_test.dart` | ❌ Wave 0 |
| SC#1 | wrong **dot** count/position (taa-when-shown-baa) rejected | unit | `flutter test test/core/scoring/letter_scorer_test.dart` | ❌ Wave 0 |
| SC#2 | scribble / wrong-letter rejected via ML Kit gate (advisory, mocked recognizer) | unit | `flutter test test/core/scoring/letter_scorer_test.dart` (mocktail fake recognizer) | ❌ Wave 0 |
| SC#2 | ML Kit gate NEVER overrides a good geometric pass (D-04) | unit | same file | ❌ Wave 0 |
| SC#3 | size/offset-varied good attempt passes (normalization) | unit | `flutter test test/core/scoring/geometric_stroke_scorer_test.dart` (extend with multi-stroke) | ✅ (single-stroke `smallCorrect` exists; extend for letters) |
| SC#4 | tolerances read from data; `normal` preset == legacy constants (behavior-preserving) | unit | `flutter test test/core/scoring/` | ❌ Wave 0 |
| SC#4 | named common mistakes encoded as regression fixtures (reject known-bad, accept known-good) | unit | `flutter test test/core/scoring/calibration_harness_test.dart` | ❌ Wave 0 |
| FP/FN per-letter | calibration harness reports per-letter confusion over labeled fixtures | unit/harness | `flutter test test/core/scoring/calibration_harness_test.dart` | ❌ Wave 0 |
| S1-05 (latency) | scorer stays sub-300 ms (existing budget: <50 ms per stroke) | unit | existing latency test in `geometric_stroke_scorer_test.dart`; add a whole-letter latency assert | ✅ (per-stroke) / ❌ (whole-letter) |
| D-05 model | model-not-ready shows "getting ready", not an error | widget | `flutter test test/features/practice/` | ❌ Wave 0 |
| PLAT-03 | every failure path maps to authored feedback (no generic fallback for real letters) | unit | `flutter test test/core/scoring/mistake_mapping_test.dart` (extend) | ✅ (extend) |

### Sampling Rate
- **Per task commit:** `flutter test test/core/scoring/` (pure-Dart, fast)
- **Per wave merge:** `flutter test` (full suite, incl. widget tests for the "getting ready" state)
- **Phase gate:** full suite green + the calibration harness asserts the tuned per-letter tolerances before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/core/scoring/letter_scorer_test.dart` — covers SC#1, SC#2 (mocked recognizer), the D-04 no-override rule
- [ ] `test/core/scoring/calibration_harness_test.dart` — runs the scorer over labeled fixtures, reports/asserts per-letter FP/FN (SC#4)
- [ ] `test/core/scoring/calibration_fixtures/` — labeled real-tablet sample sets per letter per category (captured via the extended authoring screen)
- [ ] Extend `geometric_stroke_scorer_test.dart` and `mistake_mapping_test.dart` for the new multi-stroke / count / order / dot / identity paths
- [ ] Widget test for the model-not-ready "getting ready" state (D-05)
- [ ] Fake `HandwritingRecognizer` (mocktail) — no real ML Kit in unit tests

## Security Domain

> `security_enforcement: true`, ASVS level 1. This phase is fully on-device; the dominant risk is **child data**, not network/auth.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No accounts in v1 (local-only). |
| V3 Session Management | no | No server sessions. |
| V4 Access Control | no | Single-device, no multi-user server. |
| V5 Input Validation | yes | `validateReferenceStrokes` / `validateStroke` already gate curriculum data at load; extend coverage to baa/taa/thaa + the `tolerances` block. Reject malformed/out-of-range points. |
| V6 Cryptography | no | No secrets/keys on device (tutor is v2, never client-side). Do not introduce any. |
| V8/V9 Data Protection & Privacy | yes (project-critical) | Child stroke data stays **in memory only** (T-01-05 / T-03-01). The new sample-capture mode writes ONLY labeled fixture coordinates as test data, never logs raw child strokes in release, never transmits. Capture mode is a `kDebugMode`/dev-route seam, never child-facing in production. |

### Known Threat Patterns for on-device child-handwriting scoring
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Raw child strokes leak via logs/persistence | Information Disclosure | In-memory-only discipline (already enforced in `StrokeCanvas`, `practice_screen`, `PracticeSessionController`); no `print`/`debugPrint` of points; sample export is dev-only and writes fixtures, not runtime child data. |
| Sample-capture mode reachable by a child | Information Disclosure / Tampering | Keep capture behind the existing `/dev/*` route + `kDebugMode`; not surfaced in child nav (mirror `authoring_screen.dart`'s reachability rule T-02.1-07). |
| ML Kit model download over untrusted network | Tampering | ML Kit fetches from Google's own infrastructure; verify `isModelDownloaded` before use; no custom model URLs. |
| Malformed curriculum data crashes the scorer | DoS / Tampering | Load-time validation (`validateReferenceStrokes`) already returns violations rather than throwing; extend to `tolerances`. |

## Sources

### Primary (HIGH confidence)
- Codebase (read directly): `lib/core/scoring/geometric_stroke_scorer.dart`, `scoring_models.dart`, `stroke_resampler.dart`, `stroke_validation.dart`, `reference_path.dart`; `lib/core/recognition/handwriting_recognizer.dart`; `lib/models/letter.dart`; `lib/features/practice/practice_screen.dart`, `widgets/stroke_canvas.dart`; `lib/providers/practice_providers.dart`; `lib/dev/authoring_screen.dart`, `authoring_export.dart`; `assets/curriculum/letters.json`; `test/core/scoring/*`.
- `.planning/research/STACK.md` — ML Kit package/version, API shape, model-download specifics, persistence, Riverpod flavor.
- `.planning/research/PITFALLS.md` — Pitfalls 1/3/4/6/7 governing this phase.
- `.planning/research/STROKE-REFERENCE.md` — why outline extraction is abandoned; centerline authoring.
- `.planning/phases/04-scoring-quality-calibration/04-CONTEXT.md` — locked decisions D-01…D-06.
- `.planning/ROADMAP.md` §Phase 4 + `.planning/REQUIREMENTS.md` §S1-05/PLAT-03.

### Secondary (MEDIUM confidence)
- pub.dev `google_mlkit_digital_ink_recognition` page (WebFetch) — v0.14.2, Android minSdk 21, `DigitalInkRecognizer` / `DigitalInkRecognizerModelManager` / `isModelDownloaded`, `Ink`/`Stroke`/`StrokePoint` input, `RecognitionCandidate{text, score}` output. Corroborates STACK.md.

### Tertiary (LOW confidence)
- Minimum-sample-size figure (~15–20/letter/category) — synthesized from CONTEXT's own estimate; not a measured result (A1).

## Metadata

**Confidence breakdown:**
- Existing scorer characterization: HIGH — every relevant file read; exact paths/signatures/threshold constants quoted.
- Standard stack: HIGH — ML Kit version verified on pub.dev + STACK.md; all other libs already in the project.
- Architecture / orchestrator design: HIGH on what exists, MEDIUM on the recommended new shape (Claude's-discretion items left to planner).
- ML Kit identity gate: MEDIUM — API shape HIGH, single-letter `ar` recognition quality needs an on-device spike (A4, Open Q3).
- Calibration methodology: MEDIUM — protocol is sound, sample-size and tablet/child availability are recommendations/assumptions (A1, Environment).

**Research date:** 2026-06-08
**Valid until:** ~2026-07-08 (stable codebase; re-verify ML Kit version at plan time)
