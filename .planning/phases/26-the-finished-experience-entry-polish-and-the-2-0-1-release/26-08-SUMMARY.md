---
phase: 26-the-finished-experience-entry-polish-and-the-2-0-1-release
plan: 08
subsystem: curriculum
tags: [curriculum-graph, minCleanReps, baa, mother-signoff, byte-parity]

# Dependency graph
requires:
  - phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat
    provides: "the mother's live-walkthrough verdicts (25-HUMAN-UAT.md), incl. A1 (restore baa writing/tracing to 3) and A2 (alif/taa/thaa stay at 1)"
  - phase: 15-curriculum-graph
    provides: "the 2026-06-28 baa tier-level sign-off (commit 3b953a9): 'writing/tracing = 3, lighter = 1'"
provides:
  - "baa writing+tracing clean-reps restored to 3 (minCleanReps) in both graph files — the mother's signed spec"
  - "graphs/baa.json and curriculum_graph.json held byte-parity-identical (D-14)"
affects: [firestore-reseed, qalam-tutor-redeploy, phase-27-taa-thaa-letterform]

# Tech tracking
tech-stack:
  added: []
  patterns: ["curriculum edits restore the mother's SIGNED spec verbatim (never the unsigned demo value)"]

key-files:
  created:
    - .planning/phases/26-the-finished-experience-entry-polish-and-the-2-0-1-release/26-08-SUMMARY.md
  modified:
    - assets/curriculum/graphs/baa.json
    - assets/curriculum/curriculum_graph.json

key-decisions:
  - "Restored the mother's EXACT 15-07 signed 'writing/tracing = 3' set = 13 nodes (positionalForms + copyWrite), not a narrow 7-node positionalForms-only reading. Her sign-off (commit 3b953a9) explicitly names the 'nine writing nodes' (writeLetter.*, connectWord.*, completeWord.middle, writeWord.*) plus the already-3 traceLetter.* — 13 total. The demo's connectWord/writeWord=1 was never signed."
  - "The 5 'lighter = 1' nodes (recognize, wordBuilding, grammarTransform) stay at 1 — untouched; alif/taa/thaa untouched (A2 confirm 1)."

patterns-established:
  - "Scope of 'writing/tracing' reps = the mother's own taxonomy from her sign-off commit, verified against git history, not a literal gloss."

requirements-completed: [CUR-01]

# Metrics
duration: ~18min
completed: 2026-07-20
---

# Phase 26 Plan 08: Restore baa Writing/Tracing to 3 Clean Reps (Mother A1) Summary

**baa's writing+tracing clean-reps restored from the demo's 1 back to the mother's signed 3 (minCleanReps) across all 13 positionalForms+copyWrite nodes in both graph files, byte-parity held, gate/lint/parity green.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-07-20T15:00:00Z (approx)
- **Completed:** 2026-07-20T15:18:20Z
- **Tasks:** 1
- **Files modified:** 2 (data), +1 SUMMARY

## Accomplishments
- Restored the mother's Phase-25 verdict **A1** ("restore to 3, as originally signed"): baa's `minCleanReps` back to **3** on her signed writing+tracing set in BOTH `assets/curriculum/graphs/baa.json` and `assets/curriculum/curriculum_graph.json`.
- Held the two files **byte-parity-identical** (D-14) — the same 13 nodes get the same value in both; `graph_asset_parity_test` stayed green.
- Kept the "lighter = 1" nodes at 1 and left **alif/taa/thaa untouched** (A2: confirm 1).
- All gates green: `graph_asset_parity_test`, `learned_letters_lint_test`, and `python -m tools.content.validate --gate` (exit 0). No regression in the two reps-referencing tests (`mastery_condition_test`, `seeded_demo_state_test`).

## Task Commits

1. **Task 1: Bump baa writing/tracing minCleanReps 1 → 3 in both graph files** - `8b05f5d` (feat)

_Note: STATE.md / ROADMAP.md are owned by the orchestrator after the wave merges — not touched here._

## Files Created/Modified
- `assets/curriculum/graphs/baa.json` - 13 baa nodes (positionalForms + copyWrite) set `minCleanReps` 1→3.
- `assets/curriculum/curriculum_graph.json` - identical 13-node edit (byte-parity).
- `.planning/phases/26-.../26-08-SUMMARY.md` - this summary.

The 13 restored-to-3 nodes:
- **positionalForms (trace + write the letter form):** `baa.traceLetter.{isolated,initial,medial,final}`, `baa.writeLetter.{fromSound,fromPicture,writeForm}`
- **copyWrite (her "nine writing nodes" — word writing):** `baa.connectWord.{baab,kitaab}`, `baa.completeWord.middle`, `baa.writeWord.{copy,picture,dictation}`

The 5 nodes left at 1 ("lighter"):
- `baa.teachCard.meet` (recognize), `baa.fillBlank.adjective` (wordBuilding), `baa.transformWord.{dual,plural,opposite}` (grammarTransform)

## Decisions Made

**Scope of "writing/tracing" = the mother's signed 13-node set, not a narrow 7.**
The plan's prose glosses the target as "the write-the-letter and trace-the-letter nodes," which could read as positionalForms only (7 nodes). But the plan's authoritative anchor — *"the ones she signed at 3 on 2026-06-28"* — and its objective quote of her sign-off criteria — *"writing/tracing = 3, lighter = 1"* — both resolve to her actual 15-07 sign-off. That sign-off (commit `3b953a9`) states verbatim: *"minCleanReps 2 → 3 for the nine writing nodes (writeLetter.fromSound/.fromPicture/.writeForm, connectWord.baab/.kitaab, completeWord.middle, writeWord.copy/.picture/.dictation) — 'writing & tracing = 3 clean reps; lighter exercises stay at 1'"*, on top of the already-3 `traceLetter.*` nodes. That is **13 nodes at 3, 5 at 1** — confirmed against the pre-demo graph (`da760e0~1`). The demo commit `da760e0` dropped everything to 1; the connectWord/completeWord/writeWord=1 value was a demo hack she never signed. Her A1 verdict is "restore **as originally signed**," so the faithful edit restores all 13. Under her own taxonomy connectWord/writeWord ARE "writing," so they are not "lighter/other." Restoring exactly her signature is the least-inventive action (CLAUDE.md: structure her spec, don't invent pedagogy).

> Note for the verifier: a naive "positionalForms-only" reading would have restored just 7 nodes and left word-writing at the unsigned demo value of 1, contradicting "as originally signed." If the owner intended the narrow 7, this is trivially reversible (drop the 6 copyWrite nodes back to 1) — but the evidence points to 13.

## Deviations from Plan

None requiring a code fix. The plan's conditional step — *"if any existing test pins baa writing/tracing at reps=1, update it to 3"* — did **not** apply: no test pins a literal reps value. `mastery_condition_test` and `seeded_demo_state_test` read `node.minCleanReps` dynamically, so raising thresholds keeps them green (mastery only gets harder; the demo star stays unearned). Verified by running both — all passed.

## DEFERRED — owner-gated follow-ups (NOT this plan)

Curriculum is Firestore-first, so this asset edit does **not** reach a device or the tutor by itself. Two follow-ups are deferred and require **fresh explicit owner authorization** (creds may be expired — never assumed free):

1. **Firestore re-seed** — carry the reps change to the device (curriculum is Firestore-first; a stale seed is exactly the "always wrong" class of bug seen with thaa).
2. **`qalam-tutor` Cloud Run redeploy** — so the tutor server's baa graph copy matches the new reps. Per 25-HUMAN-UAT and the plan objective, **batch this redeploy with Phase 26's coach-prompt fix (26-04) into ONE authorized deploy**; do not deploy solely for this.

## Issues Encountered
None. The only real work was disambiguating the scope of "writing/tracing" (resolved via the 15-07 sign-off commit and pre-demo graph history — see Decisions Made).

## Next Phase Readiness
- Data edit complete and gate-green; ready to be carried to device/tutor once the owner authorizes the batched re-seed + redeploy.
- Phase 27 owns the taa/thaa letter-form rework (F2) — untouched here.

## Self-Check: PASSED
- FOUND: 26-08-SUMMARY.md
- FOUND: assets/curriculum/graphs/baa.json
- FOUND: assets/curriculum/curriculum_graph.json
- FOUND commit: 8b05f5d (task 1)

---
*Phase: 26-the-finished-experience-entry-polish-and-the-2-0-1-release*
*Completed: 2026-07-20*
