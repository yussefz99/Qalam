---
status: diagnosed
trigger: "stimulus-picture-too-small — owner UAT 2026-07-17: 'here i gave you a screenshot it can be much much better' re: picture prompt size/prominence"
created: 2026-07-17T08:20:52.000Z
updated: 2026-07-17T08:27:00.000Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

hypothesis: CONFIRMED — the _ImagePart Container in prompt_header.dart is an ABSOLUTE fixed-size box (260x176 dp, hardcoded, no flex/Expanded), a leftover port of the web prototype's `.pp-img width:128px/height:84px` CSS. It never scales with the available header-row/main-column width, so on a real tablet (main column is `Expanded` after a fixed 258px mascot column — hundreds to 1000+ logical px wide) the image occupies only a small fixed fraction of the row and the rest of the row is blank space. Doubling the constant (128->260) in 2d5f0b0 only doubled an arbitrary absolute number; it did not make the image responsive/prominent relative to the actual available canvas. SECONDARY confirmed bug: the caption Text (`what does it start with?`) has no explicit textDirection and inherits the ambient RTL Directionality set at ExerciseScaffold's root (exercise_scaffold.dart:602-603), so the trailing "?" bidi-reorders to the front — matches owner's screenshot "?what does it start with" exactly. Codebase precedent for this EXACT bug class already exists and was fixed elsewhere (feedback_panel_v2.dart:93-96, `textDirection: TextDirection.ltr` with the comment "force LTR so the trailing period doesn't jump left") but was never applied to the image caption.
test: read prompt_header.dart (_ImagePart), exercise_scaffold.dart (layout tree + Directionality), feedback_panel_v2.dart (precedent fix)
expecting: confirm fixed-size Container + inherited RTL Directionality on caption
next_action: goal=find_root_cause_only — stop here, return ROOT CAUSE FOUND

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: For an exercise with a picture prompt, the image renders large and prominent — easy to make out on the tablet, not feeling like a small/incidental element.
actual: "here i gave you a screenshot it can be much much better" — the picture (a duck illustration) renders at a moderate size in the top-right area of the screen, next to the Qalam mascot, with a caption below it ("?what does it start with" — leading "?" suggests possible RTL/LTR punctuation-ordering weirdness worth a quick look too). It is bigger than before the 2026-07-12 fix (128x84 -> 260x176) but still insufficiently prominent/readable per owner.
errors: None reported
reproduction: Open a baa-unit exercise that has a picture stimulus (word/phrase questions with an image prompt, e.g. "what does it start with"). Compare rendered image size/prominence against surrounding canvas and mascot.
started: Present since the 2026-07-12 fix (2d5f0b0); UAT re-confirmed insufficient on 2026-07-17

## Eliminated
<!-- APPEND only - prevents re-investigating -->

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-07-17T08:22:00.000Z
  checked: git show 2d5f0b0 -- lib/features/letter_unit/widgets/prompt_header.dart
  found: The 2026-07-12 fix only bumped two hardcoded literals (Container width/height 128->260, 84->176; Image.asset width/height matching; caption fontSize 11->15). No layout/flex change — the image is still an exact-size Container, not a flexible/proportional element.
  implication: The "fix" made the absolute number bigger but did not change the sizing STRATEGY (fixed px vs. responsive-to-available-space). Any tablet with more header-row width than ~260+padding will still show the image as visually small relative to its surroundings.

- timestamp: 2026-07-17T08:24:00.000Z
  checked: lib/features/letter_unit/widgets/prompt_header.dart full read (_ImagePart, PromptHeader._partFlex)
  found: PromptHeader._partFlex wraps ONLY TextPart in Expanded (".ppart-text{flex:1}" comment); ImagePart/AudioPart/RulePart size to content. _ImagePart's outer Container is a literal `width: 260, height: 176` (not a BoxConstraints min, unlike _AudioPart/_TextPart/_RulePart which use `constraints: BoxConstraints(minHeight: 64)` and can grow). For an image-only prompt (no sibling TextPart to Expanded and fill the row), the header Row collapses to exactly the image's own fixed size — the rest of the row/main-column width is simply blank.
  implication: Root mechanism confirmed — the image cannot grow to use available space, and for this exercise type (image-only header) there is nothing else in the row to absorb the remaining width, so the 260x176 box reads as a small island in a wide row.

- timestamp: 2026-07-17T08:25:00.000Z
  checked: lib/features/letter_unit/widgets/exercise_scaffold.dart lines 590-682
  found: build() wraps the WHOLE exercise Row in Directionality(rtl) (line 602-603). Row = SizedBox(width:258, mascot column) + SizedBox(width:24 gap) + Expanded(_mainColumn). _mainColumn renders PromptHeader at the top, THEN Expanded(_centerSurface()) for the actual writing canvas below. On any tablet width, _mainColumn's available width is (screen width - 258 - 24 - scaffold padding 52) — routinely 700-1500+ logical px on real tablets/iPad — all of which is available to PromptHeader's Row, yet the 260px-wide image box does not use it.
  implication: Confirms "next to the mascot" framing in the screenshot (mascot column is a fixed-width sibling at the far side) and confirms the image is capped well below the actual available canvas width — the mascot column is NOT competing for the image's space (it's a completely separate fixed-width column), the image is simply hardcoded small regardless of how much room _mainColumn has.

- timestamp: 2026-07-17T08:25:30.000Z
  checked: assets/curriculum/exercises.json line 221-235 (baa.writeLetter.fromPicture — the exact exercise matching the screenshot: img.duck / "what does it start with?")
  found: prompt = [say, image] only — NO TextPart sibling in this exercise's header. Source caption string is "what does it start with?" (question mark correctly at the END in the source data).
  implication: The reordering to "?what does it start with" is a RENDERING bug, not a data/authoring bug — the source string is correct.

- timestamp: 2026-07-17T08:26:00.000Z
  checked: lib/features/letter_unit/widgets/prompt_header.dart lines 226-234 (_ImagePart caption Text)
  found: `Text(caption!, textAlign: TextAlign.center, style: ...)` — no `textDirection` parameter. It inherits ambient Directionality, which per exercise_scaffold.dart:602-603 is TextDirection.rtl for the entire exercise Row (including PromptHeader and _ImagePart).
  implication: A pure-Latin string ending in a neutral punctuation mark ("?"), laid out under an RTL paragraph base direction, has its trailing neutral character bidi-resolved toward the paragraph's embedding direction (R) per the Unicode Bidi Algorithm (rule N1/N2) — this visually moves "?" to the front. This exactly reproduces "?what does it start with".

- timestamp: 2026-07-17T08:26:30.000Z
  checked: lib/features/letter_unit/widgets/feedback_panel_v2.dart lines 88-103
  found: An analogous English string ("Nothing to write — this card teaches." / idle hint) under the SAME ambient RTL Directionality is given an EXPLICIT `textDirection: TextDirection.ltr` with the comment "UAT F1: ... English guidance under the app's RTL Directionality — force LTR so the trailing period doesn't jump left."
  implication: This is a KNOWN, already-diagnosed-and-patched bug class in this codebase (trailing punctuation jumping under ambient RTL). The fix pattern exists and was simply never applied to _ImagePart's caption Text in prompt_header.dart — confirms the caption issue is a genuine oversight/regression-of-omission, not intentional design.

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: |
  Two distinct, confirmed root causes bundled under this UAT report:

  (1) PRIMARY (sizing/prominence): lib/features/letter_unit/widgets/prompt_header.dart
      `_ImagePart` renders the stimulus picture inside a Container with an ABSOLUTE
      fixed size (currently 260x176, previously 128x84 — both are hardcoded literals
      ported directly from the web prototype's `.pp-img` CSS pixel values). Unlike the
      other PromptPart widgets in the same row (_AudioPart/_TextPart/_RulePart, which
      use `BoxConstraints(minHeight: 64)` and can grow), the image Container/Image.asset
      pair is pinned to an exact width AND height with no flex/Expanded/responsive
      sizing. The 2026-07-12 fix (commit 2d5f0b0) only doubled this constant; it did not
      change the sizing strategy. Because PromptHeader._partFlex only wraps TextPart in
      Expanded, and this specific exercise type (baa.writeLetter.fromPicture, prompt =
      [say, image] only, no sibling TextPart) has nothing else to fill the row, the
      header row collapses to exactly the image's own small fixed footprint while
      _mainColumn (the space actually available — screen width minus the fixed 258px
      mascot column, 24px gap, and scaffold padding) is routinely 700-1500+ logical
      pixels wide on a real tablet. The image therefore visually reads as a small,
      incidental element regardless of how many times the constant is bumped, because
      it is not sized relative to its available layout space.

  (2) SECONDARY (caption bidi bug, noted per investigation hint (c)): the caption Text
      in the same `_ImagePart` widget (prompt_header.dart ~line 226-234) has no explicit
      `textDirection`, so it inherits the ambient `Directionality(textDirection: rtl)`
      that ExerciseScaffold applies to the entire exercise Row (exercise_scaffold.dart
      line 602-603). A pure-English caption ending in a neutral punctuation mark ("?")
      laid out under an RTL paragraph base direction has that trailing "?" bidi-resolved
      toward the RTL embedding direction (Unicode Bidi Algorithm neutral-resolution
      rules), which visually moves it to the front — reproducing the observed
      "?what does it start with" exactly. This is a genuine, unintentional bug: the
      exact same bug class was already identified and fixed elsewhere in the codebase
      (feedback_panel_v2.dart's idle-hint Text, which explicitly sets
      `textDirection: TextDirection.ltr` with a comment documenting this precise
      "trailing punctuation jumps left under RTL" phenomenon) but the same fix was never
      applied to the image caption.
fix: []
verification: []
files_changed: []
