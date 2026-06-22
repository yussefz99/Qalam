// SettingsScreen — the parent-area placeholder shell (plan 01-03).
//
// Phase 1 ships ONLY a parchment placeholder: the Settings heading/body plus a
// few inert placeholder rows. There is NO real settings behavior and — by design
// — NO PIN gate.
//
// ROUTING SEAM (P9): the future grown-up area lives behind a PIN-gated
// `/parent/*` branch. That branch is built in P9, NOT now. The router
// (lib/router/app_router.dart) carries the commented redirect seam; this screen
// marks where the "Parent Area" entry row will eventually route. Do NOT build
// the PIN gate, the parent routes, or any auth here.
//
// All copy via gen-l10n; semantic tokens only; no emoji, no pseudo-icons (D-13).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../data/child_profile_repository.dart';
import '../features/onboarding/onboarding_data.dart';
import '../theme/colors.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await ref.read(authServiceProvider).signOut();
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _editLearner() async {
    final profile = await ref.read(childProfileProvider.future);
    if (profile == null || !mounted) return;
    var avatarId = profile.avatarId;
    final nickname = TextEditingController(text: profile.nicknameId);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit learner profile'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose an avatar'),
                const SizedBox(height: QalamSpace.space3),
                Wrap(
                  spacing: QalamSpace.space3,
                  children: [
                    for (final id in kAvatarIds)
                      GestureDetector(
                        key: Key('edit_$id'),
                        onTap: () => setDialogState(() => avatarId = id),
                        child: Container(
                          width: QalamTargets.targetMin,
                          height: QalamTargets.targetMin,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: QalamColors.bg,
                            border: Border.all(
                              color: avatarId == id
                                  ? QalamColors.primary
                                  : QalamColors.border,
                              width: avatarId == id ? 3 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/avatars/$id.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: QalamSpace.space5),
                TextField(
                  key: const Key('editLearnerNickname'),
                  controller: nickname,
                  maxLength: 16,
                  decoration: const InputDecoration(labelText: 'Nickname'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('saveLearnerProfile'),
              onPressed: () {
                final value = nickname.text.trim();
                if (value.runes.length >= 2 && value.runes.length <= 16) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    final value = nickname.text.trim();
    nickname.dispose();
    if (saved != true) return;
    await ref
        .read(childProfileRepositoryProvider)
        .update(nicknameId: value, avatarId: avatarId);
    ref.invalidate(childProfileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          key: const Key('settingsHomeButton'),
          tooltip: 'Back to Home',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home_outlined),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(QalamSpace.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l10n.settings, style: QalamTextStyles.heading),
                  const SizedBox(height: QalamSpace.space4),
                  Text(
                    l10n.settingsPlaceholderBody,
                    style: QalamTextStyles.body,
                  ),
                  const SizedBox(height: QalamSpace.space8),

                  // Inert placeholder rows — no behavior in Phase 1.
                  const _PlaceholderRow(label: 'Sound'),
                  const _PlaceholderRow(label: 'Hand (Left / Right)'),
                  // SEAM: the "Parent Area" row will route to the PIN-gated
                  // `/parent/*` branch in P9. Left inert here on purpose — do NOT
                  // wire navigation or build the PIN gate now (see app_router.dart).
                  const _PlaceholderRow(label: 'Parent Area'),
                  _ActionRow(
                    rowKey: const Key('settingsEditLearner'),
                    icon: Icons.face_retouching_natural,
                    label: 'Edit learner profile',
                    onTap: _editLearner,
                  ),
                  const SizedBox(height: QalamSpace.space5),
                  Text(
                    user?.email ?? 'Signed in account',
                    key: const Key('settingsAccountEmail'),
                    style: QalamTextStyles.body,
                  ),
                  const SizedBox(height: QalamSpace.space3),
                  SizedBox(
                    width: double.infinity,
                    height: QalamTargets.targetMin,
                    child: OutlinedButton(
                      key: const Key('settingsSignOut'),
                      onPressed: _signingOut ? null : _signOut,
                      child: _signingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single inert settings row on a soft-aqua surface (placeholder only).
class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: QalamSpace.space3),
      constraints: const BoxConstraints(minHeight: QalamTargets.targetMin),
      padding: const EdgeInsets.symmetric(
        horizontal: QalamSpace.space5,
        vertical: QalamSpace.space4,
      ),
      decoration: BoxDecoration(
        color: QalamColors.surface, // soft-aqua
        borderRadius: BorderRadius.circular(QalamRadii.lg),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: Text(label, style: QalamTextStyles.body),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.rowKey,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Key rowKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QalamSpace.space3),
      child: ListTile(
        key: rowKey,
        onTap: onTap,
        tileColor: QalamColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QalamRadii.lg),
        ),
        leading: Icon(icon, color: QalamColors.primary),
        title: Text(label, style: QalamTextStyles.body),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
