# Qalam

## What This Is

Qalam teaches heritage-learner children (ages 5–10) to *physically write* Arabic by
hand — stroke by stroke — the way a patient teacher sitting beside them would. On an
Android tablet, right-to-left, a dotted letter appears, the child traces it with a
stylus, the app scores the strokes on-device, and the child builds from letters up to
words, sentences, and simple grammar through daily structured practice. *"Real Arabic.
Not a game."*

The competition isn't Duolingo — it's a $60/hour private tutor, an underfunded weekend
school, or nothing. Qalam is the patient teacher available at 9pm on a Tuesday.

Currently a Technion course project (Android Development · 236272 · Spring 2025/26).
**Android-only for now;** iOS is a later port.

## Core Value

A child traces an Arabic letter, gets immediate, specific feedback on their actual
strokes, and advances through a real teacher's curriculum — so the language sticks
through the hand. The warm AI tutor voice (the product's eventual signature) layers on
in the next milestone; v1 must make the **handwriting-first learning loop** genuinely
good on its own.

## Current Milestone: v2.0 AI Tutor (Technion build)

**Goal:** Turn the fixed-order drill into a dynamic, **grounded** AI agent-tutor on one
letter family (**baa**) — the model reasons, coaches, and chooses which exercise to show,
but every factual claim about the child's writing is pinned to the deterministic geometry
scorer. The scorer owns pass/fail + the star; the agent owns the words. This is the fastest
path to a working, grounded, demoable tutor for the Technion meeting — not the full v2.

**Target features:**
- A swappable **`TutorBrain`** abstraction with three backends: **AuthoredFallback** (the
  offline floor — mother-signed-off coaching lines, zero model, fully offline + grounded),
  **GeminiBrain** (cloud via Firebase AI Logic + App Check; the key never ships in the
  client; degrades to the fallback offline), and **GemmaBrain** (on-device, experimental).
- The **grounding invariant**, enforced in code: the scorer owns the verdict, the agent
  never overrides it; and **only derived, non-PII facts** (a `mistakeId` enum, struggle
  tags, `letterId`) ever cross the network — never raw strokes, never the nickname/PII.
- **Dynamic, grounded exercise selection** over baa's existing 19 Schema-v2 configs — the
  agent reasons about the child's recent mistakes; the curriculum rails the choices.
- **Presence + voice** (streamed/TTS coaching within a real latency budget; the millisecond
  stroke reflex stays local), and an **eval harness** promoted to a regression gate.

**Approach:** the riskiest unknowns ship as **spikes first** (GenUI+native-canvas kill-shot ·
full-path latency/presence · a 3-way Authored-vs-Gemini-vs-Gemma Arabic+grounding bake-off),
then a grounded vertical slice (brain spine → dynamic selection → presence + eval + harden).

**Key context — reversals (recorded, like 06.1 reversed "no Firebase"):** the tutor now runs
**client-side** (Decided said "never") on **Gemini/Gemma, not Claude** — but the
"API key never in the client" rule is **preserved** via Firebase AI Logic + App Check.
On-device Gemma is pulled forward from DEFER **only as a bake-off candidate**, off the
critical path; the AuthoredFallback floor keeps the app fully offline + grounded with no
model loaded, so offline-first (PLAT-01) holds without depending on an on-device model.

**Deferred (out of this milestone):** a server-side A2UI brain + its framework (ADK/Genkit/
custom; **not** Pydantic AI), model routing, child-voice STT, the parent analytics dashboard.

## Milestones

- **v1 — Core Learning Loop (this milestone, ~one semester):** the owner's **Sprint 1**.
  Handwriting tracing with on-device feedback, pronunciation audio, sentence-building
  and grammar exercises, lesson unlocking, local child + parent profiles. Local-only,
  on-device, **no Claude tutor yet.**
- **v2 — Qalam AI Tutor (next milestone):** the owner's **Sprint 2**. The warm Claude
  tutor (voice feedback, ask-out-loud), placement exam, adaptive daily lessons,
  across-session profile compilation, parent analytics dashboard. Brings in Firebase
  Auth, Firestore cloud sync, and Python Cloud Functions.
- **Backlog (Nice-to-Have):** teacher views/assignments, multi-child accounts, reminder
  notifications. (Streaks and badges are deliberately excluded — see Key Decisions.)

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- ✓ Flutter (Android) project shell builds and runs — existing
- ✓ Codebase mapped, conventions and structure documented — existing

### Active

<!-- v1 scope = owner's Sprint 1, as written. Hypotheses until shipped and validated.
     Story IDs (S1-xx) trace back to docs/USER_STORIES.md. -->

- [ ] **S1-01** Child opens the app and immediately sees today's lesson already prepared
- [ ] **S1-02** Parent creates a child profile (name + grade) so the right curriculum loads
- [ ] **S1-03** Child picks an avatar and nickname on first open (feels personal)
- [ ] **S1-04** Child watches a correct-stroke-order animation before writing a letter
- [ ] **S1-05** Child traces letters with a stylus and gets instant **on-device** feedback on shape and stroke order
- [ ] **S1-06** Child hears the correct pronunciation of each letter and word
- [ ] **S1-07** Child completes sentence-building exercises (how words connect to form meaning)
- [ ] **S1-08** Child completes grammar exercises at their level
- [ ] **S1-09** Next lesson unlocks only after the child passes the current one
- [ ] **S1-10** Child earns a **mastery star** on lesson completion — a marker of real progress shown on the journey map (no running totals, no weekly tallies, no streaks/badges)
- [ ] **S1-11** Parent can see the child's completed lessons and scores (local progress view)
- [ ] Full curriculum (28 letters + words/sentences/grammar) loaded from the owner's mother's spec into a faithful schema
- [ ] Runs local-only on one tablet, no account/login, works offline (satisfies NTH-05 by design)

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

**Deferred to v2 (owner's Sprint 2 — the AI Tutor milestone):**
- Warm Claude AI tutor: spoken feedback (S2-02) and ask-Qalam-out-loud (S2-03) — the heart of the product, but it sits on top of the v1 foundation
- Placement exam (S2-01)
- Adaptive daily lesson + extra practice on weak areas (S2-04, S2-05)
- Parent struggle analytics, daily-goal setting, weekly progress report (S2-06, S2-07, S2-10)
- Vocabulary flashcards (S2-08) and reading-comprehension passages (S2-09)
- Across-session nightly profile compiler (the second adaptation timescale)
- Firebase Auth, Firestore cloud sync, and Python Cloud Functions — land with the tutor in v2

**Excluded by decision:**
- Streaks (NTH-01) and badges (NTH-02) — and running star totals / weekly-star tallies / "+N keep going" hype — contradict the not-points-chasing stance. Only **mastery stars** (S1-10, a marker of real progress) and the journey map are in.
- Teacher views / lesson assignment (NTH-06, NTH-07) — backlog, not a near-term goal
- Multi-child under one account (NTH-04) — needs auth; revisit after v2 introduces accounts
- Reminder notifications (NTH-03) — backlog; avoid pressure mechanics
- iOS support (deployment, PencilKit) — Android-only for now
- Teaching Arabic as a foreign language via tap-the-answer / multiple-choice keyboards — the anti-product

## Context

- **Brownfield, very early.** Repo is a minimal Flutter/Android skeleton (`lib/main.dart`
  boilerplate). Real architecture (screens, services, providers, models) is planned but
  not yet built. See `.planning/codebase/` for the full map.
- **The backlog is the owner's** (`docs/USER_STORIES.md`), grouped into Sprint 1 / Sprint 2
  / Nice-to-Have with stable IDs (S1-, S2-, NTH-). Wording is the owner's; we do not
  silently re-scope.
- **v1 is broader than tracing.** Beyond the handwriting loop it includes pronunciation
  audio, sentence-building, and grammar exercises. This is a deliberate owner choice;
  the app remains *handwriting-first* in spirit but covers the early learning loop.
- **The tutor's voice is the product's signature** (warm, calm, specific — a real
  teacher's patience, never a chatbot's cheerfulness; short sentences for a 5–10 year
  old; feedback names the exact fix). It is **built in v2**. v1's feedback is the
  deterministic on-device shape/stroke-order scoring (ML Kit Digital Ink).
- **The tutor has a face: the Qalam mascot.** A reed-pen character (the design
  system's "Qalam") is the consistent *persona of the tutor* — not a game mascot. In
  v1 he demonstrates stroke order and gives the friendly framing; in v2 the voice/AI
  feedback *is Qalam speaking*. This is the embodiment of "the patient teacher sitting
  beside the child."
- **A design system already exists** (`docs/design/kit/`, built in Claude Design) and is
  the **source of truth for product visuals & feel**: "modern manuscript / playful
  calligraphy studio" — warm parchment, ink-teal primary, gold-ink for rewards-only,
  rounded tactile shapes. English/LTR chrome with Arabic as RTL content islands; Western
  numerals; fully-vocalized Arabic in Noto Naskh; kids-UX 64px touch floor. Resolved
  product feel: **warm and friendly, but a real school — not points-chasing.** Stars are
  mastery markers (real progress on a journey map), not an accumulating score.
- **Curriculum is the owner's mother's domain** (graduate degree, years teaching Arabic).
  Stroke order, clean-reps-to-advance, the 3–4 common mistakes per letter, letter intro
  order, and the words/sentences/grammar content come from *her*. We build a schema that
  faithfully holds her spec — we structure the pedagogy, we don't invent it. Her full
  spec is available for this milestone.
- **Likely on-device v1.** With no Claude tutor and no login, v1 may need no backend at
  all — curriculum as bundled assets, progress in local storage. Whether/when Firebase
  enters is a research/architecture question (see open questions), not yet decided.
- **Open research questions** (`docs/RESEARCH_BRIEF.md`): R2 offline-first strategy,
  R3 RTL + connected-script rendering, R4 tutor cost & latency (relevant for v2 planning).
  R1 (handwriting recognition) is resolved — ML Kit Digital Ink, validated by the owner's
  own testing.
- **Child safety is a first-class design constraint:** minimum child data, private by
  default, treated as sensitive in every decision.
- Owner is fluent in Python, new to Dart — Dart choices should be explained plainly.

## Constraints

- **Tech stack**: Flutter + Dart, Android-only, tablet-first, RTL — project decision.
- **State management**: **Riverpod only** — BLoC/GetX explicitly rejected.
- **Architecture**: Handwriting recognition on **Google ML Kit Digital Ink, on-device** —
  validated, not exploratory. No network round-trip for scoring.
- **Architecture (v2)**: Firebase (Auth + Firestore + Cloud Functions, **Python** runtime).
  The tutor **never** runs client-side; the API key lives only in the Function secret.
  These enter when the AI tutor is built.
- **Security**: Children's data is sensitive — minimum collection, private by default.
  The tutor API key never ships in the client.
- **Timeline**: ~2–3 months (one course semester) for v1 — bounds the milestone.
- **Process**: Runs on GSD (discuss → plan → execute → verify); research/approval gates
  are never skipped. Propose options with tradeoffs; the human decides, especially on
  anything pedagogical.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Sprint 1 = v1 milestone; Sprint 2 = v2; NTH = backlog | Matches owner's own sprint planning and a ~one-semester scope | — Pending |
| v1 has NO Claude tutor — on-device ML Kit feedback only | Backlog scopes the AI tutor to Sprint 2; keeps v1 demoable and likely backend-free | — Pending |
| Gentle per-lesson stars allowed (S1-10); no streaks/badges | Owner's call to soften anti-gamification slightly without pressure mechanics | — Pending |
| v1 builds all of Sprint 1 (tracing + audio + sentences + grammar) | Owner chose the full Sprint 1 scope, not handwriting-only | — Pending |
| Local-only, no auth, on-device for v1 | Single-tablet course demo; works offline; defers Firebase to v2 | — Pending |
| Qalam mascot = the tutor's persona (reed-pen character) | Consistent face/voice of the patient teacher; pedagogical, not a game mascot. Reconciles the old "no mascots" rule | — Pending |
| Stars = mastery markers, not a points economy | Keeps the warm design; a star means real mastery (information), not a score to chase. "Real Arabic. Not a game." holds | — Pending |
| Design system (`docs/design/kit/`) is the visual source of truth | Owner built a full kit in Claude Design (tokens, fonts, UI kit, screens); English/LTR chrome, Arabic RTL islands, Western numerals | ✓ Good |
| Handwriting recognition = ML Kit Digital Ink, on-device | Validated by owner's own testing; no network round-trip | ✓ Good |
| Riverpod for state management | Project standard; BLoC/GetX rejected | — Pending |
| **v2.0:** Tutor runs **client-side** (reverses Decided "never client-side") | Technion build: fastest path to a grounded demoable tutor, no server | — Pending |
| **v2.0:** Brain = **Gemini (cloud) / Gemma (on-device)**, not Claude | Client-side needs an on-device/Firebase-proxied model; Claude has no client story here | — Pending |
| **v2.0:** API key still never in client — Firebase AI Logic + App Check | Preserves the original key-safety rule despite the client-side reversal | — Pending |
| **v2.0:** `TutorBrain` interface; AuthoredFallback is the offline floor | Keeps app fully offline + grounded with zero model; Gemini/Gemma swap in behind it | — Pending |
| **v2.0:** Scorer owns the verdict; only derived non-PII facts cross the network | Grounding + child-safety invariant, enforced by guard/test | — Pending |
| **v2.0:** On-device Gemma pulled forward as a **bake-off candidate only** | Small-model Arabic is unproven; measure it, don't bet the demo on it | — Pending |

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
*Last updated: 2026-07-18 after Phase 19 complete (question-presentation overhaul: self-explanatory questions, learned-letters-only cards, micro-drills restored, per-child (childProfileId, letterId) keying with v6→v7 migration; device UAT + mother's card sign-off tracked in 19-HUMAN-UAT.md)*
