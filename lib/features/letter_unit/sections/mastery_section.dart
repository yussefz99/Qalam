// MasterySection — Section 6 of the baa Letter Unit (Plan 07-06).
//
// "Mastery" — the quiet close. The child has written baa on their own,
// start-to-end, so the unit ends with the EXISTING dignified celebration:
// ONE settling gold star + the mascot + a warm, specific tutor line. This
// REUSES the existing `MasteryCelebration` widget (practice/widgets) rather
// than rebuilding it — the same one-quiet-star moment shown elsewhere, so the
// celebration is consistent across the app and the anti-gamification invariants
// it already enforces (one star, no totals/streaks/badges) carry over for free.
//
// ANTI-GAMIFICATION (CLAUDE.md Decided; MEMORY design-predates-antigamification):
//   • EXACTLY ONE star (MasteryCelebration's _SettlingStar). NO running total,
//     NO weekly tally, NO streak, NO badge, NO "+N today" — the prototype's
//     `mastery()` says "One quiet star … a milestone, not a score", and that is
//     all this section shows. The prototype's gold sparks are a one-off settle,
//     not a counter; we keep the existing celebration's single settling star.
//   • The star is INFORMATION ("you truly write باب now"), never a score.
//
// CTAs: "Next letter" → [onNext] (the next unit / journey), "See journey" →
// MasteryCelebration's built-in journey link (it navigates
// `/journey?highlight=<id>`). The shell supplies the letter's glyph + name +
// id so the celebration speaks the ACTUAL letter (never a hardcoded 'alif').

import 'package:flutter/material.dart' hide Form;

import '../../../models/letter.dart';
import '../../practice/widgets/mastery_celebration.dart';

/// Section 6 — Mastery. Feed it the just-mastered [letter]; [onNext] advances to
/// the next letter (the prototype's "Next letter"), [onSeeJourney] (when given)
/// overrides the default "Back Home" ghost. The "See journey" link inside the
/// celebration always routes to `/journey?highlight=<letterId>` (D-15).
class MasterySection extends StatelessWidget {
  const MasterySection({
    super.key,
    required this.letter,
    this.onNext,
    this.onSeeJourney,
    this.isLastLetter = false,
  });

  /// The letter the child just mastered — its glyph + name + id drive the
  /// celebration so it speaks the actual letter (Pitfall 6).
  final Letter letter;

  /// "Next letter" — advances to the next unit. Null only on the last letter,
  /// where the primary CTA becomes "See Journey" (D-16, handled by the widget).
  final VoidCallback? onNext;

  /// The "Back Home" ghost CTA handler (the demoted secondary). When null it
  /// falls back to the "See journey" route via the celebration's own link.
  final VoidCallback? onSeeJourney;

  /// True on the final letter — the celebration drops "Next letter" and the
  /// primary slot becomes "See Journey" (no capstone screen).
  final bool isLastLetter;

  @override
  Widget build(BuildContext context) {
    return MasteryCelebration(
      glyph: letter.char,
      letterName: letter.name.display,
      masteredLetterId: letter.id,
      // "Next letter" → the next unit. The celebration's D-14 primary CTA.
      onNextLesson: onNext,
      // "Back Home" ghost → onSeeJourney if supplied, else the celebration's
      // built-in "See journey" link still routes to /journey?highlight=<id>.
      onBackHome: onSeeJourney ?? () {},
      isLastLesson: isLastLetter,
    );
  }
}
