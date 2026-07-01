// ParentAuthScreen — the app-wide sign in / sign up entry page.
// (owner-approved 2026-06-22; promoted from the 260622-pas dev spike).
//
// A real parent-owned account is required before child setup or any app content.
// The boot anonymous identity remains internal and never unlocks the router.
//
// All Firebase work lives in AuthService (never inline) and is reached via
// authServiceProvider; the live auth state comes from authStateProvider.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../services/auth_service.dart';
import '../theme/brand_theme_ext.dart';
import '../theme/colors.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';

enum _AuthMode { signIn, signUp }

class ParentAuthScreen extends ConsumerStatefulWidget {
  const ParentAuthScreen({super.key});

  @override
  ConsumerState<ParentAuthScreen> createState() => _ParentAuthScreenState();
}

class _ParentAuthScreenState extends ConsumerState<ParentAuthScreen> {
  _AuthMode _mode = _AuthMode.signIn;
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;
  String? _notice;

  bool get _isSignIn => _mode == _AuthMode.signIn;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _error = null;
      _notice = null;
    });
  }

  /// Local validation before any network call — returns an error string or null.
  String? _validate() {
    final email = _email.text.trim();
    if (email.isEmpty) return 'Enter your email.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'That email doesn\'t look right.';
    }
    if (_password.text.length < 6) {
      return 'Password needs at least 6 characters.';
    }
    if (!_isSignIn && _confirm.text != _password.text) {
      return 'Passwords don\'t match.';
    }
    return null;
  }

  Future<void> _submitEmail() async {
    if (_submitting) return;
    final localError = _validate();
    if (localError != null) {
      setState(() => _error = localError);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _notice = null;
    });
    // Resolve both providers BEFORE the await: a successful sign-up makes the
    // router redirect off /auth, which can unmount this screen — reading `ref`
    // after the await would then throw. The OnboardingGate is a keepAlive object
    // valid regardless of this widget's mount state.
    final auth = ref.read(authServiceProvider);
    final onboardingGate = ref.read(onboardingGateProvider);
    try {
      if (_isSignIn) {
        await auth.signInWithEmail(_email.text, _password.text);
      } else {
        await auth.signUpWithEmail(_email.text, _password.text);
        // Account creation always leads to a fresh child setup. This also
        // prevents an old device-local profile from bypassing onboarding.
        onboardingGate.requireProfileSetup();
      }
      // Success: authStateProvider emits the new user and the view flips to the
      // signed-in card. Nothing else to do here.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (mounted) {
        setState(() {
          _error = null;
          _notice = 'Password reset email sent. Check your inbox.';
        });
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _googleSignIn() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Google sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _submitting = true);
    try {
      await ref.read(authServiceProvider).signOut();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qalam = Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;
    // A real (non-anonymous) parent account toggles the whole screen to the
    // signed-in card; the anonymous boot identity still shows the form.
    final User? user = ref.watch(authStateProvider).asData?.value;
    final bool signedIn = user != null && !user.isAnonymous;

    return Scaffold(
      key: const Key('parentAuthScreen'),
      backgroundColor: QalamColors.bg,
      appBar: AppBar(
        backgroundColor: QalamColors.bg,
        elevation: 0,
        foregroundColor: QalamColors.fg,
        automaticallyImplyLeading: false,
        title: Text('Qalam account', style: QalamTextStyles.heading),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space8,
              vertical: QalamSpace.space6,
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
                  child: signedIn
                      ? _SignedInCard(
                          email: user.email ?? 'your account',
                          busy: _submitting,
                          buttonShadow: qalam.buttonShadow,
                          onSignOut: _signOut,
                        )
                      : _buildForm(qalam),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(QalamTheme qalam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          _isSignIn ? 'Welcome back' : 'Create your account',
          style: QalamTextStyles.heading,
        ),
        const SizedBox(height: QalamSpace.space2),
        Text(
          _isSignIn
              ? 'Sign in to continue learning.'
              : 'Create an account, then set up your child\'s learning profile.',
          style: QalamTextStyles.body,
        ),
        const SizedBox(height: QalamSpace.space6),

        _ModeToggle(mode: _mode, onChanged: _switchMode),
        const SizedBox(height: QalamSpace.space6),

        _LabeledField(
          label: 'Email',
          fieldKey: const Key('authEmailField'),
          controller: _email,
          hintText: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        if (_isSignIn)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('authForgotPassword'),
              onPressed: _submitting ? null : _forgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
        const SizedBox(height: QalamSpace.space4),
        _LabeledField(
          label: 'Password',
          fieldKey: const Key('authPasswordField'),
          controller: _password,
          hintText: '••••••••',
          obscureText: true,
        ),
        if (!_isSignIn) ...<Widget>[
          const SizedBox(height: QalamSpace.space4),
          _LabeledField(
            label: 'Confirm password',
            fieldKey: const Key('authConfirmField'),
            controller: _confirm,
            hintText: '••••••••',
            obscureText: true,
          ),
        ],

        // Inline error (parent-friendly; raw Firebase codes never reach here).
        if (_error != null) ...<Widget>[
          const SizedBox(height: QalamSpace.space4),
          _ErrorBanner(message: _error!),
        ],
        if (_notice != null) ...<Widget>[
          const SizedBox(height: QalamSpace.space4),
          Text(
            _notice!,
            key: const Key('authNotice'),
            style: QalamTextStyles.body.copyWith(color: QalamColors.success),
          ),
        ],
        const SizedBox(height: QalamSpace.space6),

        _PrimaryCta(
          label: _isSignIn ? 'Sign in' : 'Create account',
          busy: _submitting,
          buttonShadow: qalam.buttonShadow,
          onTap: _submitEmail,
        ),
        const SizedBox(height: QalamSpace.space5),

        const _OrDivider(),
        const SizedBox(height: QalamSpace.space5),

        _GoogleButton(enabled: !_submitting, onTap: _googleSignIn),
        const SizedBox(height: QalamSpace.space6),

        Text(
          'Parent accounts are for grown-ups. Children never sign in.',
          style: QalamTextStyles.label.copyWith(
            color: QalamColors.fgMuted,
            fontSize: QalamFontSizes.fz12,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Shown once a real parent account is signed in.
class _SignedInCard extends StatelessWidget {
  const _SignedInCard({
    required this.email,
    required this.busy,
    required this.buttonShadow,
    required this.onSignOut,
  });

  final String email;
  final bool busy;
  final List<BoxShadow> buttonShadow;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('You\'re signed in', style: QalamTextStyles.heading),
        const SizedBox(height: QalamSpace.space2),
        Text(email, style: QalamTextStyles.body),
        const SizedBox(height: QalamSpace.space8),
        _PrimaryCta(
          label: 'Sign out',
          busy: busy,
          buttonShadow: buttonShadow,
          onTap: onSignOut,
          ctaKey: const Key('authSignOut'),
        ),
      ],
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
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
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
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autocorrect: false,
          enableSuggestions: false,
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

/// Parent-friendly inline error banner.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('authError'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: QalamSpace.space4,
        vertical: QalamSpace.space3,
      ),
      decoration: BoxDecoration(
        color: QalamColors.warnSoftTint,
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        border: Border.all(color: QalamColors.border),
      ),
      child: Text(
        message,
        style: QalamTextStyles.body.copyWith(color: QalamColors.fg),
      ),
    );
  }
}

/// The teal primary CTA pill — shows a spinner while [busy].
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.busy,
    required this.buttonShadow,
    required this.onTap,
    this.ctaKey = const Key('authPrimaryCta'),
  });

  final String label;
  final bool busy;
  final List<BoxShadow> buttonShadow;
  final VoidCallback onTap;
  final Key ctaKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ctaKey,
      onTap: busy ? null : onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: QalamColors.primary,
          borderRadius: BorderRadius.circular(QalamRadii.pill),
          boxShadow: busy ? null : buttonShadow,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: QalamTargets.targetMin),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: QalamSpace.space6,
                    height: QalamSpace.space6,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        QalamColors.fgOnPrimary,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: QalamSpace.space4,
                    ),
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

/// Outlined "Continue with Google" — a plain "G" badge stands in for the mark.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('authGoogleButton'),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
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
      ),
    );
  }
}
