// Avatar grid picker (Plan 05-03) — the CHILD's pick. Six fixed avatars from
// kAvatarIds (S1-03), rendered as placeholder colored circles (D-3: real
// illustrated art is a later asset swap — ID→placeholder visual maps in code,
// never in the DB). Single-select, taps only. Each cell carries a stable Key
// (`avatar_<id>`) for the widget test.

import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';
import '../../../theme/text_styles.dart';
import '../onboarding_data.dart';

class AvatarGrid extends StatelessWidget {
  const AvatarGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// The currently-selected avatar id, or null if none chosen yet.
  final String? selected;

  /// Called with the tapped avatar id.
  final ValueChanged<String> onSelected;

  /// Placeholder palette — one warm tint per avatar so the six cells are visibly
  /// distinct before real illustrated art lands (D-3). NOT QalamColors.reward.
  static const List<Color> _placeholderTints = <Color>[
    QalamColors.primaryTint,
    QalamColors.successTint,
    QalamColors.warnSoftTint,
    QalamColors.bgDeep,
    QalamColors.border,
    QalamColors.surface,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: QalamSpace.space4,
      runSpacing: QalamSpace.space4,
      children: <Widget>[
        for (var i = 0; i < kAvatarIds.length; i++)
          _AvatarCell(
            key: Key('avatar_${kAvatarIds[i]}'),
            avatarId: kAvatarIds[i],
            tint: _placeholderTints[i % _placeholderTints.length],
            isSelected: selected == kAvatarIds[i],
            onTap: () => onSelected(kAvatarIds[i]),
          ),
      ],
    );
  }
}

class _AvatarCell extends StatelessWidget {
  const _AvatarCell({
    super.key,
    required this.avatarId,
    required this.tint,
    required this.isSelected,
    required this.onTap,
  });

  final String avatarId;
  final Color tint;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // "avatar_3" → "3" as a simple placeholder glyph until real art lands.
    final initial = avatarId.split('_').last;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: QalamTargets.targetComfy,
        height: QalamTargets.targetComfy,
        decoration: BoxDecoration(
          color: tint,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? QalamColors.primary : QalamColors.border,
            width: isSelected ? 4 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: QalamTextStyles.heading.copyWith(color: QalamColors.fg),
        ),
      ),
    );
  }
}
