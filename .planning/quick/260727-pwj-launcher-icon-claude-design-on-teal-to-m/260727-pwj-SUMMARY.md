---
phase: quick-260727-pwj
plan: 01
subsystem: android-release
tags: [launcher-icon, play-release, branding, compliance]
requires: ["~/Downloads/export/play/qalam-icon-512.png (the uploaded Play listing icon)"]
provides:
  - "Android launcher icon == the Play listing قلم-on-teal art (all densities, legacy + adaptive)"
  - "versionCode 5 signed AAB + matching webcourse APK twin"
affects: [android-launcher, play-listing-parity, release-versioning]
tech-stack:
  added: []
  patterns: ["chroma-key glyph extraction from the store art (throwaway generator, PNGs are the durable record)"]
key-files:
  created:
    - assets/branding/qalam_icon_store_512.png
  modified:
    - assets/branding/qalam_icon_foreground.png
    - flutter_launcher_icons.yaml
    - pubspec.yaml
    - android/app/src/main/res/values/colors.xml
    - android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png
    - android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_foreground.png
decisions:
  - "Sampled teal is #168A8E (measured), 1 unit of green off the plan's expected #16898E — measured value used per the plan"
  - "aapt2 cannot read an .aab container; the AAB base module was repacked as a proto APK to run `aapt2 dump resources` against the SHIPPED bundle"
metrics:
  duration: ~16 min
  completed: 2026-07-27
---

# Quick 260727-pwj: Launcher icon = the Play listing قلم-on-teal art Summary

Replaced the Android launcher icon with the exact قلم-on-teal art already uploaded as the Play
listing icon, bumped to versionCode 5, and rebuilt the signed AAB + webcourse APK twin from one
commit — proving the new art is inside the shipped bundle with aapt2.

## The rejection and the fix

Google rejected the app on **2026-07-27 for misleading claims**: Play production ran 2.0.0+3 with
the **stock Flutter launcher icon** while the store listing showed the owner's Claude-Design قلم
art. The repo's then-current launcher (Phase 26-02's reed nib on parchment) did **not** match the
listing either, and 26-02's config comment claiming it "matched the Play listing art" was
factually wrong.

**Owner's decision this session:** keep the store icon as-is and make the APP match IT.

- Legacy (pre-API-26) mipmaps are generated from the **flat store art itself** → exact pixel match
  to the listing icon.
- The adaptive (API 26+) foreground is the cream قلم **chroma-keyed off** that same store art onto
  a transparent 1024×1024 canvas, over the teal sampled from the art.
- The stale/incorrect 26-02 comment blocks in `flutter_launcher_icons.yaml` and `colors.xml` were
  replaced with accurate provenance.

## Task 1 — icon extraction and regeneration

**Provenance copy (byte-identical):**
`~/Downloads/export/play/qalam-icon-512.png` → `assets/branding/qalam_icon_store_512.png`
sha256 `7c681d7dfe226d5d684d33c36e6c32bffbccba3de7ee373636713c4f901ca363` (both files match).
NOT added to pubspec's bundled `assets:` list — build-time provenance only, zero app-size cost.

**Measured values** (throwaway Pillow generator run under `/usr/bin/python3`, written to the
scratchpad, not the repo — the produced PNGs plus this record are the durable artifact):

| Measurement | Value | Plan expected | Delta |
|---|---|---|---|
| Edge-ring colour | `#148387` (20.2, 130.8, 135.3) | ≈ `#138287` | ~1/unit — vignette confirmed |
| **Teal reference (mean over 230,544 px = 87.9% of image)** | **`#168A8E`** (22.1, 137.7, 142.4) | `#16898E` | **+1 green** — measured value used |
| Glyph colour (fully-opaque mean, pre-unpremultiply) | `#F3F3EB` (243.4, 242.8, 235.2) | ≈ `#FAF6EE` | cream confirmed |
| Source alpha bbox | (73, 165, 433, 416) = 360×251 px | x 73–432, y 166–415 | matches (1 row of faint AA) |
| bbox as % of the 512 source | 70.3% w, 49.0% h | 70.3% w, 48.8% h | matches |
| Scaled glyph on the 1024 canvas | 614×428 px = **60.0% w**, 41.8% h | 614 px = 60% | exact (width-bound) |
| Final alpha bbox on the canvas | (205, 298, 819, 726), corner alpha 0 | centred, transparent | matches |
| Final opaque mean | `#F6F5ED` (246.2, 244.6, 237.0) | cream | each channel > 200 |

Chroma-key used the specified **soft** ramp (`alpha = clamp((d − 30)/(90 − 30), 0, 1)`), not a hard
threshold, and un-premultiplied partial-alpha pixels toward the glyph colour so no teal fringe
survives. The قلم underline is inside the bbox and was kept — it is part of the mark.

**Sizing:** 60% of the PNG (not the source's 70%) is the safe-zone accommodation for the
`android:inset="16%"` wrapper in `mipmap-anydpi-v26/ic_launcher.xml`. That inset is untouched.

**Generated output sanity check (working tree, all densities):**

| Density | Legacy `ic_launcher.png` corner | Adaptive `ic_launcher_foreground.png` |
|---|---|---|
| mdpi | (20, 133, 138) teal | 108² · corner α=0 · bbox w 66 = 61.1% |
| hdpi | (20, 131, 136) teal | 162² · corner α=0 · bbox w 98 = 60.5% |
| xhdpi | (20, 130, 135) teal | 216² · corner α=0 · bbox w 130 = 60.2% |
| xxhdpi | (19, 129, 134) teal | 324² · corner α=0 · bbox w 195 = 60.2% |
| xxxhdpi | (19, 129, 133) teal | 432² · corner α=0 · bbox w 260 = 60.2% |

`colors.xml`: `ic_launcher_background` `#FAF6EE` (parchment) → **`#168A8E`** (sampled store teal).
The generator preserved but did not update the old parchment comment, so it was rewritten by hand
to record the real provenance.

`pubspec.yaml`: `version: 2.0.1+4` → **`2.0.1+5`** (versionName unchanged — Play only needs a
higher versionCode).

Task 1 automated verification: **PASS** — `icons OK (205, 298, 819, 726) (19, 129, 133)`.

## Task 2 — the signed build pair

**Release commit (the single SHA both artifacts build from):**
`01e3c7a` — `01e3c7aefd5ad55e472247f615ff82656693df79` on `release/2.0.1`.

Sequence, in one pass, with **zero `--dart-define` flags** (flag-identical to the shipped 2.0.1+4
build): `flutter gen-l10n` → `flutter build appbundle --release` (506.8 s) → `flutter build apk
--release`. No other build ran in between; neither artifact was rebuilt afterwards.

| Artifact | Size | sha256 |
|---|---|---|
| `~/Desktop/qalam-2.0.1+5.aab` | 74,642,498 B (74.6 MB) | `f8617fe0296b3e74de5fa4842f0aa9b13c74a9192384217adeec0ab883876c89` |
| `~/Desktop/qalam-2.0.1+5-webcourse.apk` | 98,094,560 B (98.1 MB) | `5060bb84132c3bd333bd31fb0f9f17622921715b335b17944047f932f1c14fd3` |

Source paths (`build/app/outputs/bundle/release/app-release.aab`,
`build/app/outputs/flutter-apk/app-release.apk`) checksum **identical** to the Desktop copies.

**Signing verified — the real upload key, not debug:**
- APK: `apksigner verify` → *Verifies*, v2 scheme, 1 signer,
  DN `CN=Qalam, OU=Technion 236272, O=Qalam, L=Haifa, C=IL`,
  cert SHA-256 `898f38ba9821c592087de4cba75ba45fd7a2b4ad382154509f86380b2eebdc59`,
  SHA-1 `03b6cb3ab07071b2cd04be312b9cc6e8bbf84ebb`, RSA 2048.
- AAB: `jarsigner -verify` → *jar verified*, same DN, signature block `META-INF/UPLOAD.RSA`.
- Keystore stayed outside the repo (`~/qalam-upload-keystore.jks`); `android/key.properties` is
  gitignored (confirmed via `git check-ignore`) and was never staged.

Task 2 automated verification: **PASS** (`versionCode='5'` present, both files non-empty).

## Task 3 — proof the قلم art is INSIDE the shipped AAB

Verified against the binaries, not the working tree.

**1. APK badging:** `package: name='com.technion.qalam' versionCode='5' versionName='2.0.1'`,
`application: label='qalam' icon='res/BW.xml'` (the resource path is shortened in the release APK;
the AAB keeps real names — see 4).

**2. Extracted from `~/Desktop/qalam-2.0.1+5.aab`** — 5 legacy mipmaps, 5 adaptive foregrounds,
and the anydpi-v26 descriptor, all present under `base/res/`.

**3. Pillow assertions on the EXTRACTED AAB files — 16/16 PASS:**

| Assertion | mdpi | hdpi | xhdpi | xxhdpi | xxxhdpi |
|---|---|---|---|---|---|
| legacy corner teal (G>90, R<70) | (20,133,138) | (20,131,136) | (20,130,135) | (19,129,134) | (19,129,133) |
| foreground corner alpha == 0 | 0 | 0 | 0 | 0 | 0 |
| foreground bbox width (want 55–70%) | 61.1% | 60.5% | 60.2% | 60.2% | 60.2% |
| foreground opaque mean cream (>200/ch) | `#FAF6EE` | `#F7F5ED` | `#F8F5ED` | `#F6F4ED` | `#F8F5ED` |

Extra proof it is *the listing picture*, not merely "something teal": the AAB's
`mipmap-xxxhdpi/ic_launcher.png` versus the store art downscaled to 192² differs by a mean
per-channel **0.98** — pixel-equivalent. It is neither the parchment nib nor the stock Flutter
default.

**4. `ic_launcher_background` inside the AAB:**
`resource 0x7f060045 color/ic_launcher_background  () #ff168a8e` — the ARGB form of the sampled
teal written in Task 1. The same value appears in the APK's resource table.

**5. The full adaptive chain inside the AAB:** manifest `icon='res/mipmap-anydpi-v26/ic_launcher.xml'`
→ `<background android:drawable="@color/ic_launcher_background">` (`#ff168a8e`) +
`<foreground><inset android:inset="16%" android:drawable="@drawable/ic_launcher_foreground"/></foreground>`
(the cream قلم). `mipmap/ic_launcher` resolves to all five density PNGs plus the anydpi-v26 descriptor.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `aapt2 dump resources` cannot read an `.aab` container**

- **Found during:** Task 3, step 4 (and the Task 3 `<automated>` verify command)
- **Issue:** `aapt2 dump resources ~/Desktop/qalam-2.0.1+5.aab` exits 1 with
  `error: could not identify format of APK.` — aapt2 reads APKs and proto resource tables, not the
  AAB bundle container. Running it on the extracted `base/resources.pb` directly also fails
  (`failed opening zip`) because aapt2 expects a zip.
- **Fix:** Repacked the AAB's base module as a proto APK
  (`base/manifest/AndroidManifest.xml` → root `AndroidManifest.xml`, plus `resources.pb` and
  `res/`) in the scratchpad, then ran `aapt2 dump resources` against that. This reads the SHIPPED
  bundle's own resource table — the proof strength the plan asked for is preserved, only the
  invocation changed. `aapt2 dump badging` on the same repack confirmed the manifest icon
  reference. Cross-checked independently against the APK's resource table, which aapt2 reads
  natively and which reports the same `#ff168a8e`.
- **Files modified:** none (verification tooling only)
- **Commit:** n/a

**Working replacement for the plan's Task 3 verify leg:**
```
unzip -o -q qalam-2.0.1+5.aab 'base/manifest/AndroidManifest.xml' 'base/resources.pb' 'base/res/*' -d X
# flatten base/ to the zip root as AndroidManifest.xml + resources.pb + res/, re-zip as base-proto.apk
aapt2 dump resources base-proto.apk | grep -i ic_launcher_background   # -> #ff168a8e
```

**2. [Measurement] Sampled teal is `#168A8E`, not the plan's expected `#16898E`**

- **Found during:** Task 1(b)
- **Issue:** the measured mean over the store art's teal pixels is (22.1, 137.7, 142.4), which
  rounds to `#168A8E` — one unit of green above the plan's pre-measured `#16898E`.
- **Fix:** used the MEASURED value, exactly as the plan directs. Visually indistinguishable
  (ΔG = 1/255) and it is now what both `flutter_launcher_icons.yaml` and `colors.xml` carry.

**3. [Tooling] `apksigner` needed a JDK**

- **Found during:** Task 2 signature verification
- **Issue:** `apksigner` failed with *Unable to locate a Java Runtime*.
- **Fix:** used Android Studio's bundled JBR
  (`/Applications/Android Studio.app/Contents/jbr/Contents/Home`, OpenJDK 21.0.10) as `JAVA_HOME`,
  matching the existing project memory about keytool. No install performed.

No other deviations — no Rule 4 architectural changes, no package installs, no build-flag drift.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes. The only
committed asset is public store art already published on the Play listing (T-pwj-05, accepted),
and it is not bundled into the app.

## OWED — owner-only, NOT done by this task

**The Play Console upload of `~/Desktop/qalam-2.0.1+5.aab` to production AND the
`~/Desktop/qalam-2.0.1+5-webcourse.apk` twin to the webcourse — in lockstep — is owner-only and
was NOT performed here.** The two artifacts are a matched pair from commit `01e3c7a`; per the
finalization rule, if either ever needs a rebuild, BOTH must be rebuilt together and re-submitted
together. Do not ship one without the other.

Also still deferred: the **`android:label` change** (the app currently declares `label='qalam'`) —
out of scope for this task, unchanged by design.

Not verified here (no device in this session): the icon's on-device appearance under a launcher's
circular/squircle mask. The 60%-of-canvas glyph inside the 16% inset is the safe-zone-correct
sizing, but an eyeball check on the iPad/Android tablet before the upload is cheap insurance.

## Self-Check

Files claimed created/modified — all confirmed present on disk:
- `assets/branding/qalam_icon_store_512.png` — FOUND
- `assets/branding/qalam_icon_foreground.png` — FOUND (1024×1024, transparent corner)
- `flutter_launcher_icons.yaml` — FOUND (points at the store art, `#168A8E`)
- `pubspec.yaml` — FOUND (`version: 2.0.1+5`)
- `android/app/src/main/res/values/colors.xml` — FOUND (`#168A8E`, no `FAF6EE`)
- 5 × `mipmap-*/ic_launcher.png`, 5 × `drawable-*/ic_launcher_foreground.png` — FOUND, teal /
  transparent-cornered respectively
- `~/Desktop/qalam-2.0.1+5.aab`, `~/Desktop/qalam-2.0.1+5-webcourse.apk` — FOUND, checksummed

Commit claimed — confirmed in `git log`:
- `01e3c7a` `fix(260727-pwj): launcher icon = the Play listing قلم-on-teal art, versionCode 5`

## Self-Check: PASSED
