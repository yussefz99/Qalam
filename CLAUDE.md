# CLAUDE.md — Qalam

**Qalam teaches children to *write* Arabic by hand — really write it, stroke by
stroke — the way a patient teacher sitting beside them would.** Android tablet,
right-to-left, no points-chasing, no cartoon mascots. Daily structured practice in
the spirit of Kumon. *"Real Arabic. Not a game."*

Currently a Technion course project. **Android-only for now;** iOS is a later port —
do not add iOS-specific work unless asked.

---

## What we're building

Almost every Arabic app teaches Arabic as a *foreign* language — tap-the-answer,
multiple choice, a keyboard. None teach a child to form the letters by hand, which is
the one thing that makes the language stick. Qalam is for **heritage learners**: kids
who hear Arabic at home but can't yet read or write it.

The core loop is physical: a dotted letter appears, the child traces it with a stylus,
the app scores the strokes on-device, and a warm AI tutor responds with specific,
human feedback. Then they do it again. That guided repetition is the whole product.

The competition isn't Duolingo — it's a $60/hour private tutor, an underfunded weekend
school, or nothing. Qalam is the patient teacher available at 9pm on a Tuesday.

---

## The tutor's voice  (the heart of the app — get this right)

The tutor is **warm, calm, and specific** — a real teacher's patience, never a
chatbot's cheerfulness. Short sentences, pitched to a 5–10 year old. Feedback always
names the exact fix:

- Good:  *"Your baa needs a deeper curve at the bottom — try again, slower this time."*
- Never: *"Oops, try again!"*

It celebrates real progress and does not over-praise sloppy work. A little Arabic is
welcome (أحسنت — well done), but guidance stays in the child's working language. This
voice comes from the owner's mother (see Curriculum below); it is the product's
signature, not a detail.

---

## How we work  (always on, every phase)

- **Research before you build.** Resolve the open questions below before writing code
  that depends on them. This project runs on **GSD** — follow its loop
  (discuss → plan → execute → verify) and never skip its research/approval gates.
- **Propose, don't decide.** Lay out options with tradeoffs; the human makes the call,
  especially on anything pedagogical.
- **Python over TypeScript** for all backend and tooling. The owner is fluent in Python
  and new to Dart — explain Dart choices plainly, keep the magic low.
- **When unsure, ask.** A wrong autonomous build costs far more than a question.

---

## Decided  (do NOT relitigate; flag loudly if anything contradicts these)

- Flutter + Dart, **Android-only for now** (tablet-first, RTL).
- Firebase: Auth + Firestore + Cloud Functions (**Python** runtime).
- **Handwriting recognition: Google ML Kit Digital Ink — VALIDATED by our own testing,
  not exploratory.** Build the handwriting layer on ML Kit, on-device, no network
  round-trip for scoring.
- The tutor **never** runs client-side.
- Two-timescale adaptation: within-session (tutor sees full session history) +
  across-session (nightly job recompiles each child's `strengths[]` / `struggles[]`).
- Handwriting-first, **not points-chasing.** Reconciled with the design system
  (owner's call, 2026-05-30):
  - **Qalam mascot = the tutor's persona**, not a game mascot. The reed-pen character
    is the consistent face of the patient teacher; when voice/AI lands (v2), feedback
    *is Qalam speaking*. He demonstrates stroke order. This is pedagogical, not
    gamification.
  - **Stars = mastery markers**, earned only by real clean-reps and shown on the
    journey map as genuine progress. **No** running point totals, **no** weekly-star
    tallies, **no** streaks, **no** badges, **no** "+N keep going" hype, **no**
    leaderboards. A star means "you truly mastered this letter" — information, not score.
  - **Warm, kid-friendly visuals are encouraged** (parchment/ink palette, rounded
    shapes, a dignified per-mastery celebration). "Real Arabic. Not a game." still
    holds — friendly presentation, serious curriculum.
  - Source of truth for product feel: `docs/design/kit/` (Qalam Design System).
- Child safety: collect the minimum child data needed, private by default, under parent
  control. Treat children's data as sensitive in every design decision.
- **Parent accounts — LIVE (owner override, 2026-06-22).** The earlier "no real
  accounts in v1" line is lifted: real Email/Password + Google **parent** sign-in/up
  is now in scope (`AuthService` + `lib/screens/parent_auth_screen.dart`), ~~reachable
  ONLY from **behind the PIN-gated parent area**~~. The child-safety core is **unchanged**:
  **children still NEVER log in** (D-09b child-login ban holds). Sign-up links the boot
  anonymous identity (D-09c) so local progress is kept; sign-out restores an anonymous
  identity. ~~Foundation scope — the account does not yet gate or sync any data.~~ Google
  needs the Firebase console SHA-1 + Web client id (`--dart-define=GOOGLE_SERVER_CLIENT_ID`).
  - **AMENDED 2026-07-20 (D-01/D-02, Phase 26 — owner decision).** The entry model is now
    **account-first**: a parent account is the **mandatory FRONT DOOR** — every launch
    starts at `/auth` and the whole app is behind a required parent sign-in (ratifies the
    as-built `lib/router/app_router.dart` redirect). This **supersedes** two clauses above:
    (a) ~~"reachable ONLY from behind the PIN-gated parent area"~~ — the account is now the
    front door, not a behind-the-PIN extra; (b) ~~"does not yet gate ... any data"~~ — the
    account now **gates all use**. **UNCHANGED by this amendment:** D-09b (children NEVER
    log in — the *parent* signs in), D-09c (sign-up links the boot anonymous identity;
    sign-out returns to anonymous, never stranding — Plan 26-01), and the account still
    does **NOT SYNC** data across devices (sync stays future scope; only the GATING clause
    changed). Compliance consequence (D-03): the Play data-safety + app-access forms and
    the hosted legal page must declare account-gating + parent-email collection, matching
    the code — see `docs/legal/RELEASE-COMPLIANCE-2.0.1.md`.

---

## Still open  (resolve via research before the related code)

- **Offline-first strategy** + how the parent dashboard reconciles when the child
  reconnects.
- **RTL + connected-script rendering** in Flutter — letter forms
  (isolated/initial/medial/final), a font with strong Arabic glyphs, known pitfalls.
- **Tutor cost + latency** — calls per session, prompt caching, and the acceptable
  delay between a finished stroke and on-screen feedback.

*(Handwriting recognition was here — now Decided, thanks to the ML Kit testing.)*

---

## Curriculum is the owner's mother's domain

She has a graduate degree and years of teaching Arabic. Stroke order, how many clean
reps advance a child, the 3–4 most common mistakes per letter, and the order letters
are introduced come from **her** — not from research or guesswork. Build a schema that
faithfully holds her spec. Do not invent the pedagogy; structure it.

---

## Domain agents — routing map

A team of specialist subagents is installed (project-level in `.claude/agents/` plus
the Flutter plugin). **When a phase needs work in a domain below, delegate to the
matching specialist — or, if delegation isn't available, adopt that specialist's role
in place.** Keep the orchestrator thin; let specialists do the deep work.

| Concern | Specialist | Notes |
|---|---|---|
| App architecture, structure, DI, navigation | `flutter-architect` | `flutter-expert` as a second opinion on hard calls |
| State management | `flutter-state-management` | **Riverpod only** — reject any BLoC/GetX default |
| UI implementation (widgets, screens) | `flutter-ui-implementer` | build from the existing Claude Design mockups |
| Child UX & interaction design, RTL layout | `flutter-ui-designer`, `ui-designer` | child-friendly UX is a distinct craft |
| Stylus capture + ML Kit Digital Ink integration | `flutter-expert` | on-device scoring, no network round-trip |
| Firebase client (Auth, Firestore, FCM) | `flutter-firebase` | client-side wiring only |
| Cloud Functions backend (the tutor server) | `python-pro` | **Python** runtime |
| Tutor pipeline / AI system design | `ai-engineer` | Flutter → Function → Claude; the two-timescale design |
| Tutor system prompts + nightly profile compiler | `prompt-engineer` | owns the tutor's *voice* (see above) |
| Security: API key, Firestore rules, child data | `security-auditor` | key only in the Function secret |
| Code review / quality gate | `code-reviewer` | review agent-written Dart before merge |
| Tests (unit / widget / integration) | `flutter-testing` | |
| Offline behavior + app lifecycle | `mobile-developer` | if installed |
| Android build & release | `flutter-android-deployment` | later phases only |

**Precedence & rules:**
- The **Decided** section overrides any specialist's defaults. If an agent proposes
  something against it (BLoC, iOS work, a client-side API key), **stop and flag it.**
- Project agents in `.claude/agents/` outrank global (`~/.claude/agents/`) ones.
- `flutter-patterns` is an on-demand **skill** (reference for widget/testing/perf/
  security/animation patterns), not a worker — consult it, don't delegate to it.

---

## Where things live

- `.planning/` — GSD's project state (PROJECT, REQUIREMENTS, ROADMAP, STATE, config).
- `.planning/research/` — project research (STACK, FEATURES, ARCHITECTURE, PITFALLS, SUMMARY).
- `.planning/codebase/` — codebase map (ARCHITECTURE, STRUCTURE, STACK, …).
- `docs/USER_STORIES.md` — the owner's backlog (S1-/S2-/NTH- IDs) — source for requirements.
- `docs/design/kit/` — the Qalam Design System (tokens, fonts, UI kit, screenshots) —
  **canonical source of truth for product visuals & feel.** `colors_and_type.css` =
  tokens; `project/SKILL.md` = brand rules; `project/ui_kits/qalam_app/` = tablet UI kit.
- `docs/RESEARCH_BRIEF.md` — open research questions (R2/R3/R4); R1 resolved (ML Kit).
- `docs/architecture/` — compiled decisions / ADRs (as they accrue).

---

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->