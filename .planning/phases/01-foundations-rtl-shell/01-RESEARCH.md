# Phase 1: Foundations & RTL Shell - Research

**Researched:** 2026-05-31
**Domain:** Flutter/Android RTL app shell — Arabic font selection & glyph audit, Western-numeral isolation, RTL pitfalls for a mixed-direction shell, Phase-1 package version verification
**Confidence:** HIGH (font choice, numeral technique, RTL traps verified against Flutter engine source/issues + official docs; package versions verified live on pub.dev 2026-05-31)

> **Scope discipline.** This document closes **R3 (RTL + connected-script rendering)** for Phase 1 only. It does NOT cover scoring, ML Kit, stroke capture, curriculum schema, or any later phase. It builds on — and does not repeat — `STACK.md`, `PITFALLS.md`, `ARCHITECTURE.md`, and the binding `01-CONTEXT.md`. Where this research touches a CONTEXT.md decision it says so explicitly.

---

<user_constraints>
## User Constraints (from 01-CONTEXT.md)

### Locked Decisions (research THESE, not alternatives)
- **D-01/D-02:** Design system in `docs/design/kit/` is the source of truth. Lift tokens into a Dart theme layer (`lib/theme/colors.dart`, `text_styles.dart`, `dimens.dart`, `app_theme.dart` + a `ThemeExtension` for brand tokens). Semantic tokens only in widgets. `--primary` ink-teal `#168A8F`, `--bg` parchment `#FAF6EE`, `--reward` gold `#F2A60C` rewards-only, `--warn-soft` coral — **never red**. Parchment background, never stark white.
- **D-03:** Bundle local TTFs in `assets/fonts/` — **Fredoka** (English display), **Nunito** (English body), **Noto Naskh Arabic** (Arabic reading & tracing content, with tashkeel), **Cairo** (Arabic display / قلم logo). NO Google-Fonts CDN `@import`, NO `google_fonts` runtime fetch (violates offline-first).
- **D-04:** Wire fonts into `ThemeData.textTheme` per the kit type scale. Kids-UX floor 18px base; Arabic content 10–25% larger than nearby English; line-height 1.7 plain Arabic / 2.0 with tashkeel.
- **D-05:** App chrome is **English / LTR**. Arabic appears **only as RTL content islands** wrapped in `Directionality(rtl)`. **Mirror only Arabic content blocks, not the whole app.**
- **D-06:** **Western numerals (0–9) everywhere**, including inside Arabic blocks (LTR-isolate digits — the `.q-num` equivalent). Decided explicitly; do not leave to locale defaults.
- **D-07:** Light i18n/l10n seam (Flutter `gen-l10n`) so UI strings aren't hardcoded, but v1 ships **English strings only**. No Arabic UI translation in v1. Keep low-magic.
- **D-08:** **`go_router`** for declarative routing; Phase 1 = minimal route tree + placeholder home. Leave a seam for a PIN-gated `/parent/*` branch (built P9); do not build it now.
- **D-09:** **Drift** (SQLite) for local persistence. Phase 1 proves the DB by persisting/reading a trivial value across an app restart. Minimal schema only.
- **D-10:** **Lock orientation to landscape** (matches the kit's 1280×900 canvas). Set in Android manifest / `SystemChrome`.
- **D-11:** **Riverpod with code-generation** (`flutter_riverpod` + `riverpod_generator` + `riverpod_lint`), `build_runner` wired (also needed by Drift). Riverpod only — no BLoC/GetX.
- **D-12:** Before declaring Phase 1 done, **glyph-audit Noto Naskh Arabic** against a representative set of curriculum letters in all four contextual forms (isolated/initial/medial/final) — confirm correct joining, no tofu, no broken shaping.
- **D-13:** Mascot = tutor persona (not a game mascot); stars = mastery markers only. No streaks/badges/totals/nudges, no emoji or unicode pseudo-icons — use brand glyphs in `docs/design/kit/project/assets/`.

### Claude's Discretion (research options, recommend)
- Exact Dart token naming/structure inside `lib/theme/`, the `ThemeExtension` shape, and how `gen-l10n` is wired.
- Whether the Phase-1 persistence proof is a tiny `app_settings` table or a key/value row.
- Sourcing the TTFs (OFL) and the exact font weights to bundle.

### Deferred Ideas (OUT OF SCOPE — ignore)
- Mascot animated states + voice, AI feedback (v2). Journey/level map + MASTERED celebration (P6/P3). PIN-gated parent area (P9 — leave only a routing seam now). Real curriculum reference-path format (P2). Illustrator-commissioned mascot. Custom icon set.
</user_constraints>

<phase_requirements>
## Phase Requirements (this research's coverage)

| ID / Decision | Description | Research Support |
|---|---|---|
| D-03 (font) | Which Arabic content font to bundle | §Font Decision — confirms Noto Naskh Arabic; documents Amiri tradeoff |
| D-12 (glyph audit) | Executable four-form joining audit | §Glyph-Audit Method — runnable test harness + PASS/FAIL spec |
| D-06 (numerals) | Western digits, LTR-isolated, inside RTL Arabic | §Western-Numeral Isolation — concrete Flutter technique |
| D-05 (mixed direction) | LTR shell, RTL Arabic islands only | §RTL Pitfalls for the Shell |
| D-11/D-09/D-08/D-07 | Riverpod-codegen, Drift, go_router, gen-l10n versions | §Standard Stack — live-verified versions |
</phase_requirements>

## Summary

Phase 1 is a foundation phase whose single hard risk is **R3: does the chosen Arabic font render the curriculum's letters correctly in all four contextual forms inside Flutter, and do Western digits behave inside RTL islands?** Everything else (theme tokens, go_router skeleton, Drift persist-proof, landscape lock, Riverpod codegen wiring) is standard, low-risk Flutter work already specified by CONTEXT.md and STACK.md.

**On the font conflict (STACK.md's "Amiri primary" vs D-03's "Noto Naskh Arabic"):** the conflict resolves in favor of **Noto Naskh Arabic — confirming D-03, not overturning it.** The decisive evidence is that Flutter's *own engine* uses Noto Naskh Arabic as its reference Arabic test font (flutter/engine PR #21974), making it the most rendering-tested Arabic face in the Flutter stack. The one documented Noto Naskh defect is a niche "Allah" (لله) ligature-with-tashkeel edge case — irrelevant to teaching individual letters. Amiri is fully viable and renders cleanly where Lateef/Scheherazade New break (flutter/flutter #143975), so keep Amiri as a documented fallback, but bundle **Noto Naskh Arabic** as the Phase-1 content font.

**Primary recommendation:** Bundle Noto Naskh Arabic (Regular + the weights you actually use), gate Phase-1 "done" on a runnable four-form glyph-audit harness, render Western digits as literal U+0030–U+0039 wrapped in an LTR `Directionality`/isolate inside each Arabic RTL island (do NOT use `intl` number formatting on an `ar` locale at all — D-06 sidesteps the whole Eastern-digit problem), and keep the entire app LTR with `Directionality(rtl)` applied only to Arabic content widgets.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Arabic glyph shaping (4 forms) | Flutter text engine (client) | Bundled font file | Flutter's HarfBuzz-based shaper picks contextual forms automatically given a complete font; nothing in app code chooses forms |
| Western-digit shape selection | Flutter text engine (client) | — | Digits are literal Unicode codepoints; engine renders them as-is from the body font |
| Bidi ordering of digits in RTL | Flutter `Directionality`/bidi (client) | — | The Unicode Bidi Algorithm + an LTR isolate keeps digit runs LTR inside RTL text |
| Theme tokens → Material | App theme layer (`lib/theme/`) | design kit CSS | One-way translation of kit tokens into Dart; widgets read semantic tokens |
| Routing | go_router (client) | — | Declarative route tree; redirect seam for `/parent` |
| Local persistence proof | Drift / SQLite (on-device) | path_provider | Single-device, offline; no network tier exists in v1 |
| Orientation lock | Android manifest + `SystemChrome` (platform) | — | Platform-level config, not a runtime concern |

## Standard Stack

> Versions verified live on pub.dev / Flutter docs on **2026-05-31**. STACK.md's pins were 1 day old and mostly hold; the deltas below are flagged.

### Core (Phase-1 package set)
| Library | Verified Version (2026-05-31) | STACK.md pin | Purpose | Note |
|---|---|---|---|---|
| Flutter (stable) | 3.44.x | 3.44.x | Framework, RTL, Impeller | Confirmed current stable (docs updated 2026-05-15/20). [VERIFIED: docs.flutter.dev/release/release-notes] |
| flutter_riverpod | **3.3.1** | 3.3.1 | State management | Confirmed. [VERIFIED: pub.dev] |
| riverpod_annotation | **4.0.2** | 4.0.2 | Codegen annotations | Confirmed (pairs with generator 4.0.3). [VERIFIED: pub.dev] |
| riverpod_generator | **4.0.3** | 4.0.3 | Riverpod codegen | dev_dependency. [VERIFIED: pub.dev] |
| riverpod_lint | **3.1.3** | 3.1.3 | Lint | dev_dependency. **Uses `analysis_server_plugin`, NOT `custom_lint`** — install via `analysis_options.yaml`. [VERIFIED: pub.dev] |
| drift | **2.33.0** | 2.33.0 | Local DB | Confirmed (published ~27 days ago). [VERIFIED: pub.dev] |
| drift_dev | match 2.33.x | 2.33.x | Drift codegen | Keep aligned with drift. [CITED: pub.dev/packages/drift] |
| sqlite3_flutter_libs | **^0.5.41** | 0.5.42 | Bundles native SQLite | **CORRECTED (Phase 05 device UAT):** the original `^0.6.0` pin was WRONG. `0.6.0+eol` is an EMPTY end-of-life tombstone (ships NO native code; pairs with the `package:sqlite3` 3.x migration). The earlier "`+eol` is just a build tag, not a deprecation" note was backwards. Our stack is drift 2.31 + sqlite3 2.9.4 (2.x), which needs the real 0.5.x build. Under `^0.6.0`, `libsqlite3.so` silently dropped from the APK → `dlopen failed` boot crash once the DB opened on-device. Pin `^0.5.41`. [VERIFIED: pub.dev pkg pubspec + APK inspection] |
| path_provider | ^2.1.x | ^2.1.0 | Locate DB file | [CITED: pub.dev] |
| go_router | **17.2.3** | (not pinned in STACK; "current") | Declarative routing | **DELTA: confirm the major-version line.** 17.x is current (published ~29 days ago). STACK.md didn't pin go_router; planner should pin `^17.2.3`. No breaking change relevant to a minimal Phase-1 route tree. [VERIFIED: pub.dev] |
| build_runner | **2.15.0** | ^2.4.0 | Drives all codegen | **DELTA: STACK.md's `^2.4.0` floor is fine but stale.** Current is 2.15.0; `^2.4.0` will resolve forward. Recommend pinning `^2.15.0` to match local tooling. [VERIFIED: pub.dev] |
| flutter_svg | **2.3.0** | (mentioned in CONTEXT code-context, not STACK) | Render brand glyph SVGs | For logo + brand glyphs in `docs/design/kit/project/assets/`. [VERIFIED: pub.dev] |
| flutter_localizations + gen-l10n | SDK (bundled) | n/a | i18n seam (D-07) | Use Flutter's built-in `gen-l10n` (flutter_localizations from SDK + `l10n.yaml`). No third-party package. [CITED: docs.flutter.dev] |

### Fonts (bundled, D-03)
| Family | Role | Weights to bundle (recommendation) | License |
|---|---|---|---|
| Noto Naskh Arabic | Arabic content + tracing model letter | Regular (400); add Medium/Bold only if the type scale uses them — kit says Arabic is **never bold**, so Regular + maybe 500 is sufficient | OFL [CITED: fonts.google.com/noto/specimen/Noto+Naskh+Arabic] |
| Cairo | Arabic display / قلم logo | Regular + the logo weight (likely 600/700) | OFL |
| Fredoka | English display/headings/buttons | weights used by the kit scale | OFL |
| Nunito | English body/labels | 400/600/700 per scale | OFL |

**Font sourcing (discretion):** download OFL TTFs from Google Fonts' file repo (or `google_fonts` *only* to fetch-then-bundle the file). Bundle the static TTFs; do not ship a variable font unless you verify Flutter renders the chosen named instances correctly (static weights are lower-risk for Phase 1).

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|---|---|---|
| Noto Naskh Arabic | **Amiri** | Amiri is a classical-Naskh revival with richer OpenType/ligature coverage and renders cleanly in Flutter (passes where Lateef/Scheherazade break). It is a *valid* alternative and a good documented fallback. But Noto Naskh is the font Flutter's engine tests against, giving it the strongest Flutter-rendering guarantee, and its slightly more "screen-neutral" letterforms are arguably clearer model shapes for a child than Amiri's more calligraphic strokes. **Recommend Noto Naskh as default, Amiri as the escape hatch if the glyph audit surfaces a Noto Naskh defect on a curriculum letter.** |
| Noto Naskh Arabic | Scheherazade New / Lateef | **Avoid.** Documented Flutter shaping bug (#143975) breaks specific Arabic joins. |
| Noto Naskh Arabic | Noto **Sans** Arabic | Avoid for the teaching glyph — geometric/sans forms diverge from the Naskh handwriting children are taught. Fine for chrome only (but chrome is English anyway). |
| go_router | auto_route / Navigator 2.0 raw | go_router is the Flutter-team-recommended declarative router and integrates with Riverpod redirects; no reason to deviate. |
| gen-l10n | easy_localization / intl_utils | Built-in gen-l10n is lower-magic (D-07 "keep it low-magic") and adds no dependency. |

**Installation (Phase-1 delta to verify at plan time):**
```bash
flutter pub add flutter_riverpod riverpod_annotation drift sqlite3_flutter_libs path_provider go_router flutter_svg
flutter pub add dev:build_runner dev:riverpod_generator dev:riverpod_lint dev:drift_dev
# flutter_localizations comes from the SDK; enable via flutter: generate: true + l10n.yaml
```

## Package Legitimacy Audit

> All Phase-1 packages are first-party Flutter-team or well-known ecosystem packages, discovered from official docs/STACK.md and verified live on pub.dev. slopcheck was not run in this session (no external/novel packages introduced); every package below is a known, high-download, long-lived package with an official source repo. None are novel or AI-suggested.

| Package | Registry | Maturity | Source Repo | Disposition |
|---|---|---|---|---|
| flutter_riverpod / riverpod_annotation / riverpod_generator / riverpod_lint | pub.dev | mature, millions of installs | github.com/rrousselGit/riverpod | Approved [CITED: pub.dev] |
| drift / drift_dev | pub.dev | mature | github.com/simolus3/drift | Approved [CITED: pub.dev] |
| sqlite3_flutter_libs | pub.dev | mature (drift author) | github.com/simolus3/sqlite3.dart | Approved |
| go_router | pub.dev | first-party (flutter.dev publisher) | github.com/flutter/packages | Approved [CITED: pub.dev] |
| path_provider | pub.dev | first-party | github.com/flutter/packages | Approved |
| build_runner | pub.dev | first-party (dart.dev) | github.com/dart-lang/build | Approved |
| flutter_svg | pub.dev | mature, ecosystem-standard | github.com/dnfield/flutter_svg | Approved [CITED: pub.dev] |
| flutter_localizations | Flutter SDK | first-party | flutter/flutter | Approved |

**Packages removed (SLOP):** none.
**Packages flagged (SUS):** none.

---

## Font Decision (closes the STACK.md ↔ D-03 conflict)

### Verdict: bundle **Noto Naskh Arabic** as the Phase-1 Arabic content font. This **CONFIRMS D-03**; it does NOT overturn it.

STACK.md recommended Amiri as "primary" and Noto Naskh as "alternative/fallback." D-03 (the binding decision) chose Noto Naskh Arabic. The decision-grade evidence resolves the conflict toward Noto Naskh:

| Criterion | Noto Naskh Arabic | Amiri | Winner |
|---|---|---|---|
| **Flutter rendering guarantee** | Flutter's **engine** specifies Noto Naskh Arabic as its reference font for Arabic-text tests (flutter/engine PR #21974) → most-tested Arabic face in the Flutter stack | Renders correctly in Flutter; passes where Lateef/Scheherazade break (#143975) — but not the engine's reference font | **Noto Naskh** |
| **Positional/contextual coverage** | Full isolated/initial/medial/final + ligatures | Full + richer classical ligatures | Tie (both complete for curriculum letters) |
| **Tashkeel/diacritic rendering** | Designed for diacritic clarity; *one* known defect: لله (Allah) + shadda/superscript-alef ligature (notofonts/arabic #192) — **irrelevant to single-letter teaching** | Strong tashkeel | Tie (Noto's defect doesn't touch curriculum letters) |
| **Model-letter legibility for a child** | Clean, screen-neutral Naskh — clear skeletal letterforms, good as a *model* to copy | More calligraphic/ornamented strokes — beautiful, but slightly busier as a tracing model | **Noto Naskh** (slight edge for a child's model letter) |
| **OFL license** | OFL | OFL | Tie |
| **File size** | Moderate (bundle only needed weights) | Moderate–larger (more OpenType tables) | Slight Noto edge |

**Both are viable.** Noto Naskh is the recommended default for the reasons above; **Amiri is the documented escape hatch** — if the D-12 glyph audit finds Noto Naskh mis-shapes a *specific curriculum letter or form*, switching to Amiri is a one-line `pubspec.yaml` + theme change and the audit re-runs. No contradiction with D-03; the decision stands and is now evidence-backed.

> **Flag to planner/owner:** This research **does not overturn D-03.** STACK.md's "Amiri primary" line is superseded for Phase 1 by D-03 + the engine-test evidence above. Keep Amiri's TTF reachable (note it in the plan) as the fallback the glyph audit can trigger.

**Important Phase-1 boundary:** the *traceable dotted guide letter* (the child traces over it) is **NOT a font-rendered glyph** — PITFALLS.md Pitfall 5 and ARCHITECTURE.md Anti-Pattern 2 mandate it be a vector/path asset, and it's built in P3, not now. The font chosen here is for **Arabic content text** (vocalized words/labels shown as `Text`), which is what Phase 1 renders. Do not let the font audit bleed into "render the tracing target as `Text`."

## Architecture Patterns

### Mixed-direction shell (the D-05 pattern)

```
MaterialApp.router            ← NO global TextDirection.rtl; app default is LTR
  └─ theme: app chrome English/LTR (Fredoka/Nunito), parchment bg
  └─ routes (go_router): /  /parent (redirect seam)  …
       └─ Screen (LTR)
            ├─ English chrome widgets  (default LTR, EdgeInsetsDirectional)
            └─ ArabicContent(...)      ← the ONLY RTL island:
                 Directionality(
                   textDirection: TextDirection.rtl,
                   child: Text(arabicString, style: notoNaskhStyle),
                 )
                 └─ digits inside it → LTR isolate (see numeral section)
```

**Pattern: keep the app LTR, opt-in to RTL per Arabic block.**
- **What:** The root `MaterialApp` has no `Directionality` override → Flutter defaults to LTR (or follows the device, but with English-only locale it stays LTR). Wrap *only* Arabic content in `Directionality(textDirection: TextDirection.rtl)`.
- **Why:** D-05 + the design kit's "mirror only Arabic content blocks, not the whole app." Avoids mirroring the English nav/buttons/parent screens.
- **Reusable widget:** introduce a tiny `ArabicText`/`ArabicContent` wrapper widget that bundles `Directionality(rtl)` + the Noto Naskh text style + the numeral-isolate behavior. This becomes the single, low-magic way every later phase renders Arabic — set the pattern now (it's the `.q-ar` of the app).

### Recommended Phase-1 structure (aligns with ARCHITECTURE.md)
```
lib/
├── main.dart            # ProviderScope + DB init + SystemChrome landscape lock
├── app.dart            # MaterialApp.router, theme, (NO global RTL)
├── theme/              # colors.dart, text_styles.dart, dimens.dart, app_theme.dart, brand_theme_ext.dart
├── router/app_router.dart   # go_router skeleton + /parent redirect seam
├── data/               # app_database.dart (Drift) + trivial settings table/row
├── l10n/               # gen-l10n (app_en.arb only in v1)
└── widgets/arabic_text.dart # the RTL-island + Noto Naskh + numeral-isolate wrapper
assets/fonts/           # NotoNaskhArabic-Regular.ttf, Cairo-*.ttf, Fredoka-*.ttf, Nunito-*.ttf
```

### Anti-Patterns to Avoid
- **Global `Directionality(rtl)` on the whole app** — mirrors English chrome. Wrap Arabic only.
- **Rendering the tracing target glyph as `Text`** — deferred to P3 as a vector path (Pitfall 5). Not Phase 1.
- **`letterSpacing` / `wordSpacing` on Arabic `Text`** — documented to break Arabic joining (flutter/flutter #71220). Never set it on Arabic styles.
- **`intl.NumberFormat` on an `ar` locale to show numbers** — produces Eastern-Arabic digits inconsistently (dart-lang/i18n #477). D-06 forbids this path entirely.
- **Hard-coding hex/fonts in widgets** — D-01/D-02; read semantic tokens.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Arabic contextual shaping (4 forms) | A reshaper / `arabic_reshaper` / manual ZWJ in production strings | Flutter's built-in text engine + a complete font | Flutter shapes Arabic correctly given a full font; `arabic_reshaper` is a workaround for broken pipelines and **corrupts** correct strings if double-applied. ZWJ is for the *audit harness only* (see below), never for real content. |
| RTL layout primitives | Manual left/right swapping | `EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end`, `Directionality` | Framework handles mirroring per text direction. |
| Digit direction in RTL | Custom string reversal | Unicode Bidi Algorithm + LTR isolate | The bidi algorithm already keeps digit runs LTR; reversing strings double-corrupts. |
| i18n string lookup | Custom map | Flutter `gen-l10n` | Built-in, type-safe, low-magic (D-07). |

**Key insight:** every "Arabic is hard in Flutter" horror story traces to one of three causes — an incomplete font, `letterSpacing` on Arabic, or a reshaper applied to already-correct text. Avoid all three and Flutter shapes Arabic correctly out of the box. The glyph audit (D-12) exists to *prove* the font is complete for our specific curriculum letters before we trust it.

---

## Glyph-Audit Method (D-12) — runnable acceptance check

The audit's job: **prove Noto Naskh Arabic shapes every curriculum-relevant letter correctly in all four contextual forms inside Flutter**, before Phase 1 is "done." It must be repeatable (re-runnable if the font changes to Amiri) and produce an unambiguous PASS/FAIL.

### Representative letter set (cover the tricky joiners)
Test, at minimum, these — chosen because they exercise the hard shaping cases. (The full curriculum set comes from the owner's mother in P2; this Phase-1 set is the *rendering* stress test, not the curriculum.)

| Letter | Why it's in the set |
|---|---|
| **ه** (haa) | Famously divergent four forms (isolated ه / initial هـ / medial ـهـ / final ـه) — the #1 shaping smoke test |
| **ع / غ** (ain/ghain) | Complex medial form; common rendering breakage |
| **ك** (kaaf) | Distinct initial/medial vs isolated/final; kashida-sensitive |
| **ل** (laam) | Tall joiner; sets up the lam-alef ligature |
| **لا** (lam-alef) | **Mandatory ligature** — must form ﻻ, not two separate glyphs |
| **ب / ت / ث** (baa family) | Tooth-shape + dot positioning across forms |
| **ج / ح / خ** (jiim family) | Descender + medial nub |
| **س / ش** (siin/shiin) | Three-tooth shaping, easy to mis-join |
| **م** (miim) | Loop + descender, medial form |
| **ي** (yaa) | Final-form tail + dots |
| any letter **+ tashkeel** (e.g. بَ بِ بُ بّ) | Verify diacritic placement at line-height 2.0 (D-04) |

For each letter, render **all four forms**.

### How to render a specific positional form in the harness (ZWJ technique)
Flutter shapes based on neighbors. To force an isolated letter into, say, its **medial** form *in the audit only*, surround it with Zero-Width Joiner (U+200D, `‍`):

| Target form | String to render | Notes |
|---|---|---|
| Isolated | `'ه'` | the bare letter |
| Initial | `'ه‍'` | ZWJ after → forces a following-join → initial form |
| Medial | `'‍ه‍'` | ZWJ both sides → medial form |
| Final | `'‍ه'` | ZWJ before → final form |

> ZWJ is an **audit-harness device only** — never put it in real content strings (real shaping comes from the surrounding word). This is the standard, documented way to elicit a single positional form for visual verification. [CITED: Unicode U+200D; Microsoft Learn "Developing OpenType Fonts for Arabic Script"]

### Harness shape (for the planner — not code, just the spec)
- A debug-only screen/widget (e.g. a `GlyphAuditScreen` reachable from a dev route) that renders a grid: rows = letters, columns = the four forms, each cell a `Directionality(rtl)` + `Text(form, style: notoNaskhStyle)` at the **tracing display size** (kit `--fz-ar-display` 96px) so shaping is inspectable at the size children actually see.
- Include one row at line-height 2.0 with tashkeel to verify diacritic stacking.
- Render with the **bundled** TTF (not a system fallback) — confirm by temporarily setting an obviously-distinct font and seeing the glyphs change, so you *know* Noto Naskh is the one shaping.
- A golden/screenshot test (`flutter_test` golden) of this grid makes the audit a **regression gate**: if a font swap or Flutter upgrade changes shaping, the golden diff catches it. (Optional for Phase 1 but recommended — it's the cheapest way to keep the audit "runnable forever.")

### PASS vs FAIL (acceptance criteria)
**PASS** — all of:
- Every cell shows a glyph (no tofu/□/missing-box) at 96px.
- Each form is the *correct contextual shape* (initial connects on the left, final connects on the right, medial connects both — visually verified against a known-good reference such as the same string in a browser or the design kit specimen).
- **لا renders as the single ﻻ ligature**, not ل + ا side by side.
- Connected sequences stay connected (no broken joins, no isolated glyphs mid-word).
- Tashkeel marks sit correctly above/below their base letter at line-height 2.0; no overlap/clipping.
- Western digits placed beside Arabic render as 0–9 in correct LTR order (cross-check with the numeral section).

**FAIL** — any of:
- Tofu/missing glyph for any letter/form.
- A form rendered in the wrong contextual shape (e.g. an isolated ه where a medial ـهـ was forced).
- لا splitting into two glyphs.
- Broken/disconnected joins.
- Tashkeel clipped, mis-positioned, or dropped.

**On FAIL:** first confirm the bundled font is actually the one shaping (font-family wired into the text style, asset declared in `pubspec.yaml`, no `letterSpacing` set). If Noto Naskh genuinely mis-shapes a curriculum letter, **switch the bundled Arabic font to Amiri** (the documented fallback), re-run the audit. Record the outcome in the phase verification notes.

---

## Western-Numeral Isolation (D-06) — concrete Flutter technique

### The core fact that makes this simple
Western digits **0–9 are Unicode codepoints U+0030–U+0039**. They have **no Eastern-Arabic glyph variant at those codepoints** — the Eastern digits ٠١٢ are *different codepoints* (U+0660–U+0669). So **if you put literal `'0'`–`'9'` in your strings, the body font renders Western digit shapes. Period.** There is no font-feature or locale that turns U+0031 into ١.

**Therefore the only real problem is bidi *ordering*, not digit *shape*** — inside an RTL island, a run of digits could be reordered. Two guarantees solve it:

1. **Never generate digits via `intl.NumberFormat` on an `ar` locale.** That's the *only* mechanism that would substitute Eastern-Arabic digits, and D-06 forbids it. Build digit strings as plain Western strings (or, if you ever must format, use a Western/`en` locale or `ar-u-nu-latn`). [CITED: dart-lang/i18n #477]
2. **LTR-isolate digit runs inside RTL Arabic.** Mirror the kit's `.q-num` (`unicode-bidi: isolate; direction: ltr`).

### Concrete Flutter implementations (pick per case)

**Case A — digits standing alone (counters, page numbers, ages):** they're in English/LTR chrome anyway → nothing special needed; default LTR renders 0–9 correctly.

**Case B — digits embedded inside an Arabic RTL `Text`:** force an LTR run. Two equivalent, verified techniques:

- **Widget-level isolate (preferred, explicit):** build the line as a `RichText`/`Text.rich` where the digit `TextSpan` (or a small inline widget) is wrapped so its direction is LTR — practically, put digits in their own `Directionality(textDirection: TextDirection.ltr)` widget within a `Row`/`WidgetSpan` inside the RTL block. This is the direct analog of `.q-num`'s `unicode-bidi: isolate`.
- **Unicode-isolate characters (string-level):** wrap the digit substring in **LRI … PDI** — `⁦` (Left-to-Right Isolate) before, `⁩` (Pop Directional Isolate) after: `'سنة ⁦${age}⁩'`. LRI/PDI are the modern, safe isolates (Unicode 6.3+) that don't leak direction into surrounding text. This is the lowest-overhead approach and works inside a single `Text`. [CITED: Unicode Bidi; W3C inline-bidi]

**Recommendation:** bake **both** into the `ArabicText` wrapper widget so callers never think about it: the wrapper renders Arabic in `Directionality(rtl)` and, for any digits, applies LRI/PDI isolation. One low-magic widget = D-06 satisfied app-wide. Use `tnum` (tabular figures) via `FontFeature.tabularFigures()` if digits must align in columns (the kit's `.q-num` sets `"tnum" 1`).

### Pitfalls
- **`intl` on `ar` is the trap.** Eastern-Arabic digits sneak in *only* through locale-aware number/date formatting. Audit that v1 never formats numbers through an `ar` locale (it shouldn't — chrome is English).
- **Don't reverse strings manually** to "fix" digit order — the bidi algorithm + isolate already handles it; manual reversal double-corrupts.
- **Mixed digit + Arabic punctuation** (e.g. `2:30`, `1-5`) can reorder around the colon/hyphen — isolate the *whole* numeric token with LRI/PDI, not just the digits.
- **Verify in the glyph audit:** add a row mixing Arabic + Western digits and confirm 0–9 appear, in order, LTR, in the body font.

---

## Common Pitfalls (Phase-1 shell specific)

### Pitfall 1: Global RTL leaks into English chrome
**What goes wrong:** Setting `TextDirection.rtl` at `MaterialApp`/root mirrors the whole app — back/next, nav rail, parent screens all flip. Violates D-05.
**How to avoid:** No root `Directionality` override. Apply RTL only in the `ArabicText`/content wrapper. Keep `EdgeInsetsDirectional`/`start`/`end` everywhere so *if* a block is RTL it mirrors, but the app default stays LTR.
**Warning sign:** the placeholder home's English button moves to the right edge.

### Pitfall 2: letterSpacing on Arabic breaks joining
**What goes wrong:** A theme `TextStyle` with `letterSpacing` applied to Arabic disconnects letters (flutter/flutter #71220).
**How to avoid:** Define the Arabic text style with `letterSpacing: 0` (or unset) explicitly; never inherit a tracked English style onto Arabic. The kit already forbids tracking on Arabic.
**Warning sign:** Arabic letters render isolated/disconnected mid-word.

### Pitfall 3: System font fallback masks a missing bundled glyph
**What goes wrong:** Audit "passes" because the OS Arabic font shaped the text — but the bundled Noto Naskh wasn't actually wired, so production on a different device shows tofu.
**How to avoid:** In the audit, prove the bundled font is shaping (swap-test as above). Confirm `pubspec.yaml` `fonts:` declares the family and the `TextStyle.fontFamily` matches exactly.
**Warning sign:** Arabic looks right in dev but differs across devices.

### Pitfall 4: gen-l10n over-engineered for English-only v1
**What goes wrong:** Wiring Arabic `.arb` files, locale switching, and RTL-on-locale now — contradicts D-07 ("English strings only, keep it low-magic") and risks coupling RTL to locale (it must be coupled to *content*, not locale).
**How to avoid:** One `app_en.arb`, `l10n.yaml`, `flutter: generate: true`. No `app_ar.arb`. RTL stays a per-widget content decision, independent of the l10n locale.
**Warning sign:** A `supportedLocales` list with `ar`, or `Directionality` driven by `Localizations.localeOf`.

### Pitfall 5: Landscape lock not enforced at both layers
**What goes wrong:** Locking only via `SystemChrome.setPreferredOrientations` lets the app briefly rotate on cold start before Dart runs; locking only in the manifest misses runtime.
**How to avoid:** Set `android:screenOrientation` in `AndroidManifest.xml` **and** call `SystemChrome.setPreferredOrientations([landscapeLeft, landscapeRight])` in `main()` before `runApp`. Belt and suspenders (D-10).
**Warning sign:** A portrait flash on launch.

## Code Examples

> Patterns only (the planner/executor writes the code). Sources are official Flutter/Unicode references.

### Forcing a positional form in the glyph-audit harness (ZWJ)
```
// audit cells — NOT for production strings
isolated: 'ه'
initial : 'ه‍'      // ZWJ after
medial  : '‍ه‍' // ZWJ both sides
final   : '‍ه'       // ZWJ before
// Source: Unicode U+200D; Microsoft Learn — Developing OpenType Fonts for Arabic Script
```

### LTR-isolating Western digits inside an Arabic RTL string
```
// inside a Directionality(rtl) Text:
'العمر ⁦${age}⁩ سنوات'   // LRI(U+2066) … PDI(U+2069) around the digit token
// Source: Unicode Bidirectional Algorithm (isolates, Unicode 6.3+); W3C inline-bidi-markup
```

### Landscape lock in main()
```
// Source: api.flutter.dev SystemChrome.setPreferredOrientations
WidgetsFlutterBinding.ensureInitialized();
await SystemChrome.setPreferredOrientations(
  [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
// + android:screenOrientation="landscape" (or "sensorLandscape") in AndroidManifest.xml
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| `riverpod_lint` via `custom_lint` | `riverpod_lint` via `analysis_server_plugin` (config in `analysis_options.yaml`) | Riverpod v3 line | STACK.md already notes this; planner must configure the analysis-server plugin, not `custom_lint`. [VERIFIED: pub.dev] |
| RLE/LRE/PDF embedding chars for bidi | LRI/RLI/FSI/PDI **isolates** (Unicode 6.3+) | Unicode 6.3 | Use LRI/PDI for digit isolation — isolates don't leak direction into surrounding text. [CITED: W3C] |
| `arabic_reshaper` to "fix" Arabic in Flutter | Native engine shaping with a complete bundled font | Modern Flutter | Reshapers are obsolete for correct pipelines and corrupt correct text; do not use. |

**Deprecated/outdated for this phase:**
- `intl.NumberFormat` on `ar` for displaying numbers — produces inconsistent Eastern digits; D-06 avoids it entirely.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The curriculum's Arabic letters will all shape correctly in Noto Naskh Arabic — assumed, **to be PROVEN by the D-12 audit**, not yet verified against the real curriculum letter list (owner's mother's set is P2) | Font Decision / Glyph Audit | Low — the audit is the verification gate; Amiri fallback exists. The Phase-1 representative set de-risks it. |
| A2 | Bundling static TTF weights (not the variable font) is the lower-risk choice | Standard Stack | Low — if a variable font is preferred, verify named-instance rendering in the audit. |
| A3 | go_router 17.x has no breaking change affecting a minimal route tree + redirect | Standard Stack | Low — minimal usage; confirm redirect API at plan time. |
| A4 | Cairo's logo weight is ~600/700 (exact weight to bundle) | Standard Stack (fonts) | Trivial — check the قلم wordmark in the kit and bundle the matching weight. |

**Note:** No assumption here overturns a CONTEXT.md decision. A1 is the only one that *could* (if the audit fails on Noto Naskh) trigger the documented Amiri fallback — which is an *anticipated* outcome path, not a contradiction of D-03.

## Open Questions

1. **Exact curriculum letter set for the audit**
   - What we know: representative tricky-joiner set is sufficient to stress Flutter's shaper now.
   - What's unclear: the owner's mother's exact letter/intro order (P2).
   - Recommendation: run the audit on the representative set in Phase 1; re-run on the real set when P2 lands. The harness is reusable.

2. **Variable vs static font instances**
   - Recommendation: bundle static weights for Phase 1; revisit only if file size or weight flexibility demands it.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Flutter SDK (stable) | entire phase | assume ✓ (project already builds) | 3.44.x | — |
| Android tablet / emulator (landscape) | glyph audit visual check, landscape lock | assume ✓ | — | run audit on emulator; verify final glyphs on a real tablet |
| OFL font TTFs (Noto Naskh, Cairo, Fredoka, Nunito) | D-03 | downloadable (OFL) | latest | bundle from Google Fonts repo |

**Missing dependencies with no fallback:** none identified — Phase 1 is local code/config + bundled assets.
**Note:** ML Kit `ar` model download is a *later-phase* concern (not Phase 1) — do not pull it in here.

## Validation Architecture

> `.planning/config.json` not inspected in this session; treating `nyquist_validation` as enabled (default). If explicitly false, omit.

### Test Framework
| Property | Value |
|---|---|
| Framework | `flutter_test` (SDK) + golden tests |
| Config file | none yet — Wave 0 sets up `test/` |
| Quick run command | `flutter test test/theme_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Decision | Behavior | Test Type | Command | File Exists? |
|---|---|---|---|---|
| D-12 | Noto Naskh shapes 4 forms, no tofu, لا ligature | golden / widget | `flutter test test/glyph_audit_golden_test.dart` | ❌ Wave 0 |
| D-06 | Western digits render 0–9, LTR, inside RTL island | golden / widget | `flutter test test/numeral_isolation_test.dart` | ❌ Wave 0 |
| D-05 | App default LTR; only Arabic island is RTL | widget | `flutter test test/direction_test.dart` | ❌ Wave 0 |
| D-09 | Drift persist value survives "restart" (new DB instance) | unit | `flutter test test/data/app_database_test.dart` | ❌ Wave 0 |
| D-01/D-02 | Theme exposes semantic tokens (primary/bg/reward) | unit | `flutter test test/theme_test.dart` | ❌ Wave 0 |
| D-10 | Landscape orientations set | widget/manual | manual + manifest assertion | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the relevant single test file.
- **Per wave merge:** `flutter test`.
- **Phase gate:** full suite green + the **glyph-audit golden** reviewed by a human (visual PASS) before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/glyph_audit_golden_test.dart` — D-12 (the risk gate)
- [ ] `test/numeral_isolation_test.dart` — D-06
- [ ] `test/direction_test.dart` — D-05
- [ ] `test/data/app_database_test.dart` — D-09 (in-memory Drift)
- [ ] `test/theme_test.dart` — D-01/D-02
- [ ] golden infrastructure (reference images) for the audit

## Security Domain

> Phase 1 is a shell with a trivial local persist-proof; no auth, no network, no child PII yet (profiles are P5). Minimal surface.

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V5 Input Validation | minimal | No user input beyond a trivial persisted value in Phase 1 |
| V6 Cryptography | no | No secrets, no key material in v1 (tutor key is v2, server-only) |
| V8/V9 Data/Storage | light | Drift DB lives in app-private storage (path_provider documents dir); keep it private. Real child-data protections arrive with profiles (P5) — leave the repository seam, store nothing sensitive now. |

**Threat note for the shell:** the only carry-forward rule is PITFALLS.md's "treat local-only ≠ privacy-handled" — Phase 1 must not log or persist anything sensitive (it has nothing sensitive yet), and must not wire any network/telemetry. No client-side keys (Decided). Nothing in Phase 1 introduces a child-data or crypto surface.

## Sources

### Primary (HIGH confidence)
- pub.dev — flutter_riverpod 3.3.1, riverpod_annotation 4.0.2, riverpod_generator 4.0.3, riverpod_lint 3.1.3 (analysis_server_plugin), drift 2.33.0, go_router 17.2.3, build_runner 2.15.0, flutter_svg 2.3.0 (versions verified 2026-05-31)
- docs.flutter.dev/release/release-notes — Flutter 3.44.x current stable (updated 2026-05-15/20)
- github.com/flutter/engine PR #21974 — Flutter engine specifies **Noto Naskh Arabic** as reference Arabic test font (decisive for the font decision)
- github.com/flutter/flutter #143975 — Lateef/Scheherazade New mis-shape Arabic in Flutter; **Amiri renders correctly** (open, P2)
- github.com/flutter/flutter #71220 — letterSpacing breaks Arabic joining
- Unicode U+200D (ZWJ) + Microsoft Learn "Developing OpenType Fonts for Arabic Script" — positional-form forcing technique
- Unicode Bidirectional Algorithm / W3C inline-bidi-markup — LRI(U+2066)/PDI(U+2069) isolates for digit handling

### Secondary (MEDIUM confidence)
- github.com/notofonts/arabic #192 — Noto Naskh لله (Allah) ligature-with-tashkeel defect (niche; closed; irrelevant to single-letter teaching)
- dart-lang/i18n #477 — intl shows Eastern-Arabic digits on `ar` locale; `ar-u-nu-latn` / Western-locale workaround
- fonts.google.com — Noto Naskh Arabic / Amiri / Cairo / Fredoka / Nunito are OFL Naskh/display faces with full positional coverage
- talkpal.ai, nooracademy.com — Naskh is the standard teaching script; both Noto Naskh and Amiri praised for learner legibility (LOW–MEDIUM; corroborating, not decisive)

### Tertiary (LOW — flagged)
- arabic_reshaper (pub.dev) — noted only to recommend **against** using it for correct pipelines

## Metadata

**Confidence breakdown:**
- Font decision: HIGH — engine-test evidence + documented Flutter font behavior directly resolve the conflict; confirms D-03.
- Glyph-audit method: HIGH — ZWJ form-forcing and PASS/FAIL criteria are standard and runnable.
- Numeral isolation: HIGH — grounded in Unicode codepoint facts + bidi isolates; the "intl-only" risk is precisely scoped.
- RTL shell pitfalls: HIGH — each trap maps to a documented Flutter issue or the design-kit rule.
- Package versions: HIGH — verified live on pub.dev 2026-05-31.

**Research date:** 2026-05-31
**Valid until:** ~2026-06-30 (pub.dev versions move; Flutter Arabic bug status worth re-checking before P3 builds the tracing surface)
