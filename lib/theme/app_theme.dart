// The app ThemeData, composed from the semantic tokens (colors.dart),
// the type scale (text_styles.dart), and the brand ThemeExtension
// (brand_theme_ext.dart). Material 3, parchment scaffold (never white — D-02),
// ink-teal primary, Nunito default. The Flutter-scaffold seed color is gone.

import 'package:flutter/material.dart';

import 'brand_theme_ext.dart';
import 'colors.dart';
import 'text_styles.dart';

/// The single app theme. App chrome defaults to LTR; RTL is per-content
/// (ArabicText), never set on the theme (D-05).
final ThemeData qalamTheme = _buildQalamTheme();

ThemeData _buildQalamTheme() {
  const ColorScheme scheme = ColorScheme.light(
    primary: QalamColors.primary,
    onPrimary: QalamColors.fgOnPrimary,
    secondary: QalamColors.primaryPressed,
    onSecondary: QalamColors.fgOnPrimary,
    surface: QalamColors.surface,
    onSurface: QalamColors.fg,
    error: QalamColors.warnSoft, // coral — the only "error" color; never red
    onError: QalamColors.fgOnPrimary,
  );

  final TextTheme textTheme = const TextTheme(
    displayLarge: QalamTextStyles.display,
    headlineMedium: QalamTextStyles.heading,
    titleMedium: QalamTextStyles.heading,
    bodyLarge: QalamTextStyles.body,
    bodyMedium: QalamTextStyles.body,
    labelLarge: QalamTextStyles.button,
    labelMedium: QalamTextStyles.label,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: QalamColors.bg, // parchment, never stark white
    fontFamily: QalamFonts.body, // Nunito default
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: QalamColors.bg,
      foregroundColor: QalamColors.primary,
      elevation: 0,
      centerTitle: false,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      QalamTheme.light,
    ],
  );
}
