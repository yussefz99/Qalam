---
phase: 01-foundations-rtl-shell
plan: 03
subsystem: ui
tags: [flutter, dart, rtl, arabic, connected-script, golden-test, glyph-audit, noto-naskh, custom-painter, stylus, ink, go_router]

# Dependency graph
requires:
  - phase: 01-02
    provides: "Theme layer (QalamColors/QalamTextStyles/dimens), ArabicText RTL island, go_router skeleton (/ /practice /settings), bundled Noto Naskh Arabic font, gen-l10n seam, and the minimal GlyphAuditScreen stub the golden test imports"
provides:
  - "GlyphAuditScreen — the full D-12 four-form ZWJ audit grid (representative tricky-joiner set + لا ligature row + tashkeel row + mixed Arabic/Western-digit row) at 96px on bundled Noto Naskh Arabic, behind the /dev/glyph-audit debug route"
  - "Human-approved golden baseline test/goldens/glyph_audit.png gating connected-script shaping against regression (D-12 risk gate CLOSED)"
  - "test/flutter_test_config.dart — loads the bundled TTFs into the headless test engine so goldens render real glyphs, not tofu (Pitfall 3 fix)"
  - "PracticeScreen — the stylus ink-spike: smooth deep-ink freehand via CustomPainter on a parchment canvas with a guarded Clear (no scoring/guide/star)"
  - "SettingsScreen — parchment placeholder carrying only the /parent PIN-gate routing seam (gate not built)"
affects: [curriculum-schema, trace-letter-loop, scoring, parent-dashboard, glyph-audit-reaudit]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ZWJ (U+200D) form-forcing is an AUDIT-HARNESS-ONLY technique to render each contextual form (isolated/initial/medial/final) in isolation — NEVER used in production strings"
    - "Golden tests require fonts explicitly loaded into the headless engine via flutter_test_config.dart (loadFontFromList over the bundled TTF bytes); without it the engine falls back to Ahem/tofu and the gate is worthless (Pitfall 3)"
    - "The first golden baseline is PROVISIONAL until a human visual-PASS against a known-good reference (D-12) — golden tests gate regressions, but a human must confirm the first baseline is genuinely correct"
    - "Freehand ink renders smoothed paths (quadratic midpoint interpolation between sampled points), not raw polylines, with round cap/join + isAntiAlias for an on-brand stroke"
    - "Low-level Listener pointer capture (not GestureDetector) accumulates per-stroke points — the seam P3 extends for per-stroke order/count and stylus-only palm rejection"
    - "Destructive child actions are coral-tinted soft confirmations (Clear / Keep Writing), never red, never a red X (D-13)"

key-files:
  created:
    - test/flutter_test_config.dart
    - test/goldens/glyph_audit.png
  modified:
    - lib/dev/glyph_audit_screen.dart
    - lib/router/app_router.dart
    - test/glyph_audit_golden_test.dart
    - lib/screens/practice_screen.dart
    - lib/screens/settings_screen.dart

key-decisions:
  - "D-12 PASSED on Noto Naskh Arabic — human visually confirmed all six criteria (no tofu, correct contextual forms, لا → single ﻻ ligature, joins intact, tashkeel placed unclipped at lh 2.0, Western digits 0-9 LTR). NO Amiri switch needed; Amiri remains the documented fallback if a future curriculum letter (Phase 2's real set) fails re-audit."
  - "Golden goldens MUST have fonts loaded via flutter_test_config.dart — the bundled TTFs are pushed into the headless engine, otherwise the golden renders all-tofu and the D-12 gate proves nothing (Pitfall 3)."
  - "ZWJ form-forcing is harness-only and explicitly NEVER enters production strings — the audit grid is the sole place U+200D appears."
  - "Practice captures all pointers via a low-level Listener now; stylus-only filtering + palm/finger rejection is deliberately deferred to P3 (the spike only de-risks ink rendering treatment)."

requirements-completed: [PLAT-02]

# Metrics
duration: ~25min
completed: 2026-05-31
---

# Phase 1 Plan 03: Glyph-Audit Risk Gate + Practice/Settings Shell Summary

**Closed the phase's one hard risk — proving Noto Naskh Arabic shapes connected-script Arabic correctly (all four contextual forms, the لا ligature, placed tashkeel, LTR digits) via a human-approved, golden-gated GlyphAuditScreen (D-12 PASS) — and completed the shell with a smooth deep-ink stylus spike and a Settings placeholder carrying only the future /parent seam.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 3 (Task 1 + Task 2 auto/TDD; Task 3 human-action checkpoint)
- **Files created:** 2 · **Modified:** 5

## Accomplishments

- **D-12 risk gate CLOSED (human-approved PASS on Noto Naskh Arabic).** The full `GlyphAuditScreen` renders the representative tricky-joiner set (ه ع غ ك ل ب ت ث ج ح خ س ش م ي) in all four contextual forms at 96px, forced via the ZWJ (U+200D) audit-harness technique, plus a لا row, a tashkeel row at line-height 2.0, and a mixed Arabic + Western-digit row. A human visually confirmed all six PASS criteria against `test/goldens/glyph_audit.png` — **no tofu, correct contextual shapes, لا renders as the single ﻻ ligature, joins stay connected, tashkeel sits unclipped, Western digits render 0–9 LTR beside Arabic.** No Amiri switch was needed; the font question (R3 / D-12) is resolved on Noto Naskh.
- **Golden regression gate is now armed and genuine.** `test/glyph_audit_golden_test.dart` matches the committed, human-confirmed baseline; the previously-RED golden (red by design since plan 01-02) is now GREEN. Any future shaping regression fails the suite.
- **Pitfall-3 fix (`test/flutter_test_config.dart`).** The headless test engine ships no Arabic font, so the golden originally rendered all-tofu — defeating the entire point of the gate. The config loads the bundled Noto Naskh TTF bytes into the engine via `loadFontFromList` before the golden runs, so the golden captures real shaping.
- **Practice stylus ink-spike.** `PracticeScreen` paints live smoothed freehand ink (deep-ink `#0E5B5F`, width 6, round cap/join, quadratic midpoint smoothing, `isAntiAlias`) via a `CustomPainter` on a parchment canvas inset in a soft-aqua framed card, with a single Clear guarded by the coral-tinted "Clear your writing?" confirm (Clear / Keep Writing — no red). Strokes are in-memory only, discarded on Clear/dispose (threat T-01-05).
- **Settings placeholder shell.** `SettingsScreen` is a parchment placeholder with inert rows and a clear code comment marking the `/parent` PIN-gate routing seam — the gate itself is **not** built (P9 owns it).
- **`flutter analyze` = 0 issues; `flutter test` = +12 all green** (the glyph-audit golden now passes against the committed baseline).

## Task Commits

1. **Task 1: GlyphAuditScreen four-form ZWJ grid + golden baseline (D-12)** — `c732e7f` (feat)
2. **Task 2: Practice ink spike + Settings placeholder shell** — `b7ee6df` (feat)
3. **Task 3: Human visual-PASS of the glyph-audit baseline (D-12 risk gate)** — checkpoint, no code (human replied "approved")

**Plan metadata:** see final `docs(01-03)` commit.

_Tasks 1–2 were committed by a prior executor; this continuation run closed the Task-3 checkpoint and finalized the plan._

## Files Created/Modified

- `lib/dev/glyph_audit_screen.dart` — full four-form ZWJ audit grid at 96px (was a minimal stub from 01-02)
- `lib/router/app_router.dart` — added the `/dev/glyph-audit` debug route (not in user nav; threat T-01-06 accept)
- `test/glyph_audit_golden_test.dart` — pumps the screen and matches the committed baseline
- `test/flutter_test_config.dart` — loads bundled TTFs into the headless engine (Pitfall 3)
- `test/goldens/glyph_audit.png` — the human-approved golden baseline (the D-12 regression gate)
- `lib/screens/practice_screen.dart` — the CustomPainter ink spike + guarded Clear (was a placeholder)
- `lib/screens/settings_screen.dart` — placeholder shell + /parent routing-seam comment (was a placeholder)

## Decisions Made

- **D-12 PASSED on Noto Naskh Arabic** — human-confirmed all six criteria; no font switch. **Amiri remains the documented fallback** if any future curriculum letter (the real Phase-2 set) fails re-audit.
- **Goldens load fonts via `flutter_test_config.dart`** — mandatory for any future Arabic golden; without it the engine renders tofu and the gate is meaningless.
- **ZWJ form-forcing is harness-only** — U+200D appears only in the audit grid, never in production strings.
- **Practice captures all pointers now** — stylus-only filtering and palm/finger rejection are deferred to P3 by design; this plan only de-risks the ink rendering treatment.

## Deviations from Plan

None — plan executed as written. Task 1 noted in its own commit that self-inspection found no shaping faults on Noto Naskh, so the documented Amiri fallback was correctly not triggered; the human PASS in Task 3 confirmed that judgment.

## Out of Scope (deliberately NOT built)

Per the plan's explicit OUT OF SCOPE list, the Practice screen is a rendering spike only — none of the following were built and are owned by later phases:

- **Dotted guide letter** + stroke-order animation (P3)
- **Geometric stroke scoring** / correctness feedback / failing-stroke highlight (P3–P4, the deepest-risk work)
- **Mastery star** / celebration / confetti (P3+; and never streaks/badges/points per D-13)
- **Palm/finger rejection**, stylus-only capture (P3)
- **Settings PIN gate** for `/parent` — only the routing seam comment was left (P9)

## Issues Encountered

- The glyph-audit golden initially rendered all-tofu because the headless test engine carries no Arabic font (Pitfall 3). Resolved in Task 1 by adding `test/flutter_test_config.dart` to push the bundled Noto Naskh TTF bytes into the engine before the golden runs — so the committed baseline captures genuine connected-script shaping. (Recorded here from the Task-1 commit; fix predates this continuation run.)

## Known Stubs

- **`lib/screens/practice_screen.dart`** — an intentional, documented rendering spike: it renders real smooth ink but has no curriculum data, guide, or scoring wired (that is P3's job, not a silent stub). The plan's success criteria explicitly scope it as ink-only.
- **`lib/screens/settings_screen.dart`** — a deliberate placeholder with inert rows and only the `/parent` routing-seam comment; the PIN gate is P9. Documented deferral, not a silent stub.

No stub blocks this plan's goal: the D-12 gate is genuinely proven (real shaped glyphs, human-confirmed) and the ink spike renders real on-brand strokes.

## Threat Flags

None. This plan honors the phase threat register: Practice strokes are held in-memory only and discarded on Clear/dispose (T-01-05 mitigate); the `/dev/glyph-audit` route renders only public Arabic letters and Western digits and is not surfaced in user nav (T-01-06 accept). No network, auth, PII, or new trust-boundary surface introduced.

## Next Phase Readiness

- **Phase 1 is feature-complete across all 3 plans and ready for phase verification.** The RTL shell, glyph-audited Arabic font (Noto Naskh, D-12 PASS), routing, theme, Drift persistence, and the de-risked stylus ink treatment are all in place.
- **Carry-forward for Phase 2/3:** when the owner's-mother's real curriculum letters land, re-run the glyph audit against that exact set; **Amiri is the ready escape hatch** if any letter fails. The `GlyphAuditScreen` + `flutter_test_config.dart` pattern is the reusable mechanism for that re-audit.
- **Carry-forward for Phase 3:** the Practice `Listener`-based pointer capture is the seam to extend for per-stroke order/count, stylus-only filtering, and palm rejection — none of which this spike attempted.

## Self-Check: PASSED

Both created files verified present on disk (`test/flutter_test_config.dart`, `test/goldens/glyph_audit.png`); both task commits (`c732e7f`, `b7ee6df`) verified in git history. `flutter analyze` exits 0; `flutter test` is +12 all green with the glyph-audit golden passing against the committed, human-approved baseline. D-12 risk gate recorded CLOSED (human PASS, Noto Naskh).

---
*Phase: 01-foundations-rtl-shell*
*Completed: 2026-05-31*
