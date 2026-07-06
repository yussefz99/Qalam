---
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
plan: 10
subsystem: coaching-contract
tags: [adr, ground-04, eval-03, d-a, phase-close, human-uat, cloud-run, verification-sweep, wave-8]

# Dependency graph
requires:
  - phase: 17-08
    provides: "the SERVER half of the D-A cutover — strokeImage->image_judge deleted, CoachOut.verdict gone, image_judge.py removed, strokeImage in FORBIDDEN_KEYS; the retirement this ADR records as durable + the contract the single re-deploy carries live"
  - phase: 17-07
    provides: "the CLIENT half of the D-A cutover — scorer owns pass/fail on every path, strokeImage render/send deleted; the other half of the GROUND-04 surface-shrink story the ADR documents"
  - phase: 17-09
    provides: "the per-form calibration harness (the mom-facing D-D tuning artifact) the HUMAN-UAT calibration item points at"
provides:
  - "ADR-017 — the 4th roadmap success criterion: the softened GROUND-02 reversal (derived diff crosses the wire, raw strokes/images never do) AND the D-A verdict-authority un-reversal recorded as one owner-attributed, evidence-cited decision record"
  - "The end-of-phase HUMAN-UAT ledger (7 gated items, each with an exact command/file + resume signal): Cloud Run re-deploy, device F1-F6 re-walk, mother's gold re-sign, per-form sign-off queue, calibration labelling, make-eval judge+baseline, consent copy"
  - "A reconciled verification baseline for the phase close: flutter 748 passed / 8 known-baseline failed (0 new), server -m code 109 passed / 1 skipped"
affects: [phase-verifier, roadmap-sc-4, ground-04, eval-03, strk-01]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Phase-closing ADR in the ADR-015 register (Status/Supersedes/Amends/Affects header + numbered Decision + Consequences/Alternatives/Revisit/Seam) — one ADR for the single load-bearing architectural story, evidence-cited (research F1-F11 + spike H1-H5) and owner-attributed"
    - "Deploy-can't-run-here => ledger PENDING item, never faked: gcloud IS authenticated but the auto-mode safety classifier blocked the production deploy; recorded as the FIRST HUMAN-UAT item with the exact command + current live revision, not worked around (honors the plan's 'do NOT fake it' branch)"
    - "human_verify_mode=end-of-phase ledger (Phase-16 precedent): every gate outside an agent session (device, ADC, owner's-mother authority, reviewed deploy) is written down with what / why-human / exact-command / resume-signal so nothing is silently dropped"

key-files:
  created:
    - docs/architecture/ADR-017-scorer-owns-verdict-derived-facts.md
    - .planning/phases/17-build-stroke-aware-coaching-on-device-geo-diff-to-coach/17-HUMAN-UAT.md
  modified: []

key-decisions:
  - "ADR-017 KEPT from the prior executor's uncommitted draft, reviewed critically against all 5 acceptance criteria and committed as-is: it names the verdict owner (the deterministic on-device scorer), carries all six greppable tokens (Supersedes/GROUND-02/strokeImage/image_judge/kinematics/signedOff), records deletion-not-demotion + the net privacy win, and marks §5 OWNER-CONFIRMED 2026-07-05. 188 lines (min 50). No fix needed — the draft was complete and correct."
  - "Cloud Run re-deploy is a PENDING HUMAN gate, NOT done autonomously: the auto-mode safety classifier denied the production `gcloud run deploy` (asked for review outside auto-mode). gcloud IS authenticated (qalam1481@gmail.com, project qalam-app-bd7d0, service access confirmed) and /health already returns 200 on the current rev qalam-tutor-00020-txt — so the demo is not broken; the re-deploy (which makes the deployed contract match the repo, closing T-17-21) is the FIRST ledger item with the exact command. NOT faked (plan's 'do NOT fake it' branch)."
  - "make eval judge + two-arm baseline legs DEFERRED to the ledger: no ADC file present this session (~/.config/gcloud/application_default_credentials.json absent) and the gold set is unsigned (0/47), which blocks the judge calibration. The model-free eval-code leg is green in-session (covered by the -m code run). Exact `gcloud auth application-default login && make eval` command recorded."
  - "STRK-01 / GROUND-04 / EVAL-03 NOT checkbox-marked (17-01..17-09 precedent + genuine pending gates): every prior plan deliberately left these for the phase verifier, and all three still have PENDING human gates before they are truly Complete — STRK-01 -> the two-arm baseline (deferred, no ADC); GROUND-04 -> the Cloud Run re-deploy (classifier-blocked -> human); EVAL-03 -> the mother's gold re-sign (0 signed) + make eval. `requirements mark-complete` skipped; `/gsd-verify-work 17` flips the boxes once the ledger gates close."
  - "The dead `applyVerdict` in exercise_controller.dart (flagged in 17-07/17-08 deferred-items 'for the 17-10 cleanup sweep') was NOT touched: this plan has no code-cleanup sweep in scope (Task 1 = ADR, Task 2 = deploy/sweep/ledger; neither is in lib/'s file scope). It stays in deferred-items for a future sweep."

patterns-established:
  - "A phase-closing plan's job is durability + honesty, not new code: record the decision (ADR), reconcile the suites to a documented baseline, and convert every un-automatable gate into a written resume path — so 'phase closes with zero silent gaps' is literally true."

requirements-completed: []

# Metrics
duration: 30min
completed: 2026-07-06
---

# Phase 17 Plan 10: ADR-017 + Verification Sweep + HUMAN-UAT Ledger (Phase Close) Summary

**The closing plan of Phase 17: ADR-017 records the single load-bearing architectural story as durable, owner-attributed, evidence-cited fact (the deterministic on-device scorer OWNS pass/fail per D-A; only a derived, point-free geometry diff crosses the wire per the softened GROUND-02; strokeImage + CoachOut.verdict + image_judge.py deleted-not-demoted; §5 OWNER-CONFIRMED kinematics-descoped amendment); the full verification sweep reconciles to the documented baseline (flutter 748/8-known, server -m code 109/1-skip, zero new failures); and the 17-HUMAN-UAT ledger converts every remaining human/device/authority/ADC gate — led by the classifier-blocked Cloud Run re-deploy — into a written resume path so the phase closes with zero silent gaps.**

## Continuation Context

This plan was resumed from a precise mid-Task-1 state: a prior executor was killed by an API error after writing (but never committing) the ADR-017 draft and extracting the failing-test baseline. On resume: NO 17-10 commits existed (HEAD `a198c04`), the ADR-017 draft was untracked, and 17-HUMAN-UAT.md did not exist. Both tasks were completed cleanly from there.

## Performance

- **Duration:** ~30 min (continuation)
- **Completed:** 2026-07-06
- **Tasks:** 2 (both `type="auto"`)
- **Files created:** 2 (ADR-017 + 17-HUMAN-UAT.md); **modified:** 0

## Accomplishments

- **ADR-017 committed — roadmap success criterion 4 satisfied.** The prior executor's uncommitted draft was reviewed critically against all five acceptance criteria and kept as-is (it was complete and correct — no fix needed). It names the verdict owner (the deterministic on-device scorer), carries all six required greppable tokens (`Supersedes` / `GROUND-02` ×4 / `strokeImage` ×7 / `image_judge` ×6 / `kinematics` ×7 / `signedOff`), records the deletion-not-demotion rationale for `image_judge.py` (worst spike arm at 0.20 hallucination; an advisory image call would re-open the consent reversal) and the net privacy win, and marks §5 `OWNER-CONFIRMED` 2026-07-05 (kinematics descoped, position folded, five criteria, demo scores unsigned baa forms per A2). Header follows the ADR-015 pattern; 188 lines (min 50). Cites research F1-F11 + spike H1-H5.
- **Verification sweep reconciled to the documented baseline — zero new failures.** Full `flutter test` → **748 passed / 8 known-baseline failed**, the exact 17-08 baseline. The 8 failures across 7 files: `alif_reference_test` (×2), `all_letters_validation_test`, `reference_overlay_golden_test` (font-drift), `curriculum_repository_v2_test`, `meet_section_test` (door-image Test 1), `mastery_celebration_golden_test` (font-drift), `glyph_audit_golden_test` (font-drift) — all pre-existing, none touch this phase's changed code, font-drift goldens never re-baked (per MEMORY). Server `cd server && uv run pytest -m code -q` → **109 passed / 1 skipped** (unchanged since 17-08). No new failure = no phase defect.
- **The 17-HUMAN-UAT ledger closes the phase with zero silent gaps.** Seven gated items, each with what / why-human / exact-command-or-file / resume-signal: (1) Cloud Run re-deploy [PENDING — see below]; (2) device F1-F6 re-walk with expected outcomes (F1 LTR fixed, F2 impossible-by-construction, F3 English-primary, F4/F6 specific coaching, F5 form-trap fails); (3) mother's gold-set re-sign; (4) per-form sign-off queue (baa i/m/f + alif); (5) calibration labelling (D-D production gate); (6) make-eval judge + two-arm baseline (deferred — no ADC); (7) consent copy for the derived-diff flow. `grep -c '"signed": true' gold_set.jsonl` == **0** at close (no autonomous sign-off).
- **The Cloud Run re-deploy is recorded as a human gate, not faked.** gcloud IS authenticated in this environment (qalam1481@gmail.com, project qalam-app-bd7d0, `describe` confirmed service access, current rev `qalam-tutor-00020-txt`), and the live `/health` already returns 200 — but the auto-mode safety classifier DENIED the production `gcloud run deploy` and asked that it run outside auto-mode for review. Per the plan's explicit "if the deploy can't run here, do NOT fake it — record the exact command as the FIRST PENDING ledger item and continue" branch, it is item 1 with the full documented command + verification. The demo is not broken (rev 00020 serves 200); the re-deploy only makes the deployed contract match the repo (closes T-17-21).

## Task Commits

Each task committed atomically:

1. **Task 1: ADR-017 — scorer owns the verdict; only derived facts cross the wire** — `e71423d` (docs)
2. **Task 2: re-deploy sweep + 17-HUMAN-UAT end-of-phase ledger** — `cc2250a` (docs)

## Files Created/Modified

- `docs/architecture/ADR-017-scorer-owns-verdict-derived-facts.md` — **NEW** (kept from the prior executor's reviewed draft): the GROUND-04 ADR — verdict authority (D-A) + derived-diff data flow (softened GROUND-02) + image-path retirement + owner-confirmed §5 D-C amendment.
- `.planning/phases/17-build-stroke-aware-coaching-on-device-geo-diff-to-coach/17-HUMAN-UAT.md` — **NEW**: the end-of-phase human-gate ledger (7 items, Phase-16 format).

## Decisions Made

See frontmatter key-decisions. The load-bearing ones: the ADR draft was kept as-is (complete + correct against all acceptance criteria); the Cloud Run re-deploy is a PENDING human gate (classifier-blocked, NOT faked); make-eval judge/baseline deferred (no ADC + unsigned gold); STRK-01/GROUND-04/EVAL-03 NOT checkbox-marked (phase precedent + genuine pending gates → the phase verifier flips them); the dead `applyVerdict` left untouched (no cleanup sweep in this plan's scope).

## Deviations from Plan

### Deliberate Interpretation

**1. [Judgment call] Cloud Run re-deploy recorded as a PENDING ledger item (classifier-blocked), not executed**
- **Found during:** Task 2 step 1 (deploy)
- **Issue:** The plan's deploy fork is worded around gcloud authentication ("if gcloud is unauthenticated … record as PENDING and continue"). Here gcloud IS authenticated, but the auto-mode safety classifier denied the production `gcloud run deploy` and asked for human review outside auto-mode.
- **Resolution:** Treated the classifier denial as the same "can't deploy autonomously here" case the plan designed for — recorded the exact command as the FIRST PENDING HUMAN-UAT item with the current live revision + verification, and continued. Did NOT retry, substitute, or work around the denial. The live `/health` still returns 200, so the demo is unaffected.
- **Files:** 17-HUMAN-UAT.md (item 1)

**2. [Judgment call] make eval judge + two-arm baseline deferred to the ledger (no ADC, unsigned gold)**
- **Issue:** The plan runs `make eval` "when Vertex ADC is available"; ADC is absent (`~/.config/gcloud/application_default_credentials.json` not present) and the gold set is unsigned (0/47), which also gates the judge calibration.
- **Resolution:** Recorded the judge + baseline legs as HUMAN-UAT item 6 with the exact `gcloud auth application-default login && make eval` command + the two-arm baseline acceptance (arm A beats arm B, 0 grounding violations). The model-free `eval-code` leg is green in-session via the `-m code` run.
- **Files:** 17-HUMAN-UAT.md (item 6)

**3. [Judgment call] STRK-01 / GROUND-04 / EVAL-03 not checkbox-marked (17-01..17-09 precedent + pending gates)**
- **Issue:** The plan's `requirements: [GROUND-04, EVAL-03]` frontmatter would drive a `requirements mark-complete`, but every prior plan in the phase deliberately left these for the phase verifier, and all three still have PENDING human gates before they are truly Complete (deploy / two-arm baseline / mother's gold re-sign).
- **Resolution:** `requirements mark-complete` skipped; `requirements-completed: []`. `/gsd-verify-work 17` flips the boxes once the ledger gates close — flipping "Complete" while the deploy is un-deployed and the gold unsigned would falsely show a requirement done.
- **Files:** none (REQUIREMENTS.md untouched)

---

**Total deviations:** 0 auto-fixed + 3 judgment calls. No architectural changes, no scope creep, no code touched (both tasks are pure docs). Zero new packages (T-17-SC green — pubspec.yaml / pyproject.toml dependency sections unchanged).

## Issues Encountered

- **Prior-executor draft recovery:** the ADR-017 draft was untracked (written, never committed) when the prior executor was killed. Reviewed critically — it met all five acceptance criteria and every greppable token, so it was committed as-is rather than rewritten.
- **8 known full-suite failures** (documented above) — unchanged baseline, no regression. Font-drift goldens never re-baked (MEMORY).

## Known Stubs

None — both artifacts are complete durable documents. The HUMAN-UAT ledger's PENDING items are explicit, resume-signalled human gates (not code stubs), and the ADR's consent-copy TODO is an owner/legal pre-production item, not a shipped placeholder.

## Threat Flags

None new. The plan's threat register is satisfied:
- **T-17-21 (Tampering — deploy-order 422 window):** MITIGATED-by-design + recorded — both wire sides are consistent in-repo (client 17-07 + server 17-08); the single re-deploy is safe (only live client is the same-phase demo build). The re-deploy is a PENDING ledger item (classifier-blocked here); until then the live rev 00020 still serves 200, and the removal-ordering (client-first) means no 422 window opens.
- **T-17-22 (Repudiation — unsigned pedagogy shipping):** MITIGATED — `grep -c '"signed": true' server/tests/test_eval/gold_set.jsonl` == 0 at close; sign-off flips only via the ledger (15-07 precedent).
- **T-17-23 (Information Disclosure — consent debt):** MITIGATED — ADR-017 §3/§5 records the residual derived-diff flow + the consent-copy TODO as an explicit pre-production ledger item (HUMAN-UAT item 7).
- **T-17-SC (Tampering — package installs):** green — zero new packages this phase-close.

## Next Phase Readiness

- **Phase 17 is autonomous-complete.** All code + docs are committed and green; ADR-017 records the decision; the verification sweep reconciles to the documented baseline. The remaining work is the 7-item HUMAN-UAT ledger (deploy, device F1-F6, gold re-sign, per-form sign-off, calibration labelling, make-eval baseline, consent copy).
- **`/gsd-verify-work 17` is the final leg:** it confirms the ledger gates and flips STRK-01 / GROUND-04 / EVAL-03 once the deploy lands + the mother signs + the two-arm baseline runs. Until then those three requirements stay Pending by design.
- **Owner next action:** run the 17-HUMAN-UAT ledger (start with item 1 — the reviewed Cloud Run re-deploy in an interactive session), then `/gsd-verify-work 17`.

## Self-Check: PASSED

- Both created files exist on disk (`docs/architecture/ADR-017-scorer-owns-verdict-derived-facts.md`, `.../17-HUMAN-UAT.md`); this SUMMARY exists.
- Commits `e71423d` (Task 1 docs) + `cc2250a` (Task 2 docs) present in git log.
- Acceptance re-verified: ADR-017 has all six greppable tokens + `OWNER-CONFIRMED` (§5) + 188 lines; 17-HUMAN-UAT.md has 7 items, each with a resume_signal + exact command/file, and the deploy as the first PENDING item; `grep -c '"signed": true' server/tests/test_eval/gold_set.jsonl` == 0; full `flutter test` → 748 passed / 8 known-baseline failed (0 new); server `uv run pytest -m code -q` → 109 passed / 1 skipped.

---
*Phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach*
*Completed: 2026-07-06*
