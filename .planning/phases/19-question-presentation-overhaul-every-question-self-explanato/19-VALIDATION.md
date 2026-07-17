---
phase: 19
slug: question-presentation-overhaul-every-question-self-explanato
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-17
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Dart); Python `pytest` only if server content is re-derived |
| **Config file** | none — Flutter convention (server has `pytest` markers) |
| **Quick run command** | `flutter test test/features/letter_unit/ test/data/app_database_test.dart test/curriculum/ test/tutor/microdrill_selection_test.dart` |
| **Full suite command** | `flutter test` (client) + `cd server && make eval` only if server content re-derived |
| **Estimated runtime** | ~60–120 seconds (quick), several minutes (full) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command above (letter_unit widgets + app_database + curriculum + microdrill)
- **After every plan wave:** Run `flutter test` (full client suite) — known pre-existing failures excluded (alif_reference, mastery/glyph goldens per STATE.md; never "fix" via re-bake)
- **Before `/gsd-verify-work`:** Full client suite green (minus documented pre-existing goldens); device UAT of the new presentation is the human gate
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

> Task IDs to be filled by the planner. Requirement rows derive from RESEARCH.md's Phase Requirements → Test Map.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | — | — | QP-01/02 instruction bar renders per type + tap replays (live path via `presentGraphExercise`) | — | N/A | widget | `flutter test test/features/letter_unit/` | ❌ W0 | ⬜ pending |
| TBD | — | — | QP-03 `writeWord.copy` shows word → hides on action → peek restores | — | N/A | widget | `flutter test test/features/letter_unit/` | ❌ W0 | ⬜ pending |
| TBD | — | — | QP-04 `completeWord`/`fillBlank` big RTL slot box; no `__blank__` leak | — | N/A | widget | `flutter test test/features/letter_unit/` | ❌ W0 | ⬜ pending |
| TBD | — | — | QP-05 audio stimulus large card, auto-plays once, tap replays | — | N/A | widget | `flutter test test/features/letter_unit/` | ❌ W0 | ⬜ pending |
| TBD | — | — | QP-06 recall write types render no letter model | — | N/A | widget/data | `flutter test test/features/letter_unit/` | ❌ W0 | ⬜ pending |
| TBD | — | — | QP-07 learned-letters lint: baa `letters` ⊆ {alif,baa} unless gated | T-19-04 | Content never demands unlearned letters | data/lint | `flutter test test/curriculum/` | ❌ W0 | ⬜ pending |
| TBD | — | — | QP-08 3 microDrill nodes in `curriculum_graph.json`; selection green | — | N/A | data | `flutter test test/tutor/microdrill_selection_test.dart` | ✅ | ⬜ pending |
| TBD | — | — | QP-09 v6→v7 migration backfills `childProfileId`; profile A survives, profile B reads clean | T-19-01/02 | No cross-profile leak; no progress loss | migration | `flutter test test/data/app_database_test.dart` | ✅ (extend) | ⬜ pending |
| TBD | — | — | QP-09b `baa_signoff` invariant holds with rewritten cards carved out | — | N/A | data | `flutter test test/curriculum/baa_signoff_test.dart` | ✅ (extend) | ⬜ pending |
| TBD | — | — | QP-10 ADR-018 file present | — | N/A | doc | file-exists check | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Threat refs (from RESEARCH.md Security Domain):**
- T-19-01 Cross-profile data leak → `(childProfileId, letterId)` keys + fresh-profile clean read (D-14/16)
- T-19-02 Migration data loss → `TableMigration` recreate + backfill + temp-file migration test proving rows survive (D-16)
- T-19-03 PII reaching the wire via keying change → keying stays client-local (ADR-017); `childProfileId` never enters `TutorFacts`/coach payload — existing non-PII payload guard tests
- T-19-04 Content demanding unlearned letters (pedagogical) → D-12 lint

---

## Wave 0 Requirements

- [ ] `test/features/letter_unit/exercise_scaffold_instruction_bar_test.dart` — QP-01/02, mounted through `presentGraphExercise` (live path — Phase-15 lesson: never a bare scaffold)
- [ ] `test/features/letter_unit/copy_stimulus_test.dart` — QP-03 hide+peek state
- [ ] `test/features/letter_unit/prompt_header_slot_audio_test.dart` — QP-04/05 (extend existing prompt_header coverage)
- [ ] `test/curriculum/learned_letters_lint_test.dart` — QP-07 (`letters` ⊆ cumulative introOrder set)
- [ ] Extend `test/data/app_database_test.dart` — v6→v7 migration + two-profile isolation (temp-file DB per the v3→v4 precedent)
- [ ] Extend `test/curriculum/baa_signoff_test.dart` — carve out rewritten/gated cards
- [ ] Update `test/providers/progression_providers_test.dart` + parent-dashboard tests — for the `LetterReps` fold (D-15)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| New presentation readable cold by a child on device | QP-01..06 | Visual/pedagogical judgment on real tablet | Device UAT: run each non-trace question type, read screen with sound off, confirm instruction + stimulus + affordance carry the ask |
| Card rewrite sign-off | QP-07 | Curriculum is the mother's domain | Review packet: rewritten cards № 10, 15–20 + lint flag set vs owner's № list (A5) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
