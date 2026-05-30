# Phase 1: Foundations & RTL Shell - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a runnable Android-tablet app skeleton that everything else builds on:
correct right-to-left layout, the Qalam design-system theme (tokens + bundled fonts),
declarative routing, and a working local Drift database. This phase proves the
*foundation* renders Arabic correctly and persists data — it does NOT build the
tracing surface, scoring, lessons, or any screen content (those are later phases).

**In scope:** RTL app shell; design-token theme layer (`lib/theme/`); bundled fonts;
`go_router` skeleton; Drift DB with a trivial persist/read proven across restart;
landscape orientation lock; glyph audit of the Arabic font; numeral-system wiring.

**Out of scope (later phases):** stroke capture/scoring (P3/P4), curriculum schema
(P2), profiles (P5), lessons/home/journey (P6), exercises (P8), parent area (P9),
the mascot's animated states and any AI/voice (v2).
</domain>

<decisions>
## Implementation Decisions

### Visual foundation — driven by the design system
- **D-01:** The Qalam Design System in `docs/design/kit/` is the **source of truth** for
  all visuals. Phase 1 lifts its tokens — never hard-code hex/fonts. Translate
  `colors_and_type.css` into a Dart theme layer: `lib/theme/colors.dart`,
  `text_styles.dart`, `dimens.dart` (spacing/radii/shadows/motion), `app_theme.dart`,
  plus a `ThemeExtension` for brand tokens Material doesn't cover (e.g. `--reward`,
  surface tints).
- **D-02:** Semantic tokens, not raw palette, in widgets (`--primary` = ink-teal
  `#168A8F`, `--bg` = parchment `#FAF6EE`, `--reward` = gold `#F2A60C` **rewards-only**,
  `--success` = leaf, `--warn-soft` = coral — **never red**). Background is warm
  parchment, never stark white.

### Fonts (must be bundled — offline rule)
- **D-03:** Bundle these as local TTFs in `assets/fonts/` and declare in `pubspec.yaml`
  — do NOT use the CSS's Google-Fonts CDN `@import` and do NOT use the `google_fonts`
  runtime-fetch package (violates the offline-first rule):
  - **Fredoka** — English display/headings/buttons
  - **Nunito** — English body/labels
  - **Noto Naskh Arabic** — Arabic reading & tracing content (with tashkeel)
  - **Cairo** — Arabic display / the قلم logo
- **D-04:** Wire fonts into `ThemeData.textTheme` following the kit's type scale
  (kids-UX floor: 18px base; Arabic content set 10–25% larger than nearby English;
  line-height 1.7 plain Arabic / 2.0 with tashkeel).

### Direction & language
- **D-05:** App chrome is **English / LTR** (nav, buttons, instructions, parent screens).
  Arabic appears **only as RTL content islands** wrapped in `Directionality(rtl)` /
  `dir="rtl"`-equivalent. **Mirror only Arabic content blocks, not the whole app.**
- **D-06:** **Western numerals (0–9) everywhere**, including inside Arabic blocks
  (LTR-isolate digits, equivalent to the kit's `.q-num`). Decided explicitly — do not
  leave to locale defaults.
- **D-07 (foundation only):** Set up a light i18n/l10n seam (Flutter `gen-l10n`) so UI
  strings aren't hardcoded, but v1 ships **English strings only**. No Arabic UI
  translation in v1. Keep it low-magic.

### Shell, routing, persistence, orientation
- **D-08:** Use **`go_router`** for declarative routing; Phase 1 only needs a minimal
  route tree (a placeholder home) — the real screens come later. Leave a seam for a
  PIN-gated `/parent/*` branch (built in P9), do not build it now.
- **D-09:** Use **Drift** (SQLite) for local persistence. Phase 1 proves the DB by
  persisting and reading back a trivial value across an app restart. Full curriculum &
  progress schemas come in P2/P5 — keep Phase 1's schema minimal.
- **D-10:** **Lock orientation to landscape** (matches the kit's 1280×900 canvas; most
  room for the tracing surface). Set in the Android manifest / `SystemChrome`.
- **D-11:** **Riverpod with code-generation** (`flutter_riverpod` + `riverpod_generator`
  + `riverpod_lint`), `build_runner` wired (also needed by Drift). Riverpod only — no
  BLoC/GetX. Lower-magic for a Dart-new owner.

### Glyph audit (the phase's real risk — R3)
- **D-12:** Before declaring Phase 1 done, audit Noto Naskh Arabic against a
  representative set of curriculum letters in all four contextual forms
  (isolated/initial/medial/final) — confirm correct joining, no tofu/boxes, no broken
  shaping. This de-risks the tracing surface (P3) and the dotted guide letter.

### Product-feel guardrails (cross-cutting, set the tone here)
- **D-13:** Qalam **mascot = the tutor's persona**, not a game mascot (Phase 1 may wire
  the logo/brand; mascot states & any voice are v2). **Stars = mastery markers** only;
  no running totals, no weekly tallies, no streaks/badges, no "+N keep going" hype, no
  emoji or unicode pseudo-icons (use brand glyphs in `docs/design/kit/project/assets/`).
  "Real Arabic. Not a game." — warm presentation, serious curriculum.

### Claude's Discretion
- Exact Dart token naming/structure inside `lib/theme/`, the `ThemeExtension` shape, and
  how `gen-l10n` is wired — standard Flutter patterns; planner/executor decide.
- Whether the trivial Phase-1 persistence proof is a tiny `app_settings` table or a
  key/value row — implementer's call.
- Sourcing the TTFs (Google Fonts files are open-licensed: OFL) and the exact font
  weights to bundle.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design system (source of truth for visuals)
- `docs/design/kit/project/SKILL.md` — brand hard-rules (gold rewards-only, no red, no
  emoji, Arabic content rules, Western numerals, kids-UX 64px floor, mirror-Arabic-only)
- `docs/design/kit/project/colors_and_type.css` — ALL color/type/spacing/radii/shadow/
  motion tokens to translate into `lib/theme/`
- `docs/design/kit/README.md` — handoff instructions (recreate visuals, don't copy
  prototype structure)
- `docs/design/kit/project/ui_kits/qalam_app/` — tablet UI kit (1280×900) for layout/
  pixel reference (later phases; Phase 1 only needs the shell + tokens)
- `docs/design/kit/project/preview/` — token specimen cards (colors/type/spacing)

### Research (foundation + risk)
- `.planning/research/STACK.md` — prescriptive package list & versions (Flutter, Riverpod
  codegen, Drift, go_router, fonts) — verify versions at plan time
- `.planning/research/ARCHITECTURE.md` — layering, provider organization, v1→v2 seams
- `.planning/research/PITFALLS.md` — RTL/connected-script Flutter traps (R3), font glyph
  coverage, numeral handling — directly relevant to Phase 1
- `.planning/research/SUMMARY.md` — "watch out for" overview

### Project scope & requirements
- `.planning/PROJECT.md` — product identity, constraints, v1/v2 split
- `.planning/REQUIREMENTS.md` — PLAT-02 (this phase), PLAT-03 (cross-cutting)
- `.planning/ROADMAP.md` — Phase 1 success criteria
- `docs/USER_STORIES.md` — owner's backlog (S1-/S2-/NTH-)
- `.planning/codebase/CONVENTIONS.md`, `STRUCTURE.md` — Dart conventions + planned `lib/` layout
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/main.dart` — only boilerplate counter app exists; it will be replaced by the
  real `MyApp` root (MaterialApp.router + theme + RTL setup).
- `docs/design/kit/project/assets/` — logo, brand glyph SVGs (star, ink-drop, lock,
  check, nib), mascot placeholders — usable via `flutter_svg`.

### Established Patterns
- Dart conventions are standard (snake_case files, PascalCase classes, `const`
  liberally, `flutter_lints`). Match them.
- No state management, routing, theme, or DB wired yet — Phase 1 establishes all of
  these patterns for the first time, so set them up cleanly (they become the template).

### Integration Points
- `android/app/src/main/AndroidManifest.xml` — orientation lock + app config.
- `pubspec.yaml` — add dependencies, declare `assets/fonts/` and asset dirs.
- `lib/main.dart` → new `lib/theme/`, `lib/router/`, `lib/data/` (Drift) modules.
</code_context>

<specifics>
## Specific Ideas

- Visual identity is fully specified: **"modern manuscript / playful calligraphy
  studio"** — warm parchment, ink-teal primary, gold rewards-only, rounded tactile
  shapes, soft low shadows (never glossy), gentle motion. Realize it from the kit tokens.
- The قلم logo uses Cairo; bundle it so the wordmark renders.
- Soft "sticker" press shadow for primary buttons (`--shadow-button` flat-bottom) is a
  signature detail — capture it in the theme even if buttons are built later.
</specifics>

<deferred>
## Deferred Ideas

- **Mascot animated states + voice** (idle/cheer/think/write/try-again) and AI feedback
  → v2 (Sprint 2). Phase 1 only establishes brand/logo.
- **Journey/level map** home (Variant A) and the **MASTERED celebration** (Variant B) →
  realized in P6 (home/progression) and P3 (celebration), per the kit's screens.
- **PIN-gated parent area** → P9 (leave only a routing seam now).
- **Real curriculum reference-path format** (coords vs prose, owner's-mother sign-off) →
  P2 open question.
- **Commission a real illustrator** for the mascot's 5 states (kit mascot is placeholder)
  → product backlog.
- Custom icon set to replace Lucide-style stand-ins → pre-launch backlog.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>

---

*Phase: 1-Foundations & RTL Shell*
*Context gathered: 2026-05-30*
