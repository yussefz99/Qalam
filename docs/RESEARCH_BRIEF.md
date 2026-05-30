# Qalam — Research Questions

The questions to resolve before building dependent code. Feed them into GSD's
research/discuss steps (`/gsd-new-project`, then `/gsd-discuss-phase` per phase).
Each answer goes in `docs/research/raw/<id>-<slug>.md` with: the question, findings
with sources, the tradeoffs, and a recommendation. **R1 gates all handwriting work.**

Scope: **Android-only for now.** iOS-specific concerns (deployment, PencilKit) are
deferred; Android stylus input and RTL rendering are in scope.

## R1. Arabic handwriting recognition (HIGHEST PRIORITY)
The pedagogical need is **stroke-order and shape validation for a child learning to
write**, not text recognition. Compare:
- ML Kit Digital Ink Recognition — real Arabic support? accuracy on children's
  letter-level handwriting? does it expose stroke data or only a text guess?
- TrOCR / transformer OCR — on-device vs server, latency.
- Custom TFLite stroke classifier trained on the curriculum letters.
- Geometric stroke-order checking (compare captured strokes to a reference path).
Deliverable: a recommendation with the accuracy/latency/effort tradeoffs made
explicit, plus a fallback. This decision gates everything downstream.

## R2. Offline-first strategy
How much of a practice session must work with no connection? Firestore offline
persistence behavior, queued session writes, and how the parent dashboard reconciles
when the child reconnects.

## R3. RTL + connected-script rendering in Flutter
Letter form shaping (isolated/initial/medial/final), a font with strong Arabic glyph
coverage, known Flutter RTL pitfalls, and how the dotted guide letter should render
behind the child's strokes.

## R4. Tutor cost & latency budget
Per-session Claude call count, prompt caching opportunities, expected token volume,
and the acceptable latency between a finished stroke and on-screen feedback. Propose
a target latency and a design that meets it.

## R5. Competitor teardown (keep short)
Existing Arabic-for-children apps: what they do, whether any teach handwriting, and
where the gap actually is. Validates positioning.
