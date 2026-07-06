---
status: partial
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
source: [17-10-PLAN.md, 17-VALIDATION.md (Manual-Only), docs/testing/UAT-FULL-2026-07-01.md, ADR-017]
human_verify_mode: end-of-phase
started: "2026-07-06T18:00:00Z"
updated: "2026-07-06T18:00:00Z"
---

## Current Test

[awaiting human / device / owner's-mother availability]

Phase 17 executed all autonomous code (17-01…17-09 fully; 17-10 Task 1 = ADR-017,
Task 2 = the verification sweep + this ledger). The remaining work is gated on things
outside an agent session — the tablet/iPad, a reviewed Cloud Run deploy, live Vertex
ADC, and the owner's-mother's pedagogy authority. These items are **deferred to
HUMAN-UAT** per `human_verify_mode: end-of-phase` (Phase-16 precedent). The code seams
they depend on are all committed and green (748 flutter passed / 8 known-baseline
failed; server `-m code` 109 passed / 1 skipped).

**The scorer now owns pass/fail on-device (D-A); the sign-off / calibration / consent
gates below are the mother's + owner's authority and flip ONLY on their word (15-07
precedent).**

## Tests

### 1. Cloud Run re-deploy of the Phase-17 contract  *(PENDING — deploy blocked in this session)*
expected: The live `qalam-tutor` service is running revision **`qalam-tutor-00020-txt`**
  (the pre-Phase-17 contract — still has the retired image path). Both wire sides are now
  consistent in-repo (client 17-07 + server 17-08: criteria accepted, `strokeImage`/
  `image_judge.py`/`CoachOut.verdict` deleted), so a single deploy is safe. Re-deploy from
  `server/` with the documented command:
  ```bash
  cd server && gcloud run deploy qalam-tutor \
    --source . \
    --project=qalam-app-bd7d0 \
    --region=us-central1 \
    --allow-unauthenticated \
    --min-instances=0 \
    --timeout=30 \
    --set-env-vars=GCP_PROJECT_ID=qalam-app-bd7d0,GOOGLE_CLOUD_LOCATION=us-central1,COACH_TIMEOUT_SECONDS=12
  ```
  Verify: `curl -s -o /dev/null -w "%{http_code}" https://qalam-tutor-ogtudswkjq-uc.a.run.app/health` → **200**
  (NOT `/healthz` — Google edge reserves that path); `curl -i -XPOST .../coach -d '{}'` → **401**.
  For a smooth demo, warm the service first (a `GET /health` ping masks cold start; the owner's
  option is `--min-instances=1` for the demo window, then back to 0).
why_human: `gcloud` is authenticated in this environment (`qalam1481@gmail.com`, project
  `qalam-app-bd7d0`, service access confirmed via `describe`), but the automated safety
  classifier **denied the production `gcloud run deploy`** in this autonomous session and asked
  that it run outside auto-mode for human review. It was NOT faked or worked around. The live
  `/health` already returns 200 on rev 00020 — the demo is not broken; this re-deploy only makes
  the deployed contract match the repo (closes T-17-21; no 422 window since the only live client
  is the same-phase demo build, cut over first).
resume_signal: "deployed: rev <NNNNN>, /health 200" (with the new revision name)

### 2. Device re-walk of UAT F1–F6 on the tablet/iPad  *(new build)*
expected: Build the demo on the tablet/iPad (`--dart-define=DEMO=true
  --dart-define=TUTOR_BASE_URL=https://qalam-tutor-ogtudswkjq-uc.a.run.app`) and re-walk the
  `docs/testing/UAT-FULL-2026-07-01.md` punch-list:
  - **F1** — English helper copy ("On its own…", "Nothing to write…") reads **left-to-right**
    (trailing period no longer jumps left); fixed 17-08, pinned by `meet_section_ltr_test.dart`.
  - **F2** — the cold-start flash-then-overwrite is **impossible by construction**: the verdict +
    star render instantly on-device (D-A, 17-07); a cold/slow/offline server affects only the
    coaching words, never pass/fail.
  - **F3** — coaching is **English-primary** with only light Arabic (أحسنت), not full Arabic.
  - **F4 / F6** — wrong-answer + word-path feedback is **specific and warm** (the mother's voice),
    not generic "trash"/binary.
  - **F5** — an **isolated bowl offered for the medial/final slot FAILS** at the scorer
    (form-aware shape check, `certainlyWrong`) — no longer accepted.
why_human: device rendering, latency, cold-start, and stylus capture are not reproducible in the
  headless `flutter test` VM.
resume_signal: "device UAT: F1–F6 <pass/fail per item>" (with any regressions noted)

### 3. Owner's-mother gold-set re-sign  *(EVAL-03, D-09)*
expected: Present the regrown stroke-level `server/tests/test_eval/gold_set.jsonl` (47 lines,
  each `"signed": false` today) to the owner's mother. She edits any line whose register/Arabic
  is off, or approves as-is. Flip reviewed cases to `"signed": true` per case; update/append
  `server/tests/test_eval/GOLD-SIGNOFF.md` (signer, date, scope, D-10 no-training-without-consent).
  Nothing register-shaping ships unsigned. NOTE: this supersedes the Phase-16 pending gold sign-off
  scope — coordinate with the 16-05 gate (do not double-count).
why_human: pedagogy/register authority is the owner's mother's, never autonomous (15-07 precedent).
  Acceptance at plan close: `grep -c '"signed": true' server/tests/test_eval/gold_set.jsonl` == **0**.
resume_signal: "gold signed: N cases" (with the count)

### 4. Owner's-mother per-form sign-off queue  *(A2 / ADR-017 §5)*
expected: Review the per-form references and flip form-level `signedOff: true` per form ONLY on
  her word: **baa initial / medial / final** (plus the **alif** forms). File:
  `assets/curriculum/letters.json` (`contextualForms.{initial,medial,final}.signedOff`). The demo
  currently scores these **unsigned** (`signedOff:false`) — OWNER-CONFIRMED default A2 (2026-07-05,
  ADR-017 §5); her per-form sign-off is the recorded **PRODUCTION** gate.
why_human: form-level pedagogy sign-off is the mother's authority; the demo-scores-unsigned default
  is explicitly a demo-only allowance, not a production green light.
resume_signal: "forms signed: baa <i/m/f>, alif <…>" (per-form)

### 5. Threshold calibration on real child samples  *(D-D production gate)*
expected: Capture real child baa/taa samples on-device, the mother labels each good/bad, then
  re-run the Dart per-form calibration harness against HER labels and adopt the fitted per-form
  `tcc`/`tcw` as `assets/curriculum/letters.json` tolerance overrides:
  ```bash
  flutter test test/core/scoring/calibration_harness_test.dart   # prints the per letter×form
                                                                  # confusion table + PROVISIONAL fit report
  ```
  The shipped band (tcc 0.10 / tcw 0.15) is a **provisional synthetic floor** for the demo only
  (fixed adult-tuned thresholds false-fail developing children ~15%, F8/F11). The harness PRINTS
  ONLY — it never mutates production values; the mother's fit does.
why_human: real child handwriting cannot be synthesized; the label ground-truth is the mother's.
resume_signal: "calibration: <letter×form> tcc/tcw adopted" (with the fitted values)

### 6. `make eval` judge legs + STRK-01 two-arm baseline  *(EVAL-03 / STRK-01 — deferred: no ADC)*
expected: The model-free leg (`eval-code`) is **green in-session** (covered by
  `uv run pytest -m code -q` → 109 passed / 1 skipped). The **judge + baseline** legs reach live
  Vertex (keyless ADC) and are deferred — no `~/.config/gcloud/application_default_credentials.json`
  present this session, and the gold set is unsigned (blocks the judge calibration, item 3). Run
  once ADC + signed gold are ready:
  ```bash
  gcloud auth application-default login          # set up keyless ADC for Vertex
  cd server && make eval                         # eval-code → eval-judge → eval-baseline (short-circuits on failure)
  ```
  Record the semantic-faithfulness gate result AND the **two-arm baseline table**: stroke-aware
  (arm A) must beat label-only (arm B) on specificity + variety with **0 grounding violations in
  both** (`run_baseline.py` exits non-zero otherwise).
why_human: the judge/baseline legs make live Vertex calls (ADC, cost) and the judge calibration is
  gated on the signed gold (item 3) — neither is available autonomously here.
resume_signal: "eval: judge <pass/tune>, baseline arm A>B <yes/no>, grounding 0/0"

### 7. Consent copy for the derived-diff data flow  *(owner/legal, pre-production)*
expected: The off-device child-data surface has shrunk to a **derived, point-free geometry diff +
  per-criterion result + word facts** (no image, no raw strokes, no PII — ADR-017 §2/§3). Before
  production, add onboarding/consent copy stating that handwriting-**derived** facts are processed
  by an AI coaching service. This is the residual GROUND-01/02 consent debt from 17.1, now much
  smaller (a rendered image no longer leaves the device).
why_human: consent/legal copy is an owner + legal decision, out of this phase's engineering scope.
resume_signal: "consent copy: drafted / approved" (with a pointer to the copy)

## Summary

total: 7
passed: 0
issues: 0
pending: 7
skipped: 0
blocked: 0

## Gaps

(none — these are deferred human / device / authority / ADC gates, not defects in the landed
code. The autonomous code for the phase is committed and green: ADR-017 records the decision;
the wire contract, scorer, and guards are all in place; `flutter test` and server `-m code`
reconcile to the documented baseline with zero new failures. Item 1 (deploy) is the only one that
an executor could otherwise finish — it is human-gated here solely by the auto-mode safety
classifier, not by a code or auth defect.)
