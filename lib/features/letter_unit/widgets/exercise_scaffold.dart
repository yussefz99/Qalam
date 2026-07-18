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
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/demo_flag.dart';
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
import 'teacher_margin_panel.dart';
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
    this.hearAgain = 'Hear it again',
    this.instructionTrace = 'Trace the letter',
    this.instructionWriteLetter = 'Write the letter',
    this.instructionWriteWord = 'Write the word',
    this.instructionCopyWord = 'Copy the word',
    this.instructionListenWrite = 'Listen and write',
    this.instructionConnect = 'Join the letters',
    this.instructionCompleteWord = 'Write the missing letter',
    this.instructionFillBlank = 'Write the missing part',
    this.instructionTransform = 'Change the word',
    this.instructionBuildSentence = 'Build the sentence',
    this.instructionMicroDrill = 'Practice this part',
    this.instructionMicroDrillDot = 'Practice the dot',
    this.instructionMicroDrillShape = 'Practice the curve',
    this.instructionMicroDrillStart = 'Practice the start',
    this.instructionFallback = 'Look and write',
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

  /// 18-12 / 19-02: the accessibility label of the replay-instruction control.
  /// 19-02 folds the standalone pill into the instruction bar; this is now the
  /// bar's `Semantics(button:true, label:)` (UI-SPEC §1 "Hear it again").
  final String hearAgain;

  // ── 19-02: per-type instruction-bar templates (D-02) ───────────────────────
  // The bar shows the PER-TYPE line keyed on `exercise.type` (NOT the say line,
  // Pitfall 6). English defaults live here so widget tests stay l10n-independent
  // (the `hearAgain` precedent); `app_en.arb` mirrors them as translatable keys.

  /// `traceLetter` — trace over the dotted guide.
  final String instructionTrace;

  /// `writeLetter` (no audio) — write the single letter from memory.
  final String instructionWriteLetter;

  /// `writeWord` (no audio, not a copy) — write the whole word.
  final String instructionWriteWord;

  /// `writeWord` copy variant (a `reveal:"thenHide"` word) — copy the shown word.
  final String instructionCopyWord;

  /// `writeWord`/`writeLetter` listen variant (carries an `AudioPart`).
  final String instructionListenWrite;

  /// `connectWord` — join the spaced letters into a word.
  final String instructionConnect;

  /// `completeWord` — write the one missing letter of the word.
  final String instructionCompleteWord;

  /// `fillBlank` — write the missing part.
  final String instructionFillBlank;

  /// `transformWord` — change the word per the rule chip.
  final String instructionTransform;

  /// `buildSentence` — build the sentence from the words.
  final String instructionBuildSentence;

  /// `microDrill` — practice one part (base line, before the criterion override).
  final String instructionMicroDrill;

  /// `microDrill` criterion `dot` override.
  final String instructionMicroDrillDot;

  /// `microDrill` criterion `shape` override.
  final String instructionMicroDrillShape;

  /// `microDrill` criterion `strokeOrder` override.
  final String instructionMicroDrillStart;

  /// Unknown/null type fallback.
  final String instructionFallback;
}

/// The brand nib glyph used as the `traceLetter` instruction icon (UI-SPEC §
/// Copywriting Contract). A vector asset, coloured ink-teal at the call site.
const String _kNibGlyphAsset = 'assets/icons/qalam-nib.svg';

/// Resolve the authored FLOOR line for a scored [result] over an exercise's
/// [feedback] map — a PURE mirror of `AuthoredFallbackBrain._resolveLine`
/// (kept byte-identical by construction):
///   • pass            → feedback['pass'] (or '' — nothing specific to celebrate)
///   • miss (known id) → feedback[mistakeId]
///   • miss (unknown)  → the first non-'pass' authored line, else the warm
///     [kGenericTryAgain] floor (NEVER '' on a fail — the silent-fail fix,
///     260718-l12; both resolvers share the one constant so the shown/spoken
///     text stays identical). An authored per-mistake line always wins over the
///     floor (the floor is only the terminal else).
///
/// Extracted to a top-level pure function so it is unit-testable without a widget
/// pump (the `@visibleForTesting` seam the plan asks for), while the private
/// `_floorLineFor` stays the widget-side call site.
@visibleForTesting
String resolveFloorLine(Map<String, String>? feedback, CheckResult result) {
  final fb = feedback ?? const <String, String>{};
  if (result.passed) return fb['pass'] ?? '';
  final id = result.mistakeId;
  final direct = id != null ? fb[id] : null;
  if (direct != null) return direct;
  for (final entry in fb.entries) {
    if (entry.key != 'pass') return entry.value;
  }
  return kGenericTryAgain;
}

/// The leading glyph + short child-readable line the instruction bar shows for
/// an exercise (19-02, D-02). Exactly one of [icon] / [svgAsset] is non-null:
/// [svgAsset] carries the brand nib glyph (traceLetter); [icon] is a Material
/// `*_rounded` glyph for every other type. [text] is the per-type imperative.
class InstructionSpec {
  const InstructionSpec({this.icon, this.svgAsset, required this.text})
      : assert(icon != null || svgAsset != null,
            'an InstructionSpec needs either a Material icon or a brand glyph');

  /// A Material `*_rounded` glyph, or null when [svgAsset] carries a brand glyph.
  final IconData? icon;

  /// A brand-glyph SVG asset path (traceLetter), or null when [icon] is used.
  final String? svgAsset;

  /// The short imperative line (sentence case), e.g. "Write the missing letter".
  final String text;
}

/// Resolve the per-type instruction (icon + text) for [exercise] (D-02) — the
/// content of the persistent instruction bar. Keyed on `exercise.type`, NOT the
/// `say` line (Pitfall 6: the say line is the spoken/bubble layer). The
/// `writeWord`/`writeLetter` sub-variants are disambiguated by an `AudioPart`
/// (listen → "Listen and write") vs a `reveal:"thenHide"` word (copy → "Copy the
/// word"); a `microDrill` overrides its base line per its first criterion
/// (dot/shape/strokeOrder). Text comes from [strings] so callers stay
/// l10n-independent (the `hearAgain` precedent). An unknown/null type falls back
/// to "Look and write".
InstructionSpec instructionTemplateFor(
  Exercise exercise, {
  ExerciseScaffoldStrings strings = const ExerciseScaffoldStrings(),
}) {
  final bool hasAudio = exercise.prompt.whereType<AudioPart>().isNotEmpty;
  final bool isCopy = exercise.prompt
      .whereType<TextPart>()
      .any((p) => p.reveal == 'thenHide');

  switch (exercise.type) {
    case 'traceLetter':
      return InstructionSpec(
          svgAsset: _kNibGlyphAsset, text: strings.instructionTrace);
    case 'writeLetter':
      if (hasAudio) {
        return InstructionSpec(
            icon: Icons.hearing_rounded, text: strings.instructionListenWrite);
      }
      return InstructionSpec(
          icon: Icons.create_rounded, text: strings.instructionWriteLetter);
    case 'writeWord':
      if (hasAudio) {
        return InstructionSpec(
            icon: Icons.hearing_rounded, text: strings.instructionListenWrite);
      }
      if (isCopy) {
        return InstructionSpec(
            icon: Icons.content_copy_rounded, text: strings.instructionCopyWord);
      }
      return InstructionSpec(
          icon: Icons.create_rounded, text: strings.instructionWriteWord);
    case 'connectWord':
      return InstructionSpec(
          icon: Icons.link_rounded, text: strings.instructionConnect);
    case 'completeWord':
      return InstructionSpec(
          icon: Icons.border_color_rounded,
          text: strings.instructionCompleteWord);
    case 'fillBlank':
      return InstructionSpec(
          icon: Icons.border_color_rounded, text: strings.instructionFillBlank);
    case 'transformWord':
      return InstructionSpec(
          icon: Icons.autorenew_rounded, text: strings.instructionTransform);
    case 'buildSentence':
      return InstructionSpec(
          icon: Icons.notes_rounded, text: strings.instructionBuildSentence);
    case 'microDrill':
      final String? criterion =
          exercise.criteria.isNotEmpty ? exercise.criteria.first : null;
      final String text = switch (criterion) {
        'dot' => strings.instructionMicroDrillDot,
        'shape' => strings.instructionMicroDrillShape,
        'strokeOrder' => strings.instructionMicroDrillStart,
        _ => strings.instructionMicroDrill,
      };
      return InstructionSpec(
          icon: Icons.center_focus_strong_rounded, text: text);
    default:
      return InstructionSpec(
          icon: Icons.visibility_rounded, text: strings.instructionFallback);
  }
}

/// DEMO (17.2) — the "Teacher's Eye": what the tutor saw on the LAST attempt,
/// made visible. Presenter chrome for the demo: read-only, additive, fed only
/// by data the client already holds (the scorer's criteria, the point-free
/// geometry summary, and the agent's next-exercise pick + rationale).
class TutorInsight {
  const TutorInsight({
    this.criteria,
    this.diffSummary,
    this.pick,
    this.rationale,
    this.arcStep,
    this.whyFacts,
  });
  final List<Map<String, Object?>>? criteria;
  final String? diffSummary;
  final String? pick;
  final String? rationale;

  /// 18-16: the CURRENT feedback moment's GENUINE remediation-arc step
  /// (`entry`/`stepDown`/`rebuild`/`retryOriginal`), or null when no arc is in
  /// progress. Threaded from the controller's cached policy outcome (NOT parsed
  /// from `pick` — the micro-drills are parked out of the live graph, D-03). The
  /// child-facing Teacher's Margin narrates the step-down from THIS signal.
  final String? arcStep;

  /// 18-16: the non-PII policy WHY facts (`criterion:*` / `arcStep:*` /
  /// `struggle:*`) for this moment. The margin names the arc's target part from
  /// these; never carries child data / geometry (ADR-014).
  final List<String>? whyFacts;
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
    this.advanceOnFix = false,
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

  /// 18-07 Task 3: in SELECTION mode the fix-state primary CTA ADVANCES to the
  /// SELECTED next node (`onNext`) instead of clearing for an in-place retry — so
  /// the anti-boredom / remediation arc actually CHANGES what the child sees after
  /// repeated same-criterion fails (the arc's whole point). The quiet "Clear" CTA
  /// still retries in place. Default false (legacy sections retry in place).
  final bool advanceOnFix;

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

  /// While true the tutor is SAYING what is needed and the canvas is held
  /// (visible, not writable) — owner directive 2026-07-12: a question must
  /// never open as a bare canvas; the child listens first, then writes.
  bool _instructionHold = false;

  bool get _isTeachCard => widget.exercise.surface == null;

  /// 18-12: whether this exercise has a spoken instruction to replay — a
  /// non-empty prompt `say` line on a graded (non-teachCard) surface. Gates the
  /// "Hear again" control so it appears only when there is actually something to
  /// re-speak (mirrors the no-op guard in [_speakInstructionThenRelease]).
  bool get _hasInstruction =>
      !_isTeachCard &&
      widget.exercise.prompt
          .whereType<SayPart>()
          .any((p) => p.line.trim().isNotEmpty);

  /// Phase 17.2 (owner directive 2026-07-07): baa is the LIVE-AGENT path. On it
  /// the cloud coach's line is the ONLY feedback words shown — the authored
  /// (offline) line NEVER renders, not first, not on error/timeout, and is
  /// never spoken. The feedback words area stays empty until the agent line
  /// arrives, then shows ONLY that line (in both the tutor bubble and the bottom
  /// feedback bar). Non-agent letters (alif etc.) keep the instant authored line
  /// via [AuthoredFallbackBrain]. Gated on the letter id exactly like the brain
  /// selection in [_onResult] (Phase 14-17 coaching was scoped to baa).
  bool get _isAgentPath => widget.letter.id == 'baa';

  /// Quick task 260718-nft: whether this letter is GRAPH-RAILED — i.e. its
  /// per-letter curriculum graph has LOADED (`curriculumGraphProvider(letterId)`
  /// has data). This is a SEPARATE axis from [_isAgentPath] (which stays baa-only
  /// for the server/agent legs). Graph-driven SELECTION — [beginSelection] /
  /// walker-driven next-question / cursor sync — runs under THIS for ANY graph
  /// letter (baa AND thaa AND every future promoted letter), so the offline
  /// [CurriculumGraphWalker] supplies the next node instead of the static section
  /// walk. The gate was conflated with [_isAgentPath] (== 'baa') before, which
  /// silently trapped every non-baa letter on the OLD static section order even
  /// though its graph was live (owner on-device thaa test, 2026-07-18).
  ///
  /// A synchronous `.asData?.value` read (never a blocking `.future`) — mirrors
  /// [_legalNextExerciseIds] / [LetterUnitController.beginSelection]. Letters with
  /// NO graph asset (alif, taa today) load-fail → `.asData` is null → this is
  /// false → they degrade EXACTLY as before: the static flow, no crash. The
  /// controller start() warm ([LetterUnitController.start]) resolves the future
  /// before the first attempt so this read is not racing to null on a first visit.
  bool get _isGraphRailed =>
      ref.read(curriculumGraphProvider(widget.letter.id)).asData?.value != null;

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
      ref.read(curriculumGraphProvider(widget.letter.id));
      // Clear any stale agent line from a prior exercise.
      ref.read(tutorLineProvider.notifier).clear();
      // Clear the stale Teacher's Eye insight too (demo chrome).
      ref.read(tutorInsightProvider.notifier).clear();
      // Stop any in-flight coach voice from the prior exercise, then SPEAK this
      // exercise's instruction (the prompt's say line) while HOLDING the canvas
      // (owner directive 2026-07-12: the tutor says what is needed before the
      // child can write — a question never opens as a bare canvas). Display-only:
      // the speaker swallows platform errors, an 8s cap releases a stalled hold,
      // and the tests' NoopTtsCoachSpeaker completes instantly (no hold observed).
      _speakInstructionThenRelease(mountAutoSpeak: true);
    });
  }

  /// The listen-and-write shape: the LONE visual stimulus is an [AudioPart],
  /// which PromptHeader renders as the hero "sound to write" card that
  /// AUTO-PLAYS the clip once on mount (D-07). Mirrors PromptHeader's
  /// hero-card condition exactly (visuals == [AudioPart]).
  bool get _autoPlayingHeroAudio {
    final visuals = widget.exercise.prompt
        .where((p) => p is! SayPart)
        .toList(growable: false);
    return visuals.length == 1 && visuals.first is AudioPart;
  }

  void _speakInstructionThenRelease({bool mountAutoSpeak = false}) {
    final speaker = ref.read(ttsCoachSpeakerProvider);
    final sayLine = widget.exercise.prompt
        .whereType<SayPart>()
        .map((p) => p.line.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    if (sayLine.isEmpty || _isTeachCard) {
      unawaited(speaker.stop());
      return;
    }
    // 19 review WR-03: on a lone-audio-stimulus MOUNT ([say, audio] — e.g.
    // baa.writeWord.dictation) the hero audio card already auto-plays the
    // clip in this same frame (PromptHeader D-07). Speaking the say line on
    // top plays two audio streams at once — on the one exercise type where
    // hearing the word clearly IS the question (the Phase-07 double-Hear
    // device bug is the precedent). The clip is the audible instruction; the
    // say line stays as the instruction bar's TEXT (readable with sound off,
    // D-01) and as its tap-to-re-hear reinforcement — a deliberate bar tap
    // still speaks it (mountAutoSpeak false). Scoped to a WIRED audio seam
    // (`onAudioTap != null`): with no seam the auto-play is a no-op, so the
    // say line is the only audible instruction and must still speak. Verify
    // overlap fixes on DEVICE, not only in widget tests: the two channels are
    // mocked separately here.
    if (mountAutoSpeak && widget.onAudioTap != null && _autoPlayingHeroAudio) {
      unawaited(speaker.stop());
      return;
    }
    setState(() => _instructionHold = true);
    unawaited(() async {
      try {
        await speaker.stop();
        await speaker
            .speak(sayLine)
            .timeout(const Duration(seconds: 8), onTimeout: () {});
      } catch (_) {
        // Display-only voice — a failure must never block the writing loop.
      } finally {
        if (mounted) setState(() => _instructionHold = false);
      }
    }());
  }

  /// The canvas while the instruction is being spoken: visible but not writable.
  Widget _holdWhileInstruction(Widget child) {
    return IgnorePointer(
      ignoring: _instructionHold,
      child: AnimatedOpacity(
        opacity: _instructionHold ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: child,
      ),
    );
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
    if (result.passed && widget.graphExerciseId != null) {
      widget.onGraphNodePassed?.call(widget.graphExerciseId!);
    }
    _recordAttempt(section, result.passed, result.mistakeId);

    // 18-07 / 260718-nft: BEGIN the feedback moment. For ANY GRAPH-RAILED letter
    // (baa AND thaa AND every future promoted letter — [_isGraphRailed], NOT the
    // baa-only [_isAgentPath]), when this exercise maps to a real graph node, the
    // controller records the attempt in the session-scoped store (0b), invokes
    // SelectionPolicy.narrow ONCE, and returns the policy-legal candidates —
    // threaded into the coach FACTS below so the coach proposes FROM the
    // policy-legal set (not a raw isLegalSelection sweep). The controller owns the
    // arc/profile/session context that survives scaffold key swaps (audit finding
    // 1.4). Splitting this off [_isAgentPath] is the fix for the owner's on-device
    // thaa bug: the walker never ran for a non-baa graph letter, so it fell back
    // to the static section walk even though its graph was live (2026-07-18).
    final controller =
        ref.read(letterUnitControllerProvider(widget.letter.id).notifier);
    final unitState = ref.read(letterUnitControllerProvider(widget.letter.id));
    final graphId = widget.graphExerciseId;
    final bool selectionBegan = _isGraphRailed && graphId != null;
    final candidates = selectionBegan
        ? controller.beginSelection(result, graphId,
            recentMistakes: List<String>.of(_recentMistakes))
        : const <String>[];

    // DEMO "Teacher's Eye" + 18-16 Teacher's Margin: publish what the scorer just
    // saw (criteria + the point-free geometry summary) AND — now that
    // beginSelection above has populated the policy outcome — the REAL arc signal
    // (arcStep + whyFacts). The child-facing Teacher's Margin narrates the
    // step-down from THIS arc state, not a micro-drill pick (parked out of the
    // live graph, D-03). The agent's next-exercise pick merges in when the brain
    // resolves. Agent path only — read-only presenter chrome + the warm margin.
    if (_isAgentPath) {
      ref.read(tutorInsightProvider.notifier).set(TutorInsight(
            criteria: result.criteria,
            diffSummary: strokeDiff?['summary'] as String?,
            arcStep: selectionBegan ? controller.pendingArcStep() : null,
            whyFacts: selectionBegan ? controller.pendingWhyFacts() : null,
          ));
    }

    final facts = buildTutorFacts(
      letterId: widget.letter.id,
      section: section,
      result: result,
      recentMistakes: List<String>.unmodifiable(_recentMistakes),
      trajectory: List<AttemptFact>.unmodifiable(_trajectory),
      strokeDiff: strokeDiff,
      // 18-07 / audit finding 1.3: carry the child's cleared graph-position state
      // (dead `const []` on the wire before this) so the coach's rail reasons over
      // real progress. Read from the durable controller state.
      clearedTiers: unitState.clearedTiers,
      clearedCompetencies: unitState.clearedCompetencies,
      // 18-07: the coach proposes the NEXT exercise FROM the POLICY-narrowed set
      // (anti-boredom + arc + micro-drill already applied), not a raw legal sweep.
      // Falls back to the raw legal sweep only while the graph is still loading.
      legalNextExerciseIds: candidates.isNotEmpty
          ? candidates
          : (_isAgentPath ? _legalNextExerciseIds() : const <String>[]),
      // Req 2: a RETURNING child's coach facts carry the compiled across-session
      // profile (struggles/strengths) so the first turn already reflects the last
      // session. Null on a cold boot / empty mirror (omit-when-null).
      profile: _isAgentPath ? controller.profileFacts() : null,
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
    final decisionFuture = brain.next(facts);

    // 18-07 (CLOSES the Phase-15 dead wire) + 19 review WR-04: the coach's
    // TutorDecision is threaded into the selection so the agent's (policy-legal)
    // pick is what the child ACTUALLY gets next. Runs on pass AND fail (a fail
    // enters the arc / remediation); the pick + arc persist ride THIS same
    // /coach round-trip. The controller re-checks legality (accept iff candidate
    // AND graph-legal, else the walker) so an illegal proposal never reaches the
    // child (R5). Handed to the CONTROLLER synchronously at verdict (WR-04):
    // the controller deliberately outlives scaffold key swaps (audit finding
    // 1.4), so the arc advance/persist must never ride the scaffold's `mounted`
    // flag — a fast "Try again"/"Next" tap epoch-remounts this scaffold before
    // a slow coach call resolves, and the old mounted-gated continuation then
    // silently dropped the whole selection moment (no arc advance, no persist —
    // the D-02 step-down guarantee degraded to retry-in-place). This also sets
    // the controller's `nextReady` future for THIS moment immediately, so the
    // pass-CTA awaits the fresh pick, never a stale prior one.
    //
    // 260718-nft: gated on [_isGraphRailed] (any graph letter), NOT the baa-only
    // [_isAgentPath]. This is the OTHER half of the owner's thaa fix: without it
    // the controller never flips `selectionActive`, `_nextReady` stays null, and
    // the screen's `_advance` never enters the presenter — so a non-baa letter
    // stayed on the static section walk. For a non-agent letter `decisionFuture`
    // is the AuthoredFallbackBrain's `PresentActivity` (plan == null), so
    // RouterExerciseSelector falls straight to the offline CurriculumGraphWalker —
    // graph-driven selection with zero server call, exactly the offline floor.
    if (_isGraphRailed && graphId != null) {
      unawaited(controller.selectNextWhenDecided(facts, decisionFuture));
    }

    decisionFuture.then((decision) {
      if (!mounted) return;
      final line = _lineOf(decision);

      // Route the agent's line into the tutor-owned channel. Empty → null so the
      // verdict-side authored line shows. The verdict/star are already applied and
      // are NOT touched here — the brain only enriches the WORDS (D-A).
      ref.read(tutorLineProvider.notifier).set(line.isNotEmpty ? line : null);
      markLatency(LatencySegment.lineRendered);

      // (The selection continuation runs on the CONTROLLER — see
      // selectNextWhenDecided above the mounted gate, 19 review WR-04.)

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
              // Carry the verdict-time arc signal through the merge (like
              // criteria/diff) so the margin keeps narrating the step-down.
              arcStep: cur?.arcStep,
              whyFacts: cur?.whyFacts,
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
    final graph = ref.read(curriculumGraphProvider(widget.letter.id)).asData?.value;
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

  /// The authored FLOOR line for [result] — delegates to the pure
  /// [resolveFloorLine] seam over the active exercise's feedback. Used to VOICE
  /// the offline floor when no agent line is present (D-04), so the spoken text
  /// matches the verdict-side authored line the bubble shows.
  String _floorLineFor(CheckResult result) =>
      resolveFloorLine(widget.exercise.feedback, result);

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
    ref.watch(curriculumGraphProvider(widget.letter.id));
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
                  // 18-16 (UAT T6): the child-facing Teacher's Margin moved OUT of
                  // this column to BESIDE the writing canvas (see _mainColumn), so
                  // it reads as "a note near the writing canvas" and is not the
                  // visual twin of the demo Teacher's Eye strip below.
                  //
                  // DEMO "Teacher's Eye" — the 17.2 diagnostic read-out. 18-16
                  // (UAT T6): gated to DEMO builds only (kDemoMode). Real
                  // child-facing builds omit --dart-define=DEMO=true, so this
                  // duplicate strip disappears and the Teacher's Margin is the
                  // SINGLE margin surface.
                  if (_isAgentPath && kDemoMode) _teacherEye(),
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
        // 19-02 (D-01/D-02/D-03): the persistent instruction bar — a fixed strip
        // between the ribbon row and PromptHeader that renders the SAME place on
        // every graded type, telling the child what to do from the screen alone
        // (readable with sound off). Its text is the PER-TYPE template keyed on
        // exercise.type (NOT the say line — Pitfall 6). The whole bar is one tap
        // target that re-speaks the spoken instruction: it ABSORBS the 18-12
        // "Hear again" pill so there is exactly ONE replay affordance, never two
        // (the Phase-07 double-Hear-button device bug is the cautionary
        // precedent). Guarded by [_hasInstruction] (hidden on teachCard + empty
        // say-line — there is nothing to re-hear). The bar is never dimmed; only
        // the canvas is held while speaking.
        if (_hasInstruction) ...[
          const SizedBox(height: 12),
          _instructionBar(s),
          const SizedBox(height: 12),
        ],
        // PromptHeader (top).
        PromptHeader(
          parts: widget.exercise.prompt,
          onAudioTap: widget.onAudioTap,
          playLabel: s.playLabel,
        ),
        // The center surface: WriteSurface (graded) / custom (teachCard) / none.
        // Held (not writable) while the tutor speaks the instruction. On the
        // agent path (baa) with a graded surface the Teacher's Margin sits BESIDE
        // the canvas (18-16 / UAT T6).
        const SizedBox(height: 14), // .ex-surface margin-top:14
        Expanded(
          child: (_isAgentPath && !_isTeachCard)
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _holdWhileInstruction(_centerSurface())),
                    const SizedBox(width: 18),
                    // 18-16 (UAT T6): the child-facing Teacher's Margin — the
                    // SINGLE, recognizable margin note beside the canvas (the demo
                    // Teacher's Eye twin is gated out of non-demo builds). It shows
                    // a calm resting focus BEFORE the first verdict, then the WHY +
                    // arc step-down at verdict — a persistent presence, not a
                    // verdict-only blast. Scrolls if the note grows.
                    SizedBox(
                      width: 224,
                      child: SingleChildScrollView(
                        child: TeacherMarginPanel(
                          letter: widget.letter,
                          exercise: widget.exercise,
                        ),
                      ),
                    ),
                  ],
                )
              : _holdWhileInstruction(_centerSurface()),
        ),
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

  /// 19-02 (D-01/D-02/D-03) — the persistent instruction strip (UI-SPEC §1).
  /// A light --teal-tint surface with a leading per-type glyph, the short
  /// child-readable per-type line, and a trailing speaker glyph. The WHOLE bar
  /// is one tap target whose onTap re-invokes [_speakInstructionThenRelease]
  /// verbatim (re-hear) — it is the SINGLE replay affordance (the 18-12 pill is
  /// gone). English content island (LTR), like the Teacher's Eye strip. Every
  /// value cites [QalamTokens]/[QalamTextStyles]; no gold (anti-gamification).
  Widget _instructionBar(ExerciseScaffoldStrings s) {
    final spec = instructionTemplateFor(widget.exercise, strings: s);
    return Semantics(
      key: const Key('instructionBar'),
      button: true,
      label: s.hearAgain, // UI-SPEC §1: "Hear it again"
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16), // --radius-md → 16
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _speakInstructionThenRelease,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64), // --target-min
            padding: const EdgeInsets.symmetric(horizontal: 24), // space-6
            decoration: BoxDecoration(
              color: QalamTokens.tealTint, // --teal-tint guidance fill
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: QalamTokens.aquaEdge, width: 1.5),
            ),
            // English instruction reads L→R (island), like _teacherEye.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  _instructionLeading(spec),
                  const SizedBox(width: 12), // icon↔text gap (space-3)
                  Expanded(
                    child: Text(
                      spec.text,
                      style: QalamTextStyles.heading.copyWith(
                        fontSize: 20, // --fz-20 (UI-SPEC instruction role)
                        color: QalamTokens.fg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Trailing speaker glyph = the replay affordance.
                  const Icon(Icons.volume_up_rounded,
                      size: 24, color: QalamTokens.inkTeal),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The bar's leading glyph — the brand nib SVG for traceLetter, else the
  /// per-type Material glyph. 24px, ink-teal (never gold).
  Widget _instructionLeading(InstructionSpec spec) {
    if (spec.svgAsset != null) {
      return SvgPicture.asset(
        spec.svgAsset!,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(
            QalamTokens.inkTeal, BlendMode.srcIn),
      );
    }
    return Icon(spec.icon, size: 24, color: QalamTokens.inkTeal);
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
          // In selection mode (advanceOnFix) the primary CTA advances to the
          // SELECTED next node (which is the same exercise on an early fail, and
          // the confidence-rebuilding drill once the same-criterion streak trips
          // the arc); Clear still retries in place. Legacy sections retry in place.
          _PrimaryCta(
            label: s.tryAgain,
            onTap: widget.advanceOnFix ? widget.onNext : _clear,
          ),
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
