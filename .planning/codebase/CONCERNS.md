# Codebase Concerns

**Analysis Date:** 2026-05-30

## Tech Debt

### Boilerplate Flutter Shell — No Real Implementation

**Issue:** The app is a fresh Flutter scaffold with only the default counter example (`lib/main.dart`). The entire application logic, UI screens, state management, and backend integration are missing.

**Files:** `lib/main.dart`

**Impact:**
- The app cannot perform any of its intended functions: handwriting capture, AI tutor interaction, Firebase integration, offline sync, or Arabic RTL rendering
- All research gates (R1–R4) must be completed before implementation can proceed, but the shell provides no foundation for them
- Heavy rework required when actual features are built

**Fix approach:**
- Complete R1 (handwriting recognition) research before adding any capture/scoring logic
- Establish module structure: create `lib/features/`, `lib/core/`, `lib/services/` directories per Flutter best practices
- Implement Riverpod state management as specified in CLAUDE.md
- Set up Firebase client wiring (`lib/services/firebase/`)
- Build UI from approved Claude Design mockups, following RTL guidance for Arabic text

---

## Unresolved Critical Decisions

### R1: Handwriting Recognition (BLOCKING ALL FEATURE WORK)

**Problem:** No handwriting scoring implementation. The decision between ML Kit Digital Ink, TrOCR, custom TFLite classifier, or geometric stroke checking is marked "Decided" in CLAUDE.md but lacks:
- Validation evidence in code
- Performance metrics (latency, accuracy on child handwriting)
- Integration plan in the Flutter app
- Fallback strategy if preferred choice fails

**Files:** `CLAUDE.md` (line 62–64 marks it "Decided"), no supporting code or validation tests

**Current mitigation:** Project notes it was "validated by our own testing" but test results are not in the repo

**Recommendations:**
- Document test results in `docs/research/raw/R1-handwriting-recognition.md`
- Create a proof-of-concept branch testing ML Kit on actual tablet with child-like strokes
- Establish latency SLA (time from stroke end to feedback on-screen) and measure against it

### R2: Offline-First Strategy (GATES SESSION PERSISTENCE)

**Problem:** No offline-first architecture. Questions remain:
- How much of a session works without network?
- Firestore offline persistence configuration
- Queued session writes and conflict resolution
- Parent dashboard sync when child reconnects

**Files:** None — no offline layer implemented

**Impact:** Sessions could be lost if connectivity drops mid-practice. Parent visibility of progress is undefined.

**Recommendations:**
- Define clear offline scope: can child see dotted guide letters? Can the app capture strokes? What data must sync?
- Implement Firestore offline persistence wrapper in `lib/services/firebase/offline_sync.dart`
- Add conflict resolution for nightly profile recompilation if multiple devices submit updates

### R3: RTL + Connected-Script Rendering (GATES LETTER DISPLAY)

**Problem:** Flutter's RTL support is mature but Arabic letter shaping (isolated/initial/medial/final forms) requires:
- A font with complete Arabic glyph coverage (not Material Design's default)
- Custom text rendering or a library that handles contextual shaping
- Known Flutter pitfalls (text direction switches, bidi text in mixed-language UIs)
- How dotted guide letters layer beneath child's strokes

**Files:** `pubspec.yaml` has no Arabic font dependency; `lib/main.dart` uses Material defaults

**Impact:** Letters will not display correctly in connected-script form. The pedagogical core (child traces a properly-shaped letter) fails.

**Recommendations:**
- Add a high-quality Arabic font (`noto_sans_arabic` or similar) to `pubspec.yaml`
- Create a `lib/widgets/arabic_letter_display.dart` that handles contextual shaping
- Test with real RTL text input before building the tutor interaction

### R4: Tutor Cost & Latency (GATES FEEDBACK TIMING)

**Problem:** No tutor backend implemented. Open questions:
- How many Claude API calls per session?
- Prompt caching to reduce cost/latency
- Target latency from stroke end to feedback on-screen (e.g., < 2s acceptable?)
- Token volume and monthly cost at scale

**Files:** None — tutor is marked "never runs client-side" but no Cloud Function exists

**Impact:** Feedback loop is critical pedagogy. Long latency (> 5s) breaks the flow for children.

**Recommendations:**
- Measure acceptable latency in user research with target age group
- Design Cloud Function to accept session history + latest stroke and return feedback quickly
- Implement prompt caching for repeated session context
- Set cost ceiling and test with 10 sample sessions

---

## Missing Critical Features

### Firebase Integration

**Problem:** No Firebase Auth, Firestore, Cloud Functions, or Cloud Storage integration. The app cannot authenticate users, persist data, or call the tutor.

**Files:** None — no `lib/services/firebase/` directory exists

**Blocks:** Every feature depending on backend

**Priority:** HIGH — must be first infrastructure built after R1–R4 are resolved

### Handwriting Capture & Scoring

**Problem:** No stylus input handling or ML Kit Digital Ink integration. The app cannot record strokes or validate them against curriculum letters.

**Files:** None — no `lib/features/practice/` or `lib/services/handwriting/` exists

**Blocks:** Core pedagogy (child writing by hand)

**Priority:** HIGH — depends on R1 completion

### AI Tutor Pipeline

**Problem:** No tutor logic. The app cannot:
- Build session history (strokes attempted, feedback given, mistakes noted)
- Call Claude for feedback
- Track child strengths/struggles across sessions
- Generate nightly profile recompilation

**Files:** None — no Cloud Function code; tutor responsibility unclear between client and backend

**Blocks:** Pedagogical adaptation

**Priority:** HIGH — depends on R4 and backend setup

### Parent Dashboard

**Problem:** No parent view. Parents cannot see child progress, session history, or adjust settings (practice frequency, letters being learned, etc.).

**Files:** None — entirely missing

**Blocks:** Parental oversight and engagement

**Priority:** MEDIUM — needed before public beta but not for core functionality

### Curriculum Schema

**Problem:** No data model for holding the owner's mother's curriculum spec (stroke order, letter forms, common mistakes, progression rules). The CLAUDE.md says "build a schema that faithfully holds her spec" but no schema exists.

**Files:** None — no `lib/models/curriculum.dart` or Firestore schema

**Blocks:** Ability to configure pedagogy per the domain expert

**Priority:** MEDIUM — must be in place before letters can be taught

---

## Test Coverage Gaps

### Widget Tests Incomplete

**Problem:** The only test is a smoke test for the default counter app (`test/widget_test.dart`). No tests exist for:
- Handwriting capture and display
- Tutor feedback rendering
- RTL text handling
- Firebase integration
- State management transitions
- Offline behavior

**Files:** `test/widget_test.dart` (28 lines, tests obsolete code)

**Risk:** Refactoring the counter logic won't catch regressions in the actual app

**Priority:** HIGH — testing framework must be established early so tests grow with features

### No Integration Tests

**Problem:** No tests for end-to-end user flows (login → practice session → submit → feedback).

**Impact:** Integration issues between layers (UI → state management → Firebase) discovered only at runtime

**Priority:** MEDIUM — needed before release

---

## Architectural Risks

### No Module Structure

**Problem:** `lib/` contains only `main.dart`. Best practice for Flutter projects of this scale requires:
- `lib/features/` — feature-specific UI, state, logic
- `lib/core/` — shared utilities, constants, theme
- `lib/services/` — Firebase, handwriting, tutor clients
- `lib/models/` — data models

**Impact:** As the app grows, dependencies will tangle and code will become unmaintainable

**Fix approach:** Establish directory structure now, before feature branches grow tangled roots

### No State Management Framework

**Problem:** CLAUDE.md specifies Riverpod, but no packages are declared in `pubspec.yaml`. Default counter uses raw `setState`.

**Files:** `pubspec.yaml` (no `riverpod` or related packages)

**Impact:** 
- Moving beyond simple counters will lead to prop-drilling and callback hell
- Tutor feedback (which needs to update across multiple widgets) will be painful to implement
- Session state (child's current strengths/struggles) will be hard to share

**Fix approach:** Add Riverpod dependencies immediately; restructure state to use providers before feature code grows

---

## Security Considerations

### API Keys in Client Code (Not Yet, But Anticipated)

**Problem:** CLAUDE.md specifies the tutor "never runs client-side" and the API key is in the Function secret. The current code doesn't have any keys, but future implementation must:
- Ensure no API key is hardcoded in Flutter code
- Keep all tutor calls server-side (Cloud Functions)
- Validate that Firestore rules restrict child data access

**Files:** `lib/main.dart` (currently safe, but placeholder for future integrations)

**Priority:** MEDIUM — must be audited before any real feature branches

### Child Data Sensitivity

**Problem:** CLAUDE.md declares "treat children's data as sensitive" but no Firestore rules exist. Without them:
- Any authenticated user could read any child's progress
- Session recording (strokes) could be leaked
- Tutor feedback could be modified

**Current mitigation:** No data stored yet; this becomes critical at beta

**Recommendations:**
- Write Firestore rules now as a template, even if unused
- Implement rule testing in CI/CD
- Document data retention policy (how long are old sessions kept?)

---

## Missing Documentation

### Research Findings Not Committed

**Problem:** CLAUDE.md marks R1 as "Decided" based on testing but `docs/research/raw/` is empty. No research methodology, sample sizes, accuracy metrics, or raw data are in the repo.

**Files:** `docs/RESEARCH_BRIEF.md` (lists questions), `docs/research/raw/` (missing)

**Impact:** 
- Future team members can't understand why ML Kit was chosen
- Design decisions can't be re-evaluated if requirements change
- Validation evidence is lost if original researcher leaves

**Fix approach:** 
- Create `docs/research/raw/R1-handwriting-recognition.md` with test methodology, results, and tradeoffs
- Create similar files for R2–R4 once research is complete
- Link from CLAUDE.md for easy reference

### No Architecture Decision Records (ADRs)

**Problem:** `docs/architecture/` is empty. No ADRs document:
- Why Riverpod over BLoC
- Why Firebase over a custom backend
- RTL rendering strategy
- Offline persistence approach

**Impact:** Tech choices are implicit and vulnerable to second-guessing

**Fix approach:** Create `docs/architecture/ADR-001-riverpod-state-management.md` etc. as decisions solidify

### Tutor System Design Undefined

**Problem:** CLAUDE.md describes "two-timescale adaptation" (within-session + nightly profile) but no system diagram or design doc exists. Questions like:
- What does "full session history" include? (all strokes? feedback given?)
- How does nightly job access Firestore without conflicts?
- How does the tutor respond to a specific child's level?

**Impact:** Implementation will guess at architecture, leading to rework

**Fix approach:** Create `docs/architecture/tutor-pipeline.md` with diagrams and pseudocode

---

## Fragile Areas (When Built)

### Handwriting Capture & Rendering Layer

**Files:** (Not yet created; will be `lib/features/practice/widgets/` and `lib/services/handwriting/`)

**Why fragile:**
- Depends on R1 validation, which must be rock-solid
- Touches low-level platform code (stylus input) and high-level UI (gesture detection + rendering)
- Stroke data structure must align with ML Kit input and tutor feedback loop
- RTL rendering (R3) complicates coordinate systems

**Safe modification:**
- Isolate stroke capture in a service with a clean interface (list of Point objects)
- Test capture independently from scoring
- Version the stroke data format (add version field) to allow future evolution
- Log all strokes to Firebase for debugging child issues

### Tutor Feedback Loop

**Files:** (Will span `lib/services/tutor/`, Cloud Functions, and multiple widgets)

**Why fragile:**
- Involves async network calls with potential timeouts
- Session state must be consistent across client, Firestore, and Cloud Function
- Latency directly affects pedagogy
- Feedback text is pedagogically critical (per CLAUDE.md tutor voice section)

**Safe modification:**
- Create a clear state machine for feedback lifecycle (waiting → received → displayed)
- Mock tutor responses in tests before integrating real Claude API
- Log feedback latency and collect user feedback on timing
- Route all feedback through a single "TutorService" class to avoid race conditions

### Offline Sync & Firestore Persistence

**Files:** (Will be `lib/services/firebase/offline_sync.dart`)

**Why fragile:**
- Firestore offline persistence has subtle bugs (cache invalidation, transaction handling)
- Nightly profile recompilation must not race with client updates
- Parent dashboard sync must reconcile conflicting edits

**Safe modification:**
- Design conflict resolution explicitly (last-write-wins? merge strategies?)
- Test offline scenarios (enable airplane mode, kill app, reconnect)
- Add monitoring to detect sync failures in production
- Document assumptions about timing (e.g., "nightly job runs after 2am UTC")

---

## Dependencies at Risk

### Flutter SDK Version Constraint

**Problem:** `pubspec.yaml` specifies `sdk: ^3.11.5`, which is old (current Dart is 3.5+). No migration path documented.

**Files:** `pubspec.yaml` (line 22)

**Risk:** 
- May be missing security patches
- Breaking changes in Flutter versions not yet accounted for
- Handwriting recognition libraries may require newer Dart features

**Migration plan:** 
- Run `flutter upgrade` and `pub upgrade --major-versions` together, test thoroughly
- Update `pubspec.yaml` to `^3.12` (or higher, once stable)
- Test against minimum SDK version to ensure no accidental dependencies

### Missing Foundational Packages

**Problem:** `pubspec.yaml` lacks essential packages for a production app:
- **No state management** (Riverpod not added despite being "Decided")
- **No Firebase packages** (despite CLAUDE.md mandating it)
- **No ML Kit Digital Ink** (despite R1 "validation")
- **No HTTP client** or **async helpers**
- **No dependency injection** framework

**Files:** `pubspec.yaml` (lines 30–36)

**Impact:** Every feature will be blocked waiting for the right package to be added

**Recommendations:**
- Add baseline dependencies immediately:
  ```yaml
  dependencies:
    firebase_core: ^3.0.0
    cloud_firestore: ^5.0.0
    firebase_auth: ^5.0.0
    google_ml_kit: ^0.15.0       # For Digital Ink
    riverpod: ^2.4.0
    riverpod_generator: ^2.3.0
    logger: ^2.0.0
  dev_dependencies:
    build_runner: ^2.4.0
    riverpod_generator: ^2.3.0
  ```

---

## Scaling Limits

### Single-Page App Limitation

**Problem:** Once features are built, having them all in a single `main.dart` (or even a single `lib/`) will become unmaintainable.

**Current capacity:** Can handle the counter example

**Limit:** Breaks at ~500 lines of real logic

**Scaling path:**
- Enforce feature modularization early
- Use `flutter_modular` or route pages through Riverpod for loose coupling
- Plan for separate modules: practice, dashboard, settings, onboarding

### Firebase Quota & Cost

**Problem:** No cost estimation or quota planning. Firestore and Cloud Functions have limits:
- Firestore: 10K reads/day free, then pay per operation
- Cloud Functions: 2M invocations/month free (Python runtime)
- Storage: 1GB free, then per-gigabyte charges

**Current capacity:** None (no traffic)

**Scaling path:**
- Model session write patterns (how many writes per session?)
- Test tutor call cost (token usage per feedback call)
- Set up billing alerts before going public
- Plan caching strategy to reduce API calls

---

## Missing Critical Testing Infrastructure

### No CI/CD Pipeline

**Problem:** No `.github/workflows/` or equivalent. Tests must be run manually.

**Impact:** Regressions slip into commits; no enforcement of code quality gates

**Fix approach:**
- Create `flutter analyze` + `flutter test` CI job
- Block merges if tests fail or coverage drops
- Add UI test job (once UI exists)

### No Linting Enforcement

**Problem:** `analysis_options.yaml` includes default Flutter lints but doesn't enable any custom rules. No pre-commit hooks.

**Files:** `analysis_options.yaml` (mostly commented out)

**Impact:** Code style will drift; inconsistent patterns make debugging harder

**Fix approach:**
- Enable stricter lint rules: `always_put_required_named_parameters_first`, `avoid_print`, `sort_pub_dependencies`
- Add `dart_code_metrics` for complexity analysis
- Enforce via pre-commit hook before pushing

---

## Procedural Gaps

### GSD Workflow Not Yet Established

**Problem:** CLAUDE.md references GSD (discuss → plan → execute → verify) but the project hasn't run a full cycle. No examples of:
- How research findings are documented and approved
- How phases are planned (what goes in `.planning/`?)
- How code reviews are structured
- How verification gates are enforced

**Impact:** Unclear who decides what, when, and how changes are validated

**Fix approach:**
- Run a pilot GSD cycle on the Firebase integration (R2 + infrastructure)
- Document the process in `.planning/WORKFLOW.md`
- Create phase templates that include research, implementation, and verification steps

---

*Concerns audit: 2026-05-30*
