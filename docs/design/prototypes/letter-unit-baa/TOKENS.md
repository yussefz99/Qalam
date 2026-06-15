# TOKENS.md — tokens & styles used

**Source of truth:** `docs/design/kit/project/colors_and_type.css`. The prototype uses that palette,
type, radii, shadows, and motion. This file lists exactly what was used and — honestly — **where the
prototype deviates** so it can be reconciled before Flutter.

---

## ⚠ Top deviation to reconcile first
The prototype **re-declares a subset of the kit palette locally** in
`prototype/shared/core.css` (`:root{…}`) and in `prototype/letter-unit/unit.css`, instead of
`@import`-ing `colors_and_type.css`. Values match the kit, but two **names drift**:

| Prototype name | Kit name | Action |
|---|---|---|
| `--gold` | `--gold-ink` (alias `--reward`) | rename to `--gold-ink` |
| `--white` | `--surface-raised` (`#FFFFFF`) | rename to `--surface-raised` |

**Fix:** delete the local `:root` palette block and `@import url('…/colors_and_type.css')` at the top of
`core.css`; rename the two vars. No visual change — the values are identical.

---

## Colors used (all from the kit)
- **Ink/parchment:** `--parchment` (bg), `--soft-aqua` (surfaces), `--surface-raised` `#FFFFFF` (cards/canvas).
- **Primary:** `--ink-teal` (actions, child's ink), `--deep-ink` (pressed, headers, Arabic glyphs).
- **Reward:** `--gold-ink` — **rewards only** (the start-dot, the one mastery star). Honored: gold appears nowhere else.
- **Success:** `--leaf` (+`--leaf-tint`) — pass panel, ghost-correction path.
- **Soft-warn:** `--coral` (+`--coral-tint`) — the fix panel & try-again mascot. Never harsh red.
- **Text:** `--fg` (`--ink-charcoal`), `--fg-muted` (`--slate`).
- **Tints/edges:** `--teal-tint`, `--teal-wash`, `--aqua-edge`, `--parchment-edge`, `--parchment-deep`, `--gold-tint` — surfaces, borders, chips.

## Type used (all from the kit)
- `--font-display` Fredoka — UI headings, buttons, mascot speech.
- `--font-body` Nunito — labels, captions, body.
- `--font-arabic` Noto Naskh Arabic / Cairo — **all** Arabic glyphs & words, always in `dir="rtl"`.
- Scale: prototype Arabic glyph on canvas ≈ `--fz-ar-display` (96px) and larger for the trace hero;
  English headings map to `--fz-34`/`--fz-28`. Arabic always sits larger than nearby English, per kit.

## Radii / elevation / motion (all from the kit)
- Radii: cards `--radius-xl` (28), controls `--radius-md/-lg` (14/20), pills `--radius-pill`.
- Shadows: `--shadow-sm/-md/-lg`; primary buttons use the **sticker** `--shadow-button` (flat-bottom,
  press-down). Matches the kit values verbatim.
- Motion: `--ease-out-quart`, `--ease-soft-back`; durations align with `--dur-fast/base/slow/cheer`.

---

## NEW tokens introduced (additions to reconcile)
**No new *color* tokens** — every color resolves to a kit token (post-rename). The additions are
**component-level constants** the kit doesn't yet name. Recommend promoting these to tokens:

| Prototype value | Where | Suggested token |
|---|---|---|
| writing-canvas glyph guide color `#C7DCDC` | WriteSurface given-ink | `--ink-guide` (between `--aqua-edge` and `--teal-wash`) |
| trace dotted-guide dash `1 13` / stroke `3.4` | WriteSurface guide | `--guide-dash`, `--guide-stroke` |
| child ink stroke width `12px`, color `--deep-ink` | WriteSurface canvas | `--ink-stroke-w`, `--ink-color` |
| button heights 60 / 64 / 66px | CTAs | map to kit `--target-min` (64) — **align to 64** |
| start-dot radius `14px` gold | trace guide | `--start-dot` (uses `--gold-ink`) |

These are the only places the prototype "invented" numbers; all are small and map cleanly onto the
existing 4px spacing / target-size scale.

---

## For Flutter
Define the kit `:root` values as a `QalamTokens` Dart constants class (one-to-one). The prototype's
sticker-button (`--shadow-button` + press translate) = a `Material` with a custom bottom `BoxShadow`
that collapses on `onTapDown`. The Arabic-larger-than-English rule should be a `TextTheme` policy, not
per-widget overrides.
