// QalamMascot — the tutor's persona, rendered from the bundled brand SVGs.
//
// The reed-pen character is the consistent face of the patient teacher
// (CLAUDE.md: "Qalam mascot = the tutor's persona", not a game mascot). Each
// pose maps to a screen state in the demo (DP-08):
//
//   idle     → home / journey
//   write    → Watch demo (stroke-order demonstration)
//   cheer    → celebration
//   tryAgain → miss feedback
//   think    → reflective / between-states
//
// One concern, one widget, const constructor — the house style mirrored from
// ArabicText. There is exactly ONE asset-render path, and it is
// guarded by an error fallback so a missing or corrupt asset degrades to a
// calm placeholder Container (parchment-tinted, rounded) — never a red error
// box, never debug text, never a crash. A missing asset can therefore never
// break a stage screenshot (DP-08/DP-09). Tokens only; no raw hex, no red.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/colors.dart';
import '../theme/dimens.dart';

/// The tutor poses, each bound to a demo screen state (DP-08).
enum QalamPose { idle, write, cheer, tryAgain, think }

/// Renders one Qalam mascot pose from `assets/mascot/qalam-*.svg`, with a
/// graceful fallback if the asset cannot be loaded.
class QalamMascot extends StatelessWidget {
  const QalamMascot({
    super.key,
    required this.pose,
    this.size = QalamSpace.space24, // sensible hero size (96px)
    this.semanticsLabel,
  });

  /// Which pose to render.
  final QalamPose pose;

  /// Side length (the SVG renders square; width == height == size).
  final double size;

  /// Accessibility label; defaults to a warm description of the pose.
  final String? semanticsLabel;

  /// Maps a pose to its bundled asset path. Single source of truth.
  static String _assetFor(QalamPose pose) {
    switch (pose) {
      case QalamPose.idle:
        return 'assets/mascot/qalam-idle.svg';
      case QalamPose.write:
        return 'assets/mascot/qalam-write.svg';
      case QalamPose.cheer:
        return 'assets/mascot/qalam-cheer.svg';
      case QalamPose.tryAgain:
        return 'assets/mascot/qalam-try-again.svg';
      case QalamPose.think:
        return 'assets/mascot/qalam-think.svg';
    }
  }

  /// A non-empty default label per pose (overridable for context).
  static String _defaultLabel(QalamPose pose) {
    switch (pose) {
      case QalamPose.idle:
        return 'Qalam, your writing teacher';
      case QalamPose.write:
        return 'Qalam showing how to write';
      case QalamPose.cheer:
        return 'Qalam cheering you on';
      case QalamPose.tryAgain:
        return 'Qalam, ready to try again together';
      case QalamPose.think:
        return 'Qalam thinking';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetFor(pose),
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: semanticsLabel ?? _defaultLabel(pose),
      placeholderBuilder: (_) => _MascotFallback(size: size),
      errorBuilder: (context, error, stackTrace) =>
          _MascotFallback(size: size),
    );
  }
}

/// Calm placeholder shown when a mascot asset is missing or fails to decode.
/// A sized, rounded, muted box that keeps layout stable for a screenshot — no
/// red, no debug text (DP-08/DP-09).
class _MascotFallback extends StatelessWidget {
  const _MascotFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: QalamColors.surface,
        borderRadius: BorderRadius.circular(QalamRadii.xl),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline,
        size: size / 2,
        color: QalamColors.fgMuted,
      ),
    );
  }
}
