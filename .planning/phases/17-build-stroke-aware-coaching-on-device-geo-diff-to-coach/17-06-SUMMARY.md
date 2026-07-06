---
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
plan: 06
subsystem: coaching-contract
tags: [client, wire-contract, criteria, word-facts, tutor-facts, check-result, validator, ground-04, strk-01, wave-5]

# Dependency graph
requires:
  - phase: 17-05
    provides: "the LANDED server contract this plan mirrors byte-for-byte — CriterionIn{criterion,zone,score} + criteria/weakestCriterion/expectedWord/writtenWord on TutorFactsIn, all optional/defaulted (additive strict-superset); the server ships FIRST by plan-graph construction so this client mirror closes the lockstep with zero 422 window"
  - phase: 17-03
    provides: "LetterScore.criteria (five {criterion,zone,score} CriterionResults) + weakest — the structured coaching input D-B; the validator already threads the asked form and holds the LetterScore in hand at _validateGlyph"
  - phase: 14-04
    provides: "the GROUND-02 client guard surface (payload_nonpii_test whitelist ∪ nested-key sets + the tightened token regex; TutorFacts toMap omit-when-null idiom; buildTutorFacts as the ONE non-PII chokepoint whose signature is the guard)"
provides:
  - "CheckResult carries optional DERIVED coaching facts — criteria (point-free {criterion,zone,score}), weakestCriterion, expectedWord, writtenWord — all optional, derived-only, verdict-preserving (== / passed / mistakeId / toString unchanged so every existing caller is source-compatible)"
  - "the validator serializes LetterScore.criteria (zone→enum NAME string) + weakest into the CheckResult on BOTH pass and fail (_validateGlyph); the sequence word path threads expectedWord/writtenWord on pass AND fail (F6 — the coach can praise a specific word too); _mapMistake untouched"
  - "TutorFacts mirrors the four fields byte-for-byte vs server/app/schema.py, emitted omit-when-null in toMap/toJson — the 422 lockstep closes with zero window (server already live in-repo)"
  - "buildTutorFacts derives all four FROM result (NO new parameter — the signature stays the non-PII guard); the scaffold call-site is byte-unchanged (already passes result:)"
affects: [17-07, 17-08, 17-10, coaching-contract, tutor-facts, validator]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Derived-facts-from-verdict: the validator freezes the scorer's structured LetterScore into the already-non-PII CheckResult; the builder reads them off `result` (never a new param) — so raw geometry physically cannot reach the model even as the wire widens (the signature IS the guard)"
    - "Point-free criterion serialization: CriterionResult → {criterion, zone: zone.name, score} — enum NAME string, never a coordinate; mirrors the server CriterionIn (nested extra=forbid) so a leaked point key 422s (GROUND-04)"
    - "Omit-when-null wire mirror (Pitfall 1): every new TutorFacts field is emitted only when present, so an unchanged payload byte-matches the prior shape and an old-shape client still validates against the additive server superset"
    - "Verdict-preserving CheckResult extension: the new fields are additive; == / passed / mistakeId / toString are byte-unchanged, so every validator/UI caller and every equality-based test is source-compatible with zero edits"

key-files:
  created: []
  modified:
    - lib/core/exercise_engine/check_result.dart
    - lib/core/exercise_engine/exercise_validator.dart
    - lib/tutor/tutor_facts.dart
    - lib/tutor/tutor_facts_builder.dart
    - test/tutor/payload_nonpii_test.dart
    - test/tutor/remote_agent_brain_test.dart
    - test/tutor/tutor_facts_builder_test.dart

key-decisions:
  - "The four fields are ADDITIVE + verdict-preserving on CheckResult: CheckResult.== / hashCode stay verdict-only (passed + mistakeId), so every equality-based validator/UI test passes with zero edits while the derived facts ride alongside — the deliberate property that made the sequence-path rewrite regression-free"
  - "criteria carried on a PASS too, not just a fail (D-B): _validateGlyph and the single-glyph sequence leg attach criteria + weakest on both branches, so the coach can name the weakest criterion even when praising (never invents a verdict; coaches the decided one)"
  - "word facts (expectedWord/writtenWord) travel with EVERY sequence verdict — the lifted-pen miss, the form miss, the word mismatch, the transform miss, AND the clean pass (F6: specific praise needs the word too); pure text, never geometry"
  - "zone serialized as the enum NAME string (zone.name → certainlyCorrect/fuzzy/certainlyWrong) to match the server CriterionIn.zone:str register (17-05 kept str not Literal precisely to round-trip the Dart enum name)"
  - "STRK-01 / GROUND-04 NOT checkbox-marked (17-01/03/04/05 precedent): this closes the CLIENT half of GROUND-04, but ADR-017 (17-10) + the single live re-deploy still complete it; the frontmatter records them verbatim, the final leg / phase verifier flips the boxes"

patterns-established:
  - "The wire-field change extended its guard tests in the SAME task as the field change (Pitfall 1) — the whitelist ∪ criteria-keys, the mirror-set assertion, and the recursive PII scan over a criteria-bearing fixture all landed with the field (the RED commit 99f79b0), not after"

requirements-completed: []

# Metrics
duration: 15min
completed: 2026-07-06
---

# Phase 17 Plan 06: Client Criteria + Word-facts Mirror Summary

**The CLIENT half of CONTEXT increment 4 (locked D-B): `CheckResult` gains four optional DERIVED coaching facts (`criteria` / `weakestCriterion` / `expectedWord` / `writtenWord`); the validator serializes the scorer's `LetterScore` into them on both pass and fail (word facts on the sequence path, F6); `TutorFacts` mirrors them byte-for-byte against `server/app/schema.py` (omit-when-null, the 422 lockstep); and `buildTutorFacts` derives all four straight off `result` with NO new parameter — so the two wire sides close the criteria/word lockstep with zero 422 window while the builder signature stays the non-PII guard.**

## Execution Reality: continued a partial prior run

This plan was found partly executed by an earlier attempt that was killed mid-GREEN by an API error. The Task-1 RED commit `99f79b0 test(17-06): add failing guard tests …` (the three test files) was already committed, and `lib/core/exercise_engine/check_result.dart`'s four-field extension was already implemented in the working tree (uncommitted). I verified ground truth against git, reviewed the uncommitted `check_result.dart` diff (correct and complete — kept as-is), then completed the remaining GREEN: the validator serialization, the `TutorFacts` mirror, and the builder derivation. One GREEN commit turned the RED guards green.

## Performance

- **Duration:** ~15 min (this continuation session)
- **Completed:** 2026-07-06
- **Tasks:** 1 (TDD — RED prior, GREEN this session)
- **Files modified:** 4 lib + 3 test (RED-committed); `exercise_scaffold.dart` verified unchanged

## Accomplishments

- **The scorer's decided verdict reaches the payload as structured FACTS (D-B).** `_validateGlyph` serializes `LetterScore.criteria` (each `CriterionResult` → `{criterion, zone: zone.name, score}`) plus `weakest` into the `CheckResult` on BOTH pass and fail; the builder reads them off `result`; `TutorFacts.toMap` emits them — so the coach names the FAILED (`certainlyWrong`) criterion, or on a pass the weakest one, never inventing a verdict.
- **The word path carries derived word facts (F6).** Every sequence verdict — lifted-pen miss, form miss, word mismatch, transform miss, and the clean pass — now carries `expectedWord`/`writtenWord` (pure DERIVED text, never geometry), so word/sentence coaching can be specific on praise as well as on a fix.
- **Byte-for-byte mirror, zero 422 window (Pitfall 1 / GROUND-04).** The four `TutorFacts` field names/casing match `server/app/schema.py` `TutorFactsIn` exactly and are emitted omit-when-null; the server (17-05) already accepts them, so the lockstep closes with no deploy window. `criteria` entries hold only `{criterion, zone, score}` scalars — the server's nested `extra="forbid"` 422s any leaked coordinate key.
- **The builder signature stayed the guard.** `buildTutorFacts` derives all four from the already-non-PII `result` — NO new stroke/Offset/word parameter — so raw geometry physically cannot reach the model even as the wire widens. The `exercise_scaffold.dart` call-site needed no change (it already passes `result:`); the `aiJudge`/`strokeImage` seams (17-07's) were left untouched.
- **Guards extended in-task (Pitfall 1).** The three RED test files (`payload_nonpii_test` whitelist ∪ `_criteriaKeys` + a criteria-bearing populated fixture + recursive PII scan; `remote_agent_brain_test` mirror-set + point-free CriterionIn assertion; `tutor_facts_builder_test` derive/omit) landed WITH the field change. `flutter test test/tutor/` → **114 passed**; `flutter test test/core/` → **137 passed**; server `-m code` regression → **105 passed, 1 skipped** (unchanged); `flutter analyze lib/tutor/ lib/core/exercise_engine/` → **0 issues**.

## Task Commits

TDD (test → feat); the RED commit predates this session:

1. **Task 1: client mirror — CheckResult carries the derived facts; TutorFacts/builder/validator thread them; guards extended**
   - `99f79b0` (test) — failing guard tests for the criteria + word-facts client mirror (committed by the prior run)
   - `befe05c` (feat) — client mirror scorer→validator→builder→payload + the `prefer_initializing_formals` ignore

## Files Created/Modified

- `lib/core/exercise_engine/check_result.dart` — four optional DERIVED fields (`criteria: List<Map<String,Object?>>?`, `weakestCriterion`, `expectedWord`, `writtenWord`), threaded through the main ctor + `.pass`/`.fail` factories; doc-comments cite D-B/GROUND-04 + the schema.py mirror. `==`/`hashCode`/`toString` verdict-only (unchanged). *(field extension from the prior run; completed + committed here)*
- `lib/core/exercise_engine/exercise_validator.dart` — new `_serializeCriteria(LetterScore)` (`CriterionResult → {criterion, zone.name, score}`, null when empty). `_validateGlyph` attaches `criteria`+`weakest` on pass AND fail; `_validateSequence` threads `expectedWord`/`writtenWord` on every word-path return (pass AND fail) and carries `criteria` on the single-glyph leg. `_mapMistake` untouched.
- `lib/tutor/tutor_facts.dart` — the four mirror fields with the `strokeDiff` omit-when-null idiom; `toMap()` emits `'criteria'`/`'weakestCriterion'`/`'expectedWord'`/`'writtenWord'` byte-matching schema.py; doc-comments cite the 422 trap.
- `lib/tutor/tutor_facts_builder.dart` — derives all four from `result` (`result.criteria`, etc.); NO new parameter (signature unchanged — the non-PII guard); doc updated.
- `test/tutor/payload_nonpii_test.dart`, `test/tutor/remote_agent_brain_test.dart`, `test/tutor/tutor_facts_builder_test.dart` — the RED guards (committed in `99f79b0`), now GREEN.

## Decisions Made

See frontmatter key-decisions. The load-bearing ones: the four fields are **additive + verdict-preserving** (CheckResult `==` stays verdict-only, so every equality-based test passes unchanged); **criteria ride a PASS too** (D-B — coach the weakest even when praising); **word facts on every sequence verdict** (F6 specific praise); **zone as the enum NAME string** (matches the 17-05 `str`-not-`Literal` register); and **STRK-01/GROUND-04 deferred** (this closes the client half; ADR-017 at 17-10 completes GROUND-04).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Suppressed a pre-existing `prefer_initializing_formals` lint so the plan's own `flutter analyze` verify passes**
- **Found during:** Task 1 (running the plan's `<verify>` — `flutter analyze lib/tutor/ lib/core/exercise_engine/`)
- **Issue:** `check_result.dart`'s `.fail` factory carries an info-level `prefer_initializing_formals` lint on `mistakeId = mistakeId` (pre-existing — present at HEAD line 43, already logged in `deferred-items.md` by 17-03). Because `check_result.dart` is a first-class `files_modified` target of THIS plan and the plan's `<verify>` runs `flutter analyze` over `lib/core/exercise_engine/`, the info lint made analyze exit 1.
- **Fix:** Added a targeted `// ignore: prefer_initializing_formals` with a rationale comment on the `.fail` factory. The factory deliberately takes a REQUIRED, non-null positional `mistakeId` while the field is nullable (the main ctor allows null on a pass); an initializing formal would weaken `.fail` to accept null. The ignore preserves that contract and makes `flutter analyze` exit 0.
- **Files modified:** lib/core/exercise_engine/check_result.dart
- **Verification:** `flutter analyze lib/tutor/ lib/core/exercise_engine/` → "No issues found!" (exit 0)
- **Committed in:** `befe05c` (Task 1 GREEN commit)

---

**Total deviations:** 1 auto-fixed (1 blocking, to satisfy the plan's own verify command). No architectural changes; no scope creep; no server/Dart-runtime behavior changed beyond the additive facts.

## Issues Encountered

None beyond the deviation above. Baseline discipline held:
- `flutter test test/tutor/` — **114 passed**; `flutter test test/core/` — **137 passed** (direct coverage of all four changed files — zero failures).
- `cd server && uv run pytest -m code -q` — **105 passed, 1 skipped** (mirror unchanged server-side; matches the 17-05 baseline exactly).
- Full suite post-commit — **+740 / -9**. The 9 are the KNOWN pre-existing baseline (curriculum `signedOff`/bundled-config data for alif, the `meet_section` door-image Test 1, `write_surface` Test 5, and the font-drift goldens `mastery_celebration`/`glyph_audit`/`reference_overlay`/`alif_reference` per MEMORY) — none touch the changed code. The pre-commit run showed `-10` only because the `spike_genui/durable_layers_unchanged` SC-4 guard (`git diff --quiet HEAD -- lib/core/exercise_engine/ …`) trips on UNCOMMITTED sacred-path edits; it went GREEN the moment the GREEN work was committed (working tree == HEAD), confirming zero regressions.

## Known Stubs

None — no placeholder values, no TODO/FIXME, no UI-bound empty data. The four fields are optional wire fields consumed by the existing server prompt/log path (17-05); they carry real derived data (the scorer's `LetterScore` + the config/recogniser word text) whenever the sequence/glyph path produces them, and are omitted otherwise.

## Threat Flags

None new. The plan's threat register is intact:
- **T-17-11 (Information Disclosure — criteria/word wire fields):** MITIGATED — `criteria` entries hold only `{criterion, zone, score}` scalars (`zone` an enum NAME string, never a coordinate); the whitelist ∪ `_criteriaKeys`, the mirror-set assertion, and the recursive PII token scan over a criteria-bearing fixture all extended in the SAME task as the field; the server nested `extra="forbid"` (17-05) 422s any leaked coordinate key.
- **T-17-12 (Information Disclosure — writtenWord):** MITIGATED — `expectedWord`/`writtenWord` are DERIVED TEXT (config word / ML Kit transcription of a curriculum word), never geometry; the PII regex scans the populated fixture.
- **T-17-13 (Tampering — 422 window during deploy):** MITIGATED — the server shipped first by plan-graph construction (17-06 `depends_on` 17-05); fields optional-with-default; omit-when-null keeps an unchanged payload byte-identical; single re-deploy at 17-10.
- **T-17-SC:** green — zero new packages (pubspec.yaml untouched).

## Next Phase Readiness

- **The criteria/word lockstep is closed both sides.** The server accepts the four fields (17-05, live in-repo) and the Dart `TutorFacts.toMap()` now emits them byte-for-byte — zero 422 window. The coach's criterion-aware / word-aware / English-primary addendum (17-05) now receives real client-sent evidence.
- **17-07 (geo-diff cutover):** the `aiJudge`/`strokeImage`/`onStrokeImage` seams in `exercise_scaffold.dart` were deliberately left untouched — that cutover is 17-07's.
- **17-10 (deploy + ADR):** the single Cloud Run re-deploy of the widened contract and ADR-017 (recording the D-C amendment + the verdict-authority stance) still land there; **GROUND-04's checkbox flips once the ADR is in** (the client mirror half is now complete).

## Self-Check: PASSED

- All 4 modified lib files + 3 RED-committed test files exist on disk; SUMMARY exists.
- Commits `99f79b0` (RED) + `befe05c` (GREEN) present in git log.
- Acceptance re-verified: `flutter test test/tutor/` (114) + `flutter test test/core/` (137) exit 0; `flutter analyze lib/tutor/ lib/core/exercise_engine/` → 0 issues; `tutor_facts.dart` toMap emits the four omit-when-null keys byte-matching schema.py; `buildTutorFacts` signature grew NO parameter; `grep "'name'" lib/tutor/tutor_facts.dart` → 0 (field is `criterion`); the `durable_layers_unchanged` SC-4 guard passes post-commit (no sacred-path drift beyond the committed change); server `-m code` unchanged (105/1-skip).
- TDD gate: `test(17-06)` (`99f79b0`) precedes `feat(17-06)` (`befe05c`).

---
*Phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach*
*Completed: 2026-07-06*
