---
phase: quick-260727-pwj
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - assets/branding/qalam_icon_store_512.png
  - assets/branding/qalam_icon_foreground.png
  - flutter_launcher_icons.yaml
  - pubspec.yaml
  - android/app/src/main/res/values/colors.xml
  - android/app/src/main/res/mipmap-mdpi/ic_launcher.png
  - android/app/src/main/res/mipmap-hdpi/ic_launcher.png
  - android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
  - android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
  - android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
  - android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png
  - android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png
  - android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png
  - android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png
  - android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png
autonomous: true
requirements: [PLAT-01]

must_haves:
  truths:
    - "The installed app's launcher icon is the SAME قلم-on-teal art as the Play store listing icon (no visual mismatch → removes the 2026-07-27 misleading-claims rejection cause)."
    - "The adaptive icon shows the cream قلم glyph on flat teal — not the reed nib, not parchment, not the stock Flutter default."
    - "versionCode is 5 (versionName stays 2.0.1), so Play accepts the upload over 2.0.0+3 / the built 2.0.1+4."
    - "The AAB and the webcourse APK are built from the SAME commit with NO --dart-define flags — flag-identical to the shipped 2.0.1+4 build except for the icon and versionCode."
    - "The قلم art is proven present INSIDE the built AAB (adaptive foreground + legacy mipmaps + teal background color), not just in the repo working tree."
  artifacts:
    - path: "assets/branding/qalam_icon_store_512.png"
      provides: "Provenance copy of the exact Play-listing icon art (single source of truth)"
    - path: "assets/branding/qalam_icon_foreground.png"
      provides: "1024x1024 transparent adaptive foreground — cream قلم glyph extracted from the store icon"
    - path: "flutter_launcher_icons.yaml"
      provides: "Icon config repointed at the store art with a teal adaptive background"
      contains: "qalam_icon_store_512.png"
    - path: "pubspec.yaml"
      provides: "version: 2.0.1+5"
      contains: "2.0.1+5"
    - path: "android/app/src/main/res/values/colors.xml"
      provides: "ic_launcher_background = the sampled store-icon teal"
  key_links:
    - from: "~/Downloads/export/play/qalam-icon-512.png (the uploaded listing icon)"
      to: "android/app/src/main/res/mipmap-*/ic_launcher.png (the on-device launcher)"
      via: "flutter_launcher_icons generation from the copied store art"
      pattern: "qalam_icon_store_512"
---

<objective>
Regenerate the Android launcher icon from the Claude-Design قلم-on-teal art that is already
uploaded as the Play listing icon, so the INSTALLED app matches the STORE listing. Then bump
versionCode to 5 and rebuild the signed AAB + webcourse APK twin in lockstep from one commit,
proving the new art is inside the AAB with aapt2.

Purpose: Play production runs 2.0.0+3 with the STOCK Flutter launcher icon while the listing
shows the owner's Claude-Design art → Google rejected the app on 2026-07-27 for misleading
claims (icon mismatch). The repo's current nib-on-parchment launcher (Phase 26-02) does NOT
match the listing either, and 26-02's config comment claiming it "matches the Play listing
art" is factually wrong. Owner decision this session: keep the store icon as-is and make the
APP match IT.

Output: new branding assets + icon config, versionCode 5, and a verified signed AAB/APK pair
on the Desktop with sha256 checksums.
</objective>

<execution_context>
@/Users/mareekhalila/Documents/Qalam/qalam/.claude/get-shit-done/workflows/execute-plan.md
@/Users/mareekhalila/Documents/Qalam/qalam/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@CLAUDE.md
@flutter_launcher_icons.yaml
@pubspec.yaml
@.planning/phases/26-the-finished-experience-entry-polish-and-the-2-0-1-release/26-07-PLAN.md
</context>

<locked_facts>
Verified by the orchestrator this session. Do NOT re-derive, re-decide, or contradict these.
If reality disagrees with one, STOP and report rather than improvising.

- **Branch:** work on the CURRENT branch `release/2.0.1`. Do NOT create a branch, do NOT touch
  `main`. This deliberately overrides the "phase work needs own branch" memory — this is
  release work on the release branch.
- **Source art (single source of truth):** `~/Downloads/export/play/qalam-icon-512.png` —
  512×512 RGBA, cream/parchment قلم Arabic lettering + a short underline on teal with a slight
  center-bright vignette. This exact file is what is uploaded on the Play listing.
- **Measured facts about that file** (orchestrator measured with Pillow — expected values;
  recompute to confirm):
  - Glyph color ≈ `(250, 246, 238)` = `#FAF6EE` (the parchment token).
  - Background mean over all teal pixels = `(22, 137, 142)` = `#16898E`.
    Edge ring ≈ `#138287`, center ≈ `#168A8F` (that is the vignette).
  - Glyph bounding box in the 512 source: x 73–432, y 166–415 → 70.3% of width, 48.8% of height.
- **Python:** use `/usr/bin/python3` (system Python — Pillow 11.3.0 confirmed present). The repo
  venv python has NO PIL. Do NOT pip-install anything.
- **NO `--dart-define` flags on the builds.** The orchestrator extracted strings from the shipped
  2.0.1+4 `libapp.so` and confirmed no `TUTOR_BASE_URL` / `GOOGLE_SERVER_CLIENT_ID` was baked in.
  This rebuild must be flag-identical.
- **Signing:** upload keystore `~/qalam-upload-keystore.jks` via the gitignored
  `android/key.properties` — verified present in this checkout. The release build config already
  reads it; no signing flags needed.
- **Version:** `2.0.1+4` → `2.0.1+5`. versionName stays `2.0.1`; only versionCode moves. Do NOT
  bump to 2.0.2 — Google only requires a higher versionCode.
- **aapt2:** `~/Library/Android/sdk/build-tools/36.1.0/aapt2` (confirmed present).
- **`assets/branding/` is NOT in pubspec's bundled `assets:` list** — the branding PNGs are
  build-time-only provenance and add ZERO app size. Do NOT add them to `assets:`.
- **Out of scope:** the Play Console upload (owner-only), iOS icons (`ios: false` stays — Android
  only per CLAUDE.md), the store listing itself (already correct, unchanged), and any
  `android:label` change (deferred).
</locked_facts>

<tasks>

<task type="auto">
  <name>Task 1: Extract the قلم glyph from the store art and regenerate the Android launcher icons</name>
  <files>assets/branding/qalam_icon_store_512.png, assets/branding/qalam_icon_foreground.png, flutter_launcher_icons.yaml, pubspec.yaml, android/app/src/main/res/values/colors.xml, android/app/src/main/res/mipmap-*/ic_launcher.png, android/app/src/main/res/drawable-*/ic_launcher_foreground.png</files>
  <read_first>
    - flutter_launcher_icons.yaml (current config — nib-on-parchment; the comment block is stale and wrong)
    - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml (note the `android:inset="16%"` wrapper around @drawable/ic_launcher_foreground — the reason for the 60% sizing, see <sizing_math>)
    - android/app/src/main/res/values/colors.xml (ic_launcher_background — currently #FAF6EE parchment)
    - pubspec.yaml line 19 (`version: 2.0.1+4`) and line 118 (flutter_launcher_icons ^0.14.4)
  </read_first>
  <action>
    Do these in order.

    (a) Copy the source art into the repo for provenance:
    `~/Downloads/export/play/qalam-icon-512.png` → `assets/branding/qalam_icon_store_512.png`
    (byte-identical — verify with `shasum -a 256` on both). Do NOT add it to pubspec's `assets:`
    list; it is build-time-only.

    (b) Build the adaptive FOREGROUND with a chroma-key extraction script run under
    `/usr/bin/python3`. Write the script into the scratchpad directory, NOT the repo — it is a
    one-shot generator; the produced PNGs plus this plan are the durable record. Algorithm:
      1. Open the 512 source as RGBA; compute the background teal reference as the MEAN of pixels
         within colour-distance 40 of the edge-ring colour (expect ≈ `(22,137,142)`).
      2. For every pixel compute euclidean RGB distance `d` to that teal reference. Map to alpha
         with a SOFT ramp so antialiased edges survive — do not threshold hard:
         `alpha = clamp((d - d_lo) / (d_hi - d_lo), 0, 1) * 255` with `d_lo ≈ 30`, `d_hi ≈ 90`.
         Keep each pixel's own RGB (the glyph is already cream `#FAF6EE`); optionally un-premultiply
         partial-alpha pixels toward the glyph colour so no teal fringe remains.
      3. Crop to the alpha bounding box (expect ≈ x 73–432, y 166–415 — the قلم plus its underline;
         the underline IS part of the mark, keep it).
      4. Scale that crop so its WIDTH is 60% of 1024 (= 614 px), preserving aspect ratio, LANCZOS
         resampling. If the resulting height would exceed 60% of 1024, scale by height instead so
         neither dimension breaks 60%.
      5. Paste centred on both axes onto a fully transparent 1024×1024 RGBA canvas.
      6. Save as `assets/branding/qalam_icon_foreground.png`, OVERWRITING the reed-nib version
         (flutter_launcher_icons.yaml already points there).
      7. Print for the SUMMARY: the sampled teal hex, the source bbox, the scaled glyph size, and
         the final alpha bbox on the 1024 canvas.

    (c) Rewrite `flutter_launcher_icons.yaml`:
      - `image_path: "assets/branding/qalam_icon_store_512.png"` — the LEGACY (pre-API-26) mipmaps
        come from the FLAT store art directly, so they are an exact pixel match to the listing icon.
      - `adaptive_icon_foreground: "assets/branding/qalam_icon_foreground.png"` (path unchanged).
      - `adaptive_icon_background: "#16898E"` — the sampled teal from step (b1). If the script's
        measured mean differs, USE THE MEASURED VALUE and note the delta in the SUMMARY.
      - `android: true`, `ios: false`, `min_sdk_android: 21` unchanged.
      - REPLACE the entire stale comment block. The new comment must state: the source is the
        Claude-Design قلم-on-teal Play LISTING icon (`assets/branding/qalam_icon_store_512.png`,
        provenance copy of `~/Downloads/export/play/qalam-icon-512.png`); this exists to fix the
        2026-07-27 Play misleading-claims rejection caused by the installed icon not matching the
        listing; the legacy mipmaps are the flat store art and the adaptive foreground is the
        chroma-keyed glyph on the sampled teal; and that the earlier 26-02 claim of "matching the
        Play listing art" (reed nib on parchment) was WRONG. Keep the
        `dart run flutter_launcher_icons` regeneration line and the iOS-excluded note.

    (d) Bump `pubspec.yaml` line 19: `version: 2.0.1+4` → `version: 2.0.1+5`.

    (e) Run `dart run flutter_launcher_icons` (`flutter pub get` first if the tool is unresolved).
    It rewrites the mipmap/drawable PNGs and `values/colors.xml`.

    (f) The generator overwrites `values/colors.xml` and DROPS its comment. Re-add a short comment
    above `ic_launcher_background` recording that the value is the teal sampled from the Play
    listing art (2026-07-27 icon-match fix), and confirm the colour now reads the sampled teal,
    NOT `#FAF6EE`.

    (g) Sanity-check the generated art before moving on: assert `mipmap-xxxhdpi/ic_launcher.png`
    has teal (not parchment) corner pixels, and that `drawable-xxxhdpi/ic_launcher_foreground.png`
    has a transparent corner and a non-empty alpha bbox. Same throwaway-script style; report the
    numbers.
  </action>
  <sizing_math>
    Why 60% and not the source's 70%: `mipmap-anydpi-v26/ic_launcher.xml` wraps the foreground
    drawable in `android:inset="16%"`, so the 1024 PNG maps to the central ~68% of the 108dp
    adaptive layer — almost exactly the 72dp VISIBLE (masked) area. A glyph at 60% of the PNG
    therefore renders at ~60% of the visible circle, versus 70% in the flat square store icon.
    That is the correct safe-zone accommodation: a 70%-wide glyph would touch the circular mask.
    Do NOT "fix" this by removing the inset.
  </sizing_math>
  <verify>
    <automated>grep -q '^version: 2.0.1+5' pubspec.yaml && grep -q 'qalam_icon_store_512.png' flutter_launcher_icons.yaml && ! grep -qi 'FAF6EE' android/app/src/main/res/values/colors.xml && test -s assets/branding/qalam_icon_store_512.png && /usr/bin/python3 -c "from PIL import Image; f=Image.open('assets/branding/qalam_icon_foreground.png').convert('RGBA'); assert f.size==(1024,1024), f.size; assert f.getpixel((5,5))[3]==0, 'foreground corner not transparent'; b=f.split()[3].getbbox(); w=b[2]-b[0]; assert 560 < w < 660, f'glyph width {w} not ~614'; l=Image.open('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png').convert('RGB'); c=l.getpixel((4,4)); assert c[1]>90 and c[0]<70, f'legacy corner not teal: {c}'; print('icons OK', b, c)"</automated>
  </verify>
  <done>`assets/branding/qalam_icon_store_512.png` is the provenance copy, `qalam_icon_foreground.png` is a 1024×1024 transparent canvas with the cream قلم at ~60% width centred, flutter_launcher_icons.yaml points at the store art with the sampled teal background and an accurate comment, colors.xml holds the teal, all mipmap/drawable icons are regenerated, and pubspec reads `2.0.1+5`.</done>
</task>

<task type="auto">
  <name>Task 2: Build the signed AAB + webcourse APK twin in lockstep from one commit</name>
  <files>(no repo file edits — build artifacts only: build/app/outputs/bundle/release/app-release.aab, build/app/outputs/flutter-apk/app-release.apk)</files>
  <read_first>
    - .planning/phases/26-the-finished-experience-entry-polish-and-the-2-0-1-release/26-07-PLAN.md Task 2 (the canonical build procedure this mirrors)
    - Project memory: play-upload-keystore (~/qalam-upload-keystore.jks, creds in gitignored android/key.properties); finalization-workspace (AAB+APK built TOGETHER — NO rebuilds unless BOTH are re-submitted); l10n-generated-gitignored (lib/l10n/app_localizations*.dart is gitignored — run `flutter gen-l10n` first)
  </read_first>
  <action>
    Commit Task 1's changes FIRST so both artifacts provably come from one recorded commit on
    `release/2.0.1` (record the SHA for the SUMMARY). Then:

    1. `flutter gen-l10n` — the generated localizations are gitignored; a stale or absent
       generation breaks the build.
    2. `flutter build appbundle --release`
    3. `flutter build apk --release`

    Both with ZERO `--dart-define` flags — flag-identical to the shipped 2.0.1+4 build (see
    <locked_facts>). Both are signed automatically by the release signing config reading
    `android/key.properties` + `~/qalam-upload-keystore.jks`. If the keystore or its password is
    unavailable, STOP and hand the signing step to the owner with the exact commands rather than
    producing a debug-signed artifact.

    Do NOT run any other build in between, and do NOT rebuild either artifact afterwards — the AAB
    and APK must remain the matched pair (finalization memory). If anything forces a rebuild, BOTH
    must be rebuilt together.

    Copy the pair to the Desktop with the release names:
      `~/Desktop/qalam-2.0.1+5.aab` (from build/app/outputs/bundle/release/app-release.aab)
      `~/Desktop/qalam-2.0.1+5-webcourse.apk` (from build/app/outputs/flutter-apk/app-release.apk)
    and record `shasum -a 256` for BOTH (source path and Desktop copy must match).
  </action>
  <verify>
    <automated>test -s ~/Desktop/"qalam-2.0.1+5.aab" && test -s ~/Desktop/"qalam-2.0.1+5-webcourse.apk" && ~/Library/Android/sdk/build-tools/36.1.0/aapt2 dump badging ~/Desktop/"qalam-2.0.1+5-webcourse.apk" | grep -q "versionCode='5'"</automated>
  </verify>
  <done>The signed AAB and APK are built from the same recorded commit with no dart-defines, copied to the Desktop as `qalam-2.0.1+5.aab` / `qalam-2.0.1+5-webcourse.apk`, and both sha256 checksums are captured; `aapt2 dump badging` reports versionCode 5 and versionName 2.0.1.</done>
</task>

<task type="auto">
  <name>Task 3: Prove the قلم art is inside the built AAB with aapt2, then write the SUMMARY</name>
  <files>.planning/quick/260727-pwj-launcher-icon-claude-design-on-teal-to-m/260727-pwj-SUMMARY.md</files>
  <read_first>
    - The Task 2 build output paths and checksums
    - assets/branding/qalam_icon_store_512.png (the reference the AAB contents must match)
  </read_first>
  <action>
    Verify the shipped binary, not the working tree. Using
    `~/Library/Android/sdk/build-tools/36.1.0/aapt2` and `unzip`:

    1. `aapt2 dump badging ~/Desktop/qalam-2.0.1+5-webcourse.apk` → confirm `versionCode='5'`,
       `versionName='2.0.1'`, and that the declared application icon points at the launcher mipmap.
    2. Extract from the AAB — resources live under `base/res/...`:
       `unzip -o ~/Desktop/qalam-2.0.1+5.aab '*ic_launcher*' '*ic_launcher_foreground*' -d <scratchdir>`
       — pulling a legacy `mipmap-xxxhdpi/ic_launcher.png`, a
       `drawable-xxxhdpi/ic_launcher_foreground.png`, and the anydpi-v26 adaptive descriptor. The
       descriptor may be binary-encoded; `aapt2 dump resources ~/Desktop/qalam-2.0.1+5.aab | grep -A3 ic_launcher`
       is the reliable read.
    3. With `/usr/bin/python3` + Pillow, assert on the EXTRACTED files:
       - legacy icon: corner pixels are teal (green channel > 90, red < 70) — proving it is NOT the
         parchment nib and NOT the stock Flutter default;
       - adaptive foreground: corner alpha == 0 and a non-empty alpha bbox occupying roughly 55–70%
         of the image width;
       - the foreground's opaque pixels are cream (mean RGB near `#FAF6EE`, each channel > 200).
    4. Confirm `ic_launcher_background` resolves to the sampled teal inside the AAB
       (`aapt2 dump resources ~/Desktop/qalam-2.0.1+5.aab | grep -i ic_launcher_background` → expect
       the `#ff16898e`-style ARGB form of the value written in Task 1).

    Then write the SUMMARY at
    `.planning/quick/260727-pwj-launcher-icon-claude-design-on-teal-to-m/260727-pwj-SUMMARY.md`
    recording: the rejection cause and the fix, the sampled teal hex + glyph bbox/scale numbers from
    Task 1, the release commit SHA, both artifact paths + sha256 checksums, the aapt2 verification
    results (each assertion above with its measured value), and an explicit OWED line: **the Play
    Console upload of `qalam-2.0.1+5.aab` to production and the `qalam-2.0.1+5-webcourse.apk` twin
    to the webcourse — in lockstep — is owner-only and NOT done by this task.** Also note the
    still-deferred `android:label` change.
  </action>
  <verify>
    <automated>test -s .planning/quick/260727-pwj-launcher-icon-claude-design-on-teal-to-m/260727-pwj-SUMMARY.md && grep -qi 'sha256' .planning/quick/260727-pwj-launcher-icon-claude-design-on-teal-to-m/260727-pwj-SUMMARY.md && ~/Library/Android/sdk/build-tools/36.1.0/aapt2 dump resources ~/Desktop/"qalam-2.0.1+5.aab" | grep -i ic_launcher_background</automated>
  </verify>
  <done>aapt2 proves the AAB carries versionCode 5 plus the قلم art at every layer (teal legacy mipmaps, transparent-cornered cream adaptive foreground, teal `ic_launcher_background`), and the SUMMARY records the commit SHA, both checksums, every measured verification value, and the owner-only Play/webcourse upload as OWED.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| store listing art → installed app icon | A mismatch between the two is exactly what Google flagged as a misleading claim; the copied provenance asset is the only bridge |
| upload keystore → signed artifact | `~/qalam-upload-keystore.jks` authenticates the app to Play; a debug-signed artifact is rejected and losing the key ends update authority |
| build commit → shipped binary pair | The Play AAB and the webcourse APK must be the SAME pair; drift ships two different apps under one version |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-pwj-01 | Spoofing | launcher icon vs listing icon | mitigate | Legacy mipmaps generated from the byte-identical provenance copy of the uploaded listing art; Task 3 asserts the art inside the AAB, not just in the tree |
| T-pwj-02 | Tampering | AAB/APK drift | mitigate | Both built from one committed SHA in a single pass (Task 2), sha256-checksummed; explicit no-rebuild-unless-both rule |
| T-pwj-03 | Tampering | build-flag drift vs shipped 2.0.1+4 | mitigate | Zero `--dart-define` flags, confirmed against strings extracted from the shipped `libapp.so` |
| T-pwj-04 | Elevation of privilege | signing key handling | mitigate | Keystore stays outside the repo, `android/key.properties` gitignored; stop-and-hand-to-owner if the password is unavailable rather than debug-signing |
| T-pwj-05 | Information disclosure | provenance PNG committed to the repo | accept | Public store art already published on the Play listing; not bundled into the app (`assets/branding/` absent from pubspec `assets:`) |
| T-pwj-SC | Tampering | package installs | accept | No package installs — existing `flutter_launcher_icons ^0.14.4` and system Pillow only; supply-chain surface unchanged |
</threat_model>

<verification>
- `flutter_launcher_icons.yaml` points at `assets/branding/qalam_icon_store_512.png` with the sampled teal `adaptive_icon_background`, and its comment no longer claims the nib matches the listing.
- `pubspec.yaml` reads `version: 2.0.1+5`.
- Generated legacy mipmaps are teal-cornered; the adaptive foreground is a transparent-cornered cream قلم at ~60% width.
- `aapt2 dump badging` on the APK reports `versionCode='5'` / `versionName='2.0.1'`.
- The قلم art and the teal `ic_launcher_background` are proven present INSIDE the AAB.
- Both artifacts on the Desktop with recorded sha256 checksums, built from one commit on `release/2.0.1`.
</verification>

<success_criteria>
The installed app's launcher icon is the same قلم-on-teal art as the Play listing icon — removing
the icon mismatch that caused the 2026-07-27 misleading-claims rejection — shipped as a signed
2.0.1+5 AAB with its matching webcourse APK twin, both built from one commit with no dart-defines
and verified with aapt2. The Play Console upload remains owner-only.
</success_criteria>

<output>
Create `.planning/quick/260727-pwj-launcher-icon-claude-design-on-teal-to-m/260727-pwj-SUMMARY.md` when done.
</output>
