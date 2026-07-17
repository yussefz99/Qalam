---
phase: 19-question-presentation-overhaul-every-question-self-explanato
plan: 05
subsystem: curriculum-content
tags: [curriculum, learned-letters-lint, micro-drills, gate, rewrite, server-rederive, anti-gamification, mother-signoff]

# Dependency graph
requires:
  - phase: 19
    plan: 01
    provides: "learned_letters_lint_test.dart (QP-07) — the disposition-agnostic RED lint this plan greens with zero test edits"
  - phase: 18
    plan: 02
    provides: "the 3 baa.microDrill.{dot,bowl,start} exercise configs (signedOff:false) + the parked graph note"
  - phase: 15
    plan: 07
    provides: "the owner-mother tier-structure graph sign-off (signedOff:true, unchanged here)"
provides:
  - "D-18: the 3 authored baa micro-drill nodes restored to the live curriculum graph (microdrill_selection_test sourced from the live graph)"
  - "D-12/D-19: learned-letters lint GREEN — 6 unlearned-letter cards gated (nodes removed), kitaab rewritten كتاب→باب (signedOff:false)"
  - "D-10/D-21: 19-REVIEW-PACKET.md — the mother's one-sitting review of all 7 flagged cards (non-blocking gate)"
  - "server curriculum_data/*.json re-derived via generate.py (17 nodes, 18 signed ids — kitaab dropped from the signed set)"
affects: ["19-06 keying migration (independent)", "Phase 20/21 (inherit the learned-letters rule as the authoring template; the 6 gated cards refile to their letters' units)"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Disposition-agnostic content lint self-greens: gate (node removed from graph) OR rewrite (letters ⊆ learned) — ZERO edits to the lint test"
    - "Gate = remove the graph node only; the exercise config stays dormant + mother-signed in exercises.json, refiled for its letter's unit (A6 — no cross-unit-prerequisite schema field)"
    - "Server rail re-derived via generate.py after every content edit — never hand-edited (the derived copies ship in the Docker image where the assets do not)"
    - "Rewrite drafts ship signedOff:false; only the mother flips content sign-off (baa_signoff carve-out keeps the invariant honest — Pitfall 8)"

key-files:
  created:
    - .planning/phases/19-question-presentation-overhaul-every-question-self-explanato/19-REVIEW-PACKET.md
  modified:
    - assets/curriculum/curriculum_graph.json
    - assets/curriculum/exercises.json
    - server/app/curriculum_data/curriculum_graph.json
    - server/app/curriculum_data/exercises.json
    - server/app/curriculum_data/baa_authored_ids.json
    - test/curriculum/curriculum_graph_test.dart
    - test/curriculum/baa_signoff_test.dart

key-decisions:
  - "kitaab REWRITTEN not gated (per plan Task 2): كتاب→باب (alif+baa), keeping the distinct 'baa's final form at the word's end' teaching angle; ships signedOff:false. The id is kept stable (a graph node references it). Flagged the باب-duplicates-baab concern + the gate-alternative to the mother in the packet."
  - "The 6 gated cards' exercise CONFIGS are left untouched (signedOff:true, mother-signed 15-07) — only their GRAPH NODES were removed. Gating unsigns nothing; the content is dormant + refiled for Phase 20/21."
  - "learned_letters_lint_test.dart received ZERO edits — the 19-01 lint scopes to LIVE graph nodes, so both dispositions self-green. (The plan frontmatter listed it as modified; the plan-notes' 'ZERO edits' instruction is the correct one.)"
  - "curriculum_graph_test.dart Test 1 reconciled (Rule 1): its hardcoded '20 nodes / microDrills parked' assertion directly contradicted the locked D-18 (restore) + D-19 (gate) decisions; updated to 17 nodes / 3 restored microDrills."
  - "gated fluentReading now has 0 live nodes (both buildSentence cards removed); this correctly shrinks the essential-node set for baa mastery — mastery_condition_test + curriculum_graph_walker_test both stay green (they read the graph dynamically)."

patterns-established:
  - "Micro-drill re-add mirrors the microdrill_selection fixture byte-for-byte (criterion dot/shape/strokeOrder, essential:false) so the live graph supersedes the fixture injection"

requirements-completed: [QP-07, QP-08]

# Metrics
duration: 14min
completed: 2026-07-17
---

# Phase 19 Plan 05: Learned-Letters Lint Green + Micro-Drill Restore + Mother's Packet Summary

**The baa unit becomes the authoring template Phases 20–21 inherit: the 3 authored micro-drill nodes return to the live graph (D-18), the 7 cards that demanded unlearned letters are gated (6 nodes removed) or rewritten (kitaab كتاب→باب, `signedOff:false`) so the learned-letters lint goes green with ZERO test edits (D-12/D-19), the server rail is re-derived via `generate.py`, and the mother gets a one-sitting, non-blocking review packet for the 7 cards (D-10).**

## Performance

- **Duration:** 14 min
- **Started:** 2026-07-17T22:13:32Z
- **Completed:** 2026-07-17T22:27:48Z
- **Tasks:** 3
- **Files:** 8 (1 created, 7 modified) + the deferred-items log

## Accomplishments

- **Task 1 — micro-drill restore (D-18/QP-08):** re-added the `microDrill` competency (`essential:false`, no prerequisites) and the 3 `baa.microDrill.{dot,bowl,start}` nodes (criterion dot/shape/strokeOrder, `tier:null`, `minCleanReps:1`, `essential:false`) to `curriculum_graph.json`, mirroring the `microdrill_selection_test` fixture byte-for-byte. `_meta` records the restore; the file-level `signedOff:true` and the exercise-level `signedOff:false` drill content are untouched. `microdrill_selection_test.dart` now draws the nodes from the live graph (its fixture no longer injects) — **green, zero test edits.**
- **Task 2 — lint green + gate/rewrite + server re-derive (D-12/D-19/D-09/QP-07):**
  - **Gated (node removed)** the 6 cards that fundamentally need unlearned letters — `baa.buildSentence.{hear,picture}` (need laam/kaaf/yaa/raa), `baa.fillBlank.adjective` (kaaf/yaa/raa), `baa.transformWord.{dual,plural,opposite}` (noon / waaw / ص-غ-ي-ر). Their configs stay dormant + mother-signed in `exercises.json`, filed for their letters' units (A6 — no cross-unit schema field).
  - **Rewrote** `baa.connectWord.kitaab` كتاب → **باب** (alif+baa), preserving the distinct final-form teaching angle; `signedOff:false`.
  - **`learned_letters_lint_test` self-greened with ZERO test edits** (it scopes to live graph nodes — rewrite makes `letters ⊆ {alif,baa}`, gate drops the node from the linted set).
  - Reconciled `curriculum_graph_test.dart` Test 1 (Rule 1) to 17 nodes / 3 restored microDrills; extended the `baa_signoff_test` carve-out for the kitaab rewrite (Pitfall 8).
  - **Re-derived** both server copies (+ `baa_authored_ids.json`) via `generate.py` — 17 graph nodes (3 microDrill), 18 signed baa ids (kitaab correctly dropped from the signed set). Idempotent on a second run (no hand edits).
- **Task 3 — mother's review packet (D-10/D-21):** wrote `19-REVIEW-PACKET.md` covering all 7 cards (current content + on-screen rendering under the new presentation + applied disposition + rewrite-vs-gate recommendation), a NON-BLOCKING header (drafts ship `signedOff:false`; her sign-off lands whenever she's free — D-11), the 15-07/17-10 sign-off-flip instruction, and the A5 reconciliation of the owner's "№ 10, 15–20" shorthand against the lint's 7-card flag set.

## Task Commits

1. **Task 1 — micro-drill node restore** — `dc45ba6` (feat)
2. **Task 2 — lint green: gate 6 / rewrite kitaab / re-derive server + test reconciliations** — `facd83b` (feat)
3. **Task 3 — mother's review packet** — `c791734` (docs)

**Plan metadata:** _(this SUMMARY + STATE/ROADMAP/REQUIREMENTS — final docs commit)_

## Files Created/Modified

- `assets/curriculum/curriculum_graph.json` — +microDrill competency + 3 drill nodes (D-18); −6 gated nodes (D-19); `_meta` restore/gate notes
- `assets/curriculum/exercises.json` — `baa.connectWord.kitaab` rewritten كتاب→باب, `letters:[baa,alif]`, `signedOff:false`, with a `_rewrite_19_05` provenance note
- `server/app/curriculum_data/{curriculum_graph,exercises,baa_authored_ids}.json` — re-derived via `generate.py` (never hand-edited)
- `test/curriculum/curriculum_graph_test.dart` — Test 1 reconciled to 17 nodes / 3 microDrills (Rule 1, D-18/D-19)
- `test/curriculum/baa_signoff_test.dart` — carve-out extended for the kitaab rewrite (Pitfall 8)
- `.planning/phases/19-.../19-REVIEW-PACKET.md` — the mother's one-sitting review artifact (created)
- `.planning/phases/19-.../deferred-items.md` — logged the pre-existing `alif_reference` cluster

## RED/GREEN Evidence

| Test | Status | Note |
|------|--------|------|
| `learned_letters_lint_test.dart` (QP-07) | RED → **GREEN** | greened by the gate/rewrite dispositions with ZERO test edits (self-scopes to live nodes) |
| `microdrill_selection_test.dart` (QP-08, 3 cases) | **GREEN** | now sourced from the live graph; fixture no longer injects |
| `curriculum_graph_test.dart` (4 cases) | reconciled → **GREEN** | Test 1 updated to 17 nodes / 3 microDrills (Rule 1) |
| `baa_signoff_test.dart` | **GREEN** | kitaab carved out; microDrills still `signedOff:false`; core invariant holds |
| `mastery_condition_test.dart` (8 cases) | **GREEN** | dynamic over essential nodes; unaffected by the node changes |
| `curriculum_graph_walker_test.dart` (8 cases) | **GREEN** | dynamic reachability/prereq assertions; copyWrite ramp intact |
| target-suite run (`test/curriculum/` targets + microdrill) | **43 pass / 0 fail** | see below for the 4 out-of-scope pre-existing alif failures |

## Decisions Made

- **kitaab rewritten to باب, not gated** — the plan's Task 2 directs a rewrite. باب preserves the card's distinct teaching point (baa's **final** positional form at a word's end). It does duplicate `baa.connectWord.baab` (also باب) — flagged prominently in the packet with two honest alternatives (differentiate the framing, or use بابا "daddy") and the gate option, since the mother owns the final content call.
- **The kitaab id is kept stable** (`baa.connectWord.kitaab`) even though it now teaches باب — a graph node references the id; renaming would break the reference. Noted as the mother's later call in the packet.
- **Gating removes only the graph node** — the 6 gated cards' `exercises.json` configs stay `signedOff:true` (mother-signed 15-07), dormant, refiled for their letters' units. Gating does not unsign content.
- **`learned_letters_lint_test.dart` = ZERO edits** — the 19-01 lint is disposition-agnostic (scopes to live nodes), so it self-greens. The plan frontmatter listed it under `files_modified`, but the plan-notes' explicit "ZERO edits to the test file" is correct and was followed.

## Post-wave fix (2026-07-18)

The post-wave integration gate caught ONE regression from Task 1's D-18 graph re-shape:
`test/features/letter_unit/same_id_represent_test.dart` **UAT T6** (an active-arc same-id
pass re-mounts the floor trace; "Next exercise" is not a permanently dead button) failed.

**Root cause:** re-adding `baa.microDrill.{dot,bowl,start}` to the live graph made
`graph.drillForCriterion('baa', <criterion>)` return a drill where it returned `null` in the
parked world. The remediation-arc step-down (`SelectionPolicy` entry line + `_drillOrRetry`)
preferred the drill over the floor trace — so a same-criterion **trace** fail landed the child
on the micro-drill instead of the guaranteed-doable floor trace, and T6's `_presentedGraphKey`
for the floor trace came back null. (The floor resolution itself was never null; the restored
drill preempted it.)

**Fix (`fe6487c`):** a new `_stepDownTarget` makes the arc floor resolution exercise-type-aware
— a failing guided **trace** steps down to the floor trace (the UAT-pinned confidence rebuild),
while a failing **production** exercise still steps down to its restored micro-drill (D-18
preserved for the case it targets). The micro-drill nodes stay live and are still injected as
candidates via R3; they simply never preempt the floor when the child is already at the trace
level. This is pure `lib/` selection logic — ZERO edits to the 19-01 contract tests, and the
D-18/D-19 graph decisions are untouched. Verified: `same_id_represent_test` (incl. T6),
`microdrill_selection_test`, `remediation_arc_test`, `selection_policy_test`,
`selection_rails_property_test`, and `test/curriculum/` all green (minus the documented
pre-existing `alif_reference` cluster + the pre-existing `meet_section` `img.door` case).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — obsolete test contradicts a locked decision] Reconciled `curriculum_graph_test.dart` Test 1**
- **Found during:** Task 2 (running `test/curriculum/` after the graph edits).
- **Issue:** Test 1 hardcoded "20 baa.* nodes … no microDrills" and asserted `microDrills isEmpty` — the frozen 2026-07-12 *parked* reality. Task 1 (D-18 restore) and Task 2 (D-19 gate) deliberately reverse that: 20 + 3 microDrills − 6 gated = **17 nodes, 3 microDrills**. The old assertion failed by design.
- **Fix:** Updated the node count to 17, `microDrills` to `hasLength(3)`, and the test name + reason strings to cite D-18/D-19. Behavioral intent (the graph parses the signed baa asset, baa-only, tier sign-off intact) preserved; only the count/microDrill expectations tracked the new content. NOT the protected 19-01 test.
- **Files modified:** `test/curriculum/curriculum_graph_test.dart`
- **Committed in:** `facd83b`

**Total deviations:** 1 (Rule 1 — test/contract reconciliation; mirrors the 19-02/19-03 pattern). No scope creep beyond the plan's content dispositions.

## Threat Surface

- **T-19-04 (pedagogical correctness — V5 input validation) MITIGATED:** the D-12 learned-letters lint is green and fails the build if any live baa card demands an unlearned letter; the 7 offending cards are gated/rewritten.
- **T-19-09 (Tampering — rewrite shipped as final) MITIGATED:** the kitaab rewrite ships `signedOff:false`; the `baa_signoff` carve-out keeps the "only the mother flips content sign-off" invariant honest.
- **T-19-10 (Integrity — server rail mismatch) MITIGATED:** both server copies were re-derived via `generate.py` (idempotent on re-run) — no hand edits.
- No new network endpoint, auth path, file access, or schema surface introduced. No threat flags.

## Known Stubs

None. The micro-drill nodes render real authored drill content; the rewritten kitaab card renders a real alif+baa word (باب). The gated cards are removed (not stubbed). The kitaab `signedOff:false` is an intentional, tracked provisional state (the mother's packet gate — D-11), not an unwired stub.

## Issues Encountered

- **Out-of-scope pre-existing failures (NOT fixed; logged to `deferred-items.md`):** the `alif_reference` cluster — 4 alif-only failures in `test/curriculum/` (`reference_overlay_golden_test` alif golden ~1.47% pixel drift; `alif_reference_test` ×2 centerline; `all_letters_validation_test` alif `signedOff`). **Verified pre-existing:** `git diff --name-only fef2c2c` over every input to these tests (`letters.json`, the alif golden, and the three test files) is **empty** — byte-identical to the pre-plan base, so they fail identically before and after this plan. This plan touched only the baa graph, the baa kitaab card, and two baa test files — zero overlap with alif. STATE.md repeatedly lists `alif-reference` as a known out-of-scope failure. **Did NOT re-bake the golden** (per 19-01/02/03 guidance).

## User Setup Required

- **None to unblock the deadline.** The code ships a safe state (6 gated, kitaab drafted `signedOff:false`); a child never sees an unlearned-letter card.
- **Non-blocking (D-11):** the owner's mother reviews `19-REVIEW-PACKET.md` at her convenience and confirms each disposition (rewrite vs gate) + flips `signedOff` on any card she approves. Her session does not gate the phase.
- **Server re-deploy (later):** the re-derived `server/app/curriculum_data/*.json` go live on the next `qalam-tutor` Cloud Run deploy (owner-gated, per the established re-deploy protocol) — not required for the offline client, which reads the bundled assets.

## Next Phase Readiness

- **QP-07 (learned-letters) + QP-08 (micro-drills) delivered and green.** The baa unit is now the clean authoring template for Phases 20–21: only alif+baa cards, enforced by the lint.
- **19-06** (per-child keying migration) is independent of this plan's content track and proceeds on the greened presentation + content.
- **The 6 gated cards** are filed (in `_meta` + the review packet) for their letters' own units in Phase 20/21 — re-add each node once its letters are taught + mother-signed.
- **Do NOT re-bake goldens** (`alif_reference`, mastery/glyph) — documented pre-existing font drift.

---
*Phase: 19-question-presentation-overhaul-every-question-self-explanato*
*Completed: 2026-07-17*

## Self-Check: PASSED

- Files: all 8 FOUND (curriculum_graph.json, exercises.json, 3 server copies, 2 curriculum tests, 19-REVIEW-PACKET.md).
- Commits: dc45ba6 FOUND, facd83b FOUND, c791734 FOUND.
- Target tests GREEN: learned_letters_lint + baa_signoff + curriculum_graph + mastery_condition + curriculum_graph_walker + microdrill_selection = 43 pass / 0 fail. The only suite failures are the 4 out-of-scope pre-existing alif_reference tests (verified byte-identical to base).
