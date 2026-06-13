// PracticeScreen — Phase-3 Watch → Trace → Celebrate loop (plan 03-04).
//
// Wires the full core learning loop for alif (lesson_01):
//   1. Watch phase — StrokeOrderAnimation auto-plays; Watch Again / I'll Try.
//   2. Trace / ShowFix / ShowPraise phases — _TraceWorkspace (landscape, three
//      zones: TutorPanel left, hero center with StrokeCanvas, action row bottom).
//   3. Celebrate phase — MasteryCelebration + Back Home.
//
// State machine: practiceSessionController(lessonId: 'lesson_01') via Riverpod.
// Scoring: scoreStroke(points, referenceStroke) → StrokeResult → controller.
//
// ANTI-GAMIFICATION (PLAT-03 / D-03 / D-08):
//   - NO "THIS WEEK" / weekly bar / star tally.
//   - NO "Mark correct" button (D-06 — scorer only).
//   - NO "See journey" button (Phase 6).
//   - NO running star counter.
//   - NO confetti.
//   Sound control ("Hear the letter") IS present — owner pulled Phase-7 audio
//   forward. The button is disabled until letter.audio.letter is populated.
//   Enforced by practice_screen_test.dart.
//
// SECURITY (T-03-01/T-01-05): stroke points live in StrokeCanvas widget State.
// Only StrokeResult enters the session controller — no raw Offset list is
// lifted to provider scope.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/recognition/handwriting_recognizer.dart';
import '../../core/recognition/ml_kit_recognizer.dart';
import '../../core/scoring/letter_scorer.dart';
import '../../core/scoring/scoring_models.dart';
import '../../core/scoring/tolerances.dart';
import '../../core/strokes/stroke_normalization.dart';
import '../../data/curriculum_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/lesson.dart';
import '../../models/letter.dart';
import '../../providers/audio_providers.dart';
import '../../providers/practice_providers.dart';
import '../../providers/progression_providers.dart';
import '../../services/model_download_service.dart';
import '../../theme/brand_theme_ext.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import '../../widgets/arabic_text.dart';
import '../../widgets/qalam_mascot.dart';
import 'widgets/ghost_comparison.dart';
import 'widgets/mastery_celebration.dart';
import 'widgets/stroke_canvas.dart';
import 'widgets/stroke_order_animation.dart';
import 'widgets/tutor_panel.dart';

/// The practice screen — the full Watch → Trace → Celebrate loop.
///
/// Teaches [lessonId] when given (deep link `/practice?lesson=...`), else
/// today's lesson from [todayLessonProvider]. Reads
/// [practiceSessionControllerProvider] for phase state and dispatches events
/// to the controller.
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key, this.lessonId});

  /// The requested lesson id from the route's `?lesson=` query parameter.
  ///
  /// Externally influenceable (deep link / route restoration — T-06-03):
  /// validated against the curriculum catalog before use; unknown or missing
  /// ids degrade silently to today's lesson, never an error to the child.
  final String? lessonId;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  /// Key for replaying the stroke-order animation from the Watch Again button.
  final GlobalKey<StrokeOrderAnimationState> _animKey =
      GlobalKey<StrokeOrderAnimationState>();

  /// The lesson this screen teaches, resolved once in [initState]:
  /// widget.lessonId if it exists in the catalog (allowlist, T-06-03) →
  /// today's lesson → 'lesson_01'. Null while resolving (loading treatment).
  String? _resolvedLessonId;

  /// The letter taught by [_resolvedLessonId], resolved alongside the lesson so
  /// the celebration can speak the actual mastered letter (Pitfall 6). Null
  /// while resolving or when the lesson has no letter item.
  Letter? _lessonLetter;

  @override
  void initState() {
    super.initState();
    _resolveLessonId();
  }

  Future<void> _resolveLessonId() async {
    String? resolved;
    final requested = widget.lessonId;
    final repo = ref.read(curriculumRepositoryProvider);
    if (requested != null) {
      // Catalog allowlist — a junk `?lesson=` value falls through to today.
      final lesson = await repo.getLesson(requested);
      if (lesson != null) resolved = requested;
    }
    if (resolved == null) {
      final today = await ref.read(todayLessonProvider.future);
      resolved = today?.id ?? 'lesson_01';
    }
    // Resolve the letter this lesson teaches (its first letter item) so the
    // celebration speaks the mastered letter. Defensive: no letter item → null.
    Letter? letter;
    final lesson = await repo.getLesson(resolved);
    final letterItems =
        lesson?.items.where((LessonItem i) => i.type == 'letter').toList() ??
            const <LessonItem>[];
    if (letterItems.isNotEmpty) {
      letter = await repo.getLetter(letterItems.first.ref);
    }
    if (mounted) {
      setState(() {
        _resolvedLessonId = resolved;
        _lessonLetter = letter;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Letter completion — called by StrokeCanvas once the whole multi-stroke
  // letter has been accumulated (count-reached signal, Plan 04-04).
  // ---------------------------------------------------------------------------

  /// Score the whole accumulated letter via scoreLetter and forward only the
  /// LetterResult to the controller.
  ///
  /// SECURITY: raw Offset points are used locally for scoring and then discarded.
  /// They never enter provider state (Anti-Pattern 3 / T-04-08).
  ///
  /// ML Kit gate (D-04, advisory-only): the recognizer is supplied to scoreLetter
  /// ONLY when the model is ready (ModelDownloadService.isReady). Until then the
  /// gate abstains and the geometric scorer runs unchanged (D-05). The gate can
  /// only REJECT a confidently-different letter AFTER a geometric pass — the
  /// policy lives in scoreLetter, never here.
  Future<void> _onLetterComplete(
    List<List<Offset>> strokes,
    Letter letter,
  ) async {
    // Convert Offsets → List<List<List<double>>> for the pure-Dart scorer.
    final childStrokes = strokes
        .map((List<Offset> stroke) => stroke
            .map((Offset o) => <double>[o.dx, o.dy])
            .toList(growable: false))
        .toList(growable: false);

    // Advisory ML Kit gate only when the model is downloaded (D-04 / D-05).
    final bool modelReady =
        ref.read(modelDownloadServiceProvider).isReady;
    final HandwritingRecognizer? recognizer =
        modelReady ? MlKitRecognizer() : null;

    // D-18/D-20: score THIS rep at the ramp preset the controller resolved
    // for the persisted rep index. The preset name is state, never a literal —
    // nothing in the UI exposes it to the child (UI-SPEC: invisible
    // scaffolding).
    final String tolerancePreset = ref
        .read(practiceSessionControllerProvider(_resolvedLessonId!))
        .tolerancePreset;

    final LetterResult result = await scoreLetter(
      childStrokes,
      letter,
      recognizer: recognizer,
      tolerances: Tolerances.preset(tolerancePreset),
    );

    // Only the LetterResult (not raw points) enters the controller.
    // _resolvedLessonId is non-null here: the canvas only exists after build
    // rendered the resolved lesson.
    await ref
        .read(practiceSessionControllerProvider(_resolvedLessonId!).notifier)
        .onLetterResult(result);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final lessonId = _resolvedLessonId;
    // Still resolving which lesson to teach — neutral loading, never an error
    // (UI-SPEC error contract).
    if (lessonId == null) {
      return const Scaffold(
        backgroundColor: QalamColors.bg,
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final state = ref.watch(
      practiceSessionControllerProvider(lessonId),
    );

    // Celebrate phase is full-screen — bypass the Scaffold shell.
    if (state.phase == PracticePhase.celebrate) {
      return _CelebrateView(
        masteredLetter: _lessonLetter,
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
          lessonId: lessonId,
          letter: _lessonLetter,
          state: state,
          animKey: _animKey,
          onLetterComplete: _onLetterComplete,
          onAdvanceToTrace: () => ref
              .read(practiceSessionControllerProvider(lessonId).notifier)
              .advanceToTrace(),
          onContinueAfterPraise: () => ref
              .read(practiceSessionControllerProvider(lessonId).notifier)
              .continueAfterPraise(),
          onRetry: () => ref
              .read(practiceSessionControllerProvider(lessonId).notifier)
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
      case PracticePhase.showPraise:
        return l10n?.practicePraiseEyebrow ?? 'NICE';
      case PracticePhase.celebrate:
        return l10n?.practiceMasteredEyebrow ?? 'MASTERED';
    }
  }
}

// ---------------------------------------------------------------------------
// _CelebrateView — full-screen mastery moment wiring (D-14 / D-16 / D-17)
// ---------------------------------------------------------------------------

/// Wires [MasteryCelebration] to the live progression (S1-09): post-mastery the
/// mastery stream has already recomputed, so [todayLessonProvider] now resolves
/// to the newly unlocked lesson — that becomes the "Next Lesson" target. When
/// today resolves null, every lesson is mastered → the D-16 last-lesson variant
/// (See Journey primary, no Next Lesson).
///
/// While the next-lesson provider momentarily resolves we follow the loading
/// degradation contract (UI-SPEC): render the celebration with Next Lesson
/// absent rather than show a spinner or a raw error to the child.
class _CelebrateView extends ConsumerWidget {
  const _CelebrateView({
    required this.masteredLetter,
    required this.onBackHome,
  });

  /// The letter the child just mastered (this lesson's letter). May be null if
  /// the lesson is still resolving or carries no letter item.
  final Letter? masteredLetter;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Letter? letter = masteredLetter;
    // Defensive: if the mastered letter has not resolved, fall back to alif so
    // the child always sees a coherent celebration (never a crash/blank).
    final String glyph = letter?.char ?? 'ا';
    final String letterName = letter?.name.display ?? 'alif';
    final String masteredLetterId = letter?.id ?? 'alif';

    // Post-mastery, today's lesson IS the newly unlocked lesson (the stream
    // already advanced). Null today → all mastered → last-lesson variant (D-16).
    final today = ref.watch(todayLessonProvider);
    final Lesson? nextLesson = today.asData?.value;
    // Last lesson ONLY when the provider has resolved AND today is null.
    final bool isLastLesson = today.hasValue && nextLesson == null;
    // Next Lesson is offered only once we have a concrete target; while loading
    // we leave it absent (degradation) rather than route to a stale lesson.
    final VoidCallback? onNextLesson = (!isLastLesson && nextLesson != null)
        ? () => context.go('/practice?lesson=${nextLesson.id}')
        : null;

    return MasteryCelebration(
      glyph: glyph,
      letterName: letterName,
      masteredLetterId: masteredLetterId,
      isLastLesson: isLastLesson,
      onNextLesson: onNextLesson,
      onBackHome: onBackHome,
    );
  }
}

// ---------------------------------------------------------------------------
// _PracticeBody — switches between Watch / Trace+ShowFix+ShowPraise phases
// ---------------------------------------------------------------------------

/// The body of the practice screen. Renders the correct phase view for the
/// lesson's resolved [letter].
class _PracticeBody extends ConsumerWidget {
  const _PracticeBody({
    required this.lessonId,
    required this.letter,
    required this.state,
    required this.animKey,
    required this.onLetterComplete,
    required this.onAdvanceToTrace,
    required this.onContinueAfterPraise,
    required this.onRetry,
  });

  final String lessonId;

  /// The letter this lesson teaches, resolved by the parent from the lesson's
  /// first letter item (Pitfall 6 — never the hardcoded 'alif'). Null while
  /// resolving → neutral loading.
  final Letter? letter;
  final PracticeState state;
  final GlobalKey<StrokeOrderAnimationState> animKey;
  final Future<void> Function(List<List<Offset>> strokes, Letter letter)
      onLetterComplete;
  final VoidCallback onAdvanceToTrace;
  final VoidCallback onContinueAfterPraise;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Letter? letter = this.letter;
    if (letter == null) {
      // Still resolving the lesson's letter — neutral loading, never an error.
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    // GETTING-READY (D-05): while the ML Kit model is still downloading,
    // show a calm getting-ready banner over the practice surface — NEVER an
    // error and NEVER a hard block. The geometric scorer already works; only
    // the advisory ML Kit gate abstains until the model is ready.
    final bool modelReady = ref.watch(modelDownloadServiceProvider).isReady;

    final Widget phaseView = switch (state.phase) {
      PracticePhase.watch => _WatchPhase(
          letter: letter,
          animKey: animKey,
          onAdvanceToTrace: onAdvanceToTrace,
        ),
      // trace, showFix, showPraise all share one landscape workspace.
      PracticePhase.trace ||
      PracticePhase.showFix ||
      PracticePhase.showPraise =>
        _TraceWorkspace(
          letter: letter,
          state: state,
          // Empty-stroke-safe: placeholder letters (no referenceStrokes)
          // never reach the scorer. The whole accumulated letter is scored
          // once via scoreLetter (Plan 04-04), not stroke-by-stroke.
          onLetterComplete: (List<List<Offset>> strokes) =>
              letter.referenceStrokes.isEmpty
                  ? Future<void>.value()
                  : onLetterComplete(strokes, letter),
          onContinueAfterPraise: onContinueAfterPraise,
          onRetry: onRetry,
        ),
      PracticePhase.celebrate => const SizedBox.shrink(),
    };

    // Overlay the calm getting-ready banner while the model downloads (D-05).
    // The lesson runs underneath — this is a quiet wait, never a block.
    if (!modelReady && state.phase != PracticePhase.celebrate) {
      return Stack(
        children: <Widget>[
          phaseView,
          const Positioned(
            left: QalamSpace.space4,
            right: QalamSpace.space4,
            top: QalamSpace.space4,
            child: _GettingReadyBanner(),
          ),
        ],
      );
    }
    return phaseView;
  }
}

// ---------------------------------------------------------------------------
// _WatchPhase — unchanged from Phase-3 original
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
    // Templated on the letter (Pitfall 6) — never 'alif' for another letter.
    final heading = l10n?.practiceWatchHeadingFor(letter.name.display) ??
        'Watch me write ${letter.name.display}.';
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
// _TraceWorkspace — landscape Row: TutorPanel | hero canvas | (action row)
// ---------------------------------------------------------------------------

// Structural width constants from the mockup — no tokens exist for panel sizing.
const double _kTutorPanelWidth = 262.0; // Left tutor panel width (mockup spec).
const double _kWatchMeCornerWidth = 160.0; // Watch Me corner card (mockup spec).

/// Visible think beat — a named, deliberate pause before forwarding the score
/// so the tutor's bubble visually "thinks". Not [QalamMotion.durCheer] (700ms
/// has a different semantic). This is a UX beat, not a cheer duration.
const Duration _kThinkBeat = Duration(milliseconds: 700);

/// Shared workspace for trace, showFix, and showPraise phases.
///
/// Landscape three-zone layout:
///   LEFT  — TutorPanel (mascot + bubble + Sound card), fixed [_kTutorPanelWidth].
///   CENTER — Expanded hero: heading row, canvas card, action row.
///
/// Local state manages the ghost cast overlay and canvas epoch — nothing in
/// the session controller or scorer is touched here.
class _TraceWorkspace extends ConsumerStatefulWidget {
  const _TraceWorkspace({
    required this.letter,
    required this.state,
    required this.onLetterComplete,
    required this.onContinueAfterPraise,
    required this.onRetry,
  });

  final Letter letter;
  final PracticeState state;
  final Future<void> Function(List<List<Offset>> strokes) onLetterComplete;
  final VoidCallback onContinueAfterPraise;
  final VoidCallback onRetry;

  @override
  ConsumerState<_TraceWorkspace> createState() => _TraceWorkspaceState();
}

class _TraceWorkspaceState extends ConsumerState<_TraceWorkspace> {
  bool _isScoring = false;
  bool _isCasting = false;

  /// The child's most recent FAILING strokes, normalized to 0..1 via the shared
  /// combined-bbox core, held HERE IN WIDGET STATE ONLY (T-03-01 / T-06-04).
  /// Set in [_handleLetterComplete] when the rep fails shape checks; cleared on
  /// retry, on pass, and on dispose. They feed the D-21 ghost comparison and
  /// are NEVER persisted, logged, or lifted to provider scope.
  List<StrokeSpec>? _failingStrokes;

  /// Whether the D-21 ghost-comparison overlay is currently shown. Only ever
  /// true in showFix with [_failingStrokes] held.
  bool _showGhost = false;

  /// Bumping this key gives StrokeCanvas a fresh instance (clears ink).
  int _canvasEpoch = 0;

  /// Bumping this triggers a new ghost StrokeOrderAnimation that auto-plays once.
  int _castEpoch = 0;

  /// GlobalKey for the corner loop animation — allows external replay() calls.
  final GlobalKey<StrokeOrderAnimationState> _cornerKey =
      GlobalKey<StrokeOrderAnimationState>();

  /// Periodic timer that replays the corner animation with a deliberate pause
  /// so it doesn't compete with the main canvas. Cancelled in dispose().
  Timer? _cornerLoop;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    if (widget.letter.referenceStrokes.isNotEmpty) {
      // The gap between replays is intentional — the corner animation should
      // idle quietly and not compete visually with the child's canvas work.
      // interval = durWrite (1400ms animation) + durCheer (700ms idle gap) = 2100ms.
      _cornerLoop = Timer.periodic(
        QalamMotion.durWrite + QalamMotion.durCheer,
        (_) {
          if (!_isCasting) {
            _cornerKey.currentState?.replay();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _cornerLoop?.cancel();
    // T-03-01: ensure no held stroke points outlive this State.
    _failingStrokes = null;
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Wrap the whole-letter submission with a visible think beat so the tutor
  /// bubble animates before the phase transition. Called once StrokeCanvas has
  /// accumulated the whole multi-stroke letter (Plan 04-04).
  Future<void> _handleLetterComplete(List<List<Offset>> strokes) async {
    if (widget.letter.referenceStrokes.isEmpty) return; // placeholder: no crash

    // Normalize the child's just-traced strokes to 0..1 via the shared
    // combined-bbox core (Pitfall 2) and stage them in WIDGET STATE ONLY
    // (T-03-01 / T-06-04). These become the D-21 ghost-comparison material if —
    // and only if — this rep ends in showFix. They are never persisted, never
    // lifted to provider scope.
    final List<List<List<double>>> raw = strokes
        .map((List<Offset> s) =>
            s.map((Offset o) => <double>[o.dx, o.dy]).toList())
        .toList();
    final List<List<List<double>>> normalized =
        normalizeStrokesToUnitBox(raw);
    final List<StrokeSpec> candidate = <StrokeSpec>[
      for (var i = 0; i < normalized.length; i++)
        StrokeSpec(
          order: i + 1,
          label: 'child',
          type: 'line',
          direction: 'topToBottom',
          points: normalized[i],
        ),
    ];

    setState(() => _isScoring = true);
    await Future<void>.delayed(_kThinkBeat);
    if (!mounted) return;
    await widget.onLetterComplete(strokes);
    if (!mounted) return;

    // The parent rebuilds this workspace with the post-scoring phase. We stage
    // the candidate now; build() exposes the ghost button only while the live
    // phase is showFix (a pass clears it via _clear on continue). Staging only
    // on a fresh miss avoids showing a stale stroke after the child retries.
    setState(() {
      _isScoring = false;
      _failingStrokes = candidate;
      _showGhost = false; // child opts in via the button
    });
  }

  /// Cast the stroke-order ghost overlay on the canvas. Ignored if already
  /// casting or if the letter has no reference strokes.
  void _cast() {
    if (_isCasting || widget.letter.referenceStrokes.isEmpty) return;
    setState(() {
      _isCasting = true;
      _castEpoch++;
    });
    Future<void>.delayed(QalamMotion.durWrite + QalamMotion.durBase, () {
      if (mounted) setState(() => _isCasting = false);
    });
  }

  /// Clear the canvas by giving StrokeCanvas a fresh key. Also drops any held
  /// failing strokes and closes the ghost comparison (T-03-01: the child's
  /// stroke points do not outlive the rep — cleared on retry/pass/continue).
  void _clear() => setState(() {
        _canvasEpoch++;
        _failingStrokes = null;
        _showGhost = false;
      });

  /// Open the D-21 ghost comparison (only meaningful when failing strokes are
  /// held and the phase is showFix).
  void _openGhost() => setState(() => _showGhost = true);

  /// Close the ghost comparison without clearing the canvas.
  void _closeGhost() => setState(() => _showGhost = false);

  // ---------------------------------------------------------------------------
  // Build helpers
  // ---------------------------------------------------------------------------

  /// Compute the tutor panel inputs based on current scoring / phase state.
  ({
    QalamPose pose,
    BubbleTone tone,
    String? toneLabel,
    String? bubbleText,
    Widget? bubbleChild,
  })
      _tutorParams(AppLocalizations? l10n) {
    if (_isCasting) {
      return (
        pose: QalamPose.write,
        tone: BubbleTone.none,
        toneLabel: null,
        bubbleText: l10n?.practiceCastWatchLine ??
            'Watch — start at the dot and come all the way down.',
        bubbleChild: null,
      );
    }

    if (_isScoring) {
      final thinkingPrefix = l10n?.practiceTutorThinking(
            widget.letter.name.display,
          ) ??
          'Let me look at your ${widget.letter.name.display}';
      return (
        pose: QalamPose.think,
        tone: BubbleTone.none,
        toneLabel: null,
        bubbleText: null,
        bubbleChild: ThinkingDots(prefix: thinkingPrefix),
      );
    }

    switch (widget.state.phase) {
      case PracticePhase.trace:
        return (
          pose: QalamPose.idle,
          tone: BubbleTone.none,
          toneLabel: null,
          bubbleText: l10n?.practiceTutorCoaching ??
              'Take your time. Start at the gold dot and bring it straight down.',
          bubbleChild: null,
        );
      case PracticePhase.showFix:
        final mistakeId = widget.state.lastMistakeId ?? MistakeId.fallback;
        return (
          pose: QalamPose.tryAgain,
          tone: BubbleTone.coral,
          toneLabel: l10n?.practiceTutorSays ?? 'Qalam says',
          bubbleText: _feedbackString(l10n, mistakeId),
          bubbleChild: null,
        );
      case PracticePhase.showPraise:
        final repsRemaining =
            (widget.state.cleanRepsToAdvance - widget.state.cleanReps)
                .clamp(1, 999);
        return (
          pose: QalamPose.cheer,
          tone: BubbleTone.leaf,
          toneLabel: l10n?.practiceTutorSays ?? 'Qalam says',
          bubbleText: null,
          bubbleChild: _PraiseContent(
            l10n: l10n,
            letterName: widget.letter.name.display,
            repsRemaining: repsRemaining,
          ),
        );
      // These phases are handled elsewhere; provide safe defaults.
      case PracticePhase.watch:
      case PracticePhase.celebrate:
        return (
          pose: QalamPose.idle,
          tone: BubbleTone.none,
          toneLabel: null,
          bubbleText: '',
          bubbleChild: null,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final params = _tutorParams(l10n);

    // Audio — null ⇒ Hear button disabled (letter.audio not yet populated).
    final audioPlayer = ref.read(audioPlayerProvider);
    final onHear = widget.letter.audio?.letter != null
        ? () => audioPlayer.playLetter(widget.letter.audio!.letter!)
        : null;

    final traceLeadIn = l10n?.practiceTraceLeadIn ?? 'Now you trace';
    final cleanRepsLabel = l10n?.practiceCleanRepsLabel ?? 'Clean reps';
    final strokeProg = l10n?.practiceStrokeProgress ?? 'Stroke 1 of 1';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // LEFT — Tutor panel (fixed width).
        SizedBox(
          width: _kTutorPanelWidth,
          child: TutorPanel(
            pose: params.pose,
            tone: params.tone,
            letter: widget.letter,
            toneLabel: params.toneLabel,
            bubbleText: params.bubbleText,
            bubbleChild: params.bubbleChild,
            onHear: onHear,
          ),
        ),

        // CENTER — Hero (heading + canvas + action row).
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              QalamSpace.space4,
              QalamSpace.space5,
              QalamSpace.space4,
              QalamSpace.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Heading row — letter-agnostic Wrap (never clips).
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: QalamSpace.space2,
                  children: <Widget>[
                    Text(traceLeadIn, style: QalamTextStyles.display),
                    if (widget.letter.name.ar.isNotEmpty)
                      ArabicText(
                        widget.letter.name.ar,
                        // Match the display heading scale (≥ adjacent English),
                        // not the 96px arDisplay role which would dwarf the line.
                        style: QalamTextStyles.arDisplay.copyWith(
                          fontSize: QalamFontSizes.fz42,
                          height: 1.15,
                        ),
                      ),
                    Text(
                      '— ${widget.letter.name.display}.',
                      style: QalamTextStyles.display,
                    ),
                  ],
                ),
                const SizedBox(height: QalamSpace.space3),

                // Progress row: stroke counter + clean-rep pips.
                Row(
                  children: <Widget>[
                    Text(strokeProg, style: QalamTextStyles.label),
                    const SizedBox(width: QalamSpace.space4),
                    Text(cleanRepsLabel, style: QalamTextStyles.label),
                    const SizedBox(width: QalamSpace.space2),
                    // Clean-rep pips — ink-teal (primary) fill, NOT gold.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List<Widget>.generate(
                        widget.state.cleanRepsToAdvance,
                        (int i) {
                          final bool filled = i < widget.state.cleanReps;
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: QalamSpace.space1,
                            ),
                            child: Container(
                              width: QalamSpace.space3,
                              height: QalamSpace.space3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled
                                    ? QalamColors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: filled
                                      ? QalamColors.primary
                                      : QalamColors.border,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: QalamSpace.space3),

                // Canvas card — the largest element on screen.
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: QalamColors.surface,
                      borderRadius: BorderRadius.circular(QalamRadii.xl),
                      boxShadow: QalamShadows.shadowMd,
                      border:
                          Border.all(color: QalamColors.border, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(QalamRadii.lg),
                      child: ColoredBox(
                        color: QalamColors.bg,
                        child: Stack(
                          children: <Widget>[
                            // Main trace canvas — fills the stack.
                            Positioned.fill(
                              child: StrokeCanvas(
                                key: ValueKey(_canvasEpoch),
                                referenceStrokes:
                                    widget.letter.referenceStrokes,
                                // Score the WHOLE accumulated letter once
                                // (Plan 04-04), not per-stroke.
                                onLetterComplete: _handleLetterComplete,
                              ),
                            ),

                            // Ghost cast overlay — one-shot auto-play.
                            if (_isCasting)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Opacity(
                                    opacity: 0.24,
                                    child: StrokeOrderAnimation(
                                      key: ValueKey('ghost-$_castEpoch'),
                                      referenceStrokes:
                                          widget.letter.referenceStrokes,
                                    ),
                                  ),
                                ),
                              ),

                            // D-21 ghost comparison — fills the canvas card
                            // when the child opts in from the ShowFix zone.
                            // Fed ONLY from widget State (_failingStrokes).
                            if (_showGhost && _failingStrokes != null)
                              Positioned.fill(
                                child: ColoredBox(
                                  color: QalamColors.bg,
                                  child: Stack(
                                    children: <Widget>[
                                      GhostComparison(
                                        childStrokes: _failingStrokes!,
                                        referenceStrokes:
                                            widget.letter.referenceStrokes,
                                      ),
                                      // Close affordance — top-left.
                                      Positioned(
                                        left: QalamSpace.space2,
                                        top: QalamSpace.space2,
                                        child: IconButton(
                                          onPressed: _closeGhost,
                                          color: QalamColors.fgMuted,
                                          icon: const Icon(Icons.close),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Watch Me corner card — top-right.
                            Positioned(
                              top: QalamSpace.space4,
                              right: QalamSpace.space4,
                              child: _WatchMeCorner(
                                cornerKey: _cornerKey,
                                letter: widget.letter,
                                onTap: _cast,
                                l10n: l10n,
                              ),
                            ),

                            // Clear button — bottom-left compact ghost.
                            Positioned(
                              left: QalamSpace.space4,
                              bottom: QalamSpace.space4,
                              child: _ClearButton(
                                onPressed: _clear,
                                label: l10n?.practiceClearButton ?? 'Clear',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: QalamSpace.space3),

                // Bottom action row — content-sized, right-aligned buttons.
                _ActionRow(
                  phase: widget.state.phase,
                  isScoring: _isScoring,
                  l10n: l10n,
                  onCast: _cast,
                  // D-21: offer "Watch the Difference" only when failing
                  // strokes are held in State (and not already open).
                  onWatchDifference:
                      (_failingStrokes != null && !_showGhost) ? _openGhost : null,
                  onRetry: () {
                    _clear();
                    widget.onRetry();
                  },
                  onContinueAfterPraise: () {
                    _clear();
                    widget.onContinueAfterPraise();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _WatchMeCorner — top-right corner card inside the canvas stack
// ---------------------------------------------------------------------------

class _WatchMeCorner extends StatelessWidget {
  const _WatchMeCorner({
    required this.cornerKey,
    required this.letter,
    required this.onTap,
    required this.l10n,
  });

  final GlobalKey<StrokeOrderAnimationState> cornerKey;
  final Letter letter;
  final VoidCallback onTap;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final watchMeLabel = l10n?.practiceWatchMeLabel ?? 'Watch Me';
    final watchMeHint = l10n?.practiceWatchMeHint ?? 'Tap to show me here';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _kWatchMeCornerWidth,
        constraints: const BoxConstraints(minHeight: QalamTargets.targetMin),
        decoration: BoxDecoration(
          color: QalamColors.surfaceRaised,
          border: Border.all(color: QalamColors.border, width: 1.0),
          borderRadius: BorderRadius.circular(QalamRadii.lg),
          boxShadow: QalamShadows.shadowMd,
        ),
        padding: const EdgeInsets.all(QalamSpace.space2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // "Watch Me" tag
            Text(
              watchMeLabel,
              style: QalamTextStyles.label.copyWith(
                color: QalamColors.primary,
              ),
            ),
            const SizedBox(height: QalamSpace.space1),

            // Mini animation frame
            SizedBox(
              height: QalamSpace.space20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(QalamRadii.md),
                child: ColoredBox(
                  color: QalamColors.bg,
                  child: StrokeOrderAnimation(
                    key: cornerKey,
                    referenceStrokes: letter.referenceStrokes,
                  ),
                ),
              ),
            ),
            const SizedBox(height: QalamSpace.space1),

            // Hint line
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  watchMeHint,
                  style: QalamTextStyles.label.copyWith(
                    color: QalamColors.fgMuted,
                    fontSize: QalamFontSizes.fz12,
                  ),
                ),
                const SizedBox(width: QalamSpace.space1),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: QalamColors.fgMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ClearButton — compact ghost at bottom-left of canvas
// ---------------------------------------------------------------------------

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: QalamTargets.targetMin,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: QalamColors.primary,
          side: const BorderSide(color: QalamColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QalamRadii.lg),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: QalamSpace.space4,
            vertical: QalamSpace.space2,
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: QalamTextStyles.button.copyWith(
            color: QalamColors.primary,
            fontSize: QalamFontSizes.fz16,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ActionRow — bottom of the hero center, phase-driven
// ---------------------------------------------------------------------------

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.phase,
    required this.isScoring,
    required this.l10n,
    required this.onCast,
    required this.onWatchDifference,
    required this.onRetry,
    required this.onContinueAfterPraise,
  });

  final PracticePhase phase;
  final bool isScoring;
  final AppLocalizations? l10n;
  final VoidCallback onCast;

  /// D-21 "Watch the Difference" trigger — null when no failing strokes are
  /// held (the button is then omitted). Non-null only in showFix with a
  /// retained child stroke in widget State.
  final VoidCallback? onWatchDifference;
  final VoidCallback onRetry;
  final VoidCallback onContinueAfterPraise;

  @override
  Widget build(BuildContext context) {
    final traceHint =
        l10n?.practiceTraceHint ?? 'Lift your pen when you finish the stroke.';
    final showMeAgain = l10n?.practiceShowMeAgainButton ?? 'Show Me Again';
    final tryAgain = l10n?.practiceTryAgainButton ?? 'Try Again';
    final keepGoing = l10n?.practiceKeepGoingButton ?? 'Keep going';
    final watchDifference = l10n?.ghostCompareButton ?? 'Watch the Difference';

    switch (phase) {
      case PracticePhase.trace:
        // Trace + scoring: soft hint left, no action buttons.
        return Container(
          constraints:
              const BoxConstraints(minHeight: QalamTargets.targetMin),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: QalamSpace.space2,
                height: QalamSpace.space2,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: QalamColors.primary,
                ),
              ),
              const SizedBox(width: QalamSpace.space2),
              Text(
                traceHint,
                style: QalamTextStyles.label.copyWith(
                  color: QalamColors.fgMuted,
                ),
              ),
            ],
          ),
        );

      case PracticePhase.showFix:
        // showFix: [Watch the Difference] (ghost, D-21) + Show Me Again (ghost)
        // + Try Again (primary), right-aligned. The D-21 button appears only
        // when failing strokes are held (onWatchDifference != null). >= 16px gap
        // between targets (QalamSpace.space4).
        return Container(
          constraints:
              const BoxConstraints(minHeight: QalamTargets.targetMin),
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (onWatchDifference != null) ...<Widget>[
                _GhostButton(
                  label: watchDifference,
                  onPressed: onWatchDifference,
                ),
                const SizedBox(width: QalamSpace.space4),
              ],
              _GhostButton(
                label: showMeAgain,
                onPressed: onCast,
              ),
              const SizedBox(width: QalamSpace.space4),
              _PrimaryButton(
                label: tryAgain,
                onPressed: onRetry,
              ),
            ],
          ),
        );

      case PracticePhase.showPraise:
        // showPraise: Keep Going (primary), right-aligned.
        return Container(
          constraints:
              const BoxConstraints(minHeight: QalamTargets.targetMin),
          alignment: Alignment.centerRight,
          child: _PrimaryButton(
            label: keepGoing,
            onPressed: onContinueAfterPraise,
          ),
        );

      default:
        return const SizedBox(height: QalamTargets.targetMin);
    }
  }
}

// ---------------------------------------------------------------------------
// _PraiseContent — inline bubble content for showPraise
// ---------------------------------------------------------------------------

/// Renders the praise content inline in the TutorPanel bubble so it reuses
/// the authored PraisePanel strings without mounting PraisePanel as a widget.
class _PraiseContent extends StatelessWidget {
  const _PraiseContent({
    required this.l10n,
    required this.letterName,
    required this.repsRemaining,
  });

  final AppLocalizations? l10n;
  final String letterName;
  final int repsRemaining;

  @override
  Widget build(BuildContext context) {
    final arabic = l10n?.practicePraiseArabic ?? 'أحسنت';
    // Templated on the letter (Pitfall 6) — never 'alif' for another letter.
    final line = l10n?.practicePraiseLineFor(letterName) ??
        "That's a clean $letterName. Nicely done.";
    final remaining = l10n?.practicePraiseRemaining(repsRemaining) ??
        '$repsRemaining more in a row to master it.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ArabicText(
          arabic,
          style: QalamTextStyles.arBody.copyWith(color: QalamColors.success),
        ),
        const SizedBox(height: QalamSpace.space2),
        Text(line, style: QalamTextStyles.body),
        const SizedBox(height: QalamSpace.space3),
        Text(
          remaining,
          style:
              QalamTextStyles.label.copyWith(color: QalamColors.success),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared button widgets — kept from Phase-3 original
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

// ---------------------------------------------------------------------------
// _GettingReadyBanner — calm model-download wait state (D-05)
// ---------------------------------------------------------------------------

/// A calm, non-blocking banner shown while the ML Kit Arabic model is still
/// downloading on first launch (D-05). NEVER an error and NEVER a hard block —
/// the lesson runs underneath; the advisory ML Kit gate simply abstains until
/// the model is ready. Uses surface/ink tokens, no coral/red, no emoji.
class _GettingReadyBanner extends StatelessWidget {
  const _GettingReadyBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.practiceGettingReadyTitle ?? 'Getting ready';
    final body = l10n?.practiceGettingReadyBody ??
        "I'm getting your letters ready. You can start tracing now — "
            "I'll be right here.";

    return Container(
      decoration: BoxDecoration(
        color: QalamColors.surfaceRaised,
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        border: Border.all(color: QalamColors.border, width: 1.0),
        boxShadow: QalamShadows.shadowSm,
      ),
      padding: const EdgeInsets.all(QalamSpace.space4),
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: QalamSpace.space5,
            height: QalamSpace.space5,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor:
                  AlwaysStoppedAnimation<Color>(QalamColors.primary),
            ),
          ),
          const SizedBox(width: QalamSpace.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: QalamTextStyles.button.copyWith(color: QalamColors.fg),
                ),
                const SizedBox(height: QalamSpace.space1),
                Text(
                  body,
                  style: QalamTextStyles.label
                      .copyWith(color: QalamColors.fgMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lifted feedback string helper — from feedback_panel.dart
// ---------------------------------------------------------------------------

/// Maps a [MistakeId] to the correct l10n getter.
///
/// Feedback ALWAYS comes from authored strings — never a generic "Oops".
/// Lifted from FeedbackPanel so the TutorPanel bubble can use the same strings
/// without mounting FeedbackPanel as a widget.
String _feedbackString(AppLocalizations? l10n, MistakeId id) {
  switch (id) {
    case MistakeId.tooShort:
      return l10n?.practiceFeedbackTooShort ??
          'Your alif needs to be taller — draw it from the top all the way down.';
    case MistakeId.wrongDirection:
      return l10n?.practiceFeedbackWrongDirection ??
          'Start your alif at the top and come down — not from the bottom up.';
    case MistakeId.tooCurved:
      return l10n?.practiceFeedbackTooCurved ??
          'Alif is a straight line — try to keep it as straight as you can.';
    // ── Whole-letter mistakes (Plan 04-01 enum; scored by scoreLetter, Plan
    //    04-02). Each maps to an AUTHORED l10n string (Plan 04-04) — placeholder
    //    copy the mother refines in Plan 06 — never the generic fallback
    //    (Pitfall 7 / PLAT-03). ──
    case MistakeId.wrongStrokeCount:
      return l10n?.practiceFeedbackWrongStrokeCount ??
          'Baa is two parts — the boat, then one dot underneath.';
    case MistakeId.wrongStrokeOrder:
      return l10n?.practiceFeedbackWrongStrokeOrder ??
          'Draw the boat first, then add the dot underneath.';
    case MistakeId.dotMisplaced:
      return l10n?.practiceFeedbackDotMisplaced ??
          "Baa's dot goes under the boat, not on top — try the dot again.";
    case MistakeId.wrongLetterIdentity:
      return l10n?.practiceFeedbackWrongLetterIdentity ??
          "That looks like a different letter — let's write baa together, slower.";
    case MistakeId.fallback:
      return l10n?.practiceFeedbackFallback ??
          'Something looks off — try again, slower this time.';
  }
}
