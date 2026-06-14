# Phase 9: Parent Dashboard - Research

**Researched:** 2026-06-13
**Domain:** Local PIN gate (on-device auth) + read-only aggregate-progress view in Flutter/Drift/Riverpod
**Confidence:** HIGH (data layer & patterns — all in-repo and verified), MEDIUM (PIN crypto package choice — verified on pub.dev, recommendation is a judgement call documented below)

## Summary

Phase 9 is a thin, self-contained slice: unlock the existing locked Home "Parent" nav entry, gate a new `/parent` route behind a 4-digit PIN (create-on-first-access, enter-on-every-entry), and render a **read-only** view of the child's letter progress sourced entirely from the existing Drift tables (`LetterMastery` = mastered, `LetterReps` = in-progress). No cloud, no account, no network — consistent with every prior phase.

The two genuinely new pieces are (1) **secure local PIN storage** and (2) **a brute-force cooldown**. Everything else reuses established repo patterns: a hand-written Riverpod `FutureProvider`/`AsyncNotifier` over Drift accessors (because riverpod_generator 4.0.3 throws on Drift-typed functional providers — a documented repo rule), a new top-level screen modeled on `settings_screen.dart`, a synchronous go_router redirect guard modeled on the existing onboarding gate, and ARB-only copy with design-system tokens.

The honest threat-model framing matters here: a 4-digit PIN has only 10,000 combinations and the asset it protects is *low value* (a single child's letter-mastery counts, already stored unencrypted on-device). The realistic adversary is **the child**, not a remote attacker or a forensic device extraction. This bounds the crypto: a salted slow-ish hash plus a *persisted* (not in-memory) attempt cooldown is proportionate and correct. Over-engineering (Argon2id, hardware-backed Keystore) is not warranted but the cooldown MUST survive app restart or it is trivially bypassed by force-quit.

**Primary recommendation:** Store the PIN as a **salted PBKDF2-HMAC-SHA256 hash** (random per-install salt, ≥100k iterations) in the existing `AppSettings` key/value table (keys `parentPinHash`, `parentPinSalt`, plus `parentPinFailCount` / `parentPinLockUntil` for the **persisted** cooldown). Use the **`crypto` package** (pub.dev, raw SHA-256/HMAC) plus a tiny pure-Dart PBKDF2 loop, OR add **`cryptography` ^2.9.0** for a ready Pbkdf2 — both are acceptable; `crypto` adds less surface. Do NOT add `flutter_secure_storage` for a hash (it protects secrets you must *recover*; a one-way PIN hash gains little from it and adds a platform-channel dependency). Build the PIN entry from a plain obscured numeric field — `pinput` is optional polish, not required.

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Parent creates a **4-digit PIN on first access** (enter + confirm). First tap = "create PIN"; later taps = "enter PIN".
- **D-02:** **No cloud/account recovery.** Forgotten PIN can only be reset by clearing app data (which wipes child profile + progress). State this honestly in PIN-creation copy.
- **D-03:** Layout = a **top summary line** ("N of 28 letters mastered") above a **scrollable per-letter list**; each row = letter + mastered ✓/in-progress + clean-reps count + mastered date (when applicable).
- **D-04:** **Empty state** = calm "No lessons completed yet." — never an error or empty void.
- **D-05:** **"Score" = clean-reps count + mastered/in-progress status** read from `LetterMastery` (passed) and `LetterReps` (in-progress). There is **NO 0–100 score** — do NOT invent one.
- **D-06:** Wire the **existing locked Home nav-rail "Parent" entry** → PIN prompt → full-screen dashboard. Remove the "Coming soon" lock/sublabel.
- **D-07:** PIN prompted on **every entry** (no session-long unlock). A clear "Done"/back returns to child Home. Reads as a distinct adult space (calm, no child-game chrome).
- **D-08:** **4-digit PIN.** After ~5 wrong attempts, a **short cooldown** (~30s) before more tries. No permanent lockout.

### Claude's Discretion
- **PIN storage:** MUST be **hashed + salted, never plaintext**, and **never logged**. `AppSettings` key/value table is a candidate store (e.g., `parentPinHash`). Exact hashing approach is the planner's / security-auditor's call.
- The dashboard is strictly **read-only** — must expose no edit/delete of progress.

### Deferred Ideas (OUT OF SCOPE)
- **S2-06** — parent sees specific struggle topics/letters (stretch).
- **S2-10** — weekly progress report (stretch).
- **S2-07** — parent sets a daily practice-duration goal (stretch).
- **Multi-child profiles** — v1 is single-profile (Phase 5); multi-child is future.
- **Editing/resetting individual progress from the dashboard** — out of scope; read-only.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| S1-11 | A parent can see the child's completed lessons and scores (PIN-gated parent area; read-only local progress; no cloud, no account). | PIN gate via salted PBKDF2 hash in `AppSettings` + persisted cooldown (Standard Stack, Pattern 1–3); read-only aggregate view via new Drift accessors over `LetterMastery`/`LetterReps` composed with `curriculumRepository.getLetters()` for the "N of 28" denominator (Architecture §Read-only progress; Pattern 4). |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PIN create/verify (hash, salt, compare) | Local data/security (pure-Dart service over Drift) | — | No network exists; must be on-device, never client-of-a-server. Hash compare is pure-Dart logic, testable without a widget. |
| Brute-force cooldown (count, lock-until) | Local data/storage (`AppSettings`) | Riverpod state | MUST persist across restart (a child force-quits to reset in-memory state). The authoritative counter lives in Drift; Riverpod just reflects it. |
| Route gating (`/parent` access control) | Router (go_router redirect) | Riverpod (`parentUnlocked` flag) | Mirrors the existing onboarding gate (synchronous redirect + refreshListenable). Per-entry unlock = the flag resets on exit. |
| Read aggregate progress | Local data (Drift accessors) | Riverpod providers | Reuses `LetterMastery`/`LetterReps`; new read-only list accessors. Curriculum repo supplies the 28-letter denominator/order. |
| Dashboard rendering | UI (new `/parent` screen) | — | New top-level screen modeled on `settings_screen.dart`; design-system tokens, ARB copy, PLAT-03 (no gamification). |

## Standard Stack

### Core (already in repo — reuse, do not re-add)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_riverpod` / `riverpod_annotation` | ^3.3.1 / ^4.0.2 | State, providers over Drift | Riverpod-only (CLAUDE.md / D-11). [CITED: pubspec.yaml] |
| `drift` + `sqlite3_flutter_libs` | ^2.31.0 / ^0.5.41 | Local SQLite persistence | All progress + `AppSettings` already here. **Keep `sqlite3_flutter_libs` on the 0.5.x line** — 0.6.0+eol is an empty tombstone that crashes on device (STATE.md). [CITED: pubspec.yaml + STATE.md] |
| `go_router` | ^17.2.3 | Declarative routing + redirect guard | Onboarding gate uses the same pattern. [CITED: pubspec.yaml] |
| `flutter_localizations` (gen-l10n) | sdk | All copy via ARB | D-07 convention. [CITED: pubspec.yaml] |

### Supporting (NEW — one small dependency at most)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `crypto` | 3.0.7 (pub.dev, published ~Nov 2025) | SHA-256 + HMAC primitives | **Recommended.** Implement PBKDF2 as a short pure-Dart HMAC-SHA256 loop over this. Smallest new surface; pure-Dart; no platform channel. Note: `crypto` has **no built-in PBKDF2/KDF** — only raw hashes/HMAC. [VERIFIED: pub.dev — confirmed no KDF, only SHA/HMAC] |
| `cryptography` | ^2.9.0 (pub.dev, ~Dec 2025) | Ready-made `Pbkdf2` (and Argon2id) KDF | **Acceptable alternative** if the planner prefers not to hand-roll the PBKDF2 loop. Pure-Dart fallbacks; actively maintained (dint.dev). Slightly larger surface than `crypto`. [VERIFIED: pub.dev — Pbkdf2 + Argon2id confirmed] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `crypto` + PBKDF2-in-`AppSettings` | `flutter_secure_storage` ^10.3.1 (Keystore/Keychain, RSA-OAEP+AES-GCM) | Secure storage is for secrets you must **decrypt and recover** (tokens, keys). A one-way PIN hash never needs recovery, so Keystore buys little here while adding a platform-channel dependency, an API-23 floor (already met), and v10's custom-cipher migration complexity. **Reject for the hash itself.** It *would* be justified only if you stored the PIN reversibly — which you must not. [VERIFIED: pub.dev] |
| Hand-rolled PBKDF2 loop | `cryptography` Pbkdf2 | Hand-roll = zero new deps but you own the iteration loop (small, well-understood). Package = less code to review but one more dependency. Both fine; pick per planner taste. |
| Plain obscured `TextField` (numeric) | `pinput` ^6.0.2 (OTP-style boxes, obscuring) | `pinput` is nicer 4-box UX but adds a dependency for cosmetic gain. A numeric obscured field with `maxLength:4` is sufficient for MVP. **Optional polish, not required.** [VERIFIED: pub.dev] |
| PBKDF2 | Argon2id | Argon2id is the modern password-hashing gold standard, but for a 4-digit PIN protecting low-value local data with a *persisted cooldown* already throttling guesses, PBKDF2 (≥100k iters) is proportionate. Argon2id is available via `cryptography` if the security-auditor insists; document the threat-accepted choice either way. |

**Installation (recommended path):**
```bash
flutter pub add crypto
# (PBKDF2 implemented as a small pure-Dart HMAC-SHA256 loop in a PinHasher service)
```
or, if using the package KDF:
```bash
flutter pub add cryptography
```

**Version verification:** pub.dev is not on npm; versions confirmed via pub.dev package pages (see Sources). `crypto` 3.0.7, `cryptography` 2.9.0, `flutter_secure_storage` 10.3.1, `pinput` 6.0.2 all verified live this session.

## Package Legitimacy Audit

> slopcheck targets npm/PyPI; these are pub.dev (Dart) packages. Verification done by reading the official pub.dev page for each: publisher, version, popularity, and likes.

| Package | Registry | Age / Version | Popularity | Source / Publisher | Verdict | Disposition |
|---------|----------|---------------|------------|--------------------|---------|-------------|
| `crypto` | pub.dev | 3.0.7 (~7 mo) | dart.dev first-party | dart.dev (Dart team) | OK | **Approved** (recommended) |
| `cryptography` | pub.dev | 2.9.0 (~6 mo) | verified publisher | dint.dev, GitHub CI | OK | Approved (alternative) |
| `flutter_secure_storage` | pub.dev | 10.3.1 (~17 days) | 4.4k likes, 2.94M dl | juliansteenbakker (well-known) | OK | **Not recommended for this phase** (see Alternatives) |
| `pinput` | pub.dev | 6.0.2 (~4 mo) | 3.47k likes, 519k dl | Tornike (well-known) | OK | Optional polish only |

**Packages removed due to slop verdict:** none.
**Packages flagged suspicious:** none. All four are first-party or widely-adopted, verified-publisher pub.dev packages.

## Architecture Patterns

### System Architecture Diagram

```
Home nav-rail "Parent" tap (D-06)
        │  context.go('/parent')   ← unlock the existing inert _NavItem
        ▼
go_router redirect guard  (Pattern 3)
        │  parentUnlocked == false ?
        ├── PIN not yet created ──────────► /parent  → PIN CREATE screen (enter+confirm, honest no-recovery copy, D-01/D-02)
        │                                        │ on confirm: PinService.setPin() → AppSettings(parentPinHash, parentPinSalt)
        │                                        │ sets parentUnlocked = true
        │                                        ▼
        ├── PIN exists, locked ───────────► /parent  → PIN ENTER screen
        │                                        │ cooldown check: AppSettings(parentPinLockUntil) vs now (Pattern 2, persisted)
        │                                        │ verify: PinService.verify(entered) — PBKDF2 compare, constant-time
        │                                        │   ├ wrong → failCount++ ; if ≥5 → lockUntil = now+30s ; show cooldown
        │                                        │   └ right → reset failCount/lockUntil ; parentUnlocked = true
        │                                        ▼
        └── parentUnlocked == true ───────► DASHBOARD (read-only)
                                                 │  reads (Pattern 4):
                                                 │   • masteredLettersDetail  ← LetterMastery (id, cleanReps, masteredAt)
                                                 │   • inProgressLettersDetail ← LetterReps (id, cleanReps, updatedAt) minus mastered
                                                 │   • curriculumRepository.getLetters() → 28-letter set + intro order + display names
                                                 │  composes: "N of 28 mastered" summary + per-letter rows (D-03)
                                                 │  empty state if both empty (D-04)
                                                 ▼
                                          "Done" → context.go('/')  AND  parentUnlocked = false  (per-entry, D-07)
```

The PIN never leaves the device; there is no server, no client-of-server, no network call anywhere in this flow (S1-11, PLAT-01-aligned).

### Recommended Project Structure
```
lib/
├── features/parent/
│   ├── pin_service.dart          # pure-Dart: hash/salt/verify/setPin (no widgets) — unit-testable
│   ├── parent_pin_gate.dart      # PIN create + enter screens (obscured numeric, no leak)
│   ├── parent_dashboard_screen.dart  # read-only summary line + per-letter list (D-03/D-04)
│   └── parent_progress.dart      # immutable view model: ParentLetterRow { id, displayName, status, cleanReps, masteredAt? }
├── providers/
│   └── parent_providers.dart     # parentUnlocked notifier + parentProgressProvider + pinStateProvider (hand-written, Drift-typed)
└── data/app_database.dart        # ADD read-only accessors (see Pattern 4) — no new tables needed
```
No new Drift **table** is required — `AppSettings` (k/v) holds the PIN material and cooldown state, and the progress tables already exist. **No schema-version bump.** (This avoids a migration entirely — a meaningful simplification.)

### Pattern 1: Salted PBKDF2 PIN hash in AppSettings (recommended)
**What:** On create, generate a random salt, derive `PBKDF2-HMAC-SHA256(pin, salt, iterations≥100000)`, store base64 hash + salt + iteration count in `AppSettings`. On verify, re-derive with the stored salt/iterations and compare in constant time.
**When to use:** This phase — proportionate to a 4-digit PIN over low-value local data.
**Example (with the `crypto` package + small KDF loop):**
```dart
// Source: crypto package SHA-256/HMAC (pub.dev/packages/crypto) + RFC 2898 PBKDF2.
// SECURITY: pin/salt/hash are NEVER logged (repo no-log convention, T-05-01 style).
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class PinService {
  static const _iterations = 100000;          // proportionate for a local 4-digit PIN
  static const _keyHash = 'parentPinHash';
  static const _keySalt = 'parentPinSalt';

  Uint8List _pbkdf2(String pin, Uint8List salt) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    // single 32-byte block (dkLen == hLen) — sufficient for a stored verifier.
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final out = Uint8List.fromList(u);
    for (var i = 1; i < _iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) out[j] ^= u[j];
    }
    return out;
  }

  Future<void> setPin(AppDatabase db, String pin) async {
    final salt = Uint8List.fromList(
        List<int>.generate(16, (_) => Random.secure().nextInt(256)));
    final hash = _pbkdf2(pin, salt);
    await db.setSetting(_keySalt, base64Encode(salt));
    await db.setSetting(_keyHash, base64Encode(hash));
  }

  Future<bool> verify(AppDatabase db, String pin) async {
    final saltB64 = await db.getSetting(_keySalt);
    final hashB64 = await db.getSetting(_keyHash);
    if (saltB64 == null || hashB64 == null) return false;
    final got = _pbkdf2(pin, base64Decode(saltB64));
    final want = base64Decode(hashB64);
    // constant-time compare (no early-out on first mismatch).
    if (got.length != want.length) return false;
    var diff = 0;
    for (var i = 0; i < got.length; i++) diff |= got[i] ^ want[i];
    return diff == 0;
  }

  Future<bool> isPinSet(AppDatabase db) async =>
      (await db.getSetting(_keyHash)) != null;
}
```

### Pattern 2: Persisted brute-force cooldown (NOT in-memory)
**What:** Track `parentPinFailCount` and `parentPinLockUntil` (epoch ms) in `AppSettings`. After ≥5 wrong attempts set `lockUntil = now + 30s`. On each enter, if `now < lockUntil`, block and show remaining time.
**When to use:** This phase, D-08.
**Critical:** Persist in Drift, **not** in a Riverpod-only field — a child can force-quit the app to reset any in-memory counter (this is the realistic adversary). The counter must survive restart.
```dart
// SECURITY: stores only an integer count + an epoch ms — no PIN material.
Future<Duration?> remainingCooldown(AppDatabase db) async {
  final until = int.tryParse(await db.getSetting('parentPinLockUntil') ?? '');
  if (until == null) return null;
  final delta = until - DateTime.now().millisecondsSinceEpoch;
  return delta > 0 ? Duration(milliseconds: delta) : null;
}
Future<void> registerFailure(AppDatabase db) async {
  final n = (int.tryParse(await db.getSetting('parentPinFailCount') ?? '0') ?? 0) + 1;
  await db.setSetting('parentPinFailCount', '$n');
  if (n >= 5) {
    final until = DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch;
    await db.setSetting('parentPinLockUntil', '$until');
    await db.setSetting('parentPinFailCount', '0'); // reset window after locking
  }
}
Future<void> registerSuccess(AppDatabase db) async {
  await db.setSetting('parentPinFailCount', '0');
  await db.setSetting('parentPinLockUntil', '0');
}
```

### Pattern 3: go_router redirect guard for the PIN-gated route
**What:** A synchronous redirect that keeps `/parent` reachable only when a `parentUnlocked` flag is true, mirroring the existing **onboarding gate** (`app_router.dart` lines 31–51): a Riverpod-watched listenable used both as `refreshListenable` and the redirect source. The router file already carries a commented seam for exactly this (lines 112–120).
**When to use:** This phase, D-06/D-07.
**Pattern (mirror the onboarding gate exactly):**
- Add a `ParentGate` ChangeNotifier provider (like `OnboardingGate`) holding `unlocked`.
- In `redirect`, if `state.matchedLocation == '/parent'` and `!parentGate.unlocked` → the screen renders the PIN flow itself (simplest), OR redirect to a `/parent/lock` sub-route. **Simplest for MVP: a single `/parent` route whose widget shows PIN-create/PIN-enter/dashboard based on gate + isPinSet state** — no sub-routes, no redirect-loop risk.
- "Done" sets `unlocked = false` and `context.go('/')` (per-entry, D-07).
- **Pitfall (already documented in repo):** the redirect MUST be **synchronous** — never `await` Drift inside `redirect` (app_router.dart line 42 calls this out). Read `isPinSet`/cooldown inside the screen's async build, not in the redirect.

### Pattern 4: Read-only aggregate progress (new Drift accessors)
**What:** Add read-only accessors to `AppDatabase` that return full rows (not just the ID set), then compose with the curriculum letter list for the "N of 28" denominator and display names/order.
**Why new accessors:** existing `watchMasteredLetterIds()` returns only IDs; the dashboard needs `cleanReps` + `masteredAt` per row, and the in-progress rows from `LetterReps`.
```dart
// ADD to AppDatabase (read-only — mirrors existing accessor style; never logs values).
Future<List<LetterMasteryData>> allMastered() =>
    (select(letterMastery)..orderBy([(t) => OrderingTerm(expression: t.masteredAt)])).get();
Future<List<LetterRepData>> allInProgress() =>
    (select(letterReps)..where((t) => t.cleanReps.isBiggerThanValue(0))).get();
```
Then in `parent_providers.dart` (hand-written FutureProvider — Drift types force this, per the repo rule in `profile_providers.dart`/`progression_providers.dart`):
- `final letters = await curriculumRepository.getLetters();` → the **28-letter set, intro order, and display names** (the "N of 28" denominator and row labels).
- `mastered = allMastered()` → status ✓ + cleanReps + masteredAt.
- `inProgress = allInProgress()` minus any id already in `mastered` → status "in progress" + cleanReps (no date).
- Summary: `"${mastered.length} of ${letters.length} letters mastered"`.
- Build an ordered `List<ParentLetterRow>` following the curriculum intro order for stable display.
**Note:** `getLetters()` returns 28 letters but some may be `signedOff:false` placeholders (Phase 7 authors the rest). The denominator is still the full curriculum letter count; confirm whether "28" should count all curriculum letters or only signed-off ones (Open Question 1).

### Anti-Patterns to Avoid
- **In-memory-only attempt counter** — bypassed by force-quit; the cooldown MUST be persisted (Pattern 2). This is the single most important security correctness point in the phase.
- **Storing the PIN reversibly** (encrypted-but-decryptable, or plaintext) — forbidden by Discretion constraint; a one-way salted hash is required, which is *why* `flutter_secure_storage` adds little.
- **`await`-ing Drift inside the go_router `redirect`** — repo-documented pitfall (app_router.dart line 42); causes redirect hangs/loops.
- **Logging the entered PIN, hash, or salt** — repo no-log convention (T-05-01 style); never `print`/`debugPrint` PIN material, even in debug.
- **Re-using a session unlock** — D-07 requires PIN on *every* entry; the gate must reset to locked on exit.
- **Any edit/delete affordance on the dashboard** — read-only is a hard constraint.
- **Gamification chrome** (PLAT-03) — no running totals, no stars-as-score, no "+N", no streaks. "N of 28 mastered" is *information*, presented plainly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SHA-256 / HMAC primitives | Custom SHA implementation | `crypto` package | First-party Dart-team package; never hand-roll the hash function itself. |
| Secure random salt | `Random()` (non-crypto) | `Random.secure()` (dart:math) | `Random()` is predictable; a salt must be unguessable. |
| Constant-time compare | `==` / early-return loop | XOR-accumulate compare (shown in Pattern 1) | Early-out leaks timing; trivial to get right inline. |
| Drift→Riverpod stream binding | New bespoke bridge | The existing `_bindDriftStream` helper (progression_providers.dart) | Already solves the Riverpod-3 StreamProvider-pause pitfall; reuse if you want live updates (progress won't change while the gate is open, so a one-shot FutureProvider is also fine). |
| Curriculum letter set / order / names | Hardcoded 28-letter list | `curriculumRepository.getLetters()` | Single source of truth; already loaded from `assets/curriculum/letters.json`. |
| PIN entry widget | (optional) | plain obscured numeric `TextField` (maxLength 4) or `pinput` | A numeric obscured field is enough for MVP; `pinput` only if 4-box polish is wanted. |

**Key insight:** The only thing genuinely worth hand-writing here is the PBKDF2 *iteration loop* (a dozen lines over `crypto`'s HMAC) and the constant-time compare — both small, well-specified, and avoid a heavier dependency. Everything else is library or existing-repo machinery.

## Runtime State Inventory

> Phase 9 is greenfield-additive (new screen + new `AppSettings` keys + new read accessors). No rename/refactor. This section is included only to confirm there is no hidden runtime state to migrate.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | PIN material lives in the existing `AppSettings` k/v table (new keys `parentPinHash`/`parentPinSalt`/`parentPinFailCount`/`parentPinLockUntil`). Progress already in `LetterMastery`/`LetterReps`. | None — no new table, **no schema-version bump**, no migration. |
| Live service config | None — no external services, no cloud, no network (PLAT-01). | None. |
| OS-registered state | None — no OS registrations, no scheduled tasks. | None. |
| Secrets/env vars | None — there is no API key (the tutor is v2; CLAUDE.md "tutor never runs client-side"). The PIN hash is the only secret-ish value and it stays in app-private Drift. | None. |
| Build artifacts | None new beyond standard Flutter build. If `cryptography` is chosen over `crypto`, `pubspec.lock` updates — normal. | `flutter pub get` after adding the dep. |

**Verified by:** reading `app_database.dart` (schema v4, no `AppSettings` changes needed), `pubspec.yaml`, and `app_router.dart` (the `/parent` seam is commented, not yet built).

## Common Pitfalls

### Pitfall 1: In-memory cooldown bypassed by force-quit
**What goes wrong:** Attempt counter stored only in a Riverpod field resets on app restart, so a child can guess 5 → force-quit → guess 5 more → repeat, defeating the throttle.
**Why it happens:** Riverpod state is process-lifetime; the realistic adversary (the child) controls the process.
**How to avoid:** Persist `failCount` + `lockUntil` in `AppSettings` (Pattern 2); read them on every PIN-enter mount.
**Warning signs:** Test "kill app between attempts" still allows immediate retry.

### Pitfall 2: `await` inside go_router `redirect`
**What goes wrong:** Reading `isPinSet`/cooldown via `await db.getSetting(...)` inside `redirect` hangs or loops the router.
**Why it happens:** go_router's redirect is synchronous; the repo already documents this (app_router.dart line 42, onboarding-gate pitfall).
**How to avoid:** Keep `redirect` synchronous (read a synchronous `parentGate.unlocked` flag). Do the async `isPinSet`/cooldown reads inside the `/parent` screen's `build`/notifier, not the redirect.
**Warning signs:** White screen on `/parent`; router redirect-loop assertions.

### Pitfall 3: riverpod_generator throws on Drift-typed providers
**What goes wrong:** Writing `@riverpod Future<List<LetterMasteryData>> ...` triggers `InvalidTypeException` (riverpod_generator 4.0.3 can't codegen Drift-generated data classes).
**Why it happens:** Documented repo behavior — see `profile_providers.dart` and `progression_providers.dart` notes.
**How to avoid:** Hand-write the parent providers as plain `FutureProvider`/`AsyncNotifier` (no `@riverpod` annotation) whenever the return type touches a Drift data class. Map Drift rows into a plain `ParentLetterRow` view model early if you want codegen elsewhere.
**Warning signs:** build_runner fails with InvalidTypeException.

### Pitfall 4: PIN visible / leaking through the entry field
**What goes wrong:** A non-obscured field, autofill, or logging exposes the PIN.
**How to avoid:** `obscureText: true` (or obscuring widget), `keyboardType: TextInputType.number`, `enableSuggestions:false`, `autocorrect:false`; never log the controller value. If using `pinput`, set `obscureText: true`.
**Warning signs:** PIN digits readable on screen; PIN string in any log.

### Pitfall 5: Wrong "N of 28" denominator
**What goes wrong:** Counting only signed-off letters (currently ~1: alif) makes the summary read "5 of 1", or counting mastered against a hardcoded 28 when curriculum has fewer loaded.
**How to avoid:** Use `curriculumRepository.getLetters().length` as the denominator and resolve the intended semantics with the owner (Open Question 1). Don't hardcode 28.
**Warning signs:** Summary numerator > denominator, or a denominator that isn't 28 in production.

### Pitfall 6: Stale unlock across entries
**What goes wrong:** Forgetting to reset `parentGate.unlocked=false` on "Done" lets the next entry skip the PIN (violates D-07).
**How to avoid:** "Done"/back handler always clears the flag before navigating home; also reset on `dispose` of the dashboard.
**Warning signs:** Second tap on "Parent" lands on the dashboard without a PIN prompt.

## Code Examples

### Reachability: unlock the existing inert "Parent" nav item (home_screen.dart)
```dart
// Source: lib/screens/home_screen.dart lines 128–137 — the locked _NavItem today.
// CHANGE for D-06: drop isLocked/sublabel, wire onTap to /parent, swap lock icon.
_NavItem(
  iconAsset: 'assets/icons/...',          // a non-lock parent/adult icon
  label: l10n?.navParent ?? 'Parent',
  isActive: false,
  isLocked: false,                          // was true
  // sublabel removed (was l10n?.comingSoon)
  onTap: () => context.go('/parent'),       // was null
),
```

### Read-only dashboard view model assembly (parent_providers.dart)
```dart
// Hand-written FutureProvider (Drift types — Pitfall 3). Never logs values.
final parentProgressProvider = FutureProvider<ParentProgress>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final letters = await ref.watch(curriculumRepositoryProvider).getLetters();
  final mastered = {for (final m in await db.allMastered()) m.letterId: m};
  final inProgress = await db.allInProgress();
  final rows = <ParentLetterRow>[];
  for (final l in letters) {                 // curriculum intro order
    final m = mastered[l.id];
    if (m != null) {
      rows.add(ParentLetterRow.mastered(l, m.cleanReps, m.masteredAt));
    } else {
      final ip = inProgress.where((r) => r.letterId == l.id).firstOrNull;
      if (ip != null) rows.add(ParentLetterRow.inProgress(l, ip.cleanReps));
    }
  }
  return ParentProgress(masteredCount: mastered.length,
                        totalLetters: letters.length, rows: rows);
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `flutter_secure_storage` v9 EncryptedSharedPreferences (Jetpack Security) | v10 RSA-OAEP + AES-GCM custom ciphers | v10.0.0 (2025) | Jetpack Security `encryptedSharedPreferences` deprecated; if anyone ever adds secure storage, use v10+. Not needed this phase. [VERIFIED: pub.dev] |
| Plain SHA-256(pin) | Salted slow KDF (PBKDF2/Argon2id) | Long-standing | A bare hash of a 4-digit PIN is instantly rainbow-tableable; salt + iterations is mandatory. PBKDF2 proportionate here. [CITED: standard practice] |

**Deprecated/outdated:**
- `sqlite3_flutter_libs` 0.6.0+eol — empty tombstone; **stay on 0.5.x** (already pinned; STATE.md). Not directly relevant but reaffirmed: do not bump it in this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A 4-digit PIN over local child-progress is a low-value asset whose realistic adversary is the child, so PBKDF2 (≥100k iters) + persisted cooldown is *proportionate* (vs Argon2id / Keystore). | Summary, Standard Stack | If the security-auditor judges the threat higher, upgrade to Argon2id via `cryptography` and/or store the hash via `flutter_secure_storage`. Low risk — both upgrades are drop-in. |
| A2 | The "N of 28" denominator should be `curriculumRepository.getLetters().length`. | Pattern 4, Pitfall 5 | If the owner wants only *signed-off* letters counted, the denominator differs. Resolve before building the summary line (Open Q1). |
| A3 | No schema-version bump is needed (PIN lives in existing `AppSettings`). | Runtime State Inventory | If the planner prefers dedicated typed columns over k/v, a v4→v5 migration would be needed. Reusing `AppSettings` avoids it; recommended. |
| A4 | 100k PBKDF2 iterations is acceptable latency on the target tablet (sub-100ms typical for SHA-256-HMAC). | Pattern 1 | If too slow on the low-end target device, tune iterations down (still ≥10k) — the cooldown is the primary brute-force defense anyway. Verify on device. |

## Open Questions (RESOLVED)

1. **"N of 28" denominator semantics**
   - What we know: `getLetters()` returns the full curriculum letter list (28 intended), but only ~1 (alif) is `signedOff:true` today; Phase 7 authors the rest.
   - What's unclear: Should the summary count against all 28 curriculum letters (likely yes — the journey already shows all 28 nodes) or only signed-off/available ones?
   - Recommendation: Use the full curriculum letter count (28) as the denominator for parent-facing consistency with the journey map; confirm with owner during planning.
   - **RESOLVED:** Use `curriculumRepository.getLetters().length` as the denominator (NOT hardcoded 28) — consistent with the journey map showing all curriculum nodes (planner assumption A-01).

2. **PIN-creation copy wording (D-02 honesty)**
   - What we know: forgetting the PIN means clearing app data (wipes child progress); must be stated honestly.
   - What's unclear: exact child-safe, non-alarming wording in the tutor/brand voice.
   - Recommendation: Draft 1–2 ARB strings for the owner to approve (brand-voice owned by owner per CLAUDE.md); plain, calm, no jargon.
   - **RESOLVED:** UI-SPEC §Copywriting + plan 09-01 ship working ARB drafts (`parentPinNoRecovery` et al.); final wording stays owner-owned (planner assumption A-04).

3. **PIN entry widget: plain field vs `pinput`**
   - Recommendation: Default to a plain obscured numeric field (no new dep) for MVP; offer `pinput` as an optional polish task if the owner wants the 4-box look. Planner's call.
   - **RESOLVED:** Plain obscured numeric field is the MVP implementation (no new UI dependency); `pinput` is optional future polish (planner assumption A-03).

## Environment Availability

> Phase 9 is code + one small Dart dependency; no external runtimes/services/CLIs beyond the existing Flutter/Drift toolchain (already in use across 8 completed phases).

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | ✓ (in active use) | sdk ^3.11.5 | — |
| `crypto` (pub.dev) | PIN hashing | Fetch on `pub add` | 3.0.7 | `cryptography` 2.9.0 (also pub.dev) |
| Drift toolchain / build_runner | providers/accessors | ✓ (in use) | drift ^2.31.0 | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** `crypto` ↔ `cryptography` are interchangeable for the KDF.

## Validation Architecture

> **NOTE (supersedes):** The test file *paths* below were an early draft. The authoritative
> Wave-0 contract is **09-VALIDATION.md**, which places the tests at `test/services/pin_service_test.dart`
> (persisted-cooldown folded in as a sub-case), `test/router/parent_gate_test.dart`,
> `test/screens/parent_dashboard_test.dart`, and extends `test/data/app_database_test.dart`.
> The plans follow VALIDATION.md. The persisted-cooldown-across-restart assertion (the single most
> important security correctness point) is covered inside `pin_service_test.dart`, not a separate file.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (sdk) + `mocktail` ^1.0.5 for fakes (per pubspec) |
| Config file | `test/flutter_test_config.dart` (loads bundled fonts for goldens — exists, Phase 1) |
| Quick run command | `flutter test test/features/parent/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| S1-11 | `PinService.setPin`/`verify` round-trips; wrong PIN fails; hash never equals plaintext | unit (pure-Dart) | `flutter test test/features/parent/pin_service_test.dart` | ❌ Wave 0 |
| S1-11 | Salt is random per install (two `setPin` of same PIN → different stored hash) | unit | same file | ❌ Wave 0 |
| S1-11 | Cooldown: 5 failures sets `lockUntil`; persists across a simulated restart (new AppDatabase over same store) | unit/integration | `flutter test test/features/parent/pin_cooldown_test.dart` | ❌ Wave 0 |
| S1-11 | `/parent` unreachable while locked; reachable after correct PIN; relocks on "Done" (per-entry, D-07) | widget | `flutter test test/features/parent/parent_gate_test.dart` | ❌ Wave 0 |
| S1-11 | Dashboard summary "N of M" + rows match seeded `LetterMastery`/`LetterReps`; empty state when none (D-04) | widget | `flutter test test/features/parent/parent_dashboard_test.dart` | ❌ Wave 0 |
| S1-11 | Dashboard exposes no edit/delete affordance (read-only) | widget | same file | ❌ Wave 0 |
| S1-11 | PIN entry field is obscured + numeric (no leak) | widget | `parent_gate_test.dart` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/parent/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/features/parent/pin_service_test.dart` — hashing/verify/salt-randomness/constant-time (S1-11)
- [ ] `test/features/parent/pin_cooldown_test.dart` — persisted cooldown across simulated restart (reuse the injected in-memory `AppDatabase` "restart" shape from the D-09 test)
- [ ] `test/features/parent/parent_gate_test.dart` — route gate, per-entry relock, obscured field
- [ ] `test/features/parent/parent_dashboard_test.dart` — summary/rows/empty-state/read-only
- [ ] Framework install: none (flutter_test + mocktail already present)

## Security Domain

> `security_enforcement: true`, `security_asvs_level: 1`, `security_block_on: high` (config.json). This phase introduces the app's first authentication surface (a local PIN), so security review is mandatory.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | **yes** | Salted PBKDF2-HMAC-SHA256 verifier (≥100k iters), constant-time compare; throttling via persisted cooldown (V2.2 anti-automation). 4-digit factor is a documented, threat-accepted MVP choice for a low-value local asset. |
| V3 Session Management | partial | "Session" = the per-entry `parentUnlocked` flag; must reset on exit (D-07). No tokens, no remote session. |
| V4 Access Control | **yes** | The go_router redirect guard is the access-control boundary for `/parent`; default-deny (locked) until verified. |
| V5 Input Validation | yes | PIN input restricted to 4 numeric digits; reject non-numeric/oversize input; query params not involved. |
| V6 Cryptography | **yes** | Use `crypto`/`cryptography` (never hand-roll SHA); `Random.secure()` for salt; never store/log plaintext PIN or hash. |
| V7 Error/Logging | **yes** | NEVER log PIN, salt, or hash (repo no-log convention, T-05-01 style); generic "Incorrect PIN" message (no oracle about which digit). |
| V9 Data Protection | yes | Child progress + PIN material stay in app-private Drift storage; no cloud, no network egress (PLAT-01). |

### Known Threat Patterns for {Flutter local PIN over child data}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Child brute-forces 4-digit PIN (10k space) | Spoofing / Elevation | Persisted cooldown after 5 fails (Pattern 2) — survives force-quit; this is the primary defense given the small keyspace. |
| Force-quit to reset attempt counter | Tampering | Counter persisted in Drift, not in-memory (Pitfall 1). |
| PIN read from logs / crash reports | Information Disclosure | Never log PIN/salt/hash; no telemetry/crash-reporting in v1 (T-05-01 style). |
| Rainbow-table a bare SHA(pin) | Information Disclosure | Per-install random salt + ≥100k iterations (Pattern 1). |
| Reversible/recoverable PIN storage | Information Disclosure | One-way hash only; no encrypt-and-store (Discretion constraint). |
| Dashboard used to alter child progress | Tampering | Read-only by construction — no write accessors wired to the parent screen (hard constraint). |
| Timing side-channel on compare | Information Disclosure | Constant-time XOR-accumulate compare (Pattern 1). Low practical risk locally, but trivial to do right. |
| PIN shoulder-surf / on-screen leak | Information Disclosure | Obscured numeric field; no PIN echo (Pitfall 4). |

**Threat-accepted (document explicitly in the plan):** A 4-digit PIN and PBKDF2 (not Argon2id, not Keystore-backed) are intentionally proportionate to a low-value local asset whose adversary is a curious child, not a forensic device-extraction attacker. A determined attacker with root/physical access can read the unencrypted Drift DB regardless — the PIN gate is a *child barrier*, not a device-security boundary, and the product framing (CLAUDE.md child-data minimalism) accepts this.

## Sources

### Primary (HIGH confidence)
- In-repo: `lib/data/app_database.dart` (schema v4, `AppSettings`/`LetterMastery`/`LetterReps` accessors), `lib/router/app_router.dart` (onboarding gate + `/parent` seam), `lib/providers/progression_providers.dart` & `profile_providers.dart` (Drift-typed hand-written provider rule, `_bindDriftStream`), `lib/screens/home_screen.dart` (locked `_NavItem`), `lib/screens/settings_screen.dart` (new-screen pattern), `pubspec.yaml`, `.planning/STATE.md`, `.planning/config.json`.
- pub.dev/packages/crypto — version 3.0.7; SHA family + HMAC; **no built-in KDF** (verified).
- pub.dev/packages/cryptography — version 2.9.0; Pbkdf2 + Argon2id KDFs, pure-Dart, actively maintained.
- pub.dev/packages/flutter_secure_storage — version 10.3.1; v10 RSA-OAEP+AES-GCM, API-23 floor.
- pub.dev/packages/pinput — version 6.0.2; obscurable OTP/PIN field.

### Secondary (MEDIUM confidence)
- LogRocket "Securing local storage in Flutter", LeanCode "Secure Storage in Flutter", Digital.ai — corroborate `flutter_secure_storage` = OS-keystore-backed and PBKDF2(salt, ~1k+ iters) as the standard salted-hash pattern. Used to confirm, not as sole source.

### Tertiary (LOW confidence)
- Misc Medium articles on Flutter PIN security — directional only; not relied upon for any specific claim.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every reused package is in `pubspec.yaml` and in active use; new packages verified live on pub.dev.
- Architecture: HIGH — every pattern mirrors an existing, tested in-repo pattern (onboarding gate, Drift accessors, hand-written providers).
- Pitfalls: HIGH — most are already documented in the repo (Drift-in-redirect, riverpod_generator Drift exception, no-log convention); the cooldown-persistence pitfall is the key novel one.
- PIN crypto choice: MEDIUM — the *proportionality* judgement (PBKDF2 vs Argon2id/Keystore) is a recommendation the security-auditor should ratify (A1).

**Research date:** 2026-06-13
**Valid until:** ~2026-07-13 (stable domain; pub.dev versions may tick but APIs are stable)

## RESEARCH COMPLETE

**Phase:** 9 - Parent Dashboard
**Confidence:** HIGH (data layer & patterns), MEDIUM (PIN-crypto proportionality call)

### Key Findings
- **No new Drift table or schema bump needed** — PIN material + cooldown live in the existing `AppSettings` k/v table; progress already in `LetterMastery`/`LetterReps`. Only read-only accessors + a pure-Dart `PinService` are new.
- **Recommend salted PBKDF2-HMAC-SHA256 (≥100k iters) via the `crypto` package** (smallest surface) over `flutter_secure_storage` — a one-way PIN hash never needs recovery, so Keystore buys little. `cryptography` 2.9.0 is a clean alternative if a packaged KDF is preferred.
- **The cooldown MUST be persisted in Drift, not in-memory** — a child force-quits to reset any in-memory counter (the realistic adversary). This is the single most important security correctness point.
- **Three patterns are already proven in-repo and should be mirrored exactly:** synchronous go_router redirect gate (onboarding gate), hand-written Drift-typed Riverpod providers (riverpod_generator throws otherwise), and the no-log security convention.
- **Honest threat framing:** 4-digit PIN + PBKDF2 is proportionate to a low-value local asset guarded against a curious child — document this as threat-accepted; it is a child barrier, not a device-security boundary.

### File Created
`.planning/phases/09-parent-dashboard/09-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | All reused deps in active use; new deps verified live on pub.dev |
| Architecture | HIGH | Every pattern mirrors an existing tested in-repo pattern |
| Pitfalls | HIGH | Most repo-documented; cooldown-persistence is the key novel one |
| PIN crypto choice | MEDIUM | Proportionality (PBKDF2 vs Argon2id/Keystore) should be ratified by security-auditor |

### Open Questions
- "N of 28" denominator: count all curriculum letters (recommended) vs only signed-off ones — confirm with owner.
- Exact honest PIN-creation copy (no-recovery warning) — owner owns brand voice.
- PIN entry widget: plain obscured numeric field (recommended, no dep) vs `pinput` polish.

### Ready for Planning
Research complete. Planner can create PLAN.md files; security-auditor should ratify the threat-accepted PBKDF2/4-digit choice (A1) during planning.
