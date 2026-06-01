// DemoHomeScreen — the de-gamified opening of the alif walkthrough (DP-04/DP-06).
//
// Home sets the warm, calm tone: the idle-pose Qalam mascot greets the child by
// name, and a single alif "Today's Lesson" card is the one clear way forward —
// tap it to Watch. The screen DELIBERATELY OMITS every gamification element from
// the design mockup (DP-06, BINDING): no header "⭐ N" counter, no "THIS WEEK ·
// N stars" tally, no three-star lesson rating, no "+N" hype, no progress-as-score
// bar. A star here would read as a score; the product's stance is "Real Arabic.
// Not a game." — so there are none on Home.
//
// Mocked-data demo (DP-01): no scorer, no persistence, no network. All copy
// reads through gen-l10n (null-safe, so a bare test harness still renders), and
// every color/space/radius is a design-system token (DP-02) — parchment ground,
// never white, no raw hex.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/brand_theme_ext.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import '../../widgets/arabic_text.dart';
import '../../widgets/qalam_mascot.dart';
import '../demo_alif.dart';

class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String greeting = l10n?.demoHomeGreeting ?? "Let's learn, Layla.";
    final String eyebrow = l10n?.demoLessonEyebrow ?? "TODAY'S LESSON";
    final String lessonTitle = l10n?.demoLessonTitle ?? 'Alif';

    return Scaffold(
      backgroundColor: QalamColors.bg, // parchment — never white
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(QalamSpace.space8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // The idle mascot greeting the child by name.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const QalamMascot(
                          pose: QalamPose.idle,
                          size: QalamSpace.space20,
                        ),
                        const SizedBox(width: QalamSpace.space6),
                        Flexible(
                          child: Text(
                            greeting,
                            style: QalamTextStyles.display,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: QalamSpace.space10),
                    _LessonCard(
                      eyebrow: eyebrow,
                      title: lessonTitle,
                      // Canonical path is DemoStep.watch.path ('/demo/watch').
                      onTap: () => context.go('/demo/watch'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The single "Today's Lesson" card — a raised surface showing the alif glyph
/// through the ArabicText RTL island, tappable into Watch. It is the one
/// affordance on Home (no competing chrome). >= targetComfy touch target.
class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.eyebrow,
    required this.title,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final QalamTheme qalam =
        Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(QalamRadii.xl),
        boxShadow: qalam.buttonShadow,
      ),
      child: Material(
        color: QalamColors.surface, // soft-aqua raised card
        borderRadius: BorderRadius.circular(QalamRadii.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: QalamTargets.targetLarge,
              maxWidth: 520,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space10,
              vertical: QalamSpace.space8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  eyebrow,
                  style: QalamTextStyles.label,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: QalamSpace.space4),
                // The alif glyph as a display island — the lesson's face.
                ArabicText(DemoAlif.glyph, display: true),
                const SizedBox(height: QalamSpace.space2),
                Text(
                  title,
                  style: QalamTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
