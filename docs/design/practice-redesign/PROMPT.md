# Task: redesign the Practice screen layout (Watch + Trace, side by side)

**Repo:** `yussefz99/Qalam` (Flutter, Android tablet, RTL, Riverpod).
**File:** `lib/features/practice/practice_screen.dart` and its widgets under `lib/features/practice/widgets/`.

The practice loop **already works functionally** — stylus capture, on-device geometric scoring, the `watch → trace → showFix / showPraise → celebrate` state machine, advancement and persistence. **Do not change any of that behavior.** This task is layout + visual only: restructure the **Trace** (and **ShowFix**) phase into a three-zone layout so the child writes on a big canvas with the stroke-order demo and the tutor visible *at the same time*.

> Run this through the normal **GSD workflow** (`/gsd-quick` is fine for a UI-only change) — don't edit outside it. This is `flutter-ui-implementer` work; `flutter-ui-designer` for the child-UX/RTL call.

## Read first (source of truth — don't re-derive)
- `lib/features/practice/practice_screen.dart` — the current single-column phase views (`_WatchPhase`, `_TracePhase`, `_ShowFixPhase`, `_PraisePhase`) and the shared `_PrimaryButton` / `_GhostButton` / `_TipCard`. The **anti-gamification header comment** is binding.
- `lib/features/practice/widgets/stroke_canvas.dart` — `StrokeCanvas` (Listener-based stylus capture, palm rejection, dotted guide + gold start-dot + live deep-ink smoothing, `onStrokeSubmitted`). **Reuse as-is.**
- `lib/features/practice/widgets/stroke_order_animation.dart` — `StrokeOrderAnimation` + `StrokeOrderAnimationState.replay()` via `GlobalKey`. Pen-tip travels the resolved reference path; auto-plays once. **Reuse as-is.**
- `lib/widgets/qalam_mascot.dart` — `QalamMascot(pose:, size:)`, poses `idle / write / cheer / tryAgain / think`. **Currently NOT on the practice screen — add it.**
- `lib/widgets/arabic_text.dart` — for any Arabic glyph (RTL, Noto Naskh, never bold/italic).
- `lib/theme/colors.dart` `dimens.dart` `text_styles.dart` — `QalamColors`, `QalamSpace`, `QalamTargets`, `QalamRadii`, `QalamShadows`, `QalamMotion`, `QalamTextStyles`. **Tokens only — never raw hex or magic numbers** (D-01/D-02).
- `lib/models/letter.dart` — the screen is driven entirely by `letter.referenceStrokes` (normalized 0..1 `StrokeSpec`s) + `letter.char` / `letter.name` / `letter.cleanRepsToAdvance`. This is the "one template, every letter" mechanism.

> Where this prompt and the code disagree, **the code wins.** Mirror existing token usage and widget contracts exactly.

## The new layout — `_TracePhase` (and reuse for `_ShowFixPhase`)

Landscape `Row` with three zones (replace the current single-column `Column`):

1. **Left — the Tutor panel (~262px fixed).** This is the AI tutor made visible. `QalamMascot` (~158px) + the name "Qalam" / role "Your Writing Tutor" + a **speech bubble that IS the tutor's voice**, and a **Sound section** (see below). The bubble and pose are driven by phase — the tutor *thinks, then speaks*:
   - `trace` (writing) → `idle` pose, neutral bubble with warm coaching ("Take your time. Start at the gold dot…").
   - **scoring** → `think` pose, bubble shows a brief "Let me look at your alif …" (animated dots) — the visible "thinking" beat.
   - `showFix` → `tryAgain` pose, **coral-tinted** bubble headed "Qalam says" with the **specific named fix** (the authored `commonMistakes[].feedback` string for `state.lastMistakeId`).
   - `showPraise` → `cheer` pose, **leaf-tinted** bubble with specific praise.
   - **Fold `FeedbackPanel` and `PraisePanel` content into this bubble** — same authored strings, same coral/leaf semantics, but spoken *by the tutor* on the left rather than a separate center panel. The tutor is the one consistent voice (CLAUDE.md: "feedback *is* Qalam speaking").
2. **Center — the writing canvas (the hero, `Expanded`).** Heading `"Now you trace {romanized}."` (`QalamTextStyles.display`) + the existing **pedagogical** progress row (`Stroke 1 of 1`, clean-rep pips — **NOT a score, NOT a gold tally**). Below it, the existing `StrokeCanvas` in a surface card (radius `QalamRadii.xl`, `QalamShadows.shadowMd`, 1.5px `QalamColors.border`) — as large as the frame allows. Add a **Clear** ghost button (bottom-left, ≥`QalamTargets.targetMin`) that resets the current attempt's ink. Below the canvas, a bottom **action row**: a soft hint during tracing ("Lift your pen when you finish the stroke."), the **Try Again** / **Keep Going** primary buttons on fix/praise, and a **Show Me Again** ghost button on fix (triggers the cast, below).
3. **Corner — the stroke-order demo, docked (the "perfect" replacement for the toggle).** Float a small (~160px) **"Watch Me"** card in the **top-right of the canvas** holding a shrunk `StrokeOrderAnimation` that loops gently — the at-a-glance reference the child can watch *while writing*. It carries a "Tap to show me here" hint and is itself the affordance:
   - **Tapping the corner casts the full demonstration onto the writing canvas, once** — the same `StrokeOrderAnimation` rendered as a **faint ghost (~0.24 opacity)** over `StrokeCanvas` so the child can trace *along with* the moving pen-tip, while the tutor switches to `write` and says "Watch — start at the dot." When it finishes (~1.6s) the ghost fades and the corner resumes its quiet loop.
   - Implement the cast as a one-shot overlay in a `Stack` wrapped in `IgnorePointer` so it never steals stylus input. **No mode toggle, no persistent state** — one element, two depths of help (glance in the corner, or trace-along on the canvas).

`_ShowFixPhase` reuses the same three-zone frame: tutor `tryAgain` + coral voice bubble left, the child's last ink center, the Watch-Me corner top-right, **Show Me Again** (ghost, casts) + **Try Again** (primary) in the action row.

## Sound — "Hear the letter" (NEW; owner-requested, pulls Phase-7 audio forward)
- Add a **Sound section** in the Tutor panel: the vocalized glyph (`letter.name.ar`, via `ArabicText`), the romanization (`letter.name.display`), and a round **speaker button** (`QalamTargets.targetMin`, ink-teal, sticker shadow) that plays `letter.audio.letter`.
- `letter.audio` is currently `null` for every letter (Phase-7 fills it). **Wire the button + an `audioPlayer` provider now, but it's decorative until assets land** — disable/soften the button (and skip it) when `audio?.letter == null`, never crash.
- **This intentionally relaxes the old `// NO 'Play sound' (Phase 7)` rule** — the owner asked to bring it forward. Update `practice_screen_test.dart` to expect the Sound control instead of asserting its absence, and leave a comment citing this decision.

## Hard rules (most are enforced by `practice_screen_test.dart` — do not regress)
- **Anti-gamification:** no weekly bar, no star tally, no running counter, no "+N keep going" hype, no confetti, no "Mark correct", no "See journey" on this screen. Stars are mastery markers only and live elsewhere. *(The "no Play sound" item is now lifted — see Sound above.)*
- **Color:** `QalamColors.bg` (parchment, never white) background; `QalamColors.inkStroke` for ink; **gold (`reward`) only** for the start-dot / pen-tip; **coral (`warnSoft`) is the only error color — no red**; text `QalamColors.fg` (not black).
- **Buttons:** primary = ink-teal pill with the flat-bottom sticker shadow (`QalamShadows.buttonShadow` → `buttonShadowPressed` on press); ghost = 2px primary outline. Reuse the existing `_PrimaryButton` / `_GhostButton`.
- **Type / RTL:** chrome stays LTR; Arabic only via `ArabicText` (Noto Naskh, vocalized, never bold/italic, sized ≥ adjacent English). Western numerals everywhere.
- **Targets:** every interactive element ≥ `QalamTargets.targetMin` (64), ≥ `QalamSpace.space4` (16) apart. The canvas stays the largest element; mascot and corner demo must not crowd it.
- **Security (T-03-01 / T-01-05):** stroke points stay in `StrokeCanvas` State — only `StrokeResult` reaches the controller. The ghost cast reads `referenceStrokes` only; never lift raw child points to provider scope.

## Template / data
- Drive **every** visual from `letter.referenceStrokes` + `letter.char` / `letter.name`. Do not hardcode alif's geometry or glyph in the layout — the same widget must render any letter.
- Today only `alif` (`lesson_01`) has authored `referenceStrokes`; the other 27 are placeholders (empty strokes). Handle an empty-stroke letter gracefully (guide/demo simply show nothing — no crash), so the layout is ready as curriculum data lands.

## Reference mockup
A visual of the target layout sits beside this file (`mockup.html`) — open it in a browser and use the four **Tutor states** switcher at the bottom (Coaching / Thinking / Feedback / Praise) to see the tutor's voice + poses, and **tap the "Watch Me" corner** to see the cast-onto-canvas behavior. It shows: the Tutor panel (mascot + speech bubble + Sound section) left, heading + clean-rep pips, the large writing canvas with gold start-dot and deep-ink trace, the docked **Watch Me** demo top-right with "Tap to show me here", and the **Clear** button. Match its proportions and hierarchy; pull exact values from the theme tokens, not the mockup's CSS.

## Acceptance check
- [ ] `_TracePhase` is a three-zone Row: **Tutor panel** left (mascot pose + voice bubble + Sound), `StrokeCanvas` center (hero), `StrokeOrderAnimation` docked top-right.
- [ ] Feedback + praise are delivered **in the tutor's speech bubble** (coral fix / leaf praise, authored strings), with a visible `think`-pose "thinking" beat during scoring. No separate center feedback panel.
- [ ] Corner demo loops as glance-reference; **tapping it casts a one-shot ~0.24-opacity ghost over the canvas** via an `IgnorePointer` `Stack`, then returns to the corner. **No corner/canvas toggle.**
- [ ] **Hear-the-letter** speaker control present in the Sound section; wired to `letter.audio`, gracefully disabled when null; `practice_screen_test.dart` updated to expect it.
- [ ] **Clear** resets the current attempt; capture, scoring, state machine, advancement still pass.
- [ ] Tokens only; anti-gamification intact; gold = start-dot/pen-tip only; coral (no red); parchment bg; Arabic via `ArabicText`.
- [ ] Layout is letter-agnostic (driven by `referenceStrokes`); empty-stroke placeholder letters don't crash.
- [ ] Nothing clipped in landscape; targets ≥64px, ≥16px apart; canvas remains the largest element.
