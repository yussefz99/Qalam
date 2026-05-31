# Phase 1: Foundations & RTL Shell - Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 24 (create/modify)
**Analogs found:** 6 in-repo source-of-truth / 24 — the rest are **net-new** (this is a near-greenfield Flutter app; Phase 1 *establishes* the theme/router/state/DB patterns for the first time)

> **Honesty note.** There is almost no in-repo Dart to copy from. Only three real in-repo files exist (`lib/main.dart`, `test/widget_test.dart`, `pubspec.yaml` — all default Flutter scaffold) plus the Android manifest. For the theme layer the true "analog" is the **design-kit CSS** (`docs/design/kit/project/colors_and_type.css`) — a *source-of-truth to translate*, not code to copy. For everything else (router, Drift, Riverpod, l10n, `ArabicText`) the analog is the **canonical Flutter/package convention** plus the **RESEARCH.md recommended structure (lines 180–191)**. Where a file is net-new, this map says so plainly and names the convention + the RESEARCH/CONTEXT line to follow, rather than inventing a fake in-repo precedent.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `pubspec.yaml` (modify) | config | — | self (existing scaffold) + RESEARCH §Standard Stack (L73–114), §Fonts (L90–98) | in-repo (modify) |
| `android/app/src/main/AndroidManifest.xml` (modify) | config | — | self (existing) + RESEARCH Pitfall 5 (L325–328), Code Ex (L351–358) | in-repo (modify) |
| `analysis_options.yaml` (modify/create) | config | — | net-new — `riverpod_lint` via `analysis_server_plugin` (RESEARCH L80, L364) | net-new |
| `l10n.yaml` (create) | config | — | net-new — Flutter `gen-l10n` convention (RESEARCH L88, L322; CONTEXT D-07) | net-new |
| `lib/main.dart` (replace) | entrypoint | event-driven (bootstrap) | `lib/main.dart` (boilerplate — replaced) | in-repo (replace) |
| `lib/app.dart` | provider/root | request-response (routing) | net-new — `MaterialApp.router` convention (RESEARCH L162–173, L184) | net-new |
| `lib/theme/colors.dart` | config (tokens) | transform (CSS→Dart) | `docs/design/kit/.../colors_and_type.css` `:root` L9–58 | source-of-truth |
| `lib/theme/text_styles.dart` | config (tokens) | transform (CSS→Dart) | `colors_and_type.css` type scale L60–96, utilities L169–186 | source-of-truth |
| `lib/theme/dimens.dart` | config (tokens) | transform (CSS→Dart) | `colors_and_type.css` spacing/radii/shadow/motion L98–153 | source-of-truth |
| `lib/theme/brand_theme_ext.dart` | config (tokens) | transform | net-new — Flutter `ThemeExtension<T>` convention (CONTEXT D-01) | net-new |
| `lib/theme/app_theme.dart` | config (theme) | transform | `colors_and_type.css` base L158–186 + Material `ThemeData` convention | source-of-truth + convention |
| `lib/router/app_router.dart` | route | request-response | net-new — `go_router` convention + `/parent` redirect seam (CONTEXT D-08; RESEARCH L106, L184) | net-new |
| `lib/data/app_database.dart` | model/store | CRUD (persist proof) | net-new — Drift `@DriftDatabase` convention (CONTEXT D-09; RESEARCH L66, L421) | net-new |
| `lib/widgets/arabic_text.dart` | component | transform (render) | `colors_and_type.css` `.q-ar`/`.q-num` L179–186 + RESEARCH §Arch Patterns L175–191, §Numeral L284–293 | source-of-truth + convention |
| `lib/screens/home_screen.dart` | component | request-response | net-new — `Scaffold` convention + UI-SPEC Screen Shells (L160–168), Copy (L176–188) | net-new |
| `lib/screens/practice_screen.dart` | component | event-driven (stylus) | net-new — `CustomPainter`/`Listener` convention + UI-SPEC Ink Rendering (L136–154) | net-new |
| `lib/screens/settings_screen.dart` | component | request-response | net-new — `Scaffold` convention + UI-SPEC (L166) | net-new |
| `lib/l10n/app_en.arb` | config (strings) | — | net-new — ARB convention; strings from UI-SPEC Copy table (L176–188) | net-new |
| `test/theme_test.dart` | test | — | `test/widget_test.dart` (boilerplate structure only) | in-repo (structure) |
| `test/data/app_database_test.dart` | test | CRUD | net-new — Drift in-memory test convention (RESEARCH L421) | net-new |
| `test/direction_test.dart` | test | — | `test/widget_test.dart` (structure) — D-05 (RESEARCH L420) | in-repo (structure) |
| `test/numeral_isolation_test.dart` | test | — | net-new — golden/widget; D-06 (RESEARCH L419) | net-new |
| `test/glyph_audit_golden_test.dart` | test (golden) | — | net-new — `flutter_test` golden + ZWJ harness (RESEARCH §Glyph-Audit L213–270) | net-new |
| `lib/dev/glyph_audit_screen.dart` (debug) | component | transform (render) | net-new — debug grid widget (RESEARCH L248–252) | net-new |

**Asset declarations (in `pubspec.yaml`):** `assets/fonts/` (NotoNaskhArabic, Cairo, Fredoka, Nunito TTFs — D-03), `assets/icons/`, `assets/logo*.svg` (copy from `docs/design/kit/project/assets/` — see Shared Patterns §Brand Assets).

---

## Pattern Assignments

### `pubspec.yaml` (config, modify)

**Analog:** the existing scaffold (read in full) — extend it; do not rewrite from scratch.

**Existing structure to preserve** (lines 30–47): `dependencies: flutter/sdk` + `cupertino_icons`; `dev_dependencies: flutter_test/sdk` + `flutter_lints: ^6.0.0`; `flutter: uses-material-design: true`.

**Add dependencies** (RESEARCH §Standard Stack L73–114, install block L110–114) — pin the verified versions:
```yaml
dependencies:
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2
  drift: ^2.33.0
  sqlite3_flutter_libs: ^0.6.0
  path_provider: ^2.1.0
  go_router: ^17.2.3
  flutter_svg: ^2.3.0
  flutter_localizations:
    sdk: flutter
dev_dependencies:
  build_runner: ^2.15.0
  riverpod_generator: ^4.0.3
  riverpod_lint: ^3.1.3
  drift_dev: ^2.33.0
```

**Enable gen-l10n + assets + fonts** (the commented scaffold block at L52–89 shows the exact shape Flutter expects — fill it in):
```yaml
flutter:
  uses-material-design: true
  generate: true            # gen-l10n (D-07)
  assets:
    - assets/icons/
    - assets/logo.svg
  fonts:                    # D-03 — bundle local TTFs, NO google_fonts/CDN
    - family: Noto Naskh Arabic   # exact family string must match TextStyle.fontFamily (Pitfall 3)
      fonts: [{asset: assets/fonts/NotoNaskhArabic-Regular.ttf}]
    - family: Cairo
      fonts: [{asset: assets/fonts/Cairo-Regular.ttf}, {asset: assets/fonts/Cairo-SemiBold.ttf, weight: 600}]
    - family: Fredoka
      fonts: [{asset: assets/fonts/Fredoka-Medium.ttf, weight: 500}, {asset: assets/fonts/Fredoka-SemiBold.ttf, weight: 600}]
    - family: Nunito
      fonts: [{asset: assets/fonts/Nunito-Regular.ttf, weight: 400}, {asset: assets/fonts/Nunito-SemiBold.ttf, weight: 600}]
```
> Weights: RESEARCH §Fonts L93–96 — Arabic is **never bold** (Regular sufficient, +500 only if scale uses it); Cairo logo weight ~600/700 (verify against the قلم wordmark, Assumption A4). Bundle **static** TTFs, not variable (Assumption A2).

---

### `android/app/src/main/AndroidManifest.xml` (config, modify)

**Analog:** the existing manifest (read in full). The `<activity>` block is at lines 6–14.

**Single change** (D-10; RESEARCH Pitfall 5 L325–328): add `android:screenOrientation` to the existing `<activity>` tag — do **not** touch the rest. Belt-and-suspenders: the manifest pins it at the platform layer, `SystemChrome` pins it at runtime (see `lib/main.dart`).
```xml
<activity
    android:name=".MainActivity"
    android:screenOrientation="sensorLandscape"   <!-- ADD: D-10 landscape lock -->
    android:exported="true"
    ... (keep existing configChanges/theme/launchMode unchanged) >
```
> Note: `android:configChanges` already includes `orientation|screenLayout|screenSize` (line 12) — keep them; they prevent activity recreation, complementary to the lock.

---

### `lib/main.dart` (entrypoint, **replace** the counter scaffold)

**Analog:** the boilerplate `lib/main.dart` (read in full) — its `void main() => runApp(const MyApp())` shell (L3–5) is the *only* reusable bone; everything else (counter `MyHomePage`, deepPurple seed) is deleted.

**Net-new bootstrap pattern** (RESEARCH §Recommended structure L184: "`ProviderScope` + DB init + `SystemChrome` landscape lock"; Code Ex L351–358):
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();          // RESEARCH L354
  await SystemChrome.setPreferredOrientations(        // D-10 runtime half of the lock
    [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  runApp(const ProviderScope(child: QalamApp()));     // Riverpod root (D-11)
}
```
> DB init: Drift opens lazily on first query via `LazyDatabase` (see `app_database.dart`) — no explicit await needed in `main` unless the planner chooses eager open. Keep `main` thin; root widget lives in `app.dart`.

---

### `lib/app.dart` (root, net-new)

**Analog:** net-new. Replaces the boilerplate `MaterialApp` (old `main.dart` L13–34). Follow `MaterialApp.router` convention + RESEARCH mixed-direction diagram (L161–173).

**Core pattern** — **NO global `Directionality.rtl`** (the cardinal D-05 rule; RESEARCH Pitfall 1 L305–308):
```dart
class QalamApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);       // from app_router.dart
    return MaterialApp.router(
      routerConfig: router,
      theme: qalamTheme,                                // from app_theme.dart — app default is LTR
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en')],           // D-07: English ONLY — never add Locale('ar') (Pitfall 4)
      debugShowCheckedModeBanner: false,
    );
  }
}
```
> Anti-pattern to avoid (RESEARCH L194, L323): a `supportedLocales` containing `ar`, or `Directionality` driven by `Localizations.localeOf`. RTL is a per-content decision (the `ArabicText` widget), never an app/locale decision.

---

### `lib/theme/colors.dart` (config tokens, transform CSS→Dart)

**Analog (source of truth):** `docs/design/kit/project/colors_and_type.css` `:root` block, **lines 9–58**. This is a **one-way translation**, not a copy — every `--var` becomes a `Color` const. Never hard-code hex in widgets (D-02; RESEARCH Anti-Pattern L198).

**Core palette to translate** (CSS L13–21):
```dart
// raw palette — private, only the semantic layer exposes these
const _parchment   = Color(0xFFFAF6EE);  // --parchment  (bg, never #FFFFFF)
const _softAqua    = Color(0xFFEAF4F4);  // --soft-aqua  (surfaces)
const _inkTeal     = Color(0xFF168A8F);  // --ink-teal   (primary)
const _deepInk     = Color(0xFF0E5B5F);  // --deep-ink   (pressed/headers/ink-stroke)
const _goldInk     = Color(0xFFF2A60C);  // --gold-ink   (REWARDS ONLY)
const _leaf        = Color(0xFF3FB984);  // --leaf       (success)
const _coral       = Color(0xFFFF8A6B);  // --coral      (warn-soft — NEVER red)
const _inkCharcoal = Color(0xFF222A2E);  // --ink-charcoal (fg — not pure black)
const _slate       = Color(0xFF5C6B70);  // --slate      (fg-muted)
```
**Semantic tokens** (CSS L33–58) — widgets read THESE: `bg`, `surface`, `surfaceRaised(#FFFFFF)`, `border`, `fg`, `fgMuted`, `fgOnPrimary`, `primary`, `primaryPressed`, `primaryTint`, `reward`, `rewardTint`, `success`, `warnSoft`. Plus tints (CSS L23–31) for ink-washes.
> Hard rules carried as code intent: gold = rewards only (CSS comment L17; UI-SPEC L130), coral is the only "error" color, no red anywhere.

---

### `lib/theme/text_styles.dart` (config tokens, transform CSS→Dart)

**Analog (source of truth):** `colors_and_type.css` type scale **L60–96** + utility classes **L169–186** (`.q-h1`…`.q-button`, `.q-ar`, `.q-ar-display`, `.q-num`). UI-SPEC Typography tables (L72–101) give the Phase-1 role subset.

**English roles** (CSS L169–176; UI-SPEC L74–80): Fredoka display/heading/button (500/600), Nunito body 18/400, label 16/600. Full scale `--fz-12…56` declared (CSS L72–81) but only the roles in UI-SPEC L74–80 are rendered this phase.

**Arabic roles** (CSS `.q-ar*` L179–182; UI-SPEC L88–90) — the joining-safety rules are load-bearing:
```dart
// Noto Naskh, 26px, lh 1.7 (plain) / 2.0 (tashkeel). NEVER bold/italic (UI-SPEC L96).
const arBody = TextStyle(
  fontFamily: 'Noto Naskh Arabic',   // MUST match pubspec family exactly (Pitfall 3, L316)
  fontSize: 26, height: 1.7, fontWeight: FontWeight.w400,
  letterSpacing: 0,                  // CRITICAL: letterSpacing on Arabic breaks joining (Pitfall 2, L310; #71220)
);
const arDisplay = TextStyle(fontFamily: 'Cairo', fontSize: 96, height: 1.1, fontWeight: FontWeight.w500); // .q-ar-display, deep-ink
```
> **Never** set `letterSpacing`/`wordSpacing` on any Arabic style (RESEARCH Anti-Pattern L196; Pitfall 2). Tashkeel line-height = 2.0 (CSS `--lh-tashkeel` L92).

---

### `lib/theme/dimens.dart` (config tokens, transform CSS→Dart)

**Analog (source of truth):** `colors_and_type.css` spacing **L98–117**, radii **L119–127**, elevation **L129–141**, motion **L143–153**.

**Translate:** `space1..space24` (4px base, L101–112) · `targetMin 64 / targetComfy 72 / targetLarge 96` (kids-UX floor L114–117, UI-SPEC L57–60) · radii `sm 8…pill 999` (L122–127) · shadows as `List<BoxShadow>` (`shadowSm/Md/Lg` L132–137) · the **signature sticker shadow** `--shadow-button: 0 4px 0 0 deepInk` (L140, a flat-bottom offset shadow — CONTEXT "specifics" L156–158; UI-SPEC L145) · motion curves+durations (`easeOutQuart` `Cubic(0.22,1,0.36,1)`, `durFast 140 / durBase 220 / durSlow 420 / durCheer 700` — L146–152) as `Curve`/`Duration`.

---

### `lib/theme/brand_theme_ext.dart` (config tokens, net-new)

**Analog:** net-new — Flutter `ThemeExtension<QalamTheme>` convention (CONTEXT D-01 explicitly calls for it: "a `ThemeExtension` for brand tokens Material doesn't cover — e.g. `--reward`, surface tints").

**Pattern:** a `@immutable class QalamTheme extends ThemeExtension<QalamTheme>` carrying tokens Material's `ColorScheme` has no slot for: `reward`/`rewardTint`, `warnSoft`/`warnSoftTint`, `success`/`successTint`, surface tints, the sticker `buttonShadow`, ink-stroke color, motion tokens. Implement required `copyWith` + `lerp`. Read in widgets via `Theme.of(context).extension<QalamTheme>()!`. Register in `app_theme.dart`'s `ThemeData(extensions: [...])`.

---

### `lib/theme/app_theme.dart` (theme, source-of-truth + convention)

**Analog:** `colors_and_type.css` base body L158–166 (bg/fg/font-family/18px base) + Material `ThemeData` convention. Replaces the boilerplate `ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple))` (old `main.dart` L31) — delete deepPurple entirely.

**Pattern:** `useMaterial3: true` (UI-SPEC L27); `scaffoldBackgroundColor: QalamColors.bg` (parchment, never white — D-02); `ColorScheme` seeded/overridden to ink-teal primary; `textTheme` wired from `text_styles.dart` (D-04); `fontFamily: 'Nunito'` default; `extensions: [QalamTheme(...)]`. Compose semantic tokens — never raw hex (CSS comment L34).

---

### `lib/router/app_router.dart` (route, net-new)

**Analog:** net-new — `go_router` convention (RESEARCH L106 "Flutter-team-recommended, integrates with Riverpod redirects"; structure L184).

**Pattern** (CONTEXT D-08: minimal tree + `/parent/*` redirect **seam only**):
```dart
@riverpod
GoRouter appRouter(AppRouterRef ref) => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',          builder: (c, s) => const HomeScreen()),
    GoRoute(path: '/practice',  builder: (c, s) => const PracticeScreen()),
    GoRoute(path: '/settings',  builder: (c, s) => const SettingsScreen()),
    // SEAM ONLY — do NOT build the PIN gate now (P9). Leave a commented/stub redirect hook.
  ],
  // redirect: (c, s) => ...  // /parent/* PIN-gate lands in P9 (CONTEXT D-08, RESEARCH L21)
);
```
> Three routes match UI-SPEC Screen Shells (L162–168). Active-tab indicator uses ink-teal accent (UI-SPEC L168). Do NOT build `/parent` content (deferred P9).

---

### `lib/data/app_database.dart` (model/store, net-new — CRUD persist proof)

**Analog:** net-new — Drift `@DriftDatabase` convention. No DB exists yet (CONTEXT D-09: prove persist/read survives a restart; minimal schema only).

**Pattern** (discretion per CONTEXT L91–92 / RESEARCH L31: a trivial `app_settings` key/value table is fine):
```dart
@DriftDatabase(tables: [AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _open());   // injectable executor → tests pass in-memory
  @override int get schemaVersion => 1;
}
// _open(): LazyDatabase over NativeDatabase at path_provider getApplicationDocumentsDirectory()/qalam.db
// AppSettings: key TEXT PK, value TEXT  — the trivial persist-proof row (D-09)
```
> Security (RESEARCH L446): DB lives in app-private docs dir; store **nothing sensitive** in Phase 1 (no child PII until P5). Provide the DB via a Riverpod provider so screens/tests inject it. The constructor must accept an optional `QueryExecutor` so the test can pass `NativeDatabase.memory()` (see test below).

---

### `lib/widgets/arabic_text.dart` (component, source-of-truth + convention) — THE signature widget

**Analog (source of truth):** `colors_and_type.css` `.q-ar` L179 + `.q-num` L186, combined per RESEARCH §Arch-Patterns "reusable widget" (L178) and §Numeral-Isolation (L284–293). This is the `.q-ar`/`.q-num` of the app — every later phase renders Arabic through it (RESEARCH L178). Get it right once.

**Core pattern — bundle three concerns** (RTL island + Noto Naskh style + numeral isolation):
```dart
class ArabicText extends StatelessWidget {
  // RESEARCH L167–172, L290–293:
  // 1. Directionality(rtl) — the ONLY RTL island (D-05); app stays LTR around it
  // 2. Noto Naskh style with letterSpacing:0 (Pitfall 2)
  // 3. Western digits LTR-isolated via LRI(U+2066)…PDI(U+2069) (D-06; RESEARCH L291, L347)
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Text(_isolateDigits(text), style: arBody /* or arDisplay */),
  );
}
```
**Numeral isolation** (CSS `.q-num` L186 `unicode-bidi: isolate; direction: ltr; "tnum" 1`; RESEARCH L344–348):
- Wrap any digit run in `⁦…⁩` (LRI…PDI) — the modern leak-free isolates (RESEARCH L291, State-of-Art L365).
- Use `FontFeature.tabularFigures()` if digits must column-align (CSS `tnum`; RESEARCH L293).
- **Never** `intl.NumberFormat` on an `ar` locale (RESEARCH Anti-Pattern L197, Pitfall L296 — the *only* path that injects Eastern digits ٠١٢; D-06 forbids it).

---

### `lib/screens/{home,practice,settings}_screen.dart` (component, net-new)

**Analog:** net-new — `Scaffold` convention. **Shell/scaffold level only** (UI-SPEC L17, L158–168) — no real content.

- **home_screen.dart** (UI-SPEC L164): app bar with قلم logo (`flutter_svg` on `assets/logo.svg`), parchment bg, centered soft-aqua placeholder card, single "Open Practice" primary CTA. No stars/totals/streaks (D-13). Copy: "Your Journey Starts Soon" (UI-SPEC L181).
- **practice_screen.dart** (UI-SPEC L136–154, L165): the **only** interactive screen — `CustomPainter` ink surface over a framed soft-aqua/parchment card. Ink: deep-ink `#0E5B5F`, width 6px (4–8 range), `StrokeCap.round`, `StrokeJoin.round`, quadratic/Catmull-Rom smoothing, `isAntiAlias: true` (UI-SPEC table L142–152). Capture via `Listener`/`GestureDetector`; a single **Clear** action with the "Clear your writing?" confirm (UI-SPEC L187). **Out of scope:** dotted guide, scoring, stroke-order, star (UI-SPEC L154).
- **settings_screen.dart** (UI-SPEC L166): parchment placeholder rows; leave a **routing seam comment** for `/parent/*` (P9) — do not build the PIN gate.

> Copy strings come from the UI-SPEC Copywriting table (L176–188), routed through `gen-l10n` (no hardcoded strings — D-07). Voice: second person, Title Case, no emoji, no pseudo-icons (D-13; UI-SPEC L189).

---

### `lib/l10n/app_en.arb` + `l10n.yaml` (config strings, net-new)

**Analog:** net-new — Flutter built-in `gen-l10n` convention (RESEARCH L88, L322; CONTEXT D-07 "keep it low-magic"). `pubspec` `generate: true` + a single `l10n.yaml` pointing at `lib/l10n/app_en.arb`.

**Pattern** (RESEARCH Pitfall 4 L320–323): **one** `app_en.arb` only. **No `app_ar.arb`.** Seed it with the UI-SPEC Copy table strings (L176–188). RTL must NOT be coupled to locale — it's the `ArabicText` widget's job.

---

### Test files (Wave 0) — `test/...`

**Analog:** `test/widget_test.dart` (read in full) supplies only the **harness skeleton** — `void main(){ testWidgets/test('...', (...) async {...}) }` (L13–29) with `package:qalam/...` imports. Its counter-app body is deleted. The boilerplate's `pumpWidget(const MyApp())` (L15) becomes `pumpWidget(...)` of the unit under test. RESEARCH §Validation Architecture (L403–436) is the spec; Wave-0 gaps at L431–436.

| Test file | Proves | Pattern source |
|---|---|---|
| `test/theme_test.dart` | theme exposes semantic primary/bg/reward (D-01/02) | unit; assert token values vs CSS L13–21 (RESEARCH L422) |
| `test/data/app_database_test.dart` | Drift value survives "restart" = new DB instance (D-09) | **in-memory Drift** `NativeDatabase.memory()`; write→close→reopen→read (RESEARCH L421) |
| `test/direction_test.dart` | app default LTR; only `ArabicText` is RTL (D-05) | widget; pump a screen, assert ambient `Directionality.of` == ltr outside, rtl inside the island (RESEARCH L420) |
| `test/numeral_isolation_test.dart` | digits render 0–9, LTR, inside RTL island (D-06) | golden/widget; mixed Arabic+digit string via `ArabicText` (RESEARCH L419) |
| `test/glyph_audit_golden_test.dart` | **THE risk gate** — Noto Naskh shapes 4 forms, no tofu, لا ligature (D-12) | golden of the audit grid (see below) — RESEARCH §Glyph-Audit L213–270 |

---

### `lib/dev/glyph_audit_screen.dart` (debug component, net-new) + the golden — D-12 risk gate

**Analog:** net-new — debug grid widget per the RESEARCH harness spec (L248–252). This is **the phase's one hard risk** (RESEARCH L51, L209).

**Pattern** (RESEARCH L237–252):
- Grid: rows = the representative letter set (RESEARCH table L220–232: ه ع/غ ك ل لا ب/ت/ث ج/ح/خ س/ش م ي + a tashkeel row); columns = the four contextual forms.
- Force each form with the **ZWJ technique** (RESEARCH L236–246, Code Ex L334–342) — **audit harness only, never in real strings**:
  ```dart
  isolated: 'ه'   initial: 'ه‍'   medial: '‍ ه‍'   final: '‍ ه'
  ```
- Each cell: `Directionality(rtl)` + `Text(form, style: arDisplay)` at 96px (`--fz-ar-display`) so shaping is inspectable at child-facing size.
- Prove the **bundled** TTF is the one shaping (swap-test — RESEARCH L251, Pitfall 3 L315–318).
- PASS/FAIL criteria: RESEARCH L254–270 (no tofu; correct contextual shape; **لا → single ﻻ ligature**; joins intact; tashkeel placed at lh 2.0; digits 0–9 LTR). On FAIL → switch bundled font to **Amiri** (documented escape hatch, RESEARCH L151, L270) and re-run.
- Wrap in a golden test → regression gate against font/Flutter-upgrade shaping drift (RESEARCH L252). Human visual PASS required at the phase gate (RESEARCH L428).

---

## Shared Patterns

### Mixed-direction discipline (apply to ALL UI files)
**Source:** RESEARCH §Mixed-direction shell (L159–178), Pitfall 1 (L305–308).
**Apply to:** `app.dart`, every screen, `arabic_text.dart`.
- App is LTR by default — **no root `Directionality.rtl`** (mirrors English chrome → bug).
- Arabic appears **only** inside `ArabicText` (the lone RTL island).
- Use `EdgeInsetsDirectional` / `AlignmentDirectional` / `start`/`end` (not left/right) so RTL blocks mirror correctly without flipping the app (RESEARCH L205).

### Design-token discipline (apply to ALL widget/theme files)
**Source:** `colors_and_type.css` semantic block L33–58; CONTEXT D-01/D-02; RESEARCH Anti-Pattern L198.
**Apply to:** every screen + theme file.
- Read **semantic** tokens (`primary`, `bg`, `reward`…), never raw hex, never the `_private` palette consts.
- Background is parchment `#FAF6EE` — **never** `#FFFFFF` (raised surfaces only, sparingly).
- Gold `#F2A60C` = rewards only (absent in P1). Coral is the only warn color — **no red, no red X** (UI-SPEC L115, L131).
- No emoji, no unicode pseudo-icons (⭐✓✗) — use brand SVG glyphs (D-13; ICONOGRAPHY.md).

### Brand assets (apply to home_screen, any glyph use)
**Source:** `docs/design/kit/project/assets/` (logo.svg, logo-horizontal.svg, icons/{star,ink-drop,lock,check-complete,qalam-nib}.svg, mascot/qalam-*.svg).
**Apply to:** copy needed assets into `assets/` (declared in pubspec), render via `flutter_svg` (RESEARCH L87; CONTEXT L136). Logo wordmark uses Cairo. Mascot SVGs are placeholders — Phase 1 wires logo/brand only (D-13); no mascot states/voice (v2).

### Riverpod-codegen wiring (apply to providers + analysis_options)
**Source:** RESEARCH L80, L364; CONTEXT D-11.
**Apply to:** `app_router.dart`, the DB provider, any provider.
- `@riverpod` annotation + `part 'x.g.dart';`, generated by `build_runner` (also drives Drift codegen).
- `riverpod_lint` installs via **`analysis_server_plugin` in `analysis_options.yaml`**, **NOT `custom_lint`** (RESEARCH State-of-Art L364 — common v3 footgun).
- Riverpod only — reject any BLoC/GetX (CLAUDE.md Decided; CONTEXT D-11).

### Don't hand-roll (apply throughout)
**Source:** RESEARCH §Don't Hand-Roll (L200–209).
- Arabic shaping → Flutter engine + complete font. **Never** `arabic_reshaper`/manual ZWJ in production (corrupts correct text); ZWJ is audit-harness-only.
- Digit direction → Unicode bidi + LRI/PDI isolate; **never** reverse strings manually.
- i18n → `gen-l10n`; **never** a custom string map.

---

## No Analog Found (planner: use RESEARCH/UI-SPEC patterns, not an in-repo file)

| File | Role | Data Flow | Reason / Follow |
|------|------|-----------|-----------------|
| `lib/app.dart` | root | request-response | No existing app root beyond the deleted counter. Follow `MaterialApp.router` convention + RESEARCH L162–173. |
| `lib/router/app_router.dart` | route | request-response | No routing exists. Follow `go_router` convention + CONTEXT D-08 seam. |
| `lib/data/app_database.dart` | store | CRUD | No DB exists. Follow Drift `@DriftDatabase` convention + CONTEXT D-09. |
| `lib/theme/brand_theme_ext.dart` | tokens | transform | No theme exists. Follow `ThemeExtension<T>` convention + CONTEXT D-01. |
| `lib/dev/glyph_audit_screen.dart` + golden | test/debug | render | No test infra. Follow RESEARCH §Glyph-Audit harness spec (L213–270). |
| `lib/l10n/app_en.arb`, `l10n.yaml` | config | — | No l10n exists. Follow Flutter `gen-l10n` convention + CONTEXT D-07 (English-only). |
| `analysis_options.yaml` (lint plugin) | config | — | Follow `analysis_server_plugin` wiring (RESEARCH L80, L364) — not `custom_lint`. |

> The three `lib/screens/*.dart` and the four non-golden test files are also net-new but follow plain `Scaffold` / `flutter_test` conventions with content/assertions specified by the UI-SPEC and RESEARCH §Validation tables — low risk, no analog needed.

## Metadata

**Analog search scope:** `lib/` (1 file), `test/` (1 file), `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `docs/design/kit/project/{colors_and_type.css, assets/ICONOGRAPHY.md, assets/}`.
**Files scanned:** 6 in-repo (read in full) + design-kit token CSS + asset inventory.
**Key finding:** near-greenfield — theme layer's true analog is the design-kit CSS (translate, don't copy); all runtime patterns (router/DB/state/l10n/`ArabicText`) are net-new, following package conventions + RESEARCH.md recommended structure (L180–191).
**Pattern extraction date:** 2026-05-31
