# Phase 5: Profiles & Onboarding - Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 12 (7 new, 5 modified/extended)
**Analogs found:** 12 / 12 (every file has a first-party in-repo precedent)

This is a local-only Flutter app: Drift SQLite (schema v2→v3), Riverpod codegen
(`@Riverpod(keepAlive: true)`), GoRouter-as-provider, design tokens in `lib/theme/`.
Every "new" capability has a proven analog already in the repo. The planner should
mirror the idiom exactly; the risk is *deviating*, not the absence of a library.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/data/app_database.dart` (MODIFY: +`ChildProfiles` table, schema v2→v3) | model / migration | CRUD | self (v1→v2 `LetterMastery` block, lines 30-69, 98-124) | exact (same file) |
| `lib/data/child_profile_repository.dart` (NEW) | repository / provider | CRUD | `lib/data/drift_progress_repository.dart` | exact |
| `lib/providers/profile_providers.dart` (NEW: `childProfileProvider`, `OnboardingGate`) | provider / store | request-response | `lib/providers/journey_providers.dart` + `skeletonProof` (app_database.dart:146-155) | exact |
| `lib/features/onboarding/onboarding_data.dart` (NEW: avatar set, nickname set, grade map) | utility / const data | transform (pure lookup) | `_kLetters` const list (journey_screen.dart:37-66) | role-match |
| `lib/features/onboarding/onboarding_screen.dart` (NEW) | screen / widget | request-response | `lib/screens/home_screen.dart` + `lib/features/journey/journey_screen.dart` | exact |
| `lib/features/onboarding/widgets/*.dart` (NEW: grade chips, avatar grid, nickname grid) | widget | event-driven (tap) | `_NavItem`/`_TodaysLessonCard` (home_screen.dart:134-362), `JourneyNodeWidget` | role-match |
| `lib/router/app_router.dart` (MODIFY: +`/onboarding` route, `redirect`, `refreshListenable`) | route / config | request-response | self (documented seam, lines 27-80) | exact (same file) |
| `lib/main.dart` (MODIFY: boot-time gate read + provider overrides) | config / bootstrap | request-response | self (lines 20-24) | exact (same file) |
| `lib/screens/home_screen.dart` (MODIFY: greeting reads profile provider) | screen / widget | request-response | self (`_GreetingHeader`, lines 230-272; `_PersistenceProofReader`, 387-404) | exact (same file) |
| `lib/l10n/app_en.arb` (MODIFY: onboarding strings + `{nickname}` greeting) | config / l10n | transform | self (`homeGreeting`, lines 392-400) | exact (same file) |
| `test/data/child_profile_repository_test.dart` (NEW) | test | CRUD | `test/data/progress_repository_test.dart` | exact |
| `test/data/app_database_test.dart` (EXTEND: v2→v3 migration) | test | CRUD | self + progress_repository_test.dart Test 3 | exact |
| `test/router/onboarding_gate_test.dart` (NEW) | test | request-response | `test/router/demo_routes_test.dart` | role-match |
| `test/features/onboarding/onboarding_screen_test.dart` (NEW) | test | event-driven | `test/screens/home_screen_test.dart` | exact |
| `test/features/onboarding/onboarding_data_test.dart` (NEW) | test | transform | (no direct const-map test analog) | partial |
| `test/screens/home_screen_test.dart` (EXTEND: greeting reads profile) | test | request-response | self | exact (same file) |

---

## Pattern Assignments

### `lib/data/app_database.dart` (model/migration, CRUD) — MODIFY

**Analog:** itself — the `LetterMastery` v1→v2 work is the exact template for `ChildProfiles` v2→v3.

**Table declaration** (copy the `LetterMastery` shape, lines 35-42). Note Drift pluralizes
the generated getter: class `ChildProfiles` → getter `childProfiles`, companion
`ChildProfilesCompanion`.
```dart
// New table — place beside LetterMastery (after line 42).
class ChildProfiles extends Table {
  IntColumn  get id               => integer().autoIncrement()();
  TextColumn get nicknameId       => text()();   // "nick_star" — fixed-set ID, NO real name (S1-03)
  TextColumn get avatarId         => text()();   // "avatar_1".."avatar_6"
  TextColumn get grade            => text()();   // kg|grade1|grade2|grade3|grade4plus
  TextColumn get startingLessonId => text()();   // resolved from grade (default "alif", S1-02)
  IntColumn  get createdAt        => integer()(); // unix epoch ms
}
```

**`@DriftDatabase` + schemaVersion + migration** — current code (lines 44-69):
```dart
@DriftDatabase(tables: [AppSettings, LetterMastery])   // ADD ChildProfiles
class AppDatabase extends _$AppDatabase {
  ...
  @override
  int get schemaVersion => 2;                          // BUMP to 3

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Pitfall 4: guard by version to make the migration idempotent.
          if (from < 2) await m.createTable(letterMastery);
          // ADD: if (from < 3) await m.createTable(childProfiles);
        },
      );
}
```

**Accessors** — mirror `recordMastery`/`isMastered` (lines 98-124). Use
`insertOnConflictUpdate` only where overwrite is intended; profile create is a plain insert:
```dart
Future<bool> hasProfile() async =>
    (await (select(childProfiles)..limit(1)).getSingleOrNull()) != null;

Future<ChildProfile?> getProfile() async =>
    (select(childProfiles)..limit(1)).getSingleOrNull();

Future<int> createProfile({
  required String nicknameId,
  required String avatarId,
  required String grade,
  required String startingLessonId,
}) =>
    into(childProfiles).insert(ChildProfilesCompanion.insert(
      nicknameId: nicknameId,
      avatarId: avatarId,
      grade: grade,
      startingLessonId: startingLessonId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
```

**Constructor / executor ownership is unchanged** (lines 53-77) — tests inject
`NativeDatabase.memory()`; the boot read in `main.dart` injects the production instance via
provider override (Pitfall 7). Do NOT touch `_ownsExecutor`/`close()`.

**Codegen (required after editing the table):**
```bash
dart run build_runner build --delete-conflicting-outputs
```
Regenerates `app_database.g.dart` (committed — `.g.dart` files are git-tracked in this repo).

---

### `lib/data/child_profile_repository.dart` (repository/provider, CRUD) — NEW

**Analog:** `lib/data/drift_progress_repository.dart` (whole file, 38 lines) — copy verbatim and rename.

**Full structure** (mirror lines 7-37 of the analog):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_database.dart';

part 'child_profile_repository.g.dart';   // part directive — Pitfall 5

class ChildProfileRepository {
  const ChildProfileRepository(this._db);
  final AppDatabase _db;

  Future<bool> hasProfile() => _db.hasProfile();
  Future<ChildProfile?> getProfile() => _db.getProfile();
  Future<int> create({
    required String nicknameId,
    required String avatarId,
    required String grade,
    required String startingLessonId,
  }) =>
      _db.createProfile(
        nicknameId: nicknameId, avatarId: avatarId,
        grade: grade, startingLessonId: startingLessonId,
      );
}

@Riverpod(keepAlive: true)   // exact idiom from progressRepository (analog line 35)
ChildProfileRepository childProfileRepository(Ref ref) =>
    ChildProfileRepository(ref.watch(appDatabaseProvider));
```
**Idiom notes:** `Ref ref` is untyped (repo-wide convention, RESEARCH State-of-the-Art row).
`keepAlive: true` matches every repository provider in the repo (`progressRepository`,
`appDatabase`, `mockJourneyProgress`).

---

### `lib/providers/profile_providers.dart` (provider/store, request-response) — NEW

**Analogs:** `lib/providers/journey_providers.dart` (codegen provider file shape, lines 13-29)
+ `skeletonProof` async provider (app_database.dart:146-155).

**Async read provider** (mirror `skeletonProof`'s `@riverpod Future<...>` shape — NOT keepAlive,
so `ref.invalidate` after onboarding forces Home to re-read):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/app_database.dart';
import '../data/child_profile_repository.dart';

part 'profile_providers.g.dart';

@riverpod  // NOT keepAlive — invalidated after the onboarding write
Future<ChildProfile?> childProfile(Ref ref) =>
    ref.watch(childProfileRepositoryProvider).getProfile();
```

**`OnboardingGate` ChangeNotifier + provider** (the `refreshListenable` for the router gate;
seeded at boot via override in main.dart):
```dart
class OnboardingGate extends ChangeNotifier {
  OnboardingGate(this._hasProfile);
  bool _hasProfile;
  bool get hasProfile => _hasProfile;
  void markProfileCreated() { _hasProfile = true; notifyListeners(); }
}

@Riverpod(keepAlive: true)
OnboardingGate onboardingGate(Ref ref) => OnboardingGate(false); // overridden at boot
```
Consumption in UI mirrors `_PersistenceProofReader` (home_screen.dart:387-404):
`ref.watch(childProfileProvider).when(data:…, loading:…, error:…)`.

---

### `lib/features/onboarding/onboarding_data.dart` (utility/const data, transform) — NEW

**Analog:** the `_kLetters` typed-record const list in journey_screen.dart:37-66 (same
`typedef` + `const List<...>` style). Use it for the avatar and nickname sets.

```dart
// MECHANISM only. Real per-grade entry points + final nickname wording are the
// owner's mother's domain — ship placeholders + a loud TODO. Do NOT invent these.

typedef AvatarOption   = ({String id, /* asset/color seam */});
typedef NicknameOption = ({String id, String label}); // label = Arabic-flavored placeholder

const List<String> kAvatarIds = ['avatar_1','avatar_2','avatar_3','avatar_4','avatar_5','avatar_6'];

// TODO(owner's-mother sign-off): finalize the nickname wording. Placeholders only.
const List<NicknameOption> kNicknames = [
  (id: 'nick_star', label: 'نجمة'),  // Najma — "star"
  (id: 'nick_moon', label: 'قمر'),   // Qamar — "moon"
  (id: 'nick_lion', label: 'أسد'),   // Asad — "lion"
  // …~8-10 total
];

// TODO(owner's-mother sign-off): replace 'alif' with real per-grade entry-point ids.
// Default: every grade → lesson 0 (alif) until specified. Mechanism is ours, values are hers.
const Map<String, String> gradeToStartingLessonId = {
  'kg': 'alif', 'grade1': 'alif', 'grade2': 'alif', 'grade3': 'alif', 'grade4plus': 'alif',
};
String resolveStartingLessonId(String grade) => gradeToStartingLessonId[grade] ?? 'alif';
```
**Verified:** `'alif'` is a real letter id (`assets/curriculum/letters.json`). NOTE the
namespace flag from RESEARCH Open-Q1 (letter id `alif` vs lesson id `lesson_01`) — planner
should keep the resolver single-source so a future rename is one edit.
**ID→label / ID→asset stays in code, never in the DB** (labels/art change with no migration).

---

### `lib/features/onboarding/onboarding_screen.dart` (screen/widget, request-response) — NEW

**Analogs:** `lib/screens/home_screen.dart` (chrome, tokens, l10n) + `lib/features/journey/journey_screen.dart`
(`ConsumerWidget` + `ref.watch` + `Scaffold(backgroundColor: QalamColors.bg)`).

**Chrome skeleton** (home_screen.dart:40-76): `Scaffold` → `SafeArea` →
`SingleChildScrollView` → `ConstrainedBox(maxWidth: 720)` → `Column`. App chrome stays **LTR**
(app.dart:5-6 — NO global `Directionality.rtl`; Pitfall 3). Wrap in `PopScope(canPop: false)`
to block Android back (RESEARCH Pattern 4 — `WillPopScope` is deprecated).

**Design tokens (copy semantic names exactly — NEVER raw hex, NEVER `QalamColors.reward`):**
- Background `QalamColors.bg` (parchment); surfaces `QalamColors.surface`; card border
  `QalamColors.border`; primary CTA `QalamColors.primary` (ink-teal). (colors.dart:33-63)
- Spacing/radii/targets: `QalamSpace.*`, `QalamRadii.*` (`.pill`, `.xl`, `.lg`),
  `QalamTargets.targetMin` (44dp+ taps) — see home_screen.dart usages throughout.
- Text: `QalamTextStyles.heading/body/label`.
- Theme extension for shadows: `Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light`
  then `qalam.buttonShadow` (home_screen.dart:285, 344).

**"Let's go" CTA pill** — reuse the verified teal pill (home_screen.dart:340-355):
```dart
final qalam = Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;
DecoratedBox(
  decoration: BoxDecoration(
    color: QalamColors.primary,
    borderRadius: BorderRadius.circular(QalamRadii.pill),
    boxShadow: qalam.buttonShadow,
  ),
  child: /* "Let's go" label + onTap handler */,
);
```

**Arabic nickname labels** render via the `ArabicText` widget (home_screen.dart:31, 314), NOT
raw `Text` and NOT a screen-level `Directionality` (Pitfall 3).

**l10n** with null-safe fallback: `final l10n = AppLocalizations.of(context);` then
`l10n?.someKey ?? 'literal'` (home_screen.dart:38, 257) — the bare test harness passes a null
`AppLocalizations`.

**On submit (the gate flip + navigation sequence):**
```dart
// validate selections ∈ fixed sets, then:
final lessonId = resolveStartingLessonId(grade);
await ref.read(childProfileRepositoryProvider).create(
  nicknameId: …, avatarId: …, grade: grade, startingLessonId: lessonId);
ref.read(onboardingGateProvider).markProfileCreated(); // fires refreshListenable
ref.invalidate(childProfileProvider);                  // Home re-reads
if (context.mounted) context.go('/');
```
**Anti-patterns (RESEARCH):** NO `TextField`/keyboard anywhere (S1-03); NO gold/reward color;
NO global RTL wrap.

---

### `lib/features/onboarding/widgets/*.dart` (widget, event-driven) — NEW

**Analogs:** `_NavItem` (home_screen.dart:134-198) and `_TodaysLessonCard`
(home_screen.dart:278-362) for the tap-affordance + `GestureDetector` pattern;
`JourneyNodeWidget` for a tap-state grid cell.

- **Selectable cell pattern:** `GestureDetector(onTap: …)` → `DecoratedBox`/`Container` with
  `QalamColors.surface` default and `QalamColors.primary`/`primaryTint` selected state.
- Carry a stable `Key` on tappables for widget tests (home_screen.dart:288 —
  `key: const Key('todaysLessonCard')`).
- Grid layout: prefer `Wrap`/`GridView` of fixed cells (6 avatars, ~8-10 nicknames, 5 grade chips).
- Honor `QalamTargets.targetMin` for every tap target (home_screen.dart:166-167).

---

### `lib/router/app_router.dart` (route/config, request-response) — MODIFY

**Analog:** itself — the documented `/parent` redirect seam (lines 69-77) shows exactly where
the guard goes. `appRouter` is already a `@Riverpod(keepAlive: true)` provider (lines 27-28).

**Add the gate** (extend the existing provider; RESEARCH Pattern 3):
```dart
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final gate = ref.watch(onboardingGateProvider);
  return GoRouter(
    initialLocation: kDemoMode ? '/demo/home' : '/',  // keep existing kDemoMode flag (line 24)
    refreshListenable: gate,                            // re-run redirects when gate flips
    redirect: (context, state) {
      if (kDemoMode) return null;                       // demo bypasses the gate
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!gate.hasProfile && !onOnboarding) return '/onboarding';
      if (gate.hasProfile && onOnboarding)  return '/'; // BOTH rules — prevents loop (Pitfall 1)
      return null;
    },
    routes: <RouteBase>[ /* …existing 5 routes + demoRoutes()… */,
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    ],
  );
}
```
**Critical (RESEARCH Pitfall 2):** `redirect` is synchronous — NEVER `await` Drift inside it.
The gate flag is read once at boot.

---

### `lib/main.dart` (config/bootstrap) — MODIFY

**Analog:** itself (lines 20-24). Keep the `ensureInitialized()` + `await lockOrientation()`
ordering; insert the one-time boot read and provider overrides before `runApp` (RESEARCH Pattern 3):
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await lockOrientation();
  final db = AppDatabase();
  final hasProfile = await db.hasProfile();             // one-time boot read
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) { ref.onDispose(db.close); return db; }), // Pitfall 7 — one DB
        onboardingGateProvider.overrideWith((ref) => OnboardingGate(hasProfile)),
      ],
      child: const QalamApp(),
    ),
  );
}
```
(Current `main` wraps `ProviderScope(child: QalamApp())` with no overrides — line 23.)

---

### `lib/screens/home_screen.dart` (screen/widget) — MODIFY

**Analog:** itself. `_GreetingHeader` (lines 230-272) currently hardcodes
`l10n?.homeGreeting ?? 'Welcome back, Layla.'` (line 257). Convert the greeting subtree to read
the profile provider — mirror the scope-aware `_PersistenceProof`/`_PersistenceProofReader`
split (lines 374-404) so the bare test harness (no `ProviderScope`) still renders.

- Make the greeting reader a `ConsumerWidget` watching `childProfileProvider`;
  `.when(data: profile => greeting(profile.nicknameId → label), loading: …, error: …)`
  (pattern: lines 392-403).
- Resolve `nicknameId → label` via the `onboarding_data.dart` map (presentation only).
- Avatar circle in the header area (small circle next to the greeting) — reuse the rounded
  `Container` + `BorderRadius.circular` idiom (e.g. lines 306-315) and the
  `_SafeSvgIcon` graceful fallback (lines 201-224).
- Keep all PLAT-03 invariants (file header lines 11-13): no gold, no counters.

---

### `lib/l10n/app_en.arb` (config/l10n, transform) — MODIFY

**Analog:** itself — every key has a sibling `@key` metadata block with a `description`
(e.g. `homeGreeting`, lines 392-395). Add onboarding keys (grade labels, CTA "Let's go",
nickname labels are placeholder data — they may live as ARB or in `onboarding_data.dart`).
Convert the greeting to a placeholdered template:
```json
"homeGreeting": "Welcome back, {nickname}.",
"@homeGreeting": {
  "description": "Home greeting; nickname is the child's chosen fixed-set display label.",
  "placeholders": { "nickname": { "type": "String" } }
}
```
**Note:** l10n is regenerated by `flutter gen-l10n` / `flutter pub get` / build — NOT by
`build_runner` (RESEARCH Pattern 7).

---

### `test/data/child_profile_repository_test.dart` (test, CRUD) — NEW

**Analog:** `test/data/progress_repository_test.dart` (whole file). Copy the structure:
- `TestWidgetsFlutterBinding.ensureInitialized();` (analog line 22).
- Shared in-memory executor for the restart simulation (analog lines 32-34):
  ```dart
  final shared = DatabaseConnection(NativeDatabase.memory());
  final db1 = AppDatabase(shared.executor);
  // … repo.create(...) → db1.close() → db2 = AppDatabase(shared.executor) → assert survives
  ```
- Test 1: profile round-trips and survives a simulated restart (analog Test 1, lines 27-53).
- Test 2: `resolveStartingLessonId` default = `alif`; persisted `startingLessonId` matches.
- Imports: `package:qalam/data/app_database.dart`, `package:qalam/data/child_profile_repository.dart`.

---

### `test/data/app_database_test.dart` (test, CRUD) — EXTEND

**Analog:** itself + progress_repository_test.dart Test 3 (lines 87-117, the
"existing rows survive the migration" pattern). Add a test that writes an `AppSettings` row
AND a `LetterMastery` row, then asserts a `ChildProfiles` insert works and all three survive a
simulated restart (the v2→v3 "existing rows preserved" invariant, expressed against the real
production migration path — same approach the analog uses for v1→v2).

---

### `test/router/onboarding_gate_test.dart` (test, request-response) — NEW

**Analog:** `test/router/demo_routes_test.dart` (the `MaterialAppHarness` + real `GoRouter` +
`_SentinelError` errorBuilder pattern, lines 14-110). Build a `GoRouter` with the gate's
`redirect` + `refreshListenable: OnboardingGate(...)` and assert:
- no profile → resolves to `/onboarding`;
- profile present → resolves to `/`;
- after `gate.markProfileCreated()` the router moves off `/onboarding` with NO loop (never hits
  the error/`redirectLimit` screen — RESEARCH Pitfall 1). Use a `_SentinelError` errorBuilder
  exactly like the analog to assert "no loop".

---

### `test/features/onboarding/onboarding_screen_test.dart` (test, event-driven) — NEW

**Analog:** `test/screens/home_screen_test.dart` (`ProviderScope` + `MaterialApp.router` harness
with `AppLocalizations.localizationsDelegates`, lines 27-51; tap + finder assertions throughout).
Assert (S1-03 / gate):
- NO free-text widget: `expect(find.byType(TextField), findsNothing)` and
  `find.byType(EditableText)` / `find.byType(TextFormField)` likewise.
- Tapping an avatar + nickname + grade then "Let's go" persists and navigates (find the Home stub
  text after — mirror analog Test 2, lines 95-130).
- `PopScope` present with `canPop:false` (back is blocked).

---

### `test/features/onboarding/onboarding_data_test.dart` (test, transform) — NEW

**Analog:** plain Dart `test(...)` (no widget harness — like the non-widget tests in
demo_routes_test.dart lines 39-58). Assert: `gradeToStartingLessonId` covers every grade option;
default resolves to `alif`; `resolveStartingLessonId('unknown') == 'alif'`; avatar set has 6 IDs;
nickname set has ~8-10 IDs.

---

### `test/screens/home_screen_test.dart` (test, request-response) — EXTEND

**Analog:** itself. The existing Test 1 (lines 62-90) asserts the hardcoded
`'Welcome back, Layla.'`. Update it: pump within a `ProviderScope` that overrides
`childProfileProvider` to return a profile, then assert the greeting shows the chosen nickname
label + avatar. Keep the anti-gamification Test 3 (lines 135-161) unchanged.

---

## Shared Patterns

### Riverpod codegen provider idiom (applies to: repository, providers files)
**Source:** `lib/data/drift_progress_repository.dart:35-37`, `lib/providers/journey_providers.dart:23-29`,
`lib/data/app_database.dart:135-140`.
```dart
part 'this_file.g.dart';        // 1. part directive
@Riverpod(keepAlive: true)      // 2. keepAlive for repos/services; bare @riverpod for invalidatable reads
ReturnType providerName(Ref ref) => …;   // 3. untyped `Ref ref`, camelCase fn → `providerNameProvider`
```
**Build command after editing ANY `@Riverpod`/`@DriftDatabase`/`Table`:**
```bash
dart run build_runner build --delete-conflicting-outputs
```
All `.g.dart` files are git-tracked — regenerate AND commit them (RESEARCH Pitfall 5).

### Drift migration idiom (applies to: app_database.dart + its test)
**Source:** `lib/data/app_database.dart:62-69`. Bump `schemaVersion`, add a version-guarded
`if (from < N) await m.createTable(x);` line — never delete-on-upgrade, never manual `ALTER`.
Tests use a shared `NativeDatabase.memory()` executor and a "close then re-open" restart sim
(`test/data/progress_repository_test.dart:32-51`).

### Design tokens (applies to: onboarding screen + widgets + home edit)
**Source:** `lib/theme/colors.dart` (`QalamColors.*`), `lib/theme/dimens.dart`
(`QalamSpace/QalamRadii/QalamTargets`), `lib/theme/text_styles.dart` (`QalamTextStyles.*`),
`lib/theme/brand_theme_ext.dart` (`QalamTheme`/`buttonShadow`).
**Rules:** semantic tokens only (never raw hex, colors.dart:30); `QalamColors.bg` parchment
background; `QalamColors.primary` ink-teal CTA; **NEVER `QalamColors.reward`** on a non-reward
screen (PLAT-03). Tap targets ≥ `QalamTargets.targetMin`.

### LTR chrome + per-content Arabic (applies to: onboarding screen, home edit)
**Source:** `lib/app.dart:5-6, 26` (no global `Directionality.rtl`; `supportedLocales` is
English-only). Arabic glyphs/labels render through the `ArabicText` widget
(`lib/widgets/arabic_text.dart`, used at home_screen.dart:31, 314), NOT a screen-level RTL wrap.

### Null-safe l10n (applies to: onboarding screen, home edit, all screen tests)
**Source:** `home_screen.dart:38, 257`. `final l10n = AppLocalizations.of(context);` then
`l10n?.key ?? 'literal fallback'` — the bare-MaterialApp test harness passes a null
`AppLocalizations`.

### Scope-aware provider read (applies to: home greeting edit)
**Source:** `home_screen.dart:374-404` — split a `StatelessWidget` (checks for an ancestor
`UncontrolledProviderScope`, degrades to `SizedBox.shrink()` if absent) from a `ConsumerWidget`
that does the `ref.watch(...).when(...)`. Reuse this so the bare D-05 direction test still renders.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `test/features/onboarding/onboarding_data_test.dart` | test | transform | No existing pure-const-map unit test in the repo; use the plain (non-widget) `test(...)` style from demo_routes_test.dart:39-58. Trivial — minor gap only. |

All other files have a direct, verified in-repo precedent.

---

## Metadata

**Analog search scope:** `lib/data/`, `lib/providers/`, `lib/features/journey/`, `lib/screens/`,
`lib/router/`, `lib/theme/`, `lib/l10n/`, `lib/app.dart`, `lib/main.dart`, `test/data/`,
`test/router/`, `test/screens/`.
**Files read (analogs):** `app_database.dart`, `drift_progress_repository.dart`, `app_router.dart`,
`home_screen.dart`, `main.dart`, `app.dart`, `journey_screen.dart`, `journey_providers.dart`,
`colors.dart`, `app_en.arb`, `app_database_test.dart`, `progress_repository_test.dart`,
`demo_routes_test.dart`, `home_screen_test.dart`.
**Pattern extraction date:** 2026-06-08
