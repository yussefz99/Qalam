---
phase: 15-build-dynamic-grounded-exercise-selection-on-baa
plan: 06
subsystem: server
tags: [grounding, eval, faithfulness, ground-03, server, pytest]

# Dependency graph
requires:
  - phase: 15-build-dynamic-grounded-exercise-selection-on-baa
    plan: 01
    provides: "the RED test (test_faithfulness.py) + the labeled fixture (faithfulness_set.jsonl, 9 faithful gold + 4 adversarial) — the exact contract this plan turns green"
provides:
  - "server/app/faithfulness.py — the deterministic, model-AGNOSTIC GROUND-03 faithfulness check: _contradicts(passed, coaching, expected_fix) flags praise-on-fail + wrong-fix; evaluate_faithfulness(path) returns {faithful, total, rate, flagged}; faithfulness_rate(cases) helper; runnable as `python -m app.faithfulness`"
  - "the GROUND-03 floor (not ceiling) seed that Phase 13/16 grow into the full Claude-vs-Gemini bake-off + the calibrated-judge regression gate"
affects: [13, 16]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Model-free faithfulness check (pytest.mark.code): score coaching lines against FIXED scorer verdicts, no model/auth/Firebase — a pure offline file read that gates every PR"
    - "Both failure modes gated on a FAIL (praise + expected-fix evaluated only when passed=False) so a faithful PASS that praises clean work is correctly not flagged"

key-files:
  created:
    - server/app/faithfulness.py
  modified: []

key-decisions:
  - "Lifted the RESEARCH inline `_contradicts` + `_PRAISE` lexicon verbatim into app/faithfulness.py (the test imports both `_contradicts` and `evaluate_faithfulness` from app.faithfulness) — the lexicon is byte-identical to the RESEARCH code example (beautiful/perfect/great job/well done/أحسنت/mastered)"
  - "evaluate_faithfulness returns {faithful, total, rate, flagged} (a list, not just a count) — the test asserts `len(flagged)==4`, `faithful==9`, `total==13`, and `faithful + len(flagged) == total`; flagged is the list of contradicting cases so the report is self-describing for Phase 13/16"
  - "Both praise-on-fail and wrong-fix are gated on `not passed` — REQUIRED because a faithful gold PASS case ('Beautiful — a deep, smooth bowl. أحسنت!') contains TWO praise tokens; gating on the verdict is what keeps the gold rate at 9/9 over the pass cases"
  - "Documented explicitly as a FLOOR not a ceiling (A6 / threat T-15-06-R accepted): the substring lexicon is coarse by design for the minimal D-10 slice; the calibrated-judge ceiling is Phase 13/16 scope"
  - "Fixture + test from 15-01 were NOT modified — they already satisfied the contract exactly (13 cases: 9 faithful + 4 adversarial); the plan's only new artifact is app/faithfulness.py"

requirements-completed: [GROUND-03]

# Metrics
duration: 2min
completed: 2026-06-27
---

# Phase 15 Plan 06: Model-Free GROUND-03 Faithfulness Check Summary

**A deterministic, model-agnostic Python check (`server/app/faithfulness.py`) that scores coaching lines against fixed scorer verdicts — flagging any coaching that praises a failed stroke or names the wrong fix — and reports a faithfulness RATE over a labeled set, turning the 15-01 RED faithfulness tests green (9/13 = 69.23%, 4 adversarial flagged).**

## Performance

- **Duration:** 2 min
- **Completed:** 2026-06-27
- **Tasks:** 1
- **Files modified:** 1 created

## Accomplishments

- **The GROUND-03 floor is built and green** — `app/faithfulness.py` provides `_contradicts(passed, coaching, expected_fix)` (the per-pair predicate the flag tests assert on) and `evaluate_faithfulness(path)` (the rate reporter), turning all three 15-01 RED tests green: `test_flags_praise_on_fail`, `test_flags_wrong_fix`, `test_faithfulness_rate_reported`.
- **It is model-AGNOSTIC and offline** — the module imports with no model, no auth, and no Firebase loaded (`import app.faithfulness` verified clean); it scores coaching against FIXED verdicts so it works for Claude OR Gemini output identically and does NOT pre-empt the Phase-13 model choice. The test carries `pytestmark = pytest.mark.code` (a model-free `code` check that gates every PR).
- **The faithfulness RATE is reported** — `evaluate_faithfulness` returns `{faithful, total, rate, flagged}`; over the constructed-faithful gold set the rate is `9/13 = 69.23%` (the 4 adversarial cases are correctly flagged, the 9 faithful gold cases are not). The module is also runnable as a standalone reporter: `python -m app.faithfulness`.
- **Documented as a seed/floor, not a ceiling** — the `_PRAISE` lexicon + the expected-fix substring rule are coarse by design for the minimal D-10 slice (A6); Phase 13/16 grow this into the full Claude-vs-Gemini bake-off + the calibrated-judge regression gate.

## Task Commits

Each task was committed atomically:

1. **Task 1: Deterministic faithfulness check + the GROUND-03 tests green** - `617fa4b` (feat)

## Files Created/Modified

- `server/app/faithfulness.py` (created) — the GROUND-03 check. `_PRAISE` lexicon (beautiful/perfect/great job/well done/أحسنت/mastered, byte-identical to RESEARCH); `_contradicts(passed, coaching, expected_fix)` flags praise-on-fail and wrong-fix, BOTH gated on `not passed`; `faithfulness_rate(cases)` helper (0.0 on empty); `evaluate_faithfulness(path)` returns `{faithful, total, rate, flagged}` from a pure offline JSONL read; a `__main__` block prints the rate. Module docstring documents the FLOOR-not-ceiling stance (A6) and notes `.dockerignore` excludes `tests/` so the fixture never ships to the image.

The fixture (`server/tests/fixtures/faithfulness_set.jsonl`) and test (`server/tests/test_faithfulness.py`) authored in 15-01 were NOT modified — they already satisfied the contract exactly (13 cases: 9 faithful gold + 4 adversarial).

## Decisions Made

- **Lifted `_contradicts` + `_PRAISE` verbatim from RESEARCH** into `app/faithfulness.py` (the 15-01 test imports both `_contradicts` and `evaluate_faithfulness` from `app.faithfulness`). The lexicon is byte-identical to the RESEARCH code example.
- **`evaluate_faithfulness` returns a `flagged` LIST, not just a count** — the test asserts `len(flagged) == 4`, `faithful == 9`, `total == 13`, and `faithful + len(flagged) == total`. Returning the list of contradicting cases makes the report self-describing for the Phase 13/16 harness.
- **Both failure modes gated on `not passed`** — REQUIRED, not stylistic: a faithful gold PASS case (`"Beautiful — a deep, smooth bowl. أحسنت!"`) contains two praise tokens. Gating the praise + expected-fix checks on the verdict is exactly what keeps the gold rate at 9/9 over the pass cases.
- **Documented as a FLOOR not a ceiling** (A6 / threat T-15-06-R, accepted) — the substring lexicon is coarse by design for the minimal D-10 slice; the calibrated-judge ceiling is Phase 13/16 scope.

## Deviations from Plan

None - plan executed exactly as written.

The fixture and test already encoded the precise contract (13 cases, the two required adversarial entries) from 15-01, so no fixture authoring was needed beyond writing the module under test. No auto-fix rules (1–3) or architectural decisions (Rule 4) were triggered: the implementation is a pure offline deterministic function with no external surface to harden.

## Issues Encountered

None. The single verification run passed first time (`tests/test_faithfulness.py -s -q` → 3 passed, rate printed); the full server suite is green (70 passed, no regressions).

## Known Stubs

None. `app/faithfulness.py` is a complete, exercised function — all three tests assert real behavior over the labeled set, and the module is runnable as a reporter. The coarse `_PRAISE` lexicon is NOT a stub: it is the deliberate D-10 minimal floor (A6), documented in the module docstring as the seed Phase 13/16 grow into the calibrated judge.

## Threat Surface

No new security-relevant surface. The plan's `<threat_model>` is satisfied:
- **T-15-06-T** (Tampering — coaching contradicts the geometry verdict): MITIGATED — the deterministic check flags praise-on-fail + wrong-fix and reports a rate; a regression drops the rate (GROUND-03). Model-agnostic floor; Phase 13/16 add the calibrated judge.
- **T-15-06-R** (eval gap — lexicon too coarse): ACCEPTED as designed (A6) — coarse by design for the minimal slice; documented as a floor in the module docstring.
- **T-15-SC** (pip installs): MITIGATED — zero packages installed this phase (RESEARCH § Package Legitimacy: N/A).

The check calls no model and needs no auth/Firebase — it introduces no network endpoint, no trust boundary, and no PII surface (it reads only the offline labeled fixture, which `.dockerignore` keeps out of the image).

## Verification

- `cd server && uv run pytest tests/test_faithfulness.py -s -q` → **3 passed**, `GROUND-03 faithfulness rate: 9/13 = 69.23%` printed.
- Per-wave merge: full server suite `cd server && uv run pytest -q` → **70 passed** (no regressions; the previously-RED-by-missing-symbol faithfulness file now collects + passes).
- `uv run python -c "import app.faithfulness"` → clean import (no model/auth/Firebase) — confirms model-agnostic + offline.
- `uv run python -m app.faithfulness` → standalone reporter prints `9/13 = 69.23%  (4 flagged)`.

## Next Phase Readiness

- **GROUND-03 is complete for Phase 15** — the narrow D-10 slice ships: a measured faithfulness rate over a labeled set, model-agnostic, offline.
- **Phase 13/16** grow this seed into the full Claude-vs-Gemini bake-off + the calibrated-judge regression gate (the AI-SPEC §5 D1/D2 dimensions, incl. the Arabic-register dimension deliberately left out of this floor). `evaluate_faithfulness`'s `{faithful, total, rate, flagged}` report shape is the seam they extend.
- The faithfulness check is the last GROUND-03 artifact; remaining Phase-15 work is the dynamic-selection wiring (15-05) and the owner-mother sign-off checkpoint (15-07).

## Self-Check: PASSED

- `server/app/faithfulness.py` verified on disk.
- Task commit `617fa4b` verified in git history.

---
*Phase: 15-build-dynamic-grounded-exercise-selection-on-baa*
*Completed: 2026-06-27*
