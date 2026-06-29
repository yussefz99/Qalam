---
quick_id: 260629-nle
slug: add-ios-firebaseoptions-block-so-app-boo
date: 2026-06-29
type: quick
---

# Quick Task 260629-nle: Add iOS FirebaseOptions block so app boots on iPad

## Objective

`lib/firebase_options.dart` was generated Android-only — its `TargetPlatform.iOS`
branch threw `UnsupportedError`, so `Firebase.initializeApp(options:
DefaultFirebaseOptions.currentPlatform)` in `lib/main.dart` crashes the app at launch
on iOS. The native `ios/Runner/GoogleService-Info.plist` (Firebase iOS app
`com.technion.qalam`, project `qalam-app-bd7d0`) already exists; only the Dart options
were missing the iOS block.

Authorized iOS-enabling work — the owner explicitly asked to run on the iPad for
demo/testing (a scoped extension of the Android-only "Decided" rule, recorded in
STATE, not a full iOS port).

## Task

1. In `DefaultFirebaseOptions.currentPlatform`, replace the `TargetPlatform.iOS`
   `throw UnsupportedError(...)` branch with `return ios;`.
2. Add a `static const FirebaseOptions ios` block mirroring `android`, with the values
   from `ios/Runner/GoogleService-Info.plist`:
   - apiKey `AIzaSyCkYCq_Dnt8LhnPtuOovfswxuXKHipAu8Q`
   - appId `1:718707208086:ios:b67818983d8940f1dbb7b7`
   - messagingSenderId `718707208086`
   - projectId `qalam-app-bd7d0`
   - storageBucket `qalam-app-bd7d0.firebasestorage.app`
   - iosBundleId `com.technion.qalam`

verify: `flutter analyze lib/firebase_options.dart` → No issues found.
done: iOS branch returns the `ios` options; the app no longer crashes Firebase init on
iPad. (Full on-device boot still depends on Xcode signing + a connected iPad — outside
this task.)
