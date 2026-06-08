# Phase 5: Profiles & Onboarding - Research

**Researched:** 2026-06-08
**Domain:** Flutter local persistence (Drift) + Riverpod codegen + GoRouter async-gate + child-friendly onboarding UI (RTL-aware)
**Confidence:** HIGH (codebase patterns are first-party and verified; framework APIs confirmed against pub.dev docs)

## Summary

This phase adds one `ChildProfile` Drift table to the existing `AppDatabase` (schema v2 → v3),
exposes it through the project's established `@Riverpod(keepAlive: true)` codegen idiom, and
gates the app at startup: if no profile row exists, GoRouter redirects to a new `/onboarding`
route. Onboarding is a single scrollable card (grade chips → avatar grid → nickname grid → one
"Let's go" CTA) with **no free-text input** (S1-03). On submit it resolves `grade →
startingLessonId` via a single lookup map (default all → `alif`, S1-02), writes the row, and
`context.go('/')` to Home. The Home greeting then reads the chosen nickname from a profile
provider instead of the hardcoded "Welcome back, Layla."

Every piece has a direct in-repo precedent: the `LetterMastery` v1→v2 migration is the exact
template for the v2→v3 migration; `DriftProgressRepository` is the template for the new
`ChildProfileRepository`; `appRouterProvider` is the router seam (it already documents where a
`redirect` guard goes); `home_screen.dart` is the structural analog for the onboarding screen
(parchment/teal, Fredoka/Nunito, l10n with `?? 'fallback'`, no gold). The only genuinely new
mechanic is the **async redirect gate** — solved with a synchronous cached value + a `Listenable`
on `refreshListenable`, never an `await` inside the `redirect` callback.

**Primary recommendation:** Mirror the existing Drift + Riverpod-codegen + GoRouter idioms exactly.
Bump `schemaVersion` to 3, add `if (from < 3) await m.createTable(childProfiles);`, expose a
`ChildProfileRepository` provider, gate via a **synchronous cached profile-existence flag** read
inside `redirect` (loaded once at boot before `runApp`), and block back navigation on onboarding
with `PopScope(canPop: false)`. Ship placeholder avatar/nickname sets flagged for the owner's
mother's sign-off — do not invent final pedagogy/wording.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Onboarding gate:** one-time, on first launch (no profile in local DB). Block at the app launch
  route — child cannot reach Home until a profile exists. Guard checks Drift on startup, redirects
  to `/onboarding` if absent. **No multi-profile** in this phase.
- **Screen layout:** ONE combined screen, ONE scrollable card. Fields in order: (1) Grade chip
  selector, (2) Avatar grid picker, (3) Nickname fixed-set picker. **No free-text input anywhere
  (S1-03)** — no keyboard, all taps. Single **"Let's go"** CTA saves + navigates to Home. **No
  skip.**
- **Avatar set:** 6 avatars, simple illustrated diverse kids (not animals, not mascot variants).
  Launch = placeholder colored circles with initials/geometric shapes; real art is an asset swap,
  no code change. Stored as ID string `"avatar_1"`..`"avatar_6"`; widget maps ID → asset.
- **Nickname set (S1-03):** fixed set, ~8–10 child-friendly nicknames, tapped like the avatar grid.
  No free-text. Chosen nickname is the display identity (shown on Home); no real name ever stored.
  **Voice is the owner's domain** — ship a PLACEHOLDER set (Arabic-flavored, e.g. نجمة Najma,
  قمر Qamar, أسد Asad) and flag clearly for the owner's mother's sign-off. Stored as ID string
  `"nick_star"`; widget maps ID → display label (label can change with no data migration).
- **Grade → curriculum entry point (S1-02):** Options KG · Grade 1 · Grade 2 · Grade 3 · Grade 4+.
  Grade maps to a starting lesson via a structural `grade → startingLessonId` lookup map.
  **Mechanism is ours; the actual per-grade values are the owner's mother's domain.** Default:
  ALL grades → `alif` (lesson 0) with a clear single-source seam + TODO. Resolved value stored on
  the profile as `startingLessonId` so Phase 6 reads it directly.
- **Authentication explicitly deferred** to Phase 9 (Firebase / parent area). No sign-up/sign-in/
  accounts in Phase 5. **Migration intent:** the local `ChildProfile` row must be *claimable* by a
  parent account in Phase 9 — design so the local profile is adopted, not discarded.
- **Routing:** new `/onboarding` route. On start: no profile → `/onboarding`; profile → `/` (Home).
  After submit → `context.go('/')`. No back navigation from onboarding (`PopScope`/`WillPopScope`).
- **Home integration:** Home greeting reads the saved nickname's display label from the profile
  provider; replace hardcoded `"Welcome back, Layla."`. Avatar shown in greeting header (small circle).

### Claude's Discretion

- Internal structure of the new feature folder, repository method names, the avatar/nickname
  ID→asset and ID→label mapping mechanism, the exact placeholder visuals, the chip/grid widget
  implementations, the async-redirect implementation strategy.
- Where the `grade → startingLessonId` map physically lives (this research recommends one location).

### Deferred Ideas (OUT OF SCOPE)

- Multi-child profiles (Phase 9). Parent PIN / parent-gated profile editing. Firebase sync of the
  profile. **Real per-grade entry-point values** (owner's mother — Phase 5 ships mechanism, all →
  alif). **Final nickname wording** (owner's mother — Phase 5 ships placeholders). Real illustrated
  avatar art (non-code asset swap). Onboarding analytics / funnel tracking.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **S1-02** | Parent creates a child profile with grade; grade selects the curriculum entry point. *Accept: persists locally; grade maps to a starting lesson; no real-name exposure beyond device.* | `ChildProfiles` Drift table (`grade`, `startingLessonId` columns) + a `gradeToStartingLessonId` map (default all → `alif`, a real letters.json id). Persistence mirrors the verified `LetterMastery` pattern. No real name is ever stored (nickname is a fixed-set ID). |
| **S1-03** | Child picks an avatar and nickname on first open. *Accept: persists; choices from a fixed set (no free-text); shown on home screen.* | Fixed `avatar_1..6` + `nick_*` ID sets stored as TEXT; tap-only grid pickers (no `TextField`, no keyboard); Home greeting reads the nickname label + avatar from the profile provider. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Persist the child profile | Database / Storage (Drift) | — | Local SQLite is the only datastore; mirrors `LetterMastery`. No network/Firebase this phase. |
| Profile-existence startup gate | Frontend (GoRouter `redirect`) | Storage (read once at boot) | Routing tier owns redirect logic; it reads a synchronously-cached value seeded from Drift before `runApp`. |
| Grade → startingLessonId resolution | App logic (pure Dart map) | Storage (writes resolved value) | Pure structural lookup; resolved value persisted so Phase 6 reads it directly. |
| Avatar/nickname ID → asset/label mapping | UI (presentation map) | — | Keeps display concerns out of the DB; label/art can change with no migration. |
| Onboarding form + CTA | UI (widget) | State (Riverpod form controller) | Standard Flutter screen; matches `home_screen.dart` structure. |
| Home greeting (nickname + avatar) | UI (widget) | State (profile provider) | Replaces hardcoded greeting by watching the profile provider. |

## Standard Stack

All dependencies are **already in `pubspec.yaml`** — this phase adds **no new packages**.

### Core
| Library | Version (verified in pubspec) | Purpose | Why Standard |
|---------|-------------------------------|---------|--------------|
| `drift` | `^2.31.0` | Local SQLite table + migration | Project's decided persistence (D-09); `AppDatabase` already exists. [VERIFIED: pubspec.yaml] |
| `flutter_riverpod` | `^3.3.1` | State management | Riverpod-only (D-11; CLAUDE.md forbids BLoC/GetX). [VERIFIED: pubspec.yaml] |
| `riverpod_annotation` | `^4.0.2` | `@Riverpod` codegen annotations | Every provider in the repo uses this. [VERIFIED: pubspec.yaml] |
| `go_router` | `^17.2.3` | Declarative routing + redirect gate | Router already a Riverpod provider (D-08). [VERIFIED: pubspec.yaml] |
| `flutter` gen-l10n | SDK | User-facing strings | `l10n.yaml` configured, English-only template `app_en.arb`. [VERIFIED: l10n.yaml] |

### Supporting (dev — already present)
| Library | Version | Purpose |
|---------|---------|---------|
| `build_runner` | `^2.15.0` | Drives Drift + Riverpod codegen | [VERIFIED: pubspec.yaml] |
| `riverpod_generator` | `^4.0.3` | Riverpod codegen | [VERIFIED: pubspec.yaml] |
| `drift_dev` | `^2.31.0` | Drift codegen (kept aligned with `drift`) | [VERIFIED: pubspec.yaml] |
| `riverpod_lint` | `^3.1.3` | Lint (via `analysis_server_plugin`, not custom_lint) | [VERIFIED: pubspec.yaml] |

**Installation:** None. `flutter pub get` already satisfied.

> **Version pin warning (from STATE.md / pubspec note):** `drift`/`drift_dev` are intentionally held
> at the `2.31` line. `drift_dev 2.32+/2.33` require `analyzer >=10`, which conflicts with
> `riverpod_lint 3.1.3` (analyzer `^9`) on the installed Flutter 3.41.9. **Do NOT bump drift.** Stay
> on `2.31.x`. [VERIFIED: pubspec.yaml comment + STATE.md]

## Package Legitimacy Audit

No new external packages are installed in this phase. All libraries are pre-existing, first-party-
verified entries in `pubspec.yaml` from Phase 1. Slopcheck not required.

| Package | Registry | Disposition |
|---------|----------|-------------|
| (none added) | — | N/A — phase adds no dependencies |

## Architecture Patterns

### System Architecture Diagram

```
App boot (main.dart)
  │  WidgetsFlutterBinding.ensureInitialized()
  │  await lockOrientation()
  │  ┌─────────────────────────────────────────────┐
  │  │ NEW: open DB once, read "does a profile      │
  │  │ exist?" into a synchronous bootstrap value    │
  │  │ (override a provider OR a ChangeNotifier seed) │
  │  └─────────────────────────────────────────────┘
  ▼
ProviderScope → QalamApp (MaterialApp.router)
  │  ref.watch(appRouterProvider)
  ▼
GoRouter
  │  top-level redirect(context, state):
  │    final hasProfile = <sync cached flag>   ← never awaits here
  │    if (!hasProfile && loc != '/onboarding') return '/onboarding';
  │    if ( hasProfile && loc == '/onboarding') return '/';        ← prevents loop
  │    return null;
  │  refreshListenable: <Listenable that fires when hasProfile flips>
  │
  ├── no profile ──► /onboarding ──┐
  │                                 │  OnboardingScreen (PopScope canPop:false)
  │                                 │   ┌ Grade chips ──┐
  │                                 │   ├ Avatar grid   ├─ one scrollable card
  │                                 │   ├ Nickname grid ┘
  │                                 │   └ "Let's go" CTA
  │                                 │        │ resolve grade→startingLessonId (map, default alif)
  │                                 │        │ ChildProfileRepository.create(...)  → Drift INSERT
  │                                 │        │ flip cached flag → refreshListenable fires
  │                                 │        ▼ context.go('/')
  └── profile exists ──► / (Home) ◄─┘
        │  HomeScreen watches childProfileProvider
        │  greeting = nickname label (was hardcoded "Layla")
        ▼  avatar circle from avatarId → asset map
```

### Recommended Project Structure
Follow the existing `lib/features/<feature>/` + `lib/data/` + `lib/providers/` split:
```
lib/
├── data/
│   ├── app_database.dart            # ADD ChildProfiles table + accessors; bump schema to 3
│   └── child_profile_repository.dart # NEW — mirrors drift_progress_repository.dart
├── models/
│   └── child_profile.dart           # OPTIONAL pure domain type (or use Drift row class directly)
├── providers/
│   └── profile_providers.dart       # NEW — childProfileProvider (+ hasProfile gate value)
├── features/
│   └── onboarding/
│       ├── onboarding_screen.dart   # NEW — the single combined card
│       ├── onboarding_data.dart     # NEW — avatar set, nickname set, gradeToStartingLessonId map
│       └── widgets/                  # grade chips, avatar grid, nickname grid
├── router/
│   └── app_router.dart              # ADD /onboarding route + redirect + refreshListenable
└── screens/
    └── home_screen.dart             # EDIT greeting to read profile provider
```

### Pattern 1: Drift table + migration (v2 → v3)
**What:** Add a new table and bump the schema version with a guarded `onUpgrade`.
**When to use:** Adding `ChildProfiles` to the existing `AppDatabase`.
**The exact in-repo precedent** — `lib/data/app_database.dart` added `LetterMastery` at v1→v2:
```dart
// Source: lib/data/app_database.dart (LetterMastery + migration — VERIFIED in repo)
@DriftDatabase(tables: [AppSettings, LetterMastery])   // ADD ChildProfiles here
class AppDatabase extends _$AppDatabase {
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
New table (matches CONTEXT data model; note Drift pluralizes the getter → `childProfiles`):
```dart
class ChildProfiles extends Table {
  IntColumn    get id               => integer().autoIncrement()();
  TextColumn   get nicknameId       => text()();   // "nick_star" — no real name (S1-03)
  TextColumn   get avatarId         => text()();   // "avatar_1".."avatar_6"
  TextColumn   get grade            => text()();   // kg|grade1|grade2|grade3|grade4plus
  TextColumn   get startingLessonId => text()();   // resolved from grade (default "alif", S1-02)
  IntColumn    get createdAt        => integer()(); // unix epoch ms
}
```
Accessors mirror the verified `recordMastery`/`isMastered`/`getSetting` style on `AppDatabase`:
```dart
Future<bool> hasProfile() async =>
    (await (select(childProfiles)..limit(1)).getSingleOrNull()) != null;

Future<ChildProfile?> getProfile() async =>
    (select(childProfiles)..limit(1)).getSingleOrNull();

Future<int> createProfile(ChildProfilesCompanion entry) =>
    into(childProfiles).insert(entry);
```
**Codegen command (required after editing the table):**
```bash
dart run build_runner build --delete-conflicting-outputs
```
This regenerates `app_database.g.dart` AND any new `*.g.dart` for codegen providers. `*.g.dart`
files ARE committed in this repo (`app_database.g.dart`, `*_providers.g.dart` are tracked).

### Pattern 2: Riverpod codegen provider (the canonical repo idiom)
**What:** A keep-alive provider exposing a repository/value, generated by `riverpod_generator`.
**Example** — the verified pattern from `lib/data/drift_progress_repository.dart`:
```dart
// Source: lib/data/drift_progress_repository.dart (VERIFIED in repo)
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_database.dart';
part 'child_profile_repository.g.dart';   // note the part directive

class ChildProfileRepository {
  const ChildProfileRepository(this._db);
  final AppDatabase _db;

  Future<bool> hasProfile() => _db.hasProfile();
  Future<ChildProfile?> getProfile() => _db.getProfile();
  Future<int> create({/* nicknameId, avatarId, grade, startingLessonId */}) =>
      _db.createProfile(/* …Companion… */);
}

@Riverpod(keepAlive: true)
ChildProfileRepository childProfileRepository(Ref ref) =>
    ChildProfileRepository(ref.watch(appDatabaseProvider));
```
For reading the profile in the UI (Home greeting), an async provider mirrors `skeletonProof`:
```dart
@riverpod  // NOT keepAlive — invalidate after onboarding writes so Home re-reads
Future<ChildProfile?> childProfile(Ref ref) =>
    ref.watch(childProfileRepositoryProvider).getProfile();
```
On submit, after the insert: `ref.invalidate(childProfileProvider);` so Home's `ref.watch`
re-fetches the new row.

### Pattern 3: GoRouter async startup gate — the recommended approach
**What:** Redirect to `/onboarding` when no profile exists, without `await` inside `redirect`.

**Critical constraint (verified):** GoRouter's `redirect` callback is **synchronous** —
`String? Function(BuildContext, GoRouterState)`. You cannot `await` a Drift query inside it.
`refreshListenable` accepts a `Listenable?` and re-runs all redirects when it fires.
`redirectLimit` defaults to 5; a redirect loop throws an error screen. [CITED: pub.dev go_router 17.x — Redirection topic + GoRouter constructor]

**Recommended strategy (simplest, avoids loops and loading flicker):** seed a synchronous
boolean *before* `runApp`, then keep it current via a small `ChangeNotifier`.

```dart
// main.dart — read the gate value ONCE before the app paints (no flicker, no async redirect)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await lockOrientation();
  final db = AppDatabase();
  final hasProfile = await db.hasProfile();          // one-time boot read
  runApp(
    ProviderScope(
      overrides: [
        // reuse the same db instance the provider would have created
        appDatabaseProvider.overrideWith((ref) { ref.onDispose(db.close); return db; }),
        onboardingGateProvider.overrideWith((ref) => OnboardingGate(hasProfile)),
      ],
      child: const QalamApp(),
    ),
  );
}
```
```dart
// OnboardingGate is a ChangeNotifier so it can be the router's refreshListenable
class OnboardingGate extends ChangeNotifier {
  OnboardingGate(this._hasProfile);
  bool _hasProfile;
  bool get hasProfile => _hasProfile;
  void markProfileCreated() { _hasProfile = true; notifyListeners(); } // flips → router re-runs
}
```
```dart
// app_router.dart — the redirect + refreshListenable wiring (extends the existing provider)
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final gate = ref.watch(onboardingGateProvider);
  return GoRouter(
    initialLocation: kDemoMode ? '/demo/home' : '/',
    refreshListenable: gate,                              // re-run redirects when gate flips
    redirect: (context, state) {
      if (kDemoMode) return null;                         // demo bypasses the gate
      final loc = state.matchedLocation;
      final onOnboarding = loc == '/onboarding';
      if (!gate.hasProfile && !onOnboarding) return '/onboarding';
      if (gate.hasProfile && onOnboarding)  return '/';   // ← prevents redirect loop
      return null;
    },
    routes: [ /* …existing… */,
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    ],
  );
}
```
On "Let's go": write the row, then `ref.read(onboardingGateProvider).markProfileCreated();`
followed by `context.go('/')`. The listenable fire + the explicit `go` both land on Home, and the
`hasProfile && onOnboarding → '/'` rule guarantees no oscillation.

> **Why not `await` in redirect / `AsyncValue` in redirect?** GoRouter redirect is sync; reading an
> unresolved `AsyncValue` there forces a "loading route" dance and risks loops. The boot-time read
> is simpler, has zero loading flicker, and the data is tiny (one row existence check). This is the
> recommended pattern for a single-profile local gate.

### Pattern 4: Block Android back on onboarding — PopScope (current API)
**What:** Prevent the child from backing out of onboarding (button + gesture).
**Confirmed:** `WillPopScope` is **deprecated**; use `PopScope` (Flutter 3.12+, current). [CITED: Flutter API — PopScope replaces WillPopScope]
```dart
PopScope(
  canPop: false,                 // blocks Android back button AND the predictive-back gesture
  child: Scaffold(/* onboarding card */),
);
```
Set `canPop: false` unconditionally on the onboarding route — there is intentionally no escape
(CONTEXT: "No skip option").

### Pattern 5: grade → startingLessonId map (single source, S1-02)
**What:** The structural lookup. **Single best location:** `lib/features/onboarding/onboarding_data.dart`
(co-located with the avatar/nickname sets it sits beside). Keep it a plain `const` map with a loud TODO.
```dart
// onboarding_data.dart — MECHANISM only. Real per-grade values are the owner's mother's domain.
// TODO(owner's-mother sign-off): replace 'alif' with the real per-grade entry-point letter ids.
// Default: every grade starts at lesson 0 (alif) until specified. Do NOT invent these.
const Map<String, String> gradeToStartingLessonId = {
  'kg':        'alif',
  'grade1':    'alif',
  'grade2':    'alif',
  'grade3':    'alif',
  'grade4plus':'alif',
};
String resolveStartingLessonId(String grade) =>
    gradeToStartingLessonId[grade] ?? 'alif';
```
**Verified:** `'alif'` is a real letter id — `assets/curriculum/letters.json` defines
`{"id": "alif", …}` and `CurriculumRepository.getLetter('alif')` resolves it. Lessons use a
**separate** id namespace (`"lesson_01"` in `lessons.json`). The column is named `startingLessonId`
but CONTEXT seeds it with a **letter** id (`alif`); confirm with the planner whether the resolved
value should be a `letterId` (`alif`) or a `lessonId` (`lesson_01`). The single lesson currently
authored (`lesson_01`) contains `{"type":"letter","ref":"alif"}`, so `alif` is unambiguous for now —
flag the naming for Phase 6 alignment. [VERIFIED: assets/curriculum/letters.json, lessons.json]

### Pattern 6: Screen structure + design tokens (analog = home_screen.dart)
**What:** Build onboarding with the exact same chrome the rest of the app uses.
Key conventions verified in `lib/screens/home_screen.dart`:
- `Scaffold` → `SafeArea` → content (default LTR chrome; RTL is per-content via `ArabicText`, **not**
  a global `Directionality` — see Pitfall below).
- Spacing/radii/targets via `QalamSpace.*`, `QalamRadii.*`, `QalamTargets.targetMin` (44dp+ taps).
- Colors via semantic `QalamColors.*` only — **never** gold (`QalamColors.reward`) on a non-reward
  screen (PLAT-03 anti-gamification). Background is `QalamColors.bg` (parchment), surfaces
  `QalamColors.surface`, primary CTA `QalamColors.primary` (ink-teal).
- Text via `QalamTextStyles.heading/body/label`.
- l10n with null-safe fallback: `l10n?.someKey ?? 'literal'` (the bare-MaterialApp test harness
  passes a null `AppLocalizations`).
- Arabic strings (nickname labels like نجمة) rendered via the `ArabicText` widget, not raw `Text`.

**CTA shape** (reuse the verified teal pill from `_TodaysLessonCard`):
```dart
// Source: lib/screens/home_screen.dart (forward-arrow CTA — VERIFIED)
final qalam = Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;
DecoratedBox(
  decoration: BoxDecoration(
    color: QalamColors.primary,
    borderRadius: BorderRadius.circular(QalamRadii.pill),
    boxShadow: qalam.buttonShadow,
  ),
  child: /* "Let's go" label */,
);
```

### Pattern 7: New l10n strings
Add onboarding keys to `lib/l10n/app_en.arb` (each needs an `@key` metadata block with a
`description`, matching the file's convention). Then `dart run build_runner build` is **not** what
regenerates l10n — gen-l10n runs automatically on `flutter pub get` / build, or `flutter gen-l10n`.
Strings: grade labels (KG/Grade 1…), nickname display labels (placeholder, flagged for owner),
the "Let's go" CTA, and the new greeting template (e.g. `"Welcome back, {nickname}."` with a
`String` placeholder). [VERIFIED: lib/l10n/app_en.arb conventions + l10n.yaml]

### Anti-Patterns to Avoid
- **`await` inside GoRouter `redirect`.** It's a synchronous callback — read a cached flag instead.
- **A global `Directionality.rtl` to render Arabic nicknames.** The app is deliberately LTR chrome;
  RTL is per-content via `ArabicText` (D-05, Pitfall 4 in app.dart). Wrapping the whole screen RTL
  would mirror the entire layout.
- **Any `TextField`/keyboard for nickname or name.** S1-03 forbids free-text. All taps.
- **Gold/reward color on the onboarding screen.** PLAT-03 — no gamification chrome.
- **Inventing per-grade entry points or final nickname wording.** Ship placeholders + a TODO; the
  owner's mother signs off (CLAUDE.md: "Do not invent the pedagogy; structure it").
- **Bumping `drift`/`drift_dev` past 2.31.** Breaks analyzer alignment with `riverpod_lint`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema migration | Manual `ALTER TABLE` strings / DB delete-on-upgrade | Drift `MigrationStrategy.onUpgrade` + `m.createTable` (existing pattern) | Idempotent, versioned, already proven by the v1→v2 LetterMastery migration |
| Re-running the route guard when profile is created | Manual navigation hacks / polling | `refreshListenable` (a `ChangeNotifier`) | Built into GoRouter; one `notifyListeners()` re-evaluates the gate |
| Blocking Android back | Intercepting raw key events | `PopScope(canPop: false)` | Current Flutter API; handles button + predictive-back gesture |
| Persisting the profile | SharedPreferences / a JSON file | The existing Drift `AppDatabase` | One datastore (D-09); claimable in Phase 9; consistent with LetterMastery |
| ID → label / asset mapping | Storing labels/paths in the DB | A `const` map in `onboarding_data.dart` | Labels/art change with no data migration (CONTEXT requirement) |

**Key insight:** Every "new" capability here already has a first-party precedent in this repo. The
risk is *deviating* from the idiom, not the absence of a library.

## Runtime State Inventory

This phase is **additive** (new table, new screen) — not a rename/refactor. But it touches startup
flow and existing screens, so:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | New `ChildProfiles` table only. No existing rows reference profile data. | Migration adds the table (code). No data migration of existing rows. |
| Live service config | None — local-only, no external services. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | None — no auth, no keys this phase. | None. |
| Build artifacts | `app_database.g.dart` regenerates after the table edit; new `*_repository.g.dart` / `*_providers.g.dart` generated. All `.g.dart` are git-tracked. | Run `dart run build_runner build --delete-conflicting-outputs`; commit regenerated files. |
| Existing screen edits | `home_screen.dart` hardcodes `"Welcome back, Layla."` (line ~257) via `l10n?.homeGreeting`. `app_router.dart` has a documented seam for a `redirect` guard (lines ~69–77). | Edit Home to watch the profile provider; extend the router with `/onboarding` + redirect. |
| l10n | `homeGreeting` is a static string; needs to become a templated greeting OR be read from the profile at the widget level. | Add new ARB keys; decide static-vs-template (recommend reading the nickname label in the widget and using a `{nickname}` placeholder). |

## Common Pitfalls

### Pitfall 1: Redirect loop / blank screen on startup
**What goes wrong:** The redirect sends `/` → `/onboarding` forever, or after creating a profile the
app bounces between `/onboarding` and `/`. Hits `redirectLimit` (5) → error screen.
**Why it happens:** Missing the reverse rule (`hasProfile && onOnboarding → '/'`), or the gate flag
never flips because the `Listenable` didn't fire.
**How to avoid:** Implement BOTH rules (Pattern 3) and call `markProfileCreated()` (which
`notifyListeners()`) on submit. Always return `null` when already on the correct route.
**Warning signs:** "Too many redirects" error; onboarding flashes after pressing "Let's go".

### Pitfall 2: `await` in redirect / loading flicker
**What goes wrong:** Trying to query Drift inside `redirect` (it's sync) or watching an unresolved
`AsyncValue`, causing a blank/loading frame or a thrown error.
**Why it happens:** Assuming `redirect` can be async.
**How to avoid:** Read `hasProfile` once before `runApp` (Pattern 3); keep it in a `ChangeNotifier`.

### Pitfall 3: Global RTL mirrors the whole onboarding layout
**What goes wrong:** Wrapping the screen in `Directionality(textDirection: rtl)` to show Arabic
nickname labels flips the entire layout (grade chips, CTA, grid).
**Why it happens:** Treating RTL as a screen-level concern.
**How to avoid:** Chrome stays LTR (matches `app.dart` D-05). Render only the Arabic label glyphs via
`ArabicText`; the surrounding card stays LTR. [VERIFIED: lib/app.dart comment, ArabicText usage]

### Pitfall 4: Drift getter pluralization / companion mismatch
**What goes wrong:** Referencing `childProfile` (singular) when Drift generates `childProfiles`
(plural), or building the row without the generated `ChildProfilesCompanion`.
**Why it happens:** Drift derives the accessor name from the table class.
**How to avoid:** After `build_runner`, use the generated `childProfiles` table getter and
`ChildProfilesCompanion.insert(...)` exactly as `LetterMasteryCompanion.insert` is used today.

### Pitfall 5: build_runner not run / stale .g.dart committed
**What goes wrong:** New providers/tables don't compile; `appDatabaseProvider`-style symbols missing.
**Why it happens:** Forgetting codegen after editing annotated classes.
**How to avoid:** Run `dart run build_runner build --delete-conflicting-outputs` after every edit to
a `@DriftDatabase`, `@Riverpod`, or table class; commit the regenerated `.g.dart`.

### Pitfall 6: Storing a real name (S1-03 violation)
**What goes wrong:** Adding a `name` column or a `TextField` "what's your name?".
**Why it happens:** Habit / earlier discuss-phase draft (explicitly reconciled away).
**How to avoid:** Only `nicknameId`/`avatarId` (fixed-set IDs) + `grade` + `startingLessonId` +
`createdAt`. No free-text, ever. The nickname *label* is presentation-only.

### Pitfall 7: AppDatabase opened twice at boot
**What goes wrong:** `main()` opens its own `AppDatabase` for the boot read, and the
`appDatabaseProvider` opens a second one over the same file.
**Why it happens:** Not overriding the provider with the boot instance.
**How to avoid:** Override `appDatabaseProvider` with the instance created in `main()` (Pattern 3),
and let the provider own its disposal (`ref.onDispose(db.close)`). The existing `close()` already
handles injected-vs-owned executors. [VERIFIED: lib/data/app_database.dart `_ownsExecutor` logic]

## Code Examples

(See Patterns 1–7 above — all examples are sourced from verified in-repo files:
`lib/data/app_database.dart`, `lib/data/drift_progress_repository.dart`, `lib/router/app_router.dart`,
`lib/screens/home_screen.dart`, `lib/l10n/app_en.arb`, and pub.dev go_router 17.x docs.)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `WillPopScope` | `PopScope` (`canPop` + `onPopInvokedWithResult`) | Flutter 3.12 / 3.24 | Use `PopScope(canPop: false)` to block back. [CITED: Flutter API] |
| `riverpod_annotation` `@riverpod` with `AutoDisposeRef`/typed `Ref` | Untyped `Ref ref` parameter (as used across this repo) | riverpod 3.x | Match the repo: `@Riverpod(...) Foo fooName(Ref ref)`. [VERIFIED: repo providers] |

**Deprecated/outdated:**
- `WillPopScope` — replaced by `PopScope`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Placeholder nickname set (Najma/Qamar/Asad-style) is acceptable for Phase 5 pending the owner's mother's sign-off. | User Constraints / Pattern 5 | Low — CONTEXT explicitly authorizes placeholders + flag; wording is non-final by design. |
| A2 | `startingLessonId` should hold a **letter** id (`alif`) not a lesson id (`lesson_01`) in Phase 5, since the only lesson points at `alif`. | Pattern 5 | Medium — Phase 6 consumes this; planner should confirm the intended namespace. Flagged. |
| A3 | The boot-time synchronous gate read (vs async-in-redirect) is the preferred implementation. | Pattern 3 | Low — CONTEXT marks the implementation strategy as Claude's discretion; this is the simpler, loop-safe option. Planner may choose an alternative. |
| A4 | Real avatar art is a pure asset swap (placeholder IDs `avatar_1..6` are stable). | User Constraints | Low — CONTEXT states this explicitly. |

## Open Questions

1. **`startingLessonId` namespace (letter id vs lesson id).**
   - What we know: `letters.json` uses `alif`; `lessons.json` uses `lesson_01`; CONTEXT seeds the
     column with `alif`. The one authored lesson points at `alif`.
   - What's unclear: Whether Phase 6 expects to look this value up as a letter id or a lesson id.
   - Recommendation: Store `alif` (letter id) per CONTEXT; add a code comment + flag for Phase 6 to
     confirm. Keep the resolver in one place so a later rename is one edit.

2. **Greeting: static l10n string vs `{nickname}` placeholder.**
   - What we know: `homeGreeting` is currently a fixed string with a literal name.
   - What's unclear: Whether to localize a template or compose in the widget.
   - Recommendation: Add a `{nickname}` placeholder ARB key and compose in the widget (nickname
     comes from the profile provider, label from the ID→label map). Keep a literal fallback.

## Environment Availability

No new external tools/services. Codegen toolchain is already installed (build_runner, drift_dev,
riverpod_generator — all in pubspec). Only command needed:

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `dart run build_runner` | Drift + Riverpod codegen | ✓ (in dev_deps) | build_runner ^2.15.0 | — |
| `flutter gen-l10n` | New ARB strings | ✓ (SDK + l10n.yaml) | SDK | runs on build |

## Validation Architecture

`nyquist_validation` is `true` in config → this section applies.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter SDK) + `ProviderScope` for Riverpod; goldens via `flutter_test_config.dart` |
| Config file | `test/flutter_test_config.dart` (loads bundled TTFs for Arabic goldens) |
| Quick run command | `flutter test test/data/child_profile_repository_test.dart` |
| Full suite command | `flutter test` |

Existing precedents to mirror: `test/data/app_database_test.dart` and
`test/data/progress_repository_test.dart` (use `NativeDatabase.memory()` injected into
`AppDatabase` — the constructor accepts a `QueryExecutor`), `test/router/demo_routes_test.dart`
(router/route tests), `test/screens/home_screen_test.dart` (screen widget tests).

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| S1-02 | Profile persists locally; grade resolves to startingLessonId (default alif) | unit (in-memory Drift) | `flutter test test/data/child_profile_repository_test.dart` | ❌ Wave 0 |
| S1-02 | `gradeToStartingLessonId` maps every grade option; default = alif | unit | `flutter test test/features/onboarding/onboarding_data_test.dart` | ❌ Wave 0 |
| S1-02 | v2→v3 migration creates ChildProfiles, preserves LetterMastery rows | unit (migration) | `flutter test test/data/app_database_test.dart` | ✅ extend existing |
| S1-03 | Avatar + nickname are fixed-set IDs; no free-text widget present | widget | `flutter test test/features/onboarding/onboarding_screen_test.dart` | ❌ Wave 0 |
| S1-03 | Selected nickname/avatar render on Home greeting | widget | `flutter test test/screens/home_screen_test.dart` | ✅ extend existing |
| gate | No profile → redirect to /onboarding; profile → Home; no loop | widget/router | `flutter test test/router/onboarding_gate_test.dart` | ❌ Wave 0 |
| gate | PopScope blocks back on onboarding | widget | (within onboarding_screen_test) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the touched test file (e.g. `flutter test test/data/child_profile_repository_test.dart`)
- **Per wave merge:** `flutter test test/data/ test/features/onboarding/ test/router/`
- **Phase gate:** `flutter test` (full suite green) + `flutter analyze` (exit 0) before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/data/child_profile_repository_test.dart` — covers S1-02 (persist + resolve)
- [ ] `test/features/onboarding/onboarding_data_test.dart` — covers S1-02 (grade map)
- [ ] `test/features/onboarding/onboarding_screen_test.dart` — covers S1-03 (fixed-set, no free-text, PopScope)
- [ ] `test/router/onboarding_gate_test.dart` — covers the redirect gate (no loop)
- [ ] Extend `test/data/app_database_test.dart` — v2→v3 migration
- [ ] Extend `test/screens/home_screen_test.dart` — greeting reads profile
- [ ] Framework install: none — `flutter_test` already present

## Security Domain

`security_enforcement` not disabled → applies. This phase handles **children's data** (CLAUDE.md:
"Treat children's data as sensitive in every design decision"; minimum child data, private by default).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Deferred to Phase 9 (no auth this phase, by decision) |
| V3 Session Management | no | No sessions, no network |
| V4 Access Control | no | Single local device, no multi-user |
| V5 Input Validation | yes | **No free-text input at all (S1-03)** — all inputs are taps from fixed sets, so injection surface is zero. Validate selected IDs are within the known fixed sets before persisting. |
| V6 Cryptography | no | No secrets; non-sensitive data; do not hand-roll crypto |
| V8 Data Protection / Privacy | yes | Store **minimum** child data: fixed-set IDs only, **no real name** (S1-03). DB lives in app-private storage (existing `getApplicationDocumentsDirectory`). Never log profile values (mirror the T-01-04 no-log discipline already in `app_database.dart`). |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Real-name / PII leakage | Information Disclosure | Fixed-set nickname IDs only; no `name` column; no free-text field (S1-03) |
| Out-of-set ID injection | Tampering | Validate `avatarId`/`nicknameId`/`grade` against the known const sets before insert |
| Logging child profile values | Information Disclosure | Never log profile fields (continue the no-log convention in `app_database.dart`) |
| Local DB at rest | Information Disclosure | App-private storage (existing); acceptable for v1 local-only (matches T-01-02 posture) |

## Sources

### Primary (HIGH confidence)
- In-repo (VERIFIED by reading): `lib/data/app_database.dart`, `lib/data/drift_progress_repository.dart`,
  `lib/data/curriculum_repository.dart`, `lib/router/app_router.dart`, `lib/app.dart`, `lib/main.dart`,
  `lib/screens/home_screen.dart`, `lib/models/lesson.dart`, `lib/l10n/app_en.arb`, `lib/theme/colors.dart`,
  `pubspec.yaml`, `l10n.yaml`, `assets/curriculum/letters.json`, `assets/curriculum/lessons.json`,
  `.planning/config.json`, test tree under `test/`.
- pub.dev go_router 17.x — Redirection topic (redirect returns `null` or path; `redirectLimit` default 5).
- pub.dev go_router 17.x — GoRouter constructor (`refreshListenable: Listenable?`; redirect is synchronous).

### Secondary (MEDIUM confidence)
- Flutter API: `PopScope` replaces deprecated `WillPopScope` (training + widely documented; not re-fetched this session).

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all deps verified in pubspec; no new packages.
- Architecture: HIGH — every pattern has a verified in-repo precedent (migration, provider, router seam, screen).
- GoRouter async gate: MEDIUM-HIGH — redirect/refreshListenable API confirmed via pub.dev; the boot-time-read strategy is a recommended approach (Claude's discretion per CONTEXT), not a single forced API.
- Pitfalls: HIGH — drawn from repo conventions (RTL, no-log, executor ownership) + confirmed framework behavior.

## What the Planner Should Do

A tight, dependency-ordered build that mirrors existing idioms:

1. **Data layer (S1-02 / S1-03 foundation):** Add `ChildProfiles` table to `AppDatabase`, bump
   `schemaVersion` to **3**, add `if (from < 3) await m.createTable(childProfiles);`, add
   `hasProfile()`/`getProfile()`/`createProfile()` accessors (mirror `recordMastery`/`getSetting`).
   Run `dart run build_runner build --delete-conflicting-outputs`. Extend
   `test/data/app_database_test.dart` for the v2→v3 migration (in-memory `NativeDatabase.memory()`).
2. **Repository + providers:** Add `ChildProfileRepository` + `@Riverpod(keepAlive: true)
   childProfileRepository` (mirror `DriftProgressRepository`), and a `@riverpod childProfile` async
   read. Add `child_profile_repository_test.dart`.
3. **Onboarding data (S1-02 map + S1-03 sets):** `onboarding_data.dart` with the 6 avatar IDs, the
   ~8–10 placeholder nickname IDs+labels (Arabic-flavored, flagged for owner sign-off TODO), and the
   `gradeToStartingLessonId` map (all → `alif`, with a loud TODO). Add `onboarding_data_test.dart`.
4. **Routing gate (gate req):** Add `OnboardingGate` `ChangeNotifier` provider; do the one-time
   boot read in `main.dart`; override `appDatabaseProvider` + the gate; add `/onboarding` route,
   the sync `redirect` (both rules), and `refreshListenable: gate`. Add `onboarding_gate_test.dart`
   asserting no-profile→/onboarding, profile→/, and no loop.
5. **Onboarding screen (S1-03):** Single scrollable card, `PopScope(canPop: false)`, grade chips →
   avatar grid → nickname grid → teal "Let's go" pill. No `TextField`. Tokens via `QalamColors/Space/
   Radii/Targets`, Arabic labels via `ArabicText`, l10n with `?? 'fallback'`. On submit: validate
   selections ∈ fixed sets → write row → `markProfileCreated()` → `invalidate(childProfileProvider)`
   → `context.go('/')`. Add `onboarding_screen_test.dart` (asserts no free-text widget exists,
   selection persists, back is blocked).
6. **Home integration (S1-03 "shown on home"):** Replace the hardcoded greeting in `home_screen.dart`
   with the profile nickname label + avatar circle (watch `childProfileProvider`); add the
   `{nickname}` ARB key. Extend `test/screens/home_screen_test.dart`.
7. **Gates:** `flutter analyze` exit 0, full `flutter test` green, all `.g.dart` regenerated &
   committed. Flag for owner's-mother sign-off: nickname wording + per-grade entry points.

**Do not:** add a new package, bump drift past 2.31, store a real name, add any free-text/keyboard,
use gold on onboarding, `await` inside `redirect`, or wrap the screen in global RTL.
