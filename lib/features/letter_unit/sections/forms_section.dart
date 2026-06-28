// FormsSection — Section 3 of the baa Letter Unit (Plan 07-05).
//
// "Forms in context": the child traces baa's three IN-WORD shapes — initial,
// medial, final — then JOINS them into باب ("door"). This is the prototype's
// `context()` surface (unit.js), reproduced 1:1:
//   • a row of three `.fstep` chips (initial/medial/final); the active one is
//     teal-ringed, a completed one turns leaf-green with a ✓;
//   • selecting a chip loads its trace surface (a WriteSurface with the matching
//     guideForm) via the engine ExerciseScaffold;
//   • once all three are traced, the section advances to the join-into-باب stage
//     (its own write surface for the whole word).
//
// CONFIG-DRIVEN: each form-step and the join stage are the engine's
// ExerciseScaffold fed the relevant `baa.traceLetter.<form>` / join Exercise —
// no bespoke grading UI. The authored feedback comes from each config.
//
// GRACEFUL DEGRADE (T-07-05-02, the human sign-off gate): the per-form reference
// strokes live on `letter.contextualForms[form]`. Plan 07-07 authors the
// initial/medial/final Forms; UNTIL THEN they are null. When a selected form's
// Form is null (or has no reference strokes), the section shows a CALM "not yet
// authored" placeholder and stays navigable — it NEVER crashes and NEVER
// fabricates reference strokes (the owner's-mother sign-off gate is respected).

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exercise.dart';
import '../../../models/letter.dart';
import '../../../providers/audio_providers.dart';
import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/arabic_text.dart';
import '../widgets/exercise_scaffold.dart';

/// Static copy for the Forms section (English defaults; call site passes l10n).
class FormsSectionStrings {
  const FormsSectionStrings({
    this.kick = 'Forms in Context',
    this.initialLabel = 'Initial',
    this.medialLabel = 'Medial',
    this.finalLabel = 'Final',
    this.joinKick = 'Join Them',
    this.notYetAuthoredTitle = 'Coming soon',
    this.notYetAuthoredBody =
        'This form is still being prepared by your teacher. You can come back to it soon.',
    this.listenLabel = 'This form',
    this.listenPlay = 'Hear it',
  });

  final String kick;
  final String initialLabel;
  final String medialLabel;
  final String finalLabel;
  final String joinKick;
  final String notYetAuthoredTitle;
  final String notYetAuthoredBody;
  final String listenLabel;
  final String listenPlay;
}

/// One of the three contextual form steps.
class _Step {
  const _Step(this.form, this.label, this.glyph, this.exercise);
  final String form; // "initial" | "medial" | "final"
  final String label;
  final String glyph; // the contextual glyph for the chip + listen card
  final Exercise exercise;
}

/// Section 3 — Forms in context. Feed it the per-form trace [initial]/[medial]/
/// [finalForm] Exercises and the [join] Exercise, plus the [letter] (for the
/// per-form reference strokes + graceful degrade). [onAdvance] advances to
/// Section 4 after the join.
class FormsSection extends ConsumerStatefulWidget {
  const FormsSection({
    super.key,
    required this.initial,
    required this.medial,
    required this.finalForm,
    required this.join,
    required this.letter,
    this.onAdvance,
    this.strings = const FormsSectionStrings(),
    this.onGraphNodePassed,
  });

  final Exercise initial;
  final Exercise medial;
  final Exercise finalForm;
  final Exercise join;
  final Letter letter;
  final VoidCallback? onAdvance;
  final FormsSectionStrings strings;

  /// Called with the canonical graph node id on a clean scored pass for each
  /// form scaffold (T2/T3). Only fired for nodes in the graph:
  ///   • baa.traceLetter.initial  — initial form
  ///   • baa.traceLetter.medial   — medial form
  ///   • baa.connectWord.baab     — the join stage
  /// baa.traceLetter.final is NOT in the signed graph → null for that form.
  final void Function(String graphExerciseId)? onGraphNodePassed;

  @override
  ConsumerState<FormsSection> createState() => FormsSectionState();
}

/// Public state so the host (and the widget test) can drive completion.
class FormsSectionState extends ConsumerState<FormsSection> {
  late final List<_Step> _steps;
  final Set<String> _done = <String>{};
  int _active = 0;
  bool _joinStage = false;

  @override
  void initState() {
    super.initState();
    final s = widget.strings;
    _steps = [
      _Step('initial', s.initialLabel, _glyphFor('initial'), widget.initial),
      _Step('medial', s.medialLabel, _glyphFor('medial'), widget.medial),
      _Step('final', s.finalLabel, _glyphFor('final'), widget.finalForm),
    ];
  }

  /// The contextual glyph for the chip/listen card (baa's forms by name).
  String _glyphFor(String form) {
    final base = widget.letter.char;
    if (base == 'ب') {
      return switch (form) {
        'initial' => 'بـ',
        'medial' => 'ـبـ',
        'final' => 'ـب',
        _ => base,
      };
    }
    return base;
  }

  /// True when the named form has authored reference strokes (else a null /
  /// empty contextual Form → the un-authored, pre-07-07 state).
  bool _isAuthored(String form) {
    final f = widget.letter.contextualForms?[form];
    return f != null && f.referenceStrokes.isNotEmpty;
  }

  /// Marks a form done (and advances to the join stage once all three are done).
  /// Exposed for the host's sequencing and for widget tests.
  void debugMarkFormDone(String form) {
    setState(() {
      _done.add(form);
      if (_done.length >= _steps.length) {
        _joinStage = true;
      } else {
        final next = _steps.indexWhere((s) => !_done.contains(s.form));
        if (next >= 0) _active = next;
      }
    });
  }

  void _onFormPassed(String form) => debugMarkFormDone(form);

  void _select(int i) => setState(() => _active = i);

  void _play(String? id) {
    if (id == null || id.isEmpty) return;
    ref.read(audioPlayerProvider).playLetter(id);
  }

  @override
  Widget build(BuildContext context) {
    if (_joinStage) return _buildJoin();
    return _buildForms();
  }

  // ── the three form steps ───────────────────────────────────────────────────
  Widget _buildForms() {
    final s = widget.strings;
    final active = _steps[_active];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 18, 26, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                s.kick,
                style: QalamTextStyles.label.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.13 * 12.5,
                  color: QalamTokens.inkTeal,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // .formsteps — the three chips.
            Row(
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: FormStepChip(
                      key: ValueKey<String>('formChip:${_steps[i].form}'),
                      glyph: _steps[i].glyph,
                      label: _steps[i].label,
                      active: i == _active,
                      done: _done.contains(_steps[i].form),
                      onTap: () => _select(i),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            // the active form's surface (or the un-authored placeholder).
            Expanded(child: _activeSurface(active)),
          ],
        ),
      ),
    );
  }

  Widget _activeSurface(_Step step) {
    if (!_isAuthored(step.form)) {
      // GRACEFUL DEGRADE — never crash, never fabricate strokes.
      return _NotYetAuthored(
        key: const ValueKey('formNotYetAuthored'),
        title: widget.strings.notYetAuthoredTitle,
        body: widget.strings.notYetAuthoredBody,
        glyph: step.glyph,
      );
    }
    // The engine scaffold drives the config-through-components trace + grading,
    // including its own Clear / Next CTAs and the PromptHeader Play (the single
    // audio affordance — a separate overlaid Listen card used to cover the CTAs;
    // owner bug #4).
    // T2: map each form to its canonical graph node id. baa.traceLetter.final is
    // NOT in the signed graph (15 nodes), so that form passes null — no rep
    // recording for it. initial + medial ARE in the graph.
    final graphId = switch (step.form) {
      'initial' => step.exercise.id, // baa.traceLetter.initial
      'medial' => step.exercise.id,  // baa.traceLetter.medial
      _ => null,                     // final: not a signed graph node
    };
    return ExerciseScaffold(
      // A key per form so the scaffold/controller reset cleanly on switch.
      key: ValueKey<String>('formScaffold:${step.form}'),
      exercise: step.exercise,
      letter: widget.letter,
      kick: step.label,
      onNext: () => _onFormPassed(step.form),
      onAudioTap: _play,
      graphExerciseId: graphId,
      onGraphNodePassed: graphId != null ? widget.onGraphNodePassed : null,
    );
  }

  // ── the join-into-باب stage ────────────────────────────────────────────────
  Widget _buildJoin() {
    final s = widget.strings;
    return KeyedSubtree(
      key: const ValueKey('joinStage'),
      child: ExerciseScaffold(
        exercise: widget.join,
        letter: widget.letter,
        kick: s.joinKick,
        onNext: widget.onAdvance,
        onAudioTap: _play,
        // T2: baa.connectWord.baab IS in the signed graph (copyWrite / manqul).
        graphExerciseId: widget.join.id,
        onGraphNodePassed: widget.onGraphNodePassed,
      ),
    );
  }
}

/// `.fstep` — one contextual-form step chip (glyph + label; active/done states).
class FormStepChip extends StatelessWidget {
  const FormStepChip({
    super.key,
    required this.glyph,
    required this.label,
    required this.active,
    required this.done,
    required this.onTap,
  });

  final String glyph;
  final String label;
  final bool active;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = done
        ? QalamTokens.leaf
        : (active ? QalamTokens.inkTeal : QalamTokens.aquaEdge);
    final Color bg =
        active ? QalamTokens.tealTint : QalamTokens.surfaceRaised;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ArabicText(
                  glyph,
                  style: QalamTextStyles.arBody.copyWith(
                    fontSize: 34, // .fstep .sg
                    fontWeight: FontWeight.w500,
                    color: QalamTokens.deepInk,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (done) ...[
                      const Icon(Icons.check_rounded,
                          size: 14, color: QalamTokens.leaf),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      label.toUpperCase(),
                      style: QalamTextStyles.label.copyWith(
                        fontSize: 11, // .fstep .sl
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.06 * 11,
                        color: done
                            ? QalamTokens.leaf
                            : (active
                                ? QalamTokens.inkTeal
                                : QalamTokens.fgMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The calm "not yet authored" placeholder shown for an un-signed-off form.
/// It NEVER scores and NEVER fabricates strokes — it simply tells the child the
/// form is being prepared and keeps the section navigable (the sign-off gate).
class _NotYetAuthored extends StatelessWidget {
  const _NotYetAuthored({
    super.key,
    required this.title,
    required this.body,
    required this.glyph,
  });

  final String title;
  final String body;
  final String glyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QalamTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(QalamTokens.radiusXl),
        border: Border.all(color: QalamTokens.aquaEdge, width: 1.5),
      ),
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArabicText(
              glyph,
              style: QalamTextStyles.arDisplay.copyWith(
                fontSize: 96,
                fontWeight: FontWeight.w500,
                color: QalamTokens.inkGuide, // faint — not the ink, not gold
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: QalamTextStyles.heading.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: QalamTokens.deepInk,
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: QalamTextStyles.button.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: QalamTokens.fgMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
