---
phase: 26-the-finished-experience-entry-polish-and-the-2-0-1-release
plan: 04
subsystem: testing
tags: [tutor, coach-prompt, feedback, variety, riverpod, widget-test, langgraph]

# Dependency graph
requires:
  - phase: 17-tutor-redesign
    provides: "the D-A cutover (scorer owns pass/fail; agent supplies only WORDS) + the tutorLineProvider channel + the variety_report detector"
  - phase: 14-tutor-foundation
    provides: "COACH_PROMPT + the AuthoredFallbackBrain offline floor + tutorBrainFactoryProvider seam"
provides:
  - "COACH_PROMPT restructured so the GOLD EXEMPLARS carry REGISTER only — no copyable child-facing say-line (D-06a)"
  - "A variety regression proving repeated-attempt lines stay fresh (0 verbatim hits) against the prompt's own derived exemplars"
  - "A live-path widget regression PINNING the agent-line-on-screen invariant on the baa path (foot + bubble), plus a source pin (D-06b)"
affects: [26-06, tutor-server-redeploy, coaching-quality, feedback-debt]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Register-only coaching guidance: describe what a good line DOES, never embed a ready-to-speak line the model can lift"
    - "Live-path widget regression: drive the REAL _onResult seam (WriteSurface.onResult) with the brain injected at tutorBrainFactoryProvider — never a hand-built widget"
    - "Prove a regression test is meaningful by a temporary source break-check, then restore (when the guarded behavior pre-exists)"

key-files:
  created:
    - test/features/letter_unit/exercise_scaffold_agent_line_test.dart
  modified:
    - server/app/prompts.py
    - server/tests/test_eval/test_variety.py

key-decisions:
  - "D-06a fix lives in the prompt: remove the three literal say-lines AND the top-of-persona 'Good:' line (both carried the copyable sentence — the acceptance grep matches an earlier line too), keeping the GOLD EXEMPLARS heading so run_eval.exemplar_lines() stays scoped."
  - "D-06b is verified correct at HEAD (Phase 17.2 already routes agentLine to the foot/bubble); exercise_scaffold.dart is unchanged — the plan's live-path test pins the invariant as a permanent regression."
  - "The three removed say-lines survive as the mother's idealCoaching register ANCHORS in gold_set.jsonl (the variety leg excludes idealCoaching), so no authored/curriculum content was lost."

patterns-established:
  - "Coach-prompt exemplars must be register descriptions, not quotable lines (grep-guarded + variety-guarded)."
  - "Agent-line-is-the-on-screen-feedback is guarded by a live-path widget test on baa, not just unit tests on the seam."

requirements-completed: [FEEDBACK-DEBT]

# Metrics
duration: ~16m
completed: 2026-07-20
---

# Phase 26 Plan 04: Close the two standing tutor-feedback debts (D-06) Summary

**Restructured COACH_PROMPT so the coach can no longer parrot a gold exemplar verbatim (D-06a), and pinned the agent-line-on-screen invariant on the live baa path with a real-_onResult widget regression (D-06b).**

## Performance

- **Duration:** ~16 min
- **Started:** 2026-07-20T18:07:00+03:00 (approx)
- **Completed:** 2026-07-20T18:22:34+03:00
- **Tasks:** 2
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- **D-06a — no more static feedback:** the GOLD EXEMPLARS block was rewritten to convey the register (warmth, short length, a specific named fix) as a *description of what a good line does*, with no ready-to-speak child-facing sentence to lift. The top-of-persona `Good:` example line (which carried the same copyable sentence) was also reworded. The `GROUNDING RULE`, `ACTION RULE`, the `NEVER: "Oops, try again!"` anti-pattern, and the compose-fresh / vary-on-repeat rules are all retained byte-for-byte in intent.
- **D-06a guard:** `test_variety.py` now asserts the prompt embeds no copyable child-facing line (`exemplar_lines(COACH_PROMPT)` derives only the NEVER anti-patterns) and that five distinctly-worded repeated-attempt lines score `0` verbatim-exemplar hits with `distinct_ratio == 1.0`.
- **D-06b — agent line is the on-screen feedback:** a new live-path widget test drives the REAL `_onResult` seam (`WriteSurface.onResult`) with a deferred fake brain injected at `tutorBrainFactoryProvider`, proving the bottom `FeedbackPanelV2` and the tutor bubble both render the agent's DISTINCTIVE line, the authored floor never flashes (empty-until-resolved), and a non-agent letter (alif) keeps its authored `state.line`. A source pin locks the `_foot` `agentLine` wiring.
- All server tests (167 passed, 1 skipped) and the touched Dart tests are green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Restructure the coach GOLD EXEMPLARS + variety guard (D-06a)** — `c044144` (fix)
2. **Task 2: Live-path regression pinning the agent-line foot/bubble invariant (D-06b)** — `b1652e1` (test)

_Task 2 is `tdd="true"`; see TDD Gate Compliance below._

## Files Created/Modified
- `server/app/prompts.py` — COACH_PROMPT GOLD EXEMPLARS restructured to register-only (no copyable say-line); persona `Good:` line reworded. Grounding/action rules untouched.
- `server/tests/test_eval/test_variety.py` — added a source assertion (no copyable child-facing line; register + grounding retained) and a fresh-repeated-attempts regression over the prompt's own derived exemplars; re-documented `_EXEMPLARS` as the removed lines.
- `test/features/letter_unit/exercise_scaffold_agent_line_test.dart` (new) — the D-06b live-path regression pin + source pin.

## Verification
- `uv run pytest tests/test_eval/test_variety.py -q` → 9 passed (7 pre-existing + 2 new).
- `uv run pytest -q` (full server suite) → 167 passed, 1 skipped (no regression from the prompt change).
- `flutter test test/features/letter_unit/exercise_scaffold_agent_line_test.dart` → 3 passed.
- `flutter test .../exercise_scaffold_cutover_test.dart .../exercise_scaffold_agent_line_test.dart` → 8 passed (shared contract intact).
- Acceptance greps: banned say-line absent from `prompts.py`; `Oops, try again!`, `GROUNDING RULE`, `ACTION RULE` all present.
- `flutter analyze` on the new test → no issues.

## TDD Gate Compliance
Task 2 carries `tdd="true"`. The guarded behavior (agent line → foot + bubble) already exists at HEAD (implemented in Phase 17.2). Therefore:
- There is a `test(...)` commit (`b1652e1`) — the RED gate.
- There is **no `feat(...)` commit** because `exercise_scaffold.dart` required no change; it is byte-identical to HEAD (`git diff` clean). This matches the plan's explicit "verified correct at HEAD, guarded" branch.
- To avoid a false-green, the test's meaningfulness was proven by a **temporary** foot regression (`footLine = state.line`): the test failed on both the runtime foot assertion and the source pin, then the source was restored and the test re-ran green.

## Decisions Made
- Kept the `GOLD EXEMPLARS` heading text as the anchor `run_eval.exemplar_lines()` splits on, so the live variety leg (unmodified `run_eval.py`) keeps deriving its parrot-set from the prompt — now yielding only the NEVER anti-patterns.
- Did not modify `gold_set.jsonl` / `faithfulness_set.jsonl` / `exercises.json` (the removed lines are legitimate mother-authored register anchors / authored floor there; only the PROMPT is the D-06a root cause and only it is in scope).

## Deviations from Plan
None — plan executed exactly as written. Task 2 resolved to the plan's explicit "already-correct-at-HEAD" branch (test-only, no source fix), which the plan anticipated.

## Issues Encountered
None.

## User Setup Required / Owner-Gated Follow-ups
The prompt change (D-06a) only reaches on-device coaching after an **owner-authorized `qalam-tutor` Cloud Run redeploy**, and the `make eval` Vertex variety leg needs owner-gated ADC. Both are DEFERRED follow-ups verified in **26-06** (the redeploy is batched with 26-08's baa regen) — NOT part of this plan. This plan delivers only the code change + the deterministic guards.

## Next Phase Readiness
- D-06 is closed in code: the coach cannot parrot an exemplar (guarded), and the on-screen line on baa is the agent's line (pinned on the live path).
- Blocking downstream: the qalam-tutor redeploy + `make eval` variety leg (owner-gated, 26-06).

## Self-Check: PASSED
- Files verified present: `server/app/prompts.py`, `server/tests/test_eval/test_variety.py`, `test/features/letter_unit/exercise_scaffold_agent_line_test.dart`, `26-04-SUMMARY.md`.
- Commits verified: `c044144` (Task 1), `b1652e1` (Task 2).

---
*Phase: 26-the-finished-experience-entry-polish-and-the-2-0-1-release*
*Completed: 2026-07-20*
