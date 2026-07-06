---
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
plan: 04
subsystem: eval
tags: [eval, llm-judge, vertex, gemini-2.5-flash, faithfulness, variety, gold-set, pytest, strk-01, eval-03]

# Dependency graph
requires:
  - phase: 16-presence-voice-eval-demo
    provides: "run_eval.py/run_judge.py two-leg harness + make eval gate + D1 zero-tolerance discipline (16-03)"
  - phase: 15-curriculum-graph
    provides: "app/faithfulness.py model-free floor (_PRAISE lexicon + _contradicts, 15-06)"
  - phase: "17 spike (SPIKE-FINDINGS)"
    provides: "measured substring false-flag rate 0.55–0.73 / 0 real contradictions; two-arm design; adv_broken_but_pass trap"
provides:
  - "Semantic eval gate: semantic_faithfulness + no_false_geometry + specificity Vertex-judge legs (JUDGE_RUBRIC.md sections, judge != coach, thinking_budget=0)"
  - "names_fix (D2 substring) demoted to ADVISORY — reported, never gating; D1 live-line leg = evaluate_praise_floor (praise-lexicon only, أحسنت incl.)"
  - "variety_report(lines, exemplars): pure model-free duplicate/verbatim-exemplar detector, gates every PR under -m code"
  - "run_baseline.py: two-arm STRK-01 instrument (geo-facts arm vs label-only arm) through the PRODUCTION coach node; 0 grounding violations required in BOTH arms"
  - "gold_set.jsonl regrown for stroke-level coaching: 10 new cases (all signed:false), StrokeDiffIn-vocabulary facts, adv_broken_but_pass + F3 full-Arabic traps"
  - "run_judge trap legs: adversarial cases judged individually on trapDimension, must score BELOW threshold (judge must CATCH them)"
affects: [17-05, 17-06, 17-09, 17-10, eval, coaching-contract]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-leg eval discipline extended: model-free legs (D1 floor / advisory D2 / variety) gate every PR; five judge legs + traps + baseline gate under make eval"
    - "Trap-case inversion: adversarial probes are excluded from judge means and individually checked BELOW threshold — a missed trap fails the gate"
    - "Live-line vs authored-label split: variety and the praise floor score `coaching` (live) lines; `idealCoaching` gold labels are register anchors, never parroting evidence"

key-files:
  created:
    - server/tests/test_eval/run_baseline.py
    - server/tests/test_eval/test_variety.py
  modified:
    - server/app/faithfulness.py
    - server/tests/test_eval/run_eval.py
    - server/tests/test_eval/run_judge.py
    - server/tests/test_eval/JUDGE_RUBRIC.md
    - server/tests/test_eval/gold_set.jsonl
    - server/tests/test_eval/test_eval_harness.py
    - server/Makefile

key-decisions:
  - "D1 live-line leg routes through evaluate_praise_floor (praise-lexicon only); evaluate_faithfulness is byte-unchanged so the substring rule keeps pinning the fixture set (test_faithfulness.py green throughout)"
  - "D1 gate subset broadened to all NON-adversarial cases — the old label=='faithful' filter was EMPTY over the gold set, so faithfulness_rate([])==0.0 would have hard-failed every make-eval judge run (latent 16-03 landmine)"
  - "Adversarial trap cases are excluded from judge dimension means and checked individually on trapDimension: the judge must score them BELOW threshold; a missed trap fails the gate (otherwise a missed trap RAISES the mean — backwards incentive)"
  - "Variety scores live `coaching` lines only, never authored idealCoaching gold labels — gold case #2 IS the mother's canonical exemplar verbatim; flagging it would permanently fail the gate"
  - "EVAL-03/STRK-01 deliberately NOT checkbox-marked here (17-01 precedent): STRK-01 spans to 17-09; EVAL-03 completes at the 17-10 mother re-sign human gate"
  - "make eval judge + baseline legs DEFERRED to 17-10: ADC absent this session; structure verified via make -n eval (eval-code → run_judge → run_baseline)"

patterns-established:
  - "trapDimension key on adversarial gold cases names the judge leg the trap calibrates"
  - "run_baseline strips STROKE_FACT_KEYS=(strokeDiff, criteria) for arm B — the Plan 17-05 structured criteria ride the same seam with no baseline change"

requirements-completed: [EVAL-03, STRK-01]

# Metrics
duration: 33min
completed: 2026-07-06
---

# Phase 17 Plan 04: Eval Semantic Gate + STRK-01 Baseline Summary

**Semantic faithfulness/no-false-geometry/specificity judge legs + a model-free variety leg replace the substring gate for live coach lines; the praise-lexicon floor stays zero-tolerance; a two-arm production-coach baseline instrument and a regrown stroke-level gold set (all signed:false) give STRK-01 its yardstick.**

## Performance

- **Duration:** ~33 min
- **Started:** 2026-07-06T11:05:36Z
- **Completed:** 2026-07-06T11:38:30Z
- **Tasks:** 2 (both TDD)
- **Files modified:** 9

## Accomplishments

- The eval gate no longer false-fails correct paraphrases: `names_fix` (the expected-fix substring rule, measured 0.55–0.73 false-flag rate with 0 real contradictions by the spike) is demoted to advisory; a `semantic_faithfulness` judge leg replaces it for meaning-level verdict agreement.
- Invented geometry is now catchable: the `no_false_geometry` judge leg checks every geometric claim against the rendered strokeDiff/criteria facts, with the canonical `adv_broken_but_pass` trap (flat-bowl PASS + "deep, smooth bowl" line) in the gold set — run_judge must see the judge score the trap BELOW threshold or the gate fails.
- The D1 praise-lexicon floor (`evaluate_praise_floor`, praise-on-fail incl. أحسنت) stays zero-tolerance and model-free — `test_faithfulness.py` and `test_eval_harness.py` stayed green through every commit.
- STRK-01 is measurable: `run_baseline.py` runs every stroke-level gold fixture through the PRODUCTION coach node twice (with vs without derived stroke facts) and exits non-zero unless the stroke-aware arm beats label-only on specificity (judge) AND variety (model-free) with 0 grounding violations in BOTH arms.
- Gold set regrown for stroke-level coaching: 10 appended cases (shallow-bowl, right-side-flat, dot-left, dot-above identity, tail, too-big, 2 paraphrase-FAITHFUL probes, the no-false-geometry trap, an F3 full-Arabic trap) — every one `signed:false / drafted_by:claude`, all strokeDiff facts restricted to the point-free `StrokeDiffIn` vocabulary (T-17-08 / T-17-09 mitigations verified by grep + test).

## Task Commits

Each task was committed atomically (TDD: test → feat):

1. **Task 1: Semantic faithfulness + no-false-geometry judge legs; retire the substring gate for live lines**
   - `a5020fb` (test) — failing tests: registry coverage, gate composition, advisory demotion, praise floor
   - `ac88722` (feat) — evaluate_praise_floor, DIMENSIONS+4, gate_passes rework, judge legs + rubric sections, trap legs
2. **Task 2: Model-free variety detector, two-arm STRK-01 baseline, gold-set regrow**
   - `f28b7dc` (test) — failing tests: variety_report contract, regrown gold-set contract, baseline import safety
   - `061acf6` (feat) — variety_report, run_baseline.py, gold_set.jsonl regrow, Makefile eval-baseline leg

## Files Created/Modified

- `server/app/faithfulness.py` — `evaluate_praise_floor(cases)` added (32 insertions, 0 deletions; `evaluate_faithfulness` byte-unchanged)
- `server/tests/test_eval/run_eval.py` — DIMENSIONS 4→8; D1 routed through the praise floor; names_fix advisory; `variety_report` + `exemplar_lines`; gate_passes: ran-judge-legs threshold + variety leg
- `server/tests/test_eval/run_judge.py` — JUDGE_DIMENSIONS 2→5; `_render_case_facts` renders strokeDiff/criteria generically (17-05 criteria need no harness change); `judge_traps` trap legs
- `server/tests/test_eval/JUDGE_RUBRIC.md` — rubric sections for semantic_faithfulness / no_false_geometry / specificity
- `server/tests/test_eval/gold_set.jsonl` — Phase-17 regrow header (mother re-signs the WHOLE set), 10 existing cases kept verbatim, 10 stroke-level cases appended
- `server/tests/test_eval/test_eval_harness.py` — 6 new model-free tests (registry, gate, advisory demotion, praise floor)
- `server/tests/test_eval/test_variety.py` — NEW: variety detector + gold-set contract + baseline import-safety tests (`pytest.mark.code`)
- `server/tests/test_eval/run_baseline.py` — NEW: the two-arm STRK-01 instrument (integration, `make eval` only)
- `server/Makefile` — `eval: eval-code eval-judge eval-baseline`; eval-code gains test_variety.py, stays model-free

## Decisions Made

See frontmatter key-decisions. Notable design elaborations within plan discretion:

- **Trap semantics** — adversarial gold cases carry a `trapDimension`; run_judge checks each trap individually (score must be BELOW threshold = judge CAUGHT it) instead of averaging traps into the gate means, where a missed trap would perversely raise the score.
- **Variety domain** — the variety leg and exemplar-echo detector apply to live `coaching` lines only; authored `idealCoaching` gold labels are the mother's register anchors (one deliberately IS an exemplar) and are never parroting evidence.
- **Baseline invokes the production coach node** (`app.nodes.coach.coach`) directly with `{facts, insight: {}, plan: None}` — real prompt, real addendum trigger, real G2/G3/G4 guards — rather than re-implementing a spike-style coach, so baseline numbers map to what ships.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Empty faithful-gate subset hard-failed the gold-set gate**
- **Found during:** Task 1 (D1 praise-floor routing)
- **Issue:** `_faithful_gate_cases` filters `label == "faithful"`, but gold_set labels are `gold_*` — the subset was EMPTY, and `faithfulness_rate([]) == 0.0`, so every `make eval` judge run would have failed the D1 gate regardless of content (latent since 16-03; masked because ADC judge runs were deferred).
- **Fix:** D1 praise floor now gates over all NON-adversarial cases (`_praise_gate_cases`); the advisory names_fix leg keeps the original `faithful`-label subset.
- **Files modified:** server/tests/test_eval/run_eval.py
- **Verification:** `uv run pytest -m code -q` green; gold set scores D1 == 1.0 through `score_eval_set`
- **Committed in:** ac88722 (Task 1 commit)

**2. [Rule 2 - Missing critical] Trap-case handling in run_judge**
- **Found during:** Task 1 (judge-leg extension) / Task 2 (gold-set traps)
- **Issue:** The plan requires the `adv_broken_but_pass` trap to "fail no_false_geometry", but averaging trap scores into the dimension mean is backwards: a judge that MISSES the trap (scores the bad line high) raises the mean, and a judge that CATCHES it drags the mean toward failure.
- **Fix:** `judge_traps` runs each adversarial case individually on its `trapDimension`; `_gate_passes` additionally requires every trap CAUGHT (score < threshold). Trap cases are excluded from gate means, the praise floor, and variety.
- **Files modified:** server/tests/test_eval/run_judge.py, server/tests/test_eval/run_eval.py, server/tests/test_eval/gold_set.jsonl
- **Verification:** model-free suite green; trap exclusion asserted via the adversarial-label filters
- **Committed in:** ac88722, 061acf6

---

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical)
**Impact on plan:** Both required for the gate to be trustworthy — the exact goal of EVAL-03. No scope creep; no wire contract, scorer, or client code touched.

## Issues Encountered

- Vertex ADC is absent in this session, so the `make eval` judge + baseline legs could not be executed live. Per the plan's verification clause, the structure was verified instead (`make -n eval` shows eval-code → run_judge → run_baseline; all three runners import-safe offline) and **the full run is deferred to 17-10** (which also holds the mother's re-sign gate and judge calibration).

## User Setup Required

None - no external service configuration required. (The deferred `make eval` full run needs `gcloud auth application-default login` + `GCP_PROJECT_ID` — an existing, documented requirement, not new setup.)

## Known Stubs

None. `run_baseline.py` is fully implemented; it is an integration runner that requires ADC by design (documented in its docstring and the Makefile), not a stub.

## Next Phase Readiness

- The regression gate is now semantic-ready BEFORE the coaching-contract change lands (Pitfall 5 ordering satisfied) — 17-05/17-06 can ship varied, criteria-aware coaching without false regression alarms.
- `_render_case_facts` already renders `criteria` generically — criteria-bearing gold cases from 17-05 need no further harness change; `run_baseline` strips `criteria` for arm B automatically.
- Open for 17-10: mother's re-sign of the WHOLE gold set (flips `signed:false`), judge calibration against her labels, and the first live `make eval` (judge + baseline legs) once ADC is present.

## Self-Check: PASSED

- FOUND: server/tests/test_eval/run_baseline.py, test_variety.py (created)
- FOUND: run_eval.py, run_judge.py, JUDGE_RUBRIC.md, gold_set.jsonl, test_eval_harness.py, Makefile, app/faithfulness.py (modified)
- FOUND commits: a5020fb, ac88722, f28b7dc, 061acf6
- Acceptance criteria re-run: `uv run pytest -m code -q` → 91 passed, 1 skipped, exit 0; DIMENSIONS contains all 4 new names; names_fix advisory (comment + gate-immunity test); 3 rubric sections present; faithfulness.py diff = 32 insertions / 0 deletions; `grep -c '"signed": true'` == 0; coordinate grep == 0; run_baseline wired in Makefile with grep-visible zero-tolerance check
- TDD gates: test(17-04) commits precede feat(17-04) commits for both tasks

---
*Phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach*
*Completed: 2026-07-06*
