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

import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
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
