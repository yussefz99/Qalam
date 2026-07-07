// ExerciseScaffold — the RTL landscape PAGE SHELL of the Letter-Unit exercise
// engine (Plan 07-04). It hosts the 5 components + the mascot, config-driven from
// a single [Exercise] (COMPONENTS.md §1 / components.js ExerciseScaffold /
// components.css `.ex-scaffold` two-column layout):
//
//   left  `.ex-tutor`  — QalamMascot + "Qalam / Your Writing Tutor" + speech bubble
//   right `.ex-main`   — kick eyebrow + ProgressRibbon row · PromptHeader ·
//                        WriteSurface (or a custom surface / none for teachCard) ·
//                        FeedbackPanel + CTA
//
// CONFIG-DRIVEN: every question type and every unit section is THIS shell fed a
// different [Exercise] — never new UI (the hard constraint). A teachCard
// (surface == null) renders PromptHeader-only with a support CTA — NO WriteSurface,
// NO grading (COMPONENTS.md §1/§3/§4 "NOT teachCard").
//
// The mascot pose + speech tone + FeedbackPanel state come from the
// [ExerciseController] (idle→think→pass|fix), exactly like the prototype's
// `tutorAndFeedback`. Riverpod-only (CLAUDE.md Decided).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exercise_engine/check_result.dart';
import '../../../models/exercise.dart';
import '../../../models/letter.dart';
import '../../../providers/tts_providers.dart';
import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import '../../../tutor/authored_fallback_brain.dart';
import '../../../tutor/exercise_selector_provider.dart';
import '../../../tutor/latency_trace.dart';
import '../../../tutor/tutor_brain.dart';
import '../../../tutor/tutor_decision.dart';
import '../../../tutor/tutor_facts.dart';
import '../../../tutor/tutor_facts_builder.dart';
import '../../../tutor/tutor_providers.dart';
import '../../../widgets/qalam_mascot.dart';
import '../../practice/widgets/stroke_canvas.dart';
import '../exercise_controller.dart';
import '../letter_unit_controller.dart';
import 'feedback_panel_v2.dart';
import 'progress_ribbon.dart';
import 'prompt_header.dart';
import 'write_surface.dart';

/// Static copy for the scaffold chrome (call site passes the l10n strings;
/// defaults keep widget tests independent of l10n generation).
class ExerciseScaffoldStrings {
  const ExerciseScaffoldStrings({
    this.tutorName = 'Qalam',
    this.tutorRole = 'Your Writing Tutor',
    this.tutorSays = 'Qalam says',
    this.clear = 'Clear',
    this.tryAgain = 'Try again',
    this.next = 'Next exercise',
    this.markCorrect = 'Mark correct',
    this.done = 'Done',
    this.gotIt = 'Got it',
    this.playLabel = 'Play',
    this.watchMe = 'Watch me',
    this.teachCardHint = 'Nothing to write — this card teaches.',
  });

  final String tutorName;
  final String tutorRole;
  final String tutorSays;
  final String clear;
  final String tryAgain;
  final String next;
  final String markCorrect;
  final String done;
  final String gotIt;
  final String playLabel;
  final String watchMe;
  final String teachCardHint;
}

/// DEMO (17.2) — the "Teacher's Eye": what the tutor saw on the LAST attempt,
/// made visible. Presenter chrome for the demo: read-only, additive, fed only
/// by data the client already holds (the scorer's criteria, the point-free
/// geometry summary, and the agent's next-exercise pick + rationale).
class TutorInsight {
  const TutorInsight({this.criteria, this.diffSummary, this.pick, this.rationale});
  final List<Map<String, Object?>>? criteria;
  final String? diffSummary;
  final String? pick;
  final String? rationale;
}

/// A [Notifier] (Riverpod 3 dropped `StateProvider`) mirroring the
/// [tutorLineProvider] pattern: `.set(insight)` / `.clear()`.
class TutorInsightNotifier extends Notifier<TutorInsight?> {
  @override
  TutorInsight? build() => null;

  void set(TutorInsight? insight) => state = insight;

  void clear() => state = null;
}

final tutorInsightProvider =
    NotifierProvider<TutorInsightNotifier, TutorInsight?>(
        TutorInsightNotifier.new);

/// The exercise page. Drive it by passing the [exercise], the [letter] for the
/// glyph scorer/guide, and the [ribbon] position. The host listens for advance
/// via [onNext] (pass) and supplies the audio tap handler.
class ExerciseScaffold extends ConsumerStatefulWidget {
  const ExerciseScaffold({
    super.key,
    required this.exercise,
    required this.letter,
    this.ribbon,
    this.kick = '',
    this.onNext,
    this.onAudioTap,
    this.strings = const ExerciseScaffoldStrings(),
    this.customSurface,
    this.graphExerciseId,
    this.onGraphNodePassed,
  });

  /// The config that drives the whole page.
  final Exercise exercise;

  /// The letter geometry for the WriteSurface (guide + scorer).
  final Letter letter;

  /// The R→L position dots `{total, active}`; omit to hide the ribbon.
  final ({int total, int active})? ribbon;

  /// The small eyebrow label (e.g. "Q3 · writeWord").
  final String kick;

  /// Advance handler — invoked from the pass-state "Next exercise" CTA.
  final VoidCallback? onNext;

  /// Tapped when an audio prompt part's play button is pressed.
  final void Function(String audioId)? onAudioTap;

  /// Static chrome copy (defaults are English; call site passes l10n).
  final ExerciseScaffoldStrings strings;

  /// An escape-hatch non-writing center panel (teachCard forms). When provided
  /// AND `exercise.surface == null`, it replaces the (absent) WriteSurface.
  final WidgetBuilder? customSurface;

  /// The canonical graph node id this exercise maps to (T2/T3). When non-null
  /// and the exercise passes, the scaffold calls [onGraphNodePassed] and the
  /// controller increments the clean-rep count for this node. Must be a REAL
  /// graph node id (e.g. `baa.traceLetter.isolated`, `baa.writeWord.dictation`,
  /// `baa.writeLetter.fromSound`) — never a synthetic per-word id like
  /// `baa.writeWord.door`. Pass null for exercises with no graph-node analog
  /// (e.g. the meet teachCard which is not scored, or per-word word-traces) —
  /// nothing is recorded for those.
  final String? graphExerciseId;

  /// Called immediately when this exercise scores a PASS (before the CTA fires),
  /// with the canonical graph node id so the host can increment clean-reps and
  /// drive [markNodeCleared] on the controller. Only called when [graphExerciseId]
  /// is non-null and the result is a pass. Never called for teach-cards or on a
  /// fail (T2: the rep counter only grows on genuine clean passes).
  final void Function(String graphExerciseId)? onGraphNodePassed;

  @override
  ConsumerState<ExerciseScaffold> createState() => _ExerciseScaffoldState();
}

class _ExerciseScaffoldState extends ConsumerState<ExerciseScaffold> {
  /// The imperative handle into the WriteSurface's canvas — the Clear and Done
  /// CTAs drive the actual ink through this (Clear used to reset only the mascot;
  /// Done is the submit trigger write-mode exercises had no way to fire).
  final StrokeCanvasController _canvasController = StrokeCanvasController();

  /// The non-PII session trajectory + recent mistakes accumulated across attempts
  /// of THIS exercise — fed into the chokepoint [buildTutorFacts] so the capable
  /// agent reasons over the session, not just the last attempt. Holds only
  /// derived records ({passed, mistakeId, section}); never raw strokes (GROUND-02).
  final List<AttemptFact> _trajectory = [];
  final List<String> _recentMistakes = [];

  /// Phase 17 (STRK-01): the DERIVED, point-free stroke-geometry diff for the
  /// CURRENT attempt, set by [WriteSurface.onStrokeDiff] just before the verdict
  /// arrives, consumed by [_onResult] when building the coach FACTS, then cleared.
  /// Never holds raw strokes (the surface discards those) — only the derived map.
  Map<String, Object?>? _pendingStrokeDiff;

  bool get _isTeachCard => widget.exercise.surface == null;

  /// Phase 17.2 (owner directive 2026-07-07): baa is the LIVE-AGENT path. On it
  /// the cloud coach's line is the ONLY feedback words shown — the authored
  /// (offline) line NEVER renders, not first, not on error/timeout, and is
  /// never spoken. The feedback words area stays empty until the agent line
  /// arrives, then shows ONLY that line (in both the tutor bubble and the bottom
  /// feedback bar). Non-agent letters (alif etc.) keep the instant authored line
  /// via [AuthoredFallbackBrain]. Gated on the letter id exactly like the brain
  /// selection in [_onResult] (Phase 14-17 coaching was scoped to baa).
  bool get _isAgentPath => widget.letter.id == 'baa';

  @override
  void initState() {
    super.initState();
    // Load the controller for this exercise on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseControllerProvider.notifier).load(widget.exercise);
      // Phase 17.2 (demo): kick off the (tiny) curriculum-graph load now so the
      // graph-legal next-exercise candidates are already warm by the time the
      // child finishes their FIRST attempt — the coach can then propose the next
      // exercise on the very first "Next". A no-op read that just starts the
      // keepAlive FutureProvider; harmless for non-agent letters.
      ref.read(curriculumGraphProvider);
      // Clear any stale agent line from a prior exercise.
      ref.read(tutorLineProvider.notifier).clear();
      // Clear the stale Teacher's Eye insight too (demo chrome).
      ref.read(tutorInsightProvider.notifier).clear();
      // Stop any in-flight coach voice from the prior exercise so a fresh idle is
      // silent (the visual is reset; the voice must not carry over). Fire-and-
      // forget — never block the build (ADR-014 display-only).
      unawaited(ref.read(ttsCoachSpeakerProvider).stop());
    });
  }

  /// Phase 17: stash the derived stroke-geometry diff for the current attempt. It
  /// arrives from [WriteSurface] just before [_onResult] (point-free; no strokes).
  void _onStrokeDiff(Map<String, Object?>? diff) {
    _pendingStrokeDiff = diff;
  }

  void _onValidating() {
    // LATENCY MARK 1 (debug/demo-only): the child lifted the stylus and the
    // letter is complete — the start of the written-stroke → first-TTS path.
    markLatency(LatencySegment.stylusUp);
    ref.read(exerciseControllerProvider.notifier).think();
  }

  /// Apply a scored attempt. The deterministic on-device scorer OWNS pass/fail on
  /// EVERY path (D-A — this REVERSES the Phase-17.1 AI-owns-pass/fail image judge):
  /// the verdict + star render INSTANTLY and synchronously from [result] (GROUND-01,
  /// the local reflex) — never deferred to, and never overturned by, a model. The
  /// brain then supplies a richer coaching LINE a beat later (the WORDS only); a
  /// cold, slow, offline, or failing server can affect ONLY that line, never the
  /// verdict or the star. This is the structural fix for UAT F2 (no more
  /// flash-then-overwrite: nothing is ever applied twice).
  void _onResult(CheckResult result) {
    final section = widget.exercise.type ?? widget.exercise.skill;
    final strokeDiff = _pendingStrokeDiff;
    _pendingStrokeDiff = null;

    // The scorer verdict applies UNCONDITIONALLY and synchronously — the instant
    // reflex (D-A / GROUND-01). No path waits on the network.
    ref.read(exerciseControllerProvider.notifier).applyResult(result);
    markLatency(LatencySegment.scorerVerdictRendered);
    // Phase 17.2: reset the tutor-owned WORDS channel so the feedback area is
    // EMPTY until the fresh line resolves. On the baa/agent path this is the
    // whole point — no authored line ever shows, so the area waits (and the
    // bubble hides) until the agent line lands. On non-agent letters the bubble
    // and bottom bar read the instant authored `state.line`, so this clear is
    // invisible there. The verdict/star are already applied and stand (D-A).
    ref.read(tutorLineProvider.notifier).clear();
    // DEMO "Teacher's Eye": publish what the scorer just saw (criteria + the
    // point-free geometry summary). The agent's pick merges in when the brain
    // resolves. Agent path only — presenter chrome, read-only.
    if (_isAgentPath) {
      ref.read(tutorInsightProvider.notifier).set(TutorInsight(
            criteria: result.criteria,
            diffSummary: strokeDiff?['summary'] as String?,
          ));
    }
    if (result.passed && widget.graphExerciseId != null) {
      widget.onGraphNodePassed?.call(widget.graphExerciseId!);
    }
    _recordAttempt(section, result.passed, result.mistakeId);

    final facts = buildTutorFacts(
      letterId: widget.letter.id,
      section: section,
      result: result,
      recentMistakes: List<String>.unmodifiable(_recentMistakes),
      trajectory: List<AttemptFact>.unmodifiable(_trajectory),
      strokeDiff: strokeDiff,
      // Phase 17.2 (demo): on the baa agent path, thread the graph-legal
      // next-exercise candidates so the cloud coach proposes the NEXT exercise
      // FROM the graph (the client re-checks legality before accepting —
      // exercise_selector_provider). Baa-only (the graph + the coach prompt are
      // baa-scoped), matching the brain gate below. Off the agent path it stays
      // empty (→ omitted from the wire).
      legalNextExerciseIds:
          _isAgentPath ? _legalNextExerciseIds() : const <String>[],
    );
    // The cloud agent's coaching prompt is baa-specific (Phase 14-17 was scoped to
    // baa), so it must run ONLY for baa — for any other letter it speaks baa
    // coaching ("deeper curve", "the dot"). Non-baa letters use the
    // AuthoredFallbackBrain, which returns the letter's OWN authored feedback line.
    // (Generalizing the agent beyond baa is the agent-driven-unit work for next.)
    final feedback = widget.exercise.feedback ?? const <String, String>{};
    final TutorBrain brain = _isAgentPath
        ? ref.read(tutorBrainFactoryProvider)(feedback)
        : AuthoredFallbackBrain(feedback: feedback);
    brain.next(facts).then((decision) {
      if (!mounted) return;
      final line = _lineOf(decision);

      // Route the agent's line into the tutor-owned channel. Empty → null so the
      // verdict-side authored line shows. The verdict/star are already applied and
      // are NOT touched here — the brain only enriches the WORDS (D-A).
      ref.read(tutorLineProvider.notifier).set(line.isNotEmpty ? line : null);
      markLatency(LatencySegment.lineRendered);

      // DEMO "Teacher's Eye": merge the agent's next-exercise pick + rationale
      // into the insight (keeps the criteria/diff already published at verdict).
      final plan = decision.plan;
      if (_isAgentPath && plan?.nextExerciseId != null) {
        final cur = ref.read(tutorInsightProvider);
        ref.read(tutorInsightProvider.notifier).set(TutorInsight(
              criteria: cur?.criteria,
              diffSummary: cur?.diffSummary,
              pick: plan!.nextExerciseId,
              rationale: plan.rationale,
            ));
      }

      // PHASE 16 PRESENCE HOOK: speak the resolved bubble text. On the agent path
      // (baa) the ONLY voice is the agent's line — never the authored floor
      // (owner directive 2026-07-07): if the agent returned nothing, stay silent.
      // Non-agent letters still voice the authored floor. Fire-and-forget — never
      // stalls the loop.
      final spokenText =
          line.isNotEmpty ? line : (_isAgentPath ? '' : _floorLineFor(result));
      if (spokenText.isNotEmpty) {
        markLatency(LatencySegment.firstTtsStart);
        unawaited(ref.read(ttsCoachSpeakerProvider).speak(spokenText));
      }
    }).catchError((_) {
      // The brain never throws, but be defensive. The scorer verdict is already
      // applied and STANDS; a brain failure only clears the (absent) tutor line —
      // never a flash-then-overwrite, never a verdict reversal (D-A).
      if (!mounted) return;
      ref.read(tutorLineProvider.notifier).clear();
    });
  }

  /// Append a derived (non-PII) attempt record to the session trajectory + recent
  /// mistakes. Always called with the deterministic scorer's verdict (D-A) so the
  /// next-question selection reacts to the on-device decision, never a model's.
  void _recordAttempt(String section, bool passed, String? mistakeId) {
    _trajectory.add(AttemptFact(passed: passed, mistakeId: mistakeId, section: section));
    if (!passed && mistakeId != null) {
      _recentMistakes.insert(0, mistakeId);
    }
  }

  /// Phase 17.2 (demo): the graph-LEGAL next-exercise candidate ids for the
  /// child's CURRENT durable position. Reuses the selection router's single
  /// source of truth — [CurriculumGraph.isLegalSelection] (the G4/G5/G6 rail) over
  /// every graph node — so the candidate set is EXACTLY what the router would
  /// accept; it never reimplements legality. The position (cleared tiers /
  /// competencies) is read from the SAME durable [letterUnitControllerProvider]
  /// instance the screen drives (family key = the baa letter id). Best-effort:
  /// returns empty (→ the FACTS field is omitted) when the graph has not loaded or
  /// the controller has no position yet, so it degrades cleanly (e.g. a standalone
  /// widget-test scaffold with no controller).
  List<String> _legalNextExerciseIds() {
    final graph = ref.read(curriculumGraphProvider).asData?.value;
    if (graph == null) return const [];
    final pos = ref.read(letterUnitControllerProvider(widget.letter.id));
    return [
      for (final node in graph.nodes)
        if (graph.isLegalSelection(
          node.exerciseId,
          clearedTiers: pos.clearedTiers,
          clearedCompetencies: pos.clearedCompetencies,
        ))
          node.exerciseId,
    ];
  }

  /// DEMO (17.2) — the "Teacher's Eye" strip. Renders the last attempt's five
  /// criterion zones, the point-free geometry read, and the agent's pick +
  /// rationale. Presenter chrome: read-only, additive, hidden until the first
  /// attempt publishes an insight.
  Widget _teacherEye() {
    final insight = ref.watch(tutorInsightProvider);
    if (insight == null) return const SizedBox.shrink();
    String mark(Object? zone) => switch (zone) {
          'certainlyCorrect' => '✓',
          'fuzzy' => '~',
          _ => '✗',
        };
    const labels = <String, String>{
      'strokeCount': 'Strokes',
      'strokeOrder': 'Order',
      'shape': 'Shape',
      'direction': 'Dir',
      'dot': 'Dot',
    };
    final criteria = insight.criteria;
    final critLine = (criteria == null || criteria.isEmpty)
        ? null
        : criteria
            .map((c) =>
                '${labels[c['criterion']] ?? c['criterion']} ${mark(c['zone'])}')
            .join('  ');
    final small = QalamTextStyles.label.copyWith(
      fontSize: 11.5,
      height: 1.35,
      color: QalamTokens.fgMuted,
    );
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: QalamTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QalamTokens.aquaEdge),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WHAT THE TUTOR SAW',
                style: small.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: QalamTokens.inkTeal,
                )),
            if (critLine != null) ...[
              const SizedBox(height: 4),
              Text(critLine,
                  style: small.copyWith(
                      color: QalamTokens.fg, fontWeight: FontWeight.w700)),
            ],
            if (insight.diffSummary != null) ...[
              const SizedBox(height: 3),
              Text(insight.diffSummary!,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: small),
            ],
            if (insight.pick != null) ...[
              const SizedBox(height: 3),
              Text(
                '➜ next: ${insight.pick}'
                '${insight.rationale != null ? ' — ${insight.rationale}' : ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: small.copyWith(
                    color: QalamTokens.inkTeal, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Pull the spoken line out of whichever ACTION shape the brain returned.
  String _lineOf(TutorDecision d) => switch (d) {
        Say(:final text) => text,
        PresentActivity(:final coachingLine) => coachingLine,
        _ => '',
      };

  /// The authored FLOOR line for [result] — a mirror of
  /// `AuthoredFallbackBrain._resolveLine` over the active exercise's feedback:
  ///   • pass            → feedback['pass']
  ///   • miss (known id) → feedback[mistakeId]
  ///   • miss (unknown)  → the first non-'pass' authored line
  /// Used to VOICE the offline floor when no agent line is present (D-04), so the
  /// spoken text matches the verdict-side authored line the bubble shows. Empty
  /// only when nothing is authored at all (then there is nothing to speak).
  String _floorLineFor(CheckResult result) {
    final feedback = widget.exercise.feedback ?? const <String, String>{};
    if (result.passed) return feedback['pass'] ?? '';
    final id = result.mistakeId;
    final direct = id != null ? feedback[id] : null;
    if (direct != null) return direct;
    for (final entry in feedback.entries) {
      if (entry.key != 'pass') return entry.value;
    }
    return '';
  }

  /// Clear the child's ink AND reset the mascot/feedback — the Clear / Try-again
  /// CTAs. (Previously only the controller reset, so the drawing stayed put.)
  void _clear() {
    _canvasController.clear();
    ref.read(exerciseControllerProvider.notifier).reset();
    // Drop any agent line so the cleared idle state shows the prompt, not a
    // stale coaching bubble.
    ref.read(tutorLineProvider.notifier).clear();
    // Stop any in-flight coach voice — a cleared idle is silent (D-05). Fire-and-
    // forget; a stop hiccup is non-fatal (ADR-014 display-only).
    unawaited(ref.read(ttsCoachSpeakerProvider).stop());
  }

  /// Submit what's drawn for scoring — the Done CTA. Essential for write-mode
  /// (word) exercises, which have no auto count-reached completion.
  void _submit() => _canvasController.submit();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseControllerProvider);
    // Hold a LIVE listener on the graph: a one-shot read (initState) does not
    // keep an unlistened FutureProvider resolved on-device, so
    // _legalNextExerciseIds() saw null and the agent never received candidates.
    ref.watch(curriculumGraphProvider);
    // The tutor-owned coaching line (the WORDS channel). On the agent path it is
    // the ONLY source of feedback words for both the bubble and the bottom bar.
    final agentLine = ref.watch(tutorLineProvider);
    final s = widget.strings;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        // .ex-scaffold{padding:18px 26px 22px;}
        padding: const EdgeInsets.fromLTRB(26, 18, 26, 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── left: the tutor column (.ex-tutor) ──────────────────────────
            SizedBox(
              width: 258, // .ex-tutor width:258px
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TutorColumn(
                    state: state,
                    strings: s,
                    isAgentPath: _isAgentPath,
                  ),
                  // DEMO "Teacher's Eye" — what the tutor saw (agent path only).
                  if (_isAgentPath) _teacherEye(),
                ],
              ),
            ),
            const SizedBox(width: 24), // .ex-scaffold gap:24
            // ── right: the main column (.ex-main) ───────────────────────────
            Expanded(child: _mainColumn(state, s, agentLine)),
          ],
        ),
      ),
    );
  }

  Widget _mainColumn(
      ExerciseState state, ExerciseScaffoldStrings s, String? agentLine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // .ex-ribbonrow — the kick eyebrow + the ProgressRibbon (pushed to edge).
        Row(
          children: [
            if (widget.kick.isNotEmpty)
              Text(
                widget.kick,
                style: QalamTextStyles.label.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.13 * 12.5, // .ex-kick letter-spacing:0.13em
                  color: QalamTokens.inkTeal,
                ),
              ),
            const Spacer(),
            if (widget.ribbon != null)
              ProgressRibbon(
                total: widget.ribbon!.total,
                active: widget.ribbon!.active,
              ),
          ],
        ),
        // PromptHeader (top).
        PromptHeader(
          parts: widget.exercise.prompt,
          onAudioTap: widget.onAudioTap,
          playLabel: s.playLabel,
        ),
        // The center surface: WriteSurface (graded) / custom (teachCard) / none.
        const SizedBox(height: 14), // .ex-surface margin-top:14
        Expanded(child: _centerSurface()),
        // FeedbackPanel + CTA (bottom) — .ex-foot.
        const SizedBox(height: 12),
        _foot(state, s, agentLine),
      ],
    );
  }

  Widget _centerSurface() {
    final surface = widget.exercise.surface;
    if (surface != null) {
      return WriteSurface(
        exercise: widget.exercise,
        surface: surface,
        letter: widget.letter,
        onValidating: _onValidating,
        onResult: _onResult,
        onStrokeDiff: _onStrokeDiff,
        canvasController: _canvasController,
        watchMeLabel: widget.strings.watchMe,
      );
    }
    // teachCard: a custom non-writing panel, or just empty space.
    return widget.customSurface?.call(context) ?? const SizedBox.shrink();
  }

  Widget _foot(
      ExerciseState state, ExerciseScaffoldStrings s, String? agentLine) {
    // teachCard: NO graded FeedbackPanel — just the teach hint + a support CTA.
    if (_isTeachCard) {
      return Row(
        children: [
          Expanded(
            child: FeedbackPanelV2(
              state: FeedbackState.idle,
              idleHint: s.teachCardHint,
            ),
          ),
          const SizedBox(width: 14),
          _PrimaryCta(label: s.gotIt, onTap: widget.onNext),
        ],
      );
    }

    final fbState = switch (state.phase) {
      ExercisePhase.pass => FeedbackState.pass,
      ExercisePhase.fix => FeedbackState.fix,
      _ => FeedbackState.idle,
    };

    // The WORDS shown in the bottom bar. On the agent path (baa) they come ONLY
    // from the tutor channel ([agentLine]) — empty until the agent line arrives,
    // then the agent line (the SAME text the bubble shows); the authored line
    // never appears here (owner directive 2026-07-07, fixes the Phase-14 bottom-
    // bar-pins-authored issue). Non-agent letters keep the instant authored
    // `state.line`. The verdict FACE (pass star / fix ✕) still comes from the
    // scorer-owned [fbState], so the star renders instantly with empty words.
    final footLine = _isAgentPath ? (agentLine ?? '') : state.line;

    return Row(
      children: [
        Expanded(
          child: FeedbackPanelV2(state: fbState, line: footLine),
        ),
        const SizedBox(width: 14), // .ex-foot gap:14
        ..._ctaFor(state.phase, s),
      ],
    );
  }

  /// The CTA set per phase:
  ///   pass → "Next exercise"  · fix → "Clear" + "Try again"
  ///   idle → "Clear" + "Done" (Done submits the drawing for scoring — the only
  ///   way write-mode word exercises can finish; trace also auto-completes).
  List<Widget> _ctaFor(ExercisePhase phase, ExerciseScaffoldStrings s) {
    switch (phase) {
      case ExercisePhase.pass:
        return [_PrimaryCta(label: s.next, onTap: widget.onNext)];
      case ExercisePhase.fix:
        return [
          _QuietCta(label: s.clear, onTap: _clear),
          const SizedBox(width: 12),
          _PrimaryCta(label: s.tryAgain, onTap: _clear),
        ];
      default:
        return [
          _QuietCta(label: s.clear, onTap: _clear),
          const SizedBox(width: 12),
          _PrimaryCta(label: s.done, onTap: _submit),
        ];
    }
  }
}

/// The left tutor column: mascot + id + speech bubble (toned by the result).
///
/// A [ConsumerWidget] so it can read [tutorLineProvider] — the tutor-owned
/// coaching-line channel the scaffold writes the brain's line into. The bubble
/// TONE + mascot pose still come from the verdict-driven [ExerciseController]
/// (GROUND-01: the scorer owns the verdict); ONLY the bubble TEXT is replaced by
/// the agent's line when one is present.
class _TutorColumn extends ConsumerWidget {
  const _TutorColumn({
    required this.state,
    required this.strings,
    this.isAgentPath = false,
  });

  final ExerciseState state;
  final ExerciseScaffoldStrings strings;

  /// Phase 17.2: on the agent path (baa) the bubble shows ONLY the agent's line
  /// and never the authored floor — see [_bubbleText] (owner directive).
  final bool isAgentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentLine = ref.watch(tutorLineProvider);
    final tone = state.tone;
    final Color bubbleBg = switch (tone) {
      ExerciseTone.coral => QalamTokens.coralTint,
      ExerciseTone.leaf => QalamTokens.leafTint,
      ExerciseTone.neutral => QalamTokens.surfaceRaised,
    };
    final Color bubbleBorder = switch (tone) {
      ExerciseTone.coral => const Color(0xFFF6C3B5),
      ExerciseTone.leaf => const Color(0xFFB7E4CF),
      ExerciseTone.neutral => QalamTokens.aquaEdge,
    };
    final bool toned = tone != ExerciseTone.neutral;
    final String bubbleText = _bubbleText(agentLine);
    // Hide the speech bubble entirely when there's nothing to say (e.g. a
    // teachCard idle with no line) — an empty bubble read as a stray "white box
    // under the mascot" (owner bug #2b). It returns the moment a verdict lands.
    final bool showBubble = bubbleText.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // .ex-mascot{height:140px}
        SizedBox(
          height: 140,
          child: Center(child: QalamMascot(pose: state.pose, size: 140)),
        ),
        const SizedBox(height: 12),
        // .ex-tid — name + role.
        Text(
          strings.tutorName,
          textAlign: TextAlign.center,
          style: QalamTextStyles.heading.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: QalamTokens.deepInk,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          strings.tutorRole.toUpperCase(),
          textAlign: TextAlign.center,
          style: QalamTextStyles.label.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.12 * 10, // .ex-tid .role letter-spacing:0.12em
            color: QalamTokens.fgMuted,
          ),
        ),
        if (showBubble) ...[
          const SizedBox(height: 12),
          // .ex-speech — the bubble (toned coral/leaf on a verdict).
          Container(
          constraints: const BoxConstraints(minHeight: 92), // .ex-speech min-height
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            color: bubbleBg,
            borderRadius: BorderRadius.circular(18), // .ex-speech radius:18
            border: Border.all(color: bubbleBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (toned) ...[
                Text(
                  strings.tutorSays.toUpperCase(),
                  style: QalamTextStyles.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1 * 10,
                    color: tone == ExerciseTone.coral
                        ? const Color(0xFFC2512F)
                        : const Color(0xFF1E8A5B),
                  ),
                ),
                const SizedBox(height: 5),
              ],
              Text(
                bubbleText,
                style: QalamTextStyles.button.copyWith(
                  fontSize: 16, // .ex-speech font-size:16px
                  fontWeight: FontWeight.w500,
                  color: QalamTokens.fg,
                  height: 1.42,
                ),
              ),
            ],
          ),
          ),
        ],
      ],
    );
  }

  /// The bubble carries the prompt's `say` line in idle, and on a pass/fix the
  /// AGENT's coaching line when one is present ([tutorLineProvider]), falling
  /// back to the verdict-side authored line (the prototype's `tutorAndFeedback`
  /// html). The agent supplies only the WORDS; the verdict/tone is the scorer's
  /// (GROUND-01). Empty → nothing.
  String _bubbleText(String? agentLine) {
    if (state.phase == ExercisePhase.pass ||
        state.phase == ExercisePhase.fix) {
      // Prefer the agent's line on a verdict.
      if (agentLine != null && agentLine.trim().isNotEmpty) return agentLine;
      // On the agent path (baa) the authored floor NEVER shows — the words area
      // stays empty (the bubble hides) until the agent line arrives (owner
      // directive 2026-07-07). Non-agent letters degrade to the authored verdict
      // line (the instant offline floor).
      return isAgentPath ? '' : state.line;
    }
    return state.line; // idle line set by the host via the controller, if any.
  }
}

/// `.exbtn.primary` — the sticker teal CTA (the prototype's flat-bottom shadow).
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QalamTokens.inkTeal, // .exbtn.primary background:var(--ink-teal)
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 60, // .exbtn height:60px
          padding: const EdgeInsets.symmetric(horizontal: 26),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              // .exbtn.primary box-shadow:0 5px 0 var(--deep-ink)
              BoxShadow(color: QalamTokens.deepInk, offset: Offset(0, 5)),
            ],
          ),
          child: Text(
            label,
            style: QalamTextStyles.button.copyWith(
              fontSize: 18,
              color: QalamTokens.fgOnPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// `.exbtn.quiet` — the ghost CTA (transparent, aqua-edge border).
class _QuietCta extends StatelessWidget {
  const _QuietCta({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: QalamTokens.aquaEdge, width: 2),
          ),
          child: Text(
            label,
            style: QalamTextStyles.button.copyWith(
              fontSize: 18,
              color: QalamTokens.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}
