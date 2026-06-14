---
phase: 09-parent-dashboard
reviewed: 2026-06-14T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - lib/features/parent/pin_service.dart
  - lib/features/parent/parent_pin_gate.dart
  - lib/features/parent/parent_progress.dart
  - lib/providers/parent_providers.dart
  - lib/screens/parent_dashboard_screen.dart
  - lib/router/app_router.dart
  - lib/screens/home_screen.dart
  - lib/data/app_database.dart
findings:
  critical: 2
  warning: 3
  info: 2
  total: 7
status: clean
fixed:
  - CR-01  # relock on dispose — 5275a51
  - CR-02  # in-flight _submit guard — 2495cc3
  - WR-01  # re-read persisted cooldown before verify — 3b7dc32
  - WR-02  # default-deny parentGateProvider — e356032
  - WR-03  # fold glyph into row, drop redundant parse — cfd9fce
deferred:
  - IN-01  # Future.delayed tick — info, out of scope
  - IN-02  # _PinField autofocus — info, out of scope
---

# Phase 09: Code Review Report

**Reviewed:** 2026-06-14
**Depth:** standard
**Files Reviewed:** 8
**Status:** clean (all Critical + Warning findings fixed 2026-06-14; IN-01/IN-02 deferred)

## Summary

The PBKDF2 core, constant-time compare, and persisted cooldown are all
structurally sound. The crypto primitives are correct (RFC 2898 U_1 formula,
XOR-accumulate compare with no early-out, `Random.secure()` salt, no plaintext
logged). The route-gate architecture (single `/parent` widget as access
boundary, `parentGate` seeded LOCKED in `main.dart`, re-lock on "Done") is
correct in its happy path.

Two blockers exist. The first is a missing relock path when the user leaves
`/parent` without pressing "Done" (Android back gesture, deep-link clobber, or
any future route displacement). The second is an absent in-flight guard on the
`_submit()` async method, which allows rapid double-tapping to fire two
concurrent PBKDF2 computations and two Drift writes — corrupting the fail
counter and, in the CREATE flow, leaving the wrong hash stored. There is also a
secondary timing gap in the cooldown check (in-memory `_cooldownSeconds` vs.
the persisted `lockUntil`) that could allow a submission fractionally before the
cooldown truly expires.

---

## Critical Issues

### CR-01: Relock-on-dispose not implemented — PIN gate bypassed if user leaves without "Done"

**File:** `lib/screens/parent_dashboard_screen.dart:40-53` and `lib/screens/parent_dashboard_screen.dart:87-152`

**Issue:** The entire parent screen consists of `ConsumerWidget` subclasses
(`ParentDashboardScreen` and `_DashboardContent`) with no `dispose()` override.
The only code path that calls `parentGate.lock()` is the "Done" button handler
at line 95. D-07 requires per-entry relock ("A clear 'Done'/back returns to
child Home").

Although `context.go('/parent')` replaces (rather than pushes) the route, and
the `AppBar` has `automaticallyImplyLeading: false`, go_router's history still
has a prior entry (`/`). On Android, a system back gesture (`predictive-back` or
hardware key) on a top-level `go`-based route may cause go_router to navigate
back to the previous location. In that case, the widget tree unmounts but
`parentGate` remains `unlocked: true` for the rest of the session. A second tap
on "Parent" from Home then bypasses the PIN entirely (the gate is already
unlocked, so `ParentDashboardScreen.build` renders the dashboard directly).

Additionally, any future feature that programmatically navigates away from
`/parent` (notification deep-link, lesson completion → `/`, etc.) will leave the
gate unlocked.

**Fix:** Convert `_DashboardContent` (or `ParentDashboardScreen`) to a
`ConsumerStatefulWidget` and lock the gate in `dispose`:

```dart
class _DashboardContent extends ConsumerStatefulWidget {
  const _DashboardContent({required this.l10n, required this.progress});
  final AppLocalizations l10n;
  final ParentProgress progress;

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  @override
  void dispose() {
    // D-07: relock whenever the dashboard unmounts, not only on "Done".
    // Uses read() — safe in dispose() (no rebuild triggered after unmount).
    ref.read(parentGateProvider).lock();
    super.dispose();
  }

  // ... rest of build() unchanged ...
}
```

Alternatively (simpler, fewer lines), keep `ConsumerWidget` and wrap the body
`Scaffold` in a `PopScope`:

```dart
return PopScope(
  canPop: true,
  onPopInvokedWithResult: (didPop, _) {
    if (didPop) ref.read(parentGateProvider).lock();
  },
  child: Scaffold( ... ),
);
```

The dispose-time approach is more robust because it catches every unmount path,
not only the back gesture.

---

### CR-02: No in-flight guard on `_submit()` — concurrent double-submit corrupts fail counter and hash

**File:** `lib/features/parent/parent_pin_gate.dart:122-179`

**Issue:** `_submit()` is an `async` method wired to two simultaneous triggers:
the button's `onTap` (line 282) and the field's `onSubmitted` (line 252). It
has no `_submitting` flag. During the ~100 ms PBKDF2 derivation (`_pin.verify`)
or Drift writes (`_pin.registerFailure`, `_pin.setPin`), a second tap on the
button (or another keyboard submit) launches a second concurrent `_submit()`
call.

Concrete failure modes:

1. **ENTER flow — wrong PIN:** Two concurrent calls both pass the
   `if (_cooldownSeconds > 0) return` guard (both see the same in-memory 0),
   both call `verify()`, both get `false`, both call `registerFailure()`. The
   fail counter is incremented twice per single guess attempt. After 3 rapid
   double-taps the counter reaches 6 (≥5), triggering a cooldown for only one
   actual wrong attempt. Worse, after a legitimate cooldown, a user who fails
   once more sees the counter jump by 2, locking again immediately.

2. **CREATE flow — `setPin`:** Both calls race to write the hash. The second
   `setPin` call generates a fresh salt and overwrites the first. The final
   stored hash corresponds to one of two different salts and the PIN entered;
   there is no correctness guarantee about which wins. Subsequent `verify` calls
   may silently fail.

3. **ENTER flow — correct PIN:** Both calls call `registerSuccess()` and then
   `ref.read(parentGateProvider).unlock()` — double unlock is idempotent
   (guarded in `ParentGate.unlock()`), so this case is less harmful, but
   `registerSuccess()` writes twice to Drift unnecessarily.

**Fix:** Add a bool guard at the top of `_submit()` and reset it on all exit
paths:

```dart
bool _submitting = false;

Future<void> _submit() async {
  if (_submitting) return;          // drop the concurrent call
  final value = _controller.text;
  if (value.length != 4) return;
  _submitting = true;
  try {
    switch (_mode) {
      // ... existing cases unchanged ...
    }
  } finally {
    _submitting = false;
  }
}
```

This is a single-widget bool; no Riverpod state needed. The `try/finally`
ensures the guard resets even if an exception propagates.

---

## Warnings

### WR-01: Cooldown bypass via stale in-memory counter — `_submit` checks `_cooldownSeconds`, not the persisted `lockUntil`

**File:** `lib/features/parent/parent_pin_gate.dart:156`

**Issue:** The ENTER guard at line 156 is:

```dart
if (_cooldownSeconds > 0) return;
```

`_cooldownSeconds` is an in-memory integer decremented by
`_refreshCooldown()` every second via `_tickCooldown()`. The tick chain stops
when `_cooldownSeconds` reaches 0. However, the `remainingCooldown()` call in
`_refreshCooldown()` reads `DateTime.now().millisecondsSinceEpoch` each time,
so the value displayed is accurate. The issue is: `_submit` itself does NOT
re-read `remainingCooldown()` from the DB before calling `verify`. It trusts
`_cooldownSeconds`.

Scenario: The timer fires a final `_refreshCooldown()` call that returns
`Duration(milliseconds: 400)`, setting `_cooldownSeconds = 0` (integer
truncation of 0.4 s). The input becomes enabled. The persisted `lockUntil` is
still 400 ms in the future, but `_cooldownSeconds` is 0, so `_submit` proceeds
to `verify`. This allows a guess ~0.4 s before the cooldown truly expires.

This is a marginal timing gap (sub-second, requires exact timing), but it
contradicts the stated invariant that the persisted cooldown is the source of
truth.

**Fix:** At the start of the ENTER case in `_submit`, re-read the cooldown from
the DB:

```dart
case _GateMode.enter:
  // Re-read the persisted lockUntil — the in-memory counter can be up to
  // 1 s stale at the moment of submission.
  final cooldown = await _pin.remainingCooldown(_db);
  if (!mounted) return;
  if (cooldown != null && cooldown.inMilliseconds > 0) {
    setState(() => _cooldownSeconds = cooldown.inSeconds);
    return;
  }
  // ... proceed with verify ...
```

---

### WR-02: `parentGateProvider` default value is `unlocked: true` — dangerous fallback if `main.dart` override is missing

**File:** `lib/providers/parent_providers.dart:92`

**Issue:**

```dart
@Riverpod(keepAlive: true)
ParentGate parentGate(Ref ref) => ParentGate(unlocked: true);
```

The default (non-overridden) value of `parentGateProvider` is `unlocked: true`.
This was done intentionally so the body-only `parent_dashboard_test.dart` can
render the dashboard without overriding the gate. However, the comment at lines
80-85 documents that "production ALWAYS overrides this in `main.dart`".

If anyone adds a test that pumps `ParentDashboardScreen` inside a real
`ProviderScope` without overriding `parentGateProvider` (e.g., an integration
test, a golden test, or a future screen test), they will get the dashboard body
rendered directly, skipping the PIN gate. The gate's security guarantee is
entirely contingent on the `main.dart` override being present — one missed
override in a test or a future entry point bypasses the gate silently.

The default-unlocked design creates a latent footgun. Failing safe (default
locked) is the correct posture for an access control object; tests that need the
unlocked state should explicitly opt in.

**Fix:** Change the default to `unlocked: false`:

```dart
@Riverpod(keepAlive: true)
ParentGate parentGate(Ref ref) => ParentGate();  // unlocked: false is the default
```

Then update `test/screens/parent_dashboard_test.dart` to override the gate
explicitly (alongside the existing `parentProgressProvider` override):

```dart
overrides: [
  parentGateProvider.overrideWith((ref) => ParentGate(unlocked: true)),
  parentProgressProvider.overrideWith(...),
],
```

This makes the test's intent explicit and removes the silent footgun.

---

### WR-03: `_lettersByIdProvider` calls `getLetters()` independently — redundant parse and potential inconsistency with `parentProgressProvider`

**File:** `lib/screens/parent_dashboard_screen.dart:264-267`

**Issue:**

```dart
final _lettersByIdProvider = FutureProvider<Map<String, Letter>>((ref) async {
  final letters = await ref.watch(curriculumRepositoryProvider).getLetters();
  return {for (final l in letters) l.id: l};
});
```

This provider calls `curriculumRepositoryProvider.getLetters()` as a second
independent call. `parentProgressProvider` (in `parent_providers.dart`) already
calls `getLetters()` to assemble the `ParentLetterRow` list. The two calls are
separate `Future` invocations; they do not share the same loaded data.

Two concrete risks:

1. If `getLetters()` is not idempotent (e.g., if it reads and parses a JSON
   asset and the curriculum asset differs between calls — unlikely but not
   impossible during hot-reload or test), the letter char displayed in
   `_LetterRow` could be mismatched with the `displayName` in the same row.
2. The provider is file-private (`_lettersByIdProvider`), defined at module level
   without `autoDispose`. It will be held alive by the `ProviderContainer` even
   after the user leaves `/parent`. Its lifecycle is not tied to the dashboard
   page.

**Fix:** Derive the letter map from `parentProgressProvider` instead of issuing
a second `getLetters()` call. Since `parentProgressProvider` already returns
`ParentLetterRow` objects that contain the `letterId` and `displayName`, the
glyph (`char`) is the only missing field. Pass the glyph through the view model
instead:

In `parent_progress.dart`, add:
```dart
final String? glyph;  // Letter.char — null if curriculum data unavailable
```

In `parent_providers.dart`, populate it:
```dart
rows.add(ParentLetterRow(
  letterId: letter.id,
  displayName: letter.name.display,
  glyph: letter.char,   // <- add this
  mastered: true,
  ...
));
```

Then `_LetterRow` reads `row.glyph` directly and `_lettersByIdProvider` can be
removed entirely.

---

## Info

### IN-01: `_tickCooldown` uses an unregistered `Future.delayed` chain — no cancellation on dispose

**File:** `lib/features/parent/parent_pin_gate.dart:103-110`

**Issue:**

```dart
void _tickCooldown() {
  Future<void>.delayed(const Duration(seconds: 1), () async {
    if (!mounted || _cooldownSeconds <= 0) return;
    await _refreshCooldown();
  });
}
```

Each tick schedules a new `Future.delayed`. When the widget disposes, the
pending delay is not cancelled; it fires after 1 s and hits the `!mounted`
guard. This is safe (no crash, no state mutation after dispose) but the dangling
future is invisible — it cannot be cancelled or inspected.

This pattern works correctly here, but a future change that adds side-effects
inside the delayed callback (e.g., updating an external counter) would silently
execute post-dispose.

**Fix (optional):** Use a `Timer` from `dart:async` instead, store it in a
field, and cancel it in `dispose()`:

```dart
Timer? _cooldownTimer;

void _tickCooldown() {
  _cooldownTimer?.cancel();
  _cooldownTimer = Timer(const Duration(seconds: 1), () async {
    if (!mounted || _cooldownSeconds <= 0) return;
    await _refreshCooldown();
  });
}

@override
void dispose() {
  _cooldownTimer?.cancel();
  _controller.dispose();
  _focus.dispose();
  _wiggle.dispose();
  super.dispose();
}
```

---

### IN-02: `_PinField` has `autofocus: true` unconditionally — fires even while in `_GateMode.loading`

**File:** `lib/features/parent/parent_pin_gate.dart:310`

**Issue:** `autofocus: true` is hardcoded in `_PinField`. However, `_PinField`
is only rendered in `_buildBody` after the `if (_mode == _GateMode.loading)
return` guard at line 207, so in practice the field only appears once mode is
resolved. The `autofocus` flag is therefore correct in behavior.

However, the loading guard returns a `SizedBox` (not a `_PinField`), so the
focus request only fires after mode resolves. This is a minor consistency note:
`_PinField` does not need `autofocus: true` if the parent's `_resolveInitialMode`
always calls `_focus.requestFocus()` after setting state (which it does not — it
only calls `requestFocus()` in the confirm/error branches, not on initial mode
resolution). Without explicit `requestFocus()` after the initial `setState`, the
`autofocus` on the field is the sole trigger for initial keyboard focus. This
works, but the reliance on `autofocus` is implicit.

**Fix (low priority):** Remove `autofocus: true` from `_PinField` and add an
explicit `_focus.requestFocus()` call at the end of `_resolveInitialMode` after
`setState`, matching the pattern used in the confirm/error branches. This makes
focus management explicit and consistent.

---

_Reviewed: 2026-06-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
