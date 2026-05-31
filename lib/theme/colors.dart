// Design-kit color tokens, translated one-way from
// docs/design/kit/project/colors_and_type.css (:root, lines 9–58).
//
// Widgets read the SEMANTIC tokens on [QalamColors] — never the raw `_private`
// palette, never raw hex (D-01/D-02). Background is warm parchment, never white.
// Gold is rewards-only; coral is the only "error" color — there is no red.

import 'package:flutter/painting.dart';

// --- CORE PALETTE (CSS L13–21) — private; only the semantic layer exposes these.
const _parchment = Color(0xFFFAF6EE); // --parchment   (bg, never #FFFFFF)
const _softAqua = Color(0xFFEAF4F4); // --soft-aqua    (surfaces)
const _inkTeal = Color(0xFF168A8F); // --ink-teal      (primary)
const _deepInk = Color(0xFF0E5B5F); // --deep-ink      (pressed / headers / ink stroke)
const _goldInk = Color(0xFFF2A60C); // --gold-ink      (REWARDS ONLY)
const _leaf = Color(0xFF3FB984); // --leaf            (success)
const _coral = Color(0xFFFF8A6B); // --coral           (warn-soft — never red)
const _inkCharcoal = Color(0xFF222A2E); // --ink-charcoal (fg — not pure black)
const _slate = Color(0xFF5C6B70); // --slate           (fg-muted)

// --- TINTS (CSS L23–31) — subtle surfaces, borders, ink-washes.
const _parchmentDeep = Color(0xFFF3ECDC); // --parchment-deep
const _parchmentEdge = Color(0xFFE8DFC9); // --parchment-edge
const _aquaEdge = Color(0xFFD6E8E8); // --aqua-edge
const _tealTint = Color(0xFFDCEEEF); // --teal-tint
const _goldTint = Color(0xFFFCEBC6); // --gold-tint
const _leafTint = Color(0xFFD8F0E5); // --leaf-tint
const _coralTint = Color(0xFFFFE2D9); // --coral-tint

/// Semantic color tokens (CSS L33–58). Widgets reference THESE, not raw hex.
abstract final class QalamColors {
  // Surfaces / backgrounds
  static const Color bg = _parchment; // --bg
  static const Color bgDeep = _parchmentDeep; // --bg-deep
  static const Color surface = _softAqua; // --surface
  static const Color surfaceRaised = Color(0xFFFFFFFF); // --surface-raised (sparingly)
  static const Color border = _aquaEdge; // --border
  static const Color borderSoft = _parchmentEdge; // --border-soft

  // Text
  static const Color fg = _inkCharcoal; // --fg
  static const Color fgMuted = _slate; // --fg-muted
  static const Color fgOnPrimary = Color(0xFFFFFFFF); // --fg-on-primary

  // Primary (ink-teal)
  static const Color primary = _inkTeal; // --primary
  static const Color primaryPressed = _deepInk; // --primary-pressed
  static const Color primaryTint = _tealTint; // --primary-tint

  // Reward (gold — REWARDS ONLY; absent in Phase 1, token wired only)
  static const Color reward = _goldInk; // --reward
  static const Color rewardTint = _goldTint; // --reward-tint

  // Success (leaf)
  static const Color success = _leaf; // --success
  static const Color successTint = _leafTint; // --success-tint

  // Soft-warn (coral — the only "error" color; never red)
  static const Color warnSoft = _coral; // --warn-soft
  static const Color warnSoftTint = _coralTint; // --warn-soft-tint

  // Ink-stroke color for the Practice canvas (deep-ink).
  static const Color inkStroke = _deepInk;
}
