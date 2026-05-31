---
phase: 01-foundations-rtl-shell
plan: 02
subsystem: app-shell
tags: [flutter, dart, riverpod, drift, go_router, theme, rtl, arabic, numerals, landscape, walking-skeleton]

# Dependency graph
requires:
  - "Phase-1 dependency set + bundled fonts + gen-l10n seam + six RED Wave-0 tests (01-01)"
provides:
  - "Semantic theme layer (QalamColors / QalamTextStyles / dimens / QalamTheme ThemeExtension / qalamTheme ThemeData) translated from the design-kit CSS"
  - "ArabicText — the lone RTL island (Directionality.rtl + Noto Naskh + LRI/PDI Western-digit isolation)"
  - "Drift AppDatabase (key/value app_settings) with injectable executor + Riverpod-codegen provider; persistence survives a simulated restart"
  - "go_router skeleton (/ /practice /settings) with a commented /parent PIN-gate seam; appRouter Riverpod-codegen provider"
  - "Landscape lock at both layers (lockOrientation() runtime + android:screenOrientation manifest)"
  - "Home screen wiring the قلم logo, parchment, a vocalized ArabicText sample, and the round-tripped DB value end-to-end"
affects: [practice-screen, settings-screen, glyph-audit, curriculum-schema, tutor-pipeline]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Semantic-token theme: private palette consts → QalamColors semantic getters → ThemeData + QalamTheme ThemeExtension; widgets never read raw hex"
    - "ArabicText is the single RTL island; the app chrome stays LTR (no global Directionality, supportedLocales English-only)"
    - "Western-numeral isolation via LRI(U+2066)…PDI(U+2069) inside RTL — never intl locale-number formatting on ar"
    - "Drift injectable QueryExecutor + close() that spares an injected (shared) executor so a second instance can re-open it (restart proof)"
    - "Riverpod codegen providers for the DB, the router, and the visible persistence proof (no BLoC/GetX)"
    - "Widgets degrade safely under a bare test MaterialApp (null-safe l10n, ProviderScope presence check) so Wave-0 tests pump them directly"

key-files:
  created:
    - lib/theme/colors.dart
    - lib/theme/text_styles.dart
    - lib/theme/dimens.dart
    - lib/theme/brand_theme_ext.dart
    - lib/theme/app_theme.dart
    - lib/data/app_database.dart
    - lib/data/app_database.g.dart
    - lib/widgets/arabic_text.dart
    - lib/router/app_router.dart
    - lib/router/app_router.g.dart
    - lib/screens/home_screen.dart
    - lib/screens/practice_screen.dart
    - lib/screens/settings_screen.dart
    - lib/dev/glyph_audit_screen.dart
    - lib/app.dart
    - lib/main.dart
    - assets/logo.svg
  modified:
    - android/app/src/main/AndroidManifest.xml
    - pubspec.yaml
    - analysis_options.yaml
  deleted:
    - test/widget_test.dart

key-decisions:
  - "AppDatabase.close() is a no-op for an INJECTED executor — the owner controls its lifecycle so a shared in-memory store survives db1.close() and a second instance re-opens it (the exact shape of the D-09 test)"
  - "Created a minimal real GlyphAuditScreen now (ZWJ four-form grid) so the already-committed golden test compiles; the human-approved baseline + full harness remain plan 01-03, so the golden stays RED by design"
  - "Home renders the قلم wordmark as Cairo text alongside the SVG, because flutter_svg does not rasterize the logo SVG's embedded <text> glyphs — the SVG is the brand-asset seam, the Cairo wordmark is what's visible"
  - "Fixed the analyzer-9 plugins-section format (list → map: riverpod_lint: ^3.1.3) so flutter analyze exits 0"

requirements-completed: [PLAT-02]

# Metrics
duration: ~40min
completed: 2026-05-31
---

# Phase 1 Plan 02: Walking Skeleton Summary

**The thinnest runnable end-to-end slice: a landscape-locked, LTR-chrome Android-tablet app on warm parchment that renders the قلم brand, shows a correctly-shaped vocalized Arabic string through the lone ArabicText RTL island, and displays a value round-tripped through the Drift database — proving the theme, direction, persistence, and orientation foundation seams at once.**

## Performance

- **Duration:** ~40 min
- **Tasks:** 3 (all TDD — turn the Wave-0 RED tests green)
- **Files created:** 17 · **Modified:** 3 · **Deleted:** 1

## Accomplishments

- **Theme layer** translated one-way from `colors_and_type.css`: `QalamColors` semantic tokens (parchment bg, ink-teal primary, gold reward, coral warn-soft), the full `QalamTextStyles` English + Arabic roles (Arabic carries `letterSpacing: 0` only), `QalamSpace`/`QalamTargets`/`QalamRadii`/`QalamShadows` (incl. the flat-bottom sticker `buttonShadow`)/`QalamMotion`, a `QalamTheme` `ThemeExtension`, and `qalamTheme` `ThemeData` (Material 3, parchment scaffold, no deepPurple). Turns `theme_test.dart` green (D-01/D-02).
- **Drift `AppDatabase`** with a trivial `app_settings` key/value table, an injectable `QueryExecutor`, and `set/getSetting`; a written value survives a simulated restart. Turns `app_database_test.dart` green (D-09).
- **`ArabicText`** — the signature widget bundling the only RTL island, Noto Naskh shaping, and LRI/PDI Western-digit isolation; no `NumberFormat`. Turns `direction_test.dart` (D-05) and `numeral_isolation_test.dart` (D-06) green.
- **`go_router` skeleton** (`/ /practice /settings`) with a commented `/parent` PIN-gate seam, exposed via a Riverpod-codegen provider.
- **Landscape lock at both layers:** `lockOrientation()` in `main.dart` (runtime) + `android:screenOrientation="sensorLandscape"` in the manifest (platform). Turns `orientation_test.dart` green (D-10).
- **Home screen** wires it all: قلم logo (flutter_svg + Cairo wordmark), parchment, a soft-aqua placeholder card with gen-l10n copy, a vocalized `ArabicText` sample (قَلَم with tashkeel), the round-tripped Drift value, and an Open Practice CTA with the sticker shadow. No gamification, no raw hex.
- **`build_runner`** generates `app_database.g.dart` + `app_router.g.dart` (+ riverpod providers) cleanly.
- **`flutter analyze` exits 0**; every non-golden Wave-0 test is green.

## Task Commits

1. **Task 1: Theme layer** — `0c958fc` (feat)
2. **Task 2: Drift DB + ArabicText + go_router + landscape lock** — `b51dfbf` (feat)
3. **Task 3: Home screen end-to-end wiring** — `292f2f6` (feat)

## Test State (D-* gates)

| Test | Decision | Result |
|------|----------|--------|
| theme_test.dart | D-01/D-02 | GREEN |
| data/app_database_test.dart | D-09 | GREEN |
| direction_test.dart | D-05 | GREEN |
| numeral_isolation_test.dart | D-06 | GREEN |
| orientation_test.dart | D-10 | GREEN (runtime + manifest) |
| glyph_audit_golden_test.dart | D-12 | **RED by design** — no baseline yet; plan 01-03 owns the human-approved golden |

Full suite: **+11 / -1** — the single red is the glyph-audit golden (expected).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created a minimal GlyphAuditScreen so the suite compiles**
- **Found during:** Task 2 (running the four named tests)
- **Issue:** The already-committed `test/glyph_audit_golden_test.dart` imports `package:qalam/dev/glyph_audit_screen.dart`. That symbol did not exist, so the ENTIRE `flutter test` run failed at compile time — which would have masked every Wave-0 test this plan turns green. The plan assigns the full GlyphAuditScreen + baseline to plan 01-03.
- **Fix:** Created a minimal but real `GlyphAuditScreen` (the ZWJ four-form grid at 96px Noto Naskh) so the suite compiles. The golden itself stays RED because no `test/goldens/glyph_audit.png` baseline exists — that is the intended single red, owned by plan 01-03 (which lands the human-approved baseline + the complete harness).
- **Files:** lib/dev/glyph_audit_screen.dart
- **Commit:** b51dfbf

**2. [Rule 1 - Bug] AppDatabase.close() must spare an injected executor**
- **Found during:** Task 2 (`app_database_test.dart`)
- **Issue:** The D-09 test shares one `NativeDatabase.memory()` executor between two `AppDatabase` instances; `db1.close()` tore down the shared executor, so the "restarted" `db2` raised `Bad state: Can't re-open a database after closing it`.
- **Fix:** The constructor records whether it created the executor; `close()` only closes a self-created executor and is a no-op for an injected one, leaving lifecycle to the owner. Matches the test's restart semantics; the real app (self-created executor) still closes normally.
- **Files:** lib/data/app_database.dart
- **Commit:** b51dfbf

**3. [Rule 1 - Bug] Home must render under a bare test MaterialApp**
- **Found during:** Task 3 (full suite)
- **Issue:** The D-05 `direction_test` pumps `MaterialApp(home: HomeScreen())` with no `ProviderScope` and no localization delegates. The full `ConsumerWidget` Home threw `No ProviderScope found` (and earlier a null-l10n crash), and the tall column threw a `RenderFlex overflowed` at the 800×600 test surface.
- **Fix:** Home is a `StatelessWidget`; copy reads are null-safe with the canonical English fallback; the persistence-proof reads the provider only when a `ProviderScope` ancestor is present (degrades to an empty box otherwise); the body is wrapped in `SingleChildScrollView` so it never overflows. The real app always supplies the scope/delegates and shows the value normally.
- **Files:** lib/screens/home_screen.dart
- **Commit:** 292f2f6

**4. [Rule 3 - Blocking] Fixed the analyzer-9 plugins-section format**
- **Found during:** Task 3 (`flutter analyze`)
- **Issue:** Wave 1 wrote the `plugins:` section as a YAML list (`- riverpod_lint`). Analyzer 9.0.0 rejects that with `Invalid format for the 'plugins' section`, making `flutter analyze` exit 1 — failing this plan's success gate.
- **Fix:** Changed it to the map form the `analysis_server_plugin` mechanism expects: `plugins:\n  riverpod_lint: ^3.1.3`. `flutter analyze` now exits 0 with no issues.
- **Files:** analysis_options.yaml
- **Commit:** 292f2f6

### Carry-forward cleanup (in-scope per plan)

- Deleted the stale `test/widget_test.dart` (default counter test referencing the removed `MyApp`) and replaced the counter `lib/main.dart` — both noted as in-scope by the plan/environment notes. Done in Task 2 (b51dfbf).

**Total deviations:** 4 auto-fixed (2 Rule 1, 2 Rule 3). All were forced by the test contracts / the installed analyzer; each was resolved with the minimal change and no scope creep.

## Decisions Made

- **Injected-executor `close()` is a no-op** so a shared in-memory store survives the simulated restart (D-09); the self-created on-device executor closes normally.
- **Minimal GlyphAuditScreen now, baseline later** — compile the suite without claiming the D-12 gate, which plan 01-03 owns.
- **Cairo wordmark is the visible قلم** alongside the SVG seam, because flutter_svg does not rasterize the SVG's embedded `<text>` glyphs.
- **`plugins:` map form** for analyzer 9 compatibility.

## Issues Encountered

- The test runner could not start initially (`flutter_tester` missing from the engine cache); resolved by `flutter precache --universal --force`, which downloaded the `darwin-arm64` host tools.

## Known Stubs

- **`lib/screens/practice_screen.dart`, `lib/screens/settings_screen.dart`** — intentional route placeholders (no real content). The plan defers Practice (the stylus ink spike), Settings rows, and the `/parent` PIN gate to plan 01-03 / P9. These are documented deferrals, not silent stubs; the router needs the routes to compile and the Home CTA needs a destination.
- **`lib/dev/glyph_audit_screen.dart`** — minimal grid; the full harness (representative letter set, swap-test, PASS/FAIL criteria) and the human-approved baseline golden land in plan 01-03.

No data-flow stub blocks this plan's goal — the Walking Skeleton runs and shows real round-tripped DB data and a real shaped Arabic string.

## Threat Flags

None. This plan honors the phase threat register: the Drift DB opens in `getApplicationDocumentsDirectory()` (app-private storage) and persists only a trivial non-sensitive sentinel (T-01-02); no network, no telemetry, and the persisted value is never logged (T-01-04). No new network endpoints, auth paths, or trust-boundary surface were introduced.

## Next Phase Readiness

- Plan 01-03 owns: the full `GlyphAuditScreen` harness + human-approved `test/goldens/glyph_audit.png` baseline (turns D-12 green), the real Practice ink spike (`CustomPainter`, Clear + confirm), Settings placeholder rows, and the nav affordance.
- Watch item carried forward: confirm the bundled **variable** Noto Naskh shapes correctly at 96px in the D-12 audit; Amiri remains the documented escape hatch.
- The theme, ArabicText, Drift, router, and orientation seams are now the canonical patterns every later phase extends.

## Self-Check: PASSED

All 11 created lib/asset files verified present on disk; all three task commits (`0c958fc`, `b51dfbf`, `292f2f6`) verified in git history. `flutter analyze` exits 0; the full test suite is +11/-1 with the single red being the by-design glyph-audit golden (plan 01-03).

---
*Phase: 01-foundations-rtl-shell*
*Completed: 2026-05-31*
