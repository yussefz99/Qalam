---
phase: 11-spike-genui-catalog-native-stylus-canvas-kill-shot
plan: 01
subsystem: infra
tags: [genui, firebase_ai, firebase_core, flutter, spike, ai-logic, stroke-canvas]

# Dependency graph
requires:
  - phase: 06.1-firebase-curriculum-backend
    provides: "wired Firebase app qalam-app-bd7d0 (firebase_core/auth/firestore) + firebase_options.dart the spike reuses read-only"
  - phase: 02-curriculum
    provides: "signed-off baa referenceStrokes in assets/curriculum/letters.json + StrokeSpec in lib/models/letter.dart"
provides:
  - "genui ^0.9.2 + firebase_ai ^3.13.0 installed; firebase_core bumped ^4.10.0 -> ^4.11.0 (firebase_auth auto-resolved 6.5.3, firebase_app_check 0.4.5 transitive)"
  - "Known-good FlutterFire+GenUI resolved set recorded for Phase 14 inheritance (Pitfall 4)"
  - "Two Wave-0 structural guards: package guard (genui present / flutter_genui absent) + SC-4 durable-layers git-diff guard"
  - "Self-contained read-only baa fixture (baaReferenceStrokes) — Q1 resolved without rewiring the curriculum loader"
affects: [11-02, 11-03, phase-14-tutor, ai-logic-console]

# Tech tracking
tech-stack:
  added: [genui 0.9.2, firebase_ai 3.13.0]
  patterns:
    - "Throwaway spike under lib/spike_genui/ + test/spike_genui/ — additive, imports-only, deletable"
    - "SC-4 durable-layers git-diff guard as an executable flutter_test (TUTOR-01 enforced)"
    - "Read-only fixture copies signed-off curriculum data instead of importing the loader (Q1)"

key-files:
  created:
    - test/spike_genui/correct_package_test.dart
    - test/spike_genui/durable_layers_unchanged_test.dart
    - lib/spike_genui/fixtures/baa_reference.dart
    - .planning/spikes/11-genui-native-canvas/NOTES.md
  modified:
    - pubspec.yaml
    - pubspec.lock

key-decisions:
  - "Installed genui (live, labs.flutter.dev) NOT the discontinued flutter_genui (replacedBy genui) — re-verified at pub.dev at install time"
  - "Bumped firebase_core ^4.10.0 -> ^4.11.0 in one pub-add pass; let pub resolve firebase_auth 6.5.2 -> 6.5.3 within 6.x (no hand-pinning)"
  - "genui_catalog left uninstalled (optional) — add in Plan 02 only if the coaching-text line uses CoreCatalogItems"
  - "baa fixture COPIES letters.json read-only (Q1) — no Firestore/Drift/curriculum-loader import, keeps the throwaway self-contained"
  - "Task 3 (Firebase AI Logic console enable) recorded as PENDING HUMAN ACTION — console-only, no CLI path, no human present in this autonomous session; not blocked on because Plan 02 needs only the installed packages + fixture, not the live backend"

patterns-established:
  - "Spike guards run as flutter_test: package-correctness + SC-4 durable-diff, green after every spike commit"
  - "Comment-line filtering in the package guard so prose naming flutter_genui cannot self-invalidate the gate"

requirements-completed: []

# Metrics
duration: 13min
completed: 2026-06-21
---

# Phase 11 Plan 01: Spike Foundation (genui + firebase_ai + guards + baa fixture) Summary

**Installed the live `genui` ^0.9.2 + `firebase_ai` ^3.13.0 SDKs (firebase_core bumped to ^4.11.0), stood up the package-correctness and SC-4 durable-layers git-diff guards, and copied baa's signed-off reference strokes into a self-contained read-only fixture — de-risking the GenUI/native-canvas kill-shot before any catalog code is written.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-06-21T14:59:22Z
- **Completed:** 2026-06-21T15:12:53Z
- **Tasks:** 2 of 3 done (Task 3 is a pending human-action console step — see below)
- **Files modified:** 6 (4 created, 2 modified)

## Accomplishments

- Installed the CORRECT first-party packages in one resolution pass: `genui` ^0.9.2 (publisher labs.flutter.dev) + `firebase_ai` ^3.13.0 (publisher firebase.google.com); `flutter_genui` (discontinued, replacedBy genui) is provably ABSENT.
- Bumped `firebase_core` ^4.10.0 → ^4.11.0 so `firebase_ai` 3.13.0 co-resolves (Pitfall 4); `firebase_auth` auto-resolved 6.5.2 → 6.5.3, `firebase_app_check` 0.4.5 pulled transitively. Resolved set recorded for Phase 14 (NOTES.md).
- Stood up two automatable Wave-0 guards (both green): package-correctness + the SC-4 durable-layers git-diff guard (TUTOR-01 enforced as a test).
- Copied baa's signed-off reference strokes into `lib/spike_genui/fixtures/baa_reference.dart` (Q1) — verified byte-for-byte against the live `letters.json` baa entry; imports only `StrokeSpec`, no curriculum loader / Firestore / Drift.
- No durable file touched — the SC-4 sacred-path diff is empty after both task commits.

## Resolved Package Versions (Pitfall 4 — Phase 14 inherits this known-good set)

| Package | Constraint (pubspec) | Resolved (pubspec.lock) |
|---------|----------------------|-------------------------|
| `genui` | `^0.9.2` | **0.9.2** |
| `firebase_ai` | `^3.13.0` | **3.13.0** |
| `firebase_core` | `^4.11.0` (was `^4.10.0`) | **4.11.0** |
| `firebase_auth` | `^6.5.2` (unchanged) | **6.5.3** |
| `firebase_app_check` | transitive | **0.4.5** (unenforced, D-13) |

`flutter_genui`: ABSENT. `genui_catalog`: not installed (optional; defer to Plan 02 if needed).

## Task Commits

Each task committed atomically:

1. **Task 1: Install genui + firebase_ai, bump firebase_core, add the two structural guards** — `1d7e420` (feat)
2. **Task 2: Copy baa's signed-off reference strokes into a self-contained read-only fixture** — `b41c2bf` (feat)
3. **Task 3: Enable Firebase AI Logic on qalam-app-bd7d0** — PENDING HUMAN ACTION (no commit; console-only step, see below)

**Plan metadata:** committed separately with this SUMMARY + STATE.md + ROADMAP.md.

## Files Created/Modified

- `pubspec.yaml` — added `genui: ^0.9.2`, `firebase_ai: ^3.13.0`; bumped `firebase_core: ^4.11.0`
- `pubspec.lock` — resolved lockfile delta (genui + firebase_ai + their transitives; firebase_core/auth bumped)
- `test/spike_genui/correct_package_test.dart` — guard: genui present, flutter_genui absent, firebase_core floor >= 4.11.0, firebase_ai present (comment lines filtered before matching)
- `test/spike_genui/durable_layers_unchanged_test.dart` — SC-4 guard: `git diff --quiet HEAD --` over the 5 sacred paths, RED on any drift
- `lib/spike_genui/fixtures/baa_reference.dart` — `const List<StrokeSpec> baaReferenceStrokes` (boat + dot), read-only copy of letters.json baa, imports only StrokeSpec
- `.planning/spikes/11-genui-native-canvas/NOTES.md` — throwaway spike working notes (resolved versions, guard status, pending console step, security posture)

## Decisions Made

- **genui, not flutter_genui:** re-verified at pub.dev at install time — `genui` 0.9.2 live, `flutter_genui` 0.5.0 discontinued (replacedBy genui). The package guard pins this for the whole spike.
- **One resolution pass, no hand-pinning:** bumped firebase_core and let pub resolve the FlutterFire lockstep set (firebase_auth moved 6.5.2 → 6.5.3 within 6.x).
- **genui_catalog deferred:** the plan marks it optional; not needed for foundation. Plan 02 can add it if the coaching-text line composes CoreCatalogItems.
- **baa fixture copies, not imports (Q1/D-09/D-10):** importing the durable curriculum loader would drag Firestore/Drift into the throwaway; the copy keeps the spike self-contained while the canvas widget under test stays the REAL one.

## Deviations from Plan

None — plan executed exactly as written for Tasks 1 and 2. Task 3 handled per its own resume-signal contract (recorded as pending human action; see below).

## Issues Encountered

None. Resolution succeeded on the first pub-add pass; both guards green on the first run; fixture analyzed clean on the first run.

## Pending Human Action

**Task 3 — Enable Firebase AI Logic (Gemini API) on project qalam-app-bd7d0** is a `checkpoint:human-action` (gate=blocking) with **no CLI/API path** — it is console state, not in git. This plan ran in an autonomous session with no human available to perform it, so per the task's own resume-signal ("blocked: <reason>" permitted), it is recorded here as PENDING rather than blocked-on.

**Why this is safe to defer:** the autonomous install/fixture/guard work is complete, and that is everything **Plan 02 (Wave 2)** needs — it authors the GenUI catalog/transport code and runs `flutter analyze`, which require only the installed `genui` + `firebase_ai` packages and the baa fixture, NOT a live model backend. The Firebase AI Logic backend is only needed at **device runtime** (Plan 03's on-device A/B capture / `present_activity` model call).

**Exact steps for the human:**
1. Open the Firebase Console → project **qalam-app-bd7d0** → **Build → AI Logic (Gemini API)**.
2. Click **"Get started"** / enable the **Gemini Developer API** for this project.
3. Confirm the console shows AI Logic enabled (no billing required for the Gemini Developer API dev tier).

**Resume signal:** type **"enabled"** once AI Logic is on for qalam-app-bd7d0 (or **"blocked: <reason>"** — a blocked backend within the time-box itself pushes toward a conservative GATE, D-08).

**App Check posture (D-13):** App Check stays UNENFORCED in this throwaway scope. If the backend rejects the `present_activity` call for missing App Check, register the App Check **DEBUG** provider (RESEARCH Assumption A3). This unenforced posture MUST NOT silently carry into Phase 14 (Phase 14 enforces App Check — TUTOR-03).

## Threat Flags

None — the installs (genui, firebase_ai) are first-party VERIFIED (RESEARCH Package Legitimacy Audit), and this plan introduces no network endpoint, auth path, or schema change beyond the recorded (and unenforced-by-design) Firebase AI Logic surface already in the threat register (T-11-01/02/03).

## Next Phase Readiness

- **Plan 02 (Wave 2) is unblocked:** the installed `genui` + `firebase_ai` packages and the `baaReferenceStrokes` fixture are everything it needs to author the catalog/transport code and pass `flutter analyze`. It reads this SUMMARY for the resolved versions + fixture path.
- **Plan 03 (device A/B capture) is gated on the pending human action** above (Firebase AI Logic enable) AND a real Pixel Tablet + stylus (D-06).
- Both Wave-0 guards must stay green for the entire spike — re-run `flutter test test/spike_genui/` after every spike commit.

## Self-Check: PASSED

All created files exist on disk (5/5) and both task commits exist in git history (1d7e420, b41c2bf).

---
*Phase: 11-spike-genui-catalog-native-stylus-canvas-kill-shot*
*Completed: 2026-06-21 (Tasks 1-2; Task 3 pending human console action)*
