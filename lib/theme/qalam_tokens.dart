// QalamTokens — the kit `:root` mapped 1:1 to a Dart constants class, for the
// Phase-7 Letter-Unit exercise components (Plan 07-04).
//
// SOURCE OF TRUTH: docs/design/kit/project/colors_and_type.css (`:root`) plus
// docs/design/prototypes/letter-unit-baa/TOKENS.md (which reconciles the two
// prototype NAME DRIFTS and names the new component-level constants).
//
// WHY THIS EXISTS alongside lib/theme/colors.dart + dimens.dart + text_styles.dart:
// the existing theme files already hold the kit palette/spacing/radii/motion as
// the SEMANTIC layer (QalamColors / QalamSpace / QalamRadii / QalamShadows /
// QalamMotion). This class does NOT fork that palette — every colour below
// REFERENCES the existing QalamColors token (reward/coral/leaf/inkStroke/…),
// per TOKENS.md ("Where lib/theme/colors.dart already defines a token, re-export
// /reference it — do NOT fork the palette"). What it ADDS is:
//   1. the two RECONCILED prototype name drifts as first-class names:
//        `--gold`  → goldInk        (alias of QalamColors.reward)
//        `--white` → surfaceRaised  (alias of QalamColors.surfaceRaised, #FFFFFF)
//   2. the radii the prototype components use by NAME (radiusXl=28, radiusMd=14,
//      radiusLg=20) so a component can cite TOKENS.md radii at the call site.
//   3. the NEW component constants TOKENS.md flags (guide-dash/-stroke,
//      ink-stroke-w, start-dot) that the kit does not yet name.
//
// Anti-gamification (CLAUDE.md Decided): gold (goldInk) is REWARDS ONLY — the
// trace start-dot and the one mastery star. It appears nowhere else in these
// components (the ProgressRibbon, the CTAs, the panels never use it).

import 'package:flutter/painting.dart';

import 'colors.dart';
import 'dimens.dart';

/// The kit `:root` as Dart constants (1:1), for the Letter-Unit components.
///
/// Colours reference [QalamColors] (no palette fork); the two prototype name
/// drifts are reconciled here as [goldInk] / [surfaceRaised] (TOKENS.md).
abstract final class QalamTokens {
  // ── Colours — all reference the existing semantic palette (no fork) ────────

  /// Reconciled prototype `--gold` → kit `--gold-ink` (alias `--reward`).
  /// REWARDS ONLY (the trace start-dot, the one mastery star). TOKENS.md drift 1.
  static const Color goldInk = QalamColors.reward; // #F2A60C

  /// Reconciled prototype `--white` → kit `--surface-raised` (#FFFFFF).
  /// Cards / canvas / speech bubble. TOKENS.md drift 2.
  static const Color surfaceRaised = QalamColors.surfaceRaised; // #FFFFFF

  /// `--parchment` — app background (warm, never stark white).
  static const Color parchment = QalamColors.bg; // #FAF6EE

  /// `--parchment-deep` — the surface-tag chip background.
  static const Color parchmentDeep = QalamColors.bgDeep; // #F3ECDC

  /// `--soft-aqua` — surfaces (e.g. the image-stub hatch base).
  static const Color softAqua = QalamColors.surface; // #EAF4F4

  /// `--ink-teal` — primary actions, the child's ink, the audio play button.
  static const Color inkTeal = QalamColors.primary; // #168A8F

  /// `--deep-ink` — pressed states, headers, Arabic glyphs, the ink stroke.
  static const Color deepInk = QalamColors.primaryPressed; // #0E5B5F

  /// `--leaf` — the pass panel + the leaf tone.
  static const Color leaf = QalamColors.success; // #3FB984

  /// `--leaf-tint` — the pass panel / leaf speech-bubble background.
  static const Color leafTint = QalamColors.successTint; // #D8F0E5

  /// `--coral` — the fix panel + the try-again mascot tone. Never harsh red.
  static const Color coral = QalamColors.warnSoft; // #FF8A6B

  /// `--coral-tint` — the fix panel / coral speech-bubble background.
  static const Color coralTint = QalamColors.warnSoftTint; // #FFE2D9

  /// `--gold-tint` — the gold RULE chip background (instruction chip only; this
  /// is a tint surface, not the reward gold itself).
  static const Color goldTint = QalamColors.rewardTint; // #FCEBC6

  /// `--aqua-edge` — surface borders, the upcoming progress-dot ring.
  static const Color aquaEdge = QalamColors.border; // #D6E8E8

  /// `--teal-tint` — the active progress-dot fill.
  static const Color tealTint = QalamColors.primaryTint; // #DCEEEF

  /// `--fg` — body text.
  static const Color fg = QalamColors.fg; // #222A2E

  /// `--fg-muted` — captions, the surface-tag text, upcoming dots.
  static const Color fgMuted = QalamColors.fgMuted; // #5C6B70

  /// `--fg-on-primary` — text on teal (the play button / primary CTA label).
  static const Color fgOnPrimary = QalamColors.fgOnPrimary; // #FFFFFF

  // ── Radii — kit `--radius-*` by name (TOKENS.md: cards xl, controls md/lg) ──

  /// `--radius-md` (14) — controls.
  static const double radiusMd = QalamRadii.md; // 14

  /// `--radius-lg` (20) — controls / panels.
  static const double radiusLg = QalamRadii.lg; // 20

  /// `--radius-xl` (28) — cards. (Prototype writebox uses 24; cards use 28.)
  static const double radiusXl = QalamRadii.xl; // 28

  /// `--radius-pill` (999) — the surface-tag pill, the rule chip.
  static const double radiusPill = QalamRadii.pill; // 999

  // ── NEW component constants (TOKENS.md "additions to reconcile") ───────────

  /// Trace dotted-guide stroke width — prototype `--guide-stroke` 3.4px.
  static const double guideStroke = 3.4;

  /// Trace dotted-guide dash pattern — prototype `--guide-dash` `1 13`
  /// (1px dash, 13px gap). Exposed as [guideDash]/[guideGap].
  static const double guideDash = 1.0;
  static const double guideGap = 13.0;

  /// Child ink stroke width on the WriteSurface — prototype `--ink-stroke-w`
  /// 12px (heavier than the 6px Practice spike — a deliberate hero weight).
  static const double inkStrokeWidth = 12.0;

  /// The child's ink colour — prototype `--ink-color` = `--deep-ink`.
  static const Color inkColor = deepInk;

  /// Trace gold start-dot radius — prototype `--start-dot` 14px (uses [goldInk]).
  static const double startDotRadius = 14.0;

  /// The faint given-ink guide-glyph colour — prototype `#C7DCDC`
  /// (TOKENS.md `--ink-guide`, between `--aqua-edge` and `--teal-wash`).
  static const Color inkGuide = Color(0xFFC7DCDC);
}
