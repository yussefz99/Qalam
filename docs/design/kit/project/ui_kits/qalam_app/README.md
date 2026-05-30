# Qalam — App UI Kit

A click‑through tablet recreation of the Qalam Arabic‑learning app. Renders inside `index.html` at a fixed tablet design size (1280×900, landscape) and scales to fit the viewport.

**Open `index.html` to interact.** Navigation is fake — the prototype demonstrates the visual system and shows component composition. There is no real audio, real handwriting recognition, or real lesson data.

## Screens

| # | Screen | What it shows |
|---|---|---|
| 1 | **Home / Today's Lesson** | mascot + today's prepared lesson + secondary journey entry; primary CTA |
| 2 | **Stroke‑order demo** | mascot writes الـألف; play/replay, then "I'll try" |
| 3 | **Tracing canvas (hero)** | dotted Arabic letter guide with numbered start dots and arrows; stylus traces |
| 4 | **Sentence building** | drag‑order Arabic words to build a vocalized sentence |
| 5 | **Lesson complete** | gold-star celebration with mascot cheer and +N stars |
| 6 | **Journey map** | letter nodes — complete / today / locked / future |
| 7 | **Parent area** | child progress card + this‑week summary |

## Files

```
ui_kits/qalam_app/
├── README.md
├── index.html         ← entry point with React + Babel + script imports
├── app.jsx            ← screen router + top-level layout
├── components.jsx     ← shared atoms: Button, Card, Star, ProgressBar, Mascot, AppBar, JourneyNode
└── screens.jsx        ← five lesson + home + parent screens
```

## Notes

- Tablet design size: **1280×900**. The prototype letterboxes to the viewport.
- All Arabic content is wrapped in `dir="rtl"` and fully vocalized. Western numerals throughout.
- Tracing canvas uses SVG `stroke-dashoffset` for the demo animation — production will use a real recognition engine.
- Mascot is the **placeholder** geometric reed‑pen (see `assets/mascot/`). Replace with illustrator‑authored art before launch.
