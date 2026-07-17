---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 14
subsystem: api
tags: [langchain-tools, function-calling, coach, grounding, tutor-server, python, fastapi]

# Dependency graph
requires:
  - phase: 18 (18-08)
    provides: the coach next-exercise rail + COACH_NEXT_EXERCISE_ADDENDUM (asks for nextExerciseId + rationale)
  - phase: 18 (18-07)
    provides: the Dart TutorPlan parser (_planFrom reads nextExerciseId/intent/rationale)
  - phase: 17 (17-05/17-06)
    provides: weakestCriterion on the wire (the criterion the WHY names) + the coach stroke addendum
provides:
  - The 4 ACTION tools (present_activity/say/give_hint/advance) declare next_exercise_id + rationale as OPTIONAL schema params
  - A schema test proving each ACTION tool declares both params, both optional, action space unchanged
  - Wire tests proving a clean-pass coach decision with a legal next_exercise_id + rationale serializes to CoachOut.args as camelCase nextExerciseId + rationale
  - Wire test proving an off-graph pick + its orphaned rationale are stripped by the coach rail (trust boundary held)
affects: [18-16, teacher-margin-panel, remote_agent_brain, cloud-run-deploy]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Declare optional tool params so a real function-calling model can attach per-attempt data the prompt asks for (an undeclared key is silently dropped by Gemini/Vertex)"
    - "Fake-bound-coach seam (_patch_coach clean_pass) exercises the analyze->coach clean-pass route offline"

key-files:
  created:
    - server/tests/test_tools_schema.py
  modified:
    - server/app/tools.py
    - server/tests/test_endpoint.py
    - server/app/prompts.py

key-decisions:
  - "The fix is the SCHEMA, not the tool body: the server never executes ACTION tools (no tool-return loop), so only the declared params matter for the model's function-calling — bodies keep returning their existing dicts."
  - "next_exercise_id + rationale default to '' (optional) so a clean say/present_activity with no pick stays legal and the word-less-action coercion never breaks."
  - "The G2 action-space lock is unchanged — no 5th tool, ACTION_TOOLS order + ACTION_TOOL_NAMES byte-identical; declaring params does not relax the coach rail (off-graph ids still stripped)."
  - "Tightened COACH_NEXT_EXERCISE_ADDENDUM so the WHY explicitly travels on a clean PASS (rationale never omitted on a pass); grounding rules untouched (scorer still owns pass/fail; WHY carries no verdict/mastery/star claim)."

patterns-established:
  - "Prompt-only tool-arg mechanisms are dead against a real function-calling model unless the tool schema declares the arg — verify the schema, not just the prose (mirrors the Phase-15 dead-wire lesson)."

requirements-completed: [UAT-18-T5, SPEC-18-R1]

# Metrics
duration: ~11min
completed: 2026-07-17
---

# Phase 18 Plan 14: ACTION-tool WHY schema Summary

**Declared next_exercise_id + rationale as optional params on the 4 bound ACTION tools so a real Gemini/Vertex function-calling coach can attach the per-attempt WHY on the common clean-pass path — closing the structural half of the static-feedback gap (UAT T5) at its first, dead link.**

## Performance

- **Duration:** ~11 min (first commit 12:08:11, last automated commit 12:12:48 +03:00)
- **Started:** 2026-07-17T12:08:11+03:00
- **Completed:** 2026-07-17T12:12:48+03:00 (automated tasks); Cloud Run deploy is a terminal human gate
- **Tasks:** 2 automated (Task 3 is a human-action checkpoint — NOT executed here)
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments
- Root-cause fix for the "always the same static WHY" symptom: the 4 ACTION tools now DECLARE `next_exercise_id` + `rationale`, so a real function-calling model can attach the keys the coach addendum has been asking for all along (an undeclared key was silently dropped, leaving `rationale` null on nearly every clean pass and forcing the client to a fixed fallback string).
- Proved the whole already-built chain now carries the data end-to-end: a clean-pass coach decision with a LEGAL `next_exercise_id` + `rationale` serializes to `CoachOut.args` as camelCase `nextExerciseId` + `rationale` — the exact shape `remote_agent_brain.dart` `_planFrom` reads into `TutorPlan`.
- Proved the trust boundary is unchanged (T-18-14-01): an off-graph / hallucinated `next_exercise_id` (not in `legalNextExerciseIds`) is stripped by the coach rail, and its now-orphaned `rationale` is dropped with it — an illegal pick never reaches the client.
- Tightened `COACH_NEXT_EXERCISE_ADDENDUM` so the clean-pass branch is explicit (the WHY/rationale always travels on a pass, naming what the child did well + what comes next), with zero change to the grounding rules.

## Task Commits

Each task was committed atomically:

1. **Task 1 (TDD): Declare next_exercise_id + rationale as ACTION-tool parameters**
   - RED: `dfe044a` (test) — new `test_tools_schema.py` fails against the current narrow signatures
   - GREEN: `2b3fefd` (feat) — added the two optional params to all 4 `@tool` functions
2. **Task 2: Prove the clean-pass WHY survives the wire, keep the addendum grounded** - `9489494` (test)
   - clean-pass wire tests (present_activity + say), illegal-pick strip test, `_patch_coach` clean_pass seam, addendum tightening

_Task 1 followed the TDD RED → GREEN gates; no refactor commit was needed (implementation was clean)._

## Files Created/Modified
- `server/app/tools.py` - Each ACTION tool (present_activity/say/give_hint/advance) now declares `next_exercise_id: str = ""` + `rationale: str = ""`; docstrings mirror the addendum's ask (pick FROM legalNextExerciseIds, rationale carries no verdict/mastery/star claim). Bodies + ACTION_TOOLS order + ACTION_TOOL_NAMES unchanged.
- `server/tests/test_tools_schema.py` (new) - Asserts each ACTION tool declares both WHY params, both optional (calls omitting them validate), and the action space is still exactly the four names.
- `server/tests/test_endpoint.py` - New clean-pass wire tests (legal pick + rationale reach the wire as camelCase, on both present_activity and say) and an illegal-pick strip test; `_patch_coach` gained `clean_pass` to route analyze→coach with an empty-struggle Insight.
- `server/app/prompts.py` - `COACH_NEXT_EXERCISE_ADDENDUM` "WHY THIS PICK" bullet tightened to state the rationale is never omitted on a clean pass (names what the child did well + what comes next); grounding rules unchanged.

## Verification
- `cd server && python -m pytest tests/test_tools_schema.py tests/test_endpoint.py -m code` → **34 passed**.
- Full `-m code` suite → **165 passed, 1 skipped** (the Vertex-judge eval leg is skipped in `-m code` by design; no regressions).
- The change is additive/optional (no request-DTO change, no 422 window on re-deploy); the action space is still exactly the 4 tools.

## Decisions Made
See frontmatter `key-decisions`. In short: fix the schema not the body (server never executes tools); params optional to keep the clean/word-less paths legal; G2 lock + coach rail unchanged; addendum tightened for the clean-pass WHY without touching grounding.

## Deviations from Plan

None - plan executed exactly as written. (Task 1 followed the plan's TDD flow; Task 2's optional prompts.py tightening was applied because the "WHY THIS PICK" bullet read struggle-oriented — the plan explicitly permitted this tightening.)

## Issues Encountered
- Worktree isolation initially rejected an absolute Write to the shared-checkout path; re-issued against the worktree root. No impact on output.

## Threat Flags
None - no new security surface. The change declares two optional, non-PII text params on existing tools; the coach rail (T-18-14-01) and extra=forbid DTO are unchanged. `rationale` remains a short criterion-naming phrase with no verdict/mastery/star claim (ADR-014), enforced by the addendum + tests (T-18-14-02). No new Python dependencies (T-18-14-03).

## Known Stubs
None introduced by this plan. (The client-side static fallback `_authoredWhy(...)` in `teacher_margin_panel.dart` is the PROVISIONAL offline floor that 18-16 replaces once this `rationale` flows live — it is not a stub introduced here and is out of this plan's scope.)

## User Setup Required
**Terminal human gate — Cloud Run re-deploy (Task 3) — DONE 2026-07-17.** Owner explicitly authorized ("yes do it so we can test now on the ipad"); orchestrator ran `gcloud run deploy qalam-tutor --source server --project qalam-app-bd7d0 --region us-central1` → revision **qalam-tutor-00027-nqw** serving 100% traffic (was `qalam-tutor-00026-nz5`). `GET /health` → **200**. The change was forward-safe as predicted (additive optional params only, no request-DTO change, no 422 window). On-device verification (a real UAT build, NOT `--dart-define=DEMO=true`) is the owner's next step: complete a clean baa pass and confirm the Teacher's Margin WHY varies per attempt (client presentation finished by 18-16, now unblocked by this deploy).

## Next Phase Readiness
- Server half of UAT-T5 structural fix is complete and green; the per-attempt WHY can now flow to the client on the clean-pass path once the deploy lands.
- 18-16 (client presentation + fallback-variance) reads this `rationale` — unblocked by this plan.
- Blocker to full close: the Cloud Run re-deploy (owner-run) so the new tool schema is live.

## Self-Check: PASSED
- Files verified present: `server/tests/test_tools_schema.py`, `server/app/tools.py`, `server/tests/test_endpoint.py`, `server/app/prompts.py`.
- Commits verified present: `dfe044a` (RED test), `2b3fefd` (GREEN feat), `9489494` (clean-pass wire + prompt tighten).

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-17 (automated tasks; Cloud Run deploy pending human gate)*
