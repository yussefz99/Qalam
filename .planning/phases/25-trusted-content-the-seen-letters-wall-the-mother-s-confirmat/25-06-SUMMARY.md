---
phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat
plan: 06
subsystem: curriculum
tags: [curriculum, content, mothers-packet, review, signedOff, D-11, D-13, D-14, D-09, D-16, CUR-01, seen-letters-wall]

# Dependency graph
requires:
  - phase: 25-01-L0-audit-machinery
    provides: "validation_report.md §4 — the machine-generated 22-exception enumeration (provenance-tagged) the packet is assembled from"
  - phase: 25-02-triage
    provides: "the 22 owner-approved exceptions (4 baa D-09 + 18 taa/thaa D-16) + the taa.completeWord.middle relabel + the alif.writeLetter.fromPicture draft the packet presents"
  - phase: 25-03-lint-L1
    provides: "the D-04/D-05 decoupling that makes flipping baa's signedOff:false SAFE (the lint no longer reads the flag as an enforcement gate)"
provides:
  - "25-REVIEW-PACKET.md — the ONE walkthrough-ready checklist covering every owner-directed change since her last sign-off, one row per item with an inline confirm/reject/rework verdict slot (D-11/D-13)"
  - "baa graph at its honest signedOff:false state in BOTH graphs/baa.json and curriculum_graph.json (byte-parity), + the 4 D-09 exception cards at exercise-level signedOff:false (D-14/D-09)"
affects: [25-07-verdict-ingestion]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "The packet is ASSEMBLED from the machine artifacts (validation_report.md §4 + a grep of every exercises.json `_review` note), never hand-curated — so the doc and the JSON cannot drift"
    - "Every packet row mirrors the card's `_review` text and carries an inline `confirm / reject / rework: ___` slot the owner marks on the spot (D-11 live walkthrough)"
    - "Honest-flag discipline: signedOff is flipped to its truthful value during assembly (baa live diverged from her signed spec); SAFE only because enforcement is decoupled from the flag (D-04/D-05)"

key-files:
  created:
    - ".planning/phases/25-.../25-REVIEW-PACKET.md - the mother's re-confirmation packet (335 lines; 19 verdict rows across 7 groups A–G + a summary table + 'What you sign' close)"
    - ".planning/phases/25-.../25-06-SUMMARY.md - this summary"
  modified:
    - "assets/curriculum/graphs/baa.json - graph-level signedOff true->false (honest divergence state, D-14)"
    - "assets/curriculum/curriculum_graph.json - graph-level signedOff true->false (byte-parity with baa.json held)"
    - "assets/curriculum/exercises.json - exercise-level signedOff true->false on the 4 D-09 baa exception cards"

key-decisions:
  - "The packet covers ALL 22 owner-approved exceptions (4 baa D-09 in Group F-1 + 18 taa/thaa D-16 in Group F-2), not only the 4 D-09 ids the plan's Task-1 action text named — the prior-wave context mandates the packet is where the mother rules on the 18 D-16 ids too (criterion 4 = EVERY change gets a verdict). This is coverage, not scope creep."
  - "baa graph-level signedOff flipped to false via cp-parity: edited both graphs/baa.json and curriculum_graph.json identically (the `\"signedOff\": true,` JSON key is unique at line 15 in each — the _meta prose strings use the un-quoted `signedOff:true` form and were untouched); verified byte-identical afterward."
  - "The 4 D-09 exception cards' signedOff was flipped via a verified surgical line replacement (lines 587/631/675/722), asserting each read `      \"signedOff\": true,` before replacement — because the 4 lines are byte-identical to each other AND to other true cards (baa.buildSentence.*), so an Edit/replace_all would have over-matched. Only those 4 changed; baa.buildSentence.hear/.picture stay true (untouched)."
  - "Changed ONLY signedOff fields (6 flips total): nodes, minCleanReps, and all card content are the mother's call in Plan 25-07 — untouched here."

patterns-established:
  - "The mother's packet merges the two Phase-19 precedents: 19-REVIEW-PACKET's per-item detail block + a 19-HUMAN-UAT-style inline verdict column, delivered as ONE live-walkthrough checklist (D-11)"
  - "signedOff is flipped to the TRUTH during assembly (never claims 'the mother confirmed this' while content differs); Plan 25-07 flips confirmed items back to true per her verdict"

requirements-completed: []  # CUR-01 is ADVANCED (the packet — criterion 4's assembly half — is walkthrough-ready), NOT satisfied: criterion 4 needs her actual verdicts ingested (Plan 25-07). Every one of the 22 exceptions + baa's flag stays provisional until she rules.

# Metrics
duration: ~22min
completed: 2026-07-20
---

# Phase 25 Plan 06: The mother's re-confirmation packet + baa's honest signedOff:false Summary

**`25-REVIEW-PACKET.md` is one walkthrough-ready checklist — 19 verdict rows across seven groups (clean-reps, buildSentence removals, the alif shrink + new draft, Lane-B re-points/rewordings, the word/label diff, all 22 reach-ahead exceptions, and the thaa placeholders) — each mirroring the card's `_review` note and carrying an inline `confirm / reject / rework: ___` slot the owner marks on the spot; and baa's graph flag is flipped to its honest `signedOff:false` state in both byte-parity graphs plus the 4 D-09 exception cards, SAFE because enforcement is decoupled from the flag (D-04/D-05) and the lint stays green.**

## Performance
- **Duration:** ~22 min
- **Started:** 2026-07-19 (worktree base b6117e7)
- **Completed:** 2026-07-20
- **Tasks:** 2
- **Files modified:** 4 (1 created: the packet; 3 modified: baa.json, curriculum_graph.json, exercises.json) + this SUMMARY

## Accomplishments
- **Assembled the packet (Task 1, D-11/D-13).** One document, 335 lines, covering EVERY owner-directed change since the mother's last sign-off (2026-06-28), grouped A–G with an inline verdict slot per row:
  - **Group A** — clean-reps: baa's signed spec (writing/tracing = 3) vs live (all = 1); alif/taa/thaa at 1, never signed. Flags the server-redeploy consequence if she restores baa to 3.
  - **Group B** — the 6 buildSentence removals (baa ×2, taa ×2, thaa ×2), now dormant.
  - **Group C** — alif's letter-level shrink + the new `alif.writeLetter.fromPicture` draft shown in full (lion → أسد → write ا).
  - **Group D** — every Lane-B picture swap + feedback rewording (grep `_review`), verbatim.
  - **Group E** — the full word/label diff (old → new), including the `taa.completeWord.middle` label fix (`[taa]`→`[taa, waaw]`).
  - **Group F** — all 22 reach-ahead exceptions, split by provenance: **F-1** the 4 baa D-09 (each framed "needs mother approval or re-point/remove"), **F-2** the 18 taa/thaa D-16 (block-or-per-row verdict).
  - **Group G** — the 3 thaa placeholders still needing her word ("NEEDS THE MOTHER") + the 2 thaa buildSentence draft adjectives.
  - Plus a **summary table** (19 rows + a tally) and a **"What you sign"** close.
- **Flipped baa to its honest state (Task 2, D-14/D-09).** Graph-level `signedOff` true→false in `graphs/baa.json` AND `curriculum_graph.json` (byte-parity held); exercise-level `signedOff` true→false on the 4 D-09 baa exception cards (`baa.fillBlank.adjective`, `baa.transformWord.dual/.plural/.opposite`). Intentional + temporary — Plan 25-07 flips confirmed items back to true per her verdict.
- **Proved the flip is SAFE.** `graph_asset_parity_test.dart` (byte-parity) + `learned_letters_lint_test.dart` (enforce-every-letter at signedOff:false) both green — baa and its 4 exceptions stay fully enforced/allowlisted despite the false flag, confirming the D-04/D-05 decoupling.

## Task Commits
Each task was committed atomically:
1. **Task 1: Assemble the 25-REVIEW-PACKET.md walkthrough checklist (D-11/D-13)** — `3410f53` (docs)
2. **Task 2: Flip baa graph + the 4 D-09 exception cards to honest signedOff:false (D-14/D-09)** — `38cc2a7` (fix)

## Files Created/Modified
- `.planning/phases/25-.../25-REVIEW-PACKET.md` (new) — the walkthrough checklist; every `_review` id in exercises.json appears as a packet row; the 4 D-09 baa ids each carry the "needs mother approval or re-point/remove" framing; the new alif draft shown in full.
- `assets/curriculum/graphs/baa.json` — graph-level `signedOff` true→false (line 15).
- `assets/curriculum/curriculum_graph.json` — graph-level `signedOff` true→false (line 15); byte-identical to baa.json after the flip.
- `assets/curriculum/exercises.json` — exercise-level `signedOff` true→false on 4 cards (lines 587/631/675/722); all other cards untouched.

## Verification Evidence
- **Task 1:** `grep -q "confirm / reject / rework"` → present; all 5 required ids (`baa.fillBlank.adjective`, `baa.transformWord.dual/.plural/.opposite`, `alif.writeLetter.fromPicture`) present; **all 16 exercises.json `_review` ids ⊆ packet ids** (0 missing); 335 lines (≥ 60).
- **Task 2:** `json.load(...)['signedOff'] is False` for both graphs; all 4 D-09 cards `signedOff is False`; `cmp -s graphs/baa.json curriculum_graph.json` → **BYTE-IDENTICAL** (parity held); diff = exactly six `signedOff: true→false` flips, nothing else.
- **Tests (after `flutter gen-l10n`):** `flutter test test/curriculum/graph_asset_parity_test.dart test/curriculum/learned_letters_lint_test.dart` → **All tests passed** (byte-parity + enforce-every-letter both green at signedOff:false).

## Decisions Made
- **Packet covers all 22 exceptions, not just the 4 D-09.** See key-decisions — the prior-wave context makes the packet the place the mother rules on the 18 D-16 ids too. Framed by provenance (device-UAT vs owner-decision) so she can weigh each group's warrant.
- **Surgical, verified flips only.** Graph flag via unique line-15 Edit; the 4 identical exercise-level flags via a line-index replacement that asserts the pre-image — never a blind global replace (which would have hit baa.buildSentence.* and taa/thaa cards).

## Deviations from Plan
None requiring a rule. The plan was executed as written; the only judgment call — enumerating the 18 D-16 exceptions in Group F-2 alongside the 4 D-09 ids the Task-1 text literally named — is the mandated coverage from the prior-wave context (criterion 4 = every change gets a verdict), documented above as a decision, not a scope change. No auto-fixes, no architectural escalations, no auth gates.

## Issues Encountered
- **l10n generated files missing in the fresh worktree** (known: `lib/l10n/app_localizations*.dart` is gitignored). Ran `flutter gen-l10n`; the two curriculum tests then compiled and passed. Not caused by this plan.
- No new packages. The worktree HEAD/cwd-drift safety assertions held on both commits.

## Known Stubs
- **The 22 owner-approved exceptions remain PROVISIONAL** (mother-verdict pending) — the packet is exactly the instrument that resolves them; Plan 25-07 ingests her verdicts. Tracked, not silent.
- **baa's `signedOff:false` window is intentional + temporary** (D-14). It is the honest state during assembly because live baa diverged from her signed spec (minCleanReps forced 1 vs signed 3; both buildSentence removed; 4 exceptions). Plan 25-07 flips confirmed items back to true per her verdict. SAFE — enforcement is decoupled from the flag (D-04/D-05); baa stays fully enforced at signedOff:false (lint green).
- The 3 thaa placeholders (`thaa.transformWord.plural/.opposite` with `expected:null`, `thaa.transformWord.dual` draft) are pre-existing (Plan 02) — surfaced in Group G for her input, not introduced here.

## Threat Flags
None new. The plan's threat register is satisfied:
- **T-25-06-R** (a change omitted from the packet) — MITIGATED: verified `grep '_review'` ids ⊆ packet ids (0 missing) + all six D-13 groups present (A–G), each with a verdict slot.
- **T-25-06-E** (the signedOff:false window silently un-enforcing baa) — MITIGATED: the lint runs AT signedOff:false and is green; baa + the 4 exceptions stay enforced/allowlisted (D-04/D-05 proven).
- **T-25-06-I** (child PII/strokes in the packet) — **ACCEPTED & CONFIRMED CLEAN:** the packet contains ONLY curriculum content (words, glosses, letters, feedback lines) + change descriptions. **No child identifiers, no nicknames, no stroke data, no PII of any kind.** Asserted here per the output spec.

## Next Phase Readiness
- **Plan 25-07 (verdict ingestion):** the packet is walkthrough-ready. The owner reads each of the 19 rows to the mother, captures confirm/reject/rework inline, then: (a) flips `signedOff` false→true per confirmed item (baa graph + the 4 D-09 cards + any D-16/alif she approves), (b) restores/reworks rejected content, (c) removes from `kApprovedReachAheadExceptions` + the L0/L1/L2 sources any exception she rejects (the L3 parity test enforces all four sets stay in lock-step). If she restores baa's writing/tracing to 3 clean reps, the tutor server's curriculum copy needs an owner-authorized re-derive + redeploy (flagged in Group A).

## Self-Check: PASSED
- `.planning/phases/25-.../25-REVIEW-PACKET.md` — FOUND (335 lines; contains "confirm / reject / rework"; all _review ids present)
- `assets/curriculum/graphs/baa.json` — FOUND (signedOff:false; byte-parity)
- `assets/curriculum/curriculum_graph.json` — FOUND (signedOff:false)
- `assets/curriculum/exercises.json` — FOUND (4 D-09 cards signedOff:false)
- Commit `3410f53` — FOUND
- Commit `38cc2a7` — FOUND

---
*Phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat*
*Completed: 2026-07-20*
