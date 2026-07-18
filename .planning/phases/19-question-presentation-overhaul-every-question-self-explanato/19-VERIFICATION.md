---
phase: 19-question-presentation-overhaul-every-question-self-explanato
verified: 2026-07-18T12:00:00Z
status: human_needed
score: 4/4 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Cold-read the new presentation on a real tablet with sound OFF for one card of each non-trace question type (traceLetter, writeLetter, writeWord.copy, writeWord.dictation, connectWord, completeWord, microDrill)"
    expected: "The instruction bar + stimulus zone + affordance alone (no audio) tell the child what to do — instruction text matches the per-type template, the gap slot/audio card/copy widget is legible and correctly sized, exactly one replay control is visible"
    why_human: "Visual/pedagogical legibility judgment on a real device; widget tests can assert keys/text exist but not that a child can read and act on them cold"
  - test: "On device, mount a listen-and-write node (e.g. baa.writeWord.dictation) and confirm only ONE audio stream plays on mount (WR-03 fix)"
    expected: "The hero audio card's clip plays once; the say-line TTS does NOT also fire simultaneously; tapping the instruction bar still re-speaks the say line as reinforcement"
    why_human: "19-REVIEW-FIX.md explicitly flags this fix as requiring device verification — both audio channels are mocked separately in widget tests and cannot detect real simultaneous playback"
  - test: "On device, rapidly tap 'Try again'/'Next exercise' immediately after a fail, before the coach round-trip resolves, on a criterion the child has already failed once (repeat-fail step-down path, WR-04 fix)"
    expected: "The very next card steps down to an easier form per the D-02 remediation guarantee, even under fast repeated taps — not a stale retry-in-place"
    why_human: "19-REVIEW-FIX.md explicitly flags this fix as requiring human verification — widget suites cannot reproduce real coach latency plus real tap timing"
  - test: "Owner's mother reviews 19-REVIEW-PACKET.md (the 7 flagged baa cards) and confirms/edits the rewrite-vs-gate dispositions, flipping signedOff on any card she approves"
    expected: "Each of the 7 cards gets a confirmed disposition; the kitaab→باب rewrite is either approved as-is, edited, or replaced with the gate alternative"
    why_human: "Curriculum content sign-off is explicitly the mother's domain (project CLAUDE.md); this is a non-blocking gate by design (D-11) — the phase ships safely without it, but it is not yet closed"
  - test: "Owner authorizes and executes a fresh Cloud Run deploy of the qalam-tutor server so the re-derived server/app/curriculum_data/*.json (WR-05 fix — corrected G4 membership set including the micro-drills, final-form trace, and kitaab) go live"
    expected: "The deployed server's coach can propose the restored micro-drill nodes and the final-form trace online, not only via the offline walker fallback"
    why_human: "Standing project rule: every prod deploy needs fresh explicit owner wording, even mid-session (memory: tutor-server-deployed). The fix is committed but the offline client already ships correctly with the bundled assets, so this is not a functional blocker — only an online-coach-proposal gap until redeploy"
---

# Phase 19: Question Presentation Overhaul — Verification Report

**Phase Goal:** Every non-trace question shows what is being asked without depending on the
spoken line — persistent child-readable instruction area, large stimulus zone, per-type "what
to do" affordance. Language cards use only learned letters (first unit). Micro-drills back in
the live graph. Per-child position keying with migration so a fresh profile starts at the
opening.

**Verified:** 2026-07-18T12:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Any question type read cold from the screen alone tells the child what to do — instruction + stimulus + affordance — spoken line as reinforcement only | ✓ VERIFIED | `Key('instructionBar')` renders a per-type template (`instructionTemplateFor`) independent of the `say` line (Pitfall 6 respected); gap slot (`Key('gapSlot')`), hero audio card (`Key('audioCard')`), and `CopyStimulus` (reveal→hide→peek) all render real content on the live `presentGraphExercise` path. CR-01 (the one live `completeWord` card whose authored text used a bare `_` instead of the `_letter_` marker, so the gap slot never actually rendered on device) was found by code review and fixed in `a8ce079` with a new asset-backed regression test (`prompt_header_live_asset_gap_test.dart`, verified green). All Wave-0 contract tests (`exercise_scaffold_instruction_bar_test`, `prompt_header_slot_audio_test`, `copy_stimulus_test`, `recall_no_model_test`, `instruction_template_test`) pass with zero test edits from the plans that implemented them. Cold-device legibility itself is a human-verification item (below) — code-level self-explanatory rendering is confirmed. |
| 2 | The first unit's language cards use only letters the child has learned; sentences/grammar gate to later letters | ✓ VERIFIED | `learned_letters_lint_test.dart` passes green; live `curriculum_graph.json` has 17 baa.* nodes, none of which are `buildSentence.*`, `fillBlank.adjective`, or `transformWord.*` (grep-confirmed absent). The 6 cards needing unlearned letters were gated (node removed, content dormant, filed for later units); `baa.connectWord.kitaab` was rewritten كتاب→باب (alif+baa only), shipped `signedOff:false` pending the mother's review. `baa_signoff_test.dart` passes with the carve-out extended correctly. |
| 3 | Micro-drills are back in the live graph behind the reworked presentation | ✓ VERIFIED | `curriculum_graph.json` contains the `microDrill` competency + 3 live nodes (`baa.microDrill.dot/bowl/start`, grep-confirmed). `microdrill_selection_test.dart` passes, now sourced from the live graph (fixture no longer injects). A regression surfaced during 19-05 (the remediation arc's floor-trace step-down preferred the restored drill over the guaranteed-doable floor trace on a same-criterion trace fail) was caught and fixed (`fe6487c`) with `_stepDownTarget` making floor resolution exercise-type-aware; `same_id_represent_test` T6 passes. |
| 4 | Two child profiles on one device keep separate graph cursors/arc state (a fresh profile starts at the opening) | ✓ VERIFIED | Schema is v7 (`schemaVersion => 7`); five progress tables re-keyed to include `childProfileId` in their PK; `LetterCriterionEvidence` carries it as a filtered column; `class LetterReps` is fully removed. The `v6→v7` migration test (`test/data/app_database_test.dart`) runs against a genuine temp-file `NativeDatabase`, seeds real v6-shaped rows for profile A, triggers the real `onUpgrade` path, and asserts (a) profile A's rows across all 4 re-keyed tables survive adopted under the current profile, (b) a second profile id reads **zero** rows on every table (the actual cross-profile-leak assertion), (c) `letter_reps` table is gone, (d) idempotence on a second open. Independently re-run in isolation: **PASS**, 11/11. A second WR-06 case (added in the review-fix pass) exercises the previously-untested `letter_criterion_evidence` re-key branch the same way — also green. `childProfileId` is threaded through the repository layer and cached once in `LetterUnitController.start()` (verified: no inline `childProfileProvider.future` read on a write path); confirmed absent from `lib/tutor/` and the wire payload (payload_nonpii_test, tutor_facts_builder_test both green). |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/letter_unit/widgets/exercise_scaffold.dart` | Instruction bar + per-type resolver; `_HearAgainCta` folded away | ✓ VERIFIED | `Key('instructionBar')` present at line 1009; `_HearAgainCta` class fully absent (grep-confirmed) |
| `lib/features/letter_unit/widgets/prompt_header.dart` | Enlarged gap slot + hero audio card | ✓ VERIFIED | `Key('gapSlot')` (×2 render sites), `Key('audioCard')` present |
| `lib/features/letter_unit/widgets/copy_stimulus.dart` | Child-controlled reveal→hide→peek widget | ✓ VERIFIED | 198 lines, exists, wired into `_TextPart` for `reveal=='thenHide'` |
| `test/curriculum/learned_letters_lint_test.dart` | QP-07 lint enforcing letters ⊆ cumulative introOrder | ✓ VERIFIED | Exists, green, ranks by `letters.json` introOrder |
| `assets/curriculum/curriculum_graph.json` | microDrill nodes restored, 6 unlearned-letter nodes gated | ✓ VERIFIED | 17 nodes total, 3 microDrill nodes present, 0 gated-type nodes present |
| `docs/architecture/ADR-018-child-identity-keying.md` | Identity keying rule + D-17 deferral | ✓ VERIFIED | Exists (11785 bytes), states `childProfileId` rule, verified drift 2.31 `TableMigration` API, wire-boundary note |
| `lib/data/app_database.dart` | Schema v7, 5 tables re-keyed, LetterReps dropped | ✓ VERIFIED | `schemaVersion => 7`; `class LetterReps` absent |
| `.planning/phases/19-.../19-REVIEW-PACKET.md` | Mother's review packet for the 7 cards | ✓ VERIFIED | Exists, covers all 7 cards with content/rendering/disposition/recommendation, framed non-blocking |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| Instruction bar tap | `_speakInstructionThenRelease` | `InkWell onTap` | ✓ WIRED | Confirmed at exercise_scaffold.dart; bar tap re-speaks in the audio-overlap regression test |
| `_TextPart` reveal path | `CopyStimulus` | `reveal=='thenHide'` render swap | ✓ WIRED | Static `Opacity(0.18)` dim fully replaced; `copy_stimulus_test.dart` green on the live render path |
| `progression_providers.watchLetterCleanReps` | `LetterExerciseReps` aggregate | `_bindDriftStream` bridge | ✓ WIRED | Never a bare `StreamProvider.future` (grep-confirmed); ribbon test green |
| `app_database v6→v7 onUpgrade` | `TableMigration` recreate + backfill | `Migrator.alterTable` + `Constant<int>` | ✓ WIRED | Verified by running the actual migration test against a real temp-file DB (not a fixture bypass) |
| `letter_unit_controller.start()` | every keyed DB write | cached `childProfileId` field | ✓ WIRED | `child_profile_keying_test.dart` asserts the cache-once behavior AND a source assertion that `childProfileProvider.future` is read exactly once |
| keying change | wire payload | NONE (client-local only) | ✓ VERIFIED | `payload_nonpii_test`, `tutor_facts_builder_test` green; `childProfileId` absent from `lib/tutor/` (grep: 0 matches) |

### Requirements Coverage (Phase-local QP-01..QP-10, per 19-RESEARCH.md / 19-VALIDATION.md)

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| QP-01 | 19-02 | Persistent instruction bar renders per graded exercise | ✓ SATISFIED | `exercise_scaffold_instruction_bar_test.dart` green; live-mounted via `presentGraphExercise` |
| QP-02 | 19-02 | Bar tappable to re-hear; exactly one replay affordance | ✓ SATISFIED | `_HearAgainCta` deleted; bar is the sole replay control (source + test confirmed) |
| QP-03 | 19-03 | `writeWord.copy` reveal→hide→peek, no timer | ✓ SATISFIED | `copy_stimulus_test.dart` green; no `Timer`/`Future.delayed` hiding the word (grep-confirmed absent) |
| QP-04 | 19-03 | `completeWord`/`fillBlank` big RTL slot box, no `__blank__` leak | ✓ SATISFIED | `prompt_header_slot_audio_test.dart` green + CR-01 asset-backed regression fixed and tested (the ONE live card that would otherwise have leaked the marker on device) |
| QP-05 | 19-03 | Audio stimulus large card, auto-plays once, replays on tap | ✓ SATISFIED | Same test file, `Key('audioCard')` min-height 96 confirmed; silent-degrade on missing clip confirmed |
| QP-06 | 19-03 | Recall write types render no letter model | ✓ SATISFIED | `recall_no_model_test.dart` green (non-vacuous — asserts ≥1 real recall config) |
| QP-07 | 19-05 | Learned-letters lint fails build on unlearned-letter cards | ✓ SATISFIED | `learned_letters_lint_test.dart` green; 6 cards gated, 1 rewritten |
| QP-08 | 19-05 | Micro-drills restored to live graph, selection still green | ✓ SATISFIED | 3 nodes in `curriculum_graph.json`; `microdrill_selection_test.dart` green; post-restore selection regression (arc floor-trace preemption) caught and fixed |
| QP-09 | 19-01/19-04/19-06 | v6→v7 migration; profile isolation; LetterReps folded+dropped | ✓ SATISFIED | Migration test independently re-run green (11/11); LetterReps class absent; readers folded in 19-04 before the drop in 19-06 (correct order) |
| QP-10 | 19-06 | ADR-018 records the identity rule | ✓ SATISFIED | ADR-018 exists, states the rule, verified drift API, wire-boundary note |

No orphaned requirements — REQUIREMENTS.md predates this phase and does not carry QP-* IDs (as expected per the task brief); all QP-01..10 are accounted for across the 6 plans' frontmatter and completed per their SUMMARY `requirements-completed` fields, cross-checked against actual code/test evidence above (not just SUMMARY claims).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/l10n/app_en.arb` / `exercise_presenter.dart` / `copy_stimulus.dart` | multiple | 21 Phase-19 l10n keys (`instructionBar*`, `promptAudioListen`, `copy*`) have zero consumers — `presentGraphExercise` never threads `AppLocalizations`; widgets hardcode English Semantics strings | ℹ️ Info | Dead ARB mirrors will silently drift from the widget defaults; a future localization pass must reconcile. Flagged by code review as IN-02, explicitly out of scope for the required fix pass (Info-level, not Critical/Warning) — does not affect the current English-only product or any of the 4 success criteria. Not a blocker. |
| `lib/features/letter_unit/letter_unit_controller.dart` | `_presentedExerciseIds()` | Hardcoded to the baa unit; alif/taa units' Mastery sections can never record a star via this path | ℹ️ Info | Pre-existing (documented INTERIM in the code), not introduced by this phase, and does not affect any of the 4 Phase-19 success criteria (which are baa-unit scoped). Flagged by code review as IN-04, explicitly out of scope. |

No Critical or Warning-level anti-patterns remain. The code review (19-REVIEW.md) found 2 Critical + 6 Warning issues; all 8 were independently re-verified in this pass as genuinely fixed at the code level (not just claimed in 19-REVIEW-FIX.md) — see the Fix Verification table below.

### Fix Verification (19-REVIEW.md → 19-REVIEW-FIX.md, independently re-checked)

| ID | Finding | Fix claimed | Independently verified |
|----|---------|-------------|------------------------|
| CR-01 | Live `completeWord` card used bare `_`, never rendered the gap slot on device | Marker fixed in both asset copies + new asset-backed test | ✓ Confirmed: `"text": "با_letter_"` in both `assets/curriculum/exercises.json:514` and the server mirror; `prompt_header_live_asset_gap_test.dart` exists and passes |
| CR-02 | `baa.traceLetter.final` passes discarded; mastery gate/demo omit it | Forms path maps to graph id; presented sets updated | ✓ Confirmed: `forms_section.dart` graphId now `step.exercise.id`; `_presentedExerciseIds()` and `seeded_demo_state.dart` both include `baa.traceLetter.final` |
| WR-01 | `_essentialFloor` could stamp `cleanReps: 0` on a scoped-mastery star | Floor scoped to the presented set | ✓ Confirmed: `_essentialFloor(graph, reps, presented)` skips non-presented nodes when `presented.isNotEmpty` |
| WR-02 | `CopyStimulus.hideSignal` dead code (no stroke-start seam) | Removed; documented as deferred | ✓ Confirmed: `hideSignal` absent from both `copy_stimulus.dart` and `prompt_header.dart`; deferral documented in-code |
| WR-03 | Two audio streams (TTS + hero clip) play simultaneously on mount | Mount TTS suppressed when hero audio is wired | ✓ Confirmed: `mountAutoSpeak` gate + `onAudioTap != null` check present; new regression test passes; **device verification still owed** (listed as human_verification below) |
| WR-04 | Selection/arc advance gated on scaffold `mounted`; fast tap skips step-down | Moved to `selectNextWhenDecided` on the controller | ✓ Confirmed: `selectNextWhenDecided` exists on the controller and is called from the scaffold; **device verification still owed** (listed as human_verification below) |
| WR-05 | Server G4 id set stale — rejects proposing restored micro-drills/final-form/kitaab | Re-derived from live graph nodes | ✓ Confirmed: `server/app/curriculum_data/baa_authored_ids.json` now includes `baa.traceLetter.final`, all 3 microDrill ids, `baa.connectWord.kitaab`; excludes the 6 gated ids; **NOT yet redeployed** (owner-authorization required, listed as human_verification below) |
| WR-06 | v6→v7 migration test never exercised the evidence-table re-key branch | New case added | ✓ Confirmed: new test case seeding v6 `letter_criterion_evidence` DDL exists and passes |

### Behavioral Spot-Checks / Full Suite Run

Full client suite independently re-run from a clean, sequential invocation (not trusting SUMMARY/REVIEW-FIX claims):

```
flutter test  →  00:42 +892 -7: Some tests failed.
```

The 7 failures, individually identified via `[E]` markers in the run log, are **exactly** the documented pre-existing acceptable set — no more, no fewer:

| Failing test | Matches acceptable set |
|---|---|
| `glyph_audit_golden_test.dart` — golden gate (D-12) | glyph_audit golden |
| `reference_overlay_golden_test.dart` — alif overlay | reference_overlay golden |
| `alif_reference_test.dart` — centerline y-monotonic | alif_reference ×2 (1 of 2) |
| `alif_reference_test.dart` — normalized length | alif_reference ×2 (2 of 2) |
| `all_letters_validation_test.dart` — signedOff | all_letters_validation signedOff |
| `meet_section_test.dart` — img.door | meet_section img.door |
| `mastery_celebration_golden_test.dart` — golden snapshot | mastery_celebration golden |

The previously-flagged "curriculum_repository_v2_test / all_letters_validation 51-vs-52 count drift" (noted as an open concern in the 19-06 SUMMARY and deferred-items.md) was independently re-tested and found **already resolved** — commit `a59f3ce` ("reconcile bundled exercise count to 52") landed after 19-06 and before the code review; re-running both test files in isolation shows only the one acceptable `signedOff` failure, not a count mismatch.

`flutter analyze`: 0 errors, 70 pre-existing warnings/infos (none in phase-19-modified files) — matches the 19-REVIEW-FIX.md claim.

Note: an earlier ad-hoc run in this verification session (piping `flutter test` through two concurrent invocations) surfaced spurious `pin_service_test.dart`/`parent_gate_test.dart` failures with a Drift "AppDatabase constructed twice" warning. Re-run cleanly in isolation, this file passes 9/9. This was cross-process contention from running two `flutter test` invocations at once in this verification session, not a real defect — excluded from the findings above.

### Human Verification Required

### 1. Cold-read legibility on a real tablet (sound off)

**Test:** Run each non-trace question type on-device, sound OFF, and read the screen alone.
**Expected:** Instruction bar text + stimulus zone + affordance together tell the child what to do without needing audio.
**Why human:** Visual/pedagogical legibility judgment; widget tests confirm the elements exist and render correct text/keys but cannot judge real on-device readability.

### 2. WR-03 audio-overlap fix — device confirmation

**Test:** Mount a listen-and-write node (e.g. `baa.writeWord.dictation`) on a real device.
**Expected:** Only the hero audio card's clip plays on mount; the say-line TTS does not also fire simultaneously.
**Why human:** 19-REVIEW-FIX.md explicitly flags this as needing device verification — the two audio channels are mocked independently in widget tests and cannot detect real overlapping playback.

### 3. WR-04 fast-tap step-down fix — device confirmation

**Test:** Rapidly tap "Try again"/"Next exercise" immediately after a repeat-criterion fail, before the coach round-trip resolves.
**Expected:** The very next card steps down to an easier form per the D-02 guarantee, not a stale retry-in-place.
**Why human:** 19-REVIEW-FIX.md explicitly flags this as needing human verification — widget suites cannot reproduce real coach latency plus tap timing.

### 4. Mother's sign-off on the review packet

**Test:** Owner's mother reviews `19-REVIEW-PACKET.md` and confirms/edits the 7 flagged cards' dispositions.
**Expected:** Each card gets a confirmed disposition (rewrite approved/edited, or gated instead); `signedOff` flips where she approves.
**Why human:** Curriculum content sign-off is explicitly the mother's domain (per project CLAUDE.md). Non-blocking by design (D-11) — does not gate this phase's completion — but remains an open item.

### 5. Owner-authorized server redeploy

**Test:** Owner authorizes and executes a fresh Cloud Run deploy of `qalam-tutor` carrying the re-derived `server/app/curriculum_data/*.json` (WR-05 fix).
**Expected:** The deployed server's coach can propose the restored micro-drills/final-form trace online.
**Why human:** Standing project rule requires fresh explicit owner wording for every prod deploy. Not a functional blocker for the offline client (which already reads the correct bundled assets), but the online coach-proposal path is stale until redeploy.

### Gaps Summary

No blocking gaps. All 4 ROADMAP success criteria are independently verified true in the current
codebase, not merely claimed in SUMMARY.md files. The 2 Critical + 6 Warning issues found by the
post-execution code review were independently re-verified as genuinely fixed at the code and test
level (git history confirms 12 real commits; grep/read confirms the actual source changes; the
full test suite was independently re-run and shows only the documented pre-existing failure set).
An apparent "51 vs 52 exercise count" loose end noted in the 19-06 SUMMARY/deferred-items.md was
checked and found already resolved by a later commit.

The phase is functionally complete and correct in the repository. What remains is exactly the set
of items every one of the phase's own plans/reviews already flagged as requiring a human: on-device
legibility, two specific fixes that widget tests structurally cannot exercise, the mother's
curriculum sign-off (explicitly non-blocking by design), and an owner-gated production deploy.
None of these are code gaps — they are the phase's own declared human gate. Per the verification
decision tree, any non-empty human-verification list forces `status: human_needed` even though the
automated score is 4/4.

---

_Verified: 2026-07-18T12:00:00Z_
_Verifier: Claude (gsd-verifier)_
