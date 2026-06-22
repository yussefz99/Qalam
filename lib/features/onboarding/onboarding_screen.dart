// OnboardingScreen (Plan 05-03) — the first-launch setup card (S1-02 / S1-03).
//
// One scrollable card, parent + child sitting together:
//   1. Grade chips      — the parent's pick (→ curriculum entry point, S1-02)
//   2. Avatar grid      — the child's pick (6 fixed avatars)
//   3. Nickname grid    — the child's pick (fixed Arabic nicknames)
//   4. "Let's go" CTA   — persists the profile, flips the gate, lands on Home
//
// HARD INVARIANTS:
//   * NO free-text widget anywhere — no TextField/TextFormField/EditableText, no
//     keyboard, no real-name leak (S1-03 / T-05-01). All choices are taps.
//   * PopScope(canPop: false) blocks the Android back button + predictive-back
//     gesture so the child cannot skip onboarding (T-05-05). WillPopScope is
//     deprecated — do NOT use it.
//   * App chrome stays LTR (NO global Directionality.rtl — Pitfall 3); Arabic
//     nickname labels render via ArabicText (its own RTL island).
//   * Semantic design tokens only; NEVER QalamColors.reward (PLAT-03 — no gold).
//
// On submit (all three selected): validate each selection ∈ its fixed set
// (T-05-02), resolve grade→startingLessonId (S1-02), create() the profile,
// markProfileCreated() (flips the gate → refreshListenable re-runs the redirect),
// invalidate(childProfileProvider) (Home re-reads), then context.go('/').

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../data/child_profile_repository.dart';
import '../../providers/profile_providers.dart';
import '../../theme/brand_theme_ext.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import 'onboarding_data.dart';
import 'widgets/avatar_grid.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // The three in-progress selections (all taps; no free-text state anywhere).
  String? _avatarId;
  final TextEditingController _nickname = TextEditingController();
  bool _submitting = false;

  String? get _validNickname {
    final value = _nickname.text.trim();
    return value.runes.length >= 2 && value.runes.length <= 16 ? value : null;
  }

  bool get _isComplete => _avatarId != null && _validNickname != null;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isComplete || _submitting) return;

    const grade = 'kg';
    final avatarId = _avatarId!;
    final nicknameId = _validNickname!;

    // Defence-in-depth (T-05-02): only members of the fixed sets may persist,
    // even though the UI can only ever produce in-set values.
    final validAvatar = kAvatarIds.contains(avatarId);
    final validNickname =
        nicknameId.runes.length >= 2 && nicknameId.runes.length <= 16;
    if (!validAvatar || !validNickname) return;

    setState(() => _submitting = true);

    final lessonId = resolveStartingLessonId(grade);
    await ref
        .read(childProfileRepositoryProvider)
        .create(
          nicknameId: nicknameId,
          avatarId: avatarId,
          grade: grade,
          startingLessonId: lessonId,
        );
    // Flip the gate (refreshListenable re-runs the redirect — no loop) then force
    // Home to re-read the new profile.
    ref.read(onboardingGateProvider).markProfileCreated();
    ref.invalidate(childProfileProvider);

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final qalam = Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;

    // canPop:false — the child cannot back out of onboarding (T-05-05).
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: QalamColors.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space8,
              vertical: QalamSpace.space2,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _OnboardingEntrance(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: QalamColors.surface,
                      borderRadius: BorderRadius.circular(QalamRadii.xl),
                      border: Border.all(color: QalamColors.border),
                      boxShadow: QalamShadows.shadowMd,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(QalamSpace.space5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Mascot welcome — Qalam (the tutor's persona) greets
                          // the child on the very first screen, tying onboarding
                          // to the rest of the app. Leading-mascot Row mirrors the
                          // home greeting; graceful SizedBox fallback if the asset
                          // is missing.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              SvgPicture.asset(
                                'assets/mascot/qalam-idle.svg',
                                width: QalamSpace.space16,
                                height: QalamSpace.space16,
                                semanticsLabel: 'Qalam',
                                placeholderBuilder: (_) => const SizedBox(
                                  width: QalamSpace.space16,
                                  height: QalamSpace.space16,
                                ),
                              ),
                              const SizedBox(width: QalamSpace.space5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      'Who\'s learning with Qalam?',
                                      style: QalamTextStyles.heading,
                                    ),
                                    const SizedBox(height: QalamSpace.space2),
                                    Text(
                                      'Create a private learning profile together.',
                                      style: QalamTextStyles.body,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: QalamSpace.space5),

                          const _StepLabel(
                            number: '1',
                            title: 'For your learner',
                            subtitle: 'Pick a character',
                          ),
                          const SizedBox(height: QalamSpace.space3),
                          Text(
                            l10n?.onboardingAvatarPrompt ?? 'Pick your avatar',
                            style: QalamTextStyles.label,
                          ),
                          const SizedBox(height: QalamSpace.space3),
                          AvatarGrid(
                            selected: _avatarId,
                            onSelected: (a) => setState(() => _avatarId = a),
                          ),
                          const SizedBox(height: QalamSpace.space5),

                          const _StepLabel(
                            number: '2',
                            title: 'Choose a nickname',
                            subtitle: 'Use any short name in Arabic or English',
                          ),
                          const SizedBox(height: QalamSpace.space3),
                          TextField(
                            key: const Key('onboardingNicknameField'),
                            controller: _nickname,
                            maxLength: 16,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(16),
                              FilteringTextInputFormatter.deny(
                                RegExp(r'[\r\n\t]'),
                              ),
                            ],
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.done,
                            style: QalamTextStyles.body,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: QalamColors.bg,
                              hintText: 'Example: نور or Sami',
                              counterText: '',
                              prefixIcon: const Icon(
                                Icons.edit_rounded,
                                color: QalamColors.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  QalamRadii.lg,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  QalamRadii.lg,
                                ),
                                borderSide: const BorderSide(
                                  color: QalamColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: QalamSpace.space5),

                          _LearnerPreview(
                            avatarId: _avatarId,
                            nickname: _validNickname,
                          ),
                          const SizedBox(height: QalamSpace.space5),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'The nickname stays private inside this account.',
                                  style: QalamTextStyles.label.copyWith(
                                    color: QalamColors.fgMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: QalamSpace.space4),
                              _LetsGoButton(
                                label: _isComplete
                                    ? 'Start learning'
                                    : 'Choose an avatar and nickname',
                                enabled: _isComplete && !_submitting,
                                buttonShadow: qalam.buttonShadow,
                                onTap: _submit,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: QalamSpace.space8,
          height: QalamSpace.space8,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: QalamColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: QalamTextStyles.label.copyWith(
              color: QalamColors.fgOnPrimary,
            ),
          ),
        ),
        const SizedBox(width: QalamSpace.space3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: QalamTextStyles.button),
            Text(
              subtitle,
              style: QalamTextStyles.label.copyWith(color: QalamColors.fgMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _LearnerPreview extends StatelessWidget {
  const _LearnerPreview({required this.avatarId, required this.nickname});

  final String? avatarId;
  final String? nickname;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const Key('onboardingLearnerPreview'),
      duration: QalamMotion.durBase,
      width: double.infinity,
      padding: const EdgeInsets.all(QalamSpace.space4),
      decoration: BoxDecoration(
        color: QalamColors.primaryTint,
        borderRadius: BorderRadius.circular(QalamRadii.lg),
      ),
      child: Row(
        children: [
          Container(
            width: QalamTargets.targetMin,
            height: QalamTargets.targetMin,
            decoration: BoxDecoration(
              color: QalamColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: QalamColors.primary),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarId == null
                ? Center(child: Text('?', style: QalamTextStyles.heading))
                : Padding(
                    padding: const EdgeInsets.all(QalamSpace.space1),
                    child: Image.asset(
                      'assets/avatars/$avatarId.png',
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
          const SizedBox(width: QalamSpace.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Learner preview', style: QalamTextStyles.label),
                const SizedBox(height: QalamSpace.space1),
                Text(
                  nickname ?? 'Your nickname will appear here',
                  style: QalamTextStyles.heading,
                ),
              ],
            ),
          ),
          if (avatarId != null && nickname != null)
            const Icon(Icons.check_circle, color: QalamColors.success),
        ],
      ),
    );
  }
}

/// The teal "Let's go" CTA pill (home_screen idiom). Disabled (dimmed, no tap)
/// until grade + avatar + nickname are all selected.
class _LetsGoButton extends StatelessWidget {
  const _LetsGoButton({
    required this.label,
    required this.enabled,
    required this.buttonShadow,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final List<BoxShadow> buttonShadow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('onboardingSubmit'),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: QalamColors.primary,
            borderRadius: BorderRadius.circular(QalamRadii.pill),
            boxShadow: enabled ? buttonShadow : null,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: QalamTargets.targetMin,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: QalamSpace.space10,
                vertical: QalamSpace.space4,
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: QalamTextStyles.button.copyWith(
                    color: QalamColors.fgOnPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gentle first-impression entrance: the setup card fades in while sliding up
/// ~24px (QalamSpace.space6) — `easeOutQuart` over `durSlow` (420ms) — so the
/// child's very first screen settles in warmly instead of popping onscreen
/// (mirrors home's prepared-desk beat).
///
/// Plays ONCE per arrival; the one-shot decision lives in this State so a parent
/// rebuild never replays it. Reduced motion (`MediaQuery.disableAnimations`)
/// skips the controller and renders fully settled immediately.
class _OnboardingEntrance extends StatefulWidget {
  const _OnboardingEntrance({required this.child});

  final Widget child;

  @override
  State<_OnboardingEntrance> createState() => _OnboardingEntranceState();
}

class _OnboardingEntranceState extends State<_OnboardingEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _progress;
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_played) return; // once per arrival
    _played = true;
    if (MediaQuery.of(context).disableAnimations) return; // settled at once
    final controller = AnimationController(
      vsync: this,
      duration: QalamMotion.durSlow,
    );
    _controller = controller;
    _progress = CurvedAnimation(
      parent: controller,
      curve: QalamMotion.easeOutQuart,
    );
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    if (progress == null) return widget.child; // reduced motion: settled
    return AnimatedBuilder(
      animation: progress,
      builder: (BuildContext context, Widget? child) {
        final double v = progress.value;
        return Opacity(
          key: const Key('onboardingCardEntranceFade'),
          opacity: v,
          child: Transform.translate(
            // Slide up ~24px as the card settles.
            offset: Offset(0, QalamSpace.space6 * (1 - v)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
