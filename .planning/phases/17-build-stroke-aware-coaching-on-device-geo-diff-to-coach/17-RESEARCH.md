# Phase 17: Tutor Redesign — grounded, form-aware, on-device scorer — Research

**Researched:** 2026-07-05
**Domain:** On-device handwriting scoring (Dart/Flutter) + grounded LLM coaching (LangGraph/Python on Cloud Run, keyless Gemini on Vertex) + eval-gate engineering
**Confidence:** HIGH (synthesis of committed clean-room research + direct codebase verification; both test suites run green in this session)

## Summary

This is a SYNTHESIS phase: the load-bearing research is already done, committed, and cited
(`docs/architecture/TUTOR-RESEARCH-FINDINGS.md`, 11 verified findings F1–F11), and the phase's
decisions are LOCKED in `17-CONTEXT.md` (D-A…D-F). The deterministic on-device scorer OWNS
pass/fail (D-A, reversing the Phase-17.1 image judge); the LLM only explains and coaches from
the scorer's structured per-criterion output (D-B). The scorer is UPGRADED, not rewritten (D-C):
DTW shape-match vs the per-form reference + soft 3-zone thresholds replace the chord-curvature
proxy and hard predicates. Thresholds are DATA, calibrated on labelled child samples —
provisional synthetic values ship for the demo (D-D). Prove on baa (4 forms + words), then taa (D-E).

**Critical codebase finding for the planner:** substantially more of this phase already exists
than CONTEXT's "increment 1 done" suggests. Verified in this session `[VERIFIED: codebase]`:
(1) the DTW + SoftBand core (`shape_match.dart` + 6 green tests, commit 4e71d6b); (2) the ENTIRE
strokeDiff wire path — on-device `computeStrokeDiff` (`lib/tutor/stroke_diff.dart`, commit
09d2cde), `TutorFacts.strokeDiff`, server `StrokeDiffIn` (extra="forbid", point-free), and the
`COACH_STROKE_ADDENDUM` anti-parroting prompt (all live on the deployed rev 00020); (3) the
Phase-17.1 image-judge path that D-A now RETIRES as verdict owner (`image_judge.py`, the
`main.py` short-circuit, the client `aiJudge` deferral in `exercise_scaffold.dart`). What remains
is: wiring shapeDistance into the per-stroke scorer (increment 2), the per-form + multi-criteria
letter scorer with structured per-criterion output (increment 3), routing that structured result
into the coaching contract (increment 4), the calibration-harness threshold-fitting upgrade
(increment 5), the verdict cutover retiring the image judge (increment 6), the semantic
faithfulness eval upgrade (EVAL-03), and the ADR (GROUND-04).

**Primary recommendation:** plan the phase as a scorer-core track (increments 2–3, pure Dart,
fully unit-testable), a contract/coaching track (increment 4 + cutover 6, two-sided wire change
with strict deploy ordering), and an eval track (EVAL-03 semantic gate + specificity/variety
dimensions), with the calibration harness (increment 5) and the ADR as closing tasks. Nothing
new is installed — zero new packages on either side.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-A — The deterministic scorer OWNS pass/fail** (online, stroke-based,
  multi-criteria, soft-threshold, on-device). **This REVERSES Phase 17.1's
  AI-owns-pass/fail** (the image judge in `server/app/image_judge.py`): that was a
  reaction to a *mis-calibrated* scorer, not evidence the LLM should judge. The
  research is explicit that VLMs must not own fine-grained handwriting/dot
  judgment. `TUTOR-RESEARCH-FINDINGS.md` §"Bottom line" is the spec. **The
  AI-SPEC §1/§4 "AI owns the verdict" is SUPERSEDED by this decision.**
- **D-B — The LLM only explains + coaches** from the scorer's per-criterion
  output (the warm "why" G7 + mother's-voice line G4 + points at the failed
  criterion). It never sees a blank verdict to invent. Coaching is a *separate,
  degradable* layer over a scorer that already decided.
- **D-C — Scorer design = online, 5 criteria + explicit dot check, soft 3-zone
  thresholds, DTW-to-per-form-reference, spatial dot detection, advisory-only
  CNN/ML-Kit identity.** See findings F1–F9. The existing scorer is UPGRADED, not
  rewritten (it already has spatial dots + advisory ML-Kit + firm count/order).
- **D-D — Thresholds are DATA, calibrated on real child samples, and per-child
  adaptive** (findings F8/F11). Provisional synthetic values ship for the demo;
  owner's-mother-labelled calibration is the production gate. Adaptive bands tie to
  the G8 learner model.
- **D-E — Prove on baa fully (4 forms + words), then taa** (shares baa's skeleton,
  differs only by dots) — the cheapest generalization proof. Reuse boundary from
  `TUTOR-REDESIGN.md` holds (redesign brain, reuse body).
- **D-F — Coaching model is an open bake-off, decided later**: on-device Gemma
  (coaching-only) vs Gemini-on-Vertex, on the mother's register rubric. Not a
  blocker for the scorer work.

### Build increments (from CONTEXT, for the planner to break into tasks)

1. **✅ DONE — Shape-match core.** DTW `shapeDistance` + `SoftBand` 3 zones
   (`lib/core/scoring/shape_match.dart` + test; commit 4e71d6b).
2. **Wire shape-match into the per-stroke scorer** — replace the chord-curvature
   proxy in `geometric_stroke_scorer.scoreStroke` with `shapeDistance` vs the
   **per-form** reference; verdict becomes soft (pass unless a criterion is
   certainly-wrong); keep direction as a criterion.
3. **Per-form + multi-criteria letter scorer** — `letter_scorer.scoreLetter`
   consumes the per-form reference (`contextualForms[form]`), scores the 5 criteria
   + dot check, emits a **structured per-criterion result** (each criterion's zone
   + score + the weakest one). Keep COUNT/ORDER firm; keep the advisory ML-Kit gate.
4. **Structured scorer output → coaching contract** — the per-criterion result is
   the input the LLM coaches from (which criterion failed, by how much) — replaces
   the image-judge path. Grounding holds by construction (LLM can't overturn it).
5. **Calibration harness upgrade** — extend `test/core/scoring/calibration_harness_test.dart`
   to fit the soft-band thresholds from a labelled child set (per letter × form);
   the mother's labels are the ground truth (production gate).
6. **Cutover** — route baa's pass/fail through the upgraded scorer; retire the
   `strokeImage` → `image_judge` short-circuit for the verdict (the image judge, if
   kept at all, becomes an advisory corroborator, never the owner).
7. **(Parallel, curriculum track)** per-form references for the other 25 letters —
   model drafts → owner's mother signs off. Blocks form-awareness beyond alif/baa/taa.

### Claude's Discretion

(CONTEXT.md has no explicit "Claude's Discretion" section; the build-increment
decomposition into plans/waves, the exact shape of the structured per-criterion
result type, and how the eval's specificity/variety dimensions are measured are
left to the planner within the locked decisions above.)

### Deferred Ideas (OUT OF SCOPE)

- Owner's-mother calibration labelling (production gate for D-D).
- Per-form references for 25 letters (curriculum track, D-E generalization).
- Gemma coaching-only bake-off (D-F).
- Letter audio (0/28 recorded).
- ADR + consent for any residual off-device data flow (the geometry path keeps
  strokes on-device, which shrinks this to near-zero — a win).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STRK-01 | The coach names the SPECIFIC geometry of the child's actual baa attempt, measurably beating the label-only baseline on specificity/variety with grounding intact (0 advance-on-fail, 0 praise-on-fail) | Spike-validated (SPIKE-FINDINGS H1/H2: geo_diff arm 0.87 specificity, 0 grounding violations); `computeStrokeDiff` + `COACH_STROKE_ADDENDUM` already shipped (commit 09d2cde); increment 4 upgrades the coach input to the structured per-criterion result; eval needs a specificity/variety dimension (see Validation Architecture) |
| GROUND-04 | Raw strokes never leave the device; only the derived diff crosses the wire; `extra="forbid"` rejects raw points/PII; client+server contracts match (no 422); reversal recorded as an ADR | Two-sided guard already in place and verified: `test/tutor/payload_nonpii_test.dart` (whitelist ∪ `_strokeDiffKeys`) + `server/tests/test_payload_nonpii.py` (422 on extras); `StrokeDiffIn` holds only scalars/strings by construction; ADR remains to be written (see Open Questions for numbering) |
| EVAL-03 | Eval scores stroke-level coaching with a SEMANTIC faithfulness gate (substring floor retired as the gate) + a no-false-geometry check, gold set regrown + re-signed by the owner's mother, runs as the regression gate | Spike proved the substring gate false-flags correct paraphrases (rate 0.55–0.73 with 0 real contradictions); `run_eval.py`/`run_judge.py`/`make eval` harness exists to extend; AI-SPEC §5 (E1–E8) stands per CONTEXT; gold_set.jsonl currently 10 Claude-drafted cases `signed:false` |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Python over TypeScript for backend/tooling** — the coaching server stays Python. The
  SCORER is on-device Dart by design (Decided: on-device scoring, no network round-trip),
  and the calibration harness is deliberately Dart flutter-test (recorded deviation —
  it must run the REAL `scoreLetter`, never a Python re-implementation).
- **The tutor never runs client-side** — the LLM coaching stays on the server; only the
  deterministic scorer and derived-diff computation are on-device.
- **ML Kit Digital Ink is VALIDATED and advisory-only in scoring** (Decided) — keep the
  advisory identity gate; never let it own the verdict.
- **Riverpod only** for state management; no BLoC/GetX.
- **Curriculum/pedagogy comes from the owner's mother — never invented.** Model may DRAFT
  per-form stroke data; nothing model-authored ships unsigned. Calibration ground truth =
  her labels.
- **Anti-gamification (PLAT-03)** — no point totals/streaks/badges; the star = real mastery
  only; feedback specific, never "Oops, try again!".
- **Child safety** — minimum child data, private by default, parent-controlled; children
  never log in (D-09b).
- **GSD workflow enforcement** — all file changes through GSD commands; Decided section
  overrides any specialist default.
- **Android-only for now, iPad co-demo device authorized** (memory: owner extended
  2026-06-29) — no iOS-specific work beyond demo enablement.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stroke capture (Offsets, pixel space) | Device / Flutter (`StrokeCanvas`) | — | Physical input; already built, reused verbatim |
| Pass/fail verdict (5 criteria + dot) | Device / pure Dart (`lib/core/scoring/`) | — | **D-A locked**: offline, instant, $0, COPPA-clean; LLM must not judge (F9/F10) |
| Per-form reference resolution | Device / curriculum data (`letters.json contextualForms`) | — | G2/G5: form-awareness scales from data, not per-letter code |
| Derived geometry diff + per-criterion result | Device / pure Dart (`lib/tutor/stroke_diff.dart` + scorer output) | — | GROUND-04: derived facts only cross the wire; computed where strokes still exist |
| Coaching line (warm "why", mother's voice) | Server / LangGraph on Cloud Run (`nodes/coach.py`) | Device authored fallback (`AuthoredFallbackBrain`) | D-B: coaching is separate + degradable; server = only place a model runs |
| Grounding guards (G3 verdict lock, G4 membership) | Server (`coach.py` guards) | Device (dispatcher never rebuilds state from agent) | Defense in depth; verdict can't be overturned by construction |
| Advisory letter identity | Device / ML Kit Digital Ink | — | F6: corroborating only, form-blind, never owns verdict |
| Word recognition (sequence checks) | Device / ML Kit | — | Works perfectly per UAT F6-ok; feedback depth is the gap, not recognition |
| Eval gate (faithfulness/register/specificity) | Server repo tests (`pytest -m code` + `make eval`) | Vertex LLM judge (gemini-2.5-flash, judge ≠ coach) | EVAL-03; model-free legs gate every PR, judge legs gate pre-merge |
| Verdict-correctness calibration (per letter × form) | Device repo tests (Dart calibration harness) | Owner's mother (labels) | Under D-A the scorer's accuracy is a DART test concern, not an LLM-eval concern |

## Standard Stack

### Core (all existing — this phase installs NOTHING new)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter / Dart | 3.41.9 / 3.11.5 `[VERIFIED: flutter --version]` | Client + on-device scorer | Decided stack |
| flutter_test | bundled | Scorer unit tests + calibration harness | Existing harness pattern |
| google_mlkit_digital_ink_recognition | pinned in pubspec | Advisory identity gate + word recognition | Decided, validated |
| langgraph / langchain / langchain-google-vertexai | `>=1.2,<2` / `>=1.0,<2` / `>=3.2.4` (server/pyproject.toml) `[VERIFIED: codebase]` | Coaching graph + keyless Gemini | Deployed rev 00020, reuse boundary locked |
| fastapi / pydantic | `>=0.115` / `>=2.9,<3` | /coach wire contract, `extra="forbid"` guards | Existing GROUND-02/04 mechanism |
| pytest (+ markers `-m code`) | `>=8.0` via uv 0.11.19 | Server eval gate legs | Existing `make eval` harness |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled DTW in pure Dart (already built) | A Dart DTW package | None on pub.dev is established/maintained for this; 24-line DP core already written, tested, and O(n·m) with rolling rows — keep it `[VERIFIED: codebase]` |
| Extending `StrokeDiffIn` for the per-criterion result | A brand-new request field/DTO | Either works; a NEW field (e.g. `criteria`) avoids overloading the baa-specific `bowl*` vocabulary — planner's call, but the 422 lockstep ordering applies identically |
| Vertex LLM judge for semantic faithfulness | Bigger synonym lexicon in `faithfulness.py` | Spike explicitly found the lexicon path incompatible with varied coaching; judge-based semantic check is the researched fix; lexicon stays as the *fast floor*, never the gate for varied lines |

**Installation:** none. Zero new Dart packages, zero new Python packages.

## Package Legitimacy Audit

No new external packages are installed by this phase (all work is code within the existing
Flutter app and server using already-pinned dependencies). Audit not applicable.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Current State of the Build Increments (verified 2026-07-05)

This is the section the planner must trust over CONTEXT's snapshot — the codebase has moved.

| Increment | Status | Evidence |
|---|---|---|
| 1. Shape-match core | ✅ DONE | `lib/core/scoring/shape_match.dart` + `test/core/scoring/shape_match_test.dart` (6 tests, green in this session). API: `shapeDistance(child, ref, {n:32}) → double` (unit-box DTW, avg per-aligned-point distance, `infinity` for <2 points); `SoftBand{tcc,tcw}` with `zoneFor`/`scoreFor`; `SoftBand.shapeDefault = (tcc:0.10, tcw:0.15)` **PROVISIONAL synthetic** `[VERIFIED: codebase + test run]` |
| 2. Shape-match into per-stroke scorer | ❌ NOT STARTED | `scoreStroke` still runs the 3 hard predicates (tooShort / wrongDirection / tooCurved-chord-proxy); never imports shape_match `[VERIFIED: codebase]` |
| 3. Per-form + multi-criteria letter scorer | ❌ NOT STARTED | `scoreLetter(childStrokes, letter, ...)` scores against `letter.referenceStrokes` (the BASE/isolated reference) — `contextualForms` is parsed (`Form{referenceStrokes, commonMistakes, tolerances?}`) and used for GUIDE PAINTING only (`write_surface._formStrokes`), never for scoring. `LetterResult` is binary `{passed, mistakeId}` — no per-criterion structure `[VERIFIED: codebase]` |
| 4. Structured output → coaching contract | ◐ PARTIAL | The strokeDiff transport EXISTS end-to-end: `computeStrokeDiff` (device) → `TutorFacts.strokeDiff` → `StrokeDiffIn` (server, extra="forbid", point-free) → `COACH_STROKE_ADDENDUM` appended when present (anti-parroting + name-the-specific-geometry, spike-validated). What's MISSING: the diff is a free-standing geometry description, not the scorer's per-criterion result (zones/scores/weakest criterion); nothing ties the coach's input to what the verdict actually failed on `[VERIFIED: codebase]` |
| 5. Calibration harness upgrade | ❌ NOT STARTED | Harness runs real `scoreLetter` over synthetic labeled fixtures, asserts good→PASS / named-bad→expected MistakeId, prints FP/FN confusion table. No threshold FITTING, no per-form dimension, baa-only fixtures `[VERIFIED: codebase]` |
| 6. Cutover (retire image judge as owner) | ❌ NOT STARTED — path fully live | Client: `write_surface._renderStrokesToBase64Png` (baa-only, trace) → `exercise_scaffold` `aiJudge = strokeImage != null` DEFERS the verdict to `decision.verdict` (AI can overrule a scorer fail). Server: `main.py` `if facts_in.strokeImage:` short-circuit → `image_judge.judge_baa_image` → `CoachOut.verdict`. All on deployed rev 00020 `[VERIFIED: codebase + memory]` |
| 7. Per-form refs for 25 letters | PARALLEL / deferred | `letters.json`: contextualForms with real points exist for alif/baa/taa ONLY (3/28); commonMistakes 28/28; baa initial/medial/final form-level `signedOff:false` (pending mom) `[VERIFIED: letters.json inspection]` |

**Per-form reference inventory (baa/taa, the D-E proof set)** `[VERIFIED: letters.json]`:
baa — isolated: bowl(12pts)+dot; initial: head(9)+dot; medial: tooth(8)+dot; final: bowl_tail(11)+dot.
taa — same skeletons with dot1+dot2 (3 strokes). alif — one 5-pt vertical line in all 4 forms.
All body strokes `direction: rightToLeft`, dots `type:'dot', direction:'tap'`.

## Architecture Patterns

### System Architecture Diagram (target state after this phase)

```
              CHILD'S STYLUS (iPad / Pixel Tablet)
                        │  List<List<Offset>> (pixel space, no timestamps)
                        ▼
   StrokeCanvas ──▶ WriteSurface._onLetterComplete
                        │
        ┌───────────────┴────────────────────────────────┐
        │ ON-DEVICE (pure Dart — strokes NEVER leave)     │
        │                                                 │
        │  resolve per-form reference                     │
        │  (contextualForms[surface.guideForm]            │
        │   ?? letter.referenceStrokes)                   │
        │            │                                    │
        │            ▼                                    │
        │  scoreLetter(strokes, letter, form: …)          │
        │   1 COUNT (firm)                                │
        │   2 ORDER (firm, spatial dot classify)          │
        │   3 SHAPE  = shapeDistance vs per-form ref      │
        │             → SoftBand zone (CC/fuzzy/CW)       │
        │   4 DIRECTION (criterion, softened)             │
        │   5 DOT (count + above/below, combined bbox)    │
        │   + advisory ML-Kit identity (reject-only)      │
        │            │                                    │
        │            ▼                                    │
        │  LetterScore (NEW structured result):           │
        │   { passed, mistakeId,                          │
        │     criteria: [{name, zone, score}…],           │
        │     weakest }                                   │
        │            │                                    │
        │  verdict applied INSTANTLY (scorer reflex,      │
        │  GROUND-01 restored) + star/clean-rep gate      │
        │            │                                    │
        │  computeStrokeDiff(strokes, per-form ref)       │
        │  (point-free derived diff — existing)           │
        └────────────┼────────────────────────────────────┘
                     │  TutorFacts{…, strokeDiff, criteria…}   ← ONLY derived facts cross
                     ▼                                          (extra="forbid" both sides)
        POST /coach (Firebase ID token + App Check)
                     │
        LangGraph graph: analyze → plan → coach
                     │            (G5/G6 curriculum rail)
                     ▼
        coach node: COACH_PROMPT + STROKE_ADDENDUM
          G3 verdict lock (never advance-on-fail)
          G4 curriculum membership
                     │
                     ▼
        CoachOut{toolName, args, grounded}  — NO verdict field used
                     │                        (image-judge path retired)
                     ▼
        Bubble text + TTS  (offline/timeout → AuthoredFallback floor;
                            verdict already rendered — nothing blocks)
```

The failure-path is structural: if the server is cold, slow, offline, or degraded, the child
already has the verdict + the authored floor line. Cold-start F2 stops being a verdict bug
by construction — the AI round-trip only enriches the words.

### Recommended file-touch map

```
lib/core/scoring/
├── shape_match.dart            # done — consumed, not modified (unless SoftBand needs per-criterion presets)
├── geometric_stroke_scorer.dart# inc 2: shapeDistance replaces chord proxy; soft verdict
├── letter_scorer.dart          # inc 3: per-form reference param + 5-criteria + structured result
├── scoring_models.dart         # inc 3: LetterScore / CriterionResult types (extend, don't break LetterResult callers)
└── tolerances.dart             # inc 2/3: carry SoftBand (tcc/tcw) knobs as data (preset + overrides idiom)
lib/core/exercise_engine/
└── exercise_validator.dart     # inc 3: _validateGlyph passes the FORM (Surface.guideForm) into scoreLetter
lib/features/letter_unit/widgets/
├── write_surface.dart          # inc 6: retire _renderStrokesToBase64Png/onStrokeImage; diff vs per-form ref (already does)
└── exercise_scaffold.dart      # inc 6: delete aiJudge deferral — scorer verdict instant again; facts carry criteria
lib/tutor/
├── stroke_diff.dart            # inc 4: (option) fold per-criterion result in, or leave as-is alongside
├── tutor_facts.dart            # inc 4: add criteria field (mirror server byte-for-byte)
└── tutor_facts_builder.dart    # inc 4: thread the structured result
server/app/
├── schema.py                   # inc 4: criteria field on TutorFactsIn (additive, server FIRST); later remove strokeImage (client first!)
├── main.py                     # inc 6: retire the strokeImage short-circuit
├── prompts.py                  # inc 4: addendum names the failed criterion; F3 English-primary constraint
├── nodes/coach.py              # inc 4: unchanged guards; addendum trigger reads criteria too
├── faithfulness.py             # EVAL-03: stays as the fast lexicon FLOOR (not the gate for varied lines)
└── image_judge.py              # inc 6: delete, or demote to advisory corroborator (never owner)
server/tests/test_eval/
├── run_eval.py                 # EVAL-03: + semantic faithfulness leg, + no-false-geometry, + specificity/variety
├── run_judge.py                # EVAL-03: judge rubric extensions (judge = gemini-2.5-flash ≠ coach)
└── gold_set.jsonl              # EVAL-03: regrown for stroke-level coaching; mom re-signs
test/core/scoring/
├── calibration_harness_test.dart  # inc 5: per letter × form; FIT tcc/tcw from labelled distributions
└── calibration_fixtures/          # inc 5: per-form fixtures (synthetic seed now; child captures later)
docs/architecture/
└── ADR-0XX-….md                # GROUND-04 ADR (see Open Questions on numbering)
```

### Pattern 1: Soft multi-criteria verdict (Hamdi TCC/TCW scheme — the F2 false-fail fix)

**What:** each criterion produces a distance/score → `SoftBand.zoneFor` → three zones. The
letter FAILS only when some criterion is `certainlyWrong` (or a FIRM check — count/order —
fails). `fuzzy` passes (the tolerant middle for a shaky-but-correct child). The weakest
criterion (lowest score) is the coaching target even on a pass.
**When to use:** SHAPE and DIRECTION (and any future position/kinematics criteria). NOT for
COUNT/ORDER (CONTEXT keeps them firm) and NOT for the dot side check (identity-bearing —
a dot above baa is taa; keep it a firm categorical check, softness applies to geometry not
to identity `[CITED: TUTOR-RESEARCH-FINDINGS F7]`).
**Example (target shape for increment 3's result type):**

```dart
// Source: derived from shape_match.dart (in-repo, verified) + TUTOR-RESEARCH-FINDINGS F1/F2
class CriterionResult {
  final String name;        // 'shape' | 'direction' | 'strokeOrder' | 'strokeCount' | 'dot'
  final ShapeZone zone;     // certainlyCorrect | fuzzy | certainlyWrong
  final double score;       // SoftBand.scoreFor(distance) — 1.0..0.0
  const CriterionResult({required this.name, required this.zone, required this.score});
}

class LetterScore {          // superset of today's LetterResult — keep passed/mistakeId
  final bool passed;         // false iff any firm check fails OR any soft criterion is certainlyWrong
  final MistakeId? mistakeId;
  final List<CriterionResult> criteria;
  final CriterionResult? weakest;  // the coaching target
}
```

Keep `LetterResult` (or make `LetterScore` carry the same two fields) — `feedbackForMistake`,
`exercise_validator._mapMistake`, and the MistakeId-enum-name == `commonMistakes[].check`
contract all depend on the existing shape `[VERIFIED: codebase]`.

### Pattern 2: Per-form reference resolution (fixes UAT F5 form-blindness at the SCORER)

**What:** the same resolution `write_surface` already uses for guide painting must reach the
scorer: `contextualForms[form]?.referenceStrokes` (when non-empty) else `letter.referenceStrokes`;
tolerances resolution gains a per-form layer: override → `form.tolerances` → `letter.tolerances`
→ `Tolerances.normal`. The `Form` model already carries per-form `commonMistakes` + optional
`tolerances` `[VERIFIED: lib/models/letter.dart]`.
**Where the form comes from:** `Surface.guideForm` (trace mode) and the exercise's
positional-form expectation (`_checkPositionalForm` in the validator). `_validateGlyph` is the
single call site to widen (`scoreLetter(strokes, letter)` → pass the form).
**Watch out:** write-mode has NO painted guide but still has an asked form — the validator, not
the surface, must own form resolution for scoring.

### Pattern 3: Two-sided wire contract change under `extra="forbid"` (the 422 lockstep)

**What:** both DTOs (`TutorFactsIn` ↔ `TutorFacts.toMap()`) must mirror byte-for-byte.
**Deploy ordering is DIRECTIONAL** `[VERIFIED: codebase comments + STATE history]`:
- ADDITIVE field (e.g. `criteria`): server ships FIRST (optional with default), client follows.
- REMOVAL (retiring `strokeImage`): client stops SENDING first; the server field is deleted
  only after no live client emits it (else every old-client request 422s). Since `strokeImage`
  is optional server-side, leaving the field parked (ignored) during the demo window is safe;
  delete in the same phase once the client cutover is confirmed on-device.
Both non-PII guard tests must be extended in the same task as the field change
(`payload_nonpii_test.dart` whitelist ∪ nested-key sets; `test_payload_nonpii.py`).

### Pattern 4: Verdict cutover (increment 6) — the exact seams

Client `exercise_scaffold._onResult`: delete the `aiJudge = strokeImage != null` branch — the
scorer verdict applies instantly for every path (restores GROUND-01 semantics + kills the
flash-then-overwrite problem the deferral existed to hide). `_recordAttempt` returns to
scorer-verdict-driven. `write_surface`: remove the baa-only PNG render + `onStrokeImage` wiring.
Server `main.py`: remove the `if facts_in.strokeImage:` short-circuit; `CoachOut.verdict`
becomes unused (removable server-side immediately — response extras are the server's to drop,
but check the Dart `_parseCoachOut` tolerates a missing `verdict` key — it must, since the
normal path never had one) `[VERIFIED: codebase]`. `image_judge.py`: delete or clearly demote
to advisory-only (CONTEXT permits "advisory corroborator, never the owner" — recommend DELETE
for the demo: an advisory image call re-opens the GROUND-02 image reversal the phase is
closing, and F6 findings say the image representation was the worst performer anyway
`[CITED: SPIKE-FINDINGS H3]`).

### Pattern 5: Semantic faithfulness gate (EVAL-03) — floor + ceiling

**What:** keep `faithfulness.py`'s praise-lexicon as the zero-tolerance model-free FLOOR
(praise-on-fail detection still works on varied lines); RETIRE the expected-fix SUBSTRING rule
as the gate for varied/stroke-aware coaching (spike: it false-flags paraphrases — measured
0.55–0.73 "rate" with ZERO real contradictions). Add two judge-based legs under `make eval`:
(a) semantic verdict-agreement ("does the line's meaning contradict the verdict / fail to
address the failed criterion?"), (b) **no-false-geometry** ("is every geometric claim in the
line supported by the strokeDiff/criteria facts sent?") — the spike's `adv_broken_but_pass`
case (model invented "a deep, smooth bowl" on a flat-bowl pass) is the canonical trap case.
**Measurement of STRK-01's "beats the label-only baseline":** reuse the spike's design — run
the same fixture set through the coach WITH and WITHOUT strokeDiff/criteria and score
(i) specificity (names a localized geometric fact), (ii) variety (distinct lines across distinct
attempts — a duplicate/verbatim-exemplar detector is model-free), (iii) grounding (must be 0
violations in BOTH arms). The spike harness in `.planning/spikes/_lib/` (fixtures.py,
representations.py, scoring.py) is reusable raw material `[VERIFIED: dir listing]`.

### Anti-Patterns to Avoid

- **Letting the LLM see a blank verdict to fill** — D-B forbids it; the coach receives
  `passed` + criteria as frozen FACTS (the existing G3 guard stays).
- **Per-letter prompt branches** — form-awareness must come from curriculum data (G2/G5);
  the addendum + rubric are letter/form-parameterized, never hardcoded per letter.
- **Hard thresholds in code** — D-D: tcc/tcw are data (Tolerances/letters.json idiom), the
  in-code `SoftBand.shapeDefault` is a fallback default only.
- **Re-implementing the scorer in Python for the eval** — the calibration harness runs the
  REAL Dart `scoreLetter` (A3, recorded decision).
- **Tuning thresholds on the synthetic fixtures** — synthetic strokes are too smooth; they
  pin the regression contract only. Real child captures + mom labels set production values
  (recorded Pitfall from Phase 4).
- **Softening COUNT/ORDER or the dot-side check** — identity-bearing; CONTEXT keeps them firm.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Shape distance | A new curve metric | `shapeDistance` (in-repo DTW, done) | Validated metric (F4); already tested |
| Soft zoning | Ad-hoc if/else bands | `SoftBand` (in-repo) | Hamdi TCC/TCW scheme, one place to calibrate |
| Resample/normalize | New geometry utils | `resample` + `normalizeToUnitBox` (`stroke_resampler.dart`) | Shared with scorer + shape-match; unit-box convention already fixed (zero-width axis → 0.5) |
| Dot classification | Point-count heuristics | `_classifyChildDots` spatial-extent rule (in `letter_scorer.dart`) | Fixed on-device bug 0444dd5; F7 says spatial, not count |
| Letter identity | Custom CNN | Existing advisory ML-Kit gate | F6; validated, advisory-only |
| Faithfulness floor | New praise detector | `faithfulness.py` `_PRAISE` lexicon | Keep as floor; only the gate goes semantic |
| Judge runner | New Vertex plumbing | `run_judge.py` + `make eval` env-swap | Judge ≠ coach already enforced; 0.7 calibration bar established |
| Specificity/variety fixtures | New synthetic strokes from scratch | Spike `_lib/fixtures.py` perturbations of the real authored baa reference | Already validated against the production prompt/tools |

**Key insight:** the phase's genuinely NEW code is small — the per-criterion result type, the
per-form scoring path, threshold-fitting in the harness, and eval legs. Everything else is
re-wiring validated pieces.

## Runtime State Inventory (cutover/migration concerns)

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Deployed service | Cloud Run `qalam-tutor` rev 00020 (project qalam-app-bd7d0, us-central1, keyless Vertex) currently runs the image-judge short-circuit + strokeDiff addendum | Re-deploy after server changes; observe removal ordering (Pattern 3). min-instances=0 when idle — warm before device UAT `[VERIFIED: memory + main.py]` |
| Wire contract | `strokeImage` + `CoachOut.verdict` live on both sides | Client stops sending first; server field removal second; `verdict` response field drop needs `_parseCoachOut` tolerance check |
| Gold set | `gold_set.jsonl` 10 cases, all `signed:false`, drafted for LABEL-only coaching | Regrow for stroke-level coaching; mom re-signs (EVAL-03 acceptance); nothing unsigned ships |
| Provisional thresholds | `SoftBand.shapeDefault(0.10, 0.15)` from synthetic variants | Ship for demo labeled PROVISIONAL; production gate = mom-labelled calibration (deferred) |
| Curriculum sign-off flags | baa letter-level `signedOff:true`; baa initial/medial/final FORM-level `signedOff:false`; alif all false | Per-form scoring may run on unsigned forms for the demo (guides already do); flag for mom's sign-off queue — do NOT flip flags autonomously (Pitfall: 15-07 human-verify precedent) |
| Known-failing tests | 9 pre-existing full-suite failures: 3 font-drift goldens, alif_reference, all_letters_validation, meet_section, write_surface, curriculum_repo_v2 | Baseline noted so the phase's verification doesn't chase them; do NOT re-bake goldens (memory) — but note `write_surface` test is IN this phase's touch set: it must not be left worse |
| Git state | Working branch is `gsd/phase-16-…`; Phase 16 paused at 6 human gates | Phase 17 needs its OWN branch (memory: branching_strategy "none" silently uses the checked-out branch) |
| Secrets/env | None change; keyless ADC throughout | None |
| Build artifacts | None affected | None |

## Common Pitfalls

### Pitfall 1: The 422 lockstep trap (hit before, twice)
**What goes wrong:** one side ships a wire field without the other → every /coach call 422s →
silent degrade to the authored floor everywhere.
**How to avoid:** Pattern 3 ordering; extend BOTH non-PII guard tests in the same task; the
Dart mirror-field-set assertions (3 exact-mirror tests, extended 8→10 fields in 15-04) must be
extended again for `criteria`.
**Warning signs:** on-device coaching suddenly all-authored; server logs show ValidationError.

### Pitfall 2: Breaking the MistakeId ↔ commonMistakes[].check naming contract
**What goes wrong:** the enum-value names parallel the authored `check` strings; l10n and
authored feedback resolution key off them. New per-criterion outputs that rename or bypass
`mistakeId` break authored-feedback resolution and the calibration harness's
`_expectedRejection` map.
**How to avoid:** `LetterScore` CARRIES `mistakeId` unchanged; criteria are additive.

### Pitfall 3: Soft-verdict scope creep into firm checks
**What goes wrong:** making COUNT/ORDER/dot-side fuzzy "for consistency" lets a taa pass as
baa (identity error) or a dot-first order pass.
**How to avoid:** CONTEXT D-C is explicit — firm count/order stay; soften geometry only.

### Pitfall 4: Tuning tcc/tcw against synthetic strokes
**What goes wrong:** synthetic strokes are unnaturally smooth → thresholds too strict → the
F2 false-fail returns on real children.
**How to avoid:** synthetic values ship labeled PROVISIONAL (D-D); harness upgrade FITS from
labelled distributions but the fixtures stay a regression seed until real child captures land.
FN-over-FP priority (a child who tried should rarely be told they failed) is the recorded
Phase-4 tuning rule.

### Pitfall 5: The eval gate blocking varied coaching before it's upgraded
**What goes wrong:** ship increments 4/6 with the substring gate still gating → correct
paraphrases fail `make eval` → false regression alarms.
**How to avoid:** sequence the EVAL-03 semantic upgrade BEFORE or WITH the coaching-contract
change; the model-free D1 praise-lexicon leg keeps gating throughout.

### Pitfall 6: Deferred-verdict remnants after cutover
**What goes wrong:** leftover `aiJudge`/`applyVerdict`/`decision.verdict` paths half-removed
→ verdict applied twice or star driven by a stale AI verdict.
**How to avoid:** cutover task enumerates all four seams (write_surface render, scaffold
deferral, main.py short-circuit, CoachOut.verdict) with a grep-guard test that `strokeImage`
no longer appears in `lib/` payload construction.

### Pitfall 7: `onLetterComplete` fires at reference-stroke-count
**What goes wrong:** the canvas auto-completes when the child's stroke count REACHES
`referenceStrokes.length` `[VERIFIED: stroke_canvas.dart]` — with per-form references the
expected count comes from the FORM's strokes (taa medial = 3), so passing the wrong reference
set to the canvas vs the scorer desynchronizes completion and COUNT.
**How to avoid:** one resolution function for "the reference strokes for this exercise,"
shared by canvas, diff, and scorer.

### Pitfall 8: Gemini structured-output / latency knobs (server work only)
Known in-repo: `thinking_budget=0` is load-bearing for Vertex Gemini structured replies;
`/healthz` never reaches the container (use `/health`); building the model client per-request
is the F2 cold-start bug (singleton + lifespan warm-up if any warm-up work is done this phase).
Under D-A these affect only coaching richness, not the verdict `[VERIFIED: AI-SPEC §3 + main.py]`.

### Pitfall 9: Kinematics criterion has no data source yet
`StrokeCanvas` captures `List<List<Offset>>` — NO timestamps `[VERIFIED: stroke_canvas.dart]`.
A true kinematics criterion (speed/fluency, F1's 5th criterion) needs capture-layer change
(PointerEvent timestamps). See Open Questions — recommend descoping to the 4 geometric criteria
+ dot for this phase unless the planner adds a small capture extension.

## Code Examples

### Existing shape-match API (consume as-is)
```dart
// Source: lib/core/scoring/shape_match.dart (verified in-repo, tests green)
final d = shapeDistance(childStroke, formReference.points); // 0.0 = identical, ∞ = degenerate
final band = SoftBand.shapeDefault;                         // PROVISIONAL (0.10, 0.15)
switch (band.zoneFor(d)) {
  case ShapeZone.certainlyCorrect: // pass outright
  case ShapeZone.fuzzy:            // tolerant middle — PASS (the F2 fix)
  case ShapeZone.certainlyWrong:   // fail → mistakeId for this criterion
}
final score = band.scoreFor(d);    // 1.0 → 0.0 linear across the fuzzy band
```

### Existing derived-diff payload keys (client mirrors server byte-for-byte)
```python
# Source: server/app/schema.py StrokeDiffIn (verified in-repo, deployed)
# summary, strokeCount, bodySegments, bowlDepthRatio, bowlDepthVerdict, bowlSymmetry,
# sizeVerdict, directionChild, directionReference, tailPresent, dotPresent,
# dotHorizontal, dotVertical, dotPlacementOk     — all Optional, point-free, extra="forbid"
```

### Threshold-as-data idiom to extend (Tolerances pattern)
```dart
// Source: lib/core/scoring/tolerances.dart (verified) — extend with soft-band knobs, e.g.:
// { "preset": "normal", "overrides": { "shapeTcc": 0.10, "shapeTcw": 0.15 } }
// Resolution order stays: explicit override → form.tolerances → letter.tolerances → normal.
```

### Eval gate commands (verified runnable this session)
```bash
# model-free leg (gates every PR) — 78 passed, 1 skipped in 0.48s on 2026-07-05:
cd server && uv run pytest -m code -q
# full pre-merge gate (needs Vertex ADC):
cd server && make eval
# scorer suite — 66/66 green in ~2s on 2026-07-05:
flutter test test/core/scoring/
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Chord-curvature proxy (`maxCurvature` ceiling, tuned for alif) | DTW `shapeDistance` vs per-form reference | This phase (core landed 4e71d6b) | Shape is actually compared to the asked form; fixes false-fail + form-blindness at the metric level |
| Hard pass/fail predicates | Soft 3-zone bands (CC/fuzzy/CW), continuous score | This phase | Shaky-but-correct child passes (F2 fix) without going blind to real errors |
| AI image-judge owns baa verdict (17.1, rev 00020) | Deterministic on-device scorer owns verdict; LLM coaches only | This phase (D-A) | Offline/instant/$0 verdict; VLM counting weakness removed from the trust path (F9/F10); GROUND-01 restored; image-off-device consent debt shrinks |
| mistakeId label-only coaching input | Derived strokeDiff + structured per-criterion result | strokeDiff landed 09d2cde; criteria this phase | Attempt-specific, varied, localized coaching (STRK-01) |
| Substring faithfulness gate | Lexicon floor + semantic judge gate + no-false-geometry | This phase (EVAL-03) | Varied coaching stops false-flagging; invented geometry caught |

**Deprecated/outdated by this phase:** `image_judge.py` as verdict owner; `CoachOut.verdict`;
`TutorFactsIn.strokeImage` (after client cutover); AI-SPEC §1/§4 verdict framing (already
marked superseded in the doc).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The next free ADR number is 016 or 017 (ADR-014/015 exist on disk; "ADR-016" is verbally reserved for the Phase-16 coach bake-off per STATE) | Open Questions / file-touch map | Numbering collision — trivial to fix at plan time `[ASSUMED]` |
| A2 | The demo can run per-form scoring on baa forms whose FORM-level `signedOff` is false (guides already do this since ba3923c) | Runtime State Inventory | If the owner wants sign-off-gated scoring, the medial/final proof waits on mom `[ASSUMED — owner call]` |
| A3 | Kinematics can be descoped (or approximated) this phase without violating D-C's "5 criteria" intent, since capture has no timestamps | Pitfall 9 / Open Questions | If the owner insists on true kinematics, a capture-layer change enters scope `[ASSUMED — needs confirmation]` |
| A4 | The spike's specificity/variety scoring approach (distinct-line counting + judged localization) is acceptable as STRK-01's "measurably beats baseline" instrument | Validation Architecture | Owner may want a different metric definition `[ASSUMED]` |
| A5 | `image_judge.py` should be deleted rather than kept advisory (image was the worst spike arm; keeping it re-opens the consent reversal) | Pattern 4 | If the owner wants it as a corroborator, keep behind a flag — CONTEXT permits either `[ASSUMED — recommend delete]` |

## Open Questions

1. **ADR numbering + scope** — one ADR covering both the GROUND-02 softening (derived diff
   crosses the wire — required by GROUND-04 acceptance) and the D-A un-reversal (scorer owns
   verdict again; image path retired), or two? What we know: ADR-014/015 exist; ADR-016 is
   informally reserved (16-06 bake-off). Recommendation: a single Phase-17 ADR at the next
   free number covering the verdict-authority decision + the derived-diff data flow, since
   they are one architectural story; verify the number at plan time.
2. **Kinematics criterion (the 5th of F1's five)** — no timestamps in capture.
   Recommendation: score shape/direction/order/count + dot this phase (all data available);
   record kinematics as a follow-up needing `PointerEvent.timeStamp` capture; per-point
   spacing at fixed sampling rate is a weak proxy — don't fake it.
3. **"Position" criterion definition** — Hamdi's position = placement vs reference lines. In
   trace mode child strokes and the painted guide share pixel space, so raw-space offset IS
   computable pre-normalization. Recommendation: treat position as the existing relative
   checks (dot above/below via combined bbox — already firm) + optionally a body-vs-guide
   offset in trace mode; don't over-engineer for write mode (no guide exists).
4. **Phase-16 open human gates** — Phase 17 nominally executes after 16 closes; 16 is paused
   at 6 human/hardware gates. What's unclear: whether the owner wants 17 planned/executed on
   its own branch in parallel. Recommendation: plan 17 now (this research), branch fresh, and
   flag the dependency at execution kickoff.
5. **F1 (RTL rendering of English helper lines) and F6 (word-path coaching depth)** — both in
   the UAT punch-list this phase must fix, both outside the scorer core. F1 is a small
   bidi/textDirection UI fix; F6 needs the word path's derived facts enriched (recognized
   `writtenWord` vs expected — derived, non-PII) so the coach can say something specific.
   Recommendation: include as small tasks in the coaching-contract plan; word-fact enrichment
   follows the same 422-lockstep pattern.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter / Dart SDK | scorer + client work, all Dart tests | ✓ | 3.41.9 / 3.11.5 | — |
| uv (Python runner) | server tests, `make eval` | ✓ | 0.11.19 | — |
| Python | server runtime (≥3.12 required) | ✓ | 3.14.6 | — |
| gcloud SDK | Cloud Run re-deploy, ADC for judge legs | ✓ | 573.0.0 | — |
| Vertex AI ADC credentials | `make eval` judge legs, live /coach | not verified this session | — | model-free legs (`-m code`) run without it; judge legs deferred until ADC present |
| Physical tablet (iPad/Pixel) | on-device UAT of cutover + F1–F6 fixes | ✗ (human gate) | — | widget/unit tests + emulator; device verification is an end-of-phase human gate (Phase-07 memory: device bugs invisible to widget tests) |
| Owner's mother | gold-set re-sign (EVAL-03), per-form sign-off, calibration labels | ✗ (human gate) | — | Provisional/synthetic values shipped clearly labeled; sign-off items queue in HUMAN-UAT |

**Missing dependencies with no fallback:** none for the autonomous build. Device + mother
gates are end-of-phase human checkpoints, not build blockers.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Frameworks | flutter_test (Flutter 3.41.9) — client/scorer; pytest ≥8 via uv — server (`-m code` marker = model-free PR gate) |
| Config files | `pubspec.yaml` + `test/flutter_test_config.dart` (Arabic font loading); `server/pyproject.toml` (`[tool.pytest.ini_options]`, asyncio auto, `code` marker); `server/Makefile` (`eval` / `eval-code` / `eval-judge`) |
| Quick run command | `flutter test test/core/scoring/` (66 tests, ~2 s — verified green 2026-07-05) · `cd server && uv run pytest -m code -q` (78 passed, 1 skipped, 0.48 s — verified green 2026-07-05) |
| Full suite command | `flutter test` (⚠ 9 known pre-existing failures — see baseline below) · `cd server && make eval` (needs Vertex ADC) |

**Full-suite baseline (do not chase, do not worsen):** 3 font-drift goldens (never re-bake),
`alif_reference`, `all_letters_validation`, `meet_section`, `write_surface`, `curriculum_repo_v2`.
`write_surface` is IN this phase's touch set — its pre-existing failure must be reconciled or
explicitly re-baselined in the plan, not silently absorbed.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STRK-01 | Stroke-aware coaching beats label-only baseline on specificity + variety, grounding intact (0 advance-on-fail, 0 praise-on-fail) | eval (model-free variety/duplicate leg + Vertex-judge specificity leg, two-arm baseline comparison) | `cd server && uv run pytest tests/test_eval -m code -q` (variety/duplicate + grounding legs) · `make eval` (judged legs) | ❌ Wave 0 — new legs in `run_eval.py` + fixtures; grounding zero-tolerance leg exists (D1) ✅ |
| STRK-01 (transport) | strokeDiff/criteria reach the coach; addendum activates; no exemplar parroting | unit (server) | `cd server && uv run pytest tests/test_grounding.py tests/test_endpoint.py -m code -q` | ✅ partial (addendum trigger); ❌ criteria-field tests Wave 0 |
| GROUND-04 | No raw stroke coordinates / PII in any payload; whitelist mirrors byte-for-byte; extras 422 | unit (both sides) | `flutter test test/tutor/payload_nonpii_test.dart` · `cd server && uv run pytest tests/test_payload_nonpii.py -m code -q` | ✅ exist — must be EXTENDED for `criteria` (and shrunk when `strokeImage` retires) |
| GROUND-04 (contract) | Client and server field sets match (no 422 window) | unit (mirror-set assertions) | `flutter test test/tutor/` (exact-mirror field-set tests) | ✅ exist — extend in lockstep task |
| GROUND-04 (ADR) | Softened GROUND-02 reversal recorded | human/doc gate | checklist item in VERIFICATION.md — file exists at `docs/architecture/ADR-0XX-*.md` | ❌ Wave/closing task |
| EVAL-03 | Semantic faithfulness gate (paraphrases not false-flagged) + no-false-geometry check | eval (Vertex judge leg + trap fixtures) | `cd server && make eval` — must include the `adv_broken_but_pass` false-geometry trap and paraphrase cases scoring FAITHFUL | ❌ Wave 0 — new judge legs + trap cases |
| EVAL-03 (floor intact) | Praise-lexicon zero-tolerance leg still gates (D1 == 100%) | unit (model-free) | `cd server && uv run pytest tests/test_faithfulness.py tests/test_eval/test_eval_harness.py -m code -q` | ✅ exists — must stay green throughout |
| EVAL-03 (gold set) | Regrown stroke-level gold set, `signed:true` by mom | human gate | grep `"signed": true` in `gold_set.jsonl` behind a human-verify checkpoint | ❌ human gate (mother) |
| D-A scorer (verdict correctness) | Per-form scoring: correct form passes, wrong form fails, shaky-correct passes, flat-line fails, per letter × form | unit + calibration harness (Dart) | `flutter test test/core/scoring/` — extended harness prints per letter × form confusion table; asserts good→PASS, named-bad→expected MistakeId, isolated-shape-for-medial-slot→FAIL (the F5 cell == 0, moved from the LLM eval to the Dart harness under D-A) | ◐ harness exists; per-form fixtures + form-confusion assertions Wave 0 |
| D-A cutover | Scorer verdict applies instantly on every path; no `aiJudge` deferral; `strokeImage` absent from payload construction | unit + grep-guard | `flutter test test/features/` + a payload grep-guard test | ❌ Wave 0 |
| UAT F1–F6 fixes | RTL English copy LTR (F1); form-blind fixed (F5 → harness above); coaching English-primary (F3 → eval register/language leg exists in run_eval D5); specific feedback (F4 → STRK-01 legs); word-path coaching (F6) | mixed | existing E4/register leg under `make eval`; F1 widget test; F6 server test on word facts | ◐ partial |

### Sampling Rate

- **Per task commit:** `flutter test test/core/scoring/ test/tutor/` + `cd server && uv run pytest -m code -q` (both < 30 s combined — verified)
- **Per wave merge:** `flutter test` (against the 9-failure baseline) + `cd server && make eval` (when ADC available; else `-m code` + defer judge legs to the phase gate)
- **Phase gate:** full `flutter test` reconciled to baseline + `make eval` green + on-device HUMAN-UAT items + mom sign-off gates recorded (some may remain open as documented production gates per D-D)

### Wave 0 Gaps

- [ ] `test/core/scoring/` — RED tests for `scoreStroke` soft-verdict via shapeDistance (inc 2): shaky-correct passes, flat-line fails, direction still a criterion
- [ ] `test/core/scoring/letter_scorer_test.dart` (extend) — per-form scoring + `LetterScore` per-criterion structure + weakest-criterion selection (inc 3)
- [ ] `test/core/scoring/calibration_fixtures/` — per-form baa fixtures incl. the F5 trap (isolated bowl offered for medial/final → FAIL) (inc 5)
- [ ] `test/core/scoring/calibration_harness_test.dart` (extend) — per letter × form dimension + threshold-fit report (inc 5)
- [ ] `test/tutor/payload_nonpii_test.dart` + mirror-set tests (extend) — `criteria` field; strokeImage removal (inc 4/6)
- [ ] `test/features/` cutover tests + strokeImage grep-guard (inc 6)
- [ ] `server/tests/` — `criteria` DTO tests (additive, defaults, 422 on extras) (inc 4)
- [ ] `server/tests/test_eval/` — semantic faithfulness leg, no-false-geometry trap cases, duplicate/variety detector, two-arm specificity baseline (EVAL-03/STRK-01)
- [ ] Framework install: none — all infrastructure exists

## Security Domain

`security_enforcement: true`, ASVS level 1 `[VERIFIED: .planning/config.json]`.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (unchanged) | /coach gated by Firebase ID token + App Check (`Depends(verify_caller)`) — existing, do not weaken |
| V3 Session Management | no | Stateless server (InMemorySaver, per-process); no sessions added |
| V4 Access Control | yes (unchanged) | Children never authenticate (D-09b); parent area PIN-gated — untouched by this phase |
| V5 Input Validation | **yes — the heart of GROUND-04** | Pydantic `extra="forbid"` on `TutorFactsIn`/`StrokeDiffIn`/nested DTOs; point-free-by-construction schema; two-sided guard tests |
| V6 Cryptography | no new | No new crypto; existing PIN PBKDF2 untouched |
| V8 Data Protection (child data / COPPA) | **yes** | Derived-only facts cross the wire; retiring `strokeImage` REDUCES the off-device child-data surface (a rendered handwriting image stops leaving the device) — the phase is a net privacy improvement; learner-model expansion (G8) stays out of scope |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Raw stroke/PII leakage via new wire fields | Information Disclosure | Point-free DTO schema + `extra="forbid"` + both non-PII guard tests extended with every field change |
| Prompt injection via recognized text (`writtenWord`, if added for F6) | Tampering | Treat recognized text as data in the HumanMessage (never system prompt); it is child handwriting, not free text — low risk, but keep the closed 4-tool action lock + G3/G4 guards as the backstop |
| Verdict spoofing by the model | Tampering / Elevation | Structural: verdict computed on-device before any model call; server guards (G3) rewrite advance-on-fail; `CoachOut.verdict` removed so no response field can carry a verdict |
| Eval-gate bypass (unsigned content shipping) | Repudiation | `signed:false` items never ship as gates; sign-off flips only behind human-verify (15-07 precedent) |
| Child-data in logs/traces | Information Disclosure | Server logs derived diff only (`exclude_none`, explicitly non-PII — existing pattern in main.py); keep it that way for `criteria` |

## Sources

### Primary (HIGH confidence)
- `docs/architecture/TUTOR-RESEARCH-FINDINGS.md` — the cited scorer spec (F1–F11; Hamdi et al. 2022 MTAP 81:43411, Guest 2004, Sci. Reports 2025, arXiv 2510.04401 et al.) — the phase's evidence base, adversarially fact-checked per its header
- `17-CONTEXT.md` — locked decisions D-A…D-F + build increments
- Direct codebase reads (this session): `lib/core/scoring/*` (all 6 files), `lib/tutor/{stroke_diff,tutor_facts,tutor_facts_builder}.dart`, `lib/features/letter_unit/widgets/{write_surface,exercise_scaffold}.dart`, `lib/core/exercise_engine/exercise_validator.dart`, `lib/features/practice/widgets/stroke_canvas.dart`, `lib/models/letter.dart`, `server/app/{main,schema,prompts,faithfulness,image_judge}.py`, `server/app/nodes/coach.py`, `server/tests/test_eval/{run_eval.py,gold_set.jsonl}`, `server/Makefile`, `server/pyproject.toml`, `assets/curriculum/letters.json`, both guard tests
- Test runs (this session): `flutter test test/core/scoring/` 66/66 green; `uv run pytest -m code -q` 78 passed / 1 skipped
- `.planning/spikes/SPIKE-FINDINGS.md` — H1–H5 verdicts (~375 live Vertex calls), the geo_diff GATE + eval-upgrade precondition

### Secondary (MEDIUM confidence)
- `17-AI-SPEC.md` — eval §5 (E1–E8), Vertex/coaching guidance, cold-start fix pattern (its §1/§4 verdict stance superseded per CONTEXT)
- `docs/testing/UAT-FULL-2026-07-01.md` — F1–F6 punch-list + full-suite failure baseline
- `.planning/STATE.md` + project memory — deployment state (rev 00020, keyless Vertex), branch discipline, goldens font drift, executor commit constraints

### Tertiary (LOW confidence)
- ADR numbering availability (A1) — inferred from directory listing + STATE mention of a reserved "ADR-016"; confirm at plan time

## Metadata

**Confidence breakdown:**
- Current-state inventory: HIGH — every claim read from source and cross-checked against git log; both suites executed
- Scorer upgrade design: HIGH — locked by CONTEXT + the cited findings; APIs verified
- Eval upgrade design: HIGH for direction (spike-measured), MEDIUM for the exact specificity/variety metric definition (A4)
- Pitfalls: HIGH — nearly all are recorded, previously-hit failure modes in this repo

**Research date:** 2026-07-05
**Valid until:** ~2026-08-05 for the external findings; the CURRENT-STATE sections go stale with any commit to `lib/core/scoring/`, `lib/tutor/`, or `server/app/` — re-verify increment status at execution start
