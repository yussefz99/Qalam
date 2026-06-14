# Firestore Security Rules — Verification Checklist

**Target project:** `qalam-app-bd7d0` (Firestore Native, me-west1)
**Rules file:** [`firestore.rules`](../../firestore.rules)
**Deploy command:** `firebase deploy --only firestore:rules --project qalam-app-bd7d0`

> **Why this is a manual/server check.** Firestore security rules are
> **server-enforced**. The Dart test suite uses `fake_cloud_firestore`, which
> does **not** evaluate rules — so the only faithful verification is against the
> deployed rules in the **Firebase Console Rules Playground** (or the Firestore
> emulator). This file documents the exact, repeatable steps and expected
> outcomes. (Decision D-10, VALIDATION §Justified Manual-Only Items.)

---

## What the rules must enforce (acceptance)

| # | Behavior | Expected |
|---|----------|----------|
| 1 | Read `/letters/alif` with **Authentication ON** (anonymous) | **ALLOWED** |
| 2 | Read `/letters/alif` with **Authentication OFF** (unauthenticated) | **DENIED** |
| 3 | Write (set) `/letters/alif` with **Authentication ON** | **DENIED** |
| 4 | Read a non-curriculum path `/secret/x` with **Authentication ON** | **DENIED** (deny-by-default catch-all) |
| 5 | Deployed Rules tab matches `firestore.rules`; **no child-data collection** is referenced (D-11) | **CONFIRMED** |

The same expectations hold for `/lessons/{id}` and `/meta/{doc}` (identical rule
block): authed read ALLOWED, unauthed read DENIED, any client write DENIED.

---

## How to run the checks (Firebase Console Rules Playground)

Location: **Firebase Console → `qalam-app-bd7d0` → Firestore Database → Rules → Rules Playground** (run against the **deployed** rules).

### Check 1 — Authed read is ALLOWED
1. Simulation type: **get**
2. Location: `/letters/alif`
3. **Authenticated:** ON. Provider: **Anonymous** (or any provider — only `request.auth != null` is required; no specific claims).
4. Run → expect **Allowed** (green).

### Check 2 — Unauthed read is DENIED
1. Simulation type: **get**
2. Location: `/letters/alif`
3. **Authenticated:** OFF.
4. Run → expect **Denied** (red). `request.auth` is null, so `request.auth != null` is false.

### Check 3 — Authed write is DENIED
1. Simulation type: **create** (or **update**)
2. Location: `/letters/alif`
3. **Authenticated:** ON (Anonymous).
4. Provide any document fields.
5. Run → expect **Denied** (red). `allow write: if false` denies all client writes; content is written only via the admin-SDK tooling (Plan 03), which bypasses rules.

### Check 4 — Catch-all denies a non-curriculum path
1. Simulation type: **get**
2. Location: `/secret/x` (any path outside letters/lessons/meta)
3. **Authenticated:** ON (Anonymous).
4. Run → expect **Denied** (red). The deny-by-default `match /{document=**}` catch-all blocks every unlisted path — including any future/accidental child-data path (D-11).

### Check 5 — Deployed rules + no child-data surface
1. Open the **Rules** tab and confirm the live text matches `firestore.rules` in this repo.
2. Confirm there is **no** collection match for child profile / progress / stroke data — only `letters`, `lessons`, `meta`, and the deny-by-default catch-all (D-11: zero child PII surface in Firestore).

---

## Optional: Firestore emulator (CI-able alternative)

If running rules unit tests locally instead of the console:
```bash
firebase emulators:start --only firestore --project qalam-app-bd7d0
# Then use @firebase/rules-unit-testing (or the console Playground) to assert the 5 checks above.
```
The emulator evaluates the same `firestore.rules`, so the expected outcomes are identical.

---

## Status

- **Deploy:** `firebase deploy --only firestore:rules --project qalam-app-bd7d0` — see SUMMARY for the result of this execution.
- **Playground checks 1–5:** **PENDING HUMAN VERIFICATION.** These are server-side
  console actions the owner runs once against the deployed rules; record results
  inline here (e.g. `1 ✅ / 2 ✅ / 3 ✅ / 4 ✅ / 5 ✅`) after the manual pass.
