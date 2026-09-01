---
id: 260901-nuy
title: Play resubmission build 2.0.1+6
date: 2026-09-01
branch: release/2.0.1
status: in-progress
---

# Quick Task 260901-nuy — Play resubmission build 2.0.1+6

## Why

Play rejected the previous submission under **Broken Functionality**: letter
circles on the Journey did nothing when tapped, and speaker controls produced no
sound. The fix is commit `9d5c823` (already pushed, owner-confirmed on device
2026-09-01). It cannot be uploaded because `pubspec.yaml` still carried
`2.0.1+5` — the versionCode Play already holds — and the only AAB on disk was
built 2026-07-27, five weeks before the fix.

Play-only this run. The webcourse APK is explicitly OUT of scope (owner call,
2026-09-01), so the July lockstep AAB+APK rule does not apply here.

## Tasks

### T1 — Bump versionCode
- **files:** `pubspec.yaml`
- **action:** `version: 2.0.1+5` → `version: 2.0.1+6`. versionName stays 2.0.1
  (2.0.1 never successfully released; only the code must increase).
- **verify:** `grep '^version:' pubspec.yaml` → `2.0.1+6`
- **done:** version line reads 2.0.1+6

### T2 — Build the signed release AAB with the tutor URL baked in
- **action:** `flutter build appbundle --release --dart-define=TUTOR_BASE_URL=https://qalam-tutor-ogtudswkjq-uc.a.run.app`
- **note:** Departs from the July "ZERO dart-defines" parity decision. Owner
  decided 2026-09-01 to bake the URL so the live tutor is reachable. Server
  verified live and warm first: `qalam-tutor` us-central1, rev `00030-kq6`,
  `/health` 200 in 0.35s, `minScale=1`. Scope is honest and narrow — the agent
  path is `letter.id == 'baa'` only (see [[tutor-agent-path-is-baa-only]]); every
  other letter keeps the authored offline lines either way, and any transport
  failure degrades to exactly the current behavior.
- **verify:** build exits 0, AAB present at `build/app/outputs/bundle/release/app-release.aab`
- **done:** signed AAB produced

### T3 — Verify the artifact before it goes near Play
- **verify:**
  1. `aapt2 dump badging` → `versionCode='6'`, `versionName='2.0.1'`
  2. `TUTOR_BASE_URL` value present in the bundle's `libapp.so`
  3. launcher icon is the قلم-on-teal listing art from `01e3c7a`, NOT the stock
     Flutter icon (this is what got 2.0.0+3 rejected the first time)
- **done:** all three confirmed, AAB copied to `~/Desktop/qalam-2.0.1+6.aab`
  with its sha256 recorded

## Must haves

- versionCode 6 — anything lower is refused by Play as a duplicate
- The audio/tappability fix (`9d5c823`) is in the shipped commit
- The launcher icon still matches the store listing
- Nothing else changes: no content edits, no ROADMAP changes

## Out of scope

- Uploading to Play (owner does this; Claude does not touch the console)
- The webcourse APK
- Generalizing the tutor beyond baa — that is a planned phase, not this build
