# Walking Skeleton — Qalam (v1 Core Learning Loop)

**Phase:** 1
**Generated:** 2026-05-31

## Capability Proven End-to-End

A child opens the Qalam app on an Android tablet (landscape-locked), sees the قلم-branded
Home screen on warm parchment with one correctly-shaped vocalized Arabic string rendered
through the RTL `ArabicText` island, and sees a value that was written to and read back
from the on-device Drift database — proving the theme, RTL/connected-script rendering,
local persistence, and orientation seams all work together in one running app.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | Flutter 3.44.x + Dart, **Android-only** (tablet-first, landscape) | Decided (CLAUDE.md); stylus + on-device ML Kit later; iOS is a deferred port |
| State management | **Riverpod 3.3.1 with code-generation** (`riverpod_generator`, `build_runner`); `riverpod_lint` via `analysis_server_plugin` (NOT custom_lint) | Decided D-11; Riverpod-only (reject BLoC/GetX); codegen is lower-magic for a Dart-new owner |
| Data layer | **Drift 2.33.0** (SQLite via `sqlite3_flutter_libs`), DB file in `getApplicationDocumentsDirectory()` (app-private); injectable `QueryExecutor` so tests use `NativeDatabase.memory()` | Decided D-09; local-only/offline; injectable executor makes the persist-across-restart proof testable in-memory |
| Routing | **go_router 17.2.3**, declarative tree; `/`, `/practice`, `/settings`, a debug `/dev/glyph-audit`, and a commented `/parent` redirect **seam** (PIN gate built in P9) | Decided D-08; Flutter-team-recommended, integrates with Riverpod redirects |
| Direction model | App default **LTR** (English chrome); Arabic appears **only** inside the `ArabicText` widget = the single `Directionality(rtl)` island. **No global RTL.** | Decided D-05; mirror only Arabic content, never the whole app |
| Numerals | **Western 0–9 everywhere**, LTR-isolated inside Arabic via LRI(U+2066)…PDI(U+2069); **never** `intl.NumberFormat` on an `ar` locale | Decided D-06; sidesteps Eastern-digit substitution entirely |
| Arabic font | **Noto Naskh Arabic** (bundled OFL TTF) for content; **Cairo** for the قلم logo/display; **Amiri** kept reachable as the documented glyph-audit fallback | Decided D-03; Flutter engine's reference Arabic test font (strongest rendering guarantee); audit-gated (D-12) |
| Theme | Design-kit CSS (`docs/design/kit/`) translated one-way into `lib/theme/` semantic tokens + a `QalamTheme` `ThemeExtension` for tokens Material lacks (reward, sticker shadow, motion). Widgets read semantic tokens, never raw hex | Decided D-01/D-02; design system is the visual source of truth |
| i18n | Flutter built-in **gen-l10n**, `app_en.arb` only (no `app_ar.arb`); RTL is content-driven, never locale-driven | Decided D-07; low-magic, English-only v1 |
| Orientation | **Landscape lock at both layers**: `android:screenOrientation` in the manifest + `SystemChrome.setPreferredOrientations` in `main()` | Decided D-10; matches the kit's 1280×900 canvas; belt-and-suspenders avoids cold-start portrait flash |
| Deployment target | Local Android tablet / emulator; full-stack run = `flutter run` (no cloud, no backend in v1) | v1 is local-only, offline, no account |
| Directory layout | `lib/{main.dart, app.dart, theme/, router/, data/, widgets/, screens/, l10n/, dev/}`; `assets/{fonts/, icons/, logo.svg}`; tests under `test/` (+ golden) | RESEARCH §Recommended structure; establishes the template every later phase extends |

## Stack Touched in Phase 1

- [x] Project scaffold — deps pinned (Riverpod codegen, Drift, go_router, flutter_svg, flutter_localizations), bundled fonts, `build_runner` codegen, `analysis_server_plugin` lint, gen-l10n
- [x] Routing — real `go_router` tree (`/`, `/practice`, `/settings`) + debug `/dev/glyph-audit` + `/parent` seam
- [x] Database — real Drift read AND write, proven to survive a simulated restart (in-memory test) and shown on Home
- [x] UI — interactive: the Practice stylus-spike (live freehand ink) and Home wired to the DB provider + `ArabicText`
- [x] Deployment — runs on the Android-tablet dev environment via `flutter run` (local-only, offline; no cloud target in v1)

## Out of Scope (Deferred to Later Slices)

> Explicit list so later phases do not re-litigate Phase 1's minimalism.

- Tracing surface proper, the dotted guide letter (vector path, not `Text`), stroke-order animation, geometric scoring, ML Kit identity check — **P3/P4**
- Curriculum schema + reference stroke paths + owner's-mother sign-off — **P2**
- Child profiles, avatar/nickname, onboarding — **P5**
- Lesson progression, home journey map, the MASTERED celebration, mastery stars — **P3/P6**
- Pronunciation audio — **P7**; sentence-building & grammar exercises — **P8**
- PIN-gated parent dashboard (only a routing seam now) — **P9**
- Offline hardening, ML Kit model fetch-once-and-cache — **P10**
- Mascot animated states + voice, AI tutor — **v2**
- Arabic UI translation / `app_ar.arb`, any global RTL — never (RTL is content-driven)

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this skeleton without altering its
architectural decisions (Flutter+Riverpod-codegen+Drift+go_router, LTR-shell/RTL-island,
Western numerals, design-token theme, landscape lock):

- **Phase 2:** Curriculum data schema (code-reads-only) + a small owner's-mother-signed-off letter seed with reference stroke paths.
- **Phase 3:** Trace one seeded letter end-to-end — stroke-order animation, stylus tracing over the dotted guide, first-cut geometric scorer, one quiet mastery star.
- **Phase 4:** Calibrate the scorer's strictness per-letter against real child samples.
- **Phase 5:** Local child profiles + avatar/nickname onboarding (uses the Phase-1 Drift seam).
- **Phase 6:** Daily lesson home + progression/unlock.
- **Phase 7:** Full 28-letter curriculum + bundled pronunciation audio.
- **Phase 8:** Sentence-building + grammar exercises (handwriting-first).
- **Phase 9:** PIN-gated parent dashboard (builds on the Phase-1 `/parent` routing seam).
- **Phase 10:** Offline hardening, ML Kit fetch-once-and-cache, release privacy review.
