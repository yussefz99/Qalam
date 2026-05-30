# Qalam — Claude Design Setup Package

*The reusable foundation for generating Qalam's UI in Claude Design. Copy the **Brief** and **System-Prompt Prefix** blocks directly into your sessions. Recommendations are marked — swap any element you disagree with.*

---

## 0. How this fits the workflow

Claude Design outputs **web** (HTML/Tailwind/React), so for Qalam it is your **visual prototyping and spec tool** — not a Flutter code source. The flow is:

1. Generate and lock the design system + screens in Claude Design (this package).
2. Translate the approved tokens into a Flutter `theme.dart` (one coding session).
3. Build each screen as Flutter widgets, importing that theme.

The design system is the durable artifact that survives the web → Flutter jump. Get it right here once.

---

## 1. App snapshot

- **Name:** Qalam (قلم — "pen"). The AI tutor mascot is also named Qalam.
- **What it is:** A Kumon-style structured Arabic-practice app for diaspora children, built on a real teaching curriculum, with stylus letter-tracing and (later) an AI voice tutor.
- **Audience:** Grades 1–6 (~ages 6–12). Stronger language is English; Arabic is the learning target.
- **Platform:** Tablet with stylus (Android, built in Flutter). Single form factor for v1.
- **Language & direction:** English-LTR chrome (navigation, buttons, parent/teacher screens, instructions, voice feedback). Arabic appears as **RTL content islands** inside lessons.
- **Personas:** Child (primary), Parent (profiles, progress, goals), Teacher (later — class progress, assigning lessons).
- **v1 scope = Sprint 1:** onboarding, "today's lesson" home, stroke-order animation, stylus tracing with instant shape + stroke-order feedback, pronunciation audio, sentence building, grammar, mastery-gated unlock, stars, parent progress view.
- **Later:** placement exam, voice tutor Q&A, adaptive daily lesson, vocab flashcards, reading comprehension, weekly reports, streaks, badges, reminders, multi-child, offline tracing, teacher tools.

---

## 2. Recommended visual identity

### Mascot — "Qalam" the reed pen *(recommended)*
A warm, rounded reed-pen (qalam) character with a carved-nib face, expressive eyes, and small gesturing hands. Why: it embodies the app name, is culturally rooted in calligraphy, is gender- and nation-neutral, scales across grades 1–6, and — crucially — **can demonstrate stroke order by writing letters himself** in the demo animation. His ink (gold) is the app's "magic"/reward motif: ink trails for progress, celebrations, sparkles.
*Alternative if you want more emotional range:* a hoopoe bird (هدهد), culturally resonant and easy to emote, but it breaks the name tie-in.

### Color palette — "ink & parchment"
| Role | Name | Hex | Use |
|---|---|---|---|
| Background | Parchment | `#FAF6EE` | App surfaces (warm, not stark white) |
| Surface | Soft Aqua | `#EAF4F4` | Cards, panels |
| Primary (cool) | Ink Teal | `#168A8F` | Primary actions, "learning" |
| Primary dark | Deep Ink | `#0E5B5F` | Pressed states, headers |
| Accent (warm) | Gold Ink | `#F2A60C` | **Rewards/stars/progress only** |
| Success | Leaf | `#3FB984` | Correct |
| Soft error | Coral | `#FF8A6B` | "Try again" — never harsh red |
| Text | Ink Charcoal | `#222A2E` | Body text (not pure black) |
| Text muted | Slate | `#5C6B70` | Secondary text |

Contrast must meet WCAG AA (4.5:1 body, 3:1 large/UI). Reserve Gold Ink strictly for reward moments so it stays special.

### Typography — two systems
**English UI (chrome):**
- Display / headings / buttons: **Fredoka** (rounded, friendly, not babyish)
- Body / labels: **Nunito** (warm, highly legible)

**Arabic content (RTL islands):**
- Reading & tracing content (with tashkeel): **Noto Naskh Arabic** (schoolbook-correct letterforms, clean diacritics)
- Arabic display (logo قلم, subject names): **Cairo**
- Tracing guides: a dotted/outlined tracing font (e.g. Namela's *Alif Baa Taa* family) **or** custom SVG letter outlines with numbered start-dots and directional arrows.

**Arabic content rules (non-negotiable):**
- Arabic content set **10–25% larger** than adjacent English (e.g. 18px English → 22px Arabic content).
- Line-height **1.7** for plain Arabic, **2.0** when tashkeel is present.
- **No bold, no italic** on Arabic — use weight variation (Regular → Medium → SemiBold) for hierarchy.
- All learning content **fully vocalized (tashkeel)** — diaspora kids cannot infer vowels.

### Aesthetic direction — "modern manuscript / playful calligraphy studio"
Warm parchment surfaces, ink-teal and gold, generous rounded shapes, large tactile controls, and sparing ink-flourish or subtle Islamic-geometric accents. Distinctive and ownable — *not* the generic purple-gradient AI-kids-app look. Feel = warmth of Khan Academy Kids + lesson clarity of Amal + its own ink identity.

---

## 3. Provisional subject taxonomy *(adjust as curriculum firms up)*
Design the home and navigation to handle a **flexible, reorderable list** of subjects:
1. **Letters & Writing** (tracing, stroke order) — the flagship
2. **Sounds & Pronunciation** (listen/repeat; may fold into Letters)
3. **Vocabulary** (picture flashcards)
4. **Sentence Building**
5. **Grammar**
6. **Reading** (short passages + comprehension)

"Today's lesson" pulls across these. Don't hard-code the count — the curriculum may change it.

---

## 4. v1 screen list (Sprint 1 → components Claude must produce)
- **Onboarding A (parent):** create child profile — name, grade
- **Onboarding B (child):** pick avatar + nickname
- **Home / "Today's Lesson":** lesson already prepared, one tap to start; secondary "journey map"
- **Lesson player shell** holding exercise types:
  - Stroke-order animation view (Qalam writes the letter)
  - **Tracing canvas** (stylus, instant feedback) — the hero screen
  - Listen / pronunciation view
  - Sentence-building exercise
  - Grammar exercise
- **Lesson complete / stars celebration**
- **Journey map** (locked → unlocked path; mastery gating)
- **Parent area** (behind a parent gate): completed lessons + scores
- **Settings**

**Core component set:** large primary buttons, tracing canvas, stroke-order animator, star/reward elements, lesson cards, journey-map nodes, progress bars, Qalam mascot in multiple states (idle/cheer/think/write/try-again), avatar picker, parent-dashboard cards, parent gate.

---

## 5. The Brief — *upload this to Claude Design*

```
PROJECT: Qalam — an Arabic-learning app for diaspora children (grades 1–6),
built on a real teaching curriculum. Kumon-style structured practice: mastery
before progression, daily short sessions, stylus letter-tracing with instant
feedback, and a friendly tutor mascot. Tablet + stylus.

AUDIENCE: Children 6–12 whose stronger language is English; Arabic is what they
are learning. Also parents (profiles, progress) and later teachers.

LANGUAGE/DIRECTION: App chrome is ENGLISH and LTR. Arabic appears only as RTL
content islands inside lessons (dir="rtl" containers). This is NOT an
Arabic-first app — treat it like Duolingo, where the interface is in the user's
language and the target language shows up in exercises.

MASCOT: "Qalam," a friendly reed-pen character who teaches and gives feedback,
and who demonstrates letter stroke order by writing the letters himself.

AESTHETIC: "Modern manuscript / playful calligraphy studio." Warm parchment
surfaces, ink-teal primary, gold-ink reward accent, rounded tactile shapes,
sparing ink-flourish accents. Warm like Khan Academy Kids, clear like Amal,
with its own distinctive ink identity. NOT generic, NOT purple-gradient AI-slop.

PALETTE: Parchment #FAF6EE bg, Soft Aqua #EAF4F4 surface, Ink Teal #168A8F
primary, Deep Ink #0E5B5F dark, Gold Ink #F2A60C (rewards only), Leaf #3FB984
success, Coral #FF8A6B soft-error, Ink Charcoal #222A2E text.

TYPE: English UI — Fredoka (display/buttons) + Nunito (body). Arabic content —
Noto Naskh Arabic (with tashkeel) + Cairo (display). Arabic content 10–25%
larger than English; line-height 1.7 (2.0 with tashkeel); never bold/italic on
Arabic; all learning content fully vocalized.

KIDS-UX FLOOR: minimum touch target 64–76px with ≥16px spacing; one task per
screen; errors framed as gentle "try again" with soft animation, never a red X;
audio support for younger readers; large, calm layouts.

DELIVERABLE: a full UI kit — palette, typography scale, and component patterns
including a stylus tracing canvas, stroke-order animator, lesson cards, a
journey/path map, star rewards, progress bars, the Qalam mascot in multiple
states, and a parent dashboard.
```

---

## 6. System-Prompt Prefix — *paste at the start of every session*

```
You are designing UI for "Qalam," an Arabic-learning app for diaspora children
(grades 1–6) on tablet with a stylus.

Direction & language:
- App chrome is ENGLISH and LTR (nav, buttons, parent/teacher, instructions).
- Arabic is ONLY inside lesson content, as RTL islands: wrap Arabic in a
  dir="rtl" container using Tailwind logical classes (ms-, pe-, text-start).
- Do not mirror the whole app. Mirror only the Arabic content blocks.

Type:
- English: 'Fredoka' (display/buttons), 'Nunito' (body).
- Arabic content: 'Noto Naskh Arabic' (with tashkeel); 'Cairo' for Arabic display.
- Arabic content 10–25% larger than nearby English; line-height 1.7, or 2.0
  with tashkeel. Never bold/italic on Arabic — use weight variation. Always
  show tashkeel on learning content.
- Numerals: use Western numerals (0–9) everywhere, including inside Arabic
  lesson content.

Color:
- Parchment #FAF6EE bg, Soft Aqua #EAF4F4 surfaces, Ink Teal #168A8F primary,
  Deep Ink #0E5B5F dark, Gold Ink #F2A60C for rewards ONLY, Leaf #3FB984
  success, Coral #FF8A6B for soft "try again", Ink Charcoal #222A2E text.

Kids UX:
- Minimum touch target 64–76px, ≥16px apart. One task per screen.
- Warm, encouraging tone. Errors = soft "try again" animation, never red X.
- Stylus precision applies to the tracing canvas; menu controls stay large.

Aesthetic:
- "Modern manuscript / playful calligraphy studio": warm parchment, ink-teal +
  gold, rounded tactile shapes, sparing ink/geometric flourishes. Distinctive.
- Avoid your defaults: no Inter/Roboto, no purple-on-white gradients, no
  adult-dashboard density, no generic AI-kids-app look.

Use shadcn/ui components with Tailwind. Use the established design system tokens
— do not hardcode new hex values or fonts.
```

---

## 7. Asset checklist — *gather before generating*
Claude Design builds a far better kit from real assets than from text alone.
- [ ] **Palette swatch image** with the 9 hex values above (or ask me to generate one).
- [ ] **Font specimens:** screenshots of Fredoka, Nunito, Noto Naskh Arabic (include a sample *with tashkeel*), Cairo.
- [ ] **Reference screenshots (2–3):** Khan Academy Kids home + lesson; Amal tracing screen; optionally Duolingo ABC lesson.
- [ ] **Aesthetic mood:** 1–2 images of Arabic manuscript / gold illumination / a reed pen, for the ink identity.
- [ ] *(Optional)* a rough mascot reference image for the reed-pen direction.

---

## 8. Generation sequence — *run in this order*
1. **Design system:** paste the Brief + System-Prompt Prefix, attach assets → "Build the UI kit." Output: tokens + component library.
2. **Validate** against the checklist below before going further.
3. **Mascot:** "Design Qalam, the reed-pen mascot, in 5 states: idle, cheering, thinking, writing a letter, and gentle try-again."
4. **Hero screen first — the tracing canvas.** It is make-or-break; build it while the design vocabulary is fresh. Include stroke-order demo → guided trace (dotted guide, numbered arrows) → free trace → letter-in-word.
5. **Then:** Home/Today's Lesson → Lesson-complete celebration → Journey map → Onboarding (parent + child) → Parent area → Settings. Ask for 2 variants on the home and celebration screens.
6. **Interactive prototype:** wire Home → Lesson → Celebration → Home with realistic fully-vocalized Arabic content.
7. **Extract tokens to JSON**, then move to the Flutter `theme.dart` translation session.

### Validation checklist (apply to every screen)
- [ ] English chrome is LTR; only Arabic content blocks are RTL.
- [ ] Arabic content uses Noto Naskh Arabic, is fully vocalized, ≥22px, line-height ≥1.7 (2.0 with tashkeel).
- [ ] No bold/italic anywhere on Arabic.
- [ ] Western numerals (0–9) everywhere, including Arabic content.
- [ ] Touch targets ≥64px, ≥16px apart.
- [ ] Gold Ink used only for rewards.
- [ ] Errors are soft coral "try again," never red X.
- [ ] Doesn't look like generic AI-kids-app slop.

---

## 9. Decisions still open (won't block starting)
- Mascot: reed pen *(recommended)* vs hoopoe — confirm.
- Final subject taxonomy — will firm up with the curriculum; design stays flexible.
- Younger/older visual modes — deferred past v1.
