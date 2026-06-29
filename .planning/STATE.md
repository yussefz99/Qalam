---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: — AI Tutor
status: executing
stopped_at: Phase 16 context gathered
last_updated: "2026-06-29T13:01:23.087Z"
last_activity: 2026-06-29
progress:
  total_phases: 20
  completed_phases: 14
  total_plans: 80
  completed_plans: 74
  percent: 70
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-30)

**Core value:** A child traces an Arabic letter, gets immediate specific feedback on their actual strokes, and advances through a real teacher's curriculum — so the language sticks through the hand.
**Current focus:** Phase 16 — build-presence-voice-eval-gate-demo-harden

## Current Position

Phase: 16 (build-presence-voice-eval-gate-demo-harden) — EXECUTING
Plan: 2 of 6
Status: Ready to execute
Last activity: 2026-06-29
Next: human UAT (run app with --dart-define=TUTOR_BASE_URL=<service URL>), then /gsd-verify-work 14 → mark complete; then /gsd-plan-phase 15

## Performance Metrics

**Velocity:**

- Total plans completed: 52 of 34 (only 04-06 deferred/human-gated)
- Phases complete: 7 of 13 tracked (1, 2, 02.1, 02.1.1, 3, 03.1, 5); Phase 4 in progress (5/6)
- Average duration: — min
- Total execution time: 0.0 hours

<!-- reconciled 2026-06-11: prior "9 plans / 2 of 10 phases" was stale and contradicted frontmatter completed_plans=33. -->

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 02.1 | 4 | - | - |
| 02.1.1 | 5 | - | - |
| 09 | 3 | - | - |
| 06.1 | 5 | - | - |
| 11 | 3 | - | - |
| 15 | 8 | - | - |

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
| Phase 06 P07 | ~50min | 2 tasks | 6 files |
| Phase 06 P08 | ~12min | 2 tasks | 8 files |
| Phase 06 P10 | ~7min | 4 tasks | 5 files |
| Phase 06 P09 | ~6min | 1 task | 2 files |
| Phase 09 P01 | ~3min | 2 tasks | 5 files |
| Phase 09 P02 | ~7min | 3 tasks | 7 files |
| Phase 09 P03 | 30 min | 4 tasks | 9 files |
| Phase 06.1 P01 | ~22min | 3 tasks | 11 files |
| Phase 06.1 P02 | ~9min | 2 tasks | 3 files |
| Phase 06.1 P04 | ~20min | 2 tasks | 5 files |
| Phase 06.1 P05 | ~10min | 2 tasks | 4 files |
| Phase 11 P01 | 13min | 2 tasks | 6 files |
| Phase 11 P02 | 9min | 3 tasks | 6 files |
| Phase 15 P01 | 8min | 3 tasks | 10 files |
| Phase 15 P02 | 7min | 2 tasks | 7 files |
| Phase 15 P03 | 5min | 2 tasks | 4 files |
| Phase 15 P04 | 10min | 2 tasks | 8 files |
| Phase 15 P06 | 2min | 1 tasks | 1 files |
| Phase 15 P05 | 16min | 3 tasks | 7 files |
| Phase 15 P07 | 20min | 1 tasks | 4 files |
| Phase 16 P01 | 8min | 2 tasks | 7 files |

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
- [Phase 06]: [Phase 06-07]: MasteryCelebration parameterized on the mastered letter (Pitfall 6 closed); D-14 Next Lesson primary -> /practice?lesson=<next>, D-16 last-lesson See Journey variant, D-17 tutor line.
- [Phase 06]: [Phase 06-07]: Rule-1 fix — PracticeScreen now teaches the lesson's resolved letter (dropped hardcoded getLetter('alif')); Watch heading + per-rep praise templated. Per-letter coaching wording deferred to Phase 7.
- [Phase 06]: [Phase 06-07]: mastery_celebration golden deliberately re-baked ONCE for the D-14/D-17 layout (sanctioned); carries the known local-font-drift caveat; glyph_audit golden untouched.
- [Phase ?]: [Phase 06-08]: Combined-bbox stroke normalization extracted to lib/core/strokes/stroke_normalization.dart (single home; authoring_export delegates, Pitfall 2 preserved).
- [Phase ?]: [Phase 06-08]: StrokeOrderAnimation parameterized with optional duration/color (default-preserving: durWrite + inkStroke when omitted); ghost comparison reuses it at durWrite*2 + warnSoft.
- [Phase ?]: [Phase 06-08]: D-21 ghost comparison shipped — child failing strokes held in _TraceWorkspace State only, cleared on retry/pass/continue/dispose (T-03-01); 'Watch the Difference' shown only when strokes held.
- [Phase 06]: [Phase 06-10]: Dotted-letter dots render as calm ink circles in BOTH Watch animation and Trace guide; painters read StrokeSpec.type directly (ReferencePath.resolve stays point-geometry identity, T-06-10-01).
- [Phase 06]: [Phase 06-10]: Single-point dots excluded from PathMetric length math; each dot gets a small fixed beat and appears just after its body stroke — ink-colored, not gold, no bounce (anti-gamification).
- [Phase 06]: [Phase 06-09]: kClosedLoopEpsilon set to 0.06 (owner-directed, not plan's 0.10) — split-the-gap margin between a ~=0.0 closed outline and taa_h's 0.121, absorbing re-author drift across all 28 letters; D-04 guard confirmed LOAD-TIME-only over authored reference data, never the child's live trace.
- [Phase 09]: [09-01]: Wave-0 RED contract authored — every S1-11 PIN/cooldown/route-gate/read-only-dashboard behavior has an executable failing assertion before implementation (Nyquist, mirrors 05-01). The persisted-cooldown test re-opens a SECOND AppDatabase over the same shared in-memory executor (D-09 shape) to prove a force-quit cannot reset the throttle (T-09-02). RED-by-missing-symbol expected for: PinService, parentGateProvider/ParentGate, ParentDashboardScreen, parentProgressProvider/ParentProgress/ParentLetterRow, allMastered()/allInProgress().
- [Phase 09]: [09-01]: Drift in-progress row class is `LetterRep` (NOT the research-draft `LetterRepData`); mastered rows are `LetterMasteryData` — verified against app_database.g.dart. 17 Phase-9 ARB keys added (parentSummary uses {mastered}/{total} int placeholders — denominator never hardcoded to 28, Pitfall 5); generated app_localizations.dart is gitignored, only app_en.arb tracked. crypto package + its legitimacy checkpoint live in 09-02 (no install in this plan).
- [Phase 09]: [09-02]: PIN security core GREEN. PinService = salted PBKDF2-HMAC-SHA256 (100k iters, Random.secure 16-byte salt) hash/verify with a CONSTANT-TIME XOR-accumulate compare (no early-out, T-09-06) + a Drift-PERSISTED brute-force cooldown (5 fails -> 30s lockUntil in AppSettings; SURVIVES a force-quit, T-09-02 — the phase's key security point). crypto ^3.0.7 added (dart.dev first-party; human-approved legitimacy gate); PBKDF2 hand-rolled over crypto's HMAC (crypto has no KDF). NO new Drift table, NO schemaVersion bump (still 4) — all PIN material in AppSettings keys. flutter_secure_storage deliberately NOT used (one-way hash needs no recovery, T-09-08). pinServiceProvider uses @Riverpod codegen (allowed — returns only bool/void/Duration). Read-only AppDatabase.allMastered()/allInProgress() accessors (no write/edit/delete path, T-09-09) + immutable ParentProgress/ParentLetterRow view model (status enum, named factories). 09-03 wires parent_providers + ParentDashboardScreen + /parent gate.
- [Phase 09]: [09-03]: Parent dashboard screen at lib/screens/ (test import is the binding contract) — parent_dashboard_test imports package:qalam/screens/parent_dashboard_screen.dart. /parent widget is the access boundary (Pattern 3, synchronous redirect, merged refreshListenable); ink-drop nav glyph (A-02). Device-UAT fix: boundary rebuilds on live unlock() via ListenableBuilder (ChangeNotifier-as-provider-value doesn't rebuild on notifyListeners under ref.watch).
- [Phase 06.1]: [06.1-01]: Firebase auth foundation GREEN. FlutterFire wired to qalam-app-bd7d0 (firebase_core 4.10.0 / cloud_firestore 6.5.0 / firebase_auth 6.5.2 — added via `flutter pub add`, pub-resolved lockstep generation, NOT hand-pinned; D-12). `flutter build apk --debug` exits 0 → google-services Gradle plugin links + minSdk satisfies the Firebase floor of 23 (no bump needed, A2 confirmed). AuthService (lib/services/auth_service.dart) wraps an injectable FirebaseAuth (defaults to .instance): ensureSignedIn() mints an anonymous identity ONLY when currentUser==null (idempotent, zero PII — D-09b); linkToPermanent() delegates to currentUser.linkWithCredential, the v2 account-linking seam (defined/unused in v1 — D-09c). main.dart now runs Firebase.initializeApp(DefaultFirebaseOptions.currentPlatform) + AuthService().ensureSignedIn() BEFORE db.hasProfile() (Pattern 3). firebase_auth_mocks ^0.15.2 chosen for the anon boot test (A5 resolved — clean against firebase_auth 6.5.2); mocktail only verifies the link delegation. google-services.json + firebase_options.dart committed (not secrets, research Q2); admin-SDK service-account key path gitignored (T-06.1-02). No child login UI / PII (grep guard empty, T-06.1-01). RUNTIME PREREQ: enable Anonymous/Email-Password/Google providers in the console (Spark tier, no billing — D-16/D-17) before on-device sign-in works.
- [Phase 06.1]: [06.1-04]: Firestore curriculum repository GREEN. CurriculumRepository now reads letters/lessons/ramp Firestore-first via a one-shot .get() (NOT .snapshots() — Pitfall 2), maps docs through the Plan-02 codec, and falls back to the bundled assets/curriculum/*.json on empty/throwing Firestore (cold-first-run floor, D-01/D-02). validateReferenceStrokes runs over WHICHEVER source won; a closed-loop stroke throws and is never cached, never reaches the scorer (D-05, T-06.1-10). New .withFirestore(FirebaseFirestore) test-injection seam (fake_cloud_firestore 4.1.1, resolved clean vs cloud_firestore 6.5.0); .fromStrings preserved unchanged with FirebaseFirestore.instance held LAZILY so bundle/JSON tests stay network-free AND Firebase-free. Ramp source order: meta/toleranceRamp doc -> bundle defaultToleranceRamp -> decided default, defensive never-throws (D-07/Pitfall 5). Read once-at-boot into the kept-alive cache; practice path never blocks (D-03/PLAT-01). All six getter signatures unchanged. 7 fake_cloud_firestore tests + 28 bundle tests GREEN; full suite 394 passed / 4 known pre-existing out-of-scope failures (alif-reference + mastery golden). Rule-2 fix: gitignore extended to *adminsdk*.json (admin-SDK key was unmatched by existing patterns). 06.1-03 (Python seed/export) + 06.1-05 (rules + device verify) remain.
- [Phase ?]: [Phase 06.1]: [06.1-02]: Firestore curriculum codec GREEN. Shared point transform solves the nested-array landmine (D-06) once, mirrored in Dart (firestore_curriculum_codec.dart) and Python (point_codec.py) so seed/export/read agree. Dart codec is PURE (no cloud_firestore import, unit-testable without Firebase) and DEFERS to Letter.fromJson/Lesson.fromJson (re-shapes only points). Round-trip parity proven (D-08): alif deep-equals bundle; skeleton survives empty referenceStrokes plus signedOff false (Pitfall 6); defaultToleranceRamp survives the meta/toleranceRamp doc (collection meta, doc toleranceRamp, field ramp; D-07 resolves Research Q4, Pitfall 5). num to double / float on decode so a Firestore int round-trips. Python self-check asserts identity over all 28 letters. 6 Dart tests plus Python self-check GREEN; full suite 387 passed / 4 known pre-existing failures (no regressions).
- [Phase ?]: [06.1-05]: Firestore security rules DEPLOYED to qalam-app-bd7d0. letters/lessons/meta read-requires-auth (request.auth != null, anonymous OK from Plan 01); ALL client writes denied (allow write: if false — content written only via Plan 03 admin SDK). Deny-by-default catch-all (match /{document=**}) is the child-safety backstop: NO child-data collection match exists (D-11, zero child PII surface in Firestore). Commented per-collection v2 custom-claim seam (request.auth.token.role == admin) keeps role-tightening a deliberate uncomment (D-10); App-Check-compatible by construction (D-10a). firebase.json firestore.rules target merged into flutterfire config (flutter block preserved); .firebaserc default = qalam-app-bd7d0. firebase deploy --only firestore:rules compiled + released clean. Rules Playground 5-check verification documented in test/firestore/rules.test.md as PENDING server-side human check (non-blocking; deploy is the autonomous deliverable).
- [Phase 11]: [11-01]: Installed live genui ^0.9.2 + firebase_ai ^3.13.0 (firebase_core bumped ^4.10.0->^4.11.0, firebase_auth auto-resolved 6.5.3, firebase_app_check 0.4.5 transitive); flutter_genui (discontinued, replacedBy genui) provably ABSENT via the package guard. Resolved known-good set recorded for Phase 14 (Pitfall 4). genui_catalog left uninstalled (optional, defer to Plan 02).
- [Phase 11]: [11-01]: baa fixture COPIES letters.json read-only (Q1) — lib/spike_genui/fixtures/baa_reference.dart imports only StrokeSpec, no curriculum loader/Firestore/Drift. Two guards wired as flutter_test and green: package-correctness + SC-4 durable-layers git-diff (TUTOR-01). Task 3 (Firebase AI Logic console enable on qalam-app-bd7d0) recorded as PENDING HUMAN ACTION — console-only, no CLI path, no human in this autonomous session; NOT blocked because Plan 02 needs only the installed packages + fixture, not the live backend (backend only needed at Plan-03 device runtime). App Check unenforced in throwaway scope (D-13) — must not carry to Phase 14.
- [Phase 11]: [11-02]: Spike GenUI render widget is Surface (not GenUiSurface); data accessor is itemContext.data as JsonMap + BoundString (genui 0.9.2 verified)
- [Phase 11]: Spike A2UI transport: A2uiTransportAdapter onSend -> generateContentStream -> addChunk; FirebaseAI.googleAI Flash, never firebase_vertex_ai
- [Phase ?]: [15-01]: Wave-0 RED contract authored — every Phase-15 requirement (DYN-01/DYN-02/GROUND-03) has a failing automated test naming its exact behavior before implementation (Nyquist). 5 new test files (3 Dart, 2 Python) + 1 JSONL fixture, all RED by missing symbol.
- [Phase ?]: [15-01]: Provisional baa curriculum graph authored as a SEPARATE asset from exercises.json (independent signedOff gate, A5); 19 nodes map each signed baa.* exercise to competency/tier/minCleanReps; node set byte-identical to baa_authored_ids.json (metadata only). signedOff:false (PROVISIONAL, D-05) — 15-07 owns the flip behind human-verify.
- [Phase ?]: [15-01]: tier non-null ONLY for the إملاء writing ramp (connect/complete/writeWord/buildSentence); recognize/trace/recall/morphology nodes tier:null. Backward remediation walks ghayrManzur→manzur→manqul within a competency. DRAFT clean-reps (trace 3, write 2, teach/sentence 1) are owner-mother's to confirm (D-05/D-07).
- [Phase ?]: [15-02]: Server graph rail GREEN — generate.py derives server/app/curriculum_data/curriculum_graph.json from the asset (baa.* nodes only); curriculum.py loads CURRICULUM_GRAPH once at import (fail-closed to empty on read error) + tier_of/reachable_tiers/prerequisites_met; plan.py adds G5 (tier-reachability) + G6 (prereq-chain) after G4, before G3. is_authored/AUTHORED_BAA_IDS untouched (D-02). test_plan_graph.py GREEN.
- [Phase ?]: [15-02]: G5/G6 activate ONLY on a known graph position (clearedTiers OR clearedCompetencies non-empty); both-empty = pre-graph (root child OR pre-15-04 wire) → rail no-op. Forced by Pydantic defaulting both new TutorFactsIn fields to [] + main.py model_dump — the live endpoint always carries the keys, so an unconditional G6 would degrade every online plan run to the floor before 15-04 ships the Dart mirror. Backward remediation passes both guards (Pitfall 3).
- [Phase ?]: [15-02]: TutorFactsIn gains clearedTiers/clearedCompetencies (extra=forbid). Backward-compatible (default []) + rail no-op on empty → a standalone server re-deploy is SAFE; the 422 trap (Pitfall 1) is the FORWARD direction — re-deploy server BEFORE 15-04's Dart fields ship.
- [Phase ?]: [15-03]: Offline-parity GREEN — pure-Dart CurriculumGraph.fromJson (essentialNodes 70/30, tierOf, nextForward declaration-order walk, remediateOneTier=first same-competency node one tier down ghayrManzur→manzur→manqul, null at floor) + CurriculumGraphWalker implements ExerciseSelector{selectNext(TutorFacts,GraphPosition)}: pass→nextForward, fail→remediateOneTier ?? drill-in-place. GraphNode.essential derived from competency at parse. Never the old linear order (Pitfall 5/D-09).
- [Phase ?]: [15-03]: isMasteryMet (D-06) is the on-device star condition — pure over Map<String,int> clean-reps on ESSENTIAL nodes only (missing key=0 reps → clicked-through unit never earns the star, Pitfall 2; enrichment never gates). Never reads a server CoachOut (ADR-014 trust boundary). lib/curriculum gets a SEPARATE stricter import ban (cloud/Firebase/flutter-render/drift/riverpod) layered over the shared durable-layer scan, since lib/data legitimately needs Firebase/drift but lib/curriculum must not.
- [Phase ?]: [15-04]: Drift resume GREEN — LetterGraphPosition table (durable cursor, D-08) + LetterExerciseReps sibling composite-PK table (Open Q3: per-essential-exercise clean-reps for isMasteryMet, lower-migration-risk than a LetterReps PK rebuild) at schema v5; version-guarded idempotent v4→v5 onUpgrade; getPosition Future not stream (Pitfall 6); no-position reads null (clean graph-root start). GraphPositionRepository mirrors DriftProgressRepository.
- [Phase ?]: [15-04]: cleared lists persist as JSON-encoded List<String> in a text column; GraphPosition value type lives in graph_position_repository.dart (not app_database.dart) so DB accessors stay primitive-typed — breaks the repo↔DB import cycle.
- [Phase ?]: [15-04]: TutorFacts gains clearedTiers/clearedCompetencies (whitelisted non-PII string-lists), names mirror server/app/schema.py byte-for-byte (Pitfall 1, 422 lockstep — server side landed 15-02). Three exact-mirror field-set test assertions extended 8→10 fields; payload_nonpii_test extended in place. .g.dart files are TRACKED here, not gitignored. Server re-deploy gated to follow both wire sides landing.
- [Phase 15]: [15-06]: GROUND-03 faithfulness check shipped — app/faithfulness.py is a deterministic, model-AGNOSTIC check (no model/auth/Firebase) scoring coaching against FIXED verdicts; _contradicts flags praise-on-fail (incl. Arabic أحسنت) + wrong-fix (omitted expected-fix token), BOTH gated on a FAIL so a faithful praising PASS is not flagged; evaluate_faithfulness returns {faithful,total,rate,flagged} (9/13=69.23%). Documented as a FLOOR not a ceiling (A6) — Phase 13/16 grow it into the Claude-vs-Gemini bake-off + calibrated judge. 15-01's fixture+test satisfied the contract unchanged.
- [Phase ?]: [15-05]: exerciseSelectorProvider is the SELECTION switch point (sibling of tutorBrainFactoryProvider); RouterExerciseSelector accepts the agent plan.nextExerciseId ONLY when graph-legal (CurriculumGraph.isLegalSelection = authored+reachableTiers+prerequisitesMet, the pure-Dart client mirror of the server G5/G6), else delegates to CurriculumGraphWalker. Selection degrades on a SEPARATE axis from coaching (Pitfall 5); the agent's choice is UNTRUSTED (T-15-05-T).
- [Phase ?]: [15-05]: LetterUnitController rewired — durable Drift resume via graphPositionRepository (getPosition Future, Pitfall 6) replaces the in-memory _resumeByLetter; the state.atMastery->recordMastery(cleanReps:0) navigation auto-write is DELETED; recordMasteryIfMet gates the star strictly on isMasteryMet over the essential 70/30 core (D-06/Pitfall 2). Rich Phase-07 section widgets KEPT (no wholesale UI replacement); the controller is the unit-level selection+mastery driver.
- [Phase ?]: [15-05]: provider named lib/tutor/exercise_selector_provider.dart with top-level exerciseSelectorProvider to MATCH the 15-01 RED contract exactly (zero test edits), reconciling vs the plan's selection_providers.dart. The ExerciseSelector seam gained an optional decision param (offline walker ignores it). Server test_payload_nonpii.py extended over the two graph-position fields; the Dart side was already done by 15-04 (verified green, not re-touched).
- [Phase 15]: [15-07]: Owner-mother signed the baa curriculum graph at the tier level (D-05, 2026-06-28); signedOff flipped false->true ONLY behind the human-verify gate, with a 15-HUMAN-UAT.md record on the same change (Pitfall 4).
- [Phase 15]: [15-07]: Q3 adjustment — writing & tracing = 3 clean reps, lighter exercises = 1; nine writing nodes (writeLetter.* x3, connectWord.* x2, completeWord.middle, writeWord.* x3) bumped minCleanReps 2->3, joining traceLetter.* already at 3.
- [Phase 15]: [15-07]: Q1 competency mapping + Q2 70/30 essential/enrichment split APPROVED as drafted — grammarTransform + wordBuilding stay enrichment (essential:false, reps 1), do not gate the star; no flag/prerequisite/tier change.
- [Phase 15]: [15-07]: server curriculum_graph.json re-derived from the signed asset via generate.py (never hand-edited); baa-only (D-11) confirmed. FOLLOW-UP: Cloud Run qalam-tutor re-deploy (gcloud, human) so the signed graph + 15-02/15-04 wire fields go live before on-device /coach.
- [Phase ?]: [16-01]: All three tutor nodes default to keyless google_vertexai/gemini-2.5-flash (D-02; matches the live qalam-tutor deploy); the stale anthropic+API-key path removed from .env.example/README — keyless ADC only, no provider key anywhere.
- [Phase ?]: [16-01]: Claude-on-Vertex coach is a drop-in env swap (COACH_MODEL_PROVIDER=anthropic_vertex + COACH_MODEL=claude-haiku-4-5@20251001 + COACH_LOCATION=global → ChatAnthropicVertex), returned UNbound so coach.py keeps the bind_tools(tool_choice=any) G2 lock; gated on a human Model-Garden Enable + an eval win (D-03). langchain-anthropic annotated as REMOVE candidate (nothing imports it).
- [Phase ?]: [16-01]: Wave-0 RED contract authored (Nyquist) — test/tutor/tts_coach_speaker_test.dart (segmentByScript + TtsCoachSpeaker over an injectable TtsEngine) and server/tests/test_eval/test_eval_harness.py (score_eval_set over 4 §5 dims; model-free faithfulness leg==1.0; Vertex-judge leg skipped in -m code) both RED by missing symbol. The eval RED test fails the full -m code suite until 16-03 ships run_eval.py — intended state.

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

None yet.

### Blockers/Concerns

- **Geometric stroke scorer (deepest risk, Phase 3–4):** NOT provided by ML Kit (ML Kit gives only {text, score}); custom build + per-letter calibration against real child samples.
- **Offline / one-time model download (open question, Phase 10):** verify on a fresh, no-network install.
- ~~**Phase 2 sign-off gate:**~~ CLOSED — alif signedOff: true, 1 referenceStroke (64 pts), 3 commonMistakes authored. Phase 3 is unblocked.
- Phase 04 plan 04-06 (baa-family sign-off) DEFERRED — blocked on real-world resources: requires a real Android tablet + the owner's mother + real children to author/label/sign off baa/taa/thaa and tune per-letter tolerances on real samples (cannot be done on emulator, per plan note). Plans 04-01..04-05 complete. Re-run /gsd:execute-phase 4 when resources available to finish 04-06 and complete the phase.
- [Phase 11][11-01] PENDING HUMAN ACTION (Task 3, gate=blocking): Enable Firebase AI Logic (Gemini Developer API) on project qalam-app-bd7d0 in the Firebase Console (Build -> AI Logic -> Get started). Console-only, no CLI. Blocks Plan 03 device A/B model call; does NOT block Plan 02 (code authoring + flutter analyze). Resume signal: 'enabled' or 'blocked: <reason>'.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260601-wa0 | Add DEMO launch flag to boot app at /demo/home | 2026-06-01 | eed35c0 | [260601-wa0-add-demo-launch-flag-to-boot-app-at-demo](./quick/260601-wa0-add-demo-launch-flag-to-boot-app-at-demo/) |
| 260602-00f | Rebuild demo Home faithful to home.png (owner override: gamification) | 2026-06-02 | 586b195 | [260602-00f-rebuild-demo-home-faithful-to-home-png-d](./quick/260602-00f-rebuild-demo-home-faithful-to-home-png-d/) |
| 260602-bw1 | Rebuild Watch/Trace/Feedback/Celebration faithful to mockups; demo loop → Baa (owner override: gamification) | 2026-06-02 | 326c221 | [260602-bw1-rebuild-demo-walkthrough-baa](./quick/260602-bw1-rebuild-demo-walkthrough-baa/) |
| 260607-pr1 | Practice screen three-zone Trace/ShowFix/ShowPraise tutor redesign + Hear-the-letter (UI-only; scorer/state-machine/persistence untouched) | 2026-06-07 | 8f8eb56 | [practice-redesign spec](../docs/design/practice-redesign/) |
| 260615-tqu | Wire baa-unit vocab illustrations into the app: bundle assets/images/, add imageId→asset resolver (mirrors audio seam) + provider, render Image.asset in _ImagePart with silent-degrade hatched-stub fallback | 2026-06-15 | 2cff97e | [260615-tqu-wire-baa-unit-vocab-illustrations-into-t](./quick/260615-tqu-wire-baa-unit-vocab-illustrations-into-t/) |

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-06-29T13:00:45.427Z
Stopped at: Phase 16 context gathered
Resume files: .planning/phases/06.1-firebase-curriculum-backend/06.1-05-PLAN.md (next), .planning/phases/06.1-firebase-curriculum-backend/06.1-03-PLAN.md (pending), .planning/phases/06.1-firebase-curriculum-backend/06.1-04-SUMMARY.md, .planning/phases/04-scoring-quality-calibration/04-06-PLAN.md (deferred)
