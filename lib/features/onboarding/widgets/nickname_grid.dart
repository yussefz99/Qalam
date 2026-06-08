// Nickname grid picker (Plan 05-03) — the CHILD's pick. A fixed set of
// child-friendly Arabic nicknames from kNicknames (S1-03), each rendered with
// ArabicText for correct connected-glyph shaping (NOT a screen-level
// Directionality — Pitfall 3). Single-select, taps only — NO free-text, the
// child's display identity is a tap, never a typed name. Each cell carries a
// stable Key (`nickname_<id>`) for the widget test.

import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';
import '../../../widgets/arabic_text.dart';
import '../onboarding_data.dart';

class NicknameGrid extends StatelessWidget {
  const NicknameGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// The currently-selected nickname id, or null if none chosen yet.
  final String? selected;

  /// Called with the tapped nickname id.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: QalamSpace.space4,
      runSpacing: QalamSpace.space4,
      children: <Widget>[
        for (final option in kNicknames)
          _NicknameCell(
            key: Key('nickname_${option.id}'),
            label: option.label,
            isSelected: selected == option.id,
            onTap: () => onSelected(option.id),
          ),
      ],
    );
  }
}

class _NicknameCell extends StatelessWidget {
  const _NicknameCell({
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
        constraints: const BoxConstraints(
          minHeight: QalamTargets.targetMin,
          minWidth: QalamTargets.targetLarge,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? QalamColors.primaryTint : QalamColors.surface,
            borderRadius: BorderRadius.circular(QalamRadii.lg),
            border: Border.all(
              color: isSelected ? QalamColors.primary : QalamColors.border,
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space5,
              vertical: QalamSpace.space3,
            ),
            child: Center(
              widthFactor: 1,
              // Arabic label renders through ArabicText (its own RTL island) so
              // the connected glyphs shape correctly without a global RTL wrap.
              child: ArabicText(label),
            ),
          ),
        ),
      ),
    );
  }
}
