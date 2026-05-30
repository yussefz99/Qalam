# CLAUDE.md — Qalam

Arabic handwriting-first learning app for children (ages 5–10). Tablet-native,
RTL Arabic, anti-gamification, Kumon-style daily structured practice.
*"Real Arabic. Not a game."*

## How you work on this project (read every session)

1. **Research before you build. Always.** Do not scaffold, `flutter create`, or
   write feature code until the research and architecture phases are approved.
2. **Phase gates.** Work in phases; STOP at the end of each and wait for review.
   Never silently roll from research into building.
   - Phase 1 — Research → write to `docs/research/raw/`, write nothing else.
   - Phase 2 — Architecture → propose ADRs in `docs/architecture/adr/`.
   - Phase 3 — Project setup → scaffold only after Phase 2 is approved.
   - Phase 4 — First vertical slice (one letter, trace→score→feedback).
3. **Propose, don't decide.** Surface options with tradeoffs. The human owns the
   call, especially anything pedagogical.
4. **Python over TypeScript** for all backend / tooling. The owner is fluent in
   Python, not Dart/TS — explain Dart choices, keep magic low.
5. When unsure, ask. A wrong autonomous build is more expensive than a question.

## What's DECIDED (don't relitigate; validate if research contradicts)

- Stack: Flutter + Dart (tablet-first, RTL), Firebase (Auth + Firestore +
  Cloud Functions, Python runtime), Claude API for the tutor.
- Golden rule: the tutor NEVER runs client-side. Flutter → Cloud Function →
  Anthropic API. The API key lives only in the function secret.
- Two-timescale adaptation: within-session (full history in context) +
  across-session (nightly profile compiler updating strengths[]/struggles[]).
- State management: Riverpod (manual providers first, codegen optional later).
- Principle: handwriting-first, anti-gamification. No points-chasing language.

## What's OPEN (the research phase must resolve these)

- Arabic handwriting recognition approach (ML Kit Digital Ink vs TrOCR vs custom
  TFLite vs geometric stroke-order checking) — the #1 technical risk.
- Offline-first strategy and parent-dashboard sync model.
- RTL + connected-script rendering specifics in Flutter (letter forms, fonts).
- Tutor cost model + per-stroke feedback latency budget.

## Curriculum is the owner's mother's domain

Stroke order, progression logic, and the per-letter error taxonomy come from her,
not from research. Structure a schema that can hold her spec; do not invent the
pedagogy.

## Where things live (wiki-as-memory)

- `docs/research/raw/` — raw findings, one file per question.
- `docs/architecture/adr/` — compiled decisions, one ADR per decision.
- `docs/RESEARCH_BRIEF.md` — the current research scope and gates.
