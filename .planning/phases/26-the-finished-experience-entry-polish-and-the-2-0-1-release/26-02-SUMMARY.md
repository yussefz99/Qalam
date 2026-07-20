---
phase: 26-the-finished-experience-entry-polish-and-the-2-0-1-release
plan: 02
subsystem: infra
tags: [flutter_launcher_icons, adaptive-icon, android, branding, launcher-icon, mipmap]

# Dependency graph
requires:
  - phase: design-system
    provides: "Qalam brand art (docs/design/kit qalam-nib.svg + ICONOGRAPHY.md) and the parchment token (#FAF6EE)"
provides:
  - "Real Qalam ADAPTIVE Android launcher icon (nib mark on parchment) replacing the stock Flutter default across all mipmap densities + anydpi-v26"
  - "flutter_launcher_icons build-time generator wired via flutter_launcher_icons.yaml — repeatable icon regeneration"
  - "assets/branding/qalam_icon_foreground.png — reusable 1024px rasterized nib brand mark"
affects: [26-06-device-pass, release-2.0.1, ios-launcher-icon-followup]

# Tech tracking
tech-stack:
  added: ["flutter_launcher_icons ^0.14.4 (dev-only, publisher fluttercommunity.dev)"]
  patterns: ["Dependency-free stdlib PNG rasterization of brand SVG geometry (no imagemagick/cairosvg in env)", "Adaptive-icon: parchment color background layer + transparent nib foreground layer"]

key-files:
  created:
    - assets/branding/qalam_icon_foreground.png
    - flutter_launcher_icons.yaml
    - android/app/src/main/res/values/colors.xml
    - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
    - android/app/src/main/res/drawable-{h,m,xh,xxh,xxx}dpi/ic_launcher_foreground.png
  modified:
    - pubspec.yaml
    - pubspec.lock
    - android/app/src/main/res/mipmap-{h,m,xh,xxh,xxx}dpi/ic_launcher.png

key-decisions:
  - "Icon = the qalam-nib pictogram (not the mascot, not emoji/unicode) per ICONOGRAPHY.md — mascot is illustration, banned for sub-80px iconography."
  - "Rasterized the nib SVG geometry directly with a dependency-free Python stdlib script — no SVG rasterizer (imagemagick/rsvg/cairosvg/PIL) exists in this environment; avoids the known testWidgets/font-drift render flakiness."
  - "Parchment background = design-system token #FAF6EE (--parchment, lib/theme/colors.dart) — matches the Play listing art; not a new invented colour."
  - "ios: false — the iOS AppIcon is OUTSIDE this plan's files_modified and iOS is a later port per CLAUDE.md. NOTE: the iOS iconset is CURRENTLY also the Flutter default (plan premise was wrong) — flagged for a separate owner-authorized pass."

patterns-established:
  - "Launcher icon regenerates from a single tracked source PNG via `dart run flutter_launcher_icons`."
  - "Adaptive-icon background colour lives as a named resource (ic_launcher_background) in res/values/colors.xml, referenced by mipmap-anydpi-v26/ic_launcher.xml."

requirements-completed: [PLAT-01]

# Metrics
duration: 12min
completed: 2026-07-20
---

# Phase 26 Plan 02: Launcher icon — real Qalam adaptive mark replaces the Flutter default (Android) Summary

**The stock blue Flutter default Android launcher is replaced by the real Qalam reed-nib brand mark on a parchment adaptive-icon background, generated build-time via flutter_launcher_icons across all mipmap densities; the debug APK builds clean.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-07-20T15:06:31Z
- **Completed:** 2026-07-20T15:18:55Z
- **Tasks:** 2 of 2
- **Files modified:** 19 (2 pubspec, 1 config, 1 source PNG, 1 colors.xml, 1 adaptive XML, 5 mipmap PNG, 5 drawable PNG)

## Accomplishments
- Rasterized the `qalam-nib` brand mark (docs/design/kit) to a 1024x1024 safe-zone foreground PNG and wired `flutter_launcher_icons` to generate the full Android adaptive icon set.
- Every Android density (`mipmap-hdpi..xxxhdpi/ic_launcher.png`) now carries the Qalam mark; the git-confirmed stock Flutter default (untouched since commit e9fc86c) is gone.
- Adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`) composites the nib foreground over the design-system parchment background `#FAF6EE` — matching the Play listing.
- `flutter build apk --debug` exits 0 with the new resources.

## Task Commits

Each task was committed atomically:

1. **Task 1: Render brand foreground + parchment background + write icon-generation config** - `9a53b83` (feat)
2. **Task 2: Generate adaptive Android launcher, replace Flutter default, confirm iOS** - `ca2733d` (feat)

## Files Created/Modified
- `assets/branding/qalam_icon_foreground.png` - 1024x1024 transparent nib mark, centered in the adaptive safe zone (~60% box, inside the inner 66% circle).
- `flutter_launcher_icons.yaml` - Generator config: `android: true`, `ios: false`, image/foreground = the nib PNG, `adaptive_icon_background: "#FAF6EE"`.
- `android/app/src/main/res/values/colors.xml` - Defines `ic_launcher_background = #FAF6EE` (parchment token).
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` - `<adaptive-icon>` with parchment `<background>` + inset nib `<foreground>`.
- `android/app/src/main/res/mipmap-*dpi/ic_launcher.png` (5) - Regenerated legacy icons (Flutter default overwritten).
- `android/app/src/main/res/drawable-*dpi/ic_launcher_foreground.png` (5) - Per-density nib foreground drawables referenced by the adaptive XML.
- `pubspec.yaml` / `pubspec.lock` - Added `flutter_launcher_icons ^0.14.4` (dev-only), resolved to 0.14.4.

## Decisions Made
- **Nib pictogram, not the mascot or emoji.** ICONOGRAPHY.md bans emoji/unicode and reserves the mascot for illustration (>=80px); the qalam-nib is the designated small brand mark. The rendered mark is a faithful reproduction of `qalam-nib.svg` geometry (teal body #0E5B5F, lighter facet #168A8F, gold ink channel #F2A60C — all app-palette colours).
- **Self-rasterized the SVG.** No SVG-to-PNG tool (imagemagick, rsvg-convert, inkscape, cairosvg, PIL) is installed. Rather than risk flutter_svg-in-widget-test rendering (known font-drift / testWidgets-stall issues in this repo), I rasterized the nib's exact polygon geometry with a dependency-free Python stdlib script (4x4 supersampled, zlib+struct PNG writer). Fully deterministic; the source geometry is copied verbatim from the SVG.
- **Parchment cited, not invented.** Background = `#FAF6EE`, the `--parchment` token (`lib/theme/colors.dart:11`, `docs/design/kit`), the Play listing surface.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] colors.xml comment broke the AAPT resource merge**
- **Found during:** Task 2 (`flutter build apk --debug`)
- **Issue:** My initial `colors.xml` comment contained `--` sequences (`--parchment`). AAPT/`mergeDebugResources` rejects `--` inside XML comment bodies -> `BUILD FAILED`.
- **Fix:** Reworded the comment to remove all internal `--` (kept the legal `<!--`/`-->` delimiters only).
- **Files modified:** `android/app/src/main/res/values/colors.xml`
- **Verification:** Rebuild succeeded — `Built build/app/outputs/flutter-apk/app-debug.apk`.
- **Committed in:** `ca2733d` (Task 2 commit)

**2. [Rule 3 - Blocking] Committed generator outputs not listed in files_modified**
- **Found during:** Task 2 (running the generator)
- **Issue:** `flutter_launcher_icons` necessarily emits `drawable-*dpi/ic_launcher_foreground.png` (5 files, referenced by the adaptive `ic_launcher.xml`) and `pubspec.lock` changed from adding the dev-dep. Neither the 5 drawables nor `pubspec.lock` are in the plan's `files_modified` list, but the adaptive icon will not build/render without the drawables, and `pubspec.lock` is tracked and must stay consistent with `pubspec.yaml`.
- **Fix:** Committed the 5 foreground drawables (Task 2) and `pubspec.lock` (Task 1) as mandatory artifacts of the plan-prescribed generator run. No pre-existing splash drawables (`drawable/`, `drawable-v21/launch_background.xml`) were touched.
- **Verification:** `git status` shows only `android/app/src/main/res/**` + pubspec changes; APK builds.
- **Committed in:** `9a53b83`, `ca2733d`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking). Plus 1 scope flag (iOS, below).
**Impact on plan:** Both auto-fixes were necessary for a building, correct adaptive icon. No scope creep — all changes stay within Android launcher resources + the icon dev-dependency.

## Flag (loud) — iOS launcher is ALSO the Flutter default; plan premise was wrong

The plan (and this executor's critical-context) assumed **"the iOS AppIcon.appiconset already carries the Qalam mark."** It does NOT. I read `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` and it is the **stock blue Flutter default**, same as the Android default was. So Phase-26 Success Criterion 2 ("no Flutter default anywhere") is **NOT** met on iOS by this plan.

I deliberately did **not** regenerate iOS here because:
1. The iOS AppIcon files are **outside this plan's `files_modified`**, and my execution boundary is "no modifications outside files_modified + SUMMARY" (parallel-wave merge safety).
2. CLAUDE.md: **"Android-only for now; iOS is a later port — do not add iOS-specific work unless asked."** Regenerating ~16 iOS PNGs is exactly the iOS work that requires an explicit owner ask.

The mechanism is ready: flipping `ios: false -> true` in `flutter_launcher_icons.yaml` (add `remove_alpha_ios: true`) and re-running `dart run flutter_launcher_icons` will replace the iOS default from the same nib source. **Recommend the orchestrator/owner authorize a small iOS-icon follow-up** (iPad is a co-equal demo device per project memory) so SC2 holds on both platforms.

## Issues Encountered
- No SVG rasterizer in the environment (resolved by the stdlib Python rasterizer — see Decisions).
- AAPT `--`-in-comment build failure (resolved — Deviation 1).

## Threat Model
- T-26-02-SC (Tampering, flutter_launcher_icons dev-dep): **mitigated** — verified on pub.dev before adding (publisher `fluttercommunity.dev`, latest stable 0.14.4), pinned `^0.14.4`, dev-only (never shipped in the app binary).
- T-26-02-01 (Spoofing, brand mark): **accepted** — public brand art only, no sensitive data in an app icon.
- No new network/auth/trust-boundary surface introduced (build-time asset compiled into the APK; no runtime input).

## Known Stubs
None — the launcher icon is fully wired and renders the real brand mark; no placeholder/empty-data paths introduced.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Android adaptive launcher is ready for the **26-06 device pass** — on-device visual confirm (home-screen tile shows the nib on parchment, no blue Flutter default) is deferred there per the plan's human-check.
- **Blocker for SC2 (cross-platform):** iOS launcher still shows the Flutter default — needs a separate owner-authorized iOS icon pass (see the loud flag above) before the 2.0.1 cut can claim "no Flutter default anywhere."

## Self-Check: PASSED

- All 10 created/generated files present on disk (source PNG, config, colors.xml, adaptive XML, 5 foreground drawables, SUMMARY).
- Both task commits present in git history (`9a53b83`, `ca2733d`).
- `flutter pub get` clean; `flutter build apk --debug` exits 0.

---
*Phase: 26-the-finished-experience-entry-polish-and-the-2-0-1-release*
*Completed: 2026-07-20*
