---
status: complete
quick_id: 260602-bw1
description: Rebuild the remaining demo walkthrough screens (Watch/Trace/Feedback/Celebration) faithful to the Claude Design mockups; switch the loop to Baa for coherence with the rebuilt Home
date: 2026-06-02
commits:
  - e24962a  # foundation: DemoBaa, shared chrome, painter start-dot/diacritic
  - 672164e  # Watch
  - c576cbb  # Trace
  - ec29403  # Feedback (miss + pass)
  - 326c221  # Celebration
---

# Quick Task 260602-bw1: Demo walkthrough faithful to the mockups (Baa)

**Rebuilt the four remaining presentation-demo screens — Watch, Trace, Feedback
(miss + pass), Celebration — 1:1 with the Claude Design mockups, exactly as the
demo Home was just rebuilt. The tappable Home → Watch → Trace → Feedback·miss →
pass → Celebration → Home loop has no dead ends; analyze is clean; the suite is
green except the pre-existing `glyph_audit_golden_test` (D-12).**

## Key decision — the demo loop is now BAA end-to-end

The rebuilt demo Home shows **"The letter Baa" (ب)** and every walkthrough mockup
(`screenshots/02-*` … `05-*`) says *baa* ("Watch me write baa", "Now you trace
baa", "You learned the letter baa"). The previous walkthrough screens + copy were
**Alif**, which made the live demo incoherent (tap "Baa" → "Watch me write
Alif"). The whole loop was switched to Baa for fidelity + coherence.

- Added `lib/demo/demo_baa.dart` (`DemoBaa`) — the static, engine-free Baa source
  (boat reference stroke sampled from the kit's baa path + the distinguishing
  diacritic dot + glyph + authored tutor-voice miss/pass copy). `DemoAlif` is left
  untouched (its own unit + painter tests stay green).
- Updated the six Baa-relevant `demo*` copy values in `app_en.arb` and updated
  the one test that pinned Alif copy — `test/l10n/demo_copy_test.dart` — so the
  full suite stays green. (Required because the copy contract lives outside
  `test/demo/`.)

## What changed

- **`lib/demo/widgets/demo_chrome.dart`** (new) — shared walkthrough chrome + UI
  building blocks: nav rail (Home active) + header (avatar, gold **star count**,
  settings, optional ×), `DemoEyebrow`, the keyed sticker `DemoPrimaryCta`,
  `DemoGhostButton` (outline / filled-secondary, scale-down-fit so it never
  overflows a narrow side card), `DemoAquaCard`, `DemoCanvasCard`,
  `DemoCanvasChip`, `DemoProgressBar`, `DemoStarIcon`, `demoGlyphStyle`.
- **`lib/demo/widgets/dotted_guide_painter.dart`** — extended (back-compatible
  defaults) with an optional numbered **gold start-dot** and **diacritic dots**;
  existing painter test untouched and green.
- **`lib/demo/screens/demo_watch_screen.dart`** — `DemoScreen` mockup: write
  mascot + white canvas painting the dotted baa guide (gold "1" start-dot +
  diacritic, **painted, never `Text('ب')`**) + aqua TIP card with *Hear the
  sound* / *Replay* (owner override) + **Start Tracing** → `/demo/trace`.
- **`lib/demo/screens/demo_trace_screen.dart`** — `TraceScreen` + `TracingCanvas`
  mockup: *Stroke 1 of 1* gold progress + idle mascot + canvas with the
  half-traced deep-ink overlay + aqua LISTEN card (baa via `ArabicText` + *Play
  sound*) + decorative *Try again* / *Mark correct* + **Next** → `/demo/feedback`.
- **`lib/demo/screens/demo_feedback_screen.dart`** — derived from the brand
  feedback tokens: **MISS** = CORAL failing stroke (`warnSoft`, **never red**) +
  "Let's fix this" chip + the specific named fix + **Try Again** →
  `/demo/feedback/pass`; **PASS** = LEAF clean stroke + "Beautiful work" +
  specific praise + **Continue** → `/demo/celebration`. No counter.
- **`lib/demo/screens/demo_celebration_screen.dart`** — `CompleteScreen` mockup
  (**gamification, owner override**): earned three gold stars, rotated teal
  **MASTERED** stamp over a giant gold baa glyph on a soft halo, cheer mascot +
  still confetti, running **TOTAL 42 stars / +3 today**, header star **42**, *See
  journey* (decorative) + **Back Home** → `/demo/home`.
- Tests: the four `test/demo/*_screen_test.dart` rewritten for the faithful Baa
  layouts (each keeps a keyed-CTA navigation test); `test/demo/demo_baa_test.dart`
  added; `test/l10n/demo_copy_test.dart` updated to Baa.

## ⚠ Owner override — anti-gamification reversal (carried forward)

Per Rami's explicit instruction, the walkthrough is faithful to the mockups
**including** the gamification chrome (header star count, three-star rating,
progress bars, running totals, "+3", confetti, MASTERED stamp). This continues
the reversal already applied to the demo Home and **contradicts** CLAUDE.md's
"Decided" anti-gamification rule. **Follow-up for the owner:** reconcile CLAUDE.md
(and the "Real Arabic. Not a game." narrative) with the demo's gamified
presentation. The one brand rule kept intact: the miss/error treatment is **coral
(`QalamColors.warnSoft`), never red.**

## Verification

- `flutter analyze` (whole project) → **No issues found.**
- `flutter test test/demo/ test/router/demo_routes_test.dart test/l10n/demo_copy_test.dart`
  → **40/40 green** (incl. the full-chain "home→…→celebration→home never hits
  errorBuilder" route test — no dead ends).
- Full suite: **105 pass, 1 fail** = the pre-existing `glyph_audit_golden_test`
  (D-12, font-rasterization golden, unrelated).

## How to view

`flutter run --dart-define=DEMO=true` → boots at `/demo/home`; tap the lesson
card and walk the full Baa loop. For the presentation device:
`flutter build apk --dart-define=DEMO=true`.

## Notes

- Generated `lib/l10n/app_localizations*.dart` are gitignored — regenerated via
  `flutter gen-l10n`, not committed.
- Side-by-side layouts use `Wrap` so they render as one row on the tablet
  (landscape ~1280 wide) and gracefully wrap (never overflow) in the 800×600 test
  viewport. Audio / Replay / Mark-correct / See-journey are decorative (no routes
  in the mocked demo, DP-01); only the keyed primary CTA per screen navigates.
- Executed inline, sequential TDD (red→green→atomic commit per screen) rather
  than a parallel workflow: the screens are tightly coupled through one
  `app_en.arb`, the shared painter, the shared chrome, a `gen-l10n` regen, and
  verification gates that must run on the merged tree — so fan-out would add merge
  risk with no real parallelism benefit.
