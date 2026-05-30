# Qalam Design System

> **Qalam** (قلم — "pen") is a Kumon‑style Arabic‑learning app for diaspora children in grades 1–6, built on a real teaching curriculum. It runs on tablet + stylus (Flutter on Android for v1) and centers on **stylus letter‑tracing with instant feedback** taught by a friendly reed‑pen mascot also named Qalam.

This repo is the **visual prototyping and spec system** for Qalam. Web (HTML/React/CSS) is the durable artifact; the approved tokens, components, and screens here translate into a Flutter `theme.dart` in a follow‑up step.

---

## At a glance

| | |
|---|---|
| **Product** | Qalam — Arabic letter‑tracing & lesson app |
| **Audience** | Children 6–12 whose stronger language is English; also parents (profiles, progress) and later teachers |
| **Form factor** | Tablet, stylus, single orientation for v1 |
| **Direction** | App chrome **English / LTR**; Arabic appears only as **RTL content islands** inside lessons (`dir="rtl"`) |
| **Numerals** | Western (0–9) **everywhere**, including inside Arabic content |
| **Mascot** | "Qalam," a friendly reed‑pen who demonstrates stroke order by writing letters himself |
| **Aesthetic** | "Modern manuscript / playful calligraphy studio" — warm parchment, ink‑teal + gold, rounded tactile shapes |

---

## Source materials

The design system was generated from a brief + style tile prepared by the Qalam team. Everything here is derived from those documents (no Figma file or codebase was attached — the Flutter app is downstream of this kit).

- `uploads/Qalam_Brief.md` — the source‑of‑truth brief (palette, type, kids‑UX floor, deliverable list).
- `uploads/Qalam_Claude_Design_Setup_Package.md` — the longer setup package (app snapshot, screen list, validation checklist, generation sequence).
- `uploads/Screenshot 2026-05-24 at 6.35.55 PM.png` — style tile: palette swatch with hex values.
- `uploads/Screenshot 2026-05-24 at 6.36.04 PM.png` — style tile: typography specimens (Fredoka, Nunito, Noto Naskh Arabic, Cairo).
- `uploads/Screenshot 2026-05-24 at 6.36.12 PM.png` — style tile: Western numerals + component snippets (Start lesson button, +5 stars chip, try‑again chip, gold progress bar).

No external Figma URLs or GitHub repos were provided.

---

## Index — what's in this folder

```
README.md                ← this file
SKILL.md                 ← skill manifest for Agent Skills / Claude Code
colors_and_type.css      ← tokens: CSS vars for colors, type, spacing, radii, shadows, motion
fonts/                   ← (loaded via Google Fonts CDN in colors_and_type.css — see "Fonts")
assets/                  ← logos, mascot placeholders, illustrations
preview/                 ← design‑system preview cards (Type, Colors, Spacing, Components, Brand)
ui_kits/
  └── qalam_app/         ← tablet app UI kit: index.html + JSX components
uploads/                 ← original brief, setup package, style‑tile screenshots
```

---

## Content fundamentals

**Voice = a kind teacher, kneeling at the child's level.** Qalam talks *to the child* in second person ("You did it!", "Trace each letter") and refers to itself as itself ("Qalam will show you"). Parents see a more measured, factual voice in the parent area, but the same warmth.

**Casing**
- Buttons and headings: **Title Case** ("Start Lesson", "Today's Lesson", "Let's Try That Again"). Display font is Fredoka so even bold copy reads friendly.
- Section labels and meta: ALL CAPS with `letter‑spacing: 0.04em` (used sparingly — nav category headers, "ARABIC · LEARNING CONTENT" style tags).
- Body sentences: sentence case, no shouting.

**Tone, by example**
- Action: "Start Lesson" — never "Begin", "Launch", "Start Now".
- Reward: "+5 stars · Keep going!" — never "Achievement unlocked" or scoreboards in points.
- Soft error: "Let's try that again." — never "Wrong", "Incorrect", "Error".
- Encouragement (mid‑exercise): "Nice line.", "Almost — start at the dot.", "Listen and try again."
- Parent‑facing: "Layla finished 3 lessons this week. Stroke order is steady; pronunciation is the area to practice."

**Person & pronouns.** Speak to the child as **"you"**. Refer to the mascot by name ("Qalam") or as **"I"** when it speaks ("Watch me write it."). Parents read about their child by name ("Layla earned 5 stars").

**Numerals.** Always Western (0–9). Don't switch to Arabic‑Indic numerals even inside Arabic blocks — diaspora kids are reading English digits everywhere else.

**Emoji.** **Not used in chrome.** The mascot, the gold star, and the ink‑drop motif are our emotional vocabulary. The only place a star glyph appears is as the reward icon (and it is the brand's gold star, not the unicode ⭐).

**Length.** One idea per line, one task per screen. Headings ≤ 6 words. Button labels 1–3 words. Mid‑lesson coaching ≤ 8 words. Parent reports can be longer but stay short‑sentence.

**Vibe.** Warm like Khan Academy Kids. Clear like Amal. **Not** clinical, **not** gamified‑points‑casino, **not** babyish. The child should feel a calm tutor sat down next to them.

---

## Visual foundations

### Color
A nine‑swatch "ink & parchment" palette. **Parchment** (`#FAF6EE`) is the canvas everything sits on — warm, never `#FFFFFF`. **Ink Teal** (`#168A8F`) is the workhorse: every primary CTA, every "learning" state. **Deep Ink** (`#0E5B5F`) is its pressed/dark sibling — used for pressed shadows on buttons and for major headers on parchment.

**Gold Ink** (`#F2A60C`) is sacred. It is *only* for rewards — stars, the celebration bar after a completed lesson, the +N‑stars chip, ink‑drop confetti. **Never** for primary actions, never as a button color, never as a heading color. If gold appears, something good just happened.

Semantic feedback uses **Leaf** (`#3FB984`) for correct and **Coral** (`#FF8A6B`) for soft "try again". Red is banned. Errors are coral, soft, and paired with a gentle wiggle — never a red X.

Text is **Ink Charcoal** (`#222A2E`) — not pure black, so it sits inside the warm world instead of stamping on top of it. **Slate** (`#5C6B70`) is for secondary copy.

All combinations meet WCAG AA: 4.5:1 for body, 3:1 for large/UI.

### Type
Two systems, paired on the same screen:

- **English UI** — `Fredoka` for display, headings, and buttons; `Nunito` for body, labels, captions. Fredoka is rounded and friendly without being babyish; Nunito's open counters keep small body text legible at tablet distance.
- **Arabic content** — `Noto Naskh Arabic` for reading and tracing content (schoolbook‑correct letterforms, clean diacritics); `Cairo` for the قلم wordmark and short Arabic display headers.

**Arabic content rules — non‑negotiable**
- Arabic content set **10–25% larger** than adjacent English (e.g. 20px English → 26px Arabic).
- Line‑height **1.7** for plain Arabic; **2.0** when tashkeel is present.
- **Never bold, never italic** on Arabic. Hierarchy comes from weight steps (Regular → Medium → SemiBold) and size.
- All learning content is **fully vocalized (tashkeel)** — diaspora kids cannot infer the vowels.
- Numerals stay Western inside Arabic; wrap them in `.q-num` (LTR isolate).

### Spacing & layout
4px base scale (`space-1` = 4px, doubling through `space-24` = 96px). Tablet layouts use generous whitespace — `space-8` (32px) between major blocks, `space-12` (48px) for hero margins. Touch targets are **64px minimum, 72px comfortable, 96px for hero CTAs**, with **≥16px between targets**. One task per screen — never crowd.

### Radii
Tactile, rounded — nothing sharp. `8 / 14 / 20 / 28 / 36 / pill`. Buttons are pill or 28px; cards are 20–28px; the tracing canvas is 28px.

### Elevation
Soft, low, ink‑colored shadows — never grey, never glossy. Two shadow systems coexist:
1. **Card shadow** — composite, low‑offset, tinted in Deep Ink at ~6–24% alpha. Two‑layer (1px ambient + larger Y‑offset blur) so cards feel placed on parchment, not floating in space.
2. **Sticker‑press button shadow** — `0 4px 0 var(--deep-ink)`. Solid, flat‑bottom, no blur. On press, drops to `0 1px 0` and the button translates 3px down — that satisfying "sticker" feel kids love. No drop shadow blur on primary buttons.

### Backgrounds & motifs
- App background: solid Parchment. No gradients, no noise, no purple‑gradient AI slop.
- Surfaces: Soft Aqua (`#EAF4F4`) or white. Cards are clean rectangles with a 20–28px radius and the card shadow above.
- Sparing motif: an **ink‑drop** (small gold or teal teardrop) and **subtle geometric flourishes** at slide intros or celebration moments. Used like a flourish in a manuscript — once per screen, never as wallpaper.
- The mascot Qalam stands on parchment without a container. He owns negative space.

### Borders
Borders are rare. When used: `1px solid var(--border)` (Aqua Edge `#D6E8E8`) on neutral surfaces, or `1px solid var(--border-soft)` (Parchment Edge `#E8DFC9`) on warm surfaces. No borders on primary buttons — they live on shadow and color alone.

### Hover & press
*Tablet is the primary surface, so press matters more than hover, but the kit supports both for web preview.*
- **Hover** (web/cursor): primary buttons get a subtle lightness lift (1–2% brighter teal); cards rise 2px with a softer shadow.
- **Press**: primary buttons translate `translateY(3px)` and the sticker shadow shrinks to `0 1px 0` — the button "punches down". Cards scale to `0.98` and the shadow flattens. Both transitions are ~140ms `ease-out-quart`.

### Animation
- **Easing**: `--ease-out-quart` for entrances; `--ease-soft-back` (gentle overshoot) for celebration moments only; `--ease-in-out` for state transitions.
- **Durations**: `140ms / 220ms / 420ms / 700ms`. The 700ms slot is reserved for cheer/celebration sequences.
- **Try‑again feedback**: a 6px ±3 horizontal wiggle over 220ms, never a flash or shake‑violent.
- **Stroke‑order demo**: the mascot draws the letter as an animated stroke path (CSS stroke‑dashoffset or Lottie). Always at a teachable pace — kids should be able to follow the nib.
- **Reward**: gold ink confetti + +N‑stars chip slides up with `ease-soft-back`. Reserved.
- No parallax, no scroll‑linked animation, no looping idle animations that compete with the lesson.

### Transparency & blur
Used very sparingly. The only built‑in transparent surface is the **parent gate** scrim (a 60% Ink Charcoal overlay with 8px backdrop blur) — and even that is rare. The rest of the system is opaque.

### Imagery
Warm. Slight cream cast. No high‑contrast B&W, no cold blue photography, no synthetic gradients. Illustrations live on Parchment; the mascot Qalam carries the warmth.

### Cards
Default card: white or Soft Aqua, `border-radius: 20–28px`, `--shadow-md`, no border. The corner radius scales with the card's role — small chips at 14px, lesson cards at 20px, the tracing canvas at 28px.

### Fixed elements
- Top app bar on lesson screens: 72px tall, parchment, mascot avatar + lesson title + close button. Sticks during scroll within a lesson.
- Bottom action area on lesson screens: parchment with a soft top border, holds the single primary action. ≥120px tall to comfortably fit a 72–96px CTA.

---

## Iconography

See **`assets/ICONOGRAPHY.md`** for the full guide. Short version:

- Outlined, rounded, single‑weight (2px stroke at 24px) icons. The closest match on a CDN is **[Lucide](https://lucide.dev)** — that's what we use until a custom set is drawn. Lucide's stroke weight and rounded line‑caps sit cleanly next to Fredoka.
- The few **brand glyphs** (gold star, ink drop, qalam‑nib pictogram, journey lock/checkmark) are hand‑drawn SVGs in `assets/icons/` — these are the named reward and progression marks and should never be substituted by Lucide.
- The **mascot** is a separate asset family in `assets/mascot/` (placeholder SVGs until a real illustrator is engaged — see Caveats).
- **Emoji are not used.** Unicode glyphs (⭐ ✓ ✗) are not used either. We have our own marks for every emotional moment.
- For Arabic content tracing, the future plan is a dotted/outlined tracing font (e.g. Namela's *Alif Baa Taa*) or hand‑authored SVG outlines with start‑dots and direction arrows. This kit ships placeholder SVG outlines.

---

## Fonts

All four faces are on Google Fonts and pulled via CDN in `colors_and_type.css`:

- [Fredoka](https://fonts.google.com/specimen/Fredoka) (English display)
- [Nunito](https://fonts.google.com/specimen/Nunito) (English body)
- [Noto Naskh Arabic](https://fonts.google.com/noto/specimen/Noto+Naskh+Arabic) (Arabic learning content, with tashkeel)
- [Cairo](https://fonts.google.com/specimen/Cairo) (Arabic display / قلم wordmark)

To self‑host: download `.ttf` or `.woff2` from Google Fonts and drop into `fonts/`, then swap the `@import` in `colors_and_type.css` for local `@font-face` declarations.

---

## How to use this kit

1. Drop `colors_and_type.css` into your project's `<head>` (or import its tokens into your Tailwind config).
2. Use the semantic vars (`--primary`, `--surface`, `--fg`, `--reward`) in components — **never** hard‑code hex.
3. For any Arabic block, wrap in `<div dir="rtl" class="q-ar tashkeel">…</div>`. Wrap any digits inside that block in `<span class="q-num">3</span>`.
4. Build components from the patterns in `ui_kits/qalam_app/` and the preview cards in `preview/`.
5. When validating, run through the brief's checklist: chrome is LTR, Arabic content is RTL + vocalized + ≥22px, no bold/italic on Arabic, Western numerals, 64px+ targets ≥16px apart, gold reserved for rewards, errors are coral.

---

## Caveats

- **No production codebase or Figma file was provided.** The kit is built from the brief + style tile only. Anything beyond what the brief specifies (button press behavior, motion, parent dashboard layout, tracing‑canvas chrome) is a proposal — review and tell me where to adjust.
- **The mascot Qalam is a placeholder.** The brief calls for 5 mascot states (idle / cheer / think / write / try‑again) by an illustrator. We ship a simple geometric reed‑pen SVG so layouts are testable; commission a real illustration before launch.
- **Fonts are loaded from Google Fonts CDN** rather than self‑hosted in `fonts/`. If you need offline‑first or `flutter` asset bundling, download the `.ttf` files from the Google Fonts links above and we'll wire local `@font-face`.
- **No tracing‑outline font** was provided; the tracing‑canvas demo uses hand‑authored SVG letter outlines with start‑dots and direction arrows. A licensed outline font (Namela *Alif Baa Taa* or equivalent) is recommended before launch.
- **Icons are Lucide via CDN** as a stand‑in for a future custom set drawn in the brand's stroke style. The brand‑specific glyphs (star, ink drop, lock, qalam‑nib) are custom SVGs in `assets/icons/` and should not be substituted.
- **Teacher screens are out of scope** for v1 and not in this kit.
