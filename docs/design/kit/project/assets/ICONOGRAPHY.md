# Iconography — Qalam

## Approach

Qalam's icons are **outlined, rounded, single‑weight (2px stroke at 24px)**, with rounded line caps. They sit next to Fredoka without competing — both have generous corner radii and a friendly default.

Three tiers, in priority order:

1. **Brand glyphs** (custom SVG in `assets/icons/`). These are the named, emotional marks: star, ink drop, lock (journey‑gated), check (journey‑complete), qalam‑nib. They are **never** substituted with a CDN icon.
2. **General UI icons** — pulled from [Lucide](https://lucide.dev). Lucide's 2px stroke, rounded caps, and 24px viewBox align with Qalam's vocabulary. Load from CDN: `<script src="https://unpkg.com/lucide@latest"></script>`.
3. **Mascot states** (`assets/mascot/qalam-*.svg`). The mascot is illustration, not iconography — but it lives in the same folder. Five states ship as **placeholders**: idle, cheer, think, write, try‑again. Replace with illustrator‑authored versions before launch.

## Substitution flag

The Lucide set is a **stand‑in** for a future custom icon family drawn in the brand's stroke style. When the custom set is drawn, swap CDN icons one for one; component code references icons by semantic name, not by file path, so this swap is a single import change.

## Emoji & unicode

- **Emoji are not used** anywhere in the product, ever. Not in tooltips, not in error states, not in cards.
- **Unicode pseudo‑icons** (⭐ ✓ ✗) are not used either. Reward = `assets/icons/star.svg`. Correct = `assets/icons/check-complete.svg`. Try‑again has no glyph at all — it's a coral chip and a soft animation.

## Mascot vs icon

The reed‑pen mascot is the only character in the product. He is **not** an icon — he is a 200×280 figure with multiple states and a personality. Don't shrink him under 80px tall; for sizes below that, use the qalam‑nib pictogram (`assets/icons/qalam-nib.svg`) instead.

## Files

```
assets/
├── logo.svg                  ← stacked Arabic + EN wordmark
├── logo-horizontal.svg       ← horizontal lockup
├── icons/
│   ├── star.svg              ← gold reward star (brand, never substituted)
│   ├── ink-drop.svg          ← "magic" motif
│   ├── lock.svg              ← journey-map: locked
│   ├── check-complete.svg    ← journey-map: completed
│   └── qalam-nib.svg         ← small brand mark
└── mascot/
    ├── qalam-idle.svg
    ├── qalam-cheer.svg
    ├── qalam-think.svg
    ├── qalam-write.svg
    └── qalam-try-again.svg
```

## Standard sizes

- Inline UI icon (button, list): **24px**
- Touch‑target icon (nav, lesson card): **32–40px**
- Reward star in a chip: **24px**; on the celebration screen: **96–160px**
- Journey lock/check node: **48px**
- Mascot: **120–280px** depending on prominence
