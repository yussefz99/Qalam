// Parent-area PIN gate — Phase 9 (S1-11, Plan 09-03).
//
// The access boundary for /parent. On mount it reads PinService.isPinSet:
//   * NOT set  → CREATE flow: enter a 4-digit PIN, then confirm it; show the
//     honest no-recovery line; on a confirmed match, setPin() + parentGate.unlock().
//   * set      → ENTER flow: a persisted-cooldown check first (if locked, disable
//     input + a calm live countdown, never red); an obscured numeric field; on a
//     wrong PIN, a soft warnSoft message + one gentle wiggle; on a correct PIN,
//     registerSuccess() + parentGate.unlock().
//
// SECURITY / no-log convention (09-PATTERNS):
//   * The PIN controller value is NEVER printed / debugPrinted / logged.
//   * The field is obscured + numeric, no autofill/suggestions/autocorrect
//     (T-09-04 shoulder-surf / on-screen leak mitigation).
//   * "Incorrect PIN" is generic — no per-digit oracle (T-09-06).
//
// This widget renders the PIN flow ONLY. When parentGate.unlocked is true the
// parent dashboard renders instead — that switch lives in ParentDashboardScreen
// (the /parent route widget), which delegates here while locked.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/parent_providers.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import 'pin_service.dart';

/// Which step of the gate the parent is on.
enum _GateMode { loading, create, confirm, enter }

class ParentPinGate extends ConsumerStatefulWidget {
  const ParentPinGate({super.key});

  @override
  ConsumerState<ParentPinGate> createState() => _ParentPinGateState();
}

class _ParentPinGateState extends ConsumerState<ParentPinGate>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  _GateMode _mode = _GateMode.loading;

  /// The first-entry value held while the CREATE flow awaits its confirmation.
  String _firstEntry = '';

  /// Soft inline error (warnSoft) — wrong PIN / mismatch. Never red.
  String? _error;

  /// Remaining cooldown seconds (>0 disables input). Ticked once per second.
  int _cooldownSeconds = 0;

  /// One-shot gentle wiggle on a wrong PIN (≤8px), skipped under reduced motion.
  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: QalamMotion.durFast,
  );

  @override
  void initState() {
    super.initState();
    _resolveInitialMode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _wiggle.dispose();
    super.dispose();
  }

  AppDatabase get _db => ref.read(appDatabaseProvider);
  PinService get _pin => ref.read(pinServiceProvider);

  Future<void> _resolveInitialMode() async {
    final isSet = await _pin.isPinSet(_db);
    if (!mounted) return;
    if (isSet) {
      await _refreshCooldown();
      if (!mounted) return;
      setState(() => _mode = _GateMode.enter);
    } else {
      setState(() => _mode = _GateMode.create);
    }
  }

  Future<void> _refreshCooldown() async {
    final remaining = await _pin.remainingCooldown(_db);
    if (!mounted) return;
    setState(() => _cooldownSeconds = remaining?.inSeconds ?? 0);
    if (_cooldownSeconds > 0) {
      _tickCooldown();
    }
  }

  void _tickCooldown() {
    Future<void>.delayed(const Duration(seconds: 1), () async {
      if (!mounted || _cooldownSeconds <= 0) return;
      // Re-read the persisted lockUntil so the countdown reflects the source of
      // truth (survives a force-quit; never an in-memory timer alone).
      await _refreshCooldown();
    });
  }

  void _clearField() {
    _controller.clear();
  }

  void _wiggleOnce() {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return;
    _wiggle.forward(from: 0).then((_) => _wiggle.reverse());
  }

  Future<void> _submit() async {
    final value = _controller.text;
    if (value.length != 4) return;

    switch (_mode) {
      case _GateMode.create:
        setState(() {
          _firstEntry = value;
          _error = null;
          _mode = _GateMode.confirm;
        });
        _clearField();
        _focus.requestFocus();
        break;

      case _GateMode.confirm:
        if (value == _firstEntry) {
          await _pin.setPin(_db, value);
          if (!mounted) return;
          ref.read(parentGateProvider).unlock();
        } else {
          final l10n = AppLocalizations.of(context)!;
          setState(() {
            _error = l10n.parentPinMismatch;
            _firstEntry = '';
            _mode = _GateMode.create;
          });
          _clearField();
          _wiggleOnce();
          _focus.requestFocus();
        }
        break;

      case _GateMode.enter:
        if (_cooldownSeconds > 0) return;
        final ok = await _pin.verify(_db, value);
        if (!mounted) return;
        if (ok) {
          await _pin.registerSuccess(_db);
          if (!mounted) return;
          ref.read(parentGateProvider).unlock();
        } else {
          await _pin.registerFailure(_db);
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          setState(() => _error = l10n.parentPinWrong);
          _clearField();
          _wiggleOnce();
          await _refreshCooldown();
          if (!mounted) return;
          _focus.requestFocus();
        }
        break;

      case _GateMode.loading:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: QalamColors.bg,
      appBar: AppBar(
        backgroundColor: QalamColors.bg,
        elevation: 0,
        title: Text(l10n.parentTitle, style: QalamTextStyles.heading),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(QalamSpace.space8),
              child: _buildBody(l10n),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_mode == _GateMode.loading) {
      // No spinner — a calm blank while isPinSet resolves (a few ms).
      return const SizedBox(height: QalamSpace.space8);
    }

    final bool locked = _mode == _GateMode.enter && _cooldownSeconds > 0;

    final String prompt;
    final String? help;
    switch (_mode) {
      case _GateMode.create:
        prompt = l10n.parentPinCreatePrompt;
        help = l10n.parentPinCreateHelp;
        break;
      case _GateMode.confirm:
        prompt = l10n.parentPinConfirmPrompt;
        help = null;
        break;
      case _GateMode.enter:
      case _GateMode.loading:
        prompt = l10n.parentPinEnterPrompt;
        help = null;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(prompt, style: QalamTextStyles.heading),
        if (help != null) ...<Widget>[
          const SizedBox(height: QalamSpace.space4),
          Text(help, style: QalamTextStyles.body),
        ],
        const SizedBox(height: QalamSpace.space6),
        AnimatedBuilder(
          animation: _wiggle,
          builder: (context, child) {
            final dx = (_wiggle.value) * 8.0;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: _PinField(
            controller: _controller,
            focusNode: _focus,
            enabled: !locked,
            onSubmitted: (_) => _submit(),
          ),
        ),
        if (_error != null && !locked) ...<Widget>[
          const SizedBox(height: QalamSpace.space3),
          Text(
            _error!,
            style: QalamTextStyles.body.copyWith(color: QalamColors.warnSoft),
          ),
        ],
        if (locked) ...<Widget>[
          const SizedBox(height: QalamSpace.space3),
          Text(
            l10n.parentPinCooldown(_cooldownSeconds),
            style: QalamTextStyles.body.copyWith(color: QalamColors.fgMuted),
          ),
        ],
        if (_mode == _GateMode.create || _mode == _GateMode.confirm) ...<Widget>[
          const SizedBox(height: QalamSpace.space5),
          Text(
            l10n.parentPinNoRecovery,
            style: QalamTextStyles.label.copyWith(color: QalamColors.fgMuted),
          ),
        ],
        const SizedBox(height: QalamSpace.space6),
        _SubmitButton(
          label: _mode == _GateMode.confirm
              ? l10n.parentPinConfirm
              : l10n.commonContinue,
          enabled: !locked,
          onTap: _submit,
        ),
      ],
    );
  }
}

/// The obscured numeric 4-digit PIN field. No autofill/suggestions/autocorrect;
/// the controller value is never logged.
class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: true,
      obscureText: true,
      keyboardType: TextInputType.number,
      enableSuggestions: false,
      autocorrect: false,
      maxLength: 4,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      onSubmitted: onSubmitted,
      style: QalamTextStyles.heading,
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: QalamColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QalamRadii.lg),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// A calm primary button reused for Continue / Confirm.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: QalamTargets.targetComfy,
      child: TextButton(
        onPressed: enabled ? onTap : null,
        style: TextButton.styleFrom(
          backgroundColor: QalamColors.primary,
          foregroundColor: QalamColors.fgOnPrimary,
          disabledBackgroundColor: QalamColors.border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QalamRadii.lg),
          ),
        ),
        child: Text(label, style: QalamTextStyles.button),
      ),
    );
  }
}
