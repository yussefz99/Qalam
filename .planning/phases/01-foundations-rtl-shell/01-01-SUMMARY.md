---
phase: 01-foundations-rtl-shell
plan: 01
subsystem: infra
tags: [flutter, dart, riverpod, drift, go_router, gen-l10n, fonts, rtl, arabic, testing, golden-tests]

# Dependency graph
requires: []
provides:
  - "Resolvable Phase-1 dependency set (Riverpod 3, Drift, go_router, flutter_svg, flutter_localizations)"
  - "Four bundled offline OFL fonts (Noto Naskh Arabic, Cairo, Fredoka, Nunito) declared with exact family strings"
  - "gen-l10n seam enabled English-only (app_en.arb, no app_ar.arb) seeded from the UI-SPEC copy table"
  - "riverpod_lint wired via analysis_server_plugin (not custom_lint)"
  - "Six RED Wave-0 validation test files encoding D-01/02, D-05, D-06, D-09, D-10, D-12 acceptance"
affects: [theme-layer, arabic-text-widget, drift-database, go-router, glyph-audit, main-bootstrap]

# Tech tracking
tech-stack:
  added: [flutter_riverpod ^3.3.1, riverpod_annotation ^4.0.2, drift ^2.31.0, sqlite3_flutter_libs ^0.6.0, path_provider ^2.1.0, go_router ^17.2.3, flutter_svg ^2.3.0, flutter_localizations (sdk), build_runner ^2.15.0, riverpod_generator ^4.0.3, riverpod_lint ^3.1.3, drift_dev ^2.31.0]
  patterns: ["Test-first Wave-0 scaffold: acceptance tests land RED against not-yet-built package:qalam/ symbols", "Bundled variable-font TTFs with weight descriptors selecting named instances (offline, no CDN)", "gen-l10n English-only; RTL is per-content (ArabicText), never coupled to locale"]

key-files:
  created: [l10n.yaml, lib/l10n/app_en.arb, assets/fonts/NotoNaskhArabic-Regular.ttf, assets/fonts/Cairo-Regular.ttf, assets/fonts/Fredoka-Medium.ttf, assets/fonts/Nunito-Regular.ttf, test/theme_test.dart, test/data/app_database_test.dart, test/direction_test.dart, test/numeral_isolation_test.dart, test/glyph_audit_golden_test.dart, test/orientation_test.dart]
  modified: [pubspec.yaml, analysis_options.yaml]

key-decisions:
  - "Relaxed drift/drift_dev from RESEARCH-pinned ^2.33.0 to ^2.31.0 to resolve against the installed Flutter 3.41.9 (meta 1.17.0 / analyzer ^9) without dropping riverpod_lint 3.1.3"
  - "Bundled the OFL variable TTFs (the only form shipped in google/fonts) and selected weights via pubspec weight descriptors, rather than sourcing nonexistent static instances"
  - "Six Wave-0 tests reference package:qalam/ symbols so they fail at import/compile (RED for the right reason) — no lib/ stubs added"

patterns-established:
  - "Wave-0 validation contract: every Phase-1 acceptance behavior has a failing test before any production code exists"
  - "Exact font-family strings (Noto Naskh Arabic / Cairo / Fredoka / Nunito) are the contract later TextStyle.fontFamily values must match (Pitfall 3)"
  - "Eastern-Arabic digits (U+0660–U+0669) are explicitly forbidden; Western digits LRI/PDI-isolated inside RTL (D-06)"

requirements-completed: [PLAT-02]

# Metrics
duration: ~18min
completed: 2026-05-31
---

# Phase 1 Plan 01: Foundation Toolchain & Wave-0 Validation Scaffold Summary

**Phase-1 dependency set resolves against Flutter 3.41.9, four offline OFL fonts bundled with exact family strings, gen-l10n wired English-only, riverpod_lint via analysis_server_plugin, and six RED Wave-0 tests encoding the phase's acceptance criteria.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-05-31T15:18Z (approx)
- **Completed:** 2026-05-31T15:36Z (approx)
- **Tasks:** 2
- **Files created/modified:** 14

## Accomplishments
- Wired the verified Phase-1 dependency set; `flutter pub get` resolves cleanly with no version-solve conflict.
- Fetched and bundled the four OFL font families into `assets/fonts/`, declared with the exact family strings later `TextStyle.fontFamily` values must match.
- Enabled `gen-l10n` (`generate: true` + `l10n.yaml` + English-only `app_en.arb`) seeded from the UI-SPEC copy table — no `app_ar.arb`.
- Registered `riverpod_lint` via the `analysis_server_plugin` mechanism (not `custom_lint`).
- Created the six failing Wave-0 test files; the suite is RED for the right reason (missing `package:qalam/` symbols), establishing the validation contract Waves 2–3 turn green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire deps, bundle fonts, enable gen-l10n + riverpod_lint plugin** — `e7b648c` (feat)
2. **Task 2: Create the six failing Wave-0 test files** — `67fca9a` (test)

**Plan metadata:** committed separately (docs: complete plan)

## Files Created/Modified
- `pubspec.yaml` (modified) — Phase-1 dependency pins, `generate: true`, asset + four font-family declarations
- `analysis_options.yaml` (modified) — `plugins: [riverpod_lint]` via analysis_server_plugin; kept `package:flutter_lints`
- `l10n.yaml` (created) — gen-l10n config pointing at `lib/l10n/app_en.arb`
- `lib/l10n/app_en.arb` (created) — English-only UI strings from the UI-SPEC copy table
- `assets/fonts/{NotoNaskhArabic-Regular,Cairo-Regular,Fredoka-Medium,Nunito-Regular}.ttf` (created) — bundled OFL variable TTFs
- `assets/fonts/.gitkeep`, `assets/icons/.gitkeep` (created) — keep asset dirs
- `test/theme_test.dart` (created) — D-01/D-02 semantic-token assertions
- `test/data/app_database_test.dart` (created) — D-09 in-memory Drift persist-across-restart
- `test/direction_test.dart` (created) — D-05 LTR chrome / RTL ArabicText island
- `test/numeral_isolation_test.dart` (created) — D-06 Western digits LRI/PDI-isolated, no Eastern digits
- `test/glyph_audit_golden_test.dart` (created) — D-12 four-form shaping golden gate
- `test/orientation_test.dart` (created) — D-10 landscape lock (runtime + manifest)

## Decisions Made
- **drift/drift_dev relaxed to ^2.31.0** (from RESEARCH ^2.33.0): see Deviations — a genuine solver conflict on the installed SDK.
- **Bundled OFL variable TTFs, weights via descriptors:** the four families ship only as variable fonts in `google/fonts`; static instances do not exist there. Flutter selects the required weights (Regular/Medium 500/SemiBold 600) from each variable font's weight axis via the pubspec `weight` descriptors. Lower-risk than sourcing instances from elsewhere; the D-12 glyph audit (plan 01-03) will confirm shaping at the child-facing 96px.
- **Tests reference `package:qalam/` symbols** so failures are import/compile-time (the intended RED), never self-errors in the test files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Relaxed drift/drift_dev pins to resolve the dependency graph**
- **Found during:** Task 1 (`flutter pub get`)
- **Issue:** RESEARCH pinned `drift ^2.33.0` / `drift_dev ^2.33.0`. On the installed Flutter **3.41.9** (which pins `meta 1.17.0`), `drift_dev 2.32+/2.33` require `analyzer >=10`, while `riverpod_lint 3.1.3` requires `analyzer ^9.0.0`; the newer `riverpod_lint 3.1.4-dev` needs `analyzer ^12` → `meta ^1.18.0`, conflicting with the SDK's `meta 1.17.0`. Version solving failed.
- **Fix:** Relaxed `drift` and `drift_dev` to `^2.31.0` (same minor line, no major-version drop). `drift_dev 2.31` allows `analyzer >=8.1 <11`, overlapping `riverpod_lint 3.1.3`'s `analyzer ^9`. `drift_dev 2.31` requires `drift >=2.30 <2.32`, so the runtime `drift` pin moved in lockstep. Documented inline in `pubspec.yaml`.
- **Files modified:** pubspec.yaml, pubspec.lock
- **Verification:** `flutter pub get` exits 0; resolves drift 2.31.0 + riverpod_lint 3.1.3 + analyzer 9.0.0 + meta 1.17.0.
- **Committed in:** e7b648c (Task 1 commit)

**2. [Rule 3 - Blocking] Bundled variable-font TTFs (no static instances in the OFL repo)**
- **Found during:** Task 1 (font fetch)
- **Issue:** RESEARCH/PATTERNS assumed static TTFs (e.g. `Cairo-SemiBold.ttf`, `Fredoka-SemiBold.ttf`). The `google/fonts` OFL repo ships these four families **only as variable fonts** (`NotoNaskhArabic[wght]`, `Cairo[slnt,wght]`, `Fredoka[wdth,wght]`, `Nunito[wght]`); the named static instances do not exist there.
- **Fix:** Downloaded the variable TTFs and declared them in `pubspec.yaml` with `weight:` descriptors so Flutter renders the needed instances (Cairo 400/600, Fredoka 500/600, Nunito 400/600, Noto Naskh Regular) from each weight axis. Files named by their primary role (`*-Regular.ttf` / `Fredoka-Medium.ttf`).
- **Files modified:** assets/fonts/*.ttf, pubspec.yaml
- **Verification:** All four TTFs present and validated as TrueType (`file`); `flutter pub get` accepts the fonts block; family-string greps pass.
- **Committed in:** e7b648c (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 - blocking).
**Impact on plan:** Both were forced by the actual environment (installed SDK + what the OFL repo ships) and were resolved with the minimal change. No scope creep; the D-12 audit (plan 01-03) remains the gate that confirms the variable-font weights shape correctly.

## Issues Encountered
- The dependency solver conflict (deviation 1) was the only real blocker; resolved by walking `drift_dev` back to the 2.31 line after checking pub.dev analyzer/meta constraints for each candidate version.

## Known Stubs
None — this plan deliberately produces RED tests against not-yet-built `lib/` symbols. That is the intended Wave-0 outcome (the next plans implement against these tests), not a stub. No `lib/` placeholder code was added.

## Threat Flags
None. Phase 1 introduces no network, auth, PII, or secrets. The only trust boundary (pub.dev installs at `flutter pub get`) was accepted in the plan's threat register — all packages are first-party Flutter-team or mature ecosystem packages.

## User Setup Required
None — no external service configuration required. (Fonts are bundled offline; no CDN, no API keys.)

## Next Phase Readiness
- The toolchain and validation contract are in place. The next plans (Waves 2–3) implement `lib/theme/`, `lib/data/app_database.dart`, `lib/widgets/arabic_text.dart`, `lib/screens/*`, `lib/router/`, `lib/dev/glyph_audit_screen.dart`, and rewrite `lib/main.dart` (`lockOrientation`) to turn each RED test green.
- Carry-forward note: the existing `test/widget_test.dart` (default counter boilerplate referencing `MyApp`) still compiles against the untouched counter `main.dart`; the plan that rewrites `main.dart` should replace it.
- Watch item for plan 01-03: confirm the bundled **variable** fonts shape correctly at 96px in the D-12 glyph audit; Amiri remains the documented escape hatch if Noto Naskh mis-shapes a curriculum letter.

## Self-Check: PASSED

All 13 created files verified present on disk; both task commits (`e7b648c`, `67fca9a`) verified in git history.

---
*Phase: 01-foundations-rtl-shell*
*Completed: 2026-05-31*
