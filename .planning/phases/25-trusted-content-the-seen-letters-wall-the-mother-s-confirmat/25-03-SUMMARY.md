---
phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat
plan: 03
subsystem: curriculum
tags: [curriculum, learned-letters, seen-letters-wall, lint, L1, signedOff, D-04, D-05, D-16, QP-07, D-12]

# Dependency graph
requires:
  - phase: 25-01-L0-audit-machinery
    provides: "validate.py::unlearned_letters_for_exercise — the Python reach-ahead predicate this Dart lint mirrors behaviorally; OWNER_APPROVED_EXCEPTIONS the allowlist reflects"
  - phase: 25-02-triage
    provides: "D-16 (Option B): 18 taa/thaa reach-ahead word cards grandfathered as owner-approved exceptions (not removed); the two provenance groups _BAA_D09_EXCEPTIONS (4) + _TAA_THAA_D16_EXCEPTIONS (18) this lint's per-unit allowlist mirrors"
provides:
  - "learned_letters_lint_test.dart — the enforce-EVERY-live-letter lint (L1): the signedOff dispatch is collapsed to one path; baa, taa, thaa, alif all run the same violation assertion (D-04/D-05)"
  - "a per-unit owner-approved allowlist mirroring validate.py's 22-id OWNER_APPROVED_EXCEPTIONS (4 baa D-09 + 18 taa/thaa D-16), scoped so the no-rot liveness check holds each id to its own graph"
  - "a behavioral-parity assertion vs validate.py::unlearned_letters_for_exercise (crafted {letters:['taa']} at baa) — proof the four wall layers refuse identical content"
affects: [25-04-seeder-L2, 25-05-runtime-guard-L3, 25-06-mothers-packet, 25-07-verdict-ingestion]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "One enforcement path for every live letter — signedOff decoupled from enforcement (D-04/D-05); the flag is HUMAN sign-off only, verified never read as an enforcement gate in lib/"
    - "Per-unit owner-approved allowlist mirrors validate.py's OWNER_APPROVED_EXCEPTIONS by union, scoped per letter so the no-rot liveness check binds each id to its own live graph"
    - "A Dart↔Python parity assertion pins the shared reach-ahead predicate (stored letters[] vs introOrder, 1<<30 sentinel) so L1 and L0/L2 cannot drift"

key-files:
  created:
    - ".planning/phases/25-.../25-03-SUMMARY.md - this summary"
  modified:
    - "test/curriculum/learned_letters_lint_test.dart - collapsed the signedOff dispatch to a single enforce-all path; rewrote the header contract to D-04/D-05; carried the full 22-id owner-approved allowlist (per-unit, provenance-tagged); added the validate.py parity assertion"

key-decisions:
  - "The plan's Task 2 text ('taa/thaa carry NO exceptions after triage') was written assuming Plan 02 would triage to zero. Plan 02 instead chose Option B / D-16 (grandfather the 18 taa/thaa cards). Enforcing every live letter is GREEN only if those 18 exceptions are present — so the allowlist mirrors validate.py's full 22-id OWNER_APPROVED_EXCEPTIONS, not just baa's 4. This is the mandated reconciliation from the prior-wave context + both wave summaries."
  - "Exceptions scoped PER UNIT (baa/taa/thaa maps; alif none) rather than one flat set, so the preserved no-rot liveness check (`every allowlisted id must be a live node in THIS unit`) stays correct — a flat 22-id set would false-fail the taa unit on thaa ids and vice versa."
  - "signedOff field kept parsed in _UnitGraph (from the preserved-verbatim _discoverUnitGraphs) but never read in the enforcement loop — enforcement no longer dispatches on it (D-04/D-05)."
  - "Parity assertion injects a synthetic non-live id (`__parity.taaAtBaa__`) into exercisesById AFTER the enforcement loop, so it exercises the verbatim unlearnedFor directly without touching the lint's live-node scoping."

patterns-established:
  - "The seen-letters wall's Dart leg (L1) mirrors the Python source-of-truth (validate.py) by union name AND by a live parity assertion — a code-level guard against the two predicates drifting"
  - "Owner-approved exceptions stay provenance-tagged (D-09 device-UAT baa / D-16 owner-decision taa/thaa) in the lint just as in validate.py, so Plan 25-06's packet can rule on each group separately"

requirements-completed: []  # QP-07 / D-12 are ADVANCED (the L1 lint leg of criterion 1 now enforces every letter), NOT fully satisfied — the wall still needs L2 seeder (25-04) + L3 guard (25-05) + the mother's confirmation (25-06/25-07). Every exception is provisional until her verdict.

# Metrics
duration: ~20min
completed: 2026-07-19
---

# Phase 25 Plan 03: L1 lint — collapse the signedOff dispatch, enforce every live letter Summary

**The learned-letters lint's two-way `signedOff` dispatch is collapsed to ONE enforce-all path (D-04/D-05): baa, taa, thaa, and alif now run the identical violation assertion, the draft exemption is gone, `signedOff` is decoupled from enforcement (proven never read as a gate in lib/), and a validate.py parity assertion pins the shared reach-ahead predicate — all GREEN because the allowlist mirrors validate.py's full 22-id OWNER_APPROVED_EXCEPTIONS (4 baa D-09 + 18 taa/thaa D-16).**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-19 (worktree base 996e4a7)
- **Completed:** 2026-07-19
- **Tasks:** 2
- **Files modified:** 1 (`test/curriculum/learned_letters_lint_test.dart`)

## Accomplishments
- **Collapsed the `signedOff` dispatch (D-04/D-05).** Deleted the `if (unit.signedOff) { …ENFORCED… } else { …ACKNOWLEDGED (printOnFailure, never fail)… }` split. Every discovered live unit now runs the single `expect(violations, isEmpty, …)` assertion — taa, thaa, alif are held to the same bar baa always was. The draft exemption no longer exists.
- **Rewrote the header contract** from the OLD two-disposition rule to the D-04/D-05 rule: `signedOff` no longer controls enforcement; every live letter is held to the seen-letters bar; `signedOff` now means only "the mother has confirmed THIS content."
- **Carried the full owner-approved allowlist the enforce-all path needs.** Mirror of validate.py's `OWNER_APPROVED_EXCEPTIONS` (22 ids), split into the same two provenance groups (baa D-09 = 4, taa/thaa D-16 = 18), scoped per unit so the preserved no-rot liveness check holds each id to its own live graph. alif carries no exceptions.
- **Added a validate.py parity assertion** — a crafted `{letters:['taa']}` card at the baa unit reports taa as reach-ahead via the verbatim `unlearnedFor`, documented as behavioral parity with `validate.py::unlearned_letters_for_exercise` (same stored-`letters[]` vs `introOrder` read, same `1<<30` sentinel).
- **Proved `signedOff` is decoupled from enforcement** — grep of lib/ shows only parse/construct/comment reads, never an enforcement branch (the D-04/D-05 decoupling proof, below).
- **Preserved verbatim** (per the plan): `_discoverUnitGraphs()`, `unlearnedFor`, the `introOrder` map build, the baa-specific learned-set sanity pins, and the full coverage assertion (every discovered graph visited; baa + thaa explicitly covered).

## Task Commits

Each task was committed atomically:

1. **Task 1: Collapse the signedOff dispatch — enforce every live letter (D-04/D-05)** - `c759097` (test)
2. **Task 2: Add the validate.py parity assertion + scope the exception allowlist** - `25b3715` (test)

## Files Created/Modified
- `test/curriculum/learned_letters_lint_test.dart` — header contract rewritten to D-04/D-05; the `signedOff` if/else dispatch removed and replaced with a single enforce-all path over every discovered unit; the per-unit 22-id owner-approved allowlist (provenance-tagged) added; the parity assertion appended. 275 lines (was 227), contains `QP-07`.

## Verification Evidence
- **Task 1:** `! grep -q 'if (unit.signedOff)' …` → PASS (no dispatch). `grep printOnFailure|ACKNOWLEDGED|reachingAhead` → none (the acknowledged else-path is gone). `flutter test test/curriculum/learned_letters_lint_test.dart` → **All tests passed**.
- **Task 2:** `flutter test …` → **All tests passed**. `grep -c "baa.fillBlank.adjective\|baa.transformWord.dual\|baa.transformWord.plural\|baa.transformWord.opposite"` → **4** (`-ge 4` PASS).
- **Enforce-all simulation (worktree assets):** every unit — baa (order 2, signedOff=true), alif (1, false), taa (3, false), thaa (4, false) — reports **0 non-exempt violations** and **0 exception-rot**, so the collapse is GREEN, not red (Plan 02 grandfathered the taa/thaa reach-ahead as exceptions).
- **Artifact contract:** 275 lines ≥ 150 ✓; `contains: QP-07` ✓.

### lib/ `signedOff` grep — the D-04/D-05 decoupling proof (plan output requirement)
`grep -rn "signedOff" lib/ | grep -v '\.g\.dart'` → 24 matches, ALL of which are parse / construct / comment — **zero enforcement branches**:
- **Comments (6):** `spike_genui/fixtures/baa_reference.dart:18`, `core/scoring/stroke_validation.dart:311`, `models/exercise.dart:15`, `data/curriculum_repository.dart:290`, `data/firestore_curriculum_codec.dart:22,123`.
- **Field declarations (6):** `curriculum/curriculum_graph.dart:105,116`, `models/letter.dart:161,191`, `models/exercise.dart:48,74`.
- **JSON parse (3):** `curriculum/curriculum_graph.dart:148`, `models/letter.dart:218`, `models/exercise.dart:104` — all `json['signedOff'] as bool …`.
- **Construct sites `signedOff: false` (9):** `features/letter_unit/letter_unit_screen.dart:606,616,630,642,655`, `features/letter_unit/exercise_presenter.dart:112,126,139,152`.
- **Targeted branch grep** `grep -rnE "if\s*\(.*signedOff|\.where\(.*signedOff|signedOff\s*[=!]=|signedOff\s*\?|while\s*\(.*signedOff|assert\(.*signedOff" lib/` → **NONE**. Confirmed: `signedOff` is never read as an enforcement gate in lib/ — it is HUMAN sign-off only (D-05).

## Decisions Made
- **The allowlist mirrors validate.py's full 22-id set, not the plan's literal "4 baa only."** See Deviations — this is the load-bearing reconciliation with Plan 02's D-16.
- **Per-unit scoping of the allowlist.** A flat 22-id set would break the preserved no-rot liveness check (it iterates each unit's exceptions and asserts every id is a live node in THAT unit). Splitting into `baa`/`taa`/`thaa` maps keeps each exception bound to its own graph; alif → empty.
- **`signedOff` field kept but never branched on.** `_discoverUnitGraphs` (preserved verbatim) still parses it; the enforcement loop simply never reads it. This satisfies "no `unit.signedOff` dispatch" while keeping the preserve-verbatim requirement.

## Deviations from Plan

### 1. [Rule 3 - Blocking / superseded by D-16] The allowlist holds 22 ids (4 baa D-09 + 18 taa/thaa D-16), not the plan's literal "4 baa only; taa/thaa empty"
- **Found during:** Task 1 (before the first commit, during the enforce-all design).
- **Issue:** Plan 25-03's Task 2 text and `must_haves.truths` say *"the exception allowlist holds only … the 4 D-09 ids … taa/thaa carry no exceptions after triage"* and *"taa/thaa/alif exception sets are empty."* That text was written on the assumption that Plan 02 would triage the taa/thaa reach-ahead to zero (re-point / remove — the D-07 default). **Plan 02 instead chose Option B / D-16** (owner decision 2026-07-19): the 18 taa/thaa reach-ahead word cards were GRANDFATHERED as owner-approved exceptions and remain LIVE. With enforce-every-letter (D-04) applied, those 18 live cards reach ahead — so asserting "taa/thaa exceptions are empty" would make `flutter test` **RED**. Following the plan literally is impossible.
- **Fix:** Mirrored validate.py's actual `OWNER_APPROVED_EXCEPTIONS` (the union `_BAA_D09_EXCEPTIONS | _TAA_THAA_D16_EXCEPTIONS`, 22 ids) as the Dart allowlist, scoped per unit and provenance-tagged. This is exactly what the prior-wave context, 25-01-SUMMARY ("Plan 25-03 … must reflect BOTH exception groups (22 ids total)"), and 25-02-SUMMARY ("the Dart lint's `baaOwnerApprovedExceptions` mirror must be extended to the taa/thaa D-16 ids") mandate. The plan's *underlying goal* — one enforcement path, allowlist = only mother-review-pending exceptions, signedOff decoupled — is fully met; only the exception COUNT changed (4 → 22) to match the D-16 reality.
- **Files modified:** `test/curriculum/learned_letters_lint_test.dart`
- **Verification:** `flutter test` green; the 22-id allowlist matches validate.py's union byte-for-byte (verified each of the 18 D-16 ids is a live node in its graph — no rot); baa-id grep count = 4.
- **Committed in:** `c759097`, `25b3715`

**Total deviations:** 1 (blocking, mandated by the D-16 owner decision from Plan 02). No scope change beyond the exception count; the lint's structure, parity, and preserved sections match the plan exactly.

## Issues Encountered
- **Initial cwd/path slip (corrected).** Early Bash/Read used the main-checkout path (`/Users/…/qalam/`) instead of the worktree root; the Write tool blocked the shared-path write. Re-established `WT_ROOT` via `git rev-parse --show-toplevel`, confirmed the worktree test file was byte-identical to what was read, re-ran all verification against the worktree's own assets (same result), and did all edits/commits inside the worktree. No wrong-location writes occurred.
- No new packages. No child data touched (this is a build-time test over bundled JSON).

## Known Stubs
None introduced. The 22 owner-approved exceptions remain **provisional** (mother-verdict pending, D-09 baa / D-16 taa/thaa) — tracked in Plan 02's summary and the mother's packet (25-06), not a stub of this plan. The lint correctly holds each exception to a live-node liveness check so none can silently rot.

## Threat Flags
None new. The plan's threat register is satisfied:
- **T-25-03-T** (a future letter slipping through unlinted) — `_discoverUnitGraphs` + the coverage assertion are preserved verbatim; a new live graph not visited fails the test.
- **T-25-03-R** (an exception silently rotting) — the no-rot liveness check is preserved and now runs for all three exception-bearing units.
- **T-25-03-E** (a draft elevated to enforced-exempt via signedOff) — the lint no longer dispatches on `signedOff`; the lib/ grep proves it is never an enforcement gate.

## Next Phase Readiness
- **Plan 25-04 (L2 seeder):** the Dart L1 lint now exempts the SAME 22 cards L0/L2 do (validate.py's union). The seeder can import `OWNER_APPROVED_EXCEPTIONS` and `unlearned_letters_for_exercise` and be byte-parity with this lint.
- **Plan 25-06 (mother's packet):** the lint's exceptions are provenance-tagged identically to validate.py (D-09 baa / D-16 taa/thaa), so the packet's per-group enumeration matches the code.
- **Blocker for the phase's success:** every exception here is provisional; criterion 4 (the mother's verdicts flipping `signedOff` / re-pointing rejects) is satisfied only by 25-06/25-07.

## Self-Check: PASSED
- `test/curriculum/learned_letters_lint_test.dart` — FOUND (275 lines, contains QP-07, test green)
- Commit `c759097` — FOUND
- Commit `25b3715` — FOUND
- No `if (unit.signedOff)` dispatch — CONFIRMED absent
- lib/ signedOff enforcement branch — CONFIRMED none

---
*Phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat*
*Completed: 2026-07-19*
