# HANDOFF.md — Letter Unit “baa (ب)”

Design → engineering handoff for the baa Letter Unit, built as **one component engine, every question
as config**. Stage B. RTL, landscape tablet, handwriting-first.

---

## What's in this folder
```
letter-unit-baa/
├─ index.html                 ← open this. Landing → both prototypes + all docs
├─ prototype/
│  ├─ shared/                 core.css, core.js  (tokens + mascot + the reused ink/trace canvas)
│  ├─ letter-unit/            the 6-section unit  (index.html, unit.css, unit.js)
│  └─ exercise-components/    the 5 components + config gallery  (index.html, components.{css,js}, gallery.js)
├─ assets/                    mascot/*.svg, star.svg, README.md  (real vs placeholder)
├─ COMPONENTS.md              the 5-component inventory (+ the reused canvas; 0 new structural components)
├─ SCHEMA-BINDINGS.md         every element → its Exercise field, + the fields the spec is missing ⚠
├─ EXERCISE-CONFIGS.json      concrete baa configs in the canonical Exercise shape (19 exercises)
├─ TOKENS.md                  tokens used + name drifts to reconcile
├─ CHANGES.md                 owner edits, deviations, and the 8 open pedagogy TBDs
└─ HANDOFF.md                 ← you are here
```

## How to view
Open **`index.html`** in any modern browser (Chrome/Safari/Edge). No build step, no server — static
HTML/CSS/JS. From the landing, open **The baa Letter Unit** (the experience) and **Exercise Components**
(the engine). In the gallery, the **Show config** button (top-right) reveals, per screen, which of the 5
components render and the exact config object behind them. Draw on any white canvas with mouse/stylus.
*(Fonts load from Google Fonts CDN — view online, or self-host for offline.)*

## Component → schema, in one paragraph
Every question decomposes into **prompt** (how the child is cued) → **WriteSurface** (what they write) →
**check** (how it's validated) → **FeedbackPanel** (pass/fix), hosted by **ExerciseScaffold** with a
**ProgressRibbon**. The frontend reads `prompt` + `surface`; the backend reads `expected` + `check`. A
"question type" is just a set of values in the `Exercise` shape (`COMPONENT-SYSTEM.md §3`) — so 6 types +
2 support screens are **8 configs over the same 5 components**, and a new type is a new config row, never
new UI. `EXERCISE-CONFIGS.json` is that data for baa; `SCHEMA-BINDINGS.md` maps every element to its field.

---

## For the engineer

### (a) Locking the data schema — read `SCHEMA-BINDINGS.md §C` first
The `Exercise` shape holds. But the prototype needed **10 additive fields the spec doesn't yet express**
— decide each before locking:
- `feedback.pass` (praise line) · `surface.reps` (clean-rep count) · `surface.demo` (Watch-me) ·
  `surface.ghost` (green correction) · `text.reveal`/`text.loose` modifiers · `prompt.kind:"forms"` ·
  optional `type` tag · `check` as string-grammar vs structured · `policy.noFail` (letterMaze) ·
  a `Unit`/`Lesson` wrapper that owns section order (drives `ProgressRibbon`).

All are additive on `surface`/`feedback`/`prompt` + a thin Unit object. None change the components.

### (b) Rebuilding in Flutter — reuse existing widgets
- **WriteSurface** wraps your **existing ink/trace canvas** (the Practice-screen scorer) — don't rebuild
  it; add `mode`/`unit`/`given`/`guideForm` props. It's the only real engineering primitive here.
- **Mascot** = existing avatar, states `idle/think/write/cheer/try-again` (vectors in `assets/mascot/`).
- The other 4 components are layout + state: `ExerciseScaffold` (RTL Scaffold), `PromptHeader`
  (a `Row`/`Wrap` of PromptPart widgets), `FeedbackPanel` (two states), `ProgressRibbon` (dots).
- **Validators:** one geometric **`glyph`** scorer (exists) + thin **`sequence`** / **`order`** wrappers
  + rule checks (`positionalForm`, `joinContinuity`, `transformRule`). See COMPONENT-SYSTEM.md §6.
- **Tokens:** map the kit `:root` to a `QalamTokens` class; fix the two name drifts (TOKENS.md).

### Production-ready vs placeholder
| Production-ready | Placeholder (owner/curriculum) |
|---|---|
| The 5 components & their states | **Audio** — every Play button is silent (maps to `audioId`) |
| Trace surface, stroke animation, ghost-correction, celebration (match existing) | **Illustrations** — picture prompts are hatched stubs (map to `imageId`) |
| Mascot poses & the one quiet star | **Vocab / sentences / grammar answers** — drafts, not the mother's final content |
| The config shape & 19 baa configs (structure) | **`feedback` lines** — prototype-authored; `signedOff:false` everywhere |
| Tokens, RTL layout, handwriting-first interactions | **Trace geometry** — one approximate baa path; needs per-form reference strokes |

### Open questions that block locking the schema
- **Shape-blocking:** the 10 fields in `SCHEMA-BINDINGS.md §C` (decide & add).
- **Content-blocking (not shape):** the **8 pedagogy TBDs** in `CHANGES.md §5` — all OPEN, awaiting the
  owner's-mother. They fill `EXERCISE-CONFIGS.json` values and flip `signedOff`; they don't change the schema.

---

### A note on delivery
This package was authored in the Qalam **design** project and could not be pushed to the repo from here.
Drop the `letter-unit-baa/` folder into `docs/design/prototypes/` on `main` as-is — paths are relative
and self-contained.
