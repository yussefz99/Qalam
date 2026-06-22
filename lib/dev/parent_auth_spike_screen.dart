// ParentAuthSpikeScreen — v2 PROTOTYPE (NOT production). Dev seam only.
//
// A parent-account sign-in / sign-up SCREEN, built UI-only so the owner can see
// and react to the shape of a real parent login BEFORE any v1 decision changes.
//
// WHY THIS IS SAFE TO HAVE IN THE TREE:
//   * v1 runtime stays ANONYMOUS-ONLY and account-free (Decided D-09b). This
//     screen does NOT import firebase_auth or AuthService, does NOT call
//     linkToPermanent (the D-09c account-linking seam), does NOT touch the
//     parent gate, and stores/reads NO data. Every CTA is inert — it only shows
//     a "not wired yet (v2)" SnackBar.
//   * Reachable ONLY by typing the hidden dev route /dev/parent-auth (like the
//     other /dev/* seams); it is never surfaced in the child- or parent-facing
//     nav.
//   * Free-text fields are fine here: the no-free-text guardrail (S1-03) exists
//     to stop a CHILD leaking a real name during onboarding. A PARENT typing
//     their own email/password is a different context entirely.
//
// Turning this into a real feature = wiring AuthService.linkToPermanent +
// Firestore rules + a child-data review, and needs the owner's sign-off. That is
// a deliberately separate follow-up — do NOT wire it from here without that gate.

import 'package:flutter/material.dart';

import '../theme/brand_theme_ext.dart';
import '../theme/colors.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';

/// The two modes the single screen toggles between.
enum _AuthMode { signIn, signUp }

class ParentAuthSpikeScreen extends StatefulWidget {
  const ParentAuthSpikeScreen({super.key});

  @override
  State<ParentAuthSpikeScreen> createState() => _ParentAuthSpikeScreenState();
}

class _ParentAuthSpikeScreenState extends State<ParentAuthSpikeScreen> {
  _AuthMode _mode = _AuthMode.signIn;

  bool get _isSignIn => _mode == _AuthMode.signIn;

  /// Every action in this prototype is inert: it only surfaces that the real
  /// auth is a deferred v2 step. No network, no Firebase, no persistence.
  void _notWired(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Not wired yet — parent accounts land in v2.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final qalam = Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;

    return Scaffold(
      key: const Key('parentAuthScreen'),
      backgroundColor: QalamColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space8,
              vertical: QalamSpace.space8,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: QalamColors.surface,
                  borderRadius: BorderRadius.circular(QalamRadii.xl),
                  border: Border.all(color: QalamColors.border),
                  boxShadow: QalamShadows.shadowMd,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(QalamSpace.space8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // v2 prototype banner — honest about what this is.
                      const _PrototypeBanner(),
                      const SizedBox(height: QalamSpace.space6),

                      Text(
                        _isSignIn
                            ? 'Welcome back'
                            : 'Create your parent account',
                        style: QalamTextStyles.heading,
                      ),
                      const SizedBox(height: QalamSpace.space2),
                      Text(
                        _isSignIn
                            ? 'Sign in to see your child\'s progress.'
                            : 'Set up a parent account to follow along.',
                        style: QalamTextStyles.body,
                      ),
                      const SizedBox(height: QalamSpace.space6),

                      // Sign in <-> Sign up segmented toggle.
                      _ModeToggle(
                        mode: _mode,
                        onChanged: (m) => setState(() => _mode = m),
                      ),
                      const SizedBox(height: QalamSpace.space6),

                      _LabeledField(
                        label: 'Email',
                        fieldKey: const Key('authEmailField'),
                        hintText: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: QalamSpace.space4),
                      _LabeledField(
                        label: 'Password',
                        fieldKey: const Key('authPasswordField'),
                        hintText: '••••••••',
                        obscureText: true,
                      ),
                      // Sign-up adds a confirm step.
                      if (!_isSignIn) ...<Widget>[
                        const SizedBox(height: QalamSpace.space4),
                        _LabeledField(
                          label: 'Confirm password',
                          fieldKey: const Key('authConfirmField'),
                          hintText: '••••••••',
                          obscureText: true,
                        ),
                      ],
                      const SizedBox(height: QalamSpace.space6),

                      // Primary CTA (teal pill — onboarding "Let's go" idiom).
                      _PrimaryCta(
                        label: _isSignIn ? 'Sign in' : 'Create account',
                        buttonShadow: qalam.buttonShadow,
                        onTap: () => _notWired(context),
                      ),
                      const SizedBox(height: QalamSpace.space5),

                      const _OrDivider(),
                      const SizedBox(height: QalamSpace.space5),

                      // Outlined "Continue with Google" (visual only — no
                      // google_sign_in dependency, no real provider call).
                      _GoogleButton(onTap: () => _notWired(context)),
                      const SizedBox(height: QalamSpace.space6),

                      // Footer micro-note — the standing v2 / child-data caveat.
                      Text(
                        'v2 prototype · not wired to Firebase · no child data. '
                        'Real account-linking is pending owner sign-off (D-09c).',
                        style: QalamTextStyles.label.copyWith(
                          color: QalamColors.fgMuted,
                          fontSize: QalamFontSizes.fz12,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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

/// Small "PROTOTYPE" chip so no one mistakes this dev seam for shipping UI.
class _PrototypeBanner extends StatelessWidget {
  const _PrototypeBanner();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: QalamSpace.space3,
          vertical: QalamSpace.space1,
        ),
        decoration: BoxDecoration(
          color: QalamColors.bgDeep,
          borderRadius: BorderRadius.circular(QalamRadii.pill),
          border: Border.all(color: QalamColors.border),
        ),
        child: Text(
          'V2 PROTOTYPE',
          style: QalamTextStyles.label.copyWith(
            color: QalamColors.fgMuted,
            fontSize: QalamFontSizes.fz12,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Sign in / Sign up segmented control — selected segment is ink-teal.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(QalamSpace.space1),
      decoration: BoxDecoration(
        color: QalamColors.bgDeep,
        borderRadius: BorderRadius.circular(QalamRadii.pill),
        border: Border.all(color: QalamColors.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ModeSegment(
              segmentKey: const Key('authModeSignIn'),
              label: 'Sign in',
              selected: mode == _AuthMode.signIn,
              onTap: () => onChanged(_AuthMode.signIn),
            ),
          ),
          Expanded(
            child: _ModeSegment(
              segmentKey: const Key('authModeSignUp'),
              label: 'Sign up',
              selected: mode == _AuthMode.signUp,
              onTap: () => onChanged(_AuthMode.signUp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.segmentKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key segmentKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: segmentKey,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: QalamMotion.durFast,
        padding: const EdgeInsets.symmetric(vertical: QalamSpace.space3),
        decoration: BoxDecoration(
          color: selected ? QalamColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(QalamRadii.pill),
        ),
        child: Center(
          child: Text(
            label,
            style: QalamTextStyles.button.copyWith(
              color: selected ? QalamColors.fgOnPrimary : QalamColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled text field styled to the kit (parchment fill, aqua border).
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.fieldKey,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
  });

  final String label;
  final Key fieldKey;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(QalamRadii.lg),
      borderSide: const BorderSide(color: QalamColors.border),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: QalamTextStyles.label),
        const SizedBox(height: QalamSpace.space2),
        TextField(
          key: fieldKey,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: QalamTextStyles.body.copyWith(color: QalamColors.fg),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: QalamColors.bg,
            hintText: hintText,
            hintStyle: QalamTextStyles.body.copyWith(
              color: QalamColors.fgMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space4,
              vertical: QalamSpace.space4,
            ),
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: QalamColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The teal primary CTA pill (onboarding "Let's go" idiom).
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.buttonShadow,
    required this.onTap,
  });

  final String label;
  final List<BoxShadow> buttonShadow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('authPrimaryCta'),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: QalamColors.primary,
          borderRadius: BorderRadius.circular(QalamRadii.pill),
          boxShadow: buttonShadow,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: QalamTargets.targetMin),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: QalamSpace.space4),
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
    );
  }
}

/// "or" hairline divider.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider(color: QalamColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: QalamSpace.space3),
          child: Text(
            'or',
            style: QalamTextStyles.label.copyWith(color: QalamColors.fgMuted),
          ),
        ),
        const Expanded(child: Divider(color: QalamColors.border, thickness: 1)),
      ],
    );
  }
}

/// Outlined "Continue with Google" — visual only (no provider call, no asset
/// dependency: a simple round "G" badge stands in for the Google mark).
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('authGoogleButton'),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: QalamTargets.targetMin),
        decoration: BoxDecoration(
          color: QalamColors.surfaceRaised,
          borderRadius: BorderRadius.circular(QalamRadii.pill),
          border: Border.all(color: QalamColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: QalamSpace.space6,
              height: QalamSpace.space6,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: QalamColors.bg,
                shape: BoxShape.circle,
                border: Border.all(color: QalamColors.border),
              ),
              child: Text(
                'G',
                style: QalamTextStyles.button.copyWith(color: QalamColors.fg),
              ),
            ),
            const SizedBox(width: QalamSpace.space3),
            Text(
              'Continue with Google',
              style: QalamTextStyles.button.copyWith(color: QalamColors.fg),
            ),
          ],
        ),
      ),
    );
  }
}
