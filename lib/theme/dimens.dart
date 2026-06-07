// Design-kit spacing / radii / elevation / motion tokens, translated one-way
// from colors_and_type.css (spacing L98–117, radii L119–127, elevation L129–141,
// motion L143–153). Widgets read these consts, never raw magic numbers.

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'colors.dart';

/// 4px-base spacing scale (CSS L101–112).
abstract final class QalamSpace {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16; // default gap / min gap between touch targets
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;
  static const double space20 = 80;
  static const double space24 = 96;
}

/// Touch-target floors — kids-UX rule (CSS L115–117; SKILL.md). Interactive
/// elements must be >= targetMin and >= space4 apart.
abstract final class QalamTargets {
  static const double targetMin = 64;
  static const double targetComfy = 72;
  static const double targetLarge = 96;
}

/// Corner radii — tactile, rounded; nothing sharp (CSS L122–127).
abstract final class QalamRadii {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double xl2 = 36;
  static const double pill = 999;
}

/// Soft, low elevation — never glossy (CSS L132–141).
abstract final class QalamShadows {
  static const Color _ink = Color(0xFF0E5B5F); // deep-ink, matches CSS rgba base

  static const List<BoxShadow> shadowSm = <BoxShadow>[
    BoxShadow(color: Color(0x0F0E5B5F), offset: Offset(0, 1)), // 6% deep-ink
    BoxShadow(color: Color(0x1A0E5B5F), offset: Offset(0, 2), blurRadius: 6, spreadRadius: -2),
  ];

  static const List<BoxShadow> shadowMd = <BoxShadow>[
    BoxShadow(color: Color(0x0F0E5B5F), offset: Offset(0, 2)),
    BoxShadow(color: Color(0x2E0E5B5F), offset: Offset(0, 8), blurRadius: 18, spreadRadius: -8),
  ];

  static const List<BoxShadow> shadowLg = <BoxShadow>[
    BoxShadow(color: Color(0x0F0E5B5F), offset: Offset(0, 4)),
    BoxShadow(color: Color(0x3D0E5B5F), offset: Offset(0, 18), blurRadius: 30, spreadRadius: -16),
  ];

  /// Signature flat-bottom "sticker" shadow for primary buttons (CSS L140:
  /// `--shadow-button: 0 4px 0 0 var(--deep-ink)`).
  static const List<BoxShadow> buttonShadow = <BoxShadow>[
    BoxShadow(color: _ink, offset: Offset(0, 4)),
  ];

  /// Pressed-state sticker shadow (CSS L141: `0 1px 0 0 deep-ink`).
  static const List<BoxShadow> buttonShadowPressed = <BoxShadow>[
    BoxShadow(color: _ink, offset: Offset(0, 1)),
  ];
}

/// Motion — gentle, never slapstick (CSS L146–152).
abstract final class QalamMotion {
  static const Cubic easeOutQuart = Cubic(0.22, 1, 0.36, 1);
  static const Cubic easeInOut = Cubic(0.65, 0, 0.35, 1);
  static const Cubic easeSoftBack = Cubic(0.34, 1.3, 0.64, 1); // gentle overshoot

  static const Duration durFast = Duration(milliseconds: 140);
  static const Duration durBase = Duration(milliseconds: 220);
  static const Duration durSlow = Duration(milliseconds: 420);
  static const Duration durCheer = Duration(milliseconds: 700);

  /// "Watch me write" pen-tracing pace — deliberately slow and followable so a
  /// 5–10yo can track the stroke order. Paired with a linear curve for an even
  /// pen speed (no lurch-then-crawl).
  static const Duration durWrite = Duration(milliseconds: 1400);
}

/// Ink-stroke rendering constants for the Practice spike (UI-SPEC Ink Rendering).
abstract final class QalamInk {
  static const Color strokeColor = QalamColors.inkStroke; // deep-ink #0E5B5F
  static const double strokeWidth = 6; // 4–8px range
}
