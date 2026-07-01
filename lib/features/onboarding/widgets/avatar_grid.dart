// Avatar grid picker (Plan 05-03) — the CHILD's pick. Six fixed avatars from
// kAvatarIds (S1-03), rendered as placeholder colored circles (D-3: real
// illustrated art is a later asset swap — ID→placeholder visual maps in code,
// never in the DB). Single-select, taps only. Each cell carries a stable Key
// (`avatar_<id>`) for the widget test.

import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';
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
    required this.isSelected,
    required this.onTap,
  });

  final String avatarId;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: QalamTargets.targetComfy,
        height: QalamTargets.targetComfy,
        decoration: BoxDecoration(
          color: QalamColors.bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? QalamColors.primary : QalamColors.border,
            width: isSelected ? 4 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(QalamSpace.space1),
              child: Image.asset(
                'assets/avatars/$avatarId.png',
                fit: BoxFit.contain,
              ),
            ),
            if (isSelected)
              const Align(
                alignment: Alignment.bottomRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: QalamColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(QalamSpace.space1),
                    child: Icon(
                      Icons.check_rounded,
                      color: QalamColors.fgOnPrimary,
                      size: QalamSpace.space4,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
