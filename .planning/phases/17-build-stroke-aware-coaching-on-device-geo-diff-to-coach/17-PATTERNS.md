# Phase 17: Tutor Redesign — grounded, form-aware, on-device scorer — Pattern Map

**Mapped:** 2026-07-05
**Files analyzed:** 24 new/modified files (across scorer-core, contract/coaching, cutover, eval, test, and doc tracks)
**Analogs found:** 21 / 24 (3 genuinely-new pieces have no in-repo analog — see "No Analog Found")

A distinguishing property of this phase: most files are MODIFIED, not created, so the primary
"analog" is usually the file itself — the pattern to copy is a specific existing idiom *inside*
(or beside) the file being changed. Every excerpt below was read from source this session.

## File Classification

| New/Modified File | Op | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|---|
| `lib/core/scoring/geometric_stroke_scorer.dart` | modify (inc 2) | service (scoring leaf) | transform | `lib/core/scoring/shape_match.dart` (consume) + itself | exact |
| `lib/core/scoring/letter_scorer.dart` | modify (inc 3) | service (orchestrator) | transform | itself + `write_surface._formStrokes` (per-form resolution) | exact |
| `lib/core/scoring/scoring_models.dart` | modify (inc 3: `CriterionResult`/`LetterScore`) | model | transform | `LetterResult` in same file | exact |
| `lib/core/scoring/tolerances.dart` | modify (inc 2/3: `shapeTcc`/`shapeTcw` knobs) | config-as-data | transform | itself (preset + overrides idiom) | exact |
| `lib/core/exercise_engine/exercise_validator.dart` | modify (inc 3: pass form into `scoreLetter`) | service (validator spine) | request-response | itself (`_validateGlyph` / `_checkPositionalForm` / `_mapMistake`) | exact |
| `lib/tutor/tutor_facts.dart` | modify (inc 4: `criteria`; inc 6: drop `strokeImage`) | model/DTO (wire mirror) | request-response | own `strokeDiff` field pattern | exact |
| `lib/tutor/tutor_facts_builder.dart` | modify (inc 4) | utility (non-PII chokepoint) | transform | own `strokeDiff` param threading | exact |
| `lib/tutor/stroke_diff.dart` | modify-or-leave (inc 4 option) | utility (derived geometry) | transform | itself | exact |
| `lib/features/letter_unit/widgets/write_surface.dart` | modify (inc 6 cutover + shared ref resolution) | component (surface) | event-driven | itself (seams pinned below) | exact |
| `lib/features/letter_unit/widgets/exercise_scaffold.dart` | modify (inc 6: delete `aiJudge` deferral) | component (page shell) | event-driven | itself (seams pinned below) | exact |
| `server/app/schema.py` | modify (inc 4 additive `criteria`; inc 6 removals) | model/DTO | request-response | own `StrokeDiffIn` + optional-field pattern | exact |
| `server/app/main.py` | modify (inc 6: remove short-circuit) | controller | request-response | itself (normal-path + logging pattern) | exact |
| `server/app/prompts.py` | modify (inc 4: criterion-aware addendum, F3) | config (prompt) | — | own `COACH_STROKE_ADDENDUM` | exact |
| `server/app/nodes/coach.py` | modify (inc 4: addendum trigger reads criteria) | service (graph node) | request-response | own trigger + G3/G4 guard pattern | exact |
| `server/app/image_judge.py` | DELETE (recommended) or demote | service | request-response | n/a — deletion; seams enumerated below | n/a |
| `server/app/faithfulness.py` | keep as floor (EVAL-03 re-scopes it) | utility (eval floor) | batch | itself | exact |
| `server/tests/test_eval/run_eval.py` | modify (EVAL-03/STRK-01 legs) | eval harness | batch | own `_score_judge_dimension` / `gate_passes` | exact |
| `server/tests/test_eval/run_judge.py` | modify (new judge dimensions) | eval harness | batch | own `judge_dimension` / `_build_prompt` | exact |
| `server/tests/test_eval/gold_set.jsonl` | regrow (mom re-signs) | fixture data | — | own header/`signed:false` convention | exact |
| `server/tests/` new `criteria` DTO tests | new | test (unit) | — | `server/tests/test_payload_nonpii.py` | exact |
| `test/core/scoring/calibration_harness_test.dart` | modify (per letter × form + fit report) | test (harness) | batch | itself (confusion table) | exact |
| `test/core/scoring/calibration_fixtures/calibration_fixtures.dart` | extend (per-form fixtures) | fixture | — | own `LabeledSample` + `shape_match_test.dart` perturbation | exact |
| `test/core/scoring/` new soft-verdict / per-form tests | new | test (unit) | — | `test/core/scoring/shape_match_test.dart` | exact |
| `test/tutor/payload_nonpii_test.dart` (+ mirror-set test) | modify | test (guard) | — | itself + `remote_agent_brain_test.dart:185-196` | exact |
| `test/features/` cutover tests + `strokeImage` grep-guard | new | test (guard) | — | `payload_nonpii_test.dart:234-267` source-scan pattern | role-match |
| `docs/architecture/ADR-016-or-017-*.md` | new | doc (ADR) | — | `docs/architecture/ADR-015-v2-tutor-server-langgraph-agent.md` | exact |

---

## Pattern Assignments

### 1. `lib/core/scoring/geometric_stroke_scorer.dart` (service, transform) — increment 2

**Analog:** `lib/core/scoring/shape_match.dart` (the API to consume) + the file's own predicate structure.

**Current structure to replace** — `scoreStroke` runs 3 hard first-failing predicates
(`geometric_stroke_scorer.dart:32-58`): `strokeLengthBelowThreshold` → `tooShort`,
`strokeDirectionInverted` → `wrongDirection`, `strokeCurvatureExceedsThreshold` (the chord
proxy, lines 134-157) → `tooCurved`. The chord proxy is what `shapeDistance` replaces.

**API to consume as-is** (`shape_match.dart:98-109` + `49-84`, tested green):

```dart
double shapeDistance(List<List<double>> childStroke, List<List<double>> referenceStroke, {int n = 32});
// 0.0 = identical; double.infinity for <2 points (pen-slip can't fake a match)

class SoftBand {
  final double tcc; final double tcw;
  static const SoftBand shapeDefault = SoftBand(tcc: 0.10, tcw: 0.15); // PROVISIONAL synthetic
  ShapeZone zoneFor(double distance);   // certainlyCorrect | fuzzy | certainlyWrong
  double scoreFor(double distance);     // 1.0..0.0 linear across the fuzzy band
}
```

**Keep intact:** the direction check (`strokeDirectionInverted`, lines 104-126 — stays a
criterion per D-C), the raw-point floor (lines 92-96), and the resample/normalize call
(lines 44-45: `normalizeToUnitBox(resample(childStroke, tolerances.resampleN))`) — note
`shapeDistance` resamples/normalizes internally, so don't double-normalize when delegating.

**Naming contract to preserve** (lines 67-81 + 92, 104, 134): predicate function names ==
`letters.json` `commonMistakes[].check` strings; `feedbackForMistake`'s `checkNames` map keys
off `MistakeId`. Any new criterion name enters this contract, not around it.

**Header convention for pure-Dart scoring code** (`shape_match.dart:1-27`): file-level doc
comment stating "Pure Dart, no dart:ui, no Flutter imports", the research citation, and WHY —
copy this register for all new scorer code.

---

### 2. `lib/core/scoring/letter_scorer.dart` (service orchestrator, transform) — increment 3

**Analog:** itself. The five-section first-failing structure is the skeleton to extend, not replace.

**Signature + tolerance-resolution idiom to widen** (`letter_scorer.dart:60-69`):

```dart
Future<LetterResult> scoreLetter(
  List<List<List<double>>> childStrokes,
  Letter letter, {
  HandwritingRecognizer? recognizer,
  Tolerances? tolerances,
}) async {
  final reference = [...letter.referenceStrokes]..sort((a, b) => a.order.compareTo(b.order));
  final resolvedTolerances = tolerances ?? letter.tolerances ?? Tolerances.normal;
```

The per-form change is exactly here: `reference` must come from
`letter.contextualForms?[form]?.referenceStrokes` (when non-empty) else
`letter.referenceStrokes`; tolerances resolution gains a layer:
`override → form.tolerances → letter.tolerances → Tolerances.normal`. The `Form` model
already carries both (`lib/models/letter.dart:103-134` — `Form{referenceStrokes,
commonMistakes, tolerances?}`), and the resolution idiom to copy already exists as a widget
getter (`write_surface.dart:163-170` `_formStrokes`) — hoist it into shared scoring code (see
Pitfall 7 in RESEARCH: canvas, diff, and scorer must share ONE resolution function).

**Checks to keep FIRM verbatim (D-C):** COUNT (lines 71-76), ORDER with spatial dot classify
(lines 87-93 + `_classifyChildDots` 136-144 — do NOT reinvent; it fixed a real device bug),
DOT side check (`_checkDots` lines 170-209, combined-bbox `_centroidY` relative position),
advisory `_identityGate` (lines 249-265, confidence floor 0.5, reject-only).

**Check to soften:** section 3 SHAPE (lines 95-104) currently propagates `scoreStroke`'s
first hard failure. Under increments 2-3 it becomes: per-criterion `shapeDistance` +
`SoftBand.zoneFor`, fail only on `certainlyWrong`, accumulate `CriterionResult`s instead of
early-returning on `fuzzy`.

**Security comment to preserve** (lines 23-25): "child points live only in local variables
here; nothing is printed, logged, or persisted." Keep this posture for criteria output.

---

### 3. `lib/core/scoring/scoring_models.dart` (model, transform) — increment 3

**Analog:** `LetterResult` in the same file (lines 38-52) — copy its factory + doc style:

```dart
class LetterResult {
  final bool passed;
  final MistakeId? mistakeId;
  const LetterResult({required this.passed, this.mistakeId});
  const LetterResult.fail(MistakeId id) : passed = false, mistakeId = id;
  const LetterResult.pass() : passed = true, mistakeId = null;
}
```

**Target shape** (from RESEARCH Pattern 1, verified compatible with the enum at lines 11-21):
`CriterionResult{name, zone, score}` + `LetterScore` as a SUPERSET carrying `passed` +
`mistakeId` unchanged (Pitfall 2: `feedbackForMistake`, `exercise_validator._mapMistake`, and
the calibration harness `_expectedRejection` all key off `mistakeId`; criteria are additive).
The `MistakeId` enum comment contract (lines 8-10: "enum value names intentionally mirror the
authored commonMistakes[].check strings") applies to any new ids.

---

### 4. `lib/core/scoring/tolerances.dart` (config-as-data, transform) — increments 2/3

**Analog:** itself — the preset + overrides idiom is exactly how `tcc`/`tcw` become data (D-D).

**The idiom to extend** (`tolerances.dart:44-60` presets; `83-99` fromJson):

```dart
factory Tolerances.fromJson(Map<String, dynamic> json) {
  final presetName = json['preset'] as String?;
  final base = _presets[presetName] ?? normal;          // unknown → normal, never throws
  final overrides = json['overrides'] as Map<String, dynamic>?;
  if (overrides == null) return base;
  final maxCurv = overrides['maxCurvature'] as num?;
  return Tolerances(..., maxCurvature: maxCurv?.toDouble() ?? base.maxCurvature);
}
```

Add `shapeTcc`/`shapeTcw` (and any direction-band knobs) as new fields with defaults equal to
`SoftBand.shapeDefault` (0.10/0.15), overridable via the same
`{"preset": "normal", "overrides": {"shapeTcc": 0.10, "shapeTcw": 0.15}}` JSON shape. Keep the
A5 rule: `normal` stays a behavior-preserving anchor; document each knob's rationale beside the
field (lines 16-31 show the register).

---

### 5. `lib/core/exercise_engine/exercise_validator.dart` (service, request-response) — increment 3

**Analog:** itself — `_validateGlyph` is the single call site to widen.

**The seam** (`exercise_validator.dart:97-118`):

```dart
Future<CheckResult> _validateGlyph(ExerciseSpec exercise, List<List<List<double>>> strokes,
    Letter? letter, {String? writtenForm}) async {
  final formMiss = _checkPositionalForm(exercise, writtenForm);   // form checked BEFORE geometry
  if (formMiss != null) return CheckResult.fail(formMiss);
  ...
  final result = await scoreLetter(strokes, letter);              // ← widen: pass the form here
  if (result.passed) return const CheckResult.pass();
  return CheckResult.fail(_mapMistake(result.mistakeId, exercise));
}
```

**Where the form comes from** (existing evidence in this file): the exercise's expectation is
`exercise.expected?.glyph?.form` (`_checkPositionalForm`, lines 212-218). RESEARCH Pattern 2:
the VALIDATOR (not the surface) owns form resolution for scoring — write mode has no painted
guide but still has an asked form.

**Contract to preserve** — `_mapMistake` (lines 256-275): scorer `MistakeId` → ordered
authored-key candidates → `_pickKey`; new criterion outcomes must resolve through this table
(add rows, don't bypass — T-07-03-02 "no raw scorer internal ever surfaces").

---

### 6. `lib/tutor/tutor_facts.dart` (DTO wire mirror, request-response) — increments 4 + 6

**Analog:** the file's own `strokeDiff` field — the exact pattern for the new `criteria` field.

**Field pattern to copy** (`tutor_facts.dart:127-135` declaration; `162-167` serialization):

```dart
/// ... Mirrors `TutorFactsIn.strokeDiff` (`server/app/schema.py`); the
/// server's `extra="forbid"` 422s any stray coordinate key.
final Map<String, Object?>? strokeDiff;

// in toMap():
if (strokeDiff != null) 'strokeDiff': strokeDiff,     // omit-when-null keeps prior payload byte-identical
```

Copy this exactly for `criteria` (declaration + conditional emission + the "mirrors
server/app/schema.py byte-for-byte (Pitfall 1 — the 422 trap)" doc-comment, per the
`clearedTiers` precedent at lines 113-125). Increment 6 then DELETES `strokeImage`
(lines 137-144 declaration + 165-167 emission) — the field whose doc-comment already brands it
a temporary owner-authorized reversal.

**Type constraint** (lines 1-3 + guard test): no `Offset`, no stroke, no coordinate field may be
representable — `criteria` must serialize to name/zone/score scalars only.

---

### 7. `lib/tutor/tutor_facts_builder.dart` (chokepoint utility) — increment 4

**Analog:** own `strokeDiff` threading. Pattern (`tutor_facts_builder.dart:31-56`): add an
optional named param + pass-through, exactly like:

```dart
TutorFacts buildTutorFacts({
  ...
  Map<String, Object?>? strokeDiff,
  String? strokeImage,          // ← inc 6 deletes this param
}) {
  return TutorFacts(..., strokeDiff: strokeDiff, strokeImage: strokeImage);
}
```

The signature IS the guard (lines 12-17): it must never grow a stroke/Offset/profile param.
`criteria` enters as an already-derived structure (built from `LetterScore`), pass-through
like `clearedTiers` (no derivation in the builder).

---

### 8. `lib/tutor/stroke_diff.dart` (derived-geometry utility, transform) — increment 4 (option)

**Analog:** itself — the reference derived-diff pattern for any new derived facts (e.g. F6 word
facts). Key properties to copy for ANY new wire-bound derived data
(`stroke_diff.dart:1-19` header + `29-33`):

- point-free by construction (ratios/fractions/verdicts, never `x`/`y`/`points`);
- keys mirror the server DTO field-for-field;
- returns `null` when it can't compute (degrade to label-only coaching, never throw);
- scale/translation-invariant features (`_aspect`, `_symmetry`, bbox fractions);
- verdict-string buckets, e.g. lines 64-70: `ratio < 0.5 ? 'much shallower' : ... : 'matches'`.

---

### 9. `lib/features/letter_unit/widgets/write_surface.dart` (component, event-driven) — increment 6 + shared resolution

**Analog:** itself. The cutover seams, pinned:

| Seam | Lines | Action |
|---|---|---|
| `onStrokeImage` callback param + doc | 60, 93-98 | DELETE |
| baa-only PNG render call in `_onLetterComplete` | 233-247 (`if (_isTrace && widget.letter.id == 'baa')` … `widget.onStrokeImage?.call(strokeImage);`) | DELETE |
| `_renderStrokesToBase64Png` | 251-305 | DELETE (with it goes `dart:convert`/`dart:ui` PNG imports if unused) |
| `dart:convert` + `dart:ui` imports | 27, 29 | remove if orphaned |

**Pattern to KEEP and HOIST** — the per-form resolution (`write_surface.dart:157-170`) is the
in-repo original of RESEARCH Pattern 2 / Pitfall 7's "one resolution function":

```dart
List<StrokeSpec> get _referenceStrokes {
  if (!_isTrace) return const <StrokeSpec>[];
  return _formStrokes ?? widget.letter.referenceStrokes;
}
List<StrokeSpec>? get _formStrokes {
  final form = widget.surface.guideForm;
  final ctx = widget.letter.contextualForms;
  if (form == null || ctx == null) return null;
  final f = ctx[form];
  if (f == null || f.referenceStrokes.isEmpty) return null;
  return f.referenceStrokes;
}
```

Canvas completion (`StrokeCanvas` fires at `referenceStrokes.length`), `computeStrokeDiff`
(line 228, already diffs vs `_referenceStrokes` — the per-form ref), and `scoreLetter` must all
consume the SAME resolved list.

**Best-effort seam idiom to keep** (lines 225-232): `try { strokeDiff = computeStrokeDiff(...) }
catch (_) { strokeDiff = null; }` — never throw out of the validation handler.

Known baseline: `test/.../write_surface` test is a pre-existing failure IN this touch set —
reconcile or explicitly re-baseline, don't silently absorb (RESEARCH baseline note).

---

### 10. `lib/features/letter_unit/widgets/exercise_scaffold.dart` (component, event-driven) — increment 6

**Analog:** itself. The `aiJudge` deferral to delete, pinned:

| Seam | Lines | Action |
|---|---|---|
| `_pendingStrokeImage` field + doc | 161-165 | DELETE |
| `_onStrokeImage` handler | 190-194 | DELETE |
| `aiJudge` branch decl + scorer-path guard | 219-231 (`final aiJudge = strokeImage != null;` + `if (!aiJudge) {...}`) | verdict applies UNCONDITIONALLY (un-guard lines 226-231) |
| `strokeImage:` arg into `buildTutorFacts` | 241 | DELETE |
| AI-verdict overrule block in `.then` | 256-276 (`decision.verdict` → `applyVerdict`) | DELETE — `_recordAttempt` returns to scorer-verdict-driven |
| `catchError` aiJudge fallback | 292-300 | simplify (scorer already applied) |
| `onStrokeImage: _onStrokeImage` wiring | 437 | DELETE |

**The restored normal path IS already in the file** (lines 225-231) — the cutover makes it
unconditional:

```dart
ref.read(exerciseControllerProvider.notifier).applyResult(result);
markLatency(LatencySegment.scorerVerdictRendered);
if (result.passed && widget.graphExerciseId != null) {
  widget.onGraphNodePassed?.call(widget.graphExerciseId!);
}
_recordAttempt(section, result.passed, result.mistakeId);
```

`_pendingStrokeDiff` / `_onStrokeDiff` (lines 155-159, 186-188) stay — that's the surviving
transport, and the `criteria` structure rides the same stash-then-consume pattern.
Check `decision.verdict` usage in `lib/tutor/tutor_decision.dart` + `remote_agent_brain.dart`
`_parseCoachOut` when removing (Pattern 4 in RESEARCH: `_parseCoachOut` must tolerate a missing
`verdict` key — the normal path never had one).

---

### 11. `server/app/schema.py` (DTO, request-response) — increments 4 + 6

**Analog:** own `StrokeDiffIn` — the exact template for a `CriterionResultIn`/`criteria` DTO.

**Nested point-free DTO pattern** (`schema.py:47-82`, abridged):

```python
class StrokeDiffIn(BaseModel):
    """... `extra="forbid"` + only scalar/string fields means **raw stroke points can never
    cross the wire** ... Every field is optional so the producer sends only what applies."""
    model_config = ConfigDict(extra="forbid")
    summary: str | None = Field(default=None, description="...")
    bowlDepthVerdict: str | None = Field(default=None, description="'much shallower' | ... ")
```

**Optional-field-on-TutorFactsIn pattern** (`schema.py:131-137` — additive = server ships FIRST):

```python
strokeDiff: StrokeDiffIn | None = Field(
    default=None,
    description="DERIVED stroke-geometry diff computed on-device (no raw points). ...",
)
```

Copy both for `criteria` (e.g. `list[CriterionResultIn] = Field(default_factory=list)` — a new
field rather than overloading the baa-specific `bowl*` vocabulary, per RESEARCH Alternatives).
Increment 6 removals: `strokeImage` field (lines 139-146 — client stops sending FIRST, field
parked then deleted) and `CoachOut.verdict` (lines 167-172 — server's to drop immediately,
response extras are the server's).

---

### 12. `server/app/main.py` (controller, request-response) — increment 6

**Analog:** itself — the normal path below the short-circuit is the shape that remains.

**DELETE:** the `if facts_in.strokeImage:` short-circuit, `main.py:84-112` (lazy
`image_judge` import, `asyncio.to_thread` wrap, `CoachOut(verdict=...)` return).

**KEEP + EXTEND — the non-PII observability pattern** (`main.py:148-162`):

```python
_sd = facts_in.strokeDiff.model_dump(exclude_none=True) if facts_in.strokeDiff else None
logger.warning(
    "coach decision: passed=%s mistakeId=%s strokeDiff=%s tool=%s grounded=%s line=%r",
    facts_in.passed, facts_in.mistakeId, _sd, out.toolName, out.grounded, _line[:200],
)
```

Log `criteria` the same way (`exclude_none`, derived-only — the Security section's
"child-data in logs" mitigation). Also keep: timeout→503 degrade ladder (lines 114-138),
`_WIRE_ARG_KEYS` snake→camel normalization (lines 41-50), `@lru_cache` graph singleton (55-58),
`/health`-not-`/healthz` (61-68).

---

### 13. `server/app/prompts.py` (prompt config) — increment 4

**Analog:** own `COACH_STROKE_ADDENDUM` (`prompts.py:57-73`) — the register + structure for the
criterion-aware upgrade:

```python
COACH_STROKE_ADDENDUM = """
The GOLD EXEMPLARS above show the REGISTER to match — they are NOT lines to repeat. NEVER reuse an \
exemplar word-for-word; write a FRESH line every time, fitted to THIS child's attempt.

The FACTS now include `strokeDiff`: a DERIVED geometry diff ... Use it \
to name the ONE specific thing about THIS attempt ...

GROUNDING (unchanged — never break, even now that you can see the geometry):
- The scorer's verdict is STILL the frozen FACT. ...
- Describe ONLY what the diff shows. Never invent a detail (a dot, a tail) that is not there.
"""
```

The upgrade adds: name the FAILED criterion (the `weakest` from `criteria`), and the F3
English-primary constraint. Keep the file's discipline (lines 1-14): stable persona/rules in the
SystemMessage (cache-eligible), variable FACTS in the HumanMessage — never concatenate facts
into the system prompt. Anti-pattern reminder: letter/form-parameterized, never per-letter
prompt branches.

---

### 14. `server/app/nodes/coach.py` (graph node) — increment 4

**Analog:** own addendum trigger + guard structure.

**Trigger pattern to extend** (`coach.py:55-58`):

```python
system_prompt = COACH_PROMPT + (COACH_STROKE_ADDENDUM if facts.get("strokeDiff") else "")
```

Becomes `if facts.get("strokeDiff") or facts.get("criteria")`. **Do not touch** the guard
ladder (lines 83-99): out-of-set name → say (G2); `advance` on fail → rewritten grounded say
(G3, lines 89-91); unauthored `present_activity` → rejected (G4, lines 94-99). These are the
"grounding holds by construction" mechanism D-B relies on.

---

### 15. `server/app/image_judge.py` — DELETE (recommended, RESEARCH A5)

No analog needed. Deletion checklist = the four seams (RESEARCH Pattern 4 / Pitfall 6):
1. `write_surface.dart` render + `onStrokeImage` (see §9),
2. `exercise_scaffold.dart` deferral (see §10),
3. `main.py:84-112` short-circuit (see §12),
4. `schema.py` `strokeImage` + `CoachOut.verdict` (see §11) — plus the guard-test whitelist
   entries (`payload_nonpii_test.dart:44-54`, 148, 222-225) and a grep-guard test that
   `strokeImage` no longer appears in `lib/` payload construction.

---

### 16. `server/tests/test_eval/run_eval.py` (+ `run_judge.py`) — EVAL-03 / STRK-01

**Analog:** their own two-leg structure — new dimensions slot into an existing frame.

**Dimension-registry pattern** (`run_eval.py:41-49`): add entries to `DIMENSIONS` (e.g.
`semantic_faithfulness`, `no_false_geometry`, `specificity`, `variety`); the 16-01 RED-test
convention asserts the registry covers all legs.

**Skipped-when-offline judge-leg pattern** (`run_eval.py:101-124`) — copy for every new
judge-based leg:

```python
def _score_judge_dimension(cases, dimension, judge_scores):
    if judge_scores is None:
        return {"score": None, "skipped": "Vertex LLM-judge leg — runs under `make eval`, not the `-m code` gate",
                "threshold": JUDGE_THRESHOLD}
    mean = sum(judge_scores) / len(judge_scores) if judge_scores else 0.0
    return {"score": mean, "threshold": JUDGE_THRESHOLD, "meets_threshold": mean >= JUDGE_THRESHOLD, ...}
```

**Gate composition pattern** (`run_eval.py:149-160` `gate_passes`): D1 zero-tolerance stays the
floor (`if scores["faithfulness"]["rate"] < 1.0: return False`); skipped judge legs never fail
the gate; ran legs must meet threshold. The variety/duplicate detector is MODEL-FREE — it joins
the D1/D2 side (gates every PR under `-m code`), not the judge side.

**Judge-runner pattern** (`run_judge.py:47-61` keyless lazy `ChatVertexAI` with
`thinking_budget=0`; `80-113` `_build_prompt`/`_parse_score`/`judge_dimension`): new dimensions
= new rubric sections in `JUDGE_RUBRIC.md` + entries in `JUDGE_DIMENSIONS` (line 44) + a
`judge_dimension(model, rubric, "<dim>", cases)` call in `run_judge` (lines 127-128). Judge
stays `gemini-2.5-flash` ≠ coach. The no-false-geometry leg needs the facts (strokeDiff/criteria)
IN the judge prompt — extend `_build_prompt`'s case rendering (line 82 currently renders only
verdict + coaching).

**`faithfulness.py` re-scope (EVAL-03):** keep `_PRAISE` lexicon leg (lines 39-46, 60-64) as the
zero-tolerance floor; the expected-fix SUBSTRING rule (lines 65-66) is what gets retired AS THE
GATE for varied lines (spike: 0.55-0.73 false-flag rate, 0 real contradictions).

**gold_set.jsonl convention:** `#`-comment header stating provenance + status; every line
carries `"signed": false / "drafted_by": "claude"` until mom re-signs; loaders skip `#` lines
(`run_eval.py:52-61`). Regrown cases must carry the strokeDiff/criteria facts so the
no-false-geometry trap (`adv_broken_but_pass`) is expressible.

---

### 17. `server/tests/` new `criteria` DTO tests — increment 4

**Analog:** `server/tests/test_payload_nonpii.py` — copy all four moves:

```python
pytestmark = pytest.mark.code                       # model-free, gates every PR

def test_graph_position_fields_default_empty_when_omitted():   # backward-compat = no 422 window
    minimal = {"letterId": "baa", "section": "traceLetter", "passed": True}
    facts = TutorFactsIn.model_validate(minimal)
    assert facts.clearedTiers == []

@pytest.mark.parametrize("bad_key", FORBIDDEN_KEYS)            # per-key 422 rejection
def test_tutorfactsin_rejects_each_nonwhitelisted_key(bad_key): ...

def test_extra_forbid_is_pinned_on_both_models():              # config pinned, not incidental
    assert TutorFactsIn.model_config.get("extra") == "forbid"
```

For `criteria`: accepts-legit, defaults-empty-when-omitted, nested-`extra="forbid"` rejection
(a leaked key INSIDE a criterion record 422s — mirror
`test_tutorfactsin_rejects_a_leaked_key_inside_a_trajectory_entry`, lines 113-122), and the
`_PII_TOKEN_RE` name/value scan (lines 77-93).

---

### 18. `test/core/scoring/calibration_harness_test.dart` + fixtures — increment 5

**Analog:** itself + `calibration_fixtures.dart`.

**Fixture format to extend** (`calibration_fixtures.dart:46-66`): `LabeledSample{letterId,
label, strokes}` — the per-form dimension adds a field (e.g. `form`) or a per-form fixture map;
the harness's letter loop (`calibration_harness_test.dart:130-166`) gains a form loop. Keep the
`_expectedRejection` label→MistakeId pin (lines 32-37) and the FN/FP `_Confusion` tally +
`tearDownAll` printed table (lines 115-124, 170-181) — that printout is the mom-facing tuning
artifact.

**Real per-form references for fixtures** — `assets/curriculum/letters.json` baa
`contextualForms` (verified this session): isolated `bowl` curve 12pts + dot; initial `head`
9pts + dot; medial `tooth` 8pts + dot; final `bowl_tail` 11pts + dot — all bodies
`rightToLeft`, dots `type:'dot'/direction:'tap'`; initial/medial/final are form-level
`signedOff:false` (do NOT flip flags; demo may score unsigned forms per RESEARCH A2).

**Perturbation technique for new fixtures** (`shape_match_test.dart:14-39`) — build variants
from the REAL authored reference, not invented shapes:

```dart
final shakyBowl = [for (var i = 0; i < bowl.length; i++)
    [bowl[i][0] + (i.isEven ? 0.012 : -0.010), bowl[i][1] + (i % 3 == 0 ? -0.011 : 0.009)]];
final flatLine = [for (var i = 0; i < 12; i++) [0.620 - i * (0.239 / 11), 0.510]];
```

The F5 trap case (isolated bowl offered for the medial slot → must FAIL) is a fixture pair:
isolated-reference strokes scored against the medial form. Threshold-FITTING (report
suggested tcc/tcw from labelled distance distributions) has no in-repo precedent — see No
Analog Found; the confusion-table print is the output style to follow, and synthetic-fixture
values stay a regression seed, never production values (Pitfall 4).

---

### 19. `test/core/scoring/` new soft-verdict + per-form scorer tests — increments 2/3

**Analog:** `shape_match_test.dart` (test-name-states-the-requirement style, real-reference
fixtures, zone assertions) and `letter_scorer_test.dart` (inline `Letter` builder mirroring
letters.json — the same builder the harness reuses at `calibration_harness_test.dart:42-106`).
RED-first per Wave 0: shaky-correct passes, flat-line fails, direction still a criterion,
per-form reference selection, `LetterScore.criteria` structure + weakest-criterion selection.

---

### 20. `test/tutor/` guard + mirror-set extensions — increments 4/6

**Analog:** `payload_nonpii_test.dart` — three patterns to extend in the SAME task as any wire
change (Pitfall 1):

1. **Whitelist-union** (lines 27-75 + 164): `_whitelist ∪ _strokeDiffKeys` gains a
   `_criteriaKeys` set (`{name, zone, score}` or final shape); `strokeImage` LEAVES `_whitelist`
   at cutover; the fully-populated fixture (lines 114-149) gains a representative `criteria`
   value and drops `strokeImage`.
2. **Token-guard regex** (lines 88-91): `\b[xy]\b|strokes|offset|coord|point|raw|nick|name` —
   check new key names against it BEFORE naming fields (`point`/`name` are forbidden substrings;
   a criterion field literally named `name` will trip it — pick `criterion` or extend the regex
   deliberately, in both Dart and the server mirror `test_payload_nonpii.py:59`).
3. **Exact mirror-set assertion** (`remote_agent_brain_test.dart:185-196`): the sent body's
   `keys.toSet()` equals the literal field list — extend for `criteria`, shrink for
   `strokeImage`.

**Grep-guard pattern for the cutover test** (new `test/features/` guard): copy the
source-scan move from `payload_nonpii_test.dart:242-259` —
`File('lib/...').readAsStringSync()`, strip `//`-comment lines, assert the forbidden token
(`strokeImage`) is absent from payload-construction code.

---

### 21. `docs/architecture/ADR-016-or-017-*.md` — GROUND-04 ADR

**Analog:** `ADR-015-v2-tutor-server-langgraph-agent.md` header structure (lines 1-8):

```markdown
# ADR-0NN: <title>
**Status:** ACCEPTED (owner, YYYY-MM-DD). <one-paragraph decision summary with links>
**Supersedes:** <what this reverses/amends — here: the 17.1 AI-owns-verdict directive; amends GROUND-02>
**Affects:** <phases/plans reshaped>
---
## Context
## Decision   (numbered sub-decisions)
```

Numbering: only ADR-014/015 exist ON DISK; "ADR-016" is verbally reserved for the Phase-16
bake-off (STATE) — verify at plan time; ADR-017 is the safe next free number (RESEARCH A1).
One ADR covering both the verdict-authority un-reversal AND the derived-diff data flow
(RESEARCH Open Q1 recommendation).

---

## Shared Patterns

### The 422 lockstep (byte-for-byte wire mirror) — applies to EVERY wire-field change
**Sources:** `lib/tutor/tutor_facts.dart` toMap (151-168) ↔ `server/app/schema.py` `TutorFactsIn`;
guards `test/tutor/payload_nonpii_test.dart` + `server/tests/test_payload_nonpii.py` +
`remote_agent_brain_test.dart:185-196`.
**Rule (directional deploy order, RESEARCH Pattern 3):** ADDITIVE → server first (optional +
default), client follows. REMOVAL → client stops sending first, server field deleted after.
All three guard tests extended in the same task as the field change.

### Threshold-as-data (D-D)
**Source:** `lib/core/scoring/tolerances.dart` (preset + overrides + defensive fromJson) and
`lib/models/letter.dart` `Form.tolerances` (per-form layer already parsed, lines 110-133).
**Apply to:** SoftBand knobs. In-code defaults (`SoftBand.shapeDefault`) are fallbacks only,
labeled PROVISIONAL.

### Pure-Dart scoring-module header + no-PII posture
**Source:** `shape_match.dart:1-27`, `letter_scorer.dart:1-25`.
**Apply to:** all new/changed scorer code — "Pure Dart, no dart:ui, no Flutter imports", cite
the decision/finding IDs, state that child points live only in locals.

### First-failing-predicate + MistakeId ↔ commonMistakes[].check naming contract
**Sources:** `geometric_stroke_scorer.dart:67-81`, `scoring_models.dart:8-21`,
`exercise_validator._mapMistake` (256-275).
**Apply to:** all scorer changes — criteria are ADDITIVE around a preserved
`passed`/`mistakeId` core (Pitfall 2).

### Best-effort derive, never throw at the surface seam
**Source:** `write_surface.dart:225-232` (`try { computeStrokeDiff } catch (_) { null }`),
`stroke_diff.dart:29-33` (null when incomputable).
**Apply to:** criteria computation/attachment on-device.

### Fail-closed 503 degrade + non-PII structured logging (server)
**Source:** `main.py:114-138` (timeout/StructuredOutputError/Exception → 503, "NEVER
200-with-empty") + `148-162` (`exclude_none` derived-only logging).
**Apply to:** any main.py change this phase.

### Two-leg eval discipline (model-free gates PRs; judge legs gate pre-merge)
**Source:** `run_eval.py` (D1/D2 vs skipped judge legs) + `run_judge.py` (lazy keyless Vertex,
judge ≠ coach, rubric-anchored [0,1] JSON scores).
**Apply to:** every new EVAL-03/STRK-01 leg — decide the side FIRST (variety/duplicate =
model-free; semantic faithfulness/no-false-geometry/specificity = judge).

---

## No Analog Found

| File / piece | Role | Data Flow | Reason — planner should use RESEARCH.md instead |
|---|---|---|---|
| Threshold-FITTING logic (calibration harness upgrade) | test/harness | batch | No fitting code exists anywhere in the repo; the harness only tallies FP/FN. RESEARCH F8/F11 + the confusion-table print style are the guide; output = suggested tcc/tcw from labelled correct-vs-wrong distance distributions, values labeled PROVISIONAL |
| Two-arm specificity/variety baseline harness (STRK-01 measurement) | eval | batch | No in-repo precedent; closest raw material is the spike harness `.planning/spikes/_lib/{fixtures.py,representations.py,scoring.py}` (verified dir per RESEARCH) — reusable design, not production code. Variety = model-free duplicate/verbatim-exemplar detector; specificity = judged localization |
| Kinematics criterion (F1's 5th) | service | transform | `StrokeCanvas` captures `List<List<Offset>>` with NO timestamps — no data source. RESEARCH Open Q2 recommends descoping to 4 geometric criteria + dot; don't fake it with point spacing |

## Metadata

**Analog search scope:** `lib/core/scoring/`, `lib/core/exercise_engine/`, `lib/tutor/`,
`lib/features/letter_unit/widgets/`, `lib/models/`, `server/app/` (+ `nodes/`), `server/tests/`
(+ `test_eval/`), `test/core/scoring/` (+ `calibration_fixtures/`), `test/tutor/`,
`docs/architecture/`, `assets/curriculum/letters.json`
**Files read in full this session:** 22 (all excerpts verified against source at the cited lines)
**Pattern extraction date:** 2026-07-05
**Staleness note:** line numbers go stale with any commit to the touch set — re-pin at execution
if `git log` shows movement in `lib/core/scoring/`, `lib/tutor/`, or `server/app/`.
