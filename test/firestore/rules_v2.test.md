# Firestore Security Rules (Schema v2 collections) — Verification Checklist

**Target project:** `qalam-app-bd7d0` (Firestore Native, me-west1)
**Rules file:** [`firestore.rules`](../../firestore.rules)
**Deploy command:** `firebase deploy --only firestore:rules --project qalam-app-bd7d0`
**Scope:** the Phase-07 Schema-v2 collections — `words/{wordId}`,
`exercises/{exerciseId}`, `units/{letterId}`. Mirrors
[`rules.test.md`](./rules.test.md) (the Phase-06.1 letters/lessons/meta checks);
the v2 collections inherit the identical posture (D-10 read-requires-auth +
client-write-denied; D-11 no child-data path).

> **Why this is a manual/server check.** Firestore security rules are
> **server-enforced**. The Dart test suite uses `fake_cloud_firestore`, which
> does **not** evaluate rules — so the only faithful verification is against the
> deployed rules in the **Firebase Console Rules Playground** (or the Firestore
> emulator). This file documents the exact, repeatable steps and expected
> outcomes.

---

## What the v2 rules must enforce (acceptance)

| # | Behavior | Expected |
|---|----------|----------|
| 1 | Read `/exercises/baa.traceLetter.isolated` with **Authentication ON** (anonymous) | **ALLOWED** |
| 2 | Read `/exercises/baa.traceLetter.isolated` with **Authentication OFF** (unauthenticated) | **DENIED** |
| 3 | Write (set/create/update) to `/exercises/{id}`, `/words/{id}`, or `/units/{id}` with **Authentication ON** | **DENIED** (`allow write: if false`) |
| 4 | Read a fictitious child-data path `/children/x` (or `/progress/x`) with **Authentication ON** | **DENIED** (deny-by-default catch-all, D-11) |

The same read/write expectations hold identically for `/words/{wordId}` and
`/units/{letterId}` (the three v2 blocks share one rule body), and remain
unchanged for the existing `/letters`, `/lessons`, `/meta` blocks.

---

## How to run the checks (Firebase Console Rules Playground)

Location: **Firebase Console → `qalam-app-bd7d0` → Firestore Database → Rules → Rules Playground** (run against the **deployed** rules).

### Check 1 — Authed read of an exercises doc is ALLOWED
1. Simulation type: **get**
2. Location: `/exercises/baa.traceLetter.isolated`
3. **Authenticated:** ON. Provider: **Anonymous** (only `request.auth != null` is required; no specific claims).
4. Run → expect **Allowed** (green).

### Check 2 — Unauthed read is DENIED
1. Simulation type: **get**
2. Location: `/exercises/baa.traceLetter.isolated`
3. **Authenticated:** OFF.
4. Run → expect **Denied** (red). `request.auth` is null, so `request.auth != null` is false.

### Check 3 — Authed client write is DENIED (for exercises, words, units)
1. Simulation type: **create** (then repeat with **update**).
2. Location: `/exercises/baa.traceLetter.isolated` — then repeat for `/words/baab` and `/units/baa`.
3. **Authenticated:** ON (Anonymous). Provide any document fields.
4. Run → expect **Denied** (red) for every path. `allow write: if false` denies all client writes; content is written only via the admin-SDK tooling, which bypasses rules.

### Check 4 — Catch-all denies a fictitious child-data path
1. Simulation type: **get**
2. Location: `/children/x` (or `/progress/x` — any path outside letters/lessons/meta/words/exercises/units).
3. **Authenticated:** ON (Anonymous).
4. Run → expect **Denied** (red). The deny-by-default `match /{document=**}` catch-all (which MUST remain the LAST match block) blocks every unlisted path — including any future/accidental child-data path. Child data stays in local Drift only (D-11: zero child PII surface in Firestore).

---

## Status

- **Deploy:** `firebase deploy --only firestore:rules --project qalam-app-bd7d0` — see `07-02-SUMMARY.md` for whether this execution could deploy or it is human-gated on Firebase auth.
- **Playground checks 1–4:** **PENDING HUMAN VERIFICATION.** These are server-side
  console actions the owner runs once against the deployed rules; record results
  inline here (e.g. `1 ✅ / 2 ✅ / 3 ✅ / 4 ✅`) after the manual pass.
