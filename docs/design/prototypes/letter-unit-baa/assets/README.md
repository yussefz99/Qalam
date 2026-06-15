# Assets — `letter-unit-baa`

Every asset used by the prototype. **Real** = production-usable as-is. **Placeholder** = a stand-in
for content the owner / curriculum must supply; the prototype renders it as an obvious stub.

## Mascot — `mascot/` · REAL (vector, reusable)
The reed-pen tutor "Qalam", one SVG per reactor state. These match the existing built screens and
are the canonical poses for the Flutter `Mascot` widget. Inline copies live in `prototype/shared/core.js`
(`Q.M`) and `prototype/letter-unit/unit.js` (`M`).

| File | State | Used when |
|---|---|---|
| `mascot/idle.svg` | `idle` | neutral prompt, waiting |
| `mascot/think.svg` | `think` | validating the child's strokes ("let me look…") |
| `mascot/write.svg` | `write` | demonstrating / Watch-me |
| `mascot/cheer.svg` | `cheer` | pass / praise / mastery |
| `mascot/try-again.svg` | `try-again` | a specific fix (coral) |

## Star — `star.svg` · REAL
The single quiet reward star (gold). One per mastered unit. **No counts, no streaks** — see CHANGES.md.

## Icons · REAL
UI glyphs (speaker, replay, arrow, check, trash, lock, pen-nib) are inline SVG in the source
(`Q.IC` in `core.js`). They are standard line icons, safe to replace with the app's icon set.

## Audio · PLACEHOLDER ⚠
Every speaker / "Play" button is **visual-only** — it pings on tap, plays nothing. Each maps to a
schema `prompt[].audioId` (see SCHEMA-BINDINGS.md). Real recordings (letter sound, word, sentence,
instruction) are an owner/curriculum deliverable. Suggested ids: `snd.baa`, `word.baab`, `word.batta`,
`word.haliib`, `word.kitaab`, `sentence.albaab-kabiir`.

## Word / sentence illustrations · PLACEHOLDER ⚠
Picture prompts render as a hatched box with a text label (e.g. `illustration: duck (baṭṭa)`). Each
maps to `prompt[].imageId`. Real art is an owner/curriculum deliverable. Suggested ids: `img.door`,
`img.duck`, `img.milk`, `img.big-door`.

## Fonts · REAL (CDN)
Fredoka (display), Nunito (body), Noto Naskh Arabic + Cairo (Arabic) — loaded from Google Fonts,
matching `docs/design/kit/project/colors_and_type.css`. Self-host for production.

## The trace guide geometry · REAL (prototype-grade)
The baa stroke path (`Q.BAA_PATH` in `core.js`) drives the dotted guide, the animated demo, and the
green ghost-correction. It is a **single quadratic approximation** good enough to demonstrate the
mechanic — the production glyph scorer needs per-form reference strokes (see CHANGES.md / COMPONENTS.md
`WriteSurface`).
