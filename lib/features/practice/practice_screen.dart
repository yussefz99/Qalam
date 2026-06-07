// PracticeScreen — Phase-3 Watch → Trace → Celebrate loop (plan 03-04).
//
// Wires the full core learning loop for alif (lesson_01):
//   1. Watch phase — StrokeOrderAnimation auto-plays; Watch Again / I'll Try.
//   2. Trace phase — StrokeCanvas captures stylus; scored on stylus-up.
//   3. ShowFix phase — FeedbackPanel + Try Again.
//   4. Celebrate phase — MasteryCelebration + Back Home.
//
// State machine: practiceSessionController(lessonId: 'lesson_01') via Riverpod.
// Scoring: scoreStroke(points, referenceStroke) → StrokeResult → controller.
//
// ANTI-GAMIFICATION (PLAT-03 / D-03 / D-08):
//   - NO "THIS WEEK" / weekly bar / star tally.
//   - NO "Play sound" / "Listen" button (Phase 7).
//   - NO "Mark correct" button (D-06 — scorer only).
//   - NO "See journey" button (Phase 6).
//   - NO running star counter.
//   - NO confetti.
//   Enforced by practice_screen_test.dart.
//
// SECURITY (T-03-01/T-01-05): stroke points live in StrokeCanvas widget State.
// Only StrokeResult enters the session controller — no raw Offset list is
// lifted to provider scope.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/scoring/geometric_stroke_scorer.dart';
import '../../core/scoring/scoring_models.dart';
import '../../data/curriculum_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/letter.dart';
import '../../providers/practice_providers.dart';
import '../../theme/brand_theme_ext.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import 'widgets/feedback_panel.dart';
import 'widgets/mastery_celebration.dart';
import 'widgets/stroke_canvas.dart';
import 'widgets/stroke_order_animation.dart';

/// The Phase-3 practice screen — the full Watch → Trace → Celebrate loop.
///
/// Wired to `lesson_01` (alif). Reads [practiceSessionControllerProvider]
/// for phase state and dispatches events to the controller.
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  /// The lesson this screen teaches. Hardwired to lesson_01 (alif) for Phase 3.
  static const String _lessonId = 'lesson_01';

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  /// Key for replaying the stroke-order animation from the Watch Again button.
  final GlobalKey<StrokeOrderAnimationState> _animKey =
      GlobalKey<StrokeOrderAnimationState>();

  // ---------------------------------------------------------------------------
  // Stroke submission — called by StrokeCanvas on stylus-up.
  // ---------------------------------------------------------------------------

  /// Score the submitted stroke and forward only StrokeResult to the controller.
  ///
  /// SECURITY: raw Offset points are used locally for scoring and then discarded.
  /// They are never stored in provider state (Anti-Pattern 3).
  Future<void> _onStrokeSubmitted(
    List<Offset> points,
    StrokeSpec referenceStroke,
  ) async {
    // Convert Offset list → List<List<double>> for the pure-Dart scorer.
    final childStroke = points
        .map((Offset o) => <double>[o.dx, o.dy])
        .toList(growable: false);

    final StrokeResult result = scoreStroke(childStroke, referenceStroke);

    // Only StrokeResult (not raw points) enters the controller.
    await ref
        .read(practiceSessionControllerProvider(PracticeScreen._lessonId)
            .notifier)
        .onStrokeResult(result);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      practiceSessionControllerProvider(PracticeScreen._lessonId),
    );

    // Celebrate phase is full-screen — bypass the Scaffold shell.
    if (state.phase == PracticePhase.celebrate) {
      return MasteryCelebration(
        onBackHome: () => context.go('/'),
      );
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: QalamColors.bg,
      appBar: AppBar(
        backgroundColor: QalamColors.bg,
        elevation: 0,
        leading: BackButton(
          onPressed: () => context.go('/'),
          color: QalamColors.fgMuted,
        ),
        title: Text(
          _eyebrow(l10n, state.phase),
          style: QalamTextStyles.label,
        ),
      ),
      body: SafeArea(
        child: _PracticeBody(
          lessonId: PracticeScreen._lessonId,
          state: state,
          animKey: _animKey,
          onStrokeSubmitted: _onStrokeSubmitted,
          onAdvanceToTrace: () => ref
              .read(practiceSessionControllerProvider(PracticeScreen._lessonId)
                  .notifier)
              .advanceToTrace(),
          onRetry: () => ref
              .read(practiceSessionControllerProvider(PracticeScreen._lessonId)
                  .notifier)
              .retry(),
        ),
      ),
    );
  }

  String _eyebrow(AppLocalizations? l10n, PracticePhase phase) {
    switch (phase) {
      case PracticePhase.watch:
        return l10n?.practiceWatchEyebrow ?? 'WATCH · STROKE ORDER';
      case PracticePhase.trace:
      case PracticePhase.showFix:
        return l10n?.practiceTraceEyebrow ?? 'YOUR TURN · TRACE';
      case PracticePhase.celebrate:
        return l10n?.practiceMasteredEyebrow ?? 'MASTERED';
    }
  }
}

// ---------------------------------------------------------------------------
// _PracticeBody — switches between Watch / Trace+ShowFix phases
// ---------------------------------------------------------------------------

/// The body of the practice screen. Loads the letter via curriculum repo and
/// renders the correct phase view.
class _PracticeBody extends ConsumerWidget {
  const _PracticeBody({
    required this.lessonId,
    required this.state,
    required this.animKey,
    required this.onStrokeSubmitted,
    required this.onAdvanceToTrace,
    required this.onRetry,
  });

  final String lessonId;
  final PracticeState state;
  final GlobalKey<StrokeOrderAnimationState> animKey;
  final Future<void> Function(List<Offset> points, StrokeSpec referenceStroke)
      onStrokeSubmitted;
  final VoidCallback onAdvanceToTrace;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load the letter from the curriculum.
    final curriculumRepo = ref.watch(curriculumRepositoryProvider);
    return FutureBuilder<Letter?>(
      future: curriculumRepo.getLetter('alif'),
      builder: (BuildContext context, AsyncSnapshot<Letter?> snapshot) {
        final letter = snapshot.data;
        if (letter == null) {
          // Loading or not found — show a neutral loading indicator.
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }

        return switch (state.phase) {
          PracticePhase.watch => _WatchPhase(
              letter: letter,
              animKey: animKey,
              onAdvanceToTrace: onAdvanceToTrace,
            ),
          PracticePhase.trace => _TracePhase(
              letter: letter,
              state: state,
              onStrokeSubmitted: (List<Offset> pts) =>
                  onStrokeSubmitted(pts, letter.referenceStrokes.first),
            ),
          PracticePhase.showFix => _ShowFixPhase(
              letter: letter,
              state: state,
              animKey: animKey,
              onStrokeSubmitted: (List<Offset> pts) =>
                  onStrokeSubmitted(pts, letter.referenceStrokes.first),
              onRetry: onRetry,
            ),
          PracticePhase.celebrate => const SizedBox.shrink(),
        };
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _WatchPhase
// ---------------------------------------------------------------------------

class _WatchPhase extends StatelessWidget {
  const _WatchPhase({
    required this.letter,
    required this.animKey,
    required this.onAdvanceToTrace,
  });

  final Letter letter;
  final GlobalKey<StrokeOrderAnimationState> animKey;
  final VoidCallback onAdvanceToTrace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final heading = l10n?.practiceWatchHeading ?? 'Watch me write alif.';
    final tipLabel = l10n?.practiceTipLabel ?? 'Tip';
    final tipBody = l10n?.practiceTipBody ??
        'Start at the gold dot. Follow the line down.';
    final watchAgainLabel = l10n?.practiceWatchAgainButton ?? 'Watch Again';
    final illTryLabel = l10n?.practiceIllTryButton ?? "I'll Try";

    return Padding(
      padding: const EdgeInsets.all(QalamSpace.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Heading.
          Text(
            heading,
            style: QalamTextStyles.display,
          ),
          const SizedBox(height: QalamSpace.space6),

          // Tip card.
          _TipCard(title: tipLabel, body: tipBody),
          const SizedBox(height: QalamSpace.space6),

          // Animation canvas — expanded to fill remaining space.
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: QalamColors.surface,
                borderRadius: BorderRadius.circular(QalamRadii.xl),
                boxShadow: QalamShadows.shadowMd,
              ),
              padding: const EdgeInsets.all(QalamSpace.space4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(QalamRadii.lg),
                child: ColoredBox(
                  color: QalamColors.bg,
                  child: StrokeOrderAnimation(
                    key: animKey,
                    referenceStrokes: letter.referenceStrokes,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: QalamSpace.space6),

          // Button row: Watch Again (ghost) + I'll Try (primary).
          Row(
            children: <Widget>[
              Expanded(
                child: _GhostButton(
                  label: watchAgainLabel,
                  onPressed: () => animKey.currentState?.replay(),
                ),
              ),
              const SizedBox(width: QalamSpace.space4),
              Expanded(
                flex: 2,
                child: _PrimaryButton(
                  label: illTryLabel,
                  onPressed: onAdvanceToTrace,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TracePhase
// ---------------------------------------------------------------------------

class _TracePhase extends StatelessWidget {
  const _TracePhase({
    required this.letter,
    required this.state,
    required this.onStrokeSubmitted,
  });

  final Letter letter;
  final PracticeState state;
  final void Function(List<Offset> points) onStrokeSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final heading = l10n?.practiceTraceHeading ?? 'Now you trace alif.';
    final strokeProg = l10n?.practiceStrokeProgress ?? 'Stroke 1 of 1';
    final repN = state.cleanReps + 1;
    final repTotal = state.cleanRepsToAdvance;
    final repLabel = l10n?.practiceRepProgress(repN) ?? '$repN of $repTotal';

    return Padding(
      padding: const EdgeInsets.all(QalamSpace.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Heading.
          Text(heading, style: QalamTextStyles.display),
          const SizedBox(height: QalamSpace.space3),

          // Progress indicators — pedagogical, not a score.
          Row(
            children: <Widget>[
              Text(strokeProg, style: QalamTextStyles.label),
              const SizedBox(width: QalamSpace.space6),
              Text(repLabel, style: QalamTextStyles.label),
            ],
          ),
          const SizedBox(height: QalamSpace.space6),

          // Trace canvas — expanded to fill.
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: QalamColors.surface,
                borderRadius: BorderRadius.circular(QalamRadii.xl),
                boxShadow: QalamShadows.shadowMd,
              ),
              padding: const EdgeInsets.all(QalamSpace.space4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(QalamRadii.lg),
                child: ColoredBox(
                  color: QalamColors.bg,
                  child: StrokeCanvas(
                    referenceStrokes: letter.referenceStrokes,
                    onStrokeSubmitted: onStrokeSubmitted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: QalamSpace.space6),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ShowFixPhase
// ---------------------------------------------------------------------------

class _ShowFixPhase extends StatelessWidget {
  const _ShowFixPhase({
    required this.letter,
    required this.state,
    required this.animKey,
    required this.onStrokeSubmitted,
    required this.onRetry,
  });

  final Letter letter;
  final PracticeState state;
  final GlobalKey<StrokeOrderAnimationState> animKey;
  final void Function(List<Offset> points) onStrokeSubmitted;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tryAgainLabel = l10n?.practiceTryAgainButton ?? 'Try Again';
    final replayLabel = l10n?.practiceReplayButton ?? 'Replay';
    final mistakeId = state.lastMistakeId ?? MistakeId.fallback;

    return Padding(
      padding: const EdgeInsets.all(QalamSpace.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Named-fix feedback panel — framed in coral, authored string.
          FeedbackPanel(mistakeId: mistakeId),
          const SizedBox(height: QalamSpace.space6),

          // Canvas — child can see what they drew (read-only visual).
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: QalamColors.surface,
                borderRadius: BorderRadius.circular(QalamRadii.xl),
                boxShadow: QalamShadows.shadowMd,
              ),
              padding: const EdgeInsets.all(QalamSpace.space4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(QalamRadii.lg),
                child: ColoredBox(
                  color: QalamColors.bg,
                  child: StrokeCanvas(
                    referenceStrokes: letter.referenceStrokes,
                    onStrokeSubmitted: onStrokeSubmitted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: QalamSpace.space6),

          // Button row: Replay (ghost) + Try Again (primary).
          Row(
            children: <Widget>[
              Expanded(
                child: _GhostButton(
                  label: replayLabel,
                  onPressed: () {
                    animKey.currentState?.replay();
                    onRetry();
                  },
                ),
              ),
              const SizedBox(width: QalamSpace.space4),
              Expanded(
                flex: 2,
                child: _PrimaryButton(
                  label: tryAgainLabel,
                  onPressed: onRetry,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared button widgets
// ---------------------------------------------------------------------------

/// Ghost / secondary button — outlined on parchment.
class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: QalamColors.primary,
        side: const BorderSide(color: QalamColors.primary, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QalamRadii.lg),
        ),
        minimumSize: const Size.fromHeight(QalamTargets.targetComfy),
        padding: const EdgeInsets.symmetric(
          horizontal: QalamSpace.space6,
          vertical: QalamSpace.space4,
        ),
      ),
      onPressed: onPressed,
      child: Text(label, style: QalamTextStyles.button.copyWith(
        color: QalamColors.primary,
      )),
    );
  }
}

/// Primary filled button — ink-teal with sticker shadow.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final qalam = Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        boxShadow: qalam.buttonShadow,
      ),
      child: Material(
        color: QalamColors.primary,
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: QalamTargets.targetComfy,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space8,
              vertical: QalamSpace.space4,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: QalamTextStyles.button.copyWith(
                color: QalamColors.fgOnPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tip card — surface card with title + body, no reward color.
class _TipCard extends StatelessWidget {
  const _TipCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QalamColors.surface,
        borderRadius: BorderRadius.circular(QalamRadii.xl),
        boxShadow: QalamShadows.shadowSm,
      ),
      padding: const EdgeInsets.all(QalamSpace.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: QalamTextStyles.button.copyWith(color: QalamColors.fg),
          ),
          const SizedBox(height: QalamSpace.space2),
          Text(body, style: QalamTextStyles.body),
        ],
      ),
    );
  }
}
