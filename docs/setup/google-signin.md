# Google parent sign-in — setup runbook

The code path is ready: `AuthService.signInWithGoogle()` signs in (or links the
boot anonymous identity) with Google, using a **Web client id** injected at build
time via `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`. Until that value is set the
"Continue with Google" button degrades gracefully with a friendly message — no
crash. Email/Password parent sign-in already works without any of this.

These are the **one-time console steps** that make Google sign-in actually work on
Android. They are manual (a human with console access must do them).

Project: `qalam-app-bd7d0`.

---

## 1. Add the Android debug SHA-1 to Firebase

Firebase → Project settings → **Your apps** → the Android app → **Add fingerprint**.

Paste the **debug** SHA-1 (the signature of the standard Android debug keystore on
this machine):

```
28:08:05:3D:44:0B:B8:56:BD:1E:A3:2F:25:47:18:94:96:AB:F8:18
```

> Re-fetch any time with:
> ```
> keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" \
>   -alias androiddebugkey -storepass android -keypass android
> ```
> A **release** build needs its own SHA-1 from the release keystore — add that too
> when you ship.

## 2. Enable the Google sign-in provider

Firebase → **Authentication** → Sign-in method → **Google** → Enable → Save.
(Email/Password is already enabled.)

## 3. Re-download google-services.json

After steps 1–2, Firebase regenerates the config with an OAuth web client.
Download the fresh **google-services.json** and replace `android/app/google-services.json`.

Verify it now contains a web client (this is currently EMPTY — that's expected
until the steps above are done):

```
grep -A2 '"client_type": 3' android/app/google-services.json
```

The `"client_id"` on that `client_type: 3` entry (ends in
`...apps.googleusercontent.com`) is the **Web client id** you pass below.

## 4. Run with the Web client id

```
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web_client_id>.apps.googleusercontent.com
```

For release builds, pass the same `--dart-define` to `flutter build apk`.

> Tip: to avoid retyping, you can keep it in a gitignored file and run with
> `--dart-define-from-file=dart_defines.json` (`{ "GOOGLE_SERVER_CLIENT_ID": "..." }`).

---

## Checklist

- [ ] Debug SHA-1 added to Firebase
- [ ] (later) Release SHA-1 added to Firebase
- [ ] Google provider enabled in Authentication
- [ ] Fresh google-services.json committed (has a `client_type: 3` entry)
- [ ] `GOOGLE_SERVER_CLIENT_ID` passed at run/build time
- [ ] Verified on device: "Continue with Google" signs in / links the account
