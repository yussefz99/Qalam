# Phase 9: Parent Dashboard - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 8 created / 3 modified
**Analogs found:** 11 / 11 (every new/modified file has a strong in-repo analog)

> Qalam is Flutter/Dart, Android-only, RTL, Riverpod-only, Drift, go_router. Every
> excerpt below is real in-repo code the executor should mirror. The phase needs **no
> new Drift table and no schema-version bump** — PIN material + cooldown live in the
> existing `AppSettings` k/v table (research §Runtime State Inventory).

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/parent/pin_service.dart` (new) | service (pure-Dart auth/crypto) | transform / verify | `lib/core/scoring/` pure-Dart services + `app_database.dart` getSetting/setSetting | role-match |
| `lib/features/parent/parent_progress.dart` (new) | model (immutable view model) | transform | `lib/models/lesson_progression.dart` (ProgressionSnapshot.compute) / `lib/models/letter.dart` | role-match |
| `lib/providers/parent_providers.dart` (new) | provider (Drift-typed + gate) | request-response / event-driven (ChangeNotifier) | `lib/providers/profile_providers.dart` (OnboardingGate + FutureProvider) + `progression_providers.dart` | **exact** |
| `lib/data/app_database.dart` (modify — add read accessors) | model/data (Drift accessors) | CRUD (read-only) | the existing accessor block in the **same file** (`allMastered`/`allInProgress` mirror `cleanRepsFor`/`getCleanReps`) | **exact** |
| `lib/router/app_router.dart` (modify — add `/parent` route + gate) | route (go_router redirect) | request-response | the onboarding gate **in the same file** (lines 36, 41–51) + the commented `/parent` seam (lines 112–120) | **exact** |
| `lib/features/parent/parent_pin_gate.dart` (new) | component (PIN create/enter screen) | request-response | `lib/screens/settings_screen.dart` (calm centered shell) + `home_screen.dart` `.when` degradation | role-match |
| `lib/features/parent/parent_dashboard_screen.dart` (new) | component (read-only list screen) | CRUD (read) | `lib/screens/settings_screen.dart` (shell + `_PlaceholderRow`) + `home_screen.dart` `_TodayCardLayout` reader pattern | role-match |
| `lib/screens/home_screen.dart` (modify — unlock `_NavItem`) | component (nav wiring) | request-response | the `_NavItem` for Journey **in the same file** (lines 119–126, already-unlocked sibling) | **exact** |
| `lib/l10n/app_en.arb` (modify — add ~15 keys) | config (i18n strings) | static | the existing keyed entries + placeholder entries (lines 34–47, 263–334) | **exact** |
| `lib/main.dart` (modify — seed ParentGate override) | config (boot/DI) | event-driven | the `onboardingGateProvider.overrideWith` seed (lines 31–45) | **exact** |
| `test/features/parent/*` (new, Wave 0) | test | — | `test/router/onboarding_gate_test.dart` + `test/providers/progression_providers_test.dart` | role-match |

---

## Pattern Assignments

### `lib/providers/parent_providers.dart` (provider, gate + Drift-typed read)

**Analog:** `lib/providers/profile_providers.dart` (gate) + `lib/providers/progression_providers.dart` (Drift-typed FutureProvider).

This is the single most important analog. It supplies **both** new provider shapes the phase needs: (1) a `ChangeNotifier` gate used as the router's `refreshListenable`, and (2) a hand-written `FutureProvider` over Drift types.

**Gate pattern — copy `OnboardingGate` exactly** (`profile_providers.dart` lines 54–74). The `ParentGate` is identical in shape; just rename the flag to `unlocked` and add a `lock()`:
```dart
class OnboardingGate extends ChangeNotifier {
  OnboardingGate(this._hasProfile);
  bool _hasProfile;
  bool get hasProfile => _hasProfile;

  void markProfileCreated() {
    _hasProfile = true;
    notifyListeners();
  }
}

// keepAlive — held for app lifetime; overridden at boot with the real seed.
@Riverpod(keepAlive: true)
OnboardingGate onboardingGate(Ref ref) => OnboardingGate(false);
```
> NOTE the documented `riverpod_lint` `unsupported_provider_value` false-positive on a
> ChangeNotifier-as-provider (lines 12–19, 66–72). It is intentional and left visible —
> the executor should expect the same warning on `parentGate` and document it the same way.
> Per D-07 the `/parent` gate is **per-entry**: provide both `unlock()` and `lock()`, and
> "Done" calls `lock()` then `context.go('/')`.

**Drift-typed FutureProvider pattern — copy `childProfileProvider` / `progressionProvider`** (`profile_providers.dart` lines 22–47; `progression_providers.dart` lines 112–135). The Rule-3 deviation note (lines 21–29) is mandatory context — **do NOT use `@riverpod` codegen on any provider whose return type touches a Drift data class** (riverpod_generator 4.0.3 throws `InvalidTypeException`). Map Drift rows into the plain `ParentProgress`/`ParentLetterRow` view model early. The view-model assembly the research already drafted (09-RESEARCH lines 350–369) follows the `progressionProvider` shape:
```dart
final progressionProvider = FutureProvider<ProgressionSnapshot>((ref) async {
  final mastered = await ref.watch(masteredLetterIdsProvider.future);
  final lessons = await ref.watch(curriculumRepositoryProvider).getLessons();
  final ordered = [...lessons]..sort((a, b) => a.order.compareTo(b.order));
  ...
  return ProgressionSnapshot.compute(ordered, startingLessonId, mastered);
});
```
For the parent dashboard, mirror this with `db.allMastered()` + `db.allInProgress()` +
`curriculumRepository.getLetters()`, iterate in **curriculum intro order** (the list is
already sorted by `introOrder` — see curriculum analog below), and produce a `ParentProgress`.

**Optional live binding:** if live updates are wanted, `progression_providers.dart` exposes
`_bindDriftStream` (lines 43–64) which solves the Riverpod-3 StreamProvider-pause pitfall.
Progress will not change while the gate is open, so a one-shot `FutureProvider` is sufficient
and simpler — prefer it unless live refresh is explicitly required.

---

### `lib/data/app_database.dart` (data, read-only Drift accessors — MODIFY)

**Analog:** the existing accessor block **in the same file** — `cleanRepsFor` (lines 163–167),
`getProfile` (lines 181–182), `watchMasteredLetterIds` (lines 234–236).

Add two read-only accessors mirroring the existing style exactly (`select(...)..where/orderBy`).
The research drafted them (09-RESEARCH lines 249–252):
```dart
// ADD to AppDatabase — read-only; mirrors existing accessor style; never logs values.
Future<List<LetterMasteryData>> allMastered() =>
    (select(letterMastery)..orderBy([(t) => OrderingTerm(expression: t.masteredAt)])).get();
Future<List<LetterRepData>> allInProgress() =>
    (select(letterReps)..where((t) => t.cleanReps.isBiggerThanValue(0))).get();
```
> Drift generated data-class names are `LetterMasteryData` / `LetterRepData` (the table classes
> `LetterMastery`/`LetterReps` produce `*Data` rows). Verify against `app_database.g.dart` before
> wiring — the research used these names.

**PIN material storage — reuse `setSetting`/`getSetting` as-is** (lines 124–135). NO new columns,
NO new table, NO `schemaVersion` bump (currently `4`, line 92). The PIN hash/salt/failCount/lockUntil
are just new `AppSettings` keys. The existing migration (lines 95–113) is the idempotent, version-guarded
pattern to follow **if** the planner ever decides on typed columns — but the recommended path adds no migration.

**SECURITY convention (binding, repeated in every table doc-comment, e.g. lines 33–34, 46–49, 64–66):**
"never logs values" / "captured stroke points are NEVER persisted". The PIN service MUST extend this:
never `print`/`debugPrint` the PIN, salt, or hash, even in debug.

---

### `lib/router/app_router.dart` (route, synchronous redirect gate — MODIFY)

**Analog:** the onboarding gate **in the same file** (lines 36, 41–51) and the commented `/parent`
seam (lines 112–120). The seam was authored for exactly this phase.

**Synchronous redirect — copy the onboarding gate shape** (lines 38–51):
```dart
final gate = ref.watch(onboardingGateProvider);

return GoRouter(
  initialLocation: kDemoMode ? '/demo/home' : '/',
  refreshListenable: gate,          // re-run redirects when the gate flips
  redirect: (context, state) {
    if (kDemoMode) return null;
    final onOnboarding = state.matchedLocation == '/onboarding';
    if (!gate.hasProfile && !onOnboarding) return '/onboarding';
    if (gate.hasProfile && onOnboarding) return '/';
    return null;
  },
  ...
```
For `/parent`: `ref.watch(parentGateProvider)` is added as a **second** `refreshListenable`
source — go_router takes one `refreshListenable`, so merge both gates into a single
`Listenable.merge([onboardingGate, parentGate])` OR keep the existing gate and add the parent
flag check inside `redirect`. **CRITICAL (lines 42–44, repo-documented Pitfall 2):** the redirect
MUST stay synchronous — **never `await` Drift inside `redirect`**. Read `isPinSet`/cooldown inside
the `/parent` screen's async build, never in the redirect.

**Route registration — copy the `/settings` GoRoute** (lines 79–82):
```dart
GoRoute(
  path: '/settings',
  builder: (context, state) => const SettingsScreen(),
),
```
Add the `/parent` GoRoute the same way. **Research recommendation (09-RESEARCH line 240, Pattern 3):**
use a **single `/parent` route** whose widget chooses PIN-create / PIN-enter / dashboard from
`isPinSet` + `parentGate.unlocked` — no sub-routes, no redirect-loop risk.

---

### `lib/features/parent/pin_service.dart` (service, pure-Dart hash/verify — NEW)

**Analog:** there is no existing crypto service, so this is a **NEW-pattern** file (see "No Analog"
below). Its *shape* (a pure-Dart, widget-free, unit-testable class with a Riverpod provider) mirrors
`CurriculumRepository` (`lib/data/curriculum_repository.dart` lines 12–135) and its DB access mirrors
`AppDatabase.getSetting`/`setSetting`. The full reference implementation is **already written in
09-RESEARCH Pattern 1 (lines 156–205) and Pattern 2 (lines 212–233)** — PBKDF2-HMAC-SHA256 (≥100k
iters), `Random.secure()` salt, constant-time XOR compare, persisted cooldown. The executor should
copy those verbatim and have security-auditor ratify.

**Provider shape — copy `curriculumRepository`** (curriculum_repository.dart lines 132–135):
```dart
@Riverpod(keepAlive: true)
CurriculumRepository curriculumRepository(Ref ref) {
  return CurriculumRepository();
}
```
> A `PinService` returning only `bool`/`void` (no Drift data class in its signature) **may** use
> `@riverpod` codegen — the InvalidTypeException only triggers on Drift-typed *return* values.

---

### `lib/features/parent/parent_progress.dart` (model, immutable view model — NEW)

**Analog:** `lib/models/letter.dart` (immutable model with named factory) + `ProgressionSnapshot`
in `lib/models/lesson_progression.dart` (a computed snapshot, referenced at progression_providers.dart
line 134 `ProgressionSnapshot.compute(...)`).

Mirror the immutable-class-with-const-constructor style (`Letter`, letter.dart lines 108–141).
Define `ParentLetterRow { id, displayName (Latin), char (Arabic glyph), status, cleanReps, masteredAt? }`
with named constructors `ParentLetterRow.mastered(...)` / `ParentLetterRow.inProgress(...)` (research
draft, 09-RESEARCH lines 360–365), and a `ParentProgress { masteredCount, totalLetters, rows }`.
Source the glyph + display name from `Letter.char` and `Letter.name.display` (letter.dart lines 109–111).

---

### `lib/features/parent/parent_dashboard_screen.dart` (component, read-only list — NEW)

**Analog:** `lib/screens/settings_screen.dart` (the calm adult shell) for layout; `home_screen.dart`
`_TodaysLessonCardReader` (lines 648–722) for the `.when` provider-degradation reader pattern.

**Shell — copy the SettingsScreen container** (settings_screen.dart lines 29–63). UI-SPEC mandates
the same centered `ConstrainedBox(maxWidth: 640)` on `QalamColors.bg`:
```dart
return Scaffold(
  appBar: AppBar(title: Text(l10n.settings)),
  body: Center(
    child: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(QalamSpace.space8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n.settings, style: QalamTextStyles.heading),
              ...
```

**Per-letter row — copy `_PlaceholderRow`** (settings_screen.dart lines 67–90). It is the exact
row card the dashboard list reuses (soft-aqua surface, `QalamRadii.lg`, `space3` bottom margin,
`space5`/`space4` padding, `targetMin` min-height):
```dart
Container(
  width: double.infinity,
  margin: const EdgeInsets.only(bottom: QalamSpace.space3),
  constraints: const BoxConstraints(minHeight: QalamTargets.targetMin),
  padding: const EdgeInsets.symmetric(
    horizontal: QalamSpace.space5, vertical: QalamSpace.space4),
  decoration: BoxDecoration(
    color: QalamColors.surface,
    borderRadius: BorderRadius.circular(QalamRadii.lg),
  ),
  alignment: AlignmentDirectional.centerStart,
  child: Text(label, style: QalamTextStyles.body),
)
```
Extend each row to hold: the **Arabic glyph via `ArabicText(letter.char)`** (the ONLY RTL island —
see shared pattern), the leaf `check-complete.svg` for mastered rows (via the `_SafeSvgIcon` helper
pattern, home_screen.dart lines 210–233), and the status/reps/date metadata as English chrome.

**Provider reader + degradation — copy the `.when` pattern** (home_screen.dart lines 655–720,
`_TodaysLessonCardReader`). Watch `parentProgressProvider`; on `loading`/`error` render the
**empty-state copy, never a spinner or raw error** (UI-SPEC §Loading/error, lines 226–230). Empty
state (`rows.isEmpty`) = the calm `parentEmptyTitle`/`parentEmptyBody` (D-04).

> READ-ONLY (hard constraint): no edit/delete/reset affordance, no gold/`QalamColors.reward`,
> no mascot, no celebration motion (UI-SPEC Mandatory omissions, lines 45–55).

---

### `lib/features/parent/parent_pin_gate.dart` (component, PIN create/enter — NEW)

**Analog:** `lib/screens/settings_screen.dart` (calm centered shell) + the obscured-field contract
in 09-RESEARCH Pitfall 4 (lines 318–322) and UI-SPEC §Interaction (lines 245–249).

Reuse the SettingsScreen shell (above), centered vertically too. PIN field contract (Pitfall 4):
`obscureText: true`, `keyboardType: TextInputType.number`, `enableSuggestions: false`,
`autocorrect: false`, `maxLength: 4`; **never log the controller value**. Keypad keys at
`QalamTargets.targetComfy` (72px), `space4` apart (UI-SPEC Spacing). Wrong-PIN wiggle uses
`QalamMotion.easeInOut` + `durFast` (140ms) in `QalamColors.warnSoft` — never red, never an X
(UI-SPEC Interaction line 248). Honor `MediaQuery.disableAnimations` (skip the wiggle).

---

### `lib/screens/home_screen.dart` (component, unlock the Parent nav item — MODIFY)

**Analog:** the **already-unlocked Journey `_NavItem` in the same file** (lines 119–126). The Parent
item (lines 128–137) just needs to become its twin. Today it is locked:
```dart
// Parent — locked, Phase 9.
_NavItem(
  iconAsset: 'assets/icons/lock.svg',
  label: l10n?.navParent ?? 'Parent',
  isActive: false,
  isLocked: true,
  sublabel: l10n?.comingSoon ?? 'Coming soon',
  onTap: null, // Inert — no route.
),
```
Change to mirror the Journey item (lines 120–126): drop `isLocked`/`sublabel`, swap the icon to a
**non-lock** glyph (UI-SPEC Assumption A-02: no parent glyph exists in `assets/icons/` yet — do NOT
ship `lock.svg`; planner sources or reuses a neutral glyph), and wire `onTap: () => context.go('/parent')`:
```dart
_NavItem(
  iconAsset: 'assets/icons/<parent-or-neutral>.svg',
  label: l10n?.navParent ?? 'Parent',
  isActive: false,
  isLocked: false,
  onTap: () => context.go('/parent'),
),
```
Remove the now-unused `comingSoon` reference here (the ARB key may stay). Update the file's
anti-gamification header comment (lines 13) which currently says "Parent is inert".

---

### `lib/l10n/app_en.arb` (config, ~15 new keys — MODIFY)

**Analog:** the existing keyed entries (lines 34–47) for plain strings, and the placeholder-bearing
entries (lines 263–334) for `{mastered}`/`{total}`/`{seconds}`/`{reps}`/`{date}` keys.

Plain-string shape (lines 34–37):
```json
"settings": "Settings",
"@settings": {
  "description": "Settings screen heading and nav label."
},
```
Placeholder shape (lines 326–334, the `{n}` pattern):
```json
"@<key>": {
  "description": "...",
  "placeholders": {
    "n": { "type": "int", "example": "1" }
  }
}
```
Add the keys enumerated in UI-SPEC §Copywriting (lines 190–223): `parentTitle`,
`parentPinCreatePrompt`, `parentPinCreateHelp`, `parentPinConfirmPrompt`, `parentPinMismatch`,
`parentPinNoRecovery`, `parentPinConfirm`, `parentPinEnterPrompt`, `parentPinWrong`,
`parentPinCooldown` (`{seconds}` int placeholder), `parentSummary` (`{mastered}`/`{total}` int),
`parentRowMastered` (`{reps}` int + `{date}` String), `parentRowInProgress` (`{reps}` int),
`parentEmptyTitle`, `parentEmptyBody`, plus `commonContinue`/`commonDone` (reuse if present).
> Owner owns final wording (CLAUDE.md / UI-SPEC Open Q2/Q4) — these are draft strings for approval.

---

### `lib/main.dart` (config, seed the ParentGate override — MODIFY)

**Analog:** the `onboardingGateProvider.overrideWith` boot seed **in the same file** (lines 31–46).
Mirror it for the parent gate. The parent gate starts **locked** every launch (D-07 per-entry), so no
boot DB read is required — seed `ParentGate(unlocked: false)`:
```dart
onboardingGateProvider.overrideWith((ref) => OnboardingGate(hasProfile)),
// add:
parentGateProvider.overrideWith((ref) => ParentGate()),  // starts locked
```
The existing `appDatabaseProvider.overrideWith` (lines 39–42) is the shared single-DB instance the
PinService reads through — do not construct a second `AppDatabase`.

---

## Shared Patterns

### RTL Arabic glyph rendering (per-letter labels only)
**Source:** `lib/widgets/arabic_text.dart` (full file) — used at `home_screen.dart` lines 768–774, 395–398.
**Apply to:** the dashboard per-letter rows (the glyph is the ONLY RTL island; all chrome stays LTR).
```dart
ArabicText(letter.char)              // body glyph (26px Noto Naskh, letterSpacing 0)
// or, for a larger label:
ArabicText(letter.char, display: true)
```
`ArabicText` already isolates Western digits LTR and forbids Eastern-Arabic numerals (D-06) — never
wrap a whole screen in `Directionality`, only the glyph island (Pitfall 3).

### Design-system tokens (no raw hex, no magic numbers)
**Source:** `lib/theme/dimens.dart` (`QalamSpace`/`QalamTargets`/`QalamRadii`/`QalamShadows`/`QalamMotion`)
and `lib/theme/colors.dart` (`QalamColors`), `lib/theme/text_styles.dart` (`QalamTextStyles`).
**Apply to:** every widget in this phase. Key tokens (verified): `QalamColors.bg` (parchment bg),
`.surface` (soft-aqua row card), `.primary` (teal accent/buttons), `.success` (leaf — mastered marker),
`.warnSoft` (coral — wrong-PIN, never red), `.fgMuted` (slate — metadata). `QalamSpace.space8` screen
padding, `space3` row gap, `QalamTargets.targetMin`(64)/`targetComfy`(72) touch floors,
`QalamRadii.lg` row radius, `QalamMotion.durFast`/`easeInOut` (wiggle). **FORBIDDEN:** `QalamColors.reward`
(gold) anywhere on these screens (UI-SPEC).

### Provider-state degradation (`.when` → calm fallback, never crash)
**Source:** `home_screen.dart` `_TodaysLessonCardReader` (lines 655–720) + `_GreetingHeaderReader`
(lines 272–306); progression degradation `progression_providers.dart` lines 117–135.
**Apply to:** the dashboard provider reader and the PIN-state async reads. loading/error degrade to
the empty-state / quiet UI; a raw stack trace is never shown (T-05-07 / T-06-08 convention).

### No-log security convention (binding for the auth surface)
**Source:** `app_database.dart` table doc-comments (lines 9–10, 33–34, 46–49, 64–66).
**Apply to:** `pin_service.dart` and `parent_pin_gate.dart` — never log the PIN, salt, or hash; store
only IDs/counts (here: a hash, a salt, an int failCount, an epoch-ms lockUntil). Persist the cooldown
in Drift, never in-memory (research Pitfall 1 — the single most important correctness point).

### Curriculum letter set / order / "N of 28" denominator
**Source:** `lib/data/curriculum_repository.dart` `getLetters()` (lines 79–82); list is pre-sorted by
`introOrder` (lines 44–45). Provider at lines 132–135.
**Apply to:** the dashboard summary denominator and row ordering. Use `getLetters().length` as `{total}`
(09-RESEARCH Open Q1 / UI-SPEC A-01 default = full 28); iterate `getLetters()` for stable intro-order rows.
**Do NOT hardcode 28** (Pitfall 5).

---

## No Analog Found

| File | Role | Data Flow | Reason | Substitute |
|------|------|-----------|--------|------------|
| `lib/features/parent/pin_service.dart` (crypto core) | service | transform/verify | No existing hashing/auth code in the repo — this is the app's **first authentication surface** (09-RESEARCH §Security Domain). | Use the verbatim reference in **09-RESEARCH Pattern 1 (lines 156–205) + Pattern 2 (lines 212–233)**; mirror `CurriculumRepository`'s pure-Dart-class + Riverpod-provider *shape*; security-auditor ratifies (A1). |
| On-screen numeric keypad widget | component | request-response | No PIN/keypad widget exists in the repo. | UI-SPEC A-03: a plain obscured numeric `TextField` (maxLength 4) is the acceptable MVP floor; an on-screen keypad is the prescribed tablet presentation if in scope. Build to `QalamTargets`/`QalamSpace` tokens either way. |

> Both gaps are **logic/crypto and a leaf widget**, not architecture — every structural pattern
> (gate, providers, route, screen shell, accessors, nav wiring, ARB) has an exact or strong in-repo analog.

---

## Metadata

**Analog search scope:** `lib/router/`, `lib/providers/`, `lib/data/`, `lib/screens/`,
`lib/features/`, `lib/models/`, `lib/widgets/`, `lib/theme/`, `lib/l10n/`, `lib/main.dart`,
`test/router/`, `test/providers/`.
**Files scanned:** app_router.dart, profile_providers.dart, progression_providers.dart,
app_database.dart, settings_screen.dart, home_screen.dart, curriculum_repository.dart,
arabic_text.dart, letter.dart, dimens.dart, colors.dart, app_en.arb, main.dart (+ test index).
**Pattern extraction date:** 2026-06-13
**Test analogs:** `test/router/onboarding_gate_test.dart` (gate/route widget test),
`test/providers/progression_providers_test.dart` (Drift-stream provider test, zero manual refresh) —
mirror for the Wave-0 `test/features/parent/` suite (pin_service / pin_cooldown / parent_gate / parent_dashboard).
