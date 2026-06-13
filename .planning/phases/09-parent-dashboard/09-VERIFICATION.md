---
phase: 09-parent-dashboard
verified: 2026-06-14T00:00:00Z
status: human_needed
score: 7/7 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Nav unlocked — tap the Home 'Parent' nav item on a real Android tablet"
    expected: "Item shows a non-lock icon (ink-drop glyph), no 'Coming soon' text, and navigates to the PIN gate"
    why_human: "SVG asset loading + nav-rail tap flow cannot be verified with flutter_test without a real device; visual fidelity of ink-drop glyph requires screen observation"
  - test: "Create PIN flow — first entry into /parent on a fresh install"
    expected: "Prompts 'Create a PIN', shows the honest no-recovery line, enter + confirm a 4-digit PIN, then unlocks the dashboard"
    why_human: "Multi-step PIN create UI flow (enter + confirm + honest text display) requires interactive testing on device"
  - test: "Per-entry relock — exit via 'Done', re-tap 'Parent'"
    expected: "Re-prompts the PIN on every entry (no session unlock, D-07)"
    why_human: "Round-trip navigation + gate state between app sessions requires device interaction"
  - test: "Persisted cooldown (highest-value check) — enter wrong PIN 5 times, then force-quit the app and reopen"
    expected: "The cooldown countdown is still in effect after force-quit (Drift-persisted, not reset by process kill)"
    why_human: "Force-quit cannot be simulated in flutter_test; only a real device process kill can exercise this path"
  - test: "Read-only dashboard with real progress — enter correct PIN, inspect the dashboard"
    expected: "'N of M letters mastered' summary, per-letter list with mastered/in-progress rows, no edit/delete/reset affordance, no gold/star/streak/mascot chrome (PLAT-03)"
    why_human: "Visual fidelity of the dashboard against the design-kit tokens (parchment bg, soft-aqua rows, ink-teal) requires screen observation"
  - test: "Empty state — re-run with a fresh profile"
    expected: "Calm empty state ('No lessons completed yet.') appears instead of the letter list; no spinner"
    why_human: "Requires device with a fresh data state"
  - test: "Visual fidelity — inspect against docs/design/kit tokens"
    expected: "Parchment background, soft-aqua row surfaces, ink-teal accents only; no gold anywhere in the parent area"
    why_human: "Color token mapping to rendered pixels requires human visual inspection on device"
---

# Phase 9: Parent Dashboard Verification Report

**Phase Goal:** "A parent can enter a PIN to reach a read-only local area showing the child's completed lessons and scores — no cloud, no account."
**Verified:** 2026-06-14
**Status:** human_needed (all automated/code checks pass; deferred device UAT items remain)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | PIN is stored salted+hashed (PBKDF2-HMAC-SHA256, Random.secure, 100k iterations), never plaintext | VERIFIED | `pin_service.dart:46,62-74,80-87`; `_iterations=100000`, `Random.secure()`, XOR-accumulate compare at lines 96-102; no print/debugPrint of PIN/salt/hash in file |
| 2 | Per-install random salt: two identical PINs produce different stored hashes | VERIFIED | `pin_service.dart:80-86` freshly generates a 16-byte `Random.secure()` salt on every `setPin`; `pin_service_test.dart` asserts `firstSalt != secondSalt` and `firstHash != secondHash` — test GREEN |
| 3 | Constant-time verify (no early return) | VERIFIED | `pin_service.dart:97-103`: XOR-accumulate `diff |= got[i] ^ want[i]`, returns `diff == 0` — no early-out |
| 4 | Brute-force cooldown persists across force-quit (Drift-backed, not in-memory) | VERIFIED | `pin_service.dart:117-142`: cooldown stored as epoch-ms in `AppSettings` key `parentPinLockUntil` via `db.setSetting`; test constructs a second `AppDatabase` over the same in-memory executor and asserts `remainingCooldown() > Duration.zero` — GREEN |
| 5 | /parent route default-deny: not reachable while locked; reachable only after correct PIN; relocks on EVERY exit (per-entry, D-07) | VERIFIED | `parent_dashboard_screen.dart:42-50`: access boundary on `parentGateProvider.select((g) => g.unlocked)` — renders `ParentPinGate` when locked; `_DashboardContentState.dispose()` at line 110-118 calls `_gate?.lock()` on every unmount (CR-01 fix confirmed); `_done()` at line 122-126 also calls `lock()` before navigating; `parentGate` default `unlocked=false` (WR-02 fix confirmed at `parent_providers.dart:94`); `main.dart:50` seeds `parentGateProvider.overrideWith((ref) => ParentGate())` (locked); router redirect is synchronous — no `await` in redirect block (`app_router.dart:52-58`); gate tests GREEN |
| 6 | Dashboard is READ-ONLY: no edit/delete/reset affordance; "N of M" denominator parameterized (not hardcoded 28); has an empty state | VERIFIED | `parent_dashboard_screen.dart` contains no `edit`, `delete`, `reset` affordances; `parent_providers.dart:149`: `total: letters.length` (not a literal 28); empty state at `_EmptyState` widget renders `parentEmptyTitle`/`parentEmptyBody`; loading/error both degrade to `_EmptyState` (lines 75-76); no `QalamColors.reward` in file (only a comment); dashboard tests GREEN |
| 7 | No cloud / no account (local-only) | VERIFIED | `pin_service.dart` uses only `AppDatabase.getSetting/setSetting` (Drift, on-device); `parent_providers.dart` reads `allMastered()/allInProgress()` from `appDatabaseProvider` (local Drift); `main.dart` has no Firebase/network imports; no HTTP client, no Firebase call anywhere in the phase's files |

**Score: 7/7 truths verified**

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/parent/pin_service.dart` | Salted PBKDF2 hash/verify + persisted cooldown | VERIFIED | 151 lines; `_iterations=100000`; `Random.secure()`; XOR-accumulate compare; Drift-persisted cooldown; `pinServiceProvider` via `@Riverpod(keepAlive:true)` |
| `lib/features/parent/parent_progress.dart` | Immutable `ParentProgress` + `ParentLetterRow` | VERIFIED | Const constructors; `ParentLetterRow` fields include `glyph` (WR-03 fix); `ParentProgress(mastered, total, rows)` |
| `lib/providers/parent_providers.dart` | `ParentGate` ChangeNotifier + hand-written `parentProgressProvider` | VERIFIED | `ParentGate` with `lock()`/`unlock()`; default `unlocked=false`; `parentProgressProvider` is a hand-written `FutureProvider<ParentProgress>`; re-exports `ParentProgress`/`ParentLetterRow`; `total: letters.length` |
| `lib/features/parent/parent_pin_gate.dart` | PIN create/enter screens | VERIFIED | `ConsumerStatefulWidget`; `_submitting` guard (CR-02); `obscureText:true`; numeric keyboard; `remainingCooldown` re-read before verify (WR-01); `_GateMode` enum; no print/debugPrint of PIN value |
| `lib/screens/parent_dashboard_screen.dart` | Read-only dashboard, access boundary | VERIFIED | `ParentDashboardScreen` watches gate and delegates to `ParentPinGate` when locked; `_DashboardContent` is `ConsumerStatefulWidget` with `dispose()` calling `_gate?.lock()` (CR-01); no `QalamColors.reward`; `_EmptyState` for loading/error/empty |
| `lib/router/app_router.dart` | `/parent` route + merged `refreshListenable` | VERIFIED | `GoRoute(path: '/parent', builder: ... => const ParentDashboardScreen())`; `Listenable.merge([gate, parentGate])`; synchronous redirect (no await) |
| `lib/screens/home_screen.dart` | Parent nav unlocked, non-lock icon, routes to `/parent` | VERIFIED | `iconAsset: 'assets/icons/ink-drop.svg'`; `onTap: () => context.go('/parent')`; `isLocked: false`; no "Coming soon"; no `lock.svg` |
| `lib/main.dart` | Seeds `parentGateProvider` LOCKED at boot | VERIFIED | `parentGateProvider.overrideWith((ref) => ParentGate())` — `ParentGate()` defaults to `unlocked: false` |
| `lib/data/app_database.dart` | Read-only `allMastered()`/`allInProgress()` accessors | VERIFIED | Lines 254-262; `allMastered()` selects all `letterMastery` rows ordered by `masteredAt`; `allInProgress()` selects `letterReps` where `cleanReps > 0`; no write/delete accessor added |
| `lib/l10n/app_en.arb` | 17 Phase-9 copy keys with correct placeholders | VERIFIED | `parentTitle`, `parentSummary({mastered},{total})`, `parentEmptyTitle`, `parentPinNoRecovery`, `parentPinCooldown({seconds})`, and all other Phase-9 keys confirmed present with correct placeholder types |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/features/parent/pin_service.dart` | `lib/data/app_database.dart` | `getSetting`/`setSetting` over `AppSettings` keys | WIRED | `pin_service.dart:85-86,92-93,118,129-132,141` all call `db.getSetting`/`db.setSetting` with the exact key constants |
| `lib/features/parent/pin_service.dart` | `crypto` package | `Hmac(sha256, ...)` PBKDF2 loop | WIRED | `import 'package:crypto/crypto.dart'`; `Hmac(sha256, utf8.encode(pin))` at line 63 |
| `lib/providers/parent_providers.dart` | `AppDatabase.allMastered`/`allInProgress` + `curriculumRepository.getLetters` | Hand-written `FutureProvider` assembling `ParentProgress` | WIRED | `parent_providers.dart:112-151`: `db.allMastered()`, `db.allInProgress()`, `curriculum.getLetters()`, assembles rows in intro order |
| `lib/screens/home_screen.dart` | `/parent` route | `context.go('/parent')` in `_NavItem.onTap` | WIRED | `home_screen.dart:136` |
| `lib/router/app_router.dart` | `parentGateProvider` | Synchronous redirect guard + merged `refreshListenable` | WIRED | `app_router.dart:42,48`: `ref.watch(parentGateProvider)` + `Listenable.merge([gate, parentGate])` |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `parent_dashboard_screen.dart` | `progress` (ParentProgress) | `parentProgressProvider` → `db.allMastered()` + `db.allInProgress()` + `curriculum.getLetters()` | Yes — live Drift queries against real `letterMastery`/`letterReps` tables | FLOWING |
| `parent_pin_gate.dart` | `_mode` / cooldown | `_pin.isPinSet(db)` + `_pin.remainingCooldown(db)` | Yes — reads `AppSettings` keys from Drift on mount | FLOWING |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| PIN service tests (hash, salt, verify, cooldown) | `flutter test test/services/pin_service_test.dart` | `+8: All tests passed` | PASS |
| Route gate tests (default-deny, unlock, relock) | `flutter test test/router/parent_gate_test.dart` | Included in combined run, all passed | PASS |
| Dashboard tests (summary, rows, empty, read-only) | `flutter test test/screens/parent_dashboard_test.dart` | Included in combined run, all passed | PASS |
| DB accessor tests (allMastered, allInProgress) | `flutter test test/data/app_database_test.dart` | Included in combined run, all passed | PASS |
| Home screen nav test (Parent navigates, no Coming soon) | `flutter test test/screens/home_screen_test.dart` | Included in combined run, all passed | PASS |
| Combined run | All 5 test files | `+37: All tests passed!` | PASS |

The Drift "database created multiple times" warnings in the test output are the expected, documented behavior of the D-09 simulated-restart pattern (two `AppDatabase` instances over one shared in-memory executor) — not errors. All 37 assertions are GREEN.

---

### Probe Execution

No conventional probe scripts (`scripts/*/tests/probe-*.sh`) exist for this phase. Step 7c: SKIPPED (no shell probe files; automated verification handled by `flutter test`).

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| S1-11 | 09-01, 09-02, 09-03 | A parent can see the child's completed lessons and scores (PIN-gated, read-only local progress, no cloud, no account) | SATISFIED | All three plans claim S1-11; implementation verified across `pin_service.dart`, `parent_dashboard_screen.dart`, `/parent` route, `allMastered()`/`allInProgress()` accessors; REQUIREMENTS.md marks S1-11 as `[x] Complete` with Phase 9 traceability |

---

### Code Review Fix Verification (CR-01, WR-02)

The REVIEW.md identified two blockers that were fixed before this verification ran. Both are confirmed present in the actual code:

**CR-01 (relock-on-dispose gap):** `_DashboardContent` was converted to `ConsumerStatefulWidget` with `_DashboardContentState`. `dispose()` at lines 110-118 of `parent_dashboard_screen.dart` calls `_gate?.lock()` — the `_gate` reference is cached in `didChangeDependencies()` at line 106 to avoid using `ref` post-dispose. Fix is present and correct.

**WR-02 (default-deny parentGateProvider):** `parentGate` provider at `parent_providers.dart:94` returns `ParentGate()` — which defaults `unlocked: false` (confirmed at line 52: `ParentGate({bool unlocked = false})`). The comment explicitly documents "default-DENY". Fix is present. `parent_dashboard_test.dart` opts in to unlocked state via explicit override (`parentGateProvider.overrideWith((ref) => ParentGate(unlocked: true))`).

**WR-01 (cooldown re-read before verify):** `parent_pin_gate.dart` lines 177-183 re-read `_pin.remainingCooldown(_db)` at the start of the `_GateMode.enter` case before calling `verify`. Fix is present.

**CR-02 (in-flight double-submit guard):** `_submitting` bool at line 64; guard at line 136; `try/finally` at lines 141/206-208. Fix is present.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/features/parent/parent_pin_gate.dart` | 111-116 | `Future.delayed` chain without Timer cancellation (IN-01) | Info | Deferred by code reviewer — benign: `!mounted` guard prevents post-dispose side effects; no crash risk; fix is optional |
| `lib/features/parent/parent_pin_gate.dart` | 342 | `autofocus: true` implicit reliance (IN-02) | Info | Deferred by code reviewer — behavior is correct; minor consistency note only |

No `TBD`, `FIXME`, or `XXX` markers found in any Phase-9 modified files.
No `QalamColors.reward` (gold) in `parent_dashboard_screen.dart` (grep confirmed: comment only).
No `print`/`debugPrint` of PIN/salt/hash in `pin_service.dart` or `parent_pin_gate.dart` (grep confirmed: comments only).
No `lock.svg` shipped for the Parent nav item (ink-drop.svg is used).
Schema version is still 4 (confirmed in `app_database.dart:92`).

---

### Human Verification Required

All automated checks pass. The items below are the deferred device UAT from Plan 09-03 Task 4 (recorded in `09-HUMAN-UAT.md`, `human_verify_mode=end-of-phase`). These cannot be exercised by `flutter_test`.

#### 1. Nav Unlocked

**Test:** On a real Android tablet, tap the Home "Parent" nav item.
**Expected:** Shows a non-lock icon (ink-drop glyph), no "Coming soon" text, navigates to the PIN gate.
**Why human:** SVG asset rendering and nav-rail interaction require a real device. Visual confirmation that `ink-drop.svg` renders correctly and the nav item is not dimmed or locked.

#### 2. Create PIN Flow (First Entry)

**Test:** On a fresh install, tap "Parent" and complete the create-PIN flow.
**Expected:** "Create a PIN" prompt is shown; honest no-recovery line is displayed beneath; enter + confirm a 4-digit PIN; dashboard unlocks.
**Why human:** Multi-step interactive flow (enter value, see confirm screen, see no-recovery text) requires human interaction.

#### 3. Per-Entry Relock

**Test:** Exit via "Done", then re-tap "Parent".
**Expected:** Re-prompts the PIN on every entry (no session unlock — D-07).
**Why human:** Cross-entry session state requires device interaction and manual navigation.

#### 4. Persisted Cooldown After Force-Quit (Highest-Priority Check)

**Test:** Enter wrong PIN 5 times; confirm the calm cooldown countdown appears (no red, no lockout language); force-quit the app and reopen; confirm the cooldown is still in effect.
**Expected:** Cooldown persists across process kill (Drift-persisted, not in-memory). The countdown is still active after reopen.
**Why human:** Force-quit cannot be simulated in `flutter_test`. This is the highest-value device check for the persisted-cooldown security guarantee (T-09-02). The unit test exercises it with a simulated-restart pattern; the force-quit path requires a real process kill on device.

#### 5. Read-Only Dashboard with Real Progress

**Test:** Enter the correct PIN; inspect the dashboard with some completed lessons.
**Expected:** "N of M letters mastered" summary; per-letter list with mastered/in-progress rows; no edit/delete/reset affordance; no gold/star/streak/mascot chrome (PLAT-03).
**Why human:** Visual layout and real-data rendering on device; PLAT-03 compliance requires observing the absence of gamification chrome.

#### 6. Empty State on Fresh Profile

**Test:** With a fresh profile (no completed lessons), open the parent dashboard.
**Expected:** Calm empty state ("No lessons completed yet.") appears instead of the list; no spinner.
**Why human:** Requires a fresh data state on device.

#### 7. Visual Fidelity (Design Kit Compliance)

**Test:** Inspect the parent area screens against `docs/design/kit` tokens.
**Expected:** Parchment background (`QalamColors.bg`), soft-aqua row surfaces (`QalamColors.surface`), ink-teal accents only; no gold anywhere in the parent area.
**Why human:** Color token mapping to rendered pixels requires human visual inspection on device.

---

### Gaps Summary

No automated gaps. All 7 observable truths are VERIFIED in the actual codebase. The review-identified critical findings (CR-01, CR-02) and warnings (WR-01, WR-02) are all confirmed fixed in the current code. The only remaining items are the 7 device UAT checks deferred per `human_verify_mode=end-of-phase` and recorded in `09-HUMAN-UAT.md`. These are classified as `human_needed`, not as gaps — per the phase instructions, the device verification items are intentionally deferred, not absent.

---

_Verified: 2026-06-14_
_Verifier: Claude (gsd-verifier)_
