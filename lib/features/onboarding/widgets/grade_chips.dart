// Grade chip selector (Plan 05-03) — the PARENT's pick of the curriculum entry
// point (S1-02). Five fixed chips: KG, Grade 1-3, Grade 4+. Single-select, taps
// only — NO free-text (S1-03). Each chip carries a stable Key (`grade_<key>`) so
// the widget test can tap it.
//
// Mirrors the home_screen tap-cell idiom: GestureDetector → DecoratedBox with a
// QalamColors.surface default / QalamColors.primary selected state. Tap targets
// honor QalamTargets.targetMin (kids-UX floor).

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';
import '../../../theme/text_styles.dart';

/// The five fixed grade options. The key is the value stored on the profile
/// (kg|grade1|grade2|grade3|grade4plus); the label is resolved via l10n. These
/// keys are the single source for the grade tap contract + the grade→lesson map.
const List<String> kGradeKeys = <String>[
  'kg',
  'grade1',
  'grade2',
  'grade3',
  'grade4plus',
];

class GradeChips extends StatelessWidget {
  const GradeChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// The currently-selected grade key, or null if none chosen yet.
  final String? selected;

  /// Called with the tapped grade key.
  final ValueChanged<String> onSelected;

  String _labelFor(AppLocalizations? l10n, String key) {
    switch (key) {
      case 'kg':
        return l10n?.onboardingGradeKg ?? 'KG';
      case 'grade1':
        return l10n?.onboardingGrade1 ?? 'Grade 1';
      case 'grade2':
        return l10n?.onboardingGrade2 ?? 'Grade 2';
      case 'grade3':
        return l10n?.onboardingGrade3 ?? 'Grade 3';
      case 'grade4plus':
        return l10n?.onboardingGrade4plus ?? 'Grade 4+';
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: QalamSpace.space4,
      runSpacing: QalamSpace.space4,
      children: <Widget>[
        for (final key in kGradeKeys)
          _GradeChip(
            key: Key('grade_$key'),
            label: _labelFor(l10n, key),
            isSelected: selected == key,
            onTap: () => onSelected(key),
          ),
      ],
    );
  }
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: QalamTargets.targetMin),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? QalamColors.primary : QalamColors.surface,
            borderRadius: BorderRadius.circular(QalamRadii.pill),
            border: Border.all(
              color: isSelected ? QalamColors.primary : QalamColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space6,
              vertical: QalamSpace.space4,
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: QalamTextStyles.label.copyWith(
                  color: isSelected
                      ? QalamColors.fgOnPrimary
                      : QalamColors.fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
