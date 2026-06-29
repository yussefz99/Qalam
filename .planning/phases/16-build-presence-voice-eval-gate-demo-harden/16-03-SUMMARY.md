---
phase: 16-build-presence-voice-eval-gate-demo-harden
plan: 03
subsystem: testing
tags: [eval, faithfulness, llm-judge, vertex, gemini-2.5-flash, pytest, makefile, grounding]

# Dependency graph
requires:
  - phase: 16-01
    provides: "the eval RED contract (test_eval_harness.py importing tests.test_eval.run_eval) + the keyless Vertex routing table"
  - phase: 15-06
    provides: "the model-free faithfulness seed (app/faithfulness.py + fixtures/faithfulness_set.jsonl)"
  - phase: 14
    provides: "14-AI-SPEC §5 — the four eval dimensions (D1 faithfulness, D2 names-fix, D5 register, correct-Arabic) + §1b no-training constraint"
provides:
  - "Grown zero-tolerance faithfulness gate covering every signed baa mistakeId × pass/fail (D-08)"
  - "server/tests/test_eval/ harness — per-dimension scores for all four §5 dimensions (D-10)"
  - "Vertex LLM-judge runner (gemini-2.5-flash, judge != coach) for register + correct-Arabic (D-09)"
  - "Claude-drafted gold_set.jsonl (signed:false) awaiting mom sign-off in 16-05"
  - "`make eval` — the local pre-merge gate that exits non-zero below threshold (D-07)"
affects: [16-05, 16-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-leg eval harness: model-free zero-tolerance D1/D2 (gates every PR under -m code) + Vertex LLM-judge D5/correct-Arabic (threshold, runs under make eval)"
    - "Judge != coach-under-test (gemini-2.5-flash judge) to avoid self-grading bias"
    - "Lazy Vertex import so importing the runner needs no ADC; only `make eval` reaches Vertex"
    - "make eval as the local documented pre-merge gate (not CI), bake-off-ready via env-swap"

key-files:
  created:
    - server/tests/test_eval/run_eval.py
    - server/tests/test_eval/run_judge.py
    - server/tests/test_eval/JUDGE_RUBRIC.md
    - server/tests/test_eval/gold_set.jsonl
    - server/Makefile
  modified:
    - server/tests/fixtures/faithfulness_set.jsonl
    - server/tests/test_faithfulness.py

key-decisions:
  - "D1 zero-tolerance leg scores ONLY the label==faithful gate subset (adversarial probes are SUPPOSED to contradict); the probes are gated by separate flag tests so a loosened _contradicts is caught"
  - "faithfulness.py + _PRAISE lexicon left UNCHANGED — every praise word the new fixtures use is already covered; only the labeled set + tests grew (model-free floor preserved)"
  - "Rewrote the brittle hardcoded count assertions in test_faithfulness.py to be label-driven so the set can grow without re-editing the test (Rule 1)"
  - "Judge built via ChatVertexAI directly (gemini-2.5-flash, keyless ADC, thinking_budget=0) mirroring app/models.py; gate threshold 0.7 (the ≥0.7 calibration bar)"
  - "make eval = eval-code (zero-tolerance model-free) && eval-judge (Vertex judge); short-circuits so a D1<100% fail skips the judge run and exits non-zero"

patterns-established:
  - "Pattern: JSONL labeled-set loaders skip `#`-prefixed header/comment lines (gold_set.jsonl carries the D-10 no-training note as a header)"
  - "Pattern: gold set is a SEPARATE JSONL from the faithfulness fixture; Claude DRAFTS (signed:false / drafted_by:claude), owner's mother SIGNS in 16-05"

requirements-completed: [EVAL-01, EVAL-02]

# Metrics
duration: 14min
completed: 2026-06-29
---

# Phase 16 Plan 03: Eval Gate (faithfulness + LLM-judge + make eval) Summary

**Promoted the Phase-15 model-free faithfulness seed into the EVAL-01/EVAL-02 regression gate: a grown zero-tolerance faithfulness check over every baa mistake × pass/fail, a per-dimension eval harness for all four 14-AI-SPEC §5 dimensions, a gemini-2.5-flash Vertex LLM-judge (judge != coach) for register + correct-Arabic, a Claude-drafted gold set awaiting mom sign-off, and `make eval` as the local pre-merge gate.**

## Performance

- **Duration:** ~14 min
- **Started:** 2026-06-29T (plan execution)
- **Completed:** 2026-06-29
- **Tasks:** 3
- **Files modified/created:** 7

## Accomplishments
- **Grew the zero-tolerance faithfulness gate (D-08):** the labeled set now covers all six signed baa mistakeIds (shallowBowl, noDot, hasTail, tooBig, lifted, missingDot) in a faithful + praise-on-fail + wrong-fix variant (6 praise probes, 6 wrong-fix probes, 11 faithful cases). A D1==100% zero-tolerance assertion fails the build on any contradiction; the adversarial probes catch a loosened `_contradicts`.
- **Built the eval harness (D-10):** `run_eval.score_eval_set` returns per-dimension scores for all four §5 dimensions — D1 faithfulness + D2 names_fix model-free (reusing `app.faithfulness`), D5 register + correct_arabic via the Vertex judge (skipped in the offline `-m code` leg). The 16-01 RED eval test is now GREEN, which also un-breaks the full `-m code` suite collection (78 passed / 1 skipped).
- **Wired the Vertex LLM-judge (D-09):** `run_judge.py` builds a keyless gemini-2.5-flash judge (distinct from the coach-under-test, avoiding self-grading bias) that scores register + correct-Arabic against `JUDGE_RUBRIC.md` and exits non-zero below the 0.7 threshold.
- **Drafted the gold set:** `gold_set.jsonl` with Claude-drafted (verdict → ideal-coaching) examples, every line `"signed": false` / `"drafted_by": "claude"`, plus the D-10 no-training/consent note. Awaits mom sign-off in 16-05 (NOT marked signed here).
- **Wired `make eval` (D-07):** the local documented pre-merge gate (not CI), bake-off-ready via env-swap.

## Task Commits

Each task was committed atomically:

1. **Task 1: Grow the zero-tolerance faithfulness gate** - `23137c2` (test)
2. **Task 2: Build the eval harness + Vertex LLM-judge + gold-set draft + rubric** - `60d4ed4` (feat)
3. **Task 3: Wire `make eval`** - `f685915` (chore)

**Plan metadata:** (this commit) (docs: complete plan)

## Files Created/Modified
- `server/tests/fixtures/faithfulness_set.jsonl` - Grown labeled set: every baa mistakeId × {faithful, praise-on-fail, wrong-fix} + faithful PASS cases
- `server/tests/test_faithfulness.py` - Added zero-tolerance D1==100% assertion + every-mistake coverage + every-probe-flagged; made rate-report counts label-driven
- `server/tests/test_eval/run_eval.py` - `score_eval_set` (4 §5 dims) + `gate_passes`; D1/D2 model-free, D5/correct-Arabic judge legs
- `server/tests/test_eval/run_judge.py` - Vertex gemini-2.5-flash judge runner (judge != coach), keyless ChatVertexAI, lazy import, exits non-zero below 0.7
- `server/tests/test_eval/JUDGE_RUBRIC.md` - register + correct-Arabic rubric anchored to CLAUDE.md tutor's voice + national grade-1 curriculum
- `server/tests/test_eval/gold_set.jsonl` - Claude-drafted gold (signed:false, drafted_by:claude) + D-10 no-training header note
- `server/Makefile` - `eval` target (eval-code zero-tolerance && eval-judge); local pre-merge, bake-off-ready by env-swap

## Decisions Made
- **D1 leg scores only the faithful gate subset** — the adversarial probes are meant to contradict, so the zero-tolerance rate is computed over `label==faithful` cases; the probes are independently asserted-flagged so a loosened `_contradicts` still fails the build.
- **No model added to faithfulness** — D-08 says grow the seed, do not hand-roll a judge for faithfulness. The `_PRAISE` lexicon already covered every praise word the new fixtures use, so `faithfulness.py` is untouched (model-free floor preserved).
- **Judge is gemini-2.5-flash, not the coach** — avoids self-grading bias (16-RESEARCH Open Q2 / T-16-03-03); threshold 0.7 (the ≥0.7 calibration bar before the judge is trusted to gate).
- **make eval short-circuits** — `eval-code && eval-judge`, so a D1<100% failure skips the judge and exits non-zero (D-08 zero-tolerance enforced first).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rewrote brittle hardcoded count assertions in test_faithfulness.py**
- **Found during:** Task 1 (Grow the faithfulness gate)
- **Issue:** The existing `test_faithfulness_rate_reported` hardcoded `len(report["flagged"]) == 4` and `report["faithful"] == 9` against the seed set. Growing the labeled set (the plan's explicit Task 1 action) would have broken these exact-count assertions, making the test impossible to keep GREEN while satisfying the plan.
- **Fix:** Replaced the hardcoded counts with label-driven counts (`len(_by_label("faithful"))`, `len(praise)+len(wrong_fix)`), so the assertion verifies the invariant (every faithful case faithful, every adversarial flagged) rather than a frozen number — robust to set growth.
- **Files modified:** server/tests/test_faithfulness.py
- **Verification:** `uv run pytest tests/test_faithfulness.py -m code -q` → 6 passed
- **Committed in:** 23137c2 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** The fix was necessary to execute the plan's own Task 1 action (growing the set) without leaving a brittle test red. No scope creep — only the in-scope test file changed.

## Issues Encountered
None — all three tasks executed as written, verifications passed first time after the label-driven test rewrite.

## Known Stubs
The Vertex LLM-judge legs (register / correct_arabic) report `{"score": None, "skipped": ...}` in the offline `-m code` context by design — this is NOT a stub of incomplete work but the intended two-leg split (model-free legs gate every PR; the judge leg runs under `make eval` with live Vertex). The gold_set.jsonl is `"signed": false` by design — Claude DRAFTS, the owner's mother SIGNS in 16-05; the live judge run + ≥0.7 calibration are exercised at wave-merge after 16-05. No unintended stubs.

## User Setup Required
None — no external service configuration required to land this plan. The live `make eval` judge run reaches Vertex (keyless ADC, project qalam-app-bd7d0) and is exercised at wave-merge after the 16-05 mom sign-off + calibration.

## Next Phase Readiness
- **16-05 (mom sign-off):** the gold set is drafted and ready for the owner's mother to review and flip `signed:false` → `signed:true`; the judge calibration (≥0.7 correlation vs her labels) rides this harness.
- **16-06 (Claude-vs-Gemini bake-off):** `make eval` is bake-off-ready by env-swap (`COACH_MODEL_PROVIDER=anthropic_vertex COACH_LOCATION=global make eval` vs the Gemini run); the judge stays Gemini.
- No blockers.

## Self-Check: PASSED

All 8 created/modified files exist on disk; all 3 task commits (23137c2, 60d4ed4, f685915) are in the git log.

---
*Phase: 16-build-presence-voice-eval-gate-demo-harden*
*Completed: 2026-06-29*
