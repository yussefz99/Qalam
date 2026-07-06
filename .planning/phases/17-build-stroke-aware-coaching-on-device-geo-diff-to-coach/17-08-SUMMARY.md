---
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
plan: 08
subsystem: coaching-contract
tags: [server, harden, ground-04, d-a, strokeimage, image-judge, coachout-verdict, forbidden-keys, rtl, uat-f1, wave-7]

# Dependency graph
requires:
  - phase: 17-07
    provides: "the CLIENT half of the D-A cutover — the client no longer renders or sends strokeImage (field/param/callback deleted, grep-guarded), TutorDecision.verdict removed, and _parseCoachOut already tolerates an absent CoachOut.verdict; removal-ordering (client-first, RESEARCH Pattern 3) satisfied so this plan can safely delete the optional server field + image_judge.py"
  - phase: 17-05
    provides: "the enlarged criteria/word server contract this hardens on top of — the structured per-criterion coaching input D-B routes through (unchanged here)"
provides:
  - "The server can no longer RECEIVE an image or EMIT a verdict: the strokeImage->image_judge short-circuit is deleted from main.py, strokeImage is deleted from TutorFactsIn, CoachOut.verdict is deleted, and server/app/image_judge.py is DELETED (not demoted — owner-adopted RESEARCH A5: the image was the worst spike arm, 0.20 hallucination, and keeping it re-opens the GROUND-02 image reversal this phase closes)"
  - "strokeImage joins FORBIDDEN_KEYS: a stale-client payload carrying the retired image key now 422s BY DESIGN under extra='forbid' — the 422 is the STRUCTURAL PROOF the off-device child-data surface shrank (GROUND-04 server half; a rendered image of child handwriting can no longer reach the server), pinned at BOTH the DTO level (test_payload_nonpii) and the live /coach boundary (test_endpoint)"
  - "GROUND-04 removal lockstep CLOSED on both wire sides (client 17-07 + server 17-08) with zero 422 window — client-first ordering held; only ADR-017 + the single Cloud Run re-deploy (17-10) remain to flip the requirement box"
  - "UAT F1 fixed: English helper copy ('On its own…', 'Nothing to write…', the English tutor feedback line) renders left-to-right under the app's RTL Directionality, pinned by a new widget test that pumps under an explicit RTL ancestor and asserts the resolved textDirection is LTR"
affects: [17-10, coaching-contract, tutor-server, adr-017]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Removal-ordering close (RESEARCH Pattern 3): the CLIENT stopped sending strokeImage FIRST (17-07); the SERVER deletes the optional field + its handler SECOND (here). The normal-payload byte-shape never changed (strokeImage was already omit-when-null), so there is no 422 window — and once the field is gone, a stale client's image key 422s BY DESIGN, which is the retirement PROOF, not a regression."
    - "Retirement-by-422: moving a deleted optional field into the extra='forbid' deny space turns 'silently ignored' into 'actively rejected'. The FORBIDDEN_KEYS parametrize (+ an explicit named test + the live-endpoint parametrize) makes the surface-shrink a permanent, self-documenting regression guard."
    - "LTR-island for English copy under an RTL app: force textDirection: TextDirection.ltr on the ENGLISH guidance Text only; Arabic glyphs keep rendering through ArabicText (RTL). The inverse of the ArabicText RTL-island idiom — an explicit direction on each leaf, not an ambient Directionality flip."

key-files:
  created:
    - test/features/letter_unit/meet_section_ltr_test.dart
  modified:
    - server/app/main.py
    - server/app/schema.py
    - server/tests/test_payload_nonpii.py
    - server/tests/test_endpoint.py
    - lib/features/letter_unit/sections/meet_section.dart
    - lib/features/letter_unit/widgets/feedback_panel_v2.dart
  deleted:
    - server/app/image_judge.py

key-decisions:
  - "image_judge.py DELETED, not demoted to an advisory corroborator (CONTEXT increment 6 left the option open). Under D-A the scorer owns pass/fail; keeping any image path re-opens the GROUND-02 image reversal this phase closes and re-admits the worst-hallucination spike arm. Full deletion keeps the retirement structural and the code honest."
  - "TutorDecision/CoachOut retirement notes were written WITHOUT the literal tokens 'strokeImage'/'image_judge' so `grep -rn 'strokeImage\\|image_judge' server/app/` returns 0 (the acceptance grep is the harder guarantee than the plan's suggested verbatim comment, which contained the tokens). The CoachOut note avoids the word 'verdict' entirely so the CoachOut-scoped verdict grep is also clean; the surviving 'verdict' mentions in schema.py are all in AttemptFactIn/TutorFactsIn `passed` descriptions + the TutorFactsIn retirement note — outside CoachOut, legitimate."
  - "The `grounded` field description in CoachOut was reworded ('honors the frozen verdict' -> 'honors the scorer''s frozen pass/fail') to satisfy the literal acceptance (0 'verdict' matches inside CoachOut) without changing behavior — it still documents the same G3 guard semantics."
  - "prompt_header.dart was NOT touched for F1: its only English strings are short chrome labels (the Hear/Play audio button, the image caption, the rule label), not the multi-word guidance sentences whose trailing period flips under RTL. Fixing it would be scope creep; recorded and dropped from the commit per the plan's 'fix ONLY if present' instruction."
  - "feedback_panel_v2.dart was fixed alongside meet_section.dart because the reported 'Nothing to write…' F1 string is its idleHint (routed from ExerciseScaffold.teachCardHint), and its pure-English tutor feedback line has the same trailing-period-under-RTL symptom; the Arabic-bearing line still routes through ArabicText (RTL), untouched."
  - "STRK-01 / GROUND-04 NOT checkbox-marked (17-01/03/04/05/06/07 precedent): this closes the SERVER half of GROUND-04's surface shrink; ADR-017 + the single live Cloud Run re-deploy (17-10) complete it. requirements-completed stays []."

patterns-established:
  - "Retire an optional wire field by DELETING it from the extra='forbid' DTO and asserting the now-unknown key 422s at both the model and the live endpoint — the 422 is the proof the surface shrank, and the parametrized guard makes re-introduction impossible to miss."

requirements-completed: []

# Metrics
duration: 9min
completed: 2026-07-06
---

# Phase 17 Plan 08: Server Retirement (D-A) + UAT F1 Summary

**The SERVER half of CONTEXT increment 6 (locked D-A): the strokeImage->image_judge verdict short-circuit is deleted from main.py, strokeImage is deleted from TutorFactsIn, CoachOut.verdict is deleted, and image_judge.py is DELETED — no image can reach the server and no verdict can leave it, with strokeImage joining FORBIDDEN_KEYS so a stale-client image key now 422s BY DESIGN (the structural proof the off-device child-data surface shrank). Plus UAT F1: English helper copy now renders LTR under the app's RTL Directionality, pinned by a new widget test.**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-07-06T16:52:29Z
- **Completed:** 2026-07-06T17:01:21Z
- **Tasks:** 2 (both `type="auto"`)
- **Files modified:** 6 (4 server + 2 lib); **created:** 1 test file; **deleted:** 1 server module

## Accomplishments

- **No image can reach the server, no verdict can leave it (GROUND-04 server half; D-A).** `main.py` loses the entire `if facts_in.strokeImage:` short-circuit (the lazy `image_judge` import, the `asyncio.to_thread(judge_baa_image, …)` wrap, and the `CoachOut(verdict=…)` return) — only the scorer-bounded graph path remains, degrade ladder + non-PII logging kept. `schema.py` loses the `strokeImage` field from `TutorFactsIn` and the `verdict` field from `CoachOut`. `server/app/image_judge.py` is **DELETED** (owner-adopted RESEARCH A5 — the image was the worst spike arm at 0.20 hallucination; keeping it re-opens the GROUND-02 reversal this phase closes). Retirement is now structural on **both** sides (client 17-07 + server 17-08).
- **The 422 is the retirement PROOF, not a regression.** `strokeImage` moved into `FORBIDDEN_KEYS` in `test_payload_nonpii.py` — the existing top-level + nested parametrized tests now assert an image key 422s under `extra="forbid"`, joined by an explicit named `test_strokeimage_key_is_now_rejected_422`. `test_endpoint.py`'s live-boundary 422 parametrize gains `strokeImage` too, proving the image key 422s over the real `/coach` HTTP surface. A stale client that still posts the retired key is rejected BY DESIGN — and the only live client is the same-phase demo build, cut over first (T-17-18, risk window nil).
- **UAT F1 fixed — English helper copy reads left-to-right.** `meet_section.dart`'s morph-card explain line ("On its own — the full bowl with its tail.") and `feedback_panel_v2.dart`'s idle hint ("Nothing to write — this card teaches." / "Write on the surface …") + the pure-English tutor feedback line now carry an explicit `textDirection: TextDirection.ltr`, so the trailing period no longer jumps left under the app's RTL `Directionality`. Arabic glyphs (via `ArabicText`) stay RTL, untouched. NEW `meet_section_ltr_test.dart` pumps `MeetSection` under an **explicit RTL ancestor**, asserts the ambient direction really is RTL (sanity leg), then asserts the English helper `Text` resolves LTR — a runtime pin a grep cannot see.
- **Guards + regressions all green.** Server `-m code` regression → **109 passed, 1 skipped** (was 105/1-skip at 17-06/07; +4 = the new strokeImage-422 assertions, no other change). Acceptance greps: `grep -rn "strokeImage\|image_judge" server/app/` → **0**; `image_judge.py` absent; 0 `verdict` matches inside `CoachOut`. `flutter analyze` on the two touched lib files → **No issues found!**. New LTR test → green. Full Flutter suite → **748 passed / 8 known-baseline failed** (17-07 baseline was 747/8; +1 = the new LTR test, failures unchanged — baseline NOT worsened).

## Task Commits

Each task committed atomically:

1. **Task 1: server retirement — delete the short-circuit, strokeImage, CoachOut.verdict, and image_judge.py** — `28440f3` (feat)
2. **Task 2: UAT F1 — English helper copy renders LTR + pinning widget test** — `f0a555c` (fix)

## Files Created/Modified

- `server/app/main.py` — deleted the strokeImage->image_judge short-circuit block (comment + `if facts_in.strokeImage:` branch with its lazy import, timeout/error 503 arms, and the `CoachOut(verdict=…)` return); replaced with a retirement note. The scorer-bounded graph path (with its degrade ladder + non-PII derived logging) is all that remains.
- `server/app/schema.py` — deleted `strokeImage` from `TutorFactsIn` and `verdict` from `CoachOut`, each replaced with a retirement note (notes avoid the literal `strokeImage`/`image_judge` tokens so the app-scan grep stays 0, and the CoachOut note avoids the word `verdict`); reworded the `grounded` description to drop `verdict`.
- `server/app/image_judge.py` — **DELETED** (`git rm`).
- `server/tests/test_payload_nonpii.py` — `strokeImage` added to `FORBIDDEN_KEYS` (with a comment explaining the 422 = surface-shrink proof) + a new explicit `test_strokeimage_key_is_now_rejected_422`.
- `server/tests/test_endpoint.py` — `strokeImage` added to the live-endpoint 422 parametrize (proves the image key 422s over the real `/coach` boundary).
- `lib/features/letter_unit/sections/meet_section.dart` — forced `textDirection: TextDirection.ltr` on the morph-card explain `Text` (the reported "On its own…" line).
- `lib/features/letter_unit/widgets/feedback_panel_v2.dart` — forced LTR on the idle-hint `Text` (the reported "Nothing to write…" line) and the pure-English tutor feedback `Text`; the Arabic-bearing line still routes through `ArabicText` (RTL), untouched.
- `test/features/letter_unit/meet_section_ltr_test.dart` — **NEW** widget test pinning the English-helper-LTR-under-RTL contract.

## Decisions Made

See frontmatter key-decisions. The load-bearing ones: `image_judge.py` is DELETED (not demoted); the retirement notes are written to keep the acceptance greps at 0 (no `strokeImage`/`image_judge` in `server/app/`, no `verdict` inside `CoachOut`) — the greps are the harder guarantee than the plan's suggested verbatim comment (which contained those tokens); `prompt_header.dart` was left untouched for F1 (its English strings are short chrome labels, not the guidance-sentence-under-RTL pattern) and dropped from the commit per the plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Retirement notes reworded to keep the acceptance greps at 0**
- **Found during:** Task 1 (schema.py + main.py edits)
- **Issue:** The plan's suggested verbatim comment contained the literal tokens `strokeImage` and `verdict`, which would make the hard acceptance greps (`grep -rn "strokeImage\|image_judge" server/app/` → 0; `grep -n "verdict"` → 0 inside `CoachOut`) fail. The acceptance greps are the stronger guarantee (the token is fully gone from app code).
- **Fix:** Wrote equivalent retirement notes that reference "the rendered-image field" / "AI pass/fail field" without the retired tokens, and reworded the surviving `grounded` field description to drop the word `verdict`. Meaning + rationale preserved; the greps pass.
- **Files modified:** server/app/main.py, server/app/schema.py
- **Verification:** `grep -rn "strokeImage\|image_judge" server/app/` → 0; `grep -n "verdict" server/app/schema.py` → 3 matches, all OUTSIDE CoachOut (AttemptFactIn/TutorFactsIn `passed` descriptions + the TutorFactsIn retirement note).
- **Committed in:** `28440f3` (Task 1)

---

**Total deviations:** 1 auto-fixed (1 blocking, to satisfy the literal acceptance greps).
**Impact on plan:** No architectural change, no scope change. `prompt_header.dart` was evaluated and correctly left untouched (recorded above), which is the plan's own "fix ONLY if present" branch, not a deviation.

## Issues Encountered

- **No dedicated image-judge tests existed to delete.** A pre-edit grep (`grep -rln "strokeImage\|image_judge\|judge_baa_image" server/tests/`) returned nothing — the image-judge path had code (main.py + image_judge.py) but no test coverage, so Task 1's "delete/rewrite any endpoint test that posted strokeImage" reduced to ADDING the 422 assertions (there was nothing to delete). Noted so 17-10 does not expect a removed test.
- **8 known full-suite failures remain** (meet_section door-image Test 1; mastery_celebration font-drift golden; the curriculum-data/golden family — alif_reference ×2, all_letters_validation, reference_overlay golden, glyph_audit golden, curriculum_repository_v2 — all in MEMORY / prior summaries). None touch this plan's changed code; the meet_section baseline is unchanged (Test 1 still fails as before, Tests 2/3/4 pass).

## Known Stubs

None — this plan is pure removal (server) + a one-line-per-widget directionality fix + guards/tests. No placeholder values, no TODO/FIXME, no UI-bound empty data introduced.

## Threat Flags

None new. The plan's threat register is satisfied:
- **T-17-15 (Information Disclosure — strokeImage server half, GROUND-04):** MITIGATED — the field + short-circuit + `image_judge.py` are deleted; the image key joins `FORBIDDEN_KEYS` and 422s on arrival at both the DTO and the live `/coach` boundary. A rendered image of child handwriting can no longer reach the server (net privacy win; recorded for ADR-017 at 17-10).
- **T-17-16 (Elevation of Privilege — verdict spoofing by the model):** MITIGATED — `CoachOut.verdict` is deleted, so no response field can carry a model pass/fail for the client to honor over the scorer; the G3 verdict-lock guard remains server-side defense in depth; client plumbing was already removed (17-07).
- **T-17-18 (Tampering — stale-client 422 after strokeImage deletion):** ACCEPTED — the only live client is the same-phase demo build, cut over first (17-07); the risk window is nil; recorded in the schema.py retirement note.
- **T-17-SC (Tampering — package installs):** green — zero new packages (no installs; one module deleted).

## Next Phase Readiness

- **17-10 (ADR-017 + single Cloud Run re-deploy + HUMAN-UAT) is unblocked:** GROUND-04's removal lockstep is now closed on BOTH wire sides (client 17-07 + server 17-08) with zero 422 window. The single live re-deploy of `qalam-tutor` (Cloud Run, project qalam-app-bd7d0, us-central1) plus ADR-017 (recording the D-A verdict-authority un-reversal + the derived-diff data flow + the kinematics-descoped D-C amendment) complete the requirement and flip STRK-01 / GROUND-04. Per phase precedent, this plan did NOT re-deploy.
- **Follow-up (carried from 17-07 deferred-items):** the now-dead `applyVerdict` in `exercise_controller.dart` and the 12 `letter_unit_screen.dart` info-lints remain queued for a cleanup sweep alongside 17-10.

## Self-Check: PASSED

- All 6 modified + 1 created file exist on disk; `server/app/image_judge.py` is absent (deleted); this SUMMARY exists.
- Commits `28440f3` (Task 1 feat) + `f0a555c` (Task 2 fix) present in git log.
- Acceptance re-verified: `grep -rn "strokeImage\|image_judge" server/app/` → 0; `test ! -f server/app/image_judge.py` → deleted; 0 `verdict` matches inside `CoachOut`; server `uv run pytest -m code -q` → 109 passed / 1 skipped; `flutter test test/features/letter_unit/meet_section_ltr_test.dart` → passed; `flutter analyze` (2 touched lib files) → 0 issues; full Flutter suite → 748 passed / 8 known-baseline failed (baseline not worsened).

---
*Phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach*
*Completed: 2026-07-06*
