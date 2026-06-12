---
phase: quick
plan: 260612-pmt
type: execute
wave: 1
depends_on: []
files_modified:
  - android/app/build.gradle.kts
  - android/app/src/main/kotlin/com/example/qalam/MainActivity.kt
  - android/app/src/main/kotlin/com/technion/qalam/MainActivity.kt
autonomous: true
requirements: [SPRINT1-PKG]

must_haves:
  truths:
    - "App builds with applicationId com.technion.qalam"
    - "MainActivity resolves at the new package path"
    - "No references to com.example.qalam remain in android/"
  artifacts:
    - path: "android/app/build.gradle.kts"
      provides: "namespace + applicationId = com.technion.qalam"
      contains: "com.technion.qalam"
    - path: "android/app/src/main/kotlin/com/technion/qalam/MainActivity.kt"
      provides: "MainActivity in new package"
      contains: "package com.technion.qalam"
  key_links:
    - from: "android/app/build.gradle.kts namespace"
      to: "android/app/src/main/AndroidManifest.xml .MainActivity"
      via: "relative activity name resolves against namespace"
      pattern: "com\\.technion\\.qalam"
---

<objective>
Rename the Android package from `com.example.qalam` to `com.technion.qalam` to satisfy the Technion Sprint 1 submission requirement that the package name start with `com.technion.`.

Purpose: Sprint 1 submission gate — the grader requires a `com.technion.` package.
Output: Updated Gradle config, MainActivity relocated to the new package directory, app still builds.
</objective>

<execution_context>
@/Users/mareekhalila/Documents/Qalam/qalam/.claude/get-shit-done/workflows/execute-plan.md
@/Users/mareekhalila/Documents/Qalam/qalam/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@./CLAUDE.md

# Current state (already verified during planning):
# - android/app/build.gradle.kts line 9:  namespace = "com.example.qalam"
# - android/app/build.gradle.kts line 24: applicationId = "com.example.qalam"
# - MainActivity.kt at android/app/src/main/kotlin/com/example/qalam/MainActivity.kt
#   (line 1: package com.example.qalam)
# - AndroidManifest.xml uses android:name=".MainActivity" (RELATIVE — resolves against
#   namespace, so NO manifest edit is required once namespace changes)
# - No Firebase / google-services.json wired up (v1 is local-only)
# - Only the STRUCTURE.md doc mentions com.example.qalam as an example — NOT load-bearing,
#   leave it untouched
</context>

<tasks>

<task type="auto">
  <name>Task 1: Update Gradle namespace + applicationId and relocate MainActivity</name>
  <files>android/app/build.gradle.kts, android/app/src/main/kotlin/com/technion/qalam/MainActivity.kt, android/app/src/main/kotlin/com/example/qalam/MainActivity.kt</files>
  <action>
    Perform a manual rename (do NOT add the change_app_package_name dev dependency — it
    leaves a residual Dart package for a one-time operation, and only 3 edits are needed):

    1. In android/app/build.gradle.kts, change `namespace = "com.example.qalam"` (line 9)
       to `namespace = "com.technion.qalam"`, and `applicationId = "com.example.qalam"`
       (line 24) to `applicationId = "com.technion.qalam"`.
    2. Create the new package directory android/app/src/main/kotlin/com/technion/qalam/
       and write MainActivity.kt there with first line `package com.technion.qalam`
       (keep the rest identical: imports io.flutter.embedding.android.FlutterActivity,
       class MainActivity : FlutterActivity()).
    3. Delete the old file android/app/src/main/kotlin/com/example/qalam/MainActivity.kt
       and remove the now-empty com/example/qalam and com/example directories.
    4. Do NOT edit AndroidManifest.xml — it uses the relative `.MainActivity` name which
       resolves against the new namespace automatically.
  </action>
  <verify>
    <automated>cd android/app/src/main/kotlin && test -f com/technion/qalam/MainActivity.kt && ! test -e com/example && grep -q 'package com.technion.qalam' com/technion/qalam/MainActivity.kt && cd ../../../.. && grep -c 'com.technion.qalam' build.gradle.kts | grep -qx 2 && ! grep -q 'com.example.qalam' build.gradle.kts</automated>
  </verify>
  <done>build.gradle.kts has namespace and applicationId both set to com.technion.qalam; MainActivity.kt exists only under com/technion/qalam with the matching package declaration; no com/example path remains.</done>
</task>

<task type="auto">
  <name>Task 2: Verify the app builds with the new package</name>
  <files>(no edits — build verification only)</files>
  <action>
    From the repo root, prove the rename did not break the build. Run a debug APK build:
    `flutter build apk --debug`. This compiles Kotlin against the new namespace and merges
    the manifest. If `flutter build apk` is unavailable in the environment (no Android SDK /
    long build), fall back to: run `flutter analyze` (must pass) AND inspect the merged
    manifest by running `flutter build apk --debug --no-tree-shake-icons` or, if no SDK,
    confirm Gradle resolves the package via
    `cd android && ./gradlew :app:processDebugManifest` and check
    android/app/build/intermediates/merged_manifests/debug/AndroidManifest.xml contains
    `package="com.technion.qalam"`. Record which path was used in the SUMMARY.
  </action>
  <verify>
    <automated>flutter build apk --debug</automated>
  </verify>
  <done>flutter build apk --debug succeeds (or the documented fallback: flutter analyze passes AND the merged debug AndroidManifest.xml shows package="com.technion.qalam"). The build produces an APK with the com.technion.qalam application ID.</done>
</task>

</tasks>

<verification>
- `grep -r "com.example.qalam" android/` returns no matches (excluding build/ output).
- build.gradle.kts namespace and applicationId both read `com.technion.qalam`.
- MainActivity.kt lives only at android/app/src/main/kotlin/com/technion/qalam/MainActivity.kt.
- `flutter build apk --debug` completes successfully.
</verification>

<success_criteria>
- Android package renamed to com.technion.qalam (namespace + applicationId).
- MainActivity relocated to the matching Kotlin package directory; old directory removed.
- App builds cleanly with the new package name, proving the Sprint 1 submission requirement is met.
</success_criteria>

<output>
Create `.planning/quick/260612-pmt-rename-android-package-from-com-example-/260612-pmt-SUMMARY.md` when done.
</output>
