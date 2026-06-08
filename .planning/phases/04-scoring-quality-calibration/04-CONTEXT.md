# Phase 4: Scoring Quality & Calibration - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Tune the **existing** geometric stroke scorer to the *right strictness*: firmly reject
wrong stroke order, wrong stroke count, and sloppy shapes, while letting good-faith,
size/position-varied child attempts pass — with per-letter pass tolerances that the
owner's mother can adjust as **curriculum data (no code change)**, calibrated against
real child handwriting. Add the **ML Kit secondary identity check** (the "wrote a
completely different letter / scribble" safety net, SC#2) and its one-time model
download-and-cache, behind the `HandwritingRecognizer` seam left ready in Phase 3.

**In scope:**
- **Extend the scorer from single-stroke to whole-letter orchestration:** stroke
  **count** check, stroke **order** check, per-stroke direction/shape/curvature, and a
  **dot/`tap`** predicate — so SC#1 (wrong order/count rejected with a specific named
  message) becomes real on a multi-stroke letter.
- **Move the hardcoded thresholds out of code into per-letter curriculum data** so the
  owner's mother tunes strictness without a code change (SC#4). Today they are constants
  in `geometric_stroke_scorer.dart` (`_kMinRawPoints`, `_kResampleN`, `_kMaxCurvature`);
  the `Letter` model gains a tolerances field and `letters.json` carries the values.
- **Calibrate against real labeled child samples**, tuning **false-negatives** (good
  attempts wrongly rejected — Pitfall 3, the worst outcome) **separately from**
  **false-positives** (bad attempts wrongly passed — Pitfall 4), **per letter**.
- **Author + sign off the baa-family** (baa ب, taa ت, thaa ث) reference strokes and
  common mistakes with the owner's mother — pulled forward from Phase 7 (see D-01) — so
  there are real multi-stroke letters to calibrate.
- **ML Kit `MlKitRecognizer`** implementing the existing `HandwritingRecognizer`
  interface as a **coarse safety net** (D-04) + **one-time model download** (D-05),
  fully offline thereafter.
- **Regression tests** that encode each letter's named `commonMistakes` checks (SC#4).

**Out of scope (later phases):**
- Calibrating the **remaining 24 letters** + words → Phase 7 (full curriculum + sign-off).
- **Pronunciation audio**, profiles, journey map, parent dashboard, sentence/grammar
  exercises — their respective phases (5/6/7/8/9), unchanged.
- Any **points/streaks/tally** gamification — permanently out (PLAT-03).

</domain>

<decisions>
## Implementation Decisions

### Letter scope for calibration
- **D-01:** Calibrate **alif + the baa-family (baa ب, taa ت, thaa ث)**, not alif alone.
  Rationale: alif is one stroke, so SC#1 (reject wrong stroke *order* / *count*) has
  nothing real to bite on. The baa-family is the sharpest possible test — **identical
  body, differing only by dot count** (1 below / 2 above / 3 above) — so it stress-tests
  the **dot-count distinction**, **stroke count/order**, *and* whether the **ML Kit
  identity check confuses ب/ت/ث**. **Dependency pulled forward:** the owner's mother
  must author + sign off reference strokes and `commonMistakes` for baa/taa/thaa during
  this phase (these are `signedOff: false` placeholders today; sign-off was nominally
  Phase 7). Treat this authoring + sign-off as a gate inside Phase 4, mirroring the
  alif sign-off pattern from Phase 02.1.

### Calibration sample collection — OPEN RESEARCH DIRECTIVE (high priority)
- **D-02:** **Final method deferred to research** (owner's explicit call: "let research
  decide"). The researcher MUST investigate how to collect labeled child handwriting
  samples for tuning, and recommend before planning. Required research outputs:
  - **Capture fidelity:** what actually differs between emulator/mouse, real-tablet
    finger, and real-tablet stylus capture for a *geometric* scorer (sampling rate,
    jitter, deliberate-vs-childlike motion). Pressure is irrelevant to this scorer.
  - **Minimum viable sample sizes** per letter per label-category to tune
    false-neg/false-pos separately with confidence.
  - **Feasibility-ranked options** + a recommended protocol.
  - **Leading hypothesis to confirm or beat (Claude's recommendation):** collect from
    **real children on a real Android tablet**, captured via an **in-app capture tool**
    (extend the existing Phase 02.1 authoring trace screen into a labeled-sample mode),
    **labeled live by the owner's mother** (good / wrong-order / wrong-direction /
    wrong-count / scribble / wrong-letter). Even ~15–20 samples per letter per category
    beats synthetic. **Reject emulator/mouse data for setting tolerances** — it makes
    the scorer too strict and rejects real kids (Pitfall 3); emulator is fine only for
    deterministic unit tests. Captured strokes become permanent regression fixtures.
  - **Constraint:** in-memory-only capture discipline holds (T-01-05) — only labeled
    fixture coordinates intended as test data are persisted; nothing transmitted.

### Tolerance schema (what the mother edits) — OPEN RESEARCH/PLANNER DECISION
- **D-03:** **Exact form deferred to research/planner** (owner: "let research/planner
  decide"). Hard requirements that are LOCKED regardless of form:
  1. **Per-letter** (tolerances live on each `Letter`, not one global constant).
  2. **Data, not code** — editable in the bundled curriculum JSON, no recompile (SC#4).
  3. **Teacher-legible** — a non-coder who reasons pedagogically must understand it.
  - **Leading hypothesis (Claude's recommendation):** **named strictness presets**
    (e.g. `loose` / `normal` / `strict`) that expand to the underlying numeric
    thresholds, **plus** optional per-letter numeric overrides for power use. Researcher
    decides the final shape and **which knobs actually need to be tunable** (candidates:
    max-curvature, min stroke length, direction strictness, shape-distance threshold,
    dot position/size tolerance).

### ML Kit identity check role
- **D-04:** **Coarse safety net only.** ML Kit catches **"wrote a completely different
  letter / scribble"** (SC#2) and nothing finer. The **geometric scorer remains the
  sole judge** of shape, order, count, and dot quality. ML Kit rejects **only** when it
  is confidently a *different* letter; it **never overrides a good-faith correct
  geometric pass**. Honors research **Pitfall 1 (don't over-trust ML Kit)** and avoids
  ب/ت/ث confusion causing false rejections of correct attempts (the co-judge risk was
  explicitly declined).

### ML Kit model download
- **D-05:** **Background fetch on first launch** (right after install/onboarding, while
  the child explores), caching the ~few-MB Arabic model. If the child reaches a practice
  screen before the model is cached, show a **calm "getting ready" state** (no error, no
  hard block). **Fully offline after** the one-time fetch. Lazy "download on first
  practice with a wait" was declined — it puts a wait at the most important moment.

### Scope boundary carried forward (from Phase 3 — confirmed, do not relitigate)
- **D-06:** Phase 3's D-15/D-16 stand: Phase 3 shipped the deliberately **lenient
  first-cut** scorer and left the `HandwritingRecognizer` seam unimplemented; **Phase 4
  owns** the per-letter tuning + the ML Kit implementation + the model download. This is
  the deepest-risk phase, deliberately isolated.

### Claude's Discretion
- The shape-distance algorithm used for whole-letter scoring (resampled point distance
  vs Procrustes/Fréchet) — planner/researcher choice; calibration tunes it regardless.
- Exact Riverpod wiring for the letter-level scoring orchestrator that sits above the
  per-stroke `scoreStroke` (currently called once per stroke in `practice_screen.dart`).
- The labeled-fixture file format and where calibration fixtures live in the repo.
- ML Kit package selection/version (verify against `.planning/research/STACK.md` at plan
  time).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The scoring pipeline & deepest-risk design (read first)
- `.planning/research/PITFALLS.md` — §Pitfall 1 (don't over-trust ML Kit → drives D-04),
  §Pitfall 3 (too strict = false negatives that make a child quit → the primary thing
  calibration must avoid), §Pitfall 4 (too lenient = false positives), §Pitfall 7
  (anti-gamification + generic feedback). These directly govern this phase.
- `.planning/research/ARCHITECTURE.md` §"Component Breakdown" / §"Scoring pipeline" —
  `GeometricStrokeScorer`, `ScoringService`, `HandwritingRecognizer` (interface) +
  `MlKitRecognizer` (the v1 impl this phase builds), the "two judges on the same Ink"
  model.
- `.planning/research/STACK.md` — prescriptive ML Kit Digital Ink package/version
  (verify at plan time) + model-download specifics.

### Requirements & scope
- `.planning/ROADMAP.md` §"Phase 4: Scoring Quality & Calibration" — the 4 success
  criteria + research hint (false-neg/false-pos tuned **separately, per-letter**).
- `.planning/REQUIREMENTS.md` §S1-05 (instant on-device per-stroke feedback; stroke
  count/order/direction/shape; named fix; <~300 ms; offline; custom geometric scorer
  with ML Kit as **secondary identity check only**), §PLAT-03 (anti-gamification).
- `.planning/PROJECT.md` §"The tutor's voice" + §"Decided" (ML Kit Digital Ink
  validated; tutor never client-side; anti-gamification).
- `.planning/phases/03-trace-one-letter-end-to-end/03-CONTEXT.md` §D-15/D-16 — the
  Phase 3→4 handoff (lenient first-cut + deferred ML Kit/calibration).

### Existing code this phase extends/modifies
- `lib/core/scoring/geometric_stroke_scorer.dart` — the scorer to tune; **hardcoded
  thresholds** `_kMinRawPoints`/`_kResampleN`/`_kMaxCurvature` move into curriculum data
  (D-03); named predicates `strokeLengthBelowThreshold` / `strokeDirectionInverted` /
  `strokeCurvatureExceedsThreshold` map to `commonMistakes[].check`.
- `lib/core/scoring/scoring_models.dart` — `StrokeResult`, `MistakeId` enum.
- `lib/core/scoring/stroke_resampler.dart` — `resample`, `normalizeToUnitBox` (the
  normalization that lets size/offset-varied correct attempts pass, SC#3).
- `lib/core/recognition/handwriting_recognizer.dart` — the **interface seam** the ML Kit
  `MlKitRecognizer` implements (D-04/D-05). Currently no impl.
- `lib/features/practice/practice_screen.dart` — calls `scoreStroke(...)` per single
  stroke today; needs a **letter-level orchestrator** above it for count/order (D-01).
- `lib/models/letter.dart` — `Letter` gains a **tolerances** field; already holds
  `referenceStrokes`, `cleanRepsToAdvance`, `commonMistakes`, `signedOff`.
- `assets/curriculum/letters.json` — alif signed off (1 stroke); **baa/taa/thaa are
  empty `referenceStrokes` + `signedOff: false` placeholders** to be authored (D-01);
  per-letter tolerances added here (D-03).

### Authoring tool to reuse for sample capture (D-02 hypothesis)
- The Phase 02.1 in-app **authoring trace screen** (trace over a faint Noto Naskh glyph,
  normalize/export strokes) — leading candidate to extend into a labeled-sample capture
  mode. Locate via `.planning/phases/02.1-stroke-reference-correction/` and `lib/`.

### The design (feedback copy + celebration feel)
- `docs/design/kit/project/SKILL.md` — brand hard-rules (no red; coral not red; gold =
  rewards-only; Western numerals; no emoji). Feedback strings stay warm/specific.
- `assets/curriculum/letters.json` — `commonMistakes[].feedback` is the tutor's authored
  voice; calibration must keep failures mapping to these named fixes, never a generic
  "try again" (Pitfall 7).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`geometric_stroke_scorer.dart`** — working single-stroke scorer with 3 named
  predicates + `feedbackForMistake` mapping to authored copy. Phase 4 tunes its
  thresholds (→ data) and adds count/order/dot orchestration above it.
- **`stroke_resampler.dart`** — `normalizeToUnitBox` already implements the
  size/offset-invariance that SC#3 needs; calibration verifies it's sufficient.
- **`handwriting_recognizer.dart`** — clean interface seam (`identify(...) →
  RecognitionResult{topCandidate, confidence}`) ready for `MlKitRecognizer`.
- **Phase 02.1 authoring trace screen** — capture+normalize+export plumbing to reuse for
  labeled-sample collection (D-02 hypothesis).
- **Drift persistence seam** (Phase 1/3) — only the derived mastery result is persisted
  (T-01-05); calibration fixtures are test data, not runtime child data.

### Established Patterns
- Predicate **function names == `commonMistakes[].check` strings** — keep this contract
  when adding count/order/dot predicates so failures map to authored feedback.
- **Pure-Dart scorer**, no Flutter/dart:ui imports — keep new scoring logic pure for
  fast unit tests against fixtures.
- **All thresholds documented inline** at the top of the scorer — D-03 relocates them to
  data; preserve the doc-comment rationale alongside the curriculum values.
- **All feedback via authored copy / gen-l10n** — no generic failure messages (Pitfall 7).

### Integration Points
- New **letter-level scoring orchestrator** (count → order → per-stroke shape/direction →
  dot) sits between `practice_screen.dart`'s capture and `scoreStroke`.
- **`MlKitRecognizer`** plugs into `HandwritingRecognizer`; the orchestrator consults it
  as a coarse gate (D-04).
- **Model-download service** (D-05) — background fetch on first launch + "getting ready"
  state in the practice flow; fully offline after.
- **Per-letter tolerances** flow `letters.json` → `Letter` model → scorer (D-03).

</code_context>

<specifics>
## Specific Ideas

- The **baa-family was chosen deliberately** (D-01): same body, dot count is the only
  difference, so it's the cleanest stress test of dot-count scoring AND ML Kit
  ب/ت/ث confusion. Calibration should explicitly include "wrote taa when shown baa"
  (right body, wrong dot count) as a labeled failure category.
- **False-negatives matter more than false-positives** here: a wrongly-rejected
  good-faith child is the failure that makes a kid quit (Pitfall 3). When borderline,
  calibration should lean toward the encouraging side for good-faith attempts while
  still firmly catching clearly-wrong order/count/letter.
- **The emulator is a trap for tolerance-setting** (owner's own instinct): mouse-drawn
  strokes are too smooth and will mis-tune the scorer strict. Use real-hardware child
  capture for tolerances; emulator only for deterministic unit tests.

</specifics>

<deferred>
## Deferred Ideas

- **Calibrating the remaining 24 letters + words** → Phase 7 (full curriculum + sign-off).
  Phase 4 establishes the calibration *method* on alif + baa-family; Phase 7 applies it.
- **Gentle "show me again" auto-replay after repeated misses** (Phase 3 D-05 nice-to-have)
  → candidate UX polish, not required here.
- **Updating design assets** to drop the legacy star-counter/weekly-tally chrome →
  housekeeping, not Phase 4 code.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 4-Scoring Quality & Calibration*
*Context gathered: 2026-06-08*
</content>
</invoke>
