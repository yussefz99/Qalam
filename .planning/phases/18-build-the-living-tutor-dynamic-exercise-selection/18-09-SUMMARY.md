---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 09
subsystem: server
tags: [nightly-job, cloud-run-job, cloud-scheduler, ema, knowledge-tracing, firestore, admin-sdk, non-pii, letter-agnostic, child-model]

# Dependency graph
requires:
  - phase: 18
    plan: 01
    provides: "the RED test_compile_profiles.py contract (multi-letter compile + second-letter zero-schema-change + PII/token guard) this plan turns green"
  - phase: 18
    plan: 03
    provides: "server/app/criterion_ema.py — the SAME update_ema + provisional ALPHA/HI/LO/MIN as the on-device criterion_ema.dart mirror (D-15 parity)"
  - phase: 18
    plan: 05
    provides: "children/{uid}/evidence rows ({letter, criterion, passed, source[, count]}) written by evidence.py + the child_models/{uid} owner-read Firestore rule"
  - phase: 14
    provides: "auth.py's ADC-initialized firebase_admin default app + the server Dockerfile image the Job reuses (zero new package)"
provides:
  - "server/app/jobs/compile_profiles.py — the nightly across-session compiler: compile_child(evidence_rows) folds per letter/criterion evidence through the SAME update_ema as the on-device mirror, classifies via HI/LO + the >= MIN sparse-data gate, returns the derived-only {strengths, struggles, perCriterion, schemaVersion} profile (D-15 / Req 8)"
  - "Letter-agnostic by construction: keys on f\"{letter}/{criterion}\" with ZERO per-letter branch — a newly signed letter compiles with no schema/code change (second-letter alif fixture green)"
  - "main() Cloud Run Job entrypoint: iterates children, per-child isolated compile, writes child_models/{uid} {..., updatedAt: SERVER_TIMESTAMP} via the REUSED Admin SDK default app (no re-init)"
  - "python -m app.jobs.compile_profiles module entrypoint (works under [tool.uv] package = false) + the copy-paste gcloud runbook (Job create + Scheduler cron + roles/datastore.user SA) for the 18-11 deploy gate"
affects: [18-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cloud Run Job = a separate command on the SAME server image (python -m app.jobs.<name>) — no new deploy surface, no /coach service change"
    - "Nightly compile reuses the on-device EMA mirror verbatim (from app.criterion_ema import update_ema, ALPHA/HI/LO/MIN) — the two timescales agree by construction"
    - "Module-pattern entrypoint documented in pyproject.toml because package = false blocks [project.scripts] console-script install (audit finding)"

key-files:
  created:
    - server/app/jobs/__init__.py
    - server/app/jobs/compile_profiles.py
  modified:
    - server/pyproject.toml

key-decisions:
  - "compile_child folds offline-digest rows by their aggregated count (evidence.py source=digest rows carry {count}) so offline-accrued attempts feed BOTH the EMA and the min-count gate at true volume — a live letter/word row stays a single attempt"
  - "main() skips a child with zero evidence rows (a prior child_models profile is never clobbered with empties, e.g. after a raw-evidence TTL prune) and isolates per-child failures (log + skip, never abort the nightly batch)"
  - "firebase init is auth.py's _ensure_firebase_initialized, imported LAZILY inside main() — a bare module import / compile_child unit test stays Firebase-free; compile_profiles.py never calls firebase_admin.initialize_app itself"
  - "argparse --help parses BEFORE any Firestore access, so the Task-2 verify (--help) is safe with no ADC and the Job command is inspectable"
  - "Optional TTL-prune / raw-evidence deletion NOT implemented — evidence.py already stamps a 90-day ttlAt for a Firestore TTL policy; deletion inside the compiler would be premature (plan marked it Optional)"
  - "Requirements SPEC-18-R2 / SPEC-18-R8 NOT checkbox-marked (phase precedent 18-01/03/05: requirements-completed stays [] at every leg) — the compiler CODE is complete + green, but the Job/Scheduler/SA creation is the 18-11 human deploy gate, and R2 end-to-end needs that deploy so the next session actually reads a compiled profile; the phase verifier flips them"

patterns-established:
  - "Batch jobs live in app/jobs/ as python -m entrypoints on the deployed image — one deployment story, scale-to-zero, zero new package"
  - "Deploy runbooks for human gates live in the module docstring (## Nightly Job section) so the 18-11 gate is copy-paste, never re-derived"

requirements-completed: []

# Metrics
duration: ~5min
completed: 2026-07-11
---

# Phase 18 Plan 09: Nightly EMA Compiler (Cloud Run Job) Summary

**The across-session half of the two-timescale child model: a letter-agnostic nightly Python job (`python -m app.jobs.compile_profiles`) that folds `children/{uid}/evidence` through the SAME `update_ema` as the on-device mirror and writes a derived-only, non-PII `child_models/{uid}` profile — deploy-ready as a Cloud Run Job with a copy-paste gcloud runbook for the 18-11 gate.**

## Performance

- **Duration:** ~5 min (execution; close-out resumed after a provider spend-limit interruption)
- **Started:** 2026-07-11T11:55:03Z
- **Completed:** 2026-07-11T12:00:04Z (task commits; SUMMARY after quota resume)
- **Tasks:** 2
- **Files modified:** 3 (2 created, 1 modified)

## Accomplishments

- **compile_child (D-15 / Req 8):** aggregates evidence rows per `f"{letter}/{criterion}"` key via the imported `update_ema` + `ALPHA` (the 18-03 mirror — the nightly compile and the on-device within-session estimate agree by construction, T-18-09-02), counts attempts per key, and classifies `strengths`/`struggles` with the `HI`/`LO` band gated on `>= MIN` attempts (Pitfall 4 / T-18-09-04: sparse keys stay unknown, never a false struggle). Returns EXACTLY `{strengths, struggles, perCriterion, schemaVersion}` — derived-only, fixed-vocabulary, no PII (T-18-09-01).
- **Letter-agnostic by construction (Req 8 acceptance):** zero per-letter branch anywhere (`grep 'if .*letter =='` empty); the second-letter alif fixture flows the SAME code path and adds `alif/dot` with an identical top-level shape. A newly signed letter needs no schema/code change.
- **Cloud Run Job entrypoint:** `main()` reuses `auth.py`'s ADC-initialized `firebase_admin` default app (lazy import of `_ensure_firebase_initialized`, never a re-init), iterates the `children` collection sequentially (Open Q3 — parallel sharding is a later scale lever), compiles each child in isolation (log + skip on failure), and writes `child_models/{uid}` with `updatedAt: SERVER_TIMESTAMP`. `if __name__ == "__main__": main()` makes it the Job command.
- **Deploy-ready packaging + runbook (18-11 prep):** `python -m app.jobs.compile_profiles --help` runs clean with no ADC; the module docstring's `## Nightly Job` section records the exact copy-paste gcloud commands — `gcloud run jobs create` reusing the existing image with the command override, the `0 3 * * *` Cloud Scheduler cron, and the least-privilege `roles/datastore.user` runtime-SA requirement (T-18-09-03). `pyproject.toml` documents WHY the module pattern (not `[project.scripts]`) is the only workable entrypoint under `package = false`. No deploy happened here; no change to `app/main.py` or the deployed `/coach` path.
- **Wave-0 RED fully resolved server-side:** `test_compile_profiles.py` GREEN zero-edit (4/4); the full `uv run pytest -m code` now collects with ZERO deselects — **142 passed, 1 skipped** (18-01's last missing-module collection error is gone).

## Task Commits

Each task was committed atomically:

1. **Task 1: compile_profiles.py — nightly EMA compile (letter-agnostic)** — `26295aa` (feat)
2. **Task 2: Job entrypoint packaging + runbook (Cloud Run Job prep)** — `e8c4bce` (chore)

_Task 1 is `tdd="true"`: the RED phase was authored in 18-01 (`c47a7a7`); this plan is the GREEN leg (one feat commit turning test_compile_profiles.py green, zero test edits)._

## Files Created/Modified

- `server/app/jobs/__init__.py` — the batch-jobs package (Cloud Run Job entrypoints on the existing image, not FastAPI-wired)
- `server/app/jobs/compile_profiles.py` — `compile_child` (pure EMA aggregate + classify) + `main()` (Admin-SDK iterate/compile/write) + the `## Nightly Job` deploy runbook + `__main__` guard
- `server/pyproject.toml` — comment documenting the module-pattern entrypoint (no `[project.scripts]` possible under `package = false`; deps/markers untouched)

## Decisions Made

- **Digest rows fold by `count`.** `evidence.py` emits `source="digest"` rows carrying an aggregated `count`; folding the EMA update per attempt (not per row) keeps the min-count gate honest and the EMA recency-weighting consistent with the live rows. A row without `count` defaults to 1.
- **Empty-evidence children are skipped, not zeroed.** After a raw-evidence TTL prune, a child with no rows this cycle keeps their prior profile — clobbering it with `{strengths: [], struggles: []}` would erase real history.
- **Firebase init stays in `auth.py`.** The compiler imports `_ensure_firebase_initialized` lazily inside `main()`; `compile_child` and a bare module import are Firebase-free, which is exactly what the model-free `-m code` test leg needs.
- **TTL-prune left to the Firestore TTL policy** (plan marked it Optional) — evidence docs already carry `ttlAt` (+90d) from `evidence.py`; the runbook's deploy gate is the right place to enable the policy, not compiler-side deletes.
- **SPEC-18-R2 / SPEC-18-R8 NOT checkbox-marked.** The compiler code + tests are complete, but the Job/Scheduler/SA creation is the 18-11 human deploy gate, and R2 (a returning child's first pick reflects the past) is only end-to-end once the deployed Job actually writes profiles the 18-06 mirror reads. Phase precedent (18-01/03/05 all shipped `requirements-completed: []` at leg plans); the phase verifier flips them.

## Deviations from Plan

None — plan executed exactly as written. Both tasks implemented the specified files; every per-task `<automated>` verify passed. No Rule 1–4 deviations were required.

## Issues Encountered

- **Provider spend-limit interruption during close-out:** both task commits had already landed and the working tree was clean; the orchestrator verified state and execution resumed at the self-check → SUMMARY step. No work was lost, no task was redone.

## Known Stubs

None — `compile_child` and `main()` are fully implemented and the test contract is green. Two tracked gates (not stubs): (1) the Cloud Run Job + Cloud Scheduler + SA-binding creation is the **18-11 human deploy gate** (runbook is copy-paste-ready in the module docstring); (2) the EMA `ALPHA/HI/LO/MIN` constants remain PROVISIONAL `signed:false` (mother-signed at 18-11, D-15/A4) — inherited from 18-03, unchanged here.

## Threat Flags

None — no security-relevant surface beyond the plan's `<threat_model>`. The profile doc is derived-only fixed-vocabulary and the PII/token guard test passes (T-18-09-01); the EMA reuses the mirror (T-18-09-02); the runbook pins the Job SA to `roles/datastore.user` only (T-18-09-03); the min-count gate holds (T-18-09-04); zero new package (T-18-09-SC).

## Next Phase Readiness

- **18-11 (HUMAN-UAT / deploy gate):** the Job is deploy-ready — the exact `gcloud run jobs create` (command override `python -m app.jobs.compile_profiles`), Scheduler cron (`0 3 * * *`), and `roles/datastore.user` SA-binding commands are in the module docstring, copy-paste. Also at 18-11: mother signs the EMA constants + micro-drill copy + selection gold set.
- **Server Wave-0 RED contract fully closed:** all Python RED modules from 18-01 now collect and pass (`-m code` 142 passed / 1 skipped, zero deselects).
- No blockers. No new packages.

## Self-Check: PASSED

- All 3 files present on disk (verified): `server/app/jobs/__init__.py`, `server/app/jobs/compile_profiles.py` (created), `server/pyproject.toml` (modified).
- Both task commits present in git history: `26295aa`, `e8c4bce`.
- Task 1 verify: `tests/test_compile_profiles.py -m code` 4/4 GREEN zero-edit; acceptance greps all pass (uses `update_ema`, no `if letter ==` branch, no `initialize_app` call, `__main__` guard present).
- Task 2 verify: `--help` prints usage without ADC; `import app.jobs.compile_profiles` → IMPORT-OK; runbook greps (Cloud Run Job ×4, Scheduler ×2, roles/datastore.user ×2); diff scope = pyproject.toml only (no main.py / /coach change).
- Regression: full `uv run pytest -m code` = **142 passed, 1 skipped**, zero deselects.

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-11*
