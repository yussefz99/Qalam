---
phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat
plan: 04
subsystem: tooling
tags: [python, firebase, seeder, curriculum, learned-letters, seen-letters-wall, L2, D-06]

# Dependency graph
requires:
  - phase: 25-01-L0-audit-machinery
    provides: "unlearned_letters_for_exercise + live_graph_node_ids + load_intro_order + OWNER_APPROVED_EXCEPTIONS — the single Python parity source this seeder imports"
  - phase: 25-02-triage
    provides: "gate exit 0 (22 owner-approved exceptions) so the CURRENT real content seeds through the guard without raising"
provides:
  - "seed_curriculum_v2._assert_learned_letters_legal(ex, order, live_ids): the L2 fail-fast refusal — reach-ahead LIVE-node card raises SystemExit before the first write"
  - "the wall's L2 parity: the seeder imports the L0 predicate/scoping/exceptions by name so L0/L1/L2 refuse identical content"
  - "test_seed_curriculum_v2.py: crafted-fixture proof (no live DB, no key) that a reach-ahead live-node card is refused with ZERO writes, and legal/dormant/exception cards pass"
affects: [25-05-L3-runtime-guard, 25-06-mothers-packet]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "L2 seeder refusal mirrors the existing _assert_firestore_legal fail-fast shape (raise SystemExit in the pre-write pass, nothing written)"
    - "Live-node-scoped enforcement: dormant configs + OWNER_APPROVED_EXCEPTIONS exempt, exactly as the L0 gate / L1 lint scope"
    - "Repo-root sys.path insert so the script's direct-run invocation (sys.path[0]=tools/firebase) can import tools.content.validate"
    - "Off-device seeder test: in-memory _StubFirestore records (collection, doc_id) writes so a refusal proves zero writes — no key, no network (mirror of test_roundtrip.py)"

key-files:
  created:
    - "tools/firebase/test_seed_curriculum_v2.py - the crafted-fixture refusal test (8 cases)"
  modified:
    - "tools/firebase/seed_curriculum_v2.py - _assert_learned_letters_legal guard + wired into the pre-write pass + validate.py import + docstring"
    - "tools/firebase/README.md - documents the L2 seen-letters wall on the seeder row"

key-decisions:
  - "Guard signature is _assert_learned_letters_legal(ex, order, live_ids) (3-arg, per the plan) — live_ids injected so a test can make a crafted id live without a real graph; seed() computes live_ids = live_graph_node_ids() and order = load_intro_order() ONCE and threads them in"
  - "Import path: insert _REPO_ROOT on sys.path then `from tools.content.validate import ...` — required because a direct `python tools/firebase/seed_curriculum_v2.py` run puts tools/firebase (not the repo root) on sys.path[0]; validated empirically both directions"
  - "Imported only the PUBLIC union OWNER_APPROVED_EXCEPTIONS (not the private _BAA_D09/_TAA_THAA groups), per the wave contract; the test names the 4 D-09 ids locally and asserts each is a member of the public union"
  - "Task 2's test passes green immediately because Task 1 already built the guard — the plan sequences implementation (Task 1, feat) before the crafted-fixture test (Task 2, test); the test validates the shipped behavior, it does not drive it"

patterns-established:
  - "All four wall layers refuse the SAME thing: L2 (seeder) now imports the L0 predicate + scoping + exception union by name so the seeder and the audit/lint cannot drift"
  - "Fail-fast, whole-pass-before-any-write: the learned-letters check joins the existing nested-array check in the pre-write validation loop, so a single illegal live-node card aborts the seed with nothing partially written"

requirements-completed: []  # QP-07 / D-12 are ADVANCED (L2 leg of the wall), NOT fully satisfied — the wall still needs L3 (25-05) + the mother's confirmation (25-06/25-07)

# Metrics
duration: ~15min
completed: 2026-07-19
---

# Phase 25 Plan 04: L2 seeder refusal — close the Firestore-first bypass Summary

**`seed_curriculum_v2.py` now refuses any LIVE graph-node card that reaches ahead of the learned set BEFORE the first Firestore write, reusing the L0 predicate (`unlearned_letters_for_exercise` + `live_graph_node_ids` + `OWNER_APPROVED_EXCEPTIONS`) imported from `tools/content/validate.py` so the seeder and the bundle audit refuse byte-identical content — proven by an 8-case crafted-fixture test that needs no live Firestore and no service-account key.**

## Performance
- **Duration:** ~15 min
- **Started:** 2026-07-19T~22:15Z
- **Completed:** 2026-07-19T22:30Z
- **Tasks:** 2
- **Files modified:** 3 (`seed_curriculum_v2.py`, `README.md`, `test_seed_curriculum_v2.py` new)

## Accomplishments
- Added `_assert_learned_letters_legal(ex, order, live_ids)` — a sibling of the existing `_assert_firestore_legal` fail-fast guard. For a LIVE graph node, a reach-ahead card (`unlearned_letters_for_exercise` non-empty) raises `SystemExit("… demands unseen letter(s) …; nothing was written.")` unless its id is an `OWNER_APPROVED_EXCEPTIONS` member. Dormant configs (referenced by no live node) are never gated — exactly the L0/L1 scoping.
- Reused the L0 parity source: imported `unlearned_letters_for_exercise`, `live_graph_node_ids`, `load_intro_order`, and the public `OWNER_APPROVED_EXCEPTIONS` union from `tools/content/validate.py` (no re-hardcoded id list — the single Python source stays in validate.py).
- Wired the guard into the pre-write validation loop (before the first `doc(id).set(...)`), computing `live_ids`/`order` once — fail-fast, no partial seed.
- Added the repo-root `sys.path` insert so the `tools.content.validate` import resolves under a direct `python tools/firebase/seed_curriculum_v2.py` run (where `sys.path[0]` is `tools/firebase/`, not the repo root).
- Wrote `test_seed_curriculum_v2.py` (8 cases, pytest): an in-memory `_StubFirestore` records every write; proves the illegal live-node card raises + writes ZERO docs, a dormant reach-ahead config is seeded normally, and a legal card + the 4 baa D-09 exceptions are accepted. No live Firestore, no key.
- Documented the L2 wall in the module docstring's Safety-guards block and on the seeder's `README.md` row.

## Task Commits
Each task was committed atomically:
1. **Task 1: Add the learned-letters refusal to the pre-write pass (D-06)** — `362f74f` (feat)
2. **Task 2: Crafted-fixture refusal test — no live DB, no key** — `8a469c4` (test)

## Files Created/Modified
- `tools/firebase/seed_curriculum_v2.py` — new `_assert_learned_letters_legal` guard; call wired into the exercises pre-write loop; `live_ids`/`order` computed once; `from tools.content.validate import (...)` with a repo-root `sys.path` insert; docstring Safety-guards note.
- `tools/firebase/README.md` — seeder row now documents the seen-letters wall (L2, D-06) + which validate.py names it reuses.
- `tools/firebase/test_seed_curriculum_v2.py` (new) — `_StubFirestore` + 8 tests (guard-direct + end-to-end `seed()` cases).

## Verification Evidence
- `pytest tools/firebase/test_seed_curriculum_v2.py -q` → **8 passed** (exit 0).
- `python -m py_compile tools/firebase/seed_curriculum_v2.py` → ok; `grep` finds `_assert_learned_letters_legal` + `unlearned_letters_for_exercise` (3 occurrences).
- Import parity: `grep` shows `from tools.content.validate import`, `OWNER_APPROVED_EXCEPTIONS`, `live_graph_node_ids` — no re-hardcoded exception-id list.
- Guard behavior (smoke): reach-ahead live node → raises `… 'baa.x' demands unseen letter(s) taa(3); nothing was written.`; legal card / D-09 exception / dormant config → no raise.
- `seed(stub_db, None)` over the CURRENT (Plan-02-triaged) real content → does NOT raise, writes every doc: **4 graphs, 72 exercises, 4 units** to the stub (proof `--all` completes and dormant configs + exceptions pass through).
- No new packages (uses existing `firebase_admin` 7.4.0 + `content.validate`). No child data reaches the refusal message (only doc id + unseen letter) — T-25-04-I held.

## Decisions Made
- **3-arg guard with injected `live_ids`.** The plan specifies `_assert_learned_letters_legal(ex, order, live_ids)`; injecting `live_ids` (rather than calling `live_graph_node_ids()` inside the guard) lets `seed()` compute it once and lets a test mark a crafted id live without authoring a real graph. Matches the plan's Task 2 call form exactly.
- **Repo-root `sys.path` insert.** Empirically confirmed the `tools.content.validate` import fails from a direct script run without it (sys.path[0] = `tools/firebase/`), and resolves once the repo root is inserted. `tools/content/__init__.py` has no side effects; `firebase_admin` 7.4.0 and `pytest` 9.1.1 are both present.
- **Public-union import only.** Imported `OWNER_APPROVED_EXCEPTIONS` (the 22-id union), never the private `_BAA_D09/_TAA_THAA` groups, per the wave contract. The test names the 4 D-09 ids as a local list and asserts each is in the public union.

## Deviations from Plan
None — plan executed exactly as written. No auto-fixes, no architectural escalations, no auth gates.

## TDD Gate Compliance
Task 2 is `tdd="true"`, but the plan intentionally sequences Task 1 (the implementation, `feat`) before Task 2 (the crafted-fixture test, `test`). The test therefore passes green on first run — it validates the already-shipped guard rather than driving it RED→GREEN. This is the plan's authored ordering, not a skipped RED gate: a `feat(...)` commit (`362f74f`) precedes the `test(...)` commit (`8a469c4`) for the same behavior. No separate RED commit exists by design.

## Issues Encountered
- None. The one non-obvious surface — importing `tools.content.validate` from a script whose directory (not the repo root) lands on `sys.path[0]` — was resolved with the repo-root insert and verified in both invocation contexts (direct run + pytest).
- Honored the safety constraint: no live Firebase access, no seeding of any real project — the guard logic is unit-tested entirely offline with an in-memory stub.

## Known Stubs
None introduced. (The 22 `OWNER_APPROVED_EXCEPTIONS` the seeder exempts remain provisional pending the mother's verdict — tracked by Plans 25-06/25-07, not by this plan.)

## Threat Flags
None new. T-25-04-T (crafted content bypassing the shape-only validator to reach prod Firestore) is now mitigated by `_assert_learned_letters_legal` in the fail-fast pre-write pass, reusing the L0 predicate (criterion 2). The refusal message names only the doc id + the unseen letter — no child data (T-25-04-I held). No new pip installs (T-25-04-SC held).

## Next Phase Readiness
- **Plan 25-05 (L3 runtime guard):** the same learned-set rule (`introOrder[l] > unitIntroOrder`) is the Dart runtime filter's predicate; the L2/L0 Python parity is the reference behaviour to mirror.
- **Plan 25-06 (mother's packet):** the 22 owner-approved exceptions the seeder exempts are enumerable from `validation_report.md §4`; every one is still provisional until her verdict.
- QP-07 / D-12 advanced (the L2 leg holds) but NOT complete — the wall needs L3 + the mother's confirmation.

## Self-Check: PASSED
- `tools/firebase/seed_curriculum_v2.py` — FOUND (guard present, importable, py_compile ok)
- `tools/firebase/test_seed_curriculum_v2.py` — FOUND (8 tests pass)
- `tools/firebase/README.md` — FOUND (L2 wall documented)
- Commit `362f74f` — FOUND
- Commit `8a469c4` — FOUND

---
*Phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat*
*Completed: 2026-07-19*
