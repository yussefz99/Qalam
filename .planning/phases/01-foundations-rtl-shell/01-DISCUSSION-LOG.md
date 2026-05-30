# Phase 1: Foundations & RTL Shell - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 1-Foundations & RTL Shell
**Areas discussed:** Teaching script & font, UI working language, Orientation & theme mood, (escalated to) Product identity / design-system integration

---

## Gray-area selection

User selected to discuss: **Teaching script & font**, **UI working language**,
**Orientation & theme mood**. (Did not select Numeral system — later resolved by the
design system as Western numerals.)

---

## Teaching script & font

| Option | Description | Selected |
|--------|-------------|----------|
| Noto Naskh Arabic | Clean, legible Naskh teaching script | ✓ (via design system) |
| Amiri | Traditional/calligraphic Naskh | |
| Defer to mother | Capture as open for curriculum sign-off | |

**User's choice:** Superseded — user revealed they had built a full design system in
Claude Design. The kit specifies Arabic = Noto Naskh Arabic (+ Cairo display), English
= Fredoka (display) + Nunito (body).
**Notes:** Diacritics question was answered "defer to your mother"; the design system's
position is fully-vocalized (tashkeel) learning content. Mother confirms at curriculum
sign-off (P2/P7).

---

## UI working language

| Option | Description | Selected |
|--------|-------------|----------|
| English-only chrome | English UI; Arabic only as content | ✓ (via design system) |
| Bilingual EN/AR | | |
| Arabic-first | | |

**User's choice:** Resolved by the design system / brief: English / LTR chrome; Arabic
only as RTL content islands; mirror Arabic blocks, not the whole app.

---

## Orientation & theme mood

| Option | Description | Selected |
|--------|-------------|----------|
| Landscape-locked | Match the 1280×900 design kit; most tracing room | ✓ |
| Support both | Portrait + landscape | |
| Portrait-locked | | |

**User's choice:** Landscape-locked. Theme mood resolved by the design system tokens
(parchment/ink-teal/gold-rewards, soft shadows, rounded radii).

---

## Product identity / design-system integration (escalated)

The user fetched their Claude Design handoff bundle (`docs/design/kit/`). It contradicted
CLAUDE.md's anti-gamification "Decided" rule (mascot, star totals, journey map,
celebration).

| Option | Description | Selected |
|--------|-------------|----------|
| Adopt the design system wholesale | Keep mascot + full star economy + journey + celebration | |
| Warm but curriculum-first | Mascot as teacher + gentle celebration + journey-as-progress; no star economy | |
| Hold the austere "Not a game" line | Tokens only; drop mascot + stars + gamified journey | |
| Let me explain | User describes the reconciliation | ✓ |

**User's choice (free-text):** The mascot is the **persona of the AI tutor** — a
consistent character that the v2 voice/AI features attach to, so feedback feels like the
mascot (the tutor) speaking. Doesn't care about stars — asked for a recommendation.
"Real Arabic" holds — it's a school — but warm, kid-friendly visuals don't make it a game;
kids won't *play* with these things.

**Resolution (confirmed):** Mascot = tutor persona (in). **Stars = mastery markers**
(earned via real clean-reps, shown on the journey map; one dignified per-mastery
celebration) — NO running totals, weekly tallies, streaks, badges, or hype. Warm
presentation, serious curriculum. CLAUDE.md, PROJECT.md, REQUIREMENTS.md updated to match;
design kit committed as the visual source of truth.

---

## Claude's Discretion

- Exact `lib/theme/` token structure, `ThemeExtension` shape, `gen-l10n` wiring.
- Form of the trivial Phase-1 persistence proof (settings table vs key/value row).
- TTF sourcing and exact font weights to bundle.

## Deferred Ideas

- Mascot animated states + voice/AI → v2 (Sprint 2).
- Journey/level-map home (Variant A) → P6; MASTERED celebration (Variant B) → P3.
- PIN-gated parent area → P9 (routing seam only in P1).
- Curriculum reference-path format (coords vs prose) → P2 open question.
- Commission real mascot illustrator; custom icon set → backlog.
