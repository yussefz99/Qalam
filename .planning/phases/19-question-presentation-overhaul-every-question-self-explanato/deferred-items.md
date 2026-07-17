# Phase 19 — Deferred / Out-of-Scope Items

Discoveries logged during execution that are NOT this plan's task. Do not fix
here; the owning plan or a future phase resolves them.

## Pre-existing test failures (out of scope for 19-02)

- **`test/features/letter_unit/meet_section_test.dart` Test 1** — "renders the
  four contextual forms + the door image, PromptHeader-only" fails with
  `Found 0 widgets with text containing img.door`. This is a PromptHeader
  `ImagePart` rendering concern (the image id/caption is no longer surfaced as
  text). **Verified pre-existing**: fails identically at the pre-plan baseline
  commit `6611495` (run in a throwaway worktree during 19-02 execution). 19-02
  touches only `exercise_scaffold.dart` (the resolver + instruction bar) and its
  test — nothing in `PromptHeader`/`meet_section`/image rendering. Owned by the
  stimulus-renderer plan (19-03) or a later PromptHeader pass, not here.
  - **19-03 assessment (2026-07-17):** still out of scope. 19-03 touches the
    audio (`_AudioPart`) / text (`_TextPart`) / gap-slot (`_GapWord`/`_GapLetter`)
    renderers for D-05/D-06/D-07 — it does NOT touch `_ImagePart`. The failure is
    an obsolete assertion (`find.textContaining('img.door')`) expecting the
    hatched-stub id text on an image that now resolves to a real bundled asset;
    it is a meet-test / image-caption reconciliation, not a stimulus-renderer
    change. Left for a later PromptHeader/image pass (per the plan's explicit
    "not yours" note). Re-verified failing at the same `img.door` assertion after
    19-03's changes.

## Pre-existing test failures (out of scope for 19-05)

The `alif_reference` cluster — 4 failures, all alif-only, in `test/curriculum/`:

- **`reference_overlay_golden_test.dart`** — "alif resolved pen path overlays the
  glyph in draw order" → `alif_reference_overlay.png` pixel diff (~1.47%). The
  documented local Arabic-font golden drift (MEMORY: golden-tests-font-drift; do
  NOT re-bake).
- **`alif_reference_test.dart`** (2 cases) — "alif corrected centerline … first
  point at top / y monotonic" and "normalized total length ≈ 1.0". alif
  `letters.json` centerline data state.
- **`all_letters_validation_test.dart`** — "only signed-off letters claim
  signedOff: true" expects `[alif, baa, taa]`, gets `[baa, taa]` (alif currently
  signedOff:false in `letters.json`).

**Verified pre-existing (2026-07-18):** `git diff --name-only fef2c2c` (the
pre-plan base) over `letters.json`, `alif_reference_overlay.png`,
`alif_reference_test.dart`, `all_letters_validation_test.dart`,
`reference_overlay_golden_test.dart` is **empty** — every input to these tests is
byte-identical to base, so they fail identically before and after 19-05. 19-05
touches only the baa graph (`curriculum_graph.json`), the baa `kitaab` card
(`exercises.json`), and two baa test files — zero overlap with alif. STATE.md
repeatedly lists `alif-reference` as a known out-of-scope failure. Not this
plan's to fix; do NOT re-bake the golden.

## Wave-0 RED tests greened by later Wave-2 plans (expected RED at 19-02)

- **`copy_stimulus_test.dart`** (QP-03) — RED by missing `CopyStimulus`; greened
  by **19-03**.
- **`prompt_header_slot_audio_test.dart`** (QP-04/QP-05, 5 cases) — RED gap-slot
  + audio-card contract; greened by **19-03**.
- **`app_database_test.dart` v6→v7 migration case** (QP-09) — skip-marked;
  un-skipped + greened by **19-06**.
