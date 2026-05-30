# Qalam

## What This Is

Qalam teaches heritage-learner children (ages 5–10) to *physically write* Arabic by
hand — stroke by stroke — the way a patient teacher sitting beside them would. On an
Android tablet, right-to-left, a dotted letter appears, the child traces it with a
stylus, the app scores the strokes on-device, and a warm AI tutor responds with
specific, human feedback. Then they do it again. *"Real Arabic. Not a game."*

The competition isn't Duolingo — it's a $60/hour private tutor, an underfunded weekend
school, or nothing. Qalam is the patient teacher available at 9pm on a Tuesday.

Currently a Technion course project. **Android-only for now;** iOS is a later port.

## Core Value

A child traces an Arabic letter and gets warm, *specific*, teacher-quality feedback on
their actual strokes — fast enough that it feels like a person is sitting beside them.
If this one loop works, the product works.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- ✓ Flutter (Android) project shell builds and runs — existing
- ✓ Codebase mapped, conventions and structure documented — existing

### Active

<!-- v1 scope. Hypotheses until shipped and validated. -->

- [ ] Child can select an Arabic letter to practice from the curriculum
- [ ] A dotted guide letter renders correctly RTL, in the right contextual form
- [ ] Child can trace the letter with a stylus and see their ink as they draw
- [ ] Strokes are scored on-device via ML Kit Digital Ink (no network round-trip)
- [ ] A real Claude tutor (via Python Cloud Function) returns warm, specific feedback
- [ ] Tutor feedback reflects the full current-session history (within-session adaptation)
- [ ] Child repeats the letter; clean reps advance them per the curriculum spec
- [ ] Local child profile persists progress across sessions on the device
- [ ] Full 28-letter curriculum (stroke order, intro order, common mistakes) loaded from a faithful schema
- [ ] Anti-gamification throughout: no points, no streak pressure, no badges, no mascots

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Parent dashboard — deferred to v2; v1 focuses on proving the child's core loop
- Firebase Auth / parent login — deferred to v2; v1 runs local-only on one tablet
- Nightly across-session profile compiler (the second adaptation timescale) — deferred to v2
- iOS support (deployment, PencilKit) — Android-only for now per project decision
- Teaching Arabic as a foreign language (tap-the-answer, multiple choice, keyboard) — this is the anti-product
- Gamification mechanics (points, streaks-as-pressure, badges, cartoon mascots) — contradicts the pedagogy

## Context

- **Brownfield, very early.** Repo is a minimal Flutter/Android skeleton (`lib/main.dart`
  boilerplate). Real architecture (screens, services, providers, models) is planned but
  not yet built. See `.planning/codebase/` for the full map.
- **The tutor's voice is the product's signature**, not a detail. Warm, calm, specific —
  a real teacher's patience, never a chatbot's cheerfulness. Short sentences pitched to a
  5–10 year old; feedback always names the exact fix (*"Your baa needs a deeper curve at
  the bottom — try again, slower this time."* — never *"Oops, try again!"*). A little
  Arabic is welcome (أحسنت); guidance stays in the child's working language.
- **Curriculum is the owner's mother's domain** (graduate degree, years teaching Arabic).
  Stroke order, clean-reps-to-advance, the 3–4 common mistakes per letter, and letter
  introduction order come from *her*. We build a schema that faithfully holds her spec —
  we do not invent the pedagogy, we structure it. Her full 28-letter spec is available
  for this milestone.
- **Open research questions** gate dependent code (`docs/RESEARCH_BRIEF.md`):
  R2 offline-first strategy, R3 RTL + connected-script rendering, R4 tutor cost & latency.
  R1 (handwriting recognition) is resolved — ML Kit Digital Ink, validated by the owner's
  own testing.
- **Child safety is a first-class design constraint:** collect the minimum child data,
  private by default, treated as sensitive in every decision.
- Owner is fluent in Python, new to Dart — Dart choices should be explained plainly.

## Constraints

- **Tech stack**: Flutter + Dart, Android-only, tablet-first, RTL — project decision.
- **Tech stack**: Firebase (Auth + Firestore + Cloud Functions) with a **Python** runtime
  for Functions — owner is fluent in Python; backend/tooling is Python over TypeScript.
- **Architecture**: Handwriting recognition on **Google ML Kit Digital Ink, on-device** —
  validated, not exploratory. No network round-trip for scoring.
- **Architecture**: The tutor **never** runs client-side — it lives behind a Cloud
  Function; the API key lives only in the Function secret.
- **State management**: **Riverpod only** — BLoC/GetX explicitly rejected.
- **Security**: Children's data is sensitive — minimum collection, private by default,
  under (eventual) parent control. The tutor API key never ships in the client.
- **Timeline**: ~2–3 months (one course semester) for this milestone — bounds v1 scope.
- **Process**: Runs on GSD (discuss → plan → execute → verify); research/approval gates
  are never skipped. Propose options with tradeoffs; the human decides, especially on
  anything pedagogical.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Handwriting recognition = ML Kit Digital Ink, on-device | Validated by owner's own testing; no network round-trip for scoring | ✓ Good |
| Tutor runs server-side only (Python Cloud Function → Claude) | Protect API key; keep tutor logic off the client | — Pending |
| Riverpod for state management | Project standard; BLoC/GetX rejected | — Pending |
| v1 = core loop + local profiles + real within-session tutor | Prove the heart of the product within one semester | — Pending |
| Parent dashboard, auth, and nightly compiler deferred to v2 | Keep v1 demo-able; the child's loop is what must work first | — Pending |
| Local-only, no auth for v1 | Single-tablet course demo; avoids login scope without blocking the loop | — Pending |
| Full 28-letter curriculum loaded in v1 | Owner's mother's complete spec is ready | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-30 after initialization*
