---
phase: 01
slug: foundations-rtl-shell
status: passed
requirement_ids: [PLAT-02]
verified: 2026-05-31
verifier: inline (gsd-verifier hit session limit; orchestrator completed verification against live code + tests)
gates:
  flutter_analyze: "0 issues"
  flutter_test: "+12 all passed"
  d12_human_pass: true
---

# Phase 1 — Verification (Foundations & RTL Shell)

**Status: PASSED** — goal-backward verification against the live codebase and test suite.
All four success criteria are delivered by real code AND a passing test; every binding
constraint (D-01..D-13) holds; scope is clean.

**Live gates (run 2026-05-31):**
- `flutter analyze` → **No issues found.**
- `flutter test` → **+12, all passed** (incl. the human-approved glyph-audit golden).

---

## Success Criteria

### ✓ Criterion 1 — LTR chrome, Arabic RTL islands (not globally mirrored) — D-05
- `lib/app.dart`: NO global `Directionality.rtl`; `supportedLocales: const [Locale('en')]` — English only, never `'ar'`.
- `lib/widgets/arabic_text.dart:76`: the lone RTL island wraps content in `TextDirection.rtl`.
- Test: `test/direction_test.dart` passes (ambient LTR in chrome, RTL only inside `ArabicText`).
- **Verdict:** delivered.

### ✓ Criterion 2 — Correct connected-script Arabic, no tofu/broken joining — D-12
- `lib/dev/glyph_audit_screen.dart`: four contextual forms forced via ZWJ (U+200D) at 96px across the representative tricky-joiner set (ه ع غ ك ل ب ت ث ج ح خ س ش م ي) + لا ligature row + tashkeel row (lh 2.0) + mixed Arabic/digit row.
- Test: `test/glyph_audit_golden_test.dart` passes against committed baseline `test/goldens/glyph_audit.png`. `test/flutter_test_config.dart` loads the bundled TTFs into the headless engine (without it the golden was all-tofu — Pitfall 3 caught and fixed; the gate is now meaningful).
- **D-12 risk gate CLOSED — human-approved PASS on Noto Naskh Arabic** (all six criteria visually confirmed: no tofu, correct contextual shapes, لا → single ﻻ ligature, joins intact, tashkeel unclipped, Western digits 0–9 LTR). No Amiri switch; Amiri remains the documented fallback for Phase 2's real curriculum set.
- **Verdict:** delivered.

### ✓ Criterion 3 — Western numerals 0–9, deliberate and consistent — D-06
- `lib/widgets/arabic_text.dart`: digit runs isolated with LRI (U+2066)…PDI (U+2069); **zero** `NumberFormat` usage (the only path that would emit Eastern-Arabic digits).
- Test: `test/numeral_isolation_test.dart` passes; asserts literal U+0030–U+0039 LTR-isolated and forbids Eastern digits U+0660–U+0669.
- **Verdict:** delivered.

### ✓ Criterion 4 — Drift persists + reads across restart — D-09
- `lib/data/app_database.dart`: `@DriftDatabase(tables: [AppSettings])`, constructor accepts an optional `QueryExecutor` (tests inject `NativeDatabase.memory()`), exposes `putSetting`/`getSetting`.
- Test: `test/data/app_database_test.dart` passes — write → read back through a fresh access survives (simulated restart). Home screen round-trips a value via the Riverpod provider (the seam is visible).
- **Verdict:** delivered.

---

## Binding-Constraint Integrity

| Constraint | Check | Result |
|---|---|---|
| No `letterSpacing` on Arabic (Pitfall 2 / #71220) | text_styles.dart Arabic roles set `letterSpacing: 0` | ✓ |
| Offline fonts — NO google_fonts runtime fetch (D-03) | 4 TTFs in `assets/fonts/`; `google_fonts` is not a dependency (only a "do not use" comment) | ✓ |
| `riverpod_lint` via `analysis_server_plugin`, not custom_lint (D-11) | `analysis_options.yaml` `plugins: riverpod_lint`; no custom_lint | ✓ |
| Landscape lock at both layers (D-10) | `SystemChrome.setPreferredOrientations` in main.dart + `android:screenOrientation` in manifest | ✓ |
| No emoji / raw hex / gamification in widgets (D-13) | screens reference tokens only; matches are "NO stars/streaks/badges" comments | ✓ |
| Riverpod-only (no BLoC/GetX) | providers via `@riverpod` codegen | ✓ |

## Deviations (carried from SUMMARYs — assessed)

| Deviation | Assessment |
|---|---|
| drift/drift_dev relaxed `^2.33.0` → `^2.31.0` (analyzer-9 conflict with riverpod_lint on Flutter 3.41.9) | **Acceptable** — same minor family; both codegens work; no functional impact on the persistence seam. |
| Variable-font TTFs instead of static instances (families ship only as variable in google/fonts) | **Acceptable** — weight descriptors select the needed weights; the human-approved D-12 golden confirms shaping is correct. |
| `test/flutter_test_config.dart` added to load fonts in the headless golden | **Acceptable & necessary** — without it the golden gate was a false pass (all-tofu). Makes the D-12 regression gate genuine. |
| Minimal `GlyphAuditScreen` stub in 01-02 (so the golden compiled), replaced by the full harness in 01-03 | **Acceptable** — expected hand-off between plans. |

## Scope Discipline
No out-of-phase implementation shipped — no scoring, dotted guide, curriculum schema, profiles, lessons, exercises, or PIN gate. Only seams: a commented `/parent` route (P9) and placeholder Practice/Settings screens. The lone "curriculum" reference is a comment in the glyph-audit screen naming the representative letter set. ✓

## Residual Manual Check (not verifiable headlessly)
- **On-device tablet launch.** The widget/golden tests + `flutter analyze` are the proxy for "runs correctly," but actual launch on an Android tablet/emulator (landscape, parchment Home, logo, ArabicText, round-tripped DB value) should be eyeballed once before relying on the shell. Recommended: `flutter run` on a landscape tablet emulator.

## Follow-ups for Later Phases
- **Phase 2:** re-run the glyph audit against the owner's-mother's *real* curriculum letter set; if any letter mis-shapes on Noto Naskh, trigger the documented Amiri fallback.
- **Phase 3:** the dotted guide letter must be a vector/path asset (NOT font `Text`) — the font verified here is for content text only.
- **Phase 9:** build the PIN gate on the `/parent` seam left in `app_router.dart`.
