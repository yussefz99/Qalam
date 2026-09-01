---
id: 260901-nuy
title: Play resubmission build 2.0.1+6
date: 2026-09-01
branch: release/2.0.1
status: complete
commit: c541814
---

# Quick Task 260901-nuy — SUMMARY

## What shipped

`2.0.1+6`, built from `release/2.0.1` at `c541814` (parent `9d5c823` = the
audio/tappability fix Play rejected the previous build for). Play-only — no
webcourse APK this run (owner decision 2026-09-01).

**Artifact:** `~/Desktop/qalam-2.0.1+6.aab` — 74,657,073 bytes
**sha256:** `b77b2fdad8b16971eeb45c887bc9a23a21fd4817f5322158614bce8eda97a58b`
(also at `build/app/outputs/bundle/release/app-release.aab`)

## Verification (all against the built artifact, not the source)

| Check | Result |
|---|---|
| versionCode | `6` — from the packaged manifest gradle wrote into THIS bundle |
| versionName | `2.0.1` |
| package | `com.technion.qalam` |
| Tutor URL baked in | `https://qalam-tutor-ogtudswkjq-uc.a.run.app` found in `base/lib/arm64-v8a/libapp.so` |
| Launcher icon | قلم-on-teal listing art, confirmed by eye on the extracted `base/res/mipmap-xxxhdpi-v4/ic_launcher.png` (192×192). NOT the stock Flutter icon that caused the first rejection. |
| Signing | `META-INF/UPLOAD.RSA` — `CN=Qalam, OU=Technion 236272, O=Qalam, L=Haifa, C=IL`, SHA1 `03:B6:CB:...:4E:BB`, valid to 2053. The real upload key, not debug. |

Note on the icon: the AAB's PNG hash differs from the repo source
(`a5ad56f3…` vs `2e23a624…`) because aapt2 re-encodes PNGs at packaging time.
The repo file itself is untouched since `01e3c7a`, and the packaged image was
visually confirmed — hash inequality here is expected, not a red flag.

## Deviation from the July build recipe

The 260727-pwj build was cut with **zero dart-defines** for parity. This one
bakes `TUTOR_BASE_URL` in, per owner decision 2026-09-01. Server checked live
first: `qalam-tutor` us-central1, rev `00030-kq6`, `/health` 200 in 0.35s,
`minScale=1` (warm, no cold start).

Scope of that flag is narrow and was stated plainly to the owner before
building: the agent path is gated `letter.id == 'baa'`
(`exercise_scaffold.dart:439`), so ONE letter gets live Claude coaching. The
other 5 unit letters and all 22 practice letters use authored lines regardless.
Any transport failure degrades to exactly the pre-flag behavior, so the flag
cannot make the app worse. See [[tutor-agent-path-is-baa-only]].

## Owed / open

- **Owner uploads** `~/Desktop/qalam-2.0.1+6.aab` to Play production. Claude does
  not touch the console.
- **`android:label` is still lowercase `qalam`** while the listing name is
  "Qalam". Flagged as a residual after the icon rejection and still not aligned.
  Low risk on its own, but it is a listing/app mismatch in the same family as
  the rejection reason. Not changed here — that was not in scope for this build.
- **Tutor generalization beyond baa** is real phase work (server curriculum
  registry + letter-parameterized prompt + wiring practice_screen to the brain),
  not a build flag. Owner asked for it 2026-09-01; not yet planned.
