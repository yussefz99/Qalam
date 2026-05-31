// Design-kit type scale, translated one-way from colors_and_type.css
// (type scale L60–96, utility classes L169–186). UI-SPEC Typography tables give
// the Phase-1 role subset; the full --fz scale is declared so later phases reuse it.
//
// HARD RULES (SKILL.md / Pitfall 2):
//  - Arabic styles NEVER carry letterSpacing/wordSpacing — it breaks joining
//    (#71220). The Arabic roles below set letterSpacing: 0 explicitly.
//  - Arabic is never bold/italic — weight variation only.
//  - Font-family strings must match pubspec.yaml EXACTLY (Pitfall 3).
//  - No Inter/Roboto anywhere.

import 'package:flutter/painting.dart';

import 'colors.dart';

/// Bundled font-family strings (must match pubspec.yaml `fonts:` exactly).
abstract final class QalamFonts {
  static const String display = 'Fredoka'; // English display / headings / buttons
  static const String body = 'Nunito'; // English body / labels / numerals
  static const String arabic = 'Noto Naskh Arabic'; // Arabic reading content
  static const String arabicDisplay = 'Cairo'; // Arabic display / قلم logo wordmark
}

/// The full English type scale (CSS L72–81). Phase 1 renders only the roles
/// surfaced as named styles below; the scale is declared for later phases.
abstract final class QalamFontSizes {
  static const double fz12 = 12;
  static const double fz14 = 14;
  static const double fz16 = 16;
  static const double fz18 = 18;
  static const double fz20 = 20;
  static const double fz24 = 24;
  static const double fz28 = 28;
  static const double fz34 = 34;
  static const double fz42 = 42;
  static const double fz56 = 56;

  // Arabic content sizes (CSS L84–86) — 10–25% larger than nearby English.
  static const double arBody = 26;
  static const double arLarge = 40;
  static const double arDisplay = 96;
}

/// English + Arabic named text roles.
abstract final class QalamTextStyles {
  // --- English roles (CSS utilities L169–176; UI-SPEC L74–80).
  /// H1 / display — Fredoka 600, 42px, lh 1.15 (.q-h1).
  static const TextStyle display = TextStyle(
    fontFamily: QalamFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: QalamFontSizes.fz42,
    height: 1.15,
    color: QalamColors.fg,
  );

  /// H3 / heading — Fredoka 500, 28px, lh 1.3 (.q-h3).
  static const TextStyle heading = TextStyle(
    fontFamily: QalamFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: QalamFontSizes.fz28,
    height: 1.3,
    color: QalamColors.fg,
  );

  /// Button — Fredoka 500, 24px, lh 1.0 (.q-button).
  static const TextStyle button = TextStyle(
    fontFamily: QalamFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: QalamFontSizes.fz24,
    height: 1.0,
  );

  /// Body — Nunito 400, 18px, lh 1.5 (.q-body). Kids-UX floor.
  static const TextStyle body = TextStyle(
    fontFamily: QalamFonts.body,
    fontWeight: FontWeight.w400,
    fontSize: QalamFontSizes.fz18,
    height: 1.5,
    color: QalamColors.fg,
  );

  /// Label — Nunito 600, 16px, lh 1.3 (.q-label).
  static const TextStyle label = TextStyle(
    fontFamily: QalamFonts.body,
    fontWeight: FontWeight.w600,
    fontSize: QalamFontSizes.fz16,
    height: 1.3,
    color: QalamColors.fgMuted,
  );

  // --- Arabic roles (CSS .q-ar* L179–182; UI-SPEC L88–90).
  // CRITICAL: never set letterSpacing on these (Pitfall 2). lh 1.7 plain;
  // callers may apply 2.0 for tashkeel.
  /// Arabic body — Noto Naskh 400, 26px, lh 1.7 (.q-ar).
  static const TextStyle arBody = TextStyle(
    fontFamily: QalamFonts.arabic,
    fontWeight: FontWeight.w400,
    fontSize: QalamFontSizes.arBody,
    height: 1.7,
    letterSpacing: 0, // never break Arabic joining (Pitfall 2 / #71220)
    color: QalamColors.fg,
  );

  /// Arabic large — Noto Naskh 400, 40px, lh 2.0 (.q-ar-large).
  static const TextStyle arLarge = TextStyle(
    fontFamily: QalamFonts.arabic,
    fontWeight: FontWeight.w400,
    fontSize: QalamFontSizes.arLarge,
    height: 2.0,
    letterSpacing: 0,
    color: QalamColors.fg,
  );

  /// Arabic display — Cairo 500, 96px, lh 1.1 (.q-ar-display); deep-ink.
  static const TextStyle arDisplay = TextStyle(
    fontFamily: QalamFonts.arabicDisplay,
    fontWeight: FontWeight.w500,
    fontSize: QalamFontSizes.arDisplay,
    height: 1.1,
    letterSpacing: 0,
    color: QalamColors.primaryPressed,
  );
}
