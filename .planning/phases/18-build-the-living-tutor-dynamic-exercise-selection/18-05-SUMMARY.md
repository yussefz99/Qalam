---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 05
subsystem: server
tags: [wire-contract, extra-forbid, evidence, admin-sdk, firestore-rules, background-task, non-pii, 422-lockstep, cross-letter]

# Dependency graph
requires:
  - phase: 18
    plan: 01
    provides: "the RED test_schema_forbid.py (accept fixed-vocab profile/digest, reject nested coordinate keys) + test_evidence.py (word→coarse per-letter source=word, isolated→5 geometric source=letter, one-batch off-network append) this plan turns green"
  - phase: 18
    plan: 02
    provides: "the cross-letter DATA model (letters/criteria labels; باب→[baa,alif]) + the criterion vocabulary the evidence rows key on"
  - phase: 18
    plan: 03
    provides: "the Drift v6 LetterCriterionEvidence / ChildProfileMirror tables the 18-06 client mirror will persist against (this plan is the server counterpart)"
  - phase: 06.1
    provides: "firestore.rules deny-by-default posture + the firebase_admin ADC default app (auth.py) this plan reuses for the Admin-SDK write"
  - phase: 17
    provides: "TutorFactsIn additive/extra=forbid wire discipline (criteria/word fields precedent) + verify_caller returning the trusted uid claim"
provides:
  - "The FINAL wire contract server-half: TutorFactsIn.profile (ChildProfileIn) + evidenceDigest (list[EvidenceDigestRowIn]) — additive, defaulted, nested extra=forbid, fixed-vocabulary (D-14/D-16); server ships FIRST (422 lockstep)"
  - "server/app/evidence.py — evidence_rows_from_facts (letter-agnostic: isolated→5 geometric source=letter, word→coarse present/correct per touched letter source=word via an Arabic-char→curriculum-id DATA map, offline evidenceDigest→source=digest count rows) + append_evidence (one Admin-SDK batch to children/{uid}/evidence/{autoId} via the reused default app)"
  - "/coach appends evidence OFF the critical path (BackgroundTasks), keyed by the trusted verify_caller uid, wrapped so a Firestore failure can never break /coach"
  - "firestore.rules owner-read child_models/{uid} (request.auth.uid == uid) before the deny-all catch-all; writes stay Admin-only; evidence subcollection has NO client match (Admin-only)"
affects: [18-06, 18-09, 18-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Server-first additive wire field (default=None / default_factory=list, nested extra=forbid) — the 422 lockstep (15-02/17-05 discipline), the Dart mirror follows in 18-06"
    - "Alias for a Python-keyword wire key (EvidenceDigestRowIn.pass_ with alias='pass'); extra=forbid still rejects a stray nested coordinate key"
    - "Persistent write OFF the response critical path via FastAPI BackgroundTasks — the child never waits on Firestore; wrapped so a write failure is display-only degradation"
    - "Letter-agnostic derivation: branch on criteria-vs-writtenWord presence, decode words via an Arabic-char→curriculum-id DATA map — a second signed letter needs zero code branch"

key-files:
  created:
    - server/app/evidence.py
  modified:
    - server/app/schema.py
    - server/app/main.py
    - firestore.rules

key-decisions:
  - "profile + evidenceDigest are ADDITIVE/defaulted on TutorFactsIn (default=None / default_factory=list), nested extra=forbid — an OLD client that omits them still validates (no 422 window); the server ships FIRST, the Dart mirror follows in 18-06 byte-for-byte (Pitfall 2)"
  - "EvidenceDigestRowIn.pass_ carries alias='pass' because `pass` is a Python keyword; model_dump() emits the field name pass_, so evidence_rows_from_facts reads row.get('pass', row.get('pass_', 0)) to handle both the wire dict and a model dump"
  - "evidence_rows_from_facts branches on PRESENCE of criteria (isolated → 5 geometric, source=letter) vs writtenWord/expectedWord (word → coarse present/correct per touched letter, source=word) — never on a specific letter id; words decode to curriculum ids via a 28-letter Arabic-char DATA map (باب→[baa,alif]) so it's letter-agnostic (Pitfall 3 — never fabricate the 5 geometric criteria for a word)"
  - "Per-criterion passed derives from the soft zone (passed = zone != 'certainlyWrong') mirroring the scorer semantics; word present = the letter appeared in the transcription, correct = the whole written word matched expected"
  - "append_evidence reuses auth.py's already-initialized firebase_admin default app (firestore.client(), zero new package, never re-inits); auto-id docs = append-only (no hot doc); one batch = one round-trip; adds ts + a 90-day ttlAt for optional Firestore TTL-prune"
  - "/coach uses FastAPI BackgroundTasks so the write runs AFTER CoachOut is sent; the uid is the verify_caller ID-token claim, NEVER facts_in (T-18-05-01); _safe_append_evidence swallows every error (T-18-05-05) and no-ops on empty rows (a label-only attempt writes nothing)"
  - "firestore.rules adds match /child_models/{uid} { allow read: if request.auth != null && request.auth.uid == uid; allow write: if false; } BEFORE the deny-all catch-all; the children/{uid}/evidence/** subcollection deliberately has NO client match (Admin-only via the catch-all)"

patterns-established:
  - "Server-first 422-lockstep additive wire field with a nested extra=forbid model (the child model / digest cannot smuggle geometry or PII)"
  - "Trusted-uid keyed, off-critical-path Admin-SDK write (BackgroundTask) — the persistent child-data path with zero new client-write surface"

requirements-completed: []

# Metrics
duration: ~15min
completed: 2026-07-11
---

# Phase 18 Plan 05: Server-First Profile/Evidence Wire + Admin-SDK Evidence Capture Summary

**The server now carries the FINAL wire contract (TutorFactsIn.profile + evidenceDigest, additive/defaulted/extra=forbid) and writes derived per-letter×criterion evidence server-side only — off the /coach critical path (a BackgroundTask), keyed by the trusted ID-token uid — with the profile doc owner-readable and Admin-write-only, so the persistent child-data path exists with zero new client-write surface.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-07-11
- **Tasks:** 3
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- **Wire contract server-half (Task 1, D-14/D-16):** `TutorFactsIn` gains `profile: ChildProfileIn | None` (default None) and `evidenceDigest: list[EvidenceDigestRowIn]` (default []) — both additive/defaulted, both nested `extra="forbid"`, fixed-vocabulary. An old client that omits them still validates (no 422 window); a nested coordinate key (`points`/`x`) inside the profile or a digest row 422s (GROUND-04). `EvidenceDigestRowIn.pass_` uses `alias="pass"` (Python keyword). `test_schema_forbid.py` accept + both reject legs GREEN with zero test edits.
- **Evidence deriver + Admin-SDK append (Task 2, D-13/R7):** `server/app/evidence.py` derives per-letter×criterion rows letter-agnostically — an isolated-letter attempt → 5 geometric criteria (`source="letter"`, passed from the soft zone); a word attempt → a coarse present/correct signal for EVERY letter it touches (باب → baa AND alif, `source="word"`, via a 28-letter Arabic-char→curriculum-id DATA map, Pitfall 3); an offline `evidenceDigest` → aggregated `source="digest"` count rows. `append_evidence` batch-writes to `children/{uid}/evidence/{autoId}` via the REUSED `firebase_admin` default app (`firestore.client()`, no re-init, one batch = one round-trip). `test_evidence.py` 4/4 GREEN with zero test edits.
- **Off-critical-path append + owner-read rule (Task 3, T-18-05-01/05, Pitfall 1):** `/coach` schedules `_safe_append_evidence(claims, facts_in)` via `BackgroundTasks` AFTER the `CoachOut` is sent — the practice path never blocks on Firestore. The uid comes from `verify_caller` claims, never the body; the write is fully wrapped so a Firestore failure is display-only degradation. `firestore.rules` adds an owner-read `child_models/{uid}` block (`request.auth.uid == uid`) before the deny-all catch-all with writes denied; the evidence subcollection has no client match.

## Task Commits

Each task was committed atomically:

1. **Task 1: TutorFactsIn +profile +evidenceDigest (additive, extra=forbid) — ships FIRST** — `e95040f` (feat)
2. **Task 2: evidence.py — Admin-SDK append + letter×criterion derivation (D-13, R7)** — `b6e49ee` (feat)
3. **Task 3: /coach evidence append off the critical path + owner-read rule** — `7b5f3f2` (feat)

_All three tasks are `tdd="true"`: the RED phase was authored in 18-01; this plan is the GREEN leg (feat commits turning the existing server tests green, zero test edits)._

## Files Created/Modified

- `server/app/schema.py` — `ChildProfileIn` {strengths/struggles/perCriterion/schemaVersion, extra=forbid} + `EvidenceDigestRowIn` {letter/criterion/pass_(alias)/fail, extra=forbid}; `TutorFactsIn.profile` (nullable) + `evidenceDigest` (default []), both additive with the 422-lockstep comment
- `server/app/evidence.py` (NEW) — `evidence_rows_from_facts` (letter-agnostic isolated/word/digest derivation + Arabic-char→id DATA map) + `append_evidence` (one Admin-SDK batch via the reused default app; ts + ttlAt)
- `server/app/main.py` — `BackgroundTasks` param on `/coach`, `claims` (was `_claims`) used for the trusted uid, `_safe_append_evidence` helper, `background_tasks.add_task(...)` scheduled after the response is built
- `firestore.rules` — owner-read `child_models/{uid}` block before the deny-all catch-all; writes Admin-only; evidence subcollection deliberately unmatched (Admin-only)

## Decisions Made

- **Server ships FIRST (422 lockstep).** Both new fields are additive/defaulted so a standalone server re-deploy is SAFE; the Dart mirror (18-06) copies the field NAMES + nested keys byte-for-byte. The re-deploy is gated to follow BOTH wire sides landing (Pitfall 2), exactly the 15-02/15-04 and 17-05/17-06 discipline.
- **`pass` is a Python keyword → `pass_` + `alias="pass"`.** The wire key stays `pass`; `model_dump()` emits `pass_`, so `evidence_rows_from_facts` reads `row.get("pass", row.get("pass_", 0))` to accept both the raw wire dict (tests) and a model dump (the /coach path). `extra="forbid"` still rejects a stray `x`.
- **Letter-agnostic derivation via a DATA map.** The word path decodes the expected word to curriculum ids through a 28-letter Arabic-char map (+ hamza/alef-maqsura/taa-marbuta normalization + tashkeel strip), so a second signed letter needs ZERO code branch — the branch is on `criteria` vs `writtenWord` presence, never on a letter id.
- **Off-critical-path via FastAPI `BackgroundTasks`.** Chosen over a Starlette `Response(background=...)` so the route keeps `response_model=CoachOut`. The task runs after the response is sent; `_safe_append_evidence` no-ops on empty rows (a label-only attempt writes nothing) and swallows every error so a Firestore failure never breaks /coach.
- **Requirements SPEC-18-R2 / SPEC-18-R7 NOT checkbox-marked.** This plan lands the SERVER half — the wire fields, the evidence deriver + write, and the owner-read rule. R2 (across-session memory) is not delivered end-to-end until the client mirror (18-06) reads the profile and the nightly compiler (18-09) writes it; R7 (cross-letter evidence) is server-written now but the full offline-digest loop needs the 18-06 client. Following the strong phase precedent (18-01/18-02/18-03 left `requirements-completed: []` at every foundation leg; STATE: "R3/R7 NOT checkbox-marked (DATA leg only)"), `requirements-completed: []`; the plan landing the final leg (or the phase verifier) flips them.

## Deviations from Plan

None — plan executed exactly as written. All three tasks implemented the specified files; every per-task `<automated>` verify passed. No Rule 1–4 deviations were required.

## Issues Encountered

- **A full `uv run pytest -m code` still interrupts at collection with 2 errors** — `test_compile_profiles.py` (imports the not-yet-built `app.jobs.compile_profiles`, greened by 18-09) and `test_eval/test_selection_dimension.py` (imports `SELECTION_THRESHOLD` from `run_eval`, greened by 18-08/18-11). This is the established Wave-0 RED-by-missing-module behavior (18-01 documented it; 18-03 hit it). **This plan REDUCED the count from 3 to 2** by shipping `app.evidence` (test_evidence now collects + passes). Confirmed no regression by running the suite with the two remaining RED modules deselected: **130 passed, 1 skipped** (includes the /coach endpoint suite — the background evidence task no-ops on the endpoint payloads because they carry no criteria/writtenWord, so no real Firestore write occurs during tests). The rules grep prints `RULE-OK`.

## Known Stubs

None — the wire fields, the evidence deriver, the /coach append, and the owner-read rule are all fully implemented. The `child_models` owner-read rule is DEPLOYED-PENDING: it ships in `firestore.rules` now, but a `firebase deploy --only firestore:rules` + the single Cloud Run re-deploy are gated to follow the 18-06 Dart mirror landing (the 422-lockstep deploy order) — a tracked release gate, not a stub that blocks the plan's goal.

## Threat Flags

None — no security-relevant surface beyond the plan's `<threat_model>`. The new wire fields are `extra="forbid"` fixed-vocabulary (T-18-05-04); the evidence write is Admin-SDK, uid-from-token, off the critical path (T-18-05-01/05); client Firestore writes stay deny-all and the profile doc is owner-read-only (T-18-05-02/03). No new package (T-18-05-SC — `firebase_admin.firestore` already installed + ADC-initialized in auth.py).

## Next Phase Readiness

- **18-06 (Dart mirror + child-model repository):** the server carries `profile`/`evidenceDigest` — the Dart `TutorFacts` adds them byte-for-byte (greens `across_session_memory`, re-greens `payload_nonpii`); the Drift v6 `ChildProfileMirror` (18-03) is the boot mirror to refresh from the owner-read `child_models/{uid}` doc. A single Cloud Run re-deploy follows once BOTH wire sides land.
- **18-09 (nightly compiler):** `evidence_rows_from_facts` writes the per-letter×criterion rows the compiler will aggregate via the SAME `update_ema` the client uses (18-03); it must also write the `child_models/{uid}` profile doc the owner-read rule now permits the client to read.
- **18-11 (HUMAN-UAT):** signs the micro-drill copy + the selection gold set (unrelated to this plan's server surface).
- No blockers. No new packages.

## Self-Check: PASSED

- All 4 files present on disk (verified): `server/app/evidence.py` (created), `server/app/schema.py`, `server/app/main.py`, `firestore.rules` (modified).
- All 3 task commits present in git history: `e95040f`, `b6e49ee`, `7b5f3f2`.
- Task verifies: `test_schema_forbid.py` 3/3 GREEN; `test_evidence.py` 4/4 GREEN; no /coach regression (contract + endpoint + payload suites 44/44); full `-m code` with the 2 remaining Wave-0 RED modules deselected = 130 passed / 1 skipped; `firestore.rules` grep `RULE-OK`.

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-11*
