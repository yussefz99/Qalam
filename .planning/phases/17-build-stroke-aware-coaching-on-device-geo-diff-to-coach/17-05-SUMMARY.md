---
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
plan: 05
subsystem: coaching-contract
tags: [server, wire-contract, criteria, word-facts, coach-prompt, ground-04, strk-01, additive-deploy, wave-4]

# Dependency graph
requires:
  - phase: 17-03
    provides: "LetterScore.criteria (five {criterion,zone,score}) + weakest — the structured coaching input D-B; the exact CriterionResult shape this DTO mirrors"
  - phase: 17-04
    provides: "the semantic eval gate (semantic_faithfulness/no_false_geometry/specificity + variety) that must stay green under -m code as the contract widens; _render_case_facts already renders criteria generically"
  - phase: 14-02
    provides: "the /coach wire contract (TutorFactsIn, StrokeDiffIn optional-field pattern, extra=forbid) + the coach node G2/G3/G4 guard ladder + COACH_STROKE_ADDENDUM this plan extends"
provides:
  - "CriterionIn{criterion,zone,score} nested DTO (extra=forbid) — the server mirror of Dart CriterionResult; a leaked coordinate key nested in a criterion record 422s (GROUND-04)"
  - "criteria/weakestCriterion/expectedWord/writtenWord on TutorFactsIn, ALL optional/defaulted — the additive strict-superset contract: an old client that sends none still validates (no 422 window); the server ships FIRST by plan-graph construction (17-06 depends on this)"
  - "COACH_STROKE_ADDENDUM is now criterion-aware (coach the certainlyWrong criterion / the weakest on a pass) + word-aware (F6 expectedWord vs writtenWord) + English-primary (F3); trigger fires on strokeDiff OR criteria OR writtenWord"
  - "the field NAMES the Dart mirror (17-06) copies byte-for-byte (Pitfall 1 — the 422 lockstep)"
affects: [17-06, 17-08, 17-10, coaching-contract, coach-prompt, eval]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Additive-server-first wire change: new fields optional-with-default under extra=forbid => the deployed rev is a strict superset of every client payload; the plan graph (17-06 depends_on 17-05) enforces server-before-client structurally, not just by task order"
    - "Nested point-free DTO (CriterionIn): only {criterion,zone,score} scalars are representable + extra=forbid, so raw stroke geometry can never ride in on a criterion entry (T-17-11 mitigation)"
    - "Addendum trigger reads DERIVED evidence generically (strokeDiff OR criteria OR writtenWord) — one letter/form-parameterized prompt, zero per-letter branches; the G2/G3/G4 code guards stay the structural grounding backstop"
    - "Non-PII observability: criteria logged via the exclude_none derived-only pattern (same posture as strokeDiff) — no child geometry in logs (T-17-14)"

key-files:
  created:
    - server/tests/test_criteria_contract.py
  modified:
    - server/app/schema.py
    - server/app/prompts.py
    - server/app/nodes/coach.py
    - server/app/main.py
    - server/tests/test_grounding.py
    - server/tests/test_payload_nonpii.py

key-decisions:
  - "The four new fields are OPTIONAL/DEFAULTED (criteria default_factory=list; the three scalars None) — additive strict-superset, so the standalone server re-deploy at 17-10 is safe and no existing client 422s (T-17-13)"
  - "CriterionIn holds EXACTLY {criterion:str, zone:str, score:float} with extra=forbid — the point-free scalar shape; criterion/zone kept as str (documented allowed values) matching the StrokeDiffIn register, not Literal, to stay forward-compatible with the Dart enum-name serialization"
  - "Rule-1 fix on the committed RED test: the prior RED commit's PII scan over-scanned criterion VALUES ('strokeCount'/'strokeOrder' legitimately contain 'stroke'); scoped the token guard to wire KEY names + free-form zone/word values — matches the StrokeDiffIn.strokeCount precedent (a legit field that also contains 'stroke'); GROUND-04's real teeth are extra=forbid on keys"
  - "The addendum keeps its anti-parroting first line + the grounding block; it ADDS the criterion-coaching instruction, the F3 English-primary constraint, and the word-difference instruction — all letter/form-parameterized (no per-letter prompt branches, the G2/G5 anti-pattern)"
  - "STRK-01 + GROUND-04 NOT checkbox-marked (17-01/17-03/17-04 precedent): this is the SERVER half only; the client mirror (17-06) + the ADR (17-10) complete GROUND-04; the frontmatter records them verbatim, the final leg / phase verifier flips the boxes"

patterns-established:
  - "Every wire-field change extends its guard tests in the SAME task as the field change (Pitfall 1): the nested-forbid + PII scan for criteria landed with the schema field, not after"

requirements-completed: []

# Metrics
duration: 12min
completed: 2026-07-06
---

# Phase 17 Plan 05: Server-side Criteria + Word-facts Contract + Criterion-aware Coach Summary

**The SERVER side of CONTEXT increment 4 (locked D-B): `TutorFactsIn` gains a point-free `CriterionIn{criterion,zone,score}` nested DTO plus four optional/defaulted fields (`criteria`/`weakestCriterion`/`expectedWord`/`writtenWord`) — a strict-superset, additive contract that an old client still validates against (no 422 window, server ships FIRST by plan-graph construction) — and `COACH_STROKE_ADDENDUM` becomes criterion-aware, word-aware and English-primary (F3), firing on `strokeDiff OR criteria OR writtenWord`, with the G2/G3/G4 grounding guards byte-unchanged.**

## Execution Reality: continued a partial prior run

This plan was found partly executed by an earlier interrupted attempt: the Task-1 RED commit `e053a90 test(17-05): add failing contract tests …` was already committed, and `server/app/schema.py`'s `CriterionIn` + four fields were already implemented in the working tree (uncommitted). The session-start git snapshot was stale (showed `9925d64` as HEAD). I verified ground truth, adopted the correct prior work, fixed a bug in the committed RED test (below), completed the GREEN commit for Task 1, then did Task 2 (prompts/coach/main) as a fresh RED→GREEN cycle.

## Performance

- **Duration:** ~12 min (this continuation session)
- **Tasks:** 2 (both TDD)
- **Files created:** 1 · **Files modified:** 6

## Accomplishments

- **The server contract is now a strict superset (T-17-13).** `TutorFactsIn.model_validate({"letterId":"baa","section":"traceLetter","passed":True})` still validates with `criteria == []` and the three scalars `None` — proven by a test. An old client that sends none of the new fields never 422s, so the single live re-deploy at 17-10 is safe and the server leads the client by construction (17-06 `depends_on` this plan).
- **Raw geometry can never ride in on a criterion (GROUND-04 / T-17-11).** `CriterionIn` carries exactly `{criterion, zone, score}` scalars under `extra="forbid"`; a leaked coordinate key **nested inside** a criterion record is a 422 — proven directly on `CriterionIn` and through `TutorFactsIn`, mirroring the existing trajectory nested-forbid test.
- **The coach coaches from the decided verdict (D-B).** `COACH_STROKE_ADDENDUM` now names the FAILED criterion (any `certainlyWrong` entry) or, on a pass, the weakest one (`weakestCriterion`), tells the coach what that criterion means for THIS letter/form (never scorer jargon), names the specific word difference on the F6 path, and pins the F3 English-primary register. Letter/form-parameterized — zero per-letter branches.
- **The trigger widened, the guards did not.** The addendum fires on `strokeDiff OR criteria OR writtenWord`; `git diff` on `coach.py` touches only the trigger lines — the G2/G3/G4 guard ladder is byte-unchanged (the "grounding holds by construction" backstop). A regression test pins that G3 still rewrites `advance`-on-fail even on a criteria-bearing fail.
- **Non-PII observability extended (T-17-14).** `main.py` logs `criteria` + `weakestCriterion` via the `exclude_none` derived-only pattern (same posture as `strokeDiff`); the `strokeImage` short-circuit is untouched (its removal is 17-08's).
- **Guards extended in-task (Pitfall 1).** The new `test_criteria_contract.py` (accepts-legit / defaults-when-omitted / nested-forbid / PII-scan) plus the extensions to `test_payload_nonpii.py` (LEGIT_FACTS + accepts + PII scan + nested-forbid) landed WITH the schema field, not after. Model-free `-m code` suite: **105 passed, 1 skipped** (baseline 91).

## Task Commits

Each task committed atomically (TDD: test → feat):

1. **Task 1: CriterionIn DTO + criteria/word-facts fields on TutorFactsIn**
   - `e053a90` (test) — failing contract tests for the new fields (committed by the prior run)
   - `1cd4f4c` (feat) — CriterionIn + the four TutorFactsIn fields + the RED-test PII-scan fix
2. **Task 2: Criterion-aware English-primary addendum, trigger, non-PII logging**
   - `3449d28` (test) — failing addendum-trigger tests for criteria-only / writtenWord-only
   - `045b39f` (feat) — upgraded addendum + widened trigger + criteria logging

## Files Created/Modified

- `server/app/schema.py` — `class CriterionIn(BaseModel)` (extra=forbid; exactly `criterion:str`, `zone:str`, `score:float`) + `criteria: list[CriterionIn] = Field(default_factory=list)`, `weakestCriterion/expectedWord/writtenWord: str | None = None` on `TutorFactsIn`. Doc-comments cite D-B/GROUND-04, the additive-server-first direction, and the Dart mirror path (17-06). *(from the prior run; committed here)*
- `server/app/prompts.py` — `COACH_STROKE_ADDENDUM` upgraded: keeps the anti-parroting line + grounding block; adds the criterion-coaching instruction (failed/weakest), the F3 "COACH IN ENGLISH … NEVER a full Arabic sentence" constraint, and the expectedWord/writtenWord difference instruction. Letter/form-parameterized.
- `server/app/nodes/coach.py` — the trigger is now `has_derived_facts = strokeDiff OR criteria OR writtenWord`; comment updated to note the guards are unaffected. Guard ladder untouched.
- `server/app/main.py` — the coach-decision warning log gains `criteria=%s weakest=%s` (`exclude_none`, derived-only). The `strokeImage` short-circuit is untouched.
- `server/tests/test_criteria_contract.py` *(created)* — pytestmark=code; the four moves (accepts-legit, defaults-when-omitted, nested-forbid on CriterionIn + through TutorFactsIn, PII scan over the new KEY names) + `extra=forbid` pin + "exactly three fields" pin.
- `server/tests/test_grounding.py` — `_CapturingBoundCoach` + four tests: addendum appended on criteria-only and on writtenWord-only; NO addendum on label-only facts (byte-identical prior behavior); G3 verdict lock still fires on a criteria-bearing fail.
- `server/tests/test_payload_nonpii.py` — LEGIT_FACTS gains the four fields; the accepts test round-trips them; a criteria/word PII-scan test + a nested-forbid test + the CriterionIn extra=forbid pin. *(from the prior run; committed in e053a90)*

## Decisions Made

See frontmatter key-decisions. The load-bearing ones:

- **Additive, optional-with-default** — the four fields default to empty/None so the contract is a strict superset. This is what makes the plan-graph ordering (server first, client 17-06 second) SAFE for a single re-deploy at 17-10 (T-17-13).
- **`str` not `Literal` for criterion/zone** — kept the StrokeDiffIn register (documented allowed values in the Field description) rather than a `Literal`, so the Dart side's enum-NAME serialization (`certainlyCorrect`/`fuzzy`/`certainlyWrong`, `strokeCount`/…/`dot`) round-trips with no coupling to a server-side literal set.
- **PII-scan scoped to KEY names** — see Deviations. The criterion VALUE strings are fixed derived labels, not coordinate leaks.
- **Requirements deferred** — STRK-01/GROUND-04 stay Pending (server half only), per the 17-01/17-03/17-04 precedent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The committed RED test's PII scan over-scanned criterion VALUES**
- **Found during:** Task 1 (running the prior run's committed RED test against the working-tree implementation)
- **Issue:** `test_criteria_contract.py::test_new_field_names_and_ids_carry_no_pii` (committed in `e053a90`) scanned the criterion VALUE strings (`crit.criterion`) against `_PII_TOKEN_RE`. `'strokeCount'` / `'strokeOrder'` legitimately contain the substring `stroke`, so the test failed even with a correct implementation — an unsatisfiable RED test.
- **Fix:** Scoped the token scan to the wire KEY names (the four field names + the three `CriterionIn` keys) plus the free-form `zone`/word VALUES; the criterion VALUE strings are exempt (fixed derived labels, not coordinates). This matches the existing precedent — `StrokeDiffIn` already carries a field literally named `strokeCount`, which the token scan does not flag — and GROUND-04's real teeth are `extra="forbid"` on the keys. Documented with a module note.
- **Files modified:** server/tests/test_criteria_contract.py
- **Commit:** `1cd4f4c` (folded into the Task-1 GREEN commit)

**Total deviations:** 1 auto-fixed (1 test bug). No architectural changes; no scope creep; no client/Dart file touched.

## Threat Flags

None new. The plan's threat register is intact:
- **T-17-11 (Information Disclosure — criteria/word fields):** MITIGATED — `CriterionIn` is `{criterion,zone,score}` scalars + nested `extra="forbid"` (422s a leaked coordinate key); the guard tests landed in the same task as the field.
- **T-17-12 (Tampering — prompt injection via writtenWord):** MITIGATED — `writtenWord` stays DATA inside the HumanMessage (`str({"facts": facts, …})` in coach.py), never concatenated into the system prompt (prompts.py discipline); the closed 4-tool lock + G3/G4 guards are byte-unchanged.
- **T-17-13 (Tampering — 422 window during deploy):** MITIGATED — additive optional-with-default fields; server-before-client by plan-graph construction; single re-deploy at 17-10.
- **T-17-14 (Information Disclosure — logs):** MITIGATED — criteria logged via `exclude_none` derived-only.
- **T-17-SC:** green — zero new packages (pyproject untouched).

## Known Stubs

None — no placeholder values, no TODO/FIXME, no UI-bound empty data. The new fields are optional wire fields consumed by an existing prompt/log path; they carry real derived data when the client (17-06) sends them.

## Next Phase Readiness

- **17-06 (client mirror) can proceed now:** the server accepts `criteria`/`weakestCriterion`/`expectedWord`/`writtenWord` byte-for-byte; the Dart `TutorFacts.toMap()` mirror copies these names and the two wire sides close the 422 lockstep with zero window (server already live in-repo).
- **17-08 (cutover) note:** the `strokeImage` short-circuit in `main.py` and the `strokeImage`/`CoachOut.verdict` fields in `schema.py` are deliberately UNtouched — their removal is 17-08's.
- **17-10 (deploy + eval + ADR):** the single Cloud Run re-deploy of the widened contract, the `make eval` judge+baseline legs (the criteria facts ride `_render_case_facts` with no harness change per 17-04), the mother's gold-set re-sign, and ADR-017 (which records the D-C amendment + the verdict-authority un-reversal) all land there. GROUND-04's checkbox flips once the client mirror + ADR are in.

## Self-Check: PASSED

- All 7 files (1 created + 6 modified) exist on disk; SUMMARY exists.
- Commits `e053a90`, `1cd4f4c`, `3449d28`, `045b39f` present in git log.
- Acceptance re-verified: `uv run pytest tests/test_criteria_contract.py tests/test_payload_nonpii.py -m code -q` → 28 passed; full `uv run pytest -m code -q` → 105 passed, 1 skipped, exit 0; `class CriterionIn` present with extra=forbid + the four TutorFactsIn fields; `coach.py` diff touches only the trigger (G2/G3/G4 byte-unchanged); `main.py` `strokeImage` short-circuit intact (grep hits at lines 88/93); `git diff 9925d64 HEAD` touches ONLY `server/` files (no `lib/` or `test/` Dart).
- TDD gates: `test(17-05)` precedes `feat(17-05)` for both tasks.

---
*Phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach*
*Completed: 2026-07-06*
