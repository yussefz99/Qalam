<!-- refreshed: 2026-05-30 -->
# Architecture

**Analysis Date:** 2026-05-30

## System Overview

Qalam is a Flutter application (Android-only, tablet-first, RTL) that teaches Arabic handwriting through guided practice with AI tutor feedback. The architecture is currently a **minimal Flutter skeleton** with core structural decisions deferred to research phases.

```text
┌──────────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                          │
│  `lib/main.dart` (root widget, theme, routing TBD)           │
├──────────────────────────────────────────────────────────────┤
│                  Business Logic (TBD)                        │
│  • State management: Riverpod (decided, not yet integrated)  │
│  • Handwriting capture: Google ML Kit Digital Ink (on-device)│
│  • Session tutor: Firebase Cloud Functions (Python runtime)  │
├──────────────────────────────────────────────────────────────┤
│               Android Native & Platform                      │
│  `android/app/src/main/kotlin/` (MainActivity, plugins)      │
│  • Stylus input & gesture handling                           │
│  • ML Kit Digital Ink Integration (TBD)                      │
├──────────────────────────────────────────────────────────────┤
│           External Services & Infrastructure                 │
│  • Firebase (Auth, Firestore, Cloud Functions)              │
│  • AI Tutor: Claude API (via Cloud Functions)                │
│  • ML Kit: On-device handwriting recognition (validated)     │
└──────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| **MyApp** | Root widget, theme, navigation setup | `lib/main.dart` |
| **MyHomePage** | Placeholder UI, currently counter demo | `lib/main.dart` |
| **MainActivity** | Android entry point, Flutter embedding | `android/app/src/main/kotlin/com/example/qalam/MainActivity.kt` |
| **Firebase Integration** | Auth, Firestore, Cloud Functions | Not yet integrated |
| **ML Kit Wrapper** | Handwriting recognition (on-device) | Not yet implemented |
| **Tutor Service** | Session feedback, stroke correction guidance | Cloud Functions (Python) — design TBD |

## Pattern Overview

**Overall:** Early-stage Flutter application following **Material Design** with planned **Riverpod-based state management** (BLoC explicitly rejected per CLAUDE.md).

**Key Characteristics:**
- Flutter 3.11.5+, Dart 3.11.5+, Android-only (minimum SDK tbd, target SDK tbd)
- Boilerplate structure; no domain logic implemented
- Firebase backend (Auth + Firestore for offline persistence + Cloud Functions for tutor)
- On-device handwriting recognition (Google ML Kit Digital Ink)
- RTL support planned; connected-script Arabic rendering in progress

## Layers

**Presentation (UI):**
- Purpose: Render practice interface, accept stylus input, display tutor feedback
- Location: `lib/` (all Dart code)
- Contains: Widgets, screens, theme, navigation
- Depends on: State management layer (TBD), domain/business logic
- Used by: User interactions (stylus, touch)

**State Management:**
- Purpose: Manage session state, child progress, lesson data
- Location: Not yet created; will use Riverpod
- Contains: Providers, state notifiers, computed state
- Depends on: Data layer
- Used by: UI layer for rebuilds

**Data & Domain Logic:**
- Purpose: Session management, handwriting validation, curriculum tracking
- Location: Not yet created
- Contains: Models (Letter, Lesson, Session, etc.), repositories, use cases
- Depends on: Firebase SDKs, ML Kit
- Used by: State management layer

**Platform & External:**
- Purpose: Bridge to native Android code, Firebase, ML Kit
- Location: `android/app/src/main/` (Kotlin), Firebase SDKs (Dart packages)
- Contains: Platform channels (TBD), method invocation
- Depends on: Google ML Kit, Firebase services
- Used by: Data layer

## Data Flow

### Primary Request Path (Practice Session)

1. **Child starts lesson** → `MyApp` loads selected letter
2. **Render dotted guide** → UI displays Arabic letter (form varies by position: isolated/initial/medial/final)
3. **Capture strokes** → Android stylus input → ML Kit Digital Ink recognition (on-device)
4. **Send to tutor** → Strokes + session history → Cloud Functions → Claude API
5. **Display feedback** → Rendered response, specific correction guidance
6. **Store session** → Firestore (with offline persistence for reconnection)

### Offline Behavior (TBD)

- **During offline:** Child can capture and practice; strokes held in local storage
- **On reconnect:** Queued strokes sync to Firestore; parent dashboard reconciles
- **Research gate:** R2 must resolve Firestore offline strategy before coding offline sync

### State Management Flow

**Current (boilerplate):**
- `MyApp` is stateless; theme hardcoded
- `MyHomePage` is stateful with local counter

**Planned:**
- Riverpod providers for: current lesson, session history, child progress
- Computed state: "ready for next letter?", "mastery level", "mistake patterns"

## Key Abstractions

**Letter Model:**
- Purpose: Represents a single Arabic letter with metadata (stroke order, forms, common mistakes)
- Location: `lib/models/` (not yet created)
- Pattern: Value object with immutable data
- Schema: Follows curriculum owner's spec (stroke order, target forms, pedagogy)

**Session:**
- Purpose: Tracks one practice session (attempts, strokes, tutor responses, timestamps)
- Location: `lib/models/session.dart` (not yet created)
- Pattern: Mutable aggregator; persists to Firestore
- Contains: session_id, child_id, letter, attempts[], tutor_feedback[], start_time, end_time

**Stroke:**
- Purpose: Raw input from stylus — a sequence of points with pressure, timestamp
- Location: `lib/models/stroke.dart` (not yet created)
- Pattern: Value object; immutable after capture
- Data: points[], timestamp, pressure_data, recognition_result

**Tutor (service abstraction):**
- Purpose: Encapsulates calls to Claude API for feedback generation
- Location: `lib/services/tutor_service.dart` (not yet created)
- Pattern: Repository; calls Cloud Functions endpoint
- Input: strokes, session history, child age/level
- Output: structured feedback (praise, specific correction, next action)

## Entry Points

**Flutter App Entry:**
- Location: `lib/main.dart` (function `main()`)
- Triggers: App launch
- Responsibilities: Initialize Flutter, run `MyApp` root widget

**Android Entry:**
- Location: `android/app/src/main/kotlin/com/example/qalam/MainActivity.kt`
- Triggers: Android OS app launch
- Responsibilities: Set up Flutter embedding, handle platform channels

**Potential Native Channels (TBD):**
- Stylus pressure detection if Flutter gesture detection insufficient
- ML Kit integration (if not available via Dart SDK)
- File access for caching stroke data during offline mode

## Architectural Constraints

- **Threading:** Single-threaded event loop (Dart). Long operations (tutor calls, ML Kit recognition) must be non-blocking (async/await or isolates).
- **Global state:** None at present. Riverpod will manage state; avoid module-level singletons.
- **Circular imports:** Ensure `lib/models/` do not import from services or repositories.
- **RTL rendering:** Connected-script Arabic (letter forms) requires careful widget design; research gate R3 must resolve font choice and form shaping before building text widgets.
- **Offline persistence:** Firestore offline mode + local caching strategy not yet finalized (R2).
- **No network round-trip for handwriting scoring:** Strokes must be recognized on-device with ML Kit; tutor calls are separate and async.

## Anti-Patterns

### Unvalidated Pedagogical Assumptions

**What happens:** Code is written assuming stroke order validation, difficulty progression, or mistake patterns without the curriculum owner's input.

**Why it's wrong:** The pedagogy is the product. Wrong assumptions require costly rewrites and may undermine learning effectiveness.

**Do this instead:** Before implementing any validation or progression logic, consult `docs/research/raw/` for curriculum owner's specifications. Block dependent code on research sign-off in CLAUDE.md's "Still open" section.

### Client-Side Tutor Logic

**What happens:** Feedback rules or corrections are hardcoded in the app (e.g., "if stroke curves up, suggest slower").

**Why it's wrong:** The tutor's voice and pedagogy must remain consistent and updatable without app releases. It must be centralized in Cloud Functions / Claude API.

**Do this instead:** All pedagogical feedback originates from Claude API (called via Cloud Functions). App renders feedback; it never generates it.

### Ignoring Offline-First

**What happens:** App assumes internet connection; strokes are sent immediately; sessions fail if connection drops mid-practice.

**Why it's wrong:** Tablets in homes/cars may lose connection. Offline-first is core to the product promise (tutor available anytime).

**Do this instead:** All session data is written to local Firestore offline persistence first. Tutor calls are queued and processed when connection resumes. Research gate R2 is mandatory before coding any sync logic.

### Over-Gamification

**What happens:** Points, streaks, or badges are added to "motivate" practice.

**Why it's wrong:** Qalam is anti-gamification by design. Pressure and extrinsic rewards undermine real learning. The warm tutor and visible progress are the motivation.

**Do this instead:** Progress visualization is simple and honest: "You've written 45 baa's" or "Your baa is getting smoother." No artificial milestones or badges.

## Error Handling

**Strategy:** Layered error handling — catch and log at service boundaries, propagate domain errors to UI for user-facing messages.

**Patterns:**
- **ML Kit errors:** Log recognition failures; show "let me look at that again" and ask child to retrace
- **Tutor errors:** If Claude call fails, show "tutor is thinking..." and retry; fallback generic encouragement if timeout
- **Firebase errors:** For offline: queue writes; for auth: redirect to login; for quota: show "that's enough for today"
- **UI errors:** Dart error boundary (catch setState errors); show error screen with diagnostics

## Cross-Cutting Concerns

**Logging:** No logging framework yet integrated. Will use `debugPrint()` for development; production logging (error reporting) via Firebase Crashlytics (TBD).

**Validation:** Strokes must have minimum length/time (prevent accidental taps); Firestore documents validated at write-time (server-side rules TBD).

**Authentication:** Firebase Auth (provider TBD — email, Google, Apple). Parent account controls child session access. Offline sessions are local-only until auth is re-established.

---

*Architecture analysis: 2026-05-30*
