---
phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat
plan: 02
subsystem: curriculum
tags: [curriculum, content, learned-letters, seen-letters-wall, exceptions, build-gate, D-16]

# Dependency graph
requires:
  - phase: 25-01-L0-audit-machinery
    provides: "the --gate build gate + OWNER_APPROVED_EXCEPTIONS extension point + live_graph_node_ids scoping this plan drives to zero"
provides:
  - "gate exit 0: every live graph-node card obeys the learned-letters bar or is an owner-approved exception (criterion 1, content leg)"
  - "_TAA_THAA_D16_EXCEPTIONS (18 ids) + _BAA_D09_EXCEPTIONS (4 ids) — two provenance-separated groups; OWNER_APPROVED_EXCEPTIONS is their union (the exact set the mother's packet must rule on)"
  - "validation_report.md §4 — the machine-generated enumeration of all 22 exempt cards with provenance (D-09 vs D-16) for Plan 25-06"
  - "alif.writeLetter.fromPicture — a valid enforced draft node (letters+criteria, signedOff:false)"
  - "taa.completeWord.middle — truthfully relabeled letters[] ['taa','waaw']"
affects: [25-03-lint-L1, 25-04-seeder-L2, 25-06-mothers-packet, 25-07-verdict-ingestion]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Owner-approved exceptions carry PROVENANCE: two named frozensets (D-09 device-UAT baa / D-16 owner-decision taa/thaa) unioned into the single public OWNER_APPROVED_EXCEPTIONS the wall reads"
    - "The build report self-documents the gate: §4 lists every exempt reach-ahead card + verdict, so the packet is generated, never hand-curated"
    - "Truthful labeling is invariant: an exception covers reach-ahead, NEVER a false letters[] label (the drift is fixed first, THEN grandfathered)"

key-files:
  created:
    - ".planning/phases/25-.../25-02-SUMMARY.md - this summary"
  modified:
    - "tools/content/validate.py - OWNER_APPROVED_EXCEPTIONS split into D-09+D-16 groups; _gate_findings/_gate_report_section refactor; report §4 build-gate section"
    - "tools/content/validation_report.md - regenerated with §4 (22 exceptions, 0 findings, GATE PASS)"
    - "assets/curriculum/exercises.json - completed alif.writeLetter.fromPicture (D-15); truthfully relabeled taa.completeWord.middle letters[] (D-16)"

key-decisions:
  - "D-16 (owner, 2026-07-19): grandfather the taa+thaa reach-ahead word cards as owner-approved exceptions (Option B, mirroring baa's D-09) rather than remove them — 'I don't want to remove all questions and have each unit have only a few questions — the app is built for kids that know Arabic.'"
  - "Re-point (D-07 default) is IMPOSSIBLE for taa/thaa: the curated draft bank unlocks 0 legal words at unit 3 (taa) or 4 (thaa); no word both contains taa/thaa AND is legal there. Fabricating a word would violate CLAUDE.md 'do not invent pedagogy'."
  - "taa.completeWord.middle relabeled letters[] ['taa']→['taa','waaw'] (truthful توت decomposition) BEFORE grandfathering — an exception may cover reach-ahead but must never mask a false label."
  - "Editing validate.py = Rule-1 in-scope deviation (a 25-01 artifact, but OWNER_APPROVED_EXCEPTIONS is its designed extension point); the report §4 section makes the 22 exceptions enumerable for Plan 25-06."

patterns-established:
  - "Owner-decision exceptions are provenance-tagged (D-09 device-UAT vs D-16 owner-decision) so the mother's packet can rule on each group's warrant separately"
  - "Every grandfathered reach-ahead card MUST appear in validation_report.md §4 → the packet enumerates from the machine artifact, not a hand list"

requirements-completed: []  # QP-07 / D-12 / CUR-01 are ADVANCED (criterion-1 content leg: gate exits 0), NOT fully satisfied — the wall still needs L1 lint (25-03) + L2 seeder (25-04) + L3 guard (25-05) + the mother's confirmation (25-06/25-07). Every D-16 exception is provisional until her verdict.

# Metrics
duration: ~35min active (spanned an Option-A/B decision checkpoint + a transient-error resume)
completed: 2026-07-19
---

# Phase 25 Plan 02: Triage the seen-letters worklist to zero (Option B / D-16) Summary

**The 18 live taa/thaa reach-ahead word cards are grandfathered as provenance-tagged owner-approved exceptions (D-16) — not removed — so `python -m content.validate --gate` exits 0 with 22 exempt cards (4 baa D-09 + 18 taa/thaa D-16), the star is untouched, and the mother's packet can enumerate every exception from the machine-generated report §4.**

## Performance

- **Duration:** ~35 min active (across an owner decision checkpoint + a transient-error resume)
- **Started:** 2026-07-19 (first task commit 18:10Z)
- **Completed:** 2026-07-19 (last task commit 19:17Z)
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Drove the criterion-1 build gate to **exit 0**: 0 live-node findings, 22 owner-approved exceptions exempt.
- Split `OWNER_APPROVED_EXCEPTIONS` into two provenance-separated groups — `_BAA_D09_EXCEPTIONS` (4, device-UAT) and `_TAA_THAA_D16_EXCEPTIONS` (18, owner decision 2026-07-19) — unioned into the single public name L0/L2 read.
- Added a `## 4 · Build gate` section to `validation_report.md` that lists all 22 exempt reach-ahead cards with unlearned letters + provenance + the PASS/FAIL verdict — the enumeration Plan 25-06 assembles the packet from.
- Truthfully relabeled `taa.completeWord.middle` `letters[]` `['taa']`→`['taa','waaw']` (the deduped decomposition of توت) — fixed the false label FIRST, then grandfathered.
- Completed the `alif.writeLetter.fromPicture` draft card (D-15): `letters:["alif"]` + the 5-item `writeLetter` stroke criteria, `signedOff:false`.
- Confirmed the star-reachability invariant (D-02) untouched (nothing removed) and baa byte-parity held (baa graphs untouched); all four curriculum/progression test files stay green — no test surgery.

## Task Commits

Each task was committed atomically:

1. **Task 3: Complete alif.writeLetter.fromPicture draft card (D-15)** - `18d7b43` (feat)
2. **Task 1: Truthfully relabel taa.completeWord.middle letters[] (D-16)** - `dd86c2d` (fix)
3. **Task 2: Grandfather taa/thaa reach-ahead cards as D-16 owner exceptions** - `55c8f78` (feat)

_Note: Task 3 (the independently-safe D-15 draft-card completion) was committed before the disposition checkpoint; Tasks 1 & 2 landed after the owner chose Option B._

## Files Created/Modified
- `tools/content/validate.py` — `OWNER_APPROVED_EXCEPTIONS` restructured into `_BAA_D09_EXCEPTIONS | _TAA_THAA_D16_EXCEPTIONS`; extracted `_gate_findings` (surfaces exempt reach-ahead cards) + `_gate_report_section` + `_provenance`; `run_gate` now prints the exempt cards; `main` always writes §4 to the report.
- `tools/content/validation_report.md` — regenerated; §4 lists 22 exceptions (0 findings, GATE PASS).
- `assets/curriculum/exercises.json` — `alif.writeLetter.fromPicture` completed (letters+criteria); `taa.completeWord.middle` letters[] relabeled + a greppable `_review` note.

## Decisions Made
- **D-16 — grandfather taa/thaa as owner exceptions (Option B), owner's call 2026-07-19.** Verbatim constraint on record: *"I don't want to remove all questions and have each unit have only a few questions — the app is built for kids that know Arabic."* Heritage learners already know these words aurally; thaa passed Stage-1 device UAT; baa's D-09 is the precedent; the mother's packet (25-06) + live walkthrough (25-07) remain the final pedagogical gate for every grandfathered card.
- **Re-point is genuinely impossible for taa/thaa.** The draft bank unlocks 0 legal words at unit 3 (taa) or 4 (thaa) — باب lands at baa (unit 2), تاج at jeem (unit 5) — and no live/draft word both contains taa/thaa and is legal there. So D-07's re-point branch has no target, and removal (its second branch) was rejected by the owner.
- **Truthful labeling before grandfathering.** An owner exception legitimizes *reach-ahead*, never a false `letters[]`. `taa.completeWord.middle` was mislabeled `['taa']` (توت is `['taa','waaw']`); it was corrected first, so it correctly surfaces as reach-ahead (waaw) and then joins the exception set honestly.
- **Report §4 for a machine-generated packet.** Rather than a hand list, the gate now emits the full exception table into `validation_report.md`, so Plan 25-06 enumerates from the artifact and cannot drift from the code.

## Deviations from Plan

### 1. [Rule 4 → owner decision] The plan's D-07 default (re-point else remove) could not be applied as written — escalated to a checkpoint; owner chose Option B (D-16)
- **Found during:** Task 1/2 (the triage core)
- **Issue:** The plan assumed re-pointable learned-set words exist for taa/thaa. They do not (draft bank: 0 words legal at units 3/4). The only in-rule disposition left was REMOVE, but removing all taa/thaa word cards would (a) gut both units to letter-level, and (b) break load-bearing thaa progression tests (`thaa_walker_progression_test`'s fail-path structurally needs a ramp/tier node that only word cards provide). Both re-point and remove were therefore off the table for a mechanical, autonomous pass — a pedagogical + architecture fork (CLAUDE.md: "propose, don't decide, especially on anything pedagogical").
- **Fix:** Stopped and returned a decision checkpoint (Options A remove / B grandfather / C hybrid). The coordinator relayed the owner's decision: **Option B** — grandfather the 18 taa/thaa reach-ahead cards as owner-approved exceptions (D-16), mirroring baa's D-09, mother-verdict pending.
- **Files modified:** `tools/content/validate.py`, `assets/curriculum/exercises.json`
- **Verification:** `python -m content.validate --gate` exits 0 (22 exempt, 0 findings); the 4 curriculum/progression tests + graph_asset_parity all pass.
- **Committed in:** `dd86c2d`, `55c8f78`

### 2. [Rule 1 - Blocking, coordinator-authorized] Edited validate.py (a 25-01 artifact) to add the D-16 exceptions + report §4
- **Found during:** Task 2
- **Issue:** Option B requires the 18 taa/thaa ids to be exempt from the gate; the exception list lives in `validate.py`, which is not in this plan's `files_modified`.
- **Fix:** Edited `OWNER_APPROVED_EXCEPTIONS` (its designed extension point) into two provenance groups + added the report §4 section. Coordinator explicitly authorized this as a Rule-1 in-scope deviation.
- **Files modified:** `tools/content/validate.py`, `tools/content/validation_report.md`
- **Verification:** repo-root import contract holds (`OWNER_APPROVED_EXCEPTIONS` == union, 22 ids, groups disjoint); L2 seeder does not yet import it (that wiring is Plan 25-04) so nothing downstream breaks.
- **Committed in:** `55c8f78`

### Plan artifact notes (not deviations, but worth the packet's attention)
- `graphs/alif.json`, `graphs/{baa,taa,thaa}.json`, `curriculum_graph.json` were **NOT modified** — the plan's `files_modified` anticipated graph pruning, but Option B keeps every node live (no removals), so no graph edit was needed. alif's graph was already letter-level with the `fromPicture` node. baa byte-parity is therefore trivially held.

---

**Total deviations:** 1 owner-decision escalation (Rule 4) + 1 authorized Rule-1 edit.
**Impact on plan:** The disposition changed (grandfather, not re-point/remove) per the owner's D-16 decision; criterion 1 (gate exits 0) is met and the star is preserved. No pedagogy invented — every kept card is provisional pending the mother's verdict.

## Issues Encountered
- **l10n generated files missing in the fresh worktree** (known: `lib/l10n/app_localizations*.dart` is gitignored). Two curriculum tests failed to compile until `flutter gen-l10n` was run; after that all pass. Not caused by this plan's edits; the generated files are gitignored and not committed.
- **Transient API termination mid-work** — the worktree survived intact (commits `18d7b43`, `dd86c2d` present, tree clean); resumed from there per the coordinator's verified state.

## Known Stubs
- The **22 owner-approved exceptions are provisional** — they demand unseen letters and stay live ONLY by owner decision (D-09 baa / D-16 taa/thaa), mother-verdict PENDING. Each MUST be confirmed / rejected / re-pointed in the Plan 25-06 packet; this is tracked, not silent.
- Pre-existing (not introduced here): `thaa.transformWord.plural` and `thaa.transformWord.opposite` are live placeholder nodes with `expected:null` and `_review` notes reading "NEEDS THE MOTHER" — they do not trip the gate (stored `letters:['thaa']`) and are untouched by this plan.
- `alif.writeLetter.fromPicture` and taa/thaa letters remain `signedOff:false` by design (D-15 / D-10) — promotion is Plan 25-07.

## Threat Flags
None new. T-25-02-T (a re-point silently reducing a teaching point) is avoided under Option B — no re-point happened; every card is kept as-authored for the mother's review. T-25-02-D (a removal stranding the star) is avoided — nothing was removed; the star is untouched (D-02).

## Next Phase Readiness
- **Plan 25-03 (L1 lint):** the Dart lint's `baaOwnerApprovedExceptions` mirror must be extended to the taa/thaa D-16 ids (and the draft exemption removed) so L1 exempts the SAME 22 cards L0 does. The Python provenance split (`_BAA_D09_EXCEPTIONS` / `_TAA_THAA_D16_EXCEPTIONS`) is the reference.
- **Plan 25-04 (L2 seeder):** can `from content.validate import OWNER_APPROVED_EXCEPTIONS, unlearned_letters_for_exercise, live_graph_node_ids, load_intro_order` — the union name is stable (22 ids).
- **Plan 25-06 (packet):** enumerate the exceptions directly from `validation_report.md §4` (provenance column separates the 4 baa D-09 from the 18 taa/thaa D-16) + grep `_review` in exercises.json for the label/relabel diff.
- **Blocker/gate for the phase's success:** every D-16 exception is provisional; criterion 4 (the mother's verdicts) is not satisfiable until 25-06/25-07.

## Self-Check: PASSED
- `tools/content/validate.py` — FOUND (gate exits 0; 22 exempt)
- `tools/content/validation_report.md` — FOUND (§4 present, 0 findings, GATE PASS)
- `assets/curriculum/exercises.json` — FOUND (alif card valid; taa.completeWord.middle relabeled)
- Commit `18d7b43` — FOUND
- Commit `dd86c2d` — FOUND
- Commit `55c8f78` — FOUND

---
*Phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat*
*Completed: 2026-07-19*
