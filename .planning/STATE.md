---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Phase 6 UI-SPEC approved
last_updated: "2026-06-11T18:37:21.788Z"
last_activity: 2026-06-11 -- Phase 06 execution started
progress:
  total_phases: 13
  completed_phases: 7
  total_plans: 42
  completed_plans: 33
  percent: 54
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-30)

**Core value:** A child traces an Arabic letter, gets immediate specific feedback on their actual strokes, and advances through a real teacher's curriculum — so the language sticks through the hand.
**Current focus:** Phase 06 — lesson-progression-home

## Current Position

Phase: 06 (lesson-progression-home) — EXECUTING
Plan: 1 of 8
Phase: 05 (profiles-onboarding) — 4/4 plans complete, verification human_needed (device UAT)
Status: Executing Phase 06
Last activity: 2026-06-11 -- Phase 06 execution started

Progress: [█████░░░░░] 54% (7 of 13 tracked phases complete)
<!-- reconciled 2026-06-11: 13 tracked phases (integer 1-10 + inserted 02.1/02.1.1/03.1). Complete: 1, 2, 02.1, 02.1.1, 3, 03.1, 5. Phase 4 in progress (5/6, 04-06 deferred). Evidence: every plan in those phases has a SUMMARY file; scorer + curriculum repo + models exist in lib/. -->
<!-- Of the 10 INTEGER milestone phases, 4 are complete (1, 2, 3, 5); Phase 4 is 5/6. -->

## Performance Metrics

**Velocity:**

- Total plans completed: 33 of 34 (only 04-06 deferred/human-gated)
- Phases complete: 7 of 13 tracked (1, 2, 02.1, 02.1.1, 3, 03.1, 5); Phase 4 in progress (5/6)
- Average duration: — min
- Total execution time: 0.0 hours

<!-- reconciled 2026-06-11: prior "9 plans / 2 of 10 phases" was stale and contradicted frontmatter completed_plans=33. -->

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
| Phase 04 P01 | 6 | 2 tasks | 9 files |
| Phase 04 P02 | 5 | 2 tasks | 3 files |
| Phase 04 P03 | 5 | 2 tasks | 10 files |
| Phase 04 P04 | 11 | 2 tasks | 9 files |
| Phase 04 P05 | 5 | 2 tasks | 5 files |
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
- [Phase 04]: Tolerances are data not code — normal preset == today's scorer constants (A5); loose/strict move only maxCurvature (0.35/0.18) for now
- [Phase 04]: New whole-letter MistakeId values (count/order/dot/identity) keep enum-name == commonMistakes[].check; LetterResult mirrors StrokeResult; validateTolerances added as V5 sibling
- [Phase 04]: scoreLetter is the pure-Dart whole-letter spine (count→order→shape→combined-bbox dot→advisory ML Kit gate); returns Future<LetterResult> because the D-04 identity gate is async
- [Phase 04]: scoreStroke now reads Tolerances (default Tolerances.normal, A5 behavior-preserving); file-level threshold consts removed, predicate names unchanged (check-string contract)
- [Phase 04]: Dot position uses whole-letter combined-bbox y-centroid (Pitfall 2) so baa-dot-below vs taa-dots-above survives normalization; ML Kit gate advisory-only with a 0.5 confidence floor (Pitfall 1)
- [Phase 04]: MlKitRecognizer is the on-device advisory-only identity gate (D-04): reports {topCandidate, confidence} via google_mlkit_digital_ink_recognition, never a verdict; the gating decision stays in scoreLetter
- [Phase 04]: HandwritingRecognizer.identify seam widened to a whole multi-stroke letter (List<List<List<double>>>); ML Kit score is sparse/inverted so it is NOT mapped to confidence directly
- [Phase 04]: ModelDownloadService @Riverpod(keepAlive) background-fetches the ar model best-effort with isReady; any failure degrades to a calm getting-ready state, never hard-blocks (D-05); manager injected via overridable inkModelManagerProvider for tests
- [Phase 04]: StrokeCanvas accumulates a whole multi-stroke letter (no per-pointer-down clear) and fires onLetterComplete at count-reached; practice_screen scores the whole letter via scoreLetter (referenceStrokes.first path removed); D-05 getting-ready is a non-blocking overlay; four whole-letter MistakeIds resolve to authored l10n, never fallback
- [Phase 04]: Calibration harness is a pure-Dart confusion-table flutter-test running the REAL scoreLetter over labeled fixtures (FN=good-rejected, FP=named-bad-passed); no Python re-impl (A3); FN-over-FP tuning priority
- [Phase 04]: Labeled-sample capture (D-02) added to /dev/authoring behind kDebugMode (never child-facing); reuses combined-bbox normalizeToStrokeSpecs; synthetic baa seed pins the regression contract, real-tablet captures land in Plan 06
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
- [Phase 05]: Device boot crash fixed — sqlite3_flutter_libs ^0.6.0 resolved to the empty 0.6.0+eol tombstone (no native lib; for the package:sqlite3 3.x migration). Our stack is drift 2.31 + sqlite3 2.9.4 (2.x); repinned ^0.5.41 so libsqlite3.so ships in the APK. Corrected 01-RESEARCH.md.

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

None yet.

### Blockers/Concerns

- **Geometric stroke scorer (deepest risk, Phase 3–4):** NOT provided by ML Kit (ML Kit gives only {text, score}); custom build + per-letter calibration against real child samples.
- **Offline / one-time model download (open question, Phase 10):** verify on a fresh, no-network install.
- ~~**Phase 2 sign-off gate:**~~ CLOSED — alif signedOff: true, 1 referenceStroke (64 pts), 3 commonMistakes authored. Phase 3 is unblocked.
- Phase 04 plan 04-06 (baa-family sign-off) DEFERRED — blocked on real-world resources: requires a real Android tablet + the owner's mother + real children to author/label/sign off baa/taa/thaa and tune per-letter tolerances on real samples (cannot be done on emulator, per plan note). Plans 04-01..04-05 complete. Re-run /gsd:execute-phase 4 when resources available to finish 04-06 and complete the phase.

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

Last session: 2026-06-11T15:47:11.859Z
Stopped at: Phase 6 UI-SPEC approved
Resume files: .planning/phases/05-profiles-onboarding/05-04-SUMMARY.md, .planning/phases/04-scoring-quality-calibration/04-06-PLAN.md (deferred)
