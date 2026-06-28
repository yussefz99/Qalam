---
phase: 15-build-dynamic-grounded-exercise-selection-on-baa
plan: 07
subsystem: curriculum
tags: [curriculum, signoff, grounding, baa, pedagogy, clean-reps]

# Dependency graph
requires:
  - phase: 15-01
    provides: provisional baa curriculum graph asset + clean tier-level sign-off sheet
  - phase: 15-02
    provides: generate.py server-graph derivation + G5/G6 rail + clearedTiers/clearedCompetencies wire fields
  - phase: 15-03
    provides: pure-Dart CurriculumGraph parser (signedOff getter, essentialNodes, tierOf/nextForward/remediateOneTier)
  - phase: 15-05
    provides: RouterExerciseSelector + isMasteryMet star gate over the essential 70/30 core
provides:
  - "Owner-mother-signed baa curriculum graph (signedOff:true) — the signed demo path for dynamic selection"
  - "Q3 clean-reps adjustment applied: nine writing nodes 2 -> 3 (writing & tracing = 3, lighter exercises = 1)"
  - "Re-derived read-only server curriculum_graph.json carrying signedOff:true + matching reps"
  - "Human-UAT record (15-HUMAN-UAT.md) accompanying the signedOff:true commit (Pitfall 4)"
affects: [phase-16, cloud-run-redeploy, dynamic-selection, mastery-star]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Curriculum sign-off gate: signedOff flips false->true ONLY behind a blocking-human checkpoint, with a human-UAT entry on the same change (D-05 / Pitfall 4)"
    - "Derived server copy is re-generated from the signed asset via generate.py, never hand-edited (single source of truth)"

key-files:
  created:
    - .planning/phases/15-build-dynamic-grounded-exercise-selection-on-baa/15-HUMAN-UAT.md
  modified:
    - assets/curriculum/curriculum_graph.json
    - server/app/curriculum_data/curriculum_graph.json
    - docs/curriculum/baa-curriculum-graph-signoff-sheet.md
    - test/curriculum/curriculum_graph_test.dart

key-decisions:
  - "Q1 competency mapping APPROVED as drafted — no node competency changed"
  - "Q2 70/30 essential/enrichment split APPROVED as drafted — grammarTransform + wordBuilding stay enrichment (essential:false, minCleanReps:1); they do not gate the star, though grammar remains mandatory grade-1 content presented to the child with a simple bar"
  - "Q3 clean-reps ADJUSTED — writing & tracing = 3 clean reps, lighter exercises = 1; nine writing nodes bumped 2->3"
  - "signedOff flipped false->true ONLY after sign-off; server copy re-derived (not hand-edited); baa-only (D-11) confirmed"

patterns-established:
  - "Sign-off gate pattern: the flag flip + human-UAT record + derived-copy regeneration are one atomic plan, never partial"

requirements-completed: [DYN-01, DYN-02]

# Metrics
duration: 20min
completed: 2026-06-28
---

# Phase 15 Plan 07: Owner-Mother Curriculum Graph Sign-Off Summary

**Owner-mother signed the baa curriculum graph at the tier level (2026-06-28) — signedOff flipped false->true, the nine writing nodes bumped to 3 clean reps per her Q3 adjustment, the read-only server copy re-derived from the signed asset, and a human-UAT record filed alongside the flip.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-06-28
- **Completed:** 2026-06-28
- **Tasks:** 1 (the blocking-human-verify sign-off gate — sign-off completed externally; this plan applied the decisions + mechanical post-sign-off work)
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- Applied the owner-mother's tier-level sign-off decisions to the canonical asset `assets/curriculum/curriculum_graph.json`:
  - **signedOff: false -> true** — the single authorized place this flag flips (D-05).
  - **Q3 adjustment:** `minCleanReps` 2 -> 3 for the nine writing nodes (the three `writeLetter.*`, the two `connectWord.*`, `completeWord.middle`, and the three `writeWord.*`), joining the three `traceLetter.*` already at 3. All lighter exercises (teach card, sentences, fill-blank, transforms) stay at 1. No competency / essential / prerequisite / tier changes.
- Re-derived the read-only server copy via `cd server && uv run python -m app.curriculum_data.generate` — `server/app/curriculum_data/curriculum_graph.json` now carries `signedOff:true`, 19 baa.* nodes, and reps matching the asset byte-for-byte. (`baa_authored_ids.json` re-written identically — id set unchanged, no diff.)
- Confirmed baa-only scope (D-11): every node exerciseId starts with `baa.`; no ت/ث content. (`baa.connectWord.kitaab` is the baa word كتاب, not taa content.)
- Recorded the sign-off in `docs/curriculum/baa-curriculum-graph-signoff-sheet.md` (marked SIGNED; Q1/Q2/Q3 boxes checked; reviewer + date; Q3 adjustment noted) and filed `15-HUMAN-UAT.md` — the human-UAT record that must accompany a signedOff:true commit (Pitfall 4).
- Plan's automated acceptance check prints `signed + derived + baa-only OK`.

## Task Commits

Each change was committed atomically:

1. **Sign the curriculum graph (asset + derived server copy)** - `3b953a9` (feat)
2. **Pin the curriculum_graph test signedOff assertion to the signed reality** - `c263857` (test, Rule 1)
3. **Record owner-mother sign-off (sheet SIGNED + human-UAT entry)** - `9416e31` (docs)

**Plan metadata:** see the final `docs(15-07)` commit (SUMMARY + STATE + ROADMAP + REQUIREMENTS).

## Files Created/Modified

- `assets/curriculum/curriculum_graph.json` - signedOff true + nine writing nodes minCleanReps 2->3 (the signed canonical graph)
- `server/app/curriculum_data/curriculum_graph.json` - re-derived from the signed asset (signedOff true, matching reps)
- `docs/curriculum/baa-curriculum-graph-signoff-sheet.md` - marked SIGNED; Q1/Q2/Q3 recorded; Q3 adjustment note; reviewer + date
- `.planning/phases/15-.../15-HUMAN-UAT.md` (created) - human-UAT record of the tier-level sign-off (Pitfall 4)
- `test/curriculum/curriculum_graph_test.dart` - signedOff assertion updated false->true (Rule 1; the Wave-0 RED expectation was made stale by the sign-off this plan performed)

## Decisions Made

- **Q1 competency mapping:** APPROVED as drafted (no change).
- **Q2 70/30 essential/enrichment split:** APPROVED as drafted. Grammar (`grammarTransform`) + fill-blank (`wordBuilding`) remain enrichment (`essential:false`, `minCleanReps:1`) — they do NOT gate the mastery star; grammar is still mandatory grade-1 content presented to the child, but with a simple bar, which the current model already reflects (no flag/prerequisite change).
- **Q3 per-skill clean-reps:** ADJUSTED — "writing & tracing = 3 clean reps; lighter exercises stay at 1." Nine writing nodes moved 2->3.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated a stale test assertion invalidated by the sign-off flip**
- **Found during:** Step 6 (full Flutter suite re-run)
- **Issue:** `test/curriculum/curriculum_graph_test.dart` asserted `graph.signedOff isFalse` ("PROVISIONAL until owner-mother signs"). The sign-off this plan performed flipped the asset to `signedOff:true`, making that Wave-0 RED expectation stale — the test failed for the exact reason the plan exists to produce.
- **Fix:** Updated the assertion to `isTrue` with the sign-off rationale, and retitled the test ("signed baa asset ... signedOff true"). The test now tracks the asset, not a frozen draft value.
- **Files modified:** test/curriculum/curriculum_graph_test.dart
- **Verification:** `flutter test test/curriculum/curriculum_graph_test.dart` -> 4 passed.
- **Committed in:** `c263857`

---

**Total deviations:** 1 auto-fixed (1 Rule-1 stale-test fix).
**Impact on plan:** The fix is the direct and necessary consequence of the sign-off flip — the test encoded a pre-sign-off expectation that the plan's whole purpose is to invalidate. No scope creep.

## Issues Encountered

- **`spike_genui/durable_layers_unchanged_test.dart` flagged the uncommitted asset edit.** This Phase-11 spike guard fails when `git diff --quiet HEAD -- assets/curriculum/` is dirty (it treats `assets/curriculum/` as a sacred durable path). My plan-mandated asset edit made the working tree differ from HEAD, so the guard tripped while the change was uncommitted. This is the guard working as designed — it compares the working tree against HEAD, not a frozen baseline. **Resolved on commit:** after committing the asset (`3b953a9`), `git diff --quiet HEAD -- assets/curriculum/` returns clean and the guard passes (re-run -> 2 passed). Not a regression.

- **Flutter tooling regenerated `.metadata` and an `ios/` scaffold during `flutter test`.** Out of scope (project is Android-only) and unrelated to this plan — deliberately NOT staged or committed.

## Test Results (both full suites)

- **Server:** `cd server && uv run pytest -q` -> **72 passed**, 0 failures.
- **Client:** `flutter test` -> **+630 / -8** during the run; after the Rule-1 test fix and committing the asset, the residual failures are exactly the documented pre-existing drift — **no NEW failures**:
  - `glyph_audit_golden_test`, `mastery_celebration_golden_test`, `reference_overlay_golden_test` — known golden font-drift (MEMORY: golden-tests-font-drift; do NOT re-bake).
  - `alif_reference_test` (x2) — known pre-existing alif-reference data drift.
  - `meet_section_test` Test 1 (`img.door`) — pre-existing image-asset failure (re-confirmed RED pre-plan in 15-05; logged in deferred-items.md).
  - This matches the 15-05 baseline of `-6` documented pre-existing failures (golden-render nondeterminism accounts for the 6-vs-8 count fluctuation). None of the residual failing files reference `curriculum_graph` / `signedOff` / `minCleanReps`.
- **Plan acceptance check:** `signed + derived + baa-only OK`.

## Known Stubs

None. No stub patterns introduced; this plan flips a flag, adjusts data values, regenerates a derived copy, and updates docs/tests.

## User Setup Required

**One OPS / human follow-up (needs `gcloud` auth — NOT attempted by this plan):**

> **Re-deploy the `qalam-tutor` Cloud Run service** so the signed graph (`server/app/curriculum_data/curriculum_graph.json`) AND the enlarged non-PII wire contract from 15-02/15-04 (`clearedTiers` / `clearedCompetencies` on `TutorFactsIn`) are live before on-device `/coach` testing.

The standalone server re-deploy is safe (backward-compatible defaults; the G5/G6 rail is a no-op on empty lists), and it MUST land before the Dart side relies on the graph-position fields online (the 422 forward-direction trap from 15-02). Deploy reference (project `qalam-app-bd7d0`, region `us-central1`, service `qalam-tutor`).

## Next Phase Readiness

- The baa curriculum graph is **signed** and is now the dynamic-selection demo path. DYN-01 + DYN-02 are satisfied by the signed graph; GROUND-03 (faithfulness floor) was delivered in 15-06.
- Phase 16 (presence + voice + eval gate + demo-harden) can build on the signed graph once the Cloud Run re-deploy lands.
- **Blocker for live on-device testing:** the Cloud Run re-deploy above (and, separately, the real Anthropic/Vertex coach-node config + Firebase App Check registration tracked from Phase 14).

## Self-Check: PASSED

- Files verified on disk: `assets/curriculum/curriculum_graph.json`, `server/app/curriculum_data/curriculum_graph.json`, `docs/curriculum/baa-curriculum-graph-signoff-sheet.md`, `.planning/phases/15-.../15-HUMAN-UAT.md`, `test/curriculum/curriculum_graph_test.dart` — all FOUND.
- Commits verified in git log: `3b953a9`, `c263857`, `9416e31` — all FOUND.

---
*Phase: 15-build-dynamic-grounded-exercise-selection-on-baa*
*Completed: 2026-06-28*
