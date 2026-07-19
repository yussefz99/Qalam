---
phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat
plan: 01
subsystem: tooling
tags: [python, curriculum, validation, build-gate, learned-letters, seen-letters-wall]

# Dependency graph
requires:
  - phase: 19-question-presentation-overhaul
    provides: the learned-letters lint (Dart) whose unlearnedFor predicate this Python one mirrors behaviorally
provides:
  - "unlearned_letters_for_exercise(ex, order): the parity predicate reading STORED letters[] — the single definition L2 imports"
  - "live_graph_node_ids(): live graph-node scoping helper (mirror of the Dart lint's liveNodeIds)"
  - "OWNER_APPROVED_EXCEPTIONS: the 4 D-09 baa exception ids, the single Python source L0 + L2 read"
  - "unlabeled_cards(): criterion-1's unlabeled-word leg, scoped to live nodes"
  - "python -m content.validate --gate: the criterion-1 build gate (non-zero on live-node findings)"
affects: [25-02-triage, 25-04-seeder-L2, 25-03-lint-L1]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "One shared learned-letters predicate (stored letters[], not decomposed display) reused by L0 audit + L2 seeder; L1 Dart lint mirrors it behaviorally"
    - "Live-node scoping via live_graph_node_ids() so dormant reach-ahead configs never trip the wall — the exact scoping L1 uses"
    - "argparse --gate flag: report-only stays default; the gate is opt-in and always regenerates the report first"

key-files:
  created: []
  modified:
    - "tools/content/validate.py - shared predicate + live-node scoping + OWNER_APPROVED_EXCEPTIONS + unlabeled_cards + --gate build gate"
    - "tools/content/README.md - documents `python -m content.validate --gate` as the criterion-1 build gate"

key-decisions:
  - "unlabeled_cards compares stored letters[] against the DEDUPED decomposition (mirror of promote_letter.enrich_exercise's _dedup_preserve), not the raw decompose the plan text literally names — raw would false-positive on 9 legitimately-deduped cards; dedup isolates the genuine بطة/توت drift (1 card + 1 missing-letters card)"
  - "Unknown letters (e.g. taa_marbuta, not in introOrder) are treated as reaching ahead via _UNLEARNED_SENTINEL = 1<<30 — byte-for-byte the Dart lint's `introOrder[l] ?? 1<<30` fallback, so the predicates agree exactly"
  - "report_live_exercises kept UNCHANGED as a SEPARATE display-decompose label-drift signal (per plan); the gate uses the stored-letters predicate + unlabeled_cards instead; the report regenerates byte-identically (worklist reproduced)"
  - "validate.py stays self-contained (relative .arabic import) — it does NOT import promote_letter, whose absolute `content.` import breaks the repo-root `PYTHONPATH=. python -c 'from tools.content.validate ...'` invocation the plan requires"

patterns-established:
  - "The seen-letters wall's parity source of truth lives in validate.py; L2 imports the predicate/helpers by name so seeder and audit cannot drift"
  - "Build gate = regenerate report, then fail non-zero on LIVE-node findings only (dormant + owner-approved exempt)"

requirements-completed: []  # QP-07 / D-12 are ADVANCED here (L0 machinery only), not fully satisfied — the wall needs L1/L2/L3 + the 34-card triage (later plans)

# Metrics
duration: 18min
completed: 2026-07-19
---

# Phase 25 Plan 01: L0 audit machinery — the seen-letters wall's parity source Summary

**A shared Python learned-letters predicate (`unlearned_letters_for_exercise` over STORED `letters[]`) + live-node scoping + a `--gate` build gate that exits non-zero on 19 live-node findings pre-triage and 0 once clean — the single definition L2 imports so all four wall layers refuse identical content.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-07-19T17:32Z
- **Completed:** 2026-07-19T17:50Z
- **Tasks:** 2
- **Files modified:** 2 (`validate.py`, `README.md`)

## Accomplishments
- Extracted the reach-ahead check into a pure, importable `unlearned_letters_for_exercise(ex, order)` reading the card's STORED `letters[]` (behavioral mirror of the Dart lint's `unlearnedFor`), so L0/L1/L2 judge the same input.
- Added `live_graph_node_ids()` (57 live ids) and the `OWNER_APPROVED_EXCEPTIONS` frozenset (the 4 D-09 baa ids) — the shared scoping both the gate and the seeder use, so the 15 dormant reach-ahead configs and the 4 exceptions never trip the wall (mirror of L1's `liveNodeIds` / `baaOwnerApprovedExceptions`).
- Added `unlabeled_cards()` — criterion 1's unlabeled-word leg (missing/empty or drifted `letters[]`), scoped to live nodes.
- Added the `--gate` build gate: pre-triage it exits non-zero with **17 reach-ahead + 2 unlabeled = 19 live-node findings**; report-only mode is unchanged (exit 0) and always regenerates `validation_report.md` byte-identically (worklist reproduced).
- Documented `python -m content.validate --gate` in `tools/content/README.md`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract the shared learned-letters predicate + a label check** - `fcc2a16` (feat)
2. **Task 2: Add the --gate build gate and regenerate the worklist report** - `5f21f3c` (feat)

## Files Created/Modified
- `tools/content/validate.py` - Added `unlearned_letters_for_exercise`, `live_graph_node_ids`, `OWNER_APPROVED_EXCEPTIONS`, `_UNLEARNED_SENTINEL`, `_text_for_display`/`_dedup_preserve`, `unlabeled_cards`, `run_gate`; rewired `main()` with an argparse `--gate` flag; updated the module docstring.
- `tools/content/README.md` - New "The build gate (`--gate`)" section + the `--gate` command in the commands list.

## Verification Evidence
- Task 1 (repo-root import, `PYTHONPATH=.`): `unlearned_letters_for_exercise({'id':'baa.x','letters':['taa']}, load_intro_order())` → non-empty; `['alif','baa']` → `[]`; `'alif.buildSentence.hear' not in live_graph_node_ids()`; `'baa.fillBlank.adjective' in live_graph_node_ids()`; `OWNER_APPROVED_EXCEPTIONS == {the 4 D-09 ids}`. PASS.
- Task 2 (from `tools/`): `python -m content.validate` → exit 0, report rewritten; `python -m content.validate --gate` → exit 1 (19 findings). The 4 D-09 exceptions reach ahead yet are exempt (load-bearing). PASS.
- Both invocation forms work: repo-root `from tools.content.validate import …` AND `python -m content.validate` from `tools/`.

## Decisions Made
- **Dedup comparison for `unlabeled_cards`.** The plan text names `decompose(_text_for_display).letters` (raw); the stored `letters[]` convention in the repo is the *deduped* skeleton (باب → `[baa, alif]`, per `promote_letter.enrich_exercise._dedup_preserve`). Raw comparison false-positives on 9 legitimate cards; comparing against the deduped form isolates exactly the genuine drift the docstring names — `taa.completeWord.middle` (`['taa']` vs توت `['taa','waaw']`) plus the unlabeled `alif.writeLetter.fromPicture`. Documented as a faithful reading of the authoring source of truth.
- **Sentinel for non-taught letters.** Mirrors the Dart `?? 1<<30`, so a stored `taa_marbuta` is treated as reach-ahead identically (no live card currently has one, so no worklist change today — this only pins parity).
- **`report_live_exercises` left unchanged** as the separate display-decompose label-drift signal (per plan); the report is byte-identical.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] validate.py must not import promote_letter for the shared display-text helper**
- **Found during:** Task 1 (shared predicate + label check)
- **Issue:** The plan/PATTERNS suggested reusing `promote_letter`'s `_text_for` / `_dedup_preserve`, but `promote_letter.py` uses an absolute `from content.arabic import …`, which raises `ModuleNotFoundError: No module named 'content'` under the repo-root `PYTHONPATH=. python -c "from tools.content.validate import …"` invocation the acceptance criteria mandate.
- **Fix:** Re-implemented the two tiny helpers (`_text_for_display`, `_dedup_preserve`) inside `validate.py`, which uses relative imports (`from .arabic import …`) and therefore works from both repo-root and `tools/`.
- **Files modified:** `tools/content/validate.py`
- **Verification:** Both import forms exercised (repo-root `-c` import + `python -m content.validate` from `tools/`) — both pass.
- **Committed in:** `fcc2a16`

---

**Total deviations:** 1 auto-fixed (1 blocking) + 1 documented reading (dedup comparison basis).
**Impact on plan:** No scope change. The predicate/gate/scoping match the plan's contract and the acceptance criteria exactly; the dedup choice is required for the check to be correct against the repo's actual label convention.

## Issues Encountered
- None beyond the import-path blocker above. No new packages (threat T-25-01-SC held — stdlib + existing `content.arabic` only). No child data reaches this read-only tool (T-25-01-I held).

## Known Stubs
None introduced. Note: the gate correctly *flags* `alif.writeLetter.fromPicture` as unlabeled (its `letters[]`/`criteria` are completed in a later Phase-25 plan) — this is a genuine pre-triage finding surfaced by the machinery, not a stub introduced here.

## Next Phase Readiness
- **Plan 02 (triage)** can run `python -m content.validate --gate`, work the 17 reach-ahead + 2 unlabeled findings to zero, and confirm the gate flips to exit 0.
- **Plan 04 (L2 seeder)** can `from content.validate import unlearned_letters_for_exercise, live_graph_node_ids, OWNER_APPROVED_EXCEPTIONS, load_intro_order` — the names are stable and the key_links contract (`seed_curriculum_v2.py` → `validate.py::unlearned_letters_for_exercise`) is importable.
- QP-07 / D-12 are advanced (L0 machinery) but NOT marked complete — they need L1/L2/L3 + the triage before the wall fully holds.

## Self-Check: PASSED
- `tools/content/validate.py` — FOUND (modified, importable both ways)
- `tools/content/README.md` — FOUND (--gate documented)
- Commit `fcc2a16` — FOUND
- Commit `5f21f3c` — FOUND

---
*Phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat*
*Completed: 2026-07-19*
