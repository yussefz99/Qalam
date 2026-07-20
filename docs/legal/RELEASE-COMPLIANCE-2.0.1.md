# Qalam 2.0.1 — Release Compliance Declarations (account-first)

**Purpose.** Qalam's entry model is **account-first** (D-01/D-02, Phase 26): a parent
account is the mandatory front door. This document holds the **exact wording** to
transcribe into the Google Play Console and the hosted privacy/legal page so all three
surfaces match the shipped code **word-for-word** (Success Criterion 1, D-03).

**Authored from the code** — every claim below mirrors:
- `lib/services/auth_service.dart` — parent Email/Password (`signUpWithEmail` /
  `signInWithEmail`) + Google **parent** sign-in (`google_sign_in`); the boot anonymous
  identity is linked on sign-up (D-09c). Children never authenticate (D-09b).
- Firestore posture — **zero child-PII collection surface** (no child-data write path);
  the tutor payloads carry curriculum ids + stroke geometry only, never child identity.
- No cross-device **sync** (future scope; the account gates use but does not sync data).

> Do NOT declare data the app does not collect, and do NOT omit the parent email it does.
> If any Play field forces wording that must differ from this text, record the difference
> back here so the artifact and the published surface stay reconciled.

---

## 1. Play Console → App content → Data safety

**Does your app collect or share any of the required user data types?** — **Yes** (collects; does **not** share).

**Data collected (parent only, for account management + authentication):**

| Data type | Collected | Shared | Purpose | Processing |
|---|---|---|---|---|
| **Email address** (parent) | Yes | No | Account management, Authentication | Required; collected when a parent creates or signs in to an account (Email/Password or Google). |
| **User IDs** (parent account/auth identifier) | Yes | No | Account management, Authentication | The Firebase Auth UID for the parent account. |

**Data NOT collected (declare none):**
- **No child personal information** of any kind — no name, email, photo, contacts,
  location, or identifiers tied to a child. Children do not have accounts and never sign in.
- No approximate/precise location, no contacts, no messages, no financial info, no health
  data, no browsing history, no ads/marketing identifiers.
- **Handwriting stroke data** is processed **on-device** for scoring and is not collected
  as personal data (not tied to a child identity, not uploaded as a personal-data record).

**Security practices:**
- **Data is encrypted in transit** — **Yes**.
- **Users can request data deletion** — **Yes** (parent can delete the account; sign-out
  returns to an anonymous local identity).
- **Data is NOT shared with third parties.**
- Data collection is **required** to use the app (account-gated) — this is stated in
  App access below.

**Committed to Play Families / child-directed policy:** the app is designed for children;
**no child PII is collected**; the only account is the **parent's**.

---

## 2. Play Console → App content → App access

**All or some functionality is restricted** — **Yes, login required.**

Declaration text:

> Qalam requires a **parent account** to use the app. On first launch the app opens to a
> sign-in / sign-up screen (`/auth`); the child's learning experience is available only
> after a parent signs in (Email/Password or Google) and completes child setup. Children
> do not have their own logins — the parent account is the single front door.

**Reviewer test credentials (provide in the App access form):**

| Field | Value |
|---|---|
| Email | `<owner: create/enter a reviewer test parent account email>` |
| Password | `<owner: enter its password>` |
| Notes for reviewer | "Sign in with these credentials; complete the one-step child setup; the letter-tracing lessons are then reachable from Home." |

> **Owner action:** create a durable reviewer test account (do not use a personal
> account), enter it here and in the Play form, and keep it valid through review.

---

## 3. Hosted privacy / legal page (publish matching wording)

Publish (or update) the app's privacy page with wording consistent with the above:

> **Accounts.** Qalam requires a **parent account** (email + password, or Google sign-in)
> to use the app. The parent account is the only account — **children do not have accounts
> and never sign in**.
>
> **What we collect.** From the **parent**: an email address and an account identifier,
> used solely to create and secure the account and to sign in. That is all.
>
> **What we do not collect.** We do **not** collect any personal information about a child
> — no name, photo, location, contacts, or child identifiers. A child's handwriting is
> processed **on the device** to give feedback and is not uploaded as personal data.
>
> **Sharing & sync.** We do **not** share your data with third parties, and account data
> is **not** synced across devices. Data is encrypted in transit.
>
> **Your control.** A parent can delete the account at any time; signing out returns the
> app to an anonymous local session. Children's data is minimized by design and kept
> private by default under parent control.

---

## Owner checklist (Task 3 — 26-05)

- [ ] Play Console → Data safety: enter Section 1 exactly (parent email + user ID collected; nothing else; not shared; not synced; encrypted in transit; deletion available).
- [ ] Play Console → App access: select "login required", paste Section 2, add the reviewer test credentials.
- [ ] Publish the hosted privacy/legal page with Section 3 wording.
- [ ] Confirm each surface reads word-for-word as above; report any forced wording differences back here.

*Authored 2026-07-20 (Phase 26, Plan 26-05, D-03). Source of truth: the account-first code (D-01/D-02).*
