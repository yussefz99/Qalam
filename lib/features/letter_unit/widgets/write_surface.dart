// WriteSurface — the ONE canvas of the Letter-Unit exercise engine (Plan 07-04).
// A THIN config wrapper over the EXISTING StrokeCanvas (the Phase-3/4 ink/trace
// primitive) — it does NOT rebuild the ink primitive (COMPONENTS.md §3 / the
// prototype's `WriteSurface` = `Q.makeWrite` wrapper).
//
// SOURCE (reproduce exactly):
//   docs/design/prototypes/letter-unit-baa/prototype/exercise-components/
//     components.js   (WriteSurface — mode/unit/guideForm/given/demo + surface-tag)
//     components.css  (.ex-surface / .writebox / .given-ink / .surface-tag)
//   docs/design/prototypes/letter-unit-baa/prototype/letter-unit/unit.js (makeWrite)
//
// mode/unit/guideForm/given/demo behaviour:
//   • mode:trace  → the dotted guide is shown (the StrokeCanvas referenceStrokes
//     for the guideForm's contextual form). The surface-tag reads "Trace · over
//     the guide".
//   • mode:write  → a blank ruled line, NO dotted glyph (empty referenceStrokes).
//     The surface-tag reads "Write · <unit> · no guide".
//   • given {word, blankIndex} → the pre-filled given-ink cells + a dashed blank.
//   • demo:true   → a "Watch me" replay wiring the existing StrokeOrderAnimation.
//
// ON STYLUS-UP: StrokeCanvas.onLetterComplete fires; WriteSurface converts the
// Offsets to the validator's [x,y] pixel shape, calls `validateExercise(...)` via
// the ExerciseSpec adapter, and forwards the CheckResult to the host. The strokes
// are scored and discarded here (T-07-04-01) — only the verdict leaves.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exercise_engine/check_result.dart';
import '../../../core/exercise_engine/exercise_validator.dart';
import '../../../core/recognition/handwriting_recognizer.dart';
import '../../../core/recognition/ml_kit_recognizer.dart';
import '../../../core/scoring/reference_resolution.dart';
import '../../../models/exercise.dart';
import '../../../models/letter.dart';
import '../../../services/model_download_service.dart';
import '../../../tutor/stroke_diff.dart';
import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/arabic_text.dart';
import '../../practice/widgets/stroke_canvas.dart';
import '../../practice/widgets/stroke_order_animation.dart';
import '../exercise_spec_adapter.dart';

/// The config-driven write/trace surface. Composes the existing [StrokeCanvas];
/// on letter-complete it runs [validateExercise] and forwards the [CheckResult]
/// through [onResult].
class WriteSurface extends ConsumerStatefulWidget {
  const WriteSurface({
    super.key,
    required this.exercise,
    required this.surface,
    required this.letter,
    this.onResult,
    this.onStrokeDiff,
    this.onValidating,
    this.canvasController,
    this.watchMeLabel = 'Watch me',
    this.traceTag = 'Trace · over the guide',
    this.writeTagBuilder,
  });

  /// Imperative handle the engine scaffold uses to Clear the ink and force a
  /// Done/submit (write-mode exercises have no auto-complete trigger).
  final StrokeCanvasController? canvasController;

  /// The full exercise config (its check/expected/feedback drive validation).
  final Exercise exercise;

  /// The surface config (mode/unit/guideForm/given/demo).
  final Surface surface;

  /// The letter providing reference geometry for the glyph scorer + the dotted
  /// guide. Its [Letter.contextualForms] supplies the per-form reference strokes
  /// when [Surface.guideForm] names a contextual form.
  final Letter letter;

  /// Called with the validator verdict on letter-complete.
  final void Function(CheckResult result)? onResult;

  /// Phase 17 (STRK-01/GROUND-04): called on letter-complete with the DERIVED,
  /// point-free stroke-geometry diff (child vs reference) — or null when none can
  /// be computed (write mode / no reference). Fires just BEFORE [onResult] so the
  /// host has the diff in hand when it builds the coach FACTS. The raw strokes are
  /// still discarded here; only this derived map leaves the surface.
  final void Function(Map<String, Object?>? diff)? onStrokeDiff;

  /// Called the instant the child finishes the letter, BEFORE the (async)
  /// validator resolves — lets the host show the "thinking" beat.
  final VoidCallback? onValidating;

  /// "Watch me" replay label (call site passes l10n `exerciseWatchMe`).
  final String watchMeLabel;

  /// Trace-mode surface tag (l10n `exerciseSurfaceTagTrace`).
  final String traceTag;

  /// Write-mode surface tag builder, given the unit (l10n
  /// `exerciseSurfaceTagWrite(unit)`); defaults to a plain English fallback.
  final String Function(String unit)? writeTagBuilder;

  @override
  ConsumerState<WriteSurface> createState() => _WriteSurfaceState();
}

class _WriteSurfaceState extends ConsumerState<WriteSurface> {
  final GlobalKey<StrokeOrderAnimationState> _demoKey =
      GlobalKey<StrokeOrderAnimationState>();

  /// The trace canvas starts with a CLEAN dotted guide — the demo only plays
  /// when the child taps "Watch me", then auto-clears (owner bug #3c: the demo
  /// used to persist on the canvas, blocking the child from writing). The Watch
  /// & Trace section already shows the full demo in its own Watch phase first.
  bool _demoVisible = false;
  Timer? _demoTimer;
  static const Duration _demoDuration = Duration(milliseconds: 2400);

  /// One reused word recogniser (creating/closing one per attempt churns native
  /// resources and can hang the "thinking" beat). Lazily created, closed once on
  /// dispose. Recognition is wrapped in a timeout so it NEVER blocks forever.
  MlKitRecognizer? _recognizer;
  static const Duration _recognizeTimeout = Duration(seconds: 8);

  void _playDemo() {
    _demoTimer?.cancel();
    setState(() => _demoVisible = true);
    _demoTimer = Timer(_demoDuration, () {
      if (mounted) setState(() => _demoVisible = false);
    });
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _recognizer?.close(); // fire-and-forget native cleanup
    super.dispose();
  }

  bool get _isTrace => widget.surface.mode == 'trace';

  /// The reference strokes the canvas paints + scores against. For TRACE mode we
  /// resolve the [Surface.guideForm]'s contextual form (falling back to the
  /// letter's base reference); for WRITE mode we pass EMPTY so no dotted glyph
  /// shows (the blank ruled line).
  List<StrokeSpec> get _referenceStrokes {
    if (!_isTrace) return const <StrokeSpec>[];
    return _formStrokes;
  }

  /// The ONE asked positional form (WR-01 fix). The child must be graded against
  /// the form they are ASKED to write: the exercise's `expected.glyph.form` when
  /// authored, else the surface's `guideForm`. This is the SAME rule the
  /// validator applies for scoring (`exercise_validator._validateGlyph`), so a
  /// single value now drives the dotted guide, the canvas completion count,
  /// [computeStrokeDiff], AND the verdict — they can never diverge.
  ///
  /// Before this fix the guide + diff resolved against `surface.guideForm` only
  /// while the scorer resolved against `expected.glyph.form ?? guideForm`; an
  /// exercise authored with the two differing would make the child trace/diff
  /// form A but be scored against form B (a false shape/count fail plus a coach
  /// diff that contradicts the verdict). Undermines the "one shared resolver"
  /// invariant (reference_resolution.dart header / Pitfall 7).
  String? get _askedForm =>
      widget.exercise.expected?.glyph?.form ?? widget.surface.guideForm;

  /// The asked form's reference strokes, via the ONE shared resolver (Pitfall 7)
  /// — so the canvas completion count, [computeStrokeDiff], and the scorer all
  /// agree on the same per-form reference (a taa medial completing at 3 strokes
  /// matches the scorer's expected count). `resolveReferenceStrokes` already
  /// falls back to the letter's base reference for a null/empty per-form slot.
  List<StrokeSpec> get _formStrokes =>
      resolveReferenceStrokes(widget.letter, _askedForm);

  /// Glyph box width/height per the prototype (components.js glyphSize 150 for a
  /// glyph unit, 130 otherwise). The surface fills its slot; this sizes the
  /// drawable canvas band.
  double get _glyphSize => widget.surface.unit == 'glyph' ? 150 : 130;

  /// On letter-complete: convert Offsets → [x,y] pixel pairs, run the validator
  /// through the ExerciseSpec adapter, forward the verdict. Strokes discarded.
  Future<void> _onLetterComplete(List<List<Offset>> strokes) async {
    widget.onValidating?.call();
    final pixelStrokes = strokes
        .map((s) => s.map((o) => <double>[o.dx, o.dy]).toList())
        .toList();
    final spec = exerciseSpecFromExercise(widget.exercise);

    // Word checks (base 'sequence') are scored by RECOGNISING the written text
    // and comparing it to expected.word — geometry alone cannot tell باب from بب.
    // The validator needs `writtenWord`; without it the sequence check has no
    // evidence and passes blindly (owner bug: "no scoring — any writing is
    // correct"). Best-effort & offline (D-04/D-05): only when the ML Kit Arabic
    // model is downloaded. Ready-but-unreadable → '' so the validator records a
    // miss; not-ready → null so it degrades to the geometric/pass path (the model
    // keeps downloading in the background) rather than hard-blocking the child.
    String? writtenWord;
    List<String>? writtenWords;
    final base = spec.check?.base;
    if ((base == 'sequence' || base == 'order') &&
        ref.read(modelDownloadServiceProvider).isReady) {
      _recognizer ??= MlKitRecognizer();
      RecognitionResult res = const RecognitionResult();
      try {
        res = await _recognizer!.identify(pixelStrokes).timeout(
              _recognizeTimeout,
              onTimeout: () => const RecognitionResult(),
            );
      } catch (_) {
        // Any recognition failure → no opinion; never hang or throw out of the
        // validation handler (which would leave the tutor stuck on "thinking").
        res = const RecognitionResult();
      }
      // Model ready but unreadable/timed-out → '' so the validator records a
      // miss rather than a blind pass.
      final transcript = (res.topCandidate ?? '').trim();
      if (base == 'sequence') {
        writtenWord = transcript;
      } else {
        // base 'order' (baa.buildSentence.*): the child wrote a whole sentence —
        // split the recogniser transcription on whitespace into the ORDERED word
        // list the validator's `_validateOrder` compares. Before this, `order`
        // exercises received writtenWords==null and FAILED unconditionally — a dead
        // end a child could never pass, which the selector could route them into.
        writtenWords =
            transcript.isEmpty ? const <String>[] : transcript.split(RegExp(r'\s+'));
      }
    }

    final result = await validateExercise(
      spec,
      pixelStrokes,
      letter: widget.letter,
      writtenWord: writtenWord,
      writtenWords: writtenWords,
      guideForm: _askedForm, // WR-01: the SAME asked form the guide + diff use.
    );
    if (!mounted) return;
    // Phase 17: derive the point-free stroke-geometry diff from the just-captured
    // strokes vs the reference, THEN let pixelStrokes fall out of scope (still
    // discarded — only the derived diff leaves). Best-effort: any failure → null
    // diff (label-only coaching), never a thrown exception out of the handler.
    Map<String, Object?>? strokeDiff;
    if (_isTrace && _referenceStrokes.isNotEmpty) {
      try {
        strokeDiff = computeStrokeDiff(pixelStrokes, _referenceStrokes);
      } catch (_) {
        strokeDiff = null;
      }
    }
    widget.onStrokeDiff?.call(strokeDiff);
    widget.onResult?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final tag = _isTrace
        ? widget.traceTag
        : (widget.writeTagBuilder?.call(widget.surface.unit) ??
            'Write · ${widget.surface.unit} · no guide');

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          // .ex-surface .writebox{border-radius:24px} on a raised white canvas.
          decoration: BoxDecoration(
            color: QalamTokens.surfaceRaised,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: QalamTokens.aquaEdge),
          ),
          // Defect-1 (bottom-edge false-fail): the writebox must NEVER truncate
          // the child's ink. The capture layer already keeps points drawn slightly
          // below the box un-clamped (StrokeCanvas has no bounds clamp — verified
          // by stroke_canvas_test's "does not clamp" guard), and the shape verdict
          // is bbox-normalised / position-invariant (position_invariance_test). A
          // hard `Clip.antiAlias` here was the ONLY place a low bowl got visibly
          // cut at the box bottom — making a well-formed low baa LOOK shallow (the
          // owner's "ink shifts upward after pen-up"). Render the full stroke
          // un-shifted so what the child sees matches what the scorer measures.
          clipBehavior: Clip.none,
          child: Stack(
            children: [
              // write-mode ruled baseline (the blank line, no guide glyph).
              if (!_isTrace) const Positioned.fill(child: _RuledLine()),

              // the given-ink pre-filled cells (completeWord) — under the ink.
              if (widget.surface.given != null)
                Positioned.fill(
                  child: _GivenInk(
                    given: widget.surface.given!,
                    glyphSize: _glyphSize,
                  ),
                ),

              // the demo "Watch me" overlay — only while actively replaying, so
              // it clears off the canvas afterwards (owner bug #3c).
              if (_isTrace && widget.surface.demo && _demoVisible)
                Positioned.fill(
                  child: IgnorePointer(
                    child: StrokeOrderAnimation(
                      key: _demoKey,
                      referenceStrokes: _referenceStrokes,
                      duration: _demoDuration,
                    ),
                  ),
                ),

              // THE ink/trace primitive — reused verbatim, not rebuilt.
              Positioned.fill(
                child: StrokeCanvas(
                  // A fresh key per reference set so the canvas resets cleanly
                  // between exercises (it never clears strokes on pointer-down).
                  key: ValueKey<String>(
                    '${widget.exercise.id}:${widget.surface.mode}:${widget.surface.guideForm ?? ''}',
                  ),
                  referenceStrokes: _referenceStrokes,
                  onLetterComplete: _onLetterComplete,
                  controller: widget.canvasController,
                ),
              ),

              // the .surface-tag mode chip (top-start, RTL-aware via Positioned).
              Positioned(
                top: 14,
                left: 14,
                child: _SurfaceTag(label: tag),
              ),

              // the corner "Watch me" replay button (demo only).
              if (_isTrace && widget.surface.demo)
                Positioned(
                  top: 14,
                  right: 14,
                  child: _WatchMeButton(
                    label: widget.watchMeLabel,
                    onTap: _playDemo,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// `.surface-tag` — the pill mode chip ("Trace · …" / "Write · …").
class _SurfaceTag extends StatelessWidget {
  const _SurfaceTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: QalamTokens.parchmentDeep, // .surface-tag background:parchment-deep
        borderRadius: BorderRadius.circular(999), // .surface-tag radius:999
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: QalamTokens.inkTeal, // .surface-tag .sd background:ink-teal
            ),
          ),
          const SizedBox(width: 6), // .surface-tag gap:6
          Text(
            label,
            style: QalamTextStyles.label.copyWith(
              fontSize: 10.5, // .surface-tag font-size:10.5px
              fontWeight: FontWeight.w700,
              letterSpacing: 0.06 * 10.5, // .surface-tag letter-spacing:0.06em
              color: QalamTokens.fgMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The write-mode blank ruled baseline (no dotted guide glyph).
class _RuledLine extends StatelessWidget {
  const _RuledLine();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _RuledLinePainter());
}

class _RuledLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = QalamTokens.aquaEdge
      ..strokeWidth = 2;
    final y = size.height * 0.72; // a calm baseline in the lower third
    canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// `.given-ink` — the pre-filled letters the child does NOT write, with a dashed
/// blank cell at [Given.blankIndex] (completeWord). Faint guide colour.
class _GivenInk extends StatelessWidget {
  const _GivenInk({required this.given, required this.glyphSize});

  final Given given;
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    final letters = given.word.split('');
    return IgnorePointer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < letters.length; i++) ...[
                if (i > 0) const SizedBox(width: 6), // .given-ink gap:6
                if (i == given.blankIndex)
                  Container(
                    width: 96, // .gv-blank width:96px
                    height: 140, // .gv-blank height:140px
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: QalamTokens.inkTeal.withValues(alpha: 0.05),
                      border: Border.all(color: QalamTokens.inkTeal, width: 3),
                    ),
                  )
                else
                  ArabicText(
                    letters[i],
                    // .gv-letter color:#C7DCDC (the faint given guide colour).
                    style: QalamTextStyles.arDisplay.copyWith(
                      fontSize: glyphSize == 150 ? 120 : 96,
                      color: QalamTokens.inkGuide,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The corner "Watch me" replay button for the demo overlay.
class _WatchMeButton extends StatelessWidget {
  const _WatchMeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QalamTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(QalamTokens.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(QalamTokens.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline_rounded,
                  size: 18, color: QalamTokens.inkTeal),
              const SizedBox(width: 6),
              Text(
                label,
                style: QalamTextStyles.label.copyWith(
                  fontSize: 12,
                  color: QalamTokens.inkTeal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
