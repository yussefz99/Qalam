// QalamTheme — a ThemeExtension carrying the brand tokens Material's ColorScheme
// has no slot for: reward/warnSoft/success tints, the signature sticker
// buttonShadow, the ink-stroke color, and motion tokens (CONTEXT D-01).
//
// Read in widgets via `Theme.of(context).extension<QalamTheme>()!`; registered
// on ThemeData in app_theme.dart. `QalamTheme.light` is the const default.

import 'package:flutter/material.dart';

import 'colors.dart';
import 'dimens.dart';

// Re-export the composed app theme so callers that hold a QalamTheme reference
// can also reach `qalamTheme` (and the theme_test, which imports only this file).
export 'app_theme.dart' show qalamTheme;

@immutable
class QalamTheme extends ThemeExtension<QalamTheme> {
  const QalamTheme({
    required this.reward,
    required this.rewardTint,
    required this.warnSoft,
    required this.warnSoftTint,
    required this.success,
    required this.successTint,
    required this.buttonShadow,
    required this.inkStroke,
    required this.motionBase,
    required this.motionCurve,
  });

  /// The canonical Qalam brand token set (default for the app ThemeData).
  static const QalamTheme light = QalamTheme(
    reward: QalamColors.reward,
    rewardTint: QalamColors.rewardTint,
    warnSoft: QalamColors.warnSoft,
    warnSoftTint: QalamColors.warnSoftTint,
    success: QalamColors.success,
    successTint: QalamColors.successTint,
    buttonShadow: QalamShadows.buttonShadow,
    inkStroke: QalamColors.inkStroke,
    motionBase: QalamMotion.durBase,
    motionCurve: QalamMotion.easeOutQuart,
  );

  /// Gold — REWARDS ONLY (mastery / celebration). Absent in Phase 1.
  final Color reward;
  final Color rewardTint;

  /// Coral — the only "error" color ("let's try again"); never red.
  final Color warnSoft;
  final Color warnSoftTint;

  /// Leaf — correct / success affirmation.
  final Color success;
  final Color successTint;

  /// The flat-bottom "sticker" shadow for primary buttons (CSS --shadow-button).
  final List<BoxShadow> buttonShadow;

  /// Deep-ink stroke color for the Practice ink canvas.
  final Color inkStroke;

  /// Default motion tokens for brand transitions.
  final Duration motionBase;
  final Curve motionCurve;

  @override
  QalamTheme copyWith({
    Color? reward,
    Color? rewardTint,
    Color? warnSoft,
    Color? warnSoftTint,
    Color? success,
    Color? successTint,
    List<BoxShadow>? buttonShadow,
    Color? inkStroke,
    Duration? motionBase,
    Curve? motionCurve,
  }) {
    return QalamTheme(
      reward: reward ?? this.reward,
      rewardTint: rewardTint ?? this.rewardTint,
      warnSoft: warnSoft ?? this.warnSoft,
      warnSoftTint: warnSoftTint ?? this.warnSoftTint,
      success: success ?? this.success,
      successTint: successTint ?? this.successTint,
      buttonShadow: buttonShadow ?? this.buttonShadow,
      inkStroke: inkStroke ?? this.inkStroke,
      motionBase: motionBase ?? this.motionBase,
      motionCurve: motionCurve ?? this.motionCurve,
    );
  }

  @override
  QalamTheme lerp(ThemeExtension<QalamTheme>? other, double t) {
    if (other is! QalamTheme) return this;
    return QalamTheme(
      reward: Color.lerp(reward, other.reward, t)!,
      rewardTint: Color.lerp(rewardTint, other.rewardTint, t)!,
      warnSoft: Color.lerp(warnSoft, other.warnSoft, t)!,
      warnSoftTint: Color.lerp(warnSoftTint, other.warnSoftTint, t)!,
      success: Color.lerp(success, other.success, t)!,
      successTint: Color.lerp(successTint, other.successTint, t)!,
      // BoxShadow lists don't lerp cleanly element-wise here; snap at the midpoint.
      buttonShadow: t < 0.5 ? buttonShadow : other.buttonShadow,
      inkStroke: Color.lerp(inkStroke, other.inkStroke, t)!,
      motionBase: t < 0.5 ? motionBase : other.motionBase,
      motionCurve: t < 0.5 ? motionCurve : other.motionCurve,
    );
  }
}
