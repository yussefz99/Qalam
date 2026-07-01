# Qalam — Technion Presentation Deck Brief

> **Purpose of this file:** This is a complete, ready-to-build brief for **Claude Design**.
> Paste the whole thing into Claude Design (claude.ai) and ask it to build the slide deck
> exactly as specified. Every slide's content, structure, visuals, and the recurring
> architecture diagram are written out below. Everything here is verified against the
> actual Qalam codebase as of 2026-06-15 — nothing is invented.

> **Audience:** Technion course staff / reviewers. Tone: serious engineering project with
> real depth, warm product. We are running the app live on their device alongside the deck.

---

## PART A — MASTER BUILD INSTRUCTIONS (read first, applies to every slide)

### A.1 Format
- 16:9 landscape slides, presentation-grade, clean and confident — not a wall of text.
- Build as a self-contained HTML/CSS slide deck (one file, arrow-key navigation) **or**
  individual slide artifacts — Claude Design's choice, but it must look polished and on-brand.
- Each content slide = a **headline**, **3–5 tight bullets**, **a screen/visual on the right**,
  and the **recurring architecture mini-map** (see A.3) with the current layer highlighted.

### A.2 Visual language — use the REAL Qalam design system
Pull directly from `docs/design/kit/project/colors_and_type.css`. Exact tokens:

**Colors**
- Background (parchment): `#FAF6EE` — warm, never pure white
- Card surface (soft aqua): `#EAF4F4`
- Raised surface / canvas: `#FFFFFF`
- Primary (ink teal): `#168A8F`
- Pressed / headers / Arabic glyphs (deep ink): `#0E5B5F`
- Reward gold (stars only — use sparingly): `#F2A60C`
- Success (leaf): `#3FB984`
- Soft correction (coral — never harsh red): `#FF8A6B`
- Body text (ink charcoal): `#222A2E`
- Muted text (slate): `#5C6B70`
- Borders: `#E8DFC9` (parchment-edge) / `#D6E8E8` (aqua-edge)

**Type**
- Display / headings / buttons: **Fredoka**
- Body / labels: **Nunito**
- Arabic content: **Noto Naskh Arabic**
- Arabic display / large Arabic: **Cairo**
- Rule: Arabic glyphs sit ~10–25% larger than the Latin text beside them.

**Feel:** "modern manuscript / calligraphy studio." Rounded corners (14–28px), soft shadows,
generous spacing, a flat-bottom "sticker" button shadow (`0 4px 0 #0E5B5F`). Warm and
kid-friendly, but dignified — **"Real Arabic. Not a game."**

**Mascot:** Qalam, the reed-pen tutor. SVGs at `assets/mascot/` —
`qalam-idle.svg`, `qalam-think.svg`, `qalam-write.svg`, `qalam-cheer.svg`, `qalam-try-again.svg`.
Use the **cheer** pose on the title and closing slides, **write** pose near the scoring/trace
slides, **think** pose near the engineering slides. The mascot is the tutor's persona, not a
game mascot — keep that dignity.

### A.3 THE RECURRING ARCHITECTURE MINI-MAP (must appear on every content slide)
Render this as a compact, consistent diagram — a small vertical stack of labeled layers
(a "mini-map" pinned to the same corner of every content slide, e.g. bottom-left or a thin
left rail). On each slide, **highlight the one layer that slide is about** (full color +
subtle glow); dim the others to ~35% opacity. This is the spine that ties the whole deck
together and shows reviewers the system at a glance, every time.

The layers, top (child-facing) to bottom (foundation):

```
┌─────────────────────────────────────────────────────────┐
│  UI / SCREENS                                             │
│  Home · Journey Map · Practice (Watch→Trace→Feedback)     │
│  Letter Unit (6 sections) · Onboarding · Parent Dashboard │
├─────────────────────────────────────────────────────────┤
│  LEARNING ENGINE  (config-driven)                         │
│  5 reusable components + ExerciseController               │
│  ExerciseScaffold·PromptHeader·WriteSurface·              │
│  FeedbackPanel·ProgressRibbon                             │
├─────────────────────────────────────────────────────────┤
│  SCORING CORE  (pure Dart, on-device, offline)           │
│  Geometric stroke scorer · ML Kit identity gate          │
│  Reference paths = ONE source of truth                   │
├─────────────────────────────────────────────────────────┤
│  DATA  ·  CurriculumRepository                            │
│  Firestore (cloud source of truth) → bundled fallback    │
│  Drift local DB (mastery, profile, reps) · Anonymous auth │
├─────────────────────────────────────────────────────────┤
│  CURRICULUM + STROKE STUDIO  (authoring)                  │
│  Letters · Lessons · Exercises · Words                   │
│  Stroke Studio authors the reference paths               │
└─────────────────────────────────────────────────────────┘
        ↑ Built on the Qalam Design System (tokens, mascot, RTL)
```

Keep the labels short on the mini-map itself; the full text above is just so Claude Design
knows what each layer contains.

### A.4 Screens / assets to embed
Real images and prototypes live in the repo — use them so slides show the *actual* product:
- Screenshots: `docs/design/kit/project/screenshots/` (home.png, alphabet.png, celebration
  variants, lesson flows). Use these as the "screen" on each slide.
- Interactive Letter Unit prototype (screenshot it for slides):
  `docs/design/prototypes/letter-unit-baa/prototype/letter-unit/index.html`
- Journey preview: `docs/design/kit/project/ui_kits/qalam_app/journey_preview.html`
- Onboarding preview: `docs/design/kit/project/ui_kits/qalam_app/onboarding_preview.html`
- Practice/tutor mockup: `docs/design/practice-redesign/mockup.html`
- Mascot poses: `assets/mascot/*.svg`

If a live screenshot isn't handy, Claude Design should render a faithful mock of the screen
using the tokens above. Each screen slide should make clear **this is a real, running screen.**

---

## PART B — SLIDE-BY-SLIDE CONTENT

> 18 slides. Slides 1–2 and the closing can drop the mini-map (or show it whole, un-dimmed).
> Every other slide shows the mini-map with one layer highlighted (noted per slide).

---

### SLIDE 1 — TITLE
**Visual:** Qalam mascot (cheer pose) on parchment; logo `assets/logo-horizontal.svg`.
**Headline:** Qalam — *Real Arabic. Not a game.*
**Subhead:** Teaching children to *write* Arabic by hand — stroke by stroke — the way a
patient teacher sitting beside them would.
**Footer line:** Technion course project · Android tablet · right-to-left · on-device · offline-first
**Mini-map:** show the full diagram un-dimmed, small, as a teaser.

---

### SLIDE 2 — THE PROBLEM
**Highlight:** none (problem framing).
**Headline:** Almost every Arabic app teaches the wrong thing.
**Bullets:**
- They teach Arabic as a *foreign* language: tap-the-answer, multiple choice, a keyboard.
- **None teach a child to form the letters by hand** — the one thing that makes the language stick.
- Our learner is the **heritage child**: hears Arabic at home, can't yet read or write it.
- The real competition isn't Duolingo. It's a **$60/hour private tutor**, an underfunded
  weekend school, or nothing at all.
**Punchline:** Qalam is the patient teacher available at 9pm on a Tuesday.
**Visual:** split image — a "tap the answer" multiple-choice mock (greyed, crossed out) vs.
a child's hand tracing a letter with a stylus (our way, in color).

---

### SLIDE 3 — THE CORE LOOP (what the product *is*)
**Highlight:** UI / SCREENS layer.
**Headline:** One physical loop, repeated with care.
**Bullets (render as a 4-step horizontal flow with arrows):**
1. A **dotted letter** appears with a gold start-dot.
2. The child **traces it with a stylus**; live ink, palm/finger touches filtered out.
3. The app **scores the strokes on-device** in ~300ms — shape, order, direction, count.
4. The **warm tutor responds** with a specific, human fix — then they do it again.
**Sub-line:** That guided repetition *is* the product. In the spirit of Kumon.
**Visual:** the Practice screen (Watch→Trace→Feedback). Screenshot the practice/tutor mockup.

---

### SLIDE 4 — ARCHITECTURE OVERVIEW (the master diagram)
**Highlight:** the WHOLE diagram, large and centered, un-dimmed — this slide introduces the
mini-map that recurs on every later slide.
**Headline:** How it's built — five layers, one source of truth.
**Bullets (one line per layer, pointing at the diagram):**
- **UI / Screens** — Flutter, RTL islands, landscape tablet, Riverpod state.
- **Learning Engine** — 5 reusable components; every exercise is *data, not new UI*.
- **Scoring Core** — a custom geometric scorer (pure Dart) ML Kit does **not** provide.
- **Data** — Firestore as cloud source of truth, with full offline fallback + local Drift DB.
- **Curriculum + Stroke Studio** — the authoring tool that produces the reference paths.
**Sub-line:** "We'll walk down this diagram. Watch the highlight on each slide."
**Tech chips along the bottom:** Flutter · Dart · Riverpod · Drift · Firebase/Firestore ·
Google ML Kit Digital Ink · go_router.

---

### SLIDE 5 — DESIGN SYSTEM & THE TUTOR'S VOICE
**Highlight:** "Built on the Qalam Design System" footer of the diagram.
**Headline:** A real design system — and a voice that teaches.
**Bullets:**
- A full token system: parchment/ink palette, Fredoka + Nunito + Noto Naskh + Cairo,
  spacing, radii, motion — `docs/design/kit/`.
- **Qalam the reed-pen tutor** is the consistent face of the patient teacher (5 poses).
- The voice is **warm, calm, and specific** — every fix names the exact problem:
  - ✅ *"Your baa needs a deeper curve at the bottom — try again, slower this time."*
  - ❌ *"Oops, try again!"*
- **Anti-gamification by design:** no points, no streaks, no badges, no leaderboards.
  A star means *"you truly mastered this letter"* — information, not score.
**Visual:** color swatch row (the 9 core hex colors) + the 5 mascot poses + a feedback bubble
example. Pull real swatches from the palette in A.2.

---

### SLIDE 6 — SCREEN: HOME & TODAY'S LESSON
**Highlight:** UI / SCREENS.
**Headline:** Open the app → today's lesson is already prepared.
**Bullets:**
- One prepared lesson, one clear **Start** — no menus to navigate, no choice paralysis.
- Greeting uses the child's chosen **avatar + nickname** (fixed sets, never a real name).
- Progress shows as a quiet **ink-fill on the glyph** — never a running number.
- A nav rail to Journey and the Parent area; the next lesson unlocks only by *earning* it.
**Visual:** `docs/design/kit/project/screenshots/home.png`.
**Code anchor (small caption):** `lib/screens/home_screen.dart`

---

### SLIDE 7 — SCREEN: JOURNEY MAP
**Highlight:** UI / SCREENS.
**Headline:** The whole alphabet as a path you walk.
**Bullets:**
- All **28 letters** as nodes on a winding path, 4 rows that alternate direction (RTL-aware).
- Four states: **complete · current · future · locked**; the current letter gently pulses.
- Tap a reached letter to practice; future/locked nodes stay inert.
- Quiet gold stars mark genuine mastery — **no counter, no streak, no "+N" anywhere.**
**Visual:** `docs/design/kit/project/ui_kits/qalam_app/journey_preview.html` (screenshot).
**Code anchor:** `lib/features/journey/journey_screen.dart`

---

### SLIDE 8 — SCREEN: WATCH → TRACE → FEEDBACK
**Highlight:** UI / SCREENS (and visually point down to SCORING CORE).
**Headline:** The heart of a lesson.
**Bullets:**
- **Watch:** the correct stroke-order animation plays (and replays) — driven by the *same*
  reference path the scorer uses.
- **Trace:** the child writes over the dotted guide; stylus-only capture, smooth live ink.
- **Feedback:** within ~300ms, fully offline — the failing stroke is highlighted in **coral**
  with a **specific named fix**, never a generic "try again."
- A clean pass earns **one quiet star** — no confetti, no timers, no over-praise.
**Visual:** `docs/design/practice-redesign/mockup.html` (screenshot) — mascot on the left
speaking, trace canvas on the right.
**Code anchor:** `lib/features/practice/practice_screen.dart`

---

### SLIDE 9 — THE SCORING ENGINE (the hard part)
**Highlight:** SCORING CORE.
**Headline:** The piece nobody hands you: a geometric stroke scorer.
**Bullets:**
- ML Kit Digital Ink only tells you *which letter* it thinks you wrote — it does **not**
  score *how* you wrote it. We built that ourselves, in **pure Dart, on-device, offline.**
- Every attempt is checked on four axes: **stroke count → order → direction → shape**
  (length + curvature), after resampling and normalizing to a unit box so a small or
  off-center but *correct* letter still passes.
- **Dots matter:** dot count and position distinguish ب / ت / ث — the scorer enforces it.
- **ML Kit as an advisory gate:** it can catch "you wrote a completely different letter,"
  but it never overrides a good geometric pass.
- **Privacy:** stroke points live in memory only — never logged, never persisted, never sent.
**Visual:** a clean diagram of the 4-axis pipeline (count→order→direction→shape→[ML Kit gate]
→ pass/fix). Mascot "think" pose.
**Code anchors:** `lib/core/scoring/letter_scorer.dart`,
`lib/core/scoring/geometric_stroke_scorer.dart`, `lib/core/recognition/ml_kit_recognizer.dart`

---

### SLIDE 10 — ONE SOURCE OF TRUTH
**Highlight:** SCORING CORE ↔ CURRICULUM (draw the link between them).
**Headline:** One path drives everything.
**Bullets:**
- A letter's **reference strokes** are authored once as open *centerlines* (the path a pen
  tip actually travels), normalized to 0..1 coordinates.
- That single path drives **all three**: the **dotted guide** the child traces, the
  **stroke-order animation**, and the **geometric scorer**.
- They can never drift apart — authored path = animated path = scored path.
**Sub-line:** "So where do these paths come from? We built a tool for that." (→ next slide)
**Visual:** one centerline path with three arrows fanning out to: guide · animation · scorer.
**Code anchor:** `lib/core/scoring/reference_path.dart` (`ReferencePath.resolve`)

---

### SLIDE 11 — THE STROKE STUDIO ⭐ (the tool we built)
**Highlight:** CURRICULUM + STROKE STUDIO.
**Headline:** The Stroke Studio — authoring how every letter is written, by hand.
**Bullets:**
- An in-app authoring tool where the owner (with his mother, the Arabic teacher) **traces
  each letter over a faint glyph**, in *her* prescribed stroke order and direction.
- Each stroke is tagged: **order · label · type (line/curve/dot) · direction.**
- On export it **normalizes** the strokes together (combined bounding box, so "the dot is
  *below* the body" is preserved) and emits clean `referenceStrokes` data.
- A built-in **validator rejects bad input** — closed loops, outlines, directions that
  disagree with the actual point order — so a broken stroke can never reach the app.
**The problem it solved (call-out box):**
- We first pulled stroke data from the *font outline* — a closed silhouette loop ~3× too long.
- A child writes an **open downstroke**, not a loop, so every check (length, direction,
  curvature) was meaningless. The Stroke Studio replaced outlines with **correct teaching
  centerlines** — and re-authored *alif* as the proven exemplar.
**Visual:** the authoring screen — faint Noto Naskh glyph in the back, traced ink on top, the
stroke-tag controls. (Screenshot live from the app at route `/dev/authoring`, or mock it.)
**Code anchors:** `lib/dev/authoring_screen.dart`, `lib/dev/authoring_export.dart`,
`lib/core/scoring/stroke_validation.dart`

---

### SLIDE 12 — THE LEARNING ENGINE & LETTER UNIT
**Highlight:** LEARNING ENGINE.
**Headline:** A new question is a new *config*, never new code.
**Bullets:**
- Each letter is a **6-section unit**: Meet → Watch & Trace → Forms → Words →
  Listen & Write → Mastery.
- The whole experience is assembled from **5 reusable components**:
  **ExerciseScaffold · PromptHeader · WriteSurface · FeedbackPanel · ProgressRibbon.**
- Every exercise renders from a **Schema-v2 config object** — 19 different baa exercises run
  through the *same* components. Adding a question type = adding data.
- Handwriting-first throughout — even grammar and sentence-building have the child *write*,
  never tap one of four.
**Visual:** the Letter Unit baa prototype
(`docs/design/prototypes/letter-unit-baa/prototype/letter-unit/index.html`), ideally a strip
showing the 6 sections. Optionally show a tiny Exercise config JSON snippet beside a screen
to make "config → screen" concrete.
**Code anchors:** `lib/features/letter_unit/widgets/` (the 5 components),
`lib/features/letter_unit/exercise_controller.dart`

---

### SLIDE 13 — DATA & OFFLINE-FIRST
**Highlight:** DATA layer.
**Headline:** Cloud-authored, but it works on a plane.
**Bullets:**
- **Firestore** is the cloud source of truth for curriculum (letters, lessons, exercises).
- The app reads it **live**, but **Firestore offline persistence + a bundled seed fallback**
  mean the trace/score path *never* waits on the network — even airplane-mode, cold install.
- Local **Drift database** holds mastery, the child profile, and clean-rep counts on-device.
- **Anonymous auth**, zero child PII, client writes denied by security rules — child safety
  is a design constraint, not an afterthought.
**Visual:** a small flow: Firestore → (offline cache / bundled seed) → CurriculumRepository →
app; Drift DB shown beside it for local progress.
**Code anchors:** `lib/data/curriculum_repository.dart`, `lib/data/app_database.dart`,
`lib/services/auth_service.dart`

---

### SLIDE 14 — SCREEN: PARENT DASHBOARD
**Highlight:** UI / SCREENS (with a nod to DATA).
**Headline:** A quiet window for parents — read-only.
**Bullets:**
- Reachable only behind a **PIN** (salted, hashed locally — not an account).
- Shows completed letters and scores, sourced from local storage; **no cloud, no network.**
- Strictly **read-only** — no edit, delete, or reset; the child's record is safe.
**Visual:** parent dashboard mock (PIN entry → read-only mastery list).
**Code anchors:** `lib/screens/parent_dashboard_screen.dart`, `lib/services/auth_service.dart`
(PIN service: `PinService`, PBKDF2 + constant-time verify).

---

### SLIDE 15 — CURRICULUM & PEDAGOGY (the human in the loop)
**Highlight:** CURRICULUM + STROKE STUDIO.
**Headline:** The pedagogy is the owner's mother's — we just structure it.
**Bullets:**
- Stroke order, clean-reps-to-advance, the 3–4 common mistakes per letter, and the order
  letters are introduced come from a **graduate-level Arabic teacher with years in the classroom.**
- Our workflow: the model **drafts** a letter's stroke data + mistakes; **she reviews and
  signs off** — nothing ships unsigned.
- *alif* and *baa* are proven end-to-end; the remaining letters follow the same sign-off gate.
**Visual:** the common-mistakes data for a letter (e.g. baa) → mapped to named scorer checks →
the child-friendly fix message the tutor speaks. Show the chain.

---

### SLIDE 16 — HOW WE WORK / ENGINEERING PROCESS
**Highlight:** none (or whole diagram dim).
**Headline:** Built in disciplined vertical slices.
**Bullets:**
- A planning-and-execution workflow (research → plan → build → verify) with phase gates —
  the riskiest piece (the custom scorer) was isolated and tackled first.
- **Test-driven:** the Phase-3 core loop landed with **151 passing tests**; scorer logic is
  pure Dart and unit-tested independently of the UI.
- **7 of 13 phases complete; 33 of 34 plans done.** The baa Letter Unit is the current slice.
**Visual:** a simple phase timeline (Foundations → Curriculum → Trace loop → Scoring →
Profiles → Progression → Firebase → Learning Engine → … → Release) with completed phases ticked.

---

### SLIDE 17 — LIVE DEMO (on your device)
**Highlight:** UI / SCREENS, full color.
**Headline:** Let's write a letter.
**Bullets (this is the live-demo script — keep on screen while we drive the app):**
1. Open the app → **Home**, today's lesson is ready.
2. **Watch** the stroke-order animation for the letter.
3. **Trace** it with the stylus — get **instant, specific feedback**.
4. Earn the **quiet star**; see it settle on the **Journey** map.
5. Bonus: open the **Stroke Studio** (`/dev/authoring`) and author a stroke live.
**Visual:** a "LIVE" badge + the mascot (write pose). Minimal text — we're showing, not telling.

---

### SLIDE 18 — VISION & CLOSE
**Highlight:** full diagram, un-dimmed, with a "v2" glow on a future tutor layer.
**Headline:** Today: the loop works. Next: the tutor speaks.
**Bullets:**
- **v1 (now):** the full handwriting loop — trace, on-device scoring, specific feedback,
  honest progress — local-first and private.
- **v2:** a warm **AI tutor** (server-side, never on the client) that sees the child's whole
  session and responds in Qalam's voice; a nightly job recompiles each child's
  strengths and struggles.
- The mission stays the same: **the patient teacher, available at 9pm on a Tuesday.**
**Visual:** Qalam mascot (cheer), tagline *"Real Arabic. Not a game."*, thank-you + Q&A.

---

## PART C — ASSET MANIFEST (paths for Claude Design / for screenshotting)

| Need | File |
|---|---|
| Logo | `assets/logo-horizontal.svg`, `assets/logo.svg` |
| Mascot poses | `assets/mascot/qalam-{idle,think,write,cheer,try-again}.svg` |
| Color + type tokens | `docs/design/kit/project/colors_and_type.css` |
| Home screenshot | `docs/design/kit/project/screenshots/home.png` |
| Celebration variants | `docs/design/kit/project/screenshots/01-celebration.png`, `02-celebration-final.png` |
| Alphabet | `docs/design/kit/project/screenshots/alphabet.png` |
| Lesson flow shots | `docs/design/kit/project/screenshots/0{1..5}-flow.png` |
| Journey preview | `docs/design/kit/project/ui_kits/qalam_app/journey_preview.html` |
| Onboarding preview | `docs/design/kit/project/ui_kits/qalam_app/onboarding_preview.html` |
| Practice/tutor mock | `docs/design/practice-redesign/mockup.html` |
| Letter Unit baa (interactive) | `docs/design/prototypes/letter-unit-baa/prototype/letter-unit/index.html` |
| Component gallery | `docs/design/prototypes/letter-unit-baa/prototype/exercise-components/index.html` |

---

## PART D — ONE-LINE TRUTHS (so no slide overstates anything)
- The AI tutor is **v2, not built yet** — v1's feedback is authored, specific copy keyed to
  named scorer mistakes. Present it as "specific authored feedback today; AI tutor next."
- The custom geometric scorer is **real and tested**; ML Kit is an **advisory identity check**, not the scorer.
- *alif* is fully signed off; *baa*'s Letter Unit is the current end-to-end slice (Phase 7, 6/7 plans).
- The Stroke Studio is internal/dev (`/dev/authoring`) — great to *show*, not a child screen.
- Offline-first is held by Firestore cache + a bundled seed; it genuinely runs airplane-mode.
