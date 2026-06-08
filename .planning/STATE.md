---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Phase 05 Plan 04 complete — Home greeting reads chosen nickname label + avatar (S1-03) GREEN
last_updated: "2026-06-08T17:32:00.000Z"
last_activity: 2026-06-08 -- Completed 05-04 Wave 3 home greeting integration
progress:
  total_phases: 13
  completed_phases: 6
  total_plans: 28
  completed_plans: 28
  percent: 54
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-30)

**Core value:** A child traces an Arabic letter, gets immediate specific feedback on their actual strokes, and advances through a real teacher's curriculum — so the language sticks through the hand.
**Current focus:** Phase 05 — profiles-onboarding

## Current Position

Phase: 05 (profiles-onboarding) — EXECUTING
Plan: 4 of 4 (all plans complete)
Status: Executing Phase 05
Last activity: 2026-06-08 -- Completed 05-04-PLAN.md (Wave 3 home greeting integration)

Progress: [██░░░░░░░░] 20% (2 of 10 phases complete)

## Performance Metrics

**Velocity:**

- Total plans completed: 9
- Average duration: — min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 02.1 | 4 | - | - |
| 02.1.1 | 5 | - | - |

**Recent Trend:**

- Last 5 plans: none yet
- Trend: —

*Updated after each plan completion*
| Phase 01 P01 | 18 | 2 tasks | 14 files |
| Phase 01 P02 | ~40min | 3 tasks | 20 files |
| Phase 01 P03 | ~25min | 3 tasks | 7 files |
| Phase 05 P01 | ~18min | 2 tasks | 6 files |
| Phase 05 P02 | ~20min | 2 tasks | 7 files |
| Phase 05 P03 | ~11min | 2 tasks | 8 files |
| Phase 05 P04 | ~12min | 1 task | 3 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Roadmap: built as vertical MVP slices (thin trace-one-letter loop early, then thicken).
- Roadmap: CUR-01 seeded in Phase 2, fully satisfied in Phase 7; PLAT-01 owned by Phase 10.
- Decided (PROJECT.md): v1 local-only, on-device, no Firebase, no Claude tutor.
- [Phase 01]: Relaxed drift/drift_dev to ^2.31.0 to resolve against Flutter 3.41.9 (analyzer ^9 / meta 1.17.0) without dropping riverpod_lint 3.1.3
- [Phase 01]: Bundled OFL variable-font TTFs (the only form in google/fonts) and selected weights via pubspec weight descriptors; D-12 glyph audit (01-03) confirms shaping
- [Phase ?]: AppDatabase.close() spares an injected executor so a shared in-memory store survives a simulated restart (D-09 test shape)
- [Phase ?]: Minimal GlyphAuditScreen created so the golden test compiles; D-12 baseline + full harness remain plan 01-03 (golden red by design)
- [Phase ?]: analyzer-9 plugins section must be a map (riverpod_lint), not a list, for flutter analyze to exit 0
- [Phase 01]: D-12 glyph-audit risk gate CLOSED — human-confirmed Noto Naskh Arabic shapes all four contextual forms correctly (no tofu, لا → single ﻻ ligature, joins intact, tashkeel placed, Western digits LTR); golden-gated via test/goldens/glyph_audit.png. Amiri remains the documented fallback if a future curriculum letter fails re-audit.
- [Phase ?]: Arabic goldens must load bundled TTFs into the headless engine via test/flutter_test_config.dart (Pitfall 3) — otherwise the golden renders tofu and the gate proves nothing.
- [Phase 02]: Reference stroke paths extracted from NotoNaskhArabic-Regular.ttf via Python fonttools script (D-01, D-02); owner maps contours to teaching strokes and records in letters.json (D-03); alif must be signedOff: true before Phase 2 is done (D-12).
- [Phase 02]: All 28 letters authored in Phase 2 with structural data; only alif needs signedOff: true for Phase 3; remaining 27 carry referenceStrokes: [] + signedOff: false (D-05, D-07).
- [Phase 02]: CurriculumRepository uses rootBundle (not network); keepAlive: true Riverpod provider; handles exercises.json absence gracefully (D-10).
- [Phase 02]: lib/models/*.dart must not import from lib/data/ or lib/features/ — pure immutable domain types only.
- [Phase 05]: Wave 0 RED contract authored — every S1-02/S1-03/gate behavior has an executable failing assertion before implementation (Nyquist). Implementer must produce: ChildProfiles table + create/get/hasProfile, ChildProfileRepository, onboarding_data (kAvatarIds/kNicknames/gradeToStartingLessonId/resolveStartingLessonId), OnboardingScreen, profile_providers (childProfileProvider, OnboardingGate).
- [Phase 05]: Tests using flutter_test null matchers alongside drift must `import 'package:drift/drift.dart' hide isNull, isNotNull;` to avoid the matcher name collision.
- [Phase 05]: Home greeting test pins nick_star -> label 'نجمة' and avatar key homeAvatar_avatar_1; grade kg -> startingLessonId 'alif' (S1-02 default seam).
- [Phase 05]: 05-02 turned the data-layer RED tests GREEN — ChildProfiles table at schema v3 (fixed-set IDs only, no real name; S1-03), v2->v3 idempotent migration preserving AppSettings+LetterMastery, ChildProfileRepository, childProfileProvider, OnboardingGate, onboarding_data (6 avatars / 8 placeholder nicknames / all-grades->alif). S1-02 + S1-03 mechanism complete.
- [Phase 05]: childProfileProvider is a HAND-WRITTEN FutureProvider, not @riverpod codegen — riverpod_generator 4.0.3 throws InvalidTypeException when a functional provider returns a Drift-generated data class (ChildProfile). Manual FutureProvider preserves the .overrideWith((ref) async => profile) test contract.
- [Phase 05]: onboardingGate (ChangeNotifier-as-provider, the router refreshListenable) emits one un-suppressible riverpod_lint `unsupported_provider_value` warning; plugin honors no ignore form in riverpod_lint 3.1.3 — left visible + documented (prescribed pattern, not a defect).
- [Phase 05]: 05-03 turned the screen + router-gate RED tests GREEN — OnboardingScreen (one scrollable card, grade chips/avatar grid/nickname grid/"Let's go", PopScope(canPop:false), NO free-text), app_router synchronous redirect gate (both rules, no loop) + refreshListenable, main.dart boot hasProfile() read + appDatabaseProvider/onboardingGateProvider overrides. Fresh install -> /onboarding -> tap-through -> Home; relaunch skips onboarding. S1-02 + S1-03 delivered end-to-end.
- [Phase 05]: Onboarding card spacing compacted so the "Let's go" CTA fits within the 800x600 widget-test viewport (Wave-0 happy-path taps the CTA without scrolling).
- [Phase 05]: Remaining home-greeting-integration (Home reads childProfileProvider nickname) is the last Phase-5 RED test (home_screen_test Test 1) — deferred from 05-03 (out of scope; home_screen.dart not in 05-03's files). See deferred-items.md.
- [Phase 05]: 05-04 turned the last Phase-5 RED test GREEN — Home greeting now reads childProfileProvider and renders the chosen fixed-set nickname LABEL (via ArabicText island) + chosen avatar circle (keyed homeAvatar_<id>), replacing hardcoded 'Welcome back, Layla.'. Scope-aware split (_GreetingHeader/_GreetingHeaderReader/_GreetingLayout) degrades to static greeting on no-scope/loading/error/null (T-05-07); resolveNicknameLabel(id) added to onboarding_data (ID->label in code); homeGreeting ARB is a {nickname} String template. PLAT-03 held. S1-03 "shown on home" closed end-to-end.
- [Phase 05]: home_screen_test Test 4 (Journey nav must not navigate) stays deferred (deferred-items item 2) — stale vs commit 4d03e63 which intentionally unlocked Journey nav; not this plan's surface.

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

None yet.

### Blockers/Concerns

- **Geometric stroke scorer (deepest risk, Phase 3–4):** NOT provided by ML Kit (ML Kit gives only {text, score}); custom build + per-letter calibration against real child samples.
- **Offline / one-time model download (open question, Phase 10):** verify on a fresh, no-network install.
- ~~**Phase 2 sign-off gate:**~~ CLOSED — alif signedOff: true, 1 referenceStroke (64 pts), 3 commonMistakes authored. Phase 3 is unblocked.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260601-wa0 | Add DEMO launch flag to boot app at /demo/home | 2026-06-01 | eed35c0 | [260601-wa0-add-demo-launch-flag-to-boot-app-at-demo](./quick/260601-wa0-add-demo-launch-flag-to-boot-app-at-demo/) |
| 260602-00f | Rebuild demo Home faithful to home.png (owner override: gamification) | 2026-06-02 | 586b195 | [260602-00f-rebuild-demo-home-faithful-to-home-png-d](./quick/260602-00f-rebuild-demo-home-faithful-to-home-png-d/) |
| 260602-bw1 | Rebuild Watch/Trace/Feedback/Celebration faithful to mockups; demo loop → Baa (owner override: gamification) | 2026-06-02 | 326c221 | [260602-bw1-rebuild-demo-walkthrough-baa](./quick/260602-bw1-rebuild-demo-walkthrough-baa/) |
| 260607-pr1 | Practice screen three-zone Trace/ShowFix/ShowPraise tutor redesign + Hear-the-letter (UI-only; scorer/state-machine/persistence untouched) | 2026-06-07 | 8f8eb56 | [practice-redesign spec](../docs/design/practice-redesign/) |

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-06-08
Stopped at: Completed 05-04-PLAN.md — Wave 3 home greeting integration (S1-03 "shown on home" GREEN)
Resume file: .planning/phases/05-profiles-onboarding/05-04-SUMMARY.md
