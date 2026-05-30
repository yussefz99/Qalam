# Qalam — Design Brief

A brief for generating Qalam's UI in Claude Design. Treat this as the source of truth for the brand and the hard constraints.

## What Qalam is
An Arabic-learning app for diaspora children in grades 1–6, built on a real teaching curriculum. Kumon-style structured practice: mastery before progression, short daily sessions, stylus letter-tracing with instant feedback, and a friendly tutor mascot. Tablet + stylus.

## Audience
Children aged ~6–12 whose stronger language is English; Arabic is what they are learning. Also parents (profiles, progress, goals) and later teachers (class progress, assigning lessons).

## Language & direction
The app chrome is **English and LTR** — navigation, buttons, instructions, parent and teacher screens, and voice feedback. Arabic appears **only as RTL content islands** inside lessons (wrap Arabic in `dir="rtl"` containers). This is **not** an Arabic-first app. Treat it like Duolingo: the interface is in the user's language, and the target language shows up inside exercises. Do not mirror the whole app — mirror only the Arabic content blocks.

## Mascot
"Qalam," a friendly reed-pen character who teaches and gives feedback, and who demonstrates letter stroke order by writing the letters himself. (A hoopoe bird is the alternative being evaluated.)

## Aesthetic
"Modern manuscript / playful calligraphy studio." Warm parchment surfaces, ink-teal primary, gold-ink reward accent, rounded tactile shapes, sparing ink-flourish or subtle geometric accents. Warm like Khan Academy Kids, clear like Amal, with its own distinctive ink identity. **Not** generic, **not** purple-gradient AI-slop, **not** adult-dashboard density.

## Color palette
- Parchment `#FAF6EE` — app background
- Soft Aqua `#EAF4F4` — cards / surfaces
- Ink Teal `#168A8F` — primary actions
- Deep Ink `#0E5B5F` — pressed states / headers
- Gold Ink `#F2A60C` — **rewards only** (stars, progress, celebration)
- Leaf `#3FB984` — correct / success
- Coral `#FF8A6B` — soft "try again" (never harsh red)
- Ink Charcoal `#222A2E` — body text
- Slate `#5C6B70` — muted text

All text must meet WCAG AA contrast (4.5:1 body, 3:1 large/UI).

## Typography
- **English UI:** Fredoka (display, headings, buttons) + Nunito (body, labels)
- **Arabic content:** Noto Naskh Arabic (reading & tracing content, with tashkeel) + Cairo (Arabic display / the قلم logo)

Arabic content rules (non-negotiable):
- Arabic content set 10–25% larger than nearby English.
- Line-height 1.7 for plain Arabic, 2.0 when tashkeel is present.
- Never bold or italic on Arabic — use weight variation for hierarchy.
- All learning content is fully vocalized (tashkeel).

## Numerals
Use **Western numerals (0–9) everywhere**, including inside Arabic lesson content.

## Kids-UX floor
- Minimum touch target 64–76px, with ≥16px spacing between targets.
- One task per screen.
- Warm, encouraging tone. Errors are gentle "try again" with soft animation, never a red X.
- Audio support for younger readers.
- Stylus precision applies to the tracing canvas; menu controls stay large.

## Deliverable
A full UI kit — color palette, typography scale, spacing/radius tokens, and component patterns including: a **stylus tracing canvas**, a **stroke-order animator**, lesson cards, a **journey/path map**, **star rewards**, progress bars, the **Qalam mascot** in multiple states, and a **parent dashboard**.
