# External Integrations

**Analysis Date:** 2026-05-30

## APIs & External Services

**Google ML Kit (Planned):**
- Service: Digital Ink Recognition for Arabic handwriting
- Status: **Validated** per CLAUDE.md; decision made, not yet integrated
- What it's used for: On-device stroke recognition and letter-shape validation (no network call)
- SDK/Client: `google_ml_kit_digital_ink` (Dart package, not yet in pubspec.yaml)
- Auth: API key (Android, embedded in google-services.json)
- Latency: On-device, sub-second response expected
- Reference: CLAUDE.md decision: *"Handwriting recognition: Google ML Kit Digital Ink - validated, not exploratory."*

**Claude AI (Planned):**
- Service: Tutor response generation and adaptive feedback
- Status: Planned, not yet integrated
- What it's used for: Warm, specific feedback on handwriting attempts; within-session and across-session adaptation
- SDK/Client: Anthropic Python SDK (for Cloud Functions backend)
- Auth: API key (environment variable in Cloud Functions runtime)
- Latency: Target to be determined per R4 (Tutor cost & latency budget) research
- Constraints: Tutor always runs server-side (never client-side per CLAUDE.md); two-timescale adaptation (within-session history + nightly job)

## Data Storage

**Databases:**
- **Firestore** (Google Cloud)
  - Status: Planned, not yet integrated
  - Connection: Firebase SDK (Dart), authenticated via Firebase Auth
  - Data model: Not yet defined; pending curriculum schema from owner's mother
  - Offline persistence: Planned per R2 (Offline-first strategy) research
  - Client: `firebase_core`, `cloud_firestore` (Dart packages, not yet in pubspec.yaml)

**File Storage:**
- Not applicable at current stage
- Session data (strokes, timestamps) stored in Firestore

**Caching:**
- Not explicitly configured
- Firestore offline cache via built-in offline persistence (planned)

## Authentication & Identity

**Auth Provider:**
- **Firebase Authentication** (Google Cloud)
  - Status: Planned, not yet integrated
  - Implementation: Email/password or social auth (to be determined)
  - Child device local storage: Not yet designed
  - Parent dashboard: Separate auth flow (if applicable)
  - Client: `firebase_auth` (Dart package, not yet in pubspec.yaml)

## Monitoring & Observability

**Error Tracking:**
- Not configured
- Candidate: Firebase Crashlytics (can be added with Firebase integration)

**Logs:**
- Not configured
- Debugging via Flutter DevTools or platform logging
- Production: Firebase Cloud Logging (implicit with Cloud Functions)

## CI/CD & Deployment

**Hosting:**
- Android APK/AAB distribution: Not yet configured
  - Candidates: Google Play Console, internal distribution
- Backend: Google Cloud Platform (Firebase)

**CI Pipeline:**
- Not configured
- Candidates: Cloud Build, GitHub Actions (with Google Cloud integration)

## Environment Configuration

**Required env vars (planned, not yet implemented):**
- `FIREBASE_PROJECT_ID` - Google Cloud project ID
- `FIREBASE_API_KEY` - Firebase web API key
- `GOOGLE_ML_KIT_API_KEY` - ML Kit Digital Ink API key (Android-specific, typically embedded)
- `CLAUDE_API_KEY` - Anthropic API key (for Cloud Functions backend)

**Secrets location:**
- `.env` file (not yet present; GSD convention)
- Android: `google-services.json` (not in repo; per Android Firebase setup)
- Cloud Functions: Secret Manager (Google Cloud)

## Webhooks & Callbacks

**Incoming:**
- Not applicable at this stage

**Outgoing:**
- Firebase Cloud Functions trigger on Firestore writes (tutor generation)
- Parent dashboard updates via Firestore listeners (real-time sync)

## Third-Party Services (Implied but Not Yet Integrated)

**Google Cloud Project:**
- Bundles Firebase services (Auth, Firestore, Cloud Functions)
- ML Kit API
- Cloud Logging

**Research Blockers (per RESEARCH_BRIEF.md):**
- **R1. Handwriting Recognition:** Decision made (ML Kit); implementation pending
- **R2. Offline Strategy:** Not yet designed; impacts Firestore client-side persistence
- **R3. RTL Rendering:** Flutter RTL support validated; fonts and letter-form rendering to be tested
- **R4. Tutor Latency & Cost:** Research required before Cloud Functions architecture finalized
- **R5. Competitor Teardown:** Research required for positioning validation

## Data Flow (Planned)

```
┌─────────────────────────────────────────────────────────┐
│  Child Device (Android Tablet)                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Flutter App                                        │ │
│  │ ├─ Stroke Input → ML Kit Digital Ink (on-device)  │ │
│  │ ├─ Session Data → Firestore (online/offline)      │ │
│  │ └─ Listen for Tutor Feedback (Firestore)          │ │
│  └────────────────────────────────────────────────────┘ │
└──────────┬──────────────────────────────────────────────┘
           │
           ├─ Firestore (Sessions, Progress)
           │
           ▼
┌──────────────────────────────────────────────────────────┐
│  Google Cloud                                            │
│  ├─ Firestore: Child profiles, session logs, strengths/ │
│  │  struggles                                            │
│  ├─ Cloud Functions (Python): Tutor backend             │
│  │  ├─ Input: Session history, current stroke          │
│  │  ├─ Call: Claude AI API                             │
│  │  └─ Output: Feedback → Firestore                    │
│  ├─ Nightly Job (scheduled): Recompile strengths/      │
│  │  struggles per child                                 │
│  └─ Firebase Auth: User/parent authentication          │
└──────────────────────────────────────────────────────────┘
           │
           ▼ (if applicable)
┌──────────────────────────────────────────────────────────┐
│  Parent Dashboard (Web or Flutter)                       │
│  ├─ View child progress                                 │
│  ├─ Adjust practice schedule                            │
│  └─ Sync when child reconnects (offline reconciliation) │
└──────────────────────────────────────────────────────────┘
```

## Known Gaps (Per Product Notes)

- **Offline-first sync:** How Firestore reconciles queued writes when child reconnects (R2)
- **RTL + connected-script rendering:** Font selection and letter-form shaping (R3)
- **Tutor call budget:** Token volume and acceptable latency between stroke finish and feedback (R4)
- **Backend infrastructure:** No custom server; all via Firebase + Cloud Functions (approved)

---

*Integration audit: 2026-05-30*
