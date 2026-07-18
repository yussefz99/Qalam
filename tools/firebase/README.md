# Firestore curriculum tooling

Python `firebase-admin` tooling that migrates the bundled curriculum into Cloud
Firestore and keeps the offline snapshot refreshable. Implements LOCKED decisions
D-13 (Python seed), D-15 (refreshable export), D-07 (tolerance ramp meta doc),
D-14 (console-edit operating policy), and D-16 (Firestore Native, Spark tier).

## What's here

| File | Purpose |
|------|---------|
| `point_codec.py` | Shared `{x,y}`⇄`[x,y]` point transform (Plan 02). Imported by both scripts so the seed, export, and Dart read path agree (D-06). |
| `seed_firestore.py` | `letters.json` + `lessons.json` → Firestore `letters` / `lessons` collections + `meta/toleranceRamp`. **Idempotent by doc id** (uses `set()`, never `add()`). |
| `seed_curriculum_v2.py` | `graphs/<letter>.json` + `exercises.json` + `units.json` → Firestore `graphs` / `exercises` / `units` collections (finalization Lane A — the app resolves these Firestore-first with the bundled assets as fallback, so seeding a letter here brings it live with **no rebuild**). `--letter <id>` for one letter, `--all` for every letter with a graph asset. Same idempotent `doc(id).set()` posture; validates against Firestore's no-nested-arrays rule before any write. |
| `export_firestore.py` | Firestore → refreshed `assets/curriculum/letters.json` + `lessons.json`. The inverse of the seed. |
| `test_roundtrip.py` | Proves seed→export is lossless against the source JSON **without** needing a live Firestore or the service-account key — runs in CI. |
| `requirements.txt` | Pins `firebase-admin>=6.5.0`. |

## :rotating_light: NEVER commit the service-account key

The admin-SDK service-account private key grants **full admin write access** to
Firestore and **bypasses all security rules** (threat T-06.1-07, elevation of
privilege). It is a secret.

- The key lives under `tools/firebase/` and is **gitignored** — the globs
  `tools/firebase/*serviceAccount*.json`, `tools/firebase/*.key.json`, and
  `tools/firebase/*adminsdk*.json` in the repo `.gitignore` exclude it.
- **Never** `git add` a key file. **Never** paste its contents anywhere.
- The scripts read it **only** via the `GOOGLE_APPLICATION_CREDENTIALS` environment
  variable — it is never hardcoded.
- Verify it is ignored before any commit:
  ```bash
  git check-ignore tools/firebase/<your-key>.json   # must print the path
  ```

## Setup

1. **Firestore database** (D-16): a Cloud Firestore database in **Native mode** on
   the **Spark** (free) tier must exist, in a permanent owner-approved region. No
   billing / Data Connect (D-17).
2. **Service-account key**: Firebase Console → Project settings → Service accounts →
   *Generate new private key*. Save the JSON into `tools/firebase/` (it is gitignored).
3. **Install deps** (use a venv):
   ```bash
   python -m venv .venv && source .venv/Scripts/activate   # Windows Git Bash
   pip install -r tools/firebase/requirements.txt
   ```
4. **Point the SDK at the key**:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS=tools/firebase/<your-key>.json
   ```
   The Admin SDK authenticates via Application Default Credentials, which reads this
   variable. It bypasses Firestore security rules, so the production deny-all rules do
   not block these tools.

## Run order

```bash
# 1. Seed the curriculum into Firestore (idempotent — safe to re-run).
python tools/firebase/seed_firestore.py

# 1b. Seed the v2 progression content (graphs/exercises/units — Lane A).
python tools/firebase/seed_curriculum_v2.py --all      # or --letter <id>

# 2. Export Firestore back into the bundled snapshot.
python tools/firebase/export_firestore.py

# Lossless check: after a seed→export round-trip the source JSON is unchanged.
git diff assets/curriculum/letters.json assets/curriculum/lessons.json   # should be clean
```

The offline (key-free) parity gate, runnable in CI:

```bash
python tools/firebase/test_roundtrip.py   # exits 0 when the transform is lossless
```

## D-14 — ongoing curriculum edits happen in the Firebase Console

There is **no custom in-app or web authoring tool this phase**. The data model is
doc-per-letter / doc-per-lesson, which is console-friendly: a curriculum author (the
owner's mother) edits a letter's `referenceStrokes`, `commonMistakes`, `signedOff`,
etc. directly in the Firebase Console.

`export_firestore.py` (D-15) is how those console edits flow back into the bundled
offline snapshot: edit in the console → run the export → commit the refreshed
`assets/curriculum/*.json`. The seed (D-13) is the one-time / re-runnable migration
that gets the curriculum *into* Firestore in the first place; the export is the
ongoing refresh path.
