---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 08
subsystem: api
tags: [tutor-server, coach-node, langgraph, why-grounding, d-10, casing-rail, eval-harness, selection-policy, vertex-judge, signed-false, pytest]

# Dependency graph
requires:
  - phase: 18
    plan: 01
    provides: "the RED test_selection_dimension.py (imports SELECTION_THRESHOLD + a selection_policy dimension) + the 3-scenario signed:false selection gold set this plan turns green / grows"
  - phase: 18
    plan: 02
    provides: "the baa micro-drill CONTENT (baa.microDrill.{dot,bowl,start}) + criterion vocabulary the WHY line + gold scenarios reference"
  - phase: 18
    plan: 05
    provides: "TutorFactsIn.profile (strengths/struggles/perCriterion) — the returning-child struggle the WHY line may cite; the already-landed weakestCriterion/legalNextExerciseIds wire fields"
  - phase: 17
    provides: "the coach node + COACH_NEXT_EXERCISE_ADDENDUM + the Phase-17.2 candidate rail (coach.py); weakestCriterion on the wire; run_eval.py + gold_set.jsonl eval harness + the judge-defer pattern (17-04)"
  - phase: 15
    provides: "the plan-node G4/G5/G6 curriculum rails (kept byte-unchanged); the CurriculumGraph.isLegalSelection candidate set the coach picks FROM"
provides:
  - "WHY-grounded pick on the COACH path (D-10 online justification): COACH_NEXT_EXERCISE_ADDENDUM now NAMES the targeted weakestCriterion and frames a microDrill pick as a warm NAMED step-down (D-03) — the ONLY place the WHY fires on the clean-pass branch (the plan node is skipped there by graph.py needs_plan)"
  - "struggle-branch WHY: plan.py's Plan.rationale + PLAN_PROMPT ground the rationale in weakestCriterion (G4/G5/G6 byte-unchanged; no verdict/mastery claim)"
  - "CASING-SAFE next-exercise rail: the coach rail strips an out-of-candidates id under EITHER nextExerciseId OR next_exercise_id — the snake_case bypass (main.py renamed snake→camel AFTER the rail) is closed"
  - "the selection_policy eval dimension in run_eval (DIMENSIONS + JUDGE_GATED_DIMENSIONS) + a NAMED provisional SELECTION_THRESHOLD (signed:false) — the judged 'would a teacher make THIS pick?' complement to the deterministic rails property tests (Req 5)"
  - "a grown 6-scenario signed:false selection gold set (2 variants per family: fail-streak, returning-child, boredom-trap)"
affects: [18-09, 18-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "WHY grounding on the COACH path (not the plan node) so it covers the clean-pass branch that skips plan (graph.py needs_plan)"
    - "Casing-safe wire rail: validate a decision-arg id under BOTH its snake_case tool key and its camelCase wire key, because the snake→camel rename runs AFTER the guard"
    - "Named provisional eval threshold (SELECTION_THRESHOLD, signed:false) — the mother flips ONE constant at 18-11 (15-07/17-10 sign-off pattern); the judge leg is deferred to make eval (17-04 judge-defer)"

key-files:
  created: []
  modified:
    - server/app/prompts.py
    - server/app/nodes/coach.py
    - server/app/nodes/plan.py
    - server/tests/test_grounding.py
    - server/tests/test_eval/run_eval.py
    - server/tests/test_eval/selection_gold_set.jsonl

key-decisions:
  - "The casing hole was closed IN coach.py (the rail), NOT in main.py — the plan offered either option ('make the coach rail check next_exercise_id ... OR move the main.py normalization BEFORE the rail'). Railing at the coach node keeps main.py's single wire-normalization contract intact and validates the id at the point it is first proposed; main.py:41-45 was left untouched."
  - "The WHY grounding lives in COACH_NEXT_EXERCISE_ADDENDUM (prompts.py, the coach path) because graph.py `needs_plan` routes a confident pass STRAIGHT to coach — the plan node never runs on the most common 'clean pass → move forward' case, so a plan-only WHY would never fire there."
  - "plan.py touched only the Plan.rationale Field description + PLAN_PROMPT — the G4/G5/G6 guard ladder (plan.py:92-139) is BYTE-UNCHANGED, satisfying the plan's hard constraint."
  - "SELECTION_THRESHOLD = 0.7 (the established judge bar), documented signed:false; _score_judge_dimension gained an optional threshold arg so the selection leg gates against SELECTION_THRESHOLD while the five existing judge legs keep JUDGE_THRESHOLD."
  - "Gold set GROWN to 6 scenarios (2 variants per family) rather than left at the 18-01 minimum — every added line is Claude-drafted, signed:false, drafted_by:claude; the mother signs the whole set + threshold at 18-11."
  - "Header prose in selection_gold_set.jsonl was rewritten from the literal '\"signed\": false' to the bare 'signed:false' so `grep -c '\"signed\": false'` counts ONLY the 6 data lines (== data-line count), matching the acceptance grep exactly."

patterns-established:
  - "A model-free test can pin a prompt-level contract by asserting the addendum text carries the grounding tokens (weakestCriterion, microDrill) + the ADR-014 no-verdict guard, complementing the LLM-judge leg deferred to make eval"
  - "The next-exercise rail's orphaned-rationale drop is now survivor-aware: rationale is dropped only when NO legal id survives under either casing"

requirements-completed: []

# Metrics
duration: 18min
completed: 2026-07-11
---

# Phase 18 Plan 08: Server Selection Intelligence — WHY Grounding + selection_policy Eval Dimension Summary

**The coach now VOICES why it picked the next exercise (grounded in weakestCriterion, with a warm named step-down when the pick is a micro-drill) — on BOTH graph branches, since the addendum lives on the coach path the clean-pass route can't skip — the candidate rail is casing-safe (the snake_case bypass is closed), the G4/G5/G6 rails are byte-unchanged, and the pick quality is now a NAMED, mother-gated `selection_policy` eval dimension over a 6-scenario signed:false gold set.**

## Performance

- **Duration:** ~18 min
- **Completed:** 2026-07-11
- **Tasks:** 2
- **Files modified:** 6 (0 created, 6 modified)

## Accomplishments

- **WHY grounding on the COACH path (Task 1, D-10):** `COACH_NEXT_EXERCISE_ADDENDUM` now grounds the announced pick in the policy facts already on the wire — it NAMES the targeted `weakestCriterion` (in plain words, never scorer jargon) and, when the picked id contains `microDrill`, frames a warm NAMED step-down ("let's practice just the dot for a moment," D-03 register) with a promise to come back. This lives on the coach path because `graph.py` `needs_plan` routes a confident pass STRAIGHT to coach (the plan node is skipped on the most common case), so a plan-only WHY would never fire there. `plan.py`'s `Plan.rationale` + `PLAN_PROMPT` ground the struggle-branch WHY the same way — with the G4/G5/G6 guard ladder BYTE-UNCHANGED and no verdict/mastery claim (ADR-014).
- **Casing hole closed (Task 1):** the Phase-17.2 next-exercise rail is now CASING-SAFE — an out-of-candidates id is stripped under EITHER `nextExerciseId` OR the tool's snake_case `next_exercise_id`. `main.py:41-45` renames snake→camel AFTER the rail runs, so a snake_case emission used to skip candidate validation and reach the client; both keys are now checked (the orphaned `rationale` is dropped only when no legal id survives under either casing).
- **selection_policy eval dimension + signed:false gold set (Task 2, Req 9):** `run_eval` registers `selection_policy` in `DIMENSIONS` + `JUDGE_GATED_DIMENSIONS` (Vertex LLM-judge: "would a teacher make THIS pick?"), gated by a NAMED provisional `SELECTION_THRESHOLD` (0.7, signed:false until 18-11). `_score_judge_dimension` gained an optional `threshold`; `score_eval_set` gained a `selection_scores` leg. The gold set grew to 6 signed:false scenarios (a second variant per family: fail-streak on shape→micro-drill, returning-child strength→move-forward, third-repeat boredom trap). The 18-01 RED `test_selection_dimension.py` is GREEN with ZERO test edits; the judge leg is deferred to `make eval` at the 18-11 gate.

## Task Commits

Each task was committed atomically:

1. **Task 1: WHY grounding on the coach path + close the snake_case rail bypass (D-10)** — `c84a166` (feat)
2. **Task 2: selection_policy eval dimension + grow the signed:false gold set (Req 9)** — `45e6b85` (feat)

_Both tasks are `tdd="true"`. Task 1 authored 4 new model-free tests alongside the implementation; Task 2 turned the 18-01 RED contract green with zero test edits (the judge leg deferred, mirroring 17-04)._

## Files Created/Modified

- `server/app/prompts.py` — `COACH_NEXT_EXERCISE_ADDENDUM` extended with the WHY (weakestCriterion) + microDrill step-down grounding; `PLAN_PROMPT`'s rationale bullet grounds the struggle-branch WHY in weakestCriterion
- `server/app/nodes/coach.py` — the next-exercise rail is casing-safe (checks `nextExerciseId` AND `next_exercise_id`); a note documents the WHY grounding on the coach path
- `server/app/nodes/plan.py` — `Plan.rationale` Field description grounds the WHY in weakestCriterion (guard ladder byte-unchanged)
- `server/tests/test_grounding.py` — +4 model-free tests: addendum grounds the WHY in weakestCriterion + microDrill; the clean-pass branch gets the addendum; an illegal snake_case id is stripped; a legal snake_case id survives
- `server/tests/test_eval/run_eval.py` — `selection_policy` in DIMENSIONS + JUDGE_GATED_DIMENSIONS; NAMED `SELECTION_THRESHOLD` (signed:false); `_score_judge_dimension` threshold arg; `score_eval_set` `selection_scores` leg
- `server/tests/test_eval/selection_gold_set.jsonl` — grown to 6 signed:false scenarios (2 variants per family); header prose de-literalized so `grep -c '"signed": false'` == data-line count

## Decisions Made

- **Casing hole closed in coach.py (the rail), not main.py.** The plan offered either option; railing at the coach node validates the id where it is first proposed and keeps `main.py`'s single wire-normalization contract intact. `main.py:41-45` is untouched.
- **WHY grounding on the coach path (not the plan node).** `graph.py` `needs_plan` skips the plan node on a clean pass, so the pass→move-forward justification MUST ride on the coach addendum or it never fires on the most common case.
- **`SELECTION_THRESHOLD` = 0.7, signed:false, NAMED.** `_score_judge_dimension` gained an optional `threshold` so the selection leg gates against `SELECTION_THRESHOLD` while the five existing judge legs keep `JUDGE_THRESHOLD` — the mother flips one constant at 18-11.
- **Gold set grown to 6 (2 variants/family).** Richer than the 18-01 minimum but all Claude-drafted + signed:false; the mother signs the whole set + threshold at 18-11.
- **Requirements NOT checkbox-marked.** `requirements-completed: []` — R1's client WHY line + anti-boredom is 18-04/18-07, and R9 ships signed:false with the judge leg + threshold sign-off gated to 18-11. Follows the 18-01/18-02/18-05 Wave/foundation precedent; the plan landing the final leg (or the phase verifier) flips the boxes.

## Deviations from Plan

None — plan executed exactly as written. Task 1 chose the coach.py rail option for the casing fix (one of the two the plan's action (c) explicitly offered), so `main.py` — listed in the task `<files>` — was correctly left untouched; that is a sanctioned in-plan choice, not a deviation. No Rule 1–4 deviations were required.

## Issues Encountered

- **The gold-set `grep -c '"signed": false'` proxy tripped on header prose.** The 18-01 header and my initial 18-08 header note both contained the literal `"signed": false`, inflating the grep count above the data-line count. Resolved by rewriting both header lines to the bare `signed:false` form (no quotes/colon-space), so the literal now appears ONLY on the 6 data lines — `grep -c '"signed": false'` == 6 == data-line count, with zero `"signed": true`. Verified via the `_load_cases` loader (6 cases, all `signed is False`).
- **A bare `uv run pytest -m code` still interrupts at collection with 1 error** — `test_compile_profiles.py` imports the not-yet-built `app.jobs.compile_profiles` (greened by 18-09). This is the established Wave-0 RED-by-missing-module behavior (18-01/18-03/18-05 all documented it). This plan turned `test_selection_dimension.py` from RED→GREEN, so it no longer interrupts collection. Confirmed no regression by running with only `test_compile_profiles.py` deselected: **138 passed, 1 skipped** (was 134 passed with two RED modules deselected; +4 = the new Task-1 tests, and test_selection_dimension.py now collects + passes).

## Known Stubs

- **`selection_gold_set.jsonl` — every scenario is `signed:false` (PROVISIONAL), and `SELECTION_THRESHOLD` is a provisional 0.7.** INTENTIONAL and tracked: the gold-set content + the "would a teacher make this pick?" threshold are the owner-mother's pedagogy call, signed at the **18-11** HUMAN-UAT gate (the 15-07/17-10 sign-off pattern). The dimension + gold set ship now so the eval structure has a target; the only change at 18-11 is the sign-off flip + the mother-agreed threshold value. The Vertex judge leg (supplying `selection_scores` over the gold set) is likewise deferred to `make eval` at 18-11 (17-04 judge-defer pattern).

## Threat Flags

None — no security-relevant surface beyond the plan's `<threat_model>`. The agent pick stays untrusted and railed (G4/G5/G6 byte-unchanged; the candidate rail is now casing-safe, closing a validation bypass — a net tightening, T-18-08-01); the WHY/rationale carries no verdict/mastery claim (ADR-014, T-18-08-02); the eval threshold + gold set ship signed:false (T-18-08-03). No new package (T-18-08-SC).

## Next Phase Readiness

- **18-09 (nightly compiler):** unaffected by this plan's coach/eval surface; `test_compile_profiles.py` stays RED-by-missing-module (`app.jobs.compile_profiles`) until 18-09 ships it — the last remaining Wave-0 RED server module.
- **18-11 (HUMAN-UAT):** signs the micro-drill copy + the selection gold set (flip `signed:false → true`) and sets the mother-agreed `SELECTION_THRESHOLD`; runs the deferred `make eval` selection judge leg (supplies `selection_scores` over the 6 gold scenarios). The infrastructure (`selection_scores` param, named threshold, DIMENSIONS/JUDGE_GATED registration) is ready.
- No blockers. No new packages. The single Cloud Run re-deploy remains gated behind both wire sides landing (18-06, per the 422 lockstep) — unrelated to this plan's server logic.

## Self-Check: PASSED

- All 6 modified files present on disk (verified): `server/app/prompts.py`, `server/app/nodes/coach.py`, `server/app/nodes/plan.py`, `server/tests/test_grounding.py`, `server/tests/test_eval/run_eval.py`, `server/tests/test_eval/selection_gold_set.jsonl`.
- Both task commits present in git history: `c84a166`, `45e6b85`. No file deletions in either commit.
- Task verifies: `test_grounding.py` + `test_plan_graph.py` 28/28 GREEN (G4/G5/G6 rails unchanged); `test_selection_dimension.py` 4/4 GREEN (zero test edits); acceptance greps confirmed (`weakestCriterion` on the coach path in prompts.py+coach.py; `microDrill` step-down in the addendum; `grep -c '"signed": false'` == 6 == data-line count, zero `signed:true`); full `-m code` with only the 18-09 RED module deselected = **138 passed, 1 skipped**; `make -n eval` structure intact.

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-11*
