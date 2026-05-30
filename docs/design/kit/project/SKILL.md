---
name: qalam-design
description: Use this skill to generate well-branded interfaces and assets for Qalam, the Arabic-learning app for diaspora children (grades 1–6) — either production UI or throwaway prototypes/mocks/decks. Contains essential design guidelines, color and type tokens, fonts, brand assets, mascot, and a tablet UI kit.
user-invocable: true
---

# Qalam design skill

Qalam is a Kumon‑style Arabic‑learning app for diaspora children (grades 1–6) on tablet with a stylus. Visual identity: **"modern manuscript / playful calligraphy studio"** — warm parchment, ink‑teal primary, gold‑ink rewards, rounded tactile shapes. App chrome is **English / LTR**; Arabic appears only as **RTL content islands** inside lessons, fully vocalized, in Noto Naskh Arabic.

## How to use this skill

1. Read `README.md` for the full system: palette, type, content fundamentals, visual foundations, iconography, and caveats.
2. Pull tokens from `colors_and_type.css` — never hard‑code hex or fonts. Use the semantic vars (`--primary`, `--reward`, `--surface`, `--fg`).
3. For inspiration / pixel parity, study the preview cards in `preview/` and the tablet UI kit in `ui_kits/qalam_app/`.
4. For visual artifacts (slides, mocks, throwaway prototypes), **copy assets out** of `assets/` and write static HTML for the user to view. For production code, lift tokens and rules and become an expert in the brand.
5. If invoked without other guidance, ask the user what they want to design — a screen, a parent email, a marketing card, a deck. Ask 5–10 clarifying questions, then output an HTML artifact (or production code if asked).

## Hard rules — do not violate

- **Gold (`#F2A60C`) is for rewards only.** Never a button, never a heading. If gold appears, something good just happened.
- **No red.** Errors are coral (`#FF8A6B`) framed as "Let's try that again" with a soft wiggle — never a red X.
- **No emoji, ever.** No unicode pseudo‑icons (⭐ ✓ ✗). Use the brand glyphs in `assets/icons/`.
- **Arabic content rules** (non‑negotiable):
  - Wrap in `<div dir="rtl">`.
  - Use Noto Naskh Arabic, set 10–25% larger than nearby English.
  - Line‑height 1.7 for plain Arabic, 2.0 with tashkeel.
  - Never bold, never italic — weight variation only.
  - All learning content is fully vocalized (tashkeel).
- **Western numerals (0–9) everywhere**, including inside Arabic blocks (wrap digits in `.q-num` to LTR‑isolate them).
- **Kids‑UX floor**: touch targets ≥64px (72px comfortable, 96px hero), ≥16px apart. One task per screen.
- **No purple‑gradient AI slop.** No Inter/Roboto. No adult‑dashboard density.
- **Mirror only Arabic content blocks**, not the whole app — chrome stays LTR.

## Voice

Speak *to the child* in second person. Title Case on buttons and headings. Encouraging, short, one idea per line. "Start Lesson", not "Launch session". "+5 stars — keep going!", not "Achievement unlocked". The mascot, Qalam, speaks in first person: "Watch me write it."

## Files

```
README.md                ← full system; read first
colors_and_type.css      ← all tokens
assets/
  logo.svg               ← stacked wordmark
  logo-horizontal.svg    ← horizontal lockup
  icons/                 ← brand glyphs: star, ink-drop, lock, check-complete, qalam-nib
  mascot/                ← Qalam mascot, 5 states (idle/cheer/think/write/try-again) — placeholders
  ICONOGRAPHY.md         ← icon usage guide
preview/                 ← design-system cards (Type, Colors, Spacing, Components, Brand)
ui_kits/qalam_app/       ← click-thru tablet UI kit (1280×900)
  index.html             ← entry
  app.jsx                ← screen router
  components.jsx         ← Button, Star, Mascot, AppBar, NavRail, LessonCard, JourneyNode, TracingCanvas, …
  screens.jsx            ← Home, Demo, Trace, Sentence, Complete, Journey, Parent
uploads/                 ← original brief + style tile from the Qalam team
```

## Caveats

- Mascot is a placeholder; commission a real illustrator for the 5 states.
- Fonts are pulled from Google Fonts CDN; swap to local `@font-face` for offline.
- Icons beyond the brand glyphs are stand‑ins (Lucide style); a custom set should be drawn before launch.
