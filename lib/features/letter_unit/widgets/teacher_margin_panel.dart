// TeacherMarginPanel — the CHILD-FACING remediation-arc narration + WHY line
// (Plan 18-10 Task 1 · D-01 · sketch 001 Variant C "The Teacher's Margin").
//
// Unlike the 17.2 demo-only "Teacher's Eye" strip (_teacherEye in
// exercise_scaffold.dart — a diagnostic read-out of criterion marks + pick +
// rationale), this panel is what the CHILD sees beside the canvas: a warm,
// pencil-note margin that names the part being worked on and, during a
// remediation arc, narrates the step-down in the tutor's voice.
//
// SOURCE (reuse, never a second insight source): it reads the SAME [TutorInsight]
// the scaffold already publishes at verdict/coach time (exercise_scaffold.dart
// lines ~273-278 at the verdict, ~356-364 when the coach resolves). The WHY line
// rides the SAME degradation axis as coaching (D-10):
//   • ONLINE  → the coach's `rationale` (the LLM WHY line), verbatim.
//   • OFFLINE / pre-coach → an authored template keyed by the targeted criterion
//     (the verdict-time `criteria` are already published, the coach `rationale`
//     is not yet), so the panel degrades to the same authored floor the coach
//     line does — same panel, degraded source.
//
// ANTI-GAMIFICATION (CLAUDE.md Decided): the panel adds NO reward surface — no
// counter, streak, badge, points, or "+N" hype. It reads like a teacher's margin
// note. Parchment/ink tokens only; no new palette.
//
// PROVISIONAL COPY (signed:false): the WHY templates + the arc step-down framing
// are the owner-mother's to sign at the 18-11 HUMAN-UAT gate (D-03). They live as
// named strings here, never as scattered literals, so the sign-off is one edit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exercise.dart';
import '../../../models/letter.dart';
import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import 'exercise_scaffold.dart' show TutorInsight, tutorInsightProvider;

/// The child-facing Teacher's Margin panel. When an [exercise] is supplied it
/// has a persistent RESTING presence (a calm note naming the current question's
/// focus) BEFORE the first verdict, then carries the WHY line and — during a
/// GENUINE remediation arc — the named step-down narration (18-16 / UAT T6). With
/// no [exercise] and no insight it is silent (a bare host / test pump).
class TeacherMarginPanel extends ConsumerWidget {
  const TeacherMarginPanel({
    super.key,
    required this.letter,
    this.exercise,
    this.title = "Teacher's margin",
  });

  /// The letter under practice (the living-tutor arc is baa-scoped for now); kept
  /// for future per-letter WHY copy. The provisional templates below are
  /// baa-flavoured (D-03) — a newly signed letter grows its own lines at 18-11.
  final Letter letter;

  /// The current question — drives the RESTING focus shown before the first
  /// verdict (18-16). Null on a bare host / test pump → the panel stays silent
  /// until an insight publishes.
  final Exercise? exercise;

  /// The small margin heading (call site passes l10n; default keeps tests
  /// independent of l10n generation).
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insight = ref.watch(tutorInsightProvider);
    if (insight == null) {
      // 18-16 (UAT T6): a persistent RESTING presence — a calm note naming the
      // current question's focus BEFORE the first verdict, so the margin is a
      // recognizable, singular feature (not a verdict-only blast). Silent only
      // when there is no exercise context (a bare host / test pump).
      final ex = exercise;
      if (ex == null) return const SizedBox.shrink();
      return _restingNote(ex);
    }

    final criterion = _targetedCriterion(insight);
    // The WHY resolution (18-16 — vary per attempt; the authored table is a LAST-
    // RESORT offline FLOOR, not the majority-path output):
    //   1) ONLINE → the coach's `rationale` verbatim (the per-attempt WHY, now
    //      populated on the clean-pass path too, 18-14).
    //   2) CLEAN PASS offline (no failed criterion) → a warm pass-appropriate
    //      line — NOT the criterion-skewed static 'deeper bowl'.
    //   3) GENUINE miss offline → the authored floor for THAT failed criterion.
    final rationale = insight.rationale?.trim();
    final String why;
    if (rationale != null && rationale.isNotEmpty) {
      why = rationale;
    } else if (criterion == null) {
      why = _passWhy;
    } else {
      why = _authoredWhy(criterion);
    }
    // The arc's named step-down — present only during a GENUINE remediation arc
    // (the policy's real `arcStep`), NOT a micro-drill pick (drills parked, D-03).
    final arcLine = _arcStepDownLine(insight);

    return _frame([
      if (criterion != null) ...[
        const SizedBox(height: 6),
        // "Working on: the dot" — names the part, not a score.
        Text(
          'Working on · ${_friendlyCriterion(criterion)}',
          style: _workingOnStyle,
        ),
      ],
      const SizedBox(height: 8),
      // The WHY line — the tutor's warm register (online coach / offline
      // authored floor).
      Text(why, style: _whyStyle),
      if (arcLine != null) ...[
        const SizedBox(height: 10),
        // The named step-down — a coral pencil note that we take a detour and
        // come right back (never a step BACK; the arc "never leaves the desk",
        // sketch 001).
        Text(arcLine, style: _arcStyle),
      ],
    ]);
  }

  /// The RESTING note shown before the first verdict (18-16): the heading, the
  /// current question's focus when derivable, and a calm "take your time" line —
  /// a persistent, recognizable presence beside the canvas (never a reward).
  Widget _restingNote(Exercise ex) {
    final focus = _restingFocus(ex);
    return _frame([
      if (focus != null) ...[
        const SizedBox(height: 6),
        Text('Working on · $focus', style: _workingOnStyle),
      ],
      const SizedBox(height: 8),
      Text(_restingLine, style: _whyStyle),
    ]);
  }

  /// The shared pencil-note frame: parchment ground with a soft coral edge on the
  /// canvas side (sketch 001 Variant C `border-right: 2px coral-tint`) + the
  /// heading. [children] follow the heading.
  Widget _frame(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: QalamTokens.parchmentDeep,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        border: Border(
          right: BorderSide(color: QalamTokens.coralTint, width: 2),
        ),
      ),
      child: Directionality(
        // The margin note is the child's working-language guidance (LTR chrome),
        // like the rest of the tutor copy.
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title.toUpperCase(), style: _headingStyle),
            ...children,
          ],
        ),
      ),
    );
  }

  TextStyle get _headingStyle => QalamTextStyles.label.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.05 * 10,
        color: QalamTokens.fgMuted,
      );

  TextStyle get _workingOnStyle => QalamTextStyles.label.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: QalamTokens.deepInk,
      );

  TextStyle get _whyStyle => QalamTextStyles.button.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: QalamTokens.fg,
        height: 1.42,
      );

  TextStyle get _arcStyle => QalamTextStyles.button.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: QalamTokens.coral,
        height: 1.4,
      );

  /// PROVISIONAL (signed:false, D-03). The resting focus for [ex] before the
  /// first verdict — the drill's targeted criterion / spotlight zone when the
  /// question declares one, else null (a normal exercise names no single part).
  String? _restingFocus(Exercise ex) {
    if (ex.criteria.isNotEmpty) return _friendlyCriterion(ex.criteria.first);
    final zone = ex.spotlightZone;
    if (zone != null) return _friendlyZone(zone);
    return null;
  }

  /// PROVISIONAL (signed:false, D-03). The calm resting line — a teacher waiting
  /// beside the child, never a score / streak / prompt to hurry.
  static const String _restingLine =
      "I'm watching your strokes. Take your time — I'll show you what to fix.";

  /// A child-friendly name for a micro-drill spotlight zone (18-02 labels).
  String _friendlyZone(String zone) => switch (zone) {
        'dot' => 'the dot',
        'bowl' => 'the bowl',
        'start' => 'the start',
        _ => 'this part',
      };

  /// The criterion the child ACTUALLY missed — the first criterion the scorer
  /// marked `certainlyWrong`. Returns null when NOTHING is certainly wrong (a
  /// clean pass, or a merely-`fuzzy` soft-band criterion under the provisional
  /// uncalibrated bands): the WHY then shows a pass-appropriate line rather than
  /// skewing to a fixed 'shape' fallback (18-16 — the "feels static, always the
  /// deeper-bowl line" fix). Only a genuine miss names a "Working on" part.
  String? _targetedCriterion(TutorInsight insight) {
    final criteria = insight.criteria;
    if (criteria == null || criteria.isEmpty) return null;
    for (final c in criteria) {
      final zone = c['zone'];
      final name = c['criterion'];
      if (name is String && zone == 'certainlyWrong') return name;
    }
    return null; // no genuine miss → a clean pass (no skew to 'shape').
  }

  /// A child-friendly name for a scorer criterion (the part being worked on).
  String _friendlyCriterion(String criterion) => switch (criterion) {
        'dot' => 'the dot',
        'shape' => 'the bowl',
        'strokeOrder' => 'the start',
        'strokeCount' => 'the strokes',
        'direction' => 'the sweep',
        _ => 'this part',
      };

  /// PROVISIONAL (signed:false, mother-signed at 18-11, D-03). The warm
  /// pass-appropriate WHY line shown on a CLEAN PASS with no coach rationale
  /// (18-16) — so the WHY is not the criterion-skewed static 'deeper bowl' after
  /// every correct attempt. Names what the child did well; never over-praises
  /// (a clean pass earns it) and never a score/streak.
  static const String _passWhy =
      "That's a steady baa — smooth and sure. Lovely writing.";

  /// PROVISIONAL (signed:false, mother-signed at 18-11, D-03). The authored WHY
  /// line keyed by the criterion the child GENUINELY missed — the last-resort
  /// OFFLINE floor the panel shows when the coach `rationale` is absent AND a
  /// criterion is `certainlyWrong` (D-10). Warm, names the exact fix, never fake
  /// cheer. Not the majority path (a clean pass shows [_passWhy] instead).
  String _authoredWhy(String? criterion) => switch (criterion) {
        'dot' =>
          "baa's dot lives just below the bowl — let's set it right under the middle.",
        'shape' =>
          'Your baa wants a deeper bowl — a low, smooth scoop before you lift.',
        'strokeOrder' =>
          "Start on the right, then sweep across — that is baa's path.",
        'strokeCount' =>
          'Baa is one smooth bowl and one small dot — just those two.',
        'direction' =>
          'Sweep from the start across, not backwards — slow and steady.',
        _ => "Let's look at this part together — nice and slow.",
      };

  /// PROVISIONAL (signed:false, D-03). The named step-down narration — present
  /// only during a GENUINE remediation arc, driven by the REAL policy
  /// `insight.arcStep` (`entry`/`stepDown`), NOT a micro-drill pick (the drills
  /// are parked out of the live graph — the step-down is a floor-trace detour,
  /// D-03). "Let's practice just the dot for a moment — then we'll come back"
  /// (the D-03 register, sketch 001: a detour that comes right back, never a step
  /// BACK, never framed as failure).
  String? _arcStepDownLine(TutorInsight insight) {
    final step = insight.arcStep;
    if (step != 'entry' && step != 'stepDown') return null;
    final criterion = _arcTargetCriterion(insight);
    final part = criterion != null ? _friendlyCriterion(criterion) : 'this part';
    return "Let's practice just $part for a moment — then we'll come back.";
  }

  /// The arc's TARGET criterion — read from the policy `whyFacts`
  /// (`criterion:<name>`) so the step-down names the part the arc is rebuilding
  /// even when the current drill's criteria read clean, falling back to the
  /// verdict-time targeted criterion.
  String? _arcTargetCriterion(TutorInsight insight) {
    for (final f in insight.whyFacts ?? const <String>[]) {
      if (f.startsWith('criterion:')) return f.substring('criterion:'.length);
    }
    return _targetedCriterion(insight);
  }
}
