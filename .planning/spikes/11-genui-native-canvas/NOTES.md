# Phase 11 Spike — GenUI catalog + native stylus canvas (kill-shot)

> Throwaway working notes for the GATE decision. Deletable with the rest of the
> spike. The decisive evidence is an on-device A/B video judged by feel (D-06);
> these notes record the build-up to it.

## Resolved known-good package set (Pitfall 4 — Phase 14 inherits this)

Installed via one `flutter pub add` resolution pass (no hand-pinning of FlutterFire
majors), Flutter 3.41.9 / Dart 3.11.5:

| Package | Constraint (pubspec) | Resolved (pubspec.lock) | Notes |
|---------|----------------------|-------------------------|-------|
| `genui` | `^0.9.2` | **0.9.2** | publisher labs.flutter.dev; live (NOT discontinued) |
| `firebase_ai` | `^3.13.0` | **3.13.0** | publisher firebase.google.com |
| `firebase_core` | `^4.11.0` (was `^4.10.0`) | **4.11.0** | bumped to satisfy firebase_ai 3.13.0 floor |
| `firebase_auth` | `^6.5.2` (unchanged) | **6.5.3** | auto-resolved within 6.x (firebase_ai needs ^6.5.3) |
| `firebase_app_check` | (transitive) | **0.4.5** | pulled by firebase_ai; left UNENFORCED in throwaway scope (D-13) |

`flutter_genui` is **ABSENT** (discontinued 0.5.0, replacedBy: genui — verified at
pub.dev at install time). `genui_catalog` was optional (CoreCatalogItems) and was
NOT added in this plan — add it in Plan 02 if the model-generated coaching-text line
is composed from `CoreCatalogItems` rather than a hand-authored text item.

## Structural guards (Wave 0 — must stay green the whole spike)

- `test/spike_genui/correct_package_test.dart` — genui present, flutter_genui absent,
  firebase_core floor >= 4.11.0, firebase_ai present. Comment lines filtered before
  matching so prose naming flutter_genui can't self-invalidate the gate.
- `test/spike_genui/durable_layers_unchanged_test.dart` — SC-4 / TUTOR-01: runs
  `git diff --quiet HEAD --` over the 5 sacred paths and fails RED on any drift.

Both green at Task-1 commit (`1d7e420`). Re-run after every spike commit:
`flutter test test/spike_genui/`.

## baa fixture (Q1 resolved)

`lib/spike_genui/fixtures/baa_reference.dart` — `const List<StrokeSpec>`
baaReferenceStrokes, copied read-only from `assets/curriculum/letters.json`
baa entry (signedOff). Two strokes: order-1 'body' 12-point boat (rightToLeft) +
order-2 'dot' single tap at [0.498, 0.644]. Imports ONLY
`package:qalam/models/letter.dart`. Curriculum loader deliberately NOT imported.

## Pending human action — Firebase AI Logic console enable (Task 3)

Task 3 (`checkpoint:human-action`, gate=blocking) is a HUMAN-ONLY Firebase Console
step with no CLI/API path. Executed in an autonomous session with no human present →
recorded as PENDING, not blocked on. The autonomous install/fixture/guard work is
complete and is all Plan 02 needs (code authoring + `flutter analyze`); the live
backend is only needed at device runtime (Plan 03 A/B capture).

**Steps for the human:**
1. Firebase Console → project **qalam-app-bd7d0** → Build → AI Logic (Gemini API).
2. Click "Get started" / enable the **Gemini Developer API** for this project.
3. Confirm the console shows AI Logic enabled (no billing for the dev tier).

**App Check posture (D-13):** left UNENFORCED in throwaway scope. If the backend
rejects the `present_activity` call for missing App Check, register the App Check
**DEBUG** provider (RESEARCH Assumption A3). This unenforced posture MUST NOT carry
into Phase 14 (Phase 14 enforces App Check — TUTOR-03). Resume signal when enabled:
"enabled" (or "blocked: <reason>" — a blocked backend within the time-box itself
pushes toward a conservative GATE, D-08).

## Security posture for the spike (record so it does NOT leak to Phase 14)

- Model call carries ONLY `present_activity` text + `letterId: "baa"` — NEVER raw
  `List<Offset>` strokes, NEVER nickname/name/PII. The per-stroke pointer→paint loop
  stays entirely local (D-07).
- API key stays in the Firebase AI Logic backend, never in the client.
- App Check UNENFORCED (D-13) — acceptable ONLY because the spike is local, time-boxed,
  deletable, and sends no strokes/PII.
