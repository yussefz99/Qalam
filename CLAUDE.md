# CLAUDE.md — Qalam

**Qalam teaches children to *write* Arabic by hand — really write it, stroke by
stroke — the way a patient teacher sitting beside them would.** Android tablet,
right-to-left, no points-chasing, no cartoon mascots. Daily structured practice in
the spirit of Kumon. *"Real Arabic. Not a game."*

Currently a Technion course project. **Android-only for now;** iOS is a later port —
don't add iOS-specific work unless asked.

## What we're building

Almost every Arabic app on the market teaches Arabic as a *foreign* language —
tap-the-right-answer, multiple choice, a keyboard. None of them teach a child to
form the letters by hand, which is the one thing that actually makes the language
stick. Qalam is for **heritage learners**: kids who may hear Arabic at home but
can't yet read or write it. The core loop is physical — a dotted letter appears, the
child traces it with a stylus, the app watches the strokes, and a warm AI tutor
responds with specific, human feedback. Then they do it again. That repetition,
guided well, is the whole product.

The competition isn't Duolingo. It's a private tutor at $60/hour, an underfunded
weekend school, or nothing at all. Qalam is the patient teacher who's available at
9pm on a Tuesday.

## The tutor's voice

This is the heart of the app, so get it right. The tutor is **warm, calm, and
specific** — a real teacher's patience, never a chatbot's cheerfulness. It speaks
simply, to a 5-10 year old, in short sentences. Its feedback always names the exact
fix:

- Good: *"Your baa needs a deeper curve at the bottom - try again, slower this time."*
- Never: *"Oops, try again!"*

It celebrates real progress and doesn't over-praise sloppy work. A little Arabic is
welcome (أحسنت - well done), but guidance stays in the child's working language. The
tutor's personality and pedagogy come from the owner's mother (see below) - that
voice is the product's signature, not a detail.

## How we work (always on, every phase)

- **Research before you build.** Resolve the open questions below before writing
  code that depends on them. This project runs on GSD - follow its loop
  (discuss -> plan -> execute -> verify) and don't skip its research/approval gates.
- **Propose, don't decide.** Lay out options with their tradeoffs; the human makes
  the call, especially on anything pedagogical.
- **Python over TypeScript** for all backend and tooling. The owner is fluent in
  Python and new to Dart - explain Dart choices in plain terms, keep the magic low.
- **When you're unsure, ask.** A wrong autonomous build costs far more than a question.

## Decided (don't relitigate; flag loudly if something contradicts these)

- Flutter + Dart, **Android-only for now** (tablet-first, RTL).
- Firebase: Auth + Firestore + Cloud Functions (**Python** runtime).
- **Handwriting recognition: Google ML Kit Digital Ink - validated, not
  exploratory.** We tested it on Arabic and it performs excellently. Build the
  handwriting layer on ML Kit, on-device, with no network round-trip for scoring.
- The tutor **never** runs client-side.
- Two-timescale adaptation: within-session (the tutor sees the full session history)
  and across-session (a nightly job recompiles each child's strengths[]/struggles[]).
- Handwriting-first and anti-gamification. No points, no streaks-as-pressure, no
  badge-chasing language.

## Still open (resolve via research before the related code)

- **Offline-first strategy** + how the parent dashboard syncs when the child
  reconnects.
- **RTL + connected-script rendering** in Flutter - letter forms
  (isolated/initial/medial/final), a font with strong Arabic glyphs, known pitfalls.
- **Tutor cost + latency** - calls per session, prompt caching, and the acceptable
  delay between a finished stroke and on-screen feedback.

*(Handwriting recognition used to live here - it's now Decided, thanks to the ML Kit
testing.)*

## Curriculum is the owner's mother's domain

She has a graduate degree and years of teaching Arabic. Stroke order, how many clean
reps advance a child, the 3-4 most common mistakes per letter, the order letters are
introduced - these come from **her**, not from research or guesswork. Build a schema
that can faithfully hold her spec. Do not invent the pedagogy; structure it.

## Domain agents

Flutter work is delegated to the flutter-claude-code plugin agents (architect,
state-management, firebase, ui-implementer, testing). If any agent's defaults
contradict the **Decided** section - say it reaches for BLoC instead of Riverpod -
**this file wins.**

## Where things live (wiki-as-memory)

- `docs/research/raw/` - raw findings, one file per question.
- `docs/architecture/` - compiled decisions / ADRs.