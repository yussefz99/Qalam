---
status: complete
quick_id: 260629-nle
date: 2026-06-29
commit: 05109e9
---

# Quick Task 260629-nle — Summary

## What changed

`lib/firebase_options.dart`:
- The `TargetPlatform.iOS` branch now `return ios;` (was `throw UnsupportedError`).
- Added `static const FirebaseOptions ios` mirroring the `android` block, sourced from
  `ios/Runner/GoogleService-Info.plist` (apiKey, appId `…ios:b67818983d…`,
  messagingSenderId 718707208086, projectId qalam-app-bd7d0, storageBucket, iosBundleId
  `com.technion.qalam`).

Net: `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` in
`lib/main.dart` no longer throws on iOS — the Firebase-init crash on iPad launch is
removed.

## Verification

- `flutter analyze lib/firebase_options.dart` → **No issues found.**
- Values cross-checked against `ios/Runner/GoogleService-Info.plist` via PlistBuddy.

## Scope / caveats

- This removes the **Firebase-init** blocker only. A full on-device boot still needs:
  Xcode signing (team for bundle `com.technion.qalam`), a connected iPad with Developer
  Mode on, then `flutter run -d <ipad> --dart-define=DEMO=true --dart-define=TUTOR_BASE_URL=https://qalam-tutor-ogtudswkjq-uc.a.run.app`.
- Authorized iOS-enabling work (owner asked to run on iPad). This is a scoped extension
  of the Android-only "Decided" rule for demo/testing — not a commitment to a full iOS
  port. `flutter_tts` and the rest of the stack are cross-platform; no other iOS-specific
  code was added.

## Self-Check: PASSED
- [x] iOS branch returns `ios`
- [x] `ios` block present with all 6 plist-sourced fields
- [x] analyze clean
- [x] committed atomically (05109e9)
