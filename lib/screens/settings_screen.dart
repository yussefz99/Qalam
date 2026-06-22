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
    // The dialog OWNS its nickname controller (see _EditLearnerDialog) so the
    // controller lives until the route's exit animation completes — disposing it
    // here crashed the close frame ("TextEditingController used after being
    // disposed" → the on-device `_dependents.isEmpty` assertion). It returns the
    // chosen values; the repository write happens here.
    final result = await showDialog<({String nicknameId, String avatarId})>(
      context: context,
      builder: (_) => _EditLearnerDialog(
        initialNickname: profile.nicknameId,
        initialAvatarId: profile.avatarId,
      ),
    );
    if (result == null || !mounted) return;
    await ref
        .read(childProfileRepositoryProvider)
        .update(nicknameId: result.nicknameId, avatarId: result.avatarId);
    ref.invalidate(childProfileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        // No title — the body carries the single "Settings" heading.
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
                  const SizedBox(height: QalamSpace.space6),

                  // ACCOUNT — first, per request. Email + sign out grouped.
                  const _SectionLabel('ACCOUNT'),
                  const SizedBox(height: QalamSpace.space3),
                  _AccountCard(
                    email: user?.email ?? 'Signed in account',
                    signingOut: _signingOut,
                    onSignOut: _signOut,
                  ),
                  const SizedBox(height: QalamSpace.space6),

                  // LEARNER — the child's profile (working action).
                  const _SectionLabel('LEARNER'),
                  const SizedBox(height: QalamSpace.space3),
                  _ActionRow(
                    rowKey: const Key('settingsEditLearner'),
                    icon: Icons.person_outline,
                    label: 'Edit learner profile',
                    onTap: _editLearner,
                  ),
                  const SizedBox(height: QalamSpace.space6),

                  // PARENT — routes to the real PIN-gated /parent area (P9).
                  const _SectionLabel('PARENT'),
                  const SizedBox(height: QalamSpace.space3),
                  _ActionRow(
                    rowKey: const Key('settingsParentArea'),
                    icon: Icons.lock_outline,
                    label: 'Parent Area',
                    onTap: () => context.go('/parent'),
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

/// The Edit-learner dialog. A real stateful widget so it OWNS its nickname
/// controller: Flutter disposes the State only AFTER the dialog route's exit
/// animation completes, so the controller is never used after disposal (the bug
/// that crashed the close frame). It pops the chosen (nicknameId, avatarId); the
/// caller performs the repository write.
class _EditLearnerDialog extends StatefulWidget {
  const _EditLearnerDialog({
    required this.initialNickname,
    required this.initialAvatarId,
  });

  final String initialNickname;
  final String initialAvatarId;

  @override
  State<_EditLearnerDialog> createState() => _EditLearnerDialogState();
}

class _EditLearnerDialogState extends State<_EditLearnerDialog> {
  late final TextEditingController _nickname;
  late String _avatarId;

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(text: widget.initialNickname);
    _avatarId = widget.initialAvatarId;
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _save() {
    final value = _nickname.text.trim();
    if (value.runes.length >= 2 && value.runes.length <= 16) {
      Navigator.pop(context, (nicknameId: value, avatarId: _avatarId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit learner profile'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Choose an avatar'),
            const SizedBox(height: QalamSpace.space3),
            Wrap(
              spacing: QalamSpace.space3,
              children: <Widget>[
                for (final id in kAvatarIds)
                  GestureDetector(
                    key: Key('edit_$id'),
                    onTap: () => setState(() => _avatarId = id),
                    child: Container(
                      width: QalamTargets.targetMin,
                      height: QalamTargets.targetMin,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: QalamColors.bg,
                        border: Border.all(
                          color: _avatarId == id
                              ? QalamColors.primary
                              : QalamColors.border,
                          width: _avatarId == id ? 3 : 1,
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
              controller: _nickname,
              maxLength: 16,
              decoration: const InputDecoration(labelText: 'Nickname'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('saveLearnerProfile'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// A small uppercase group heading (eyebrow), mirroring the Home card eyebrows.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: QalamTextStyles.label.copyWith(
        color: QalamColors.fgMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Account group — the signed-in email (first) with the Sign out action.
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.email,
    required this.signingOut,
    required this.onSignOut,
  });

  final String email;
  final bool signingOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(QalamSpace.space5),
      decoration: BoxDecoration(
        color: QalamColors.surface,
        borderRadius: BorderRadius.circular(QalamRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: QalamTargets.targetMin,
                height: QalamTargets.targetMin,
                decoration: const BoxDecoration(
                  color: QalamColors.bg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_circle_outlined,
                  color: QalamColors.primary,
                ),
              ),
              const SizedBox(width: QalamSpace.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      email,
                      key: const Key('settingsAccountEmail'),
                      style: QalamTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Signed in',
                      style: QalamTextStyles.label.copyWith(
                        color: QalamColors.fgMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: QalamSpace.space5),
          SizedBox(
            width: double.infinity,
            height: QalamTargets.targetMin,
            child: OutlinedButton(
              key: const Key('settingsSignOut'),
              onPressed: signingOut ? null : onSignOut,
              child: signingOut
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
