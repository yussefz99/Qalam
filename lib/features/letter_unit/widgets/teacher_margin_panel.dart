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

import '../../../models/letter.dart';
import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import 'exercise_scaffold.dart' show TutorInsight, tutorInsightProvider;

/// The child-facing Teacher's Margin panel. Renders nothing until the first
/// verdict publishes a [TutorInsight]; then it carries the WHY line and, during
/// an arc (the coach picked a micro-drill), the named step-down narration.
class TeacherMarginPanel extends ConsumerWidget {
  const TeacherMarginPanel({
    super.key,
    required this.letter,
    this.title = "Teacher's margin",
  });

  /// The letter under practice (the living-tutor arc is baa-scoped for now); kept
  /// for future per-letter WHY copy. The provisional templates below are
  /// baa-flavoured (D-03) — a newly signed letter grows its own lines at 18-11.
  final Letter letter;

  /// The small margin heading (call site passes l10n; default keeps tests
  /// independent of l10n generation).
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insight = ref.watch(tutorInsightProvider);
    if (insight == null) return const SizedBox.shrink();

    final criterion = _targetedCriterion(insight);
    // ONLINE → the coach's WHY line; OFFLINE / pre-coach → the authored template
    // keyed by the targeted criterion (D-10 degradation, same panel).
    final rationale = insight.rationale?.trim();
    final why = (rationale != null && rationale.isNotEmpty)
        ? rationale
        : _authoredWhy(criterion);
    // The arc's named step-down — present only when the coach routed the child to
    // a micro-drill (the pick), i.e. the arc's stepDown moment (D-02/D-03).
    final arcLine = _arcStepDownLine(insight.pick);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        // A pencil-note margin: parchment ground, a soft coral edge on the
        // canvas side (sketch 001 Variant C `border-right: 2px coral-tint`).
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
            Text(
              title.toUpperCase(),
              style: QalamTextStyles.label.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.05 * 10,
                color: QalamTokens.fgMuted,
              ),
            ),
            if (criterion != null) ...[
              const SizedBox(height: 6),
              // "Working on: the dot" — names the part, not a score.
              Text(
                'Working on · ${_friendlyCriterion(criterion)}',
                style: QalamTextStyles.label.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: QalamTokens.deepInk,
                ),
              ),
            ],
            const SizedBox(height: 8),
            // The WHY line — the tutor's warm register (online coach / offline
            // authored floor).
            Text(
              why,
              style: QalamTextStyles.button.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: QalamTokens.fg,
                height: 1.42,
              ),
            ),
            if (arcLine != null) ...[
              const SizedBox(height: 10),
              // The named step-down — a coral pencil note that we take a detour
              // and come right back (never a step BACK; the arc "never leaves the
              // desk", sketch 001).
              Text(
                arcLine,
                style: QalamTextStyles.button.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: QalamTokens.coral,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The criterion the arc/coach is targeting — the first criterion whose zone is
  /// NOT `certainlyCorrect` (the one the child keeps missing), else the first
  /// listed, else null (the pass case with all-correct criteria).
  String? _targetedCriterion(TutorInsight insight) {
    final criteria = insight.criteria;
    if (criteria == null || criteria.isEmpty) return null;
    for (final c in criteria) {
      final zone = c['zone'];
      final name = c['criterion'];
      if (name is String && zone != 'certainlyCorrect') return name;
    }
    final first = criteria.first['criterion'];
    return first is String ? first : null;
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

  /// PROVISIONAL (signed:false, mother-signed at 18-11, D-03). The authored WHY
  /// line keyed by the targeted criterion — the OFFLINE floor the panel shows
  /// when the coach `rationale` is absent (D-10). Warm, names the exact fix,
  /// never fake cheer.
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
  /// only when the coach routed the child to a micro-drill (`pick` names a
  /// `microDrill` node). "Let's practice just the dot for a moment — then we'll
  /// come back" (the D-03 register, sketch 001: the arc never leaves the desk).
  String? _arcStepDownLine(String? pick) {
    if (pick == null || !pick.contains('microDrill')) return null;
    final zone = pick.split('.').last;
    final part = switch (zone) {
      'dot' => 'the dot',
      'bowl' => 'the bowl',
      'start' => 'the start',
      _ => 'this part',
    };
    return "Let's practice just $part for a moment — then we'll come back.";
  }
}
