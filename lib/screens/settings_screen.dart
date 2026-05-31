// Settings screen — PLACEHOLDER for plan 01-03 (parent-area shell).
//
// Route exists so the router compiles. Real placeholder rows land in plan 01-03.
//
// ROUTING SEAM: a future PIN-gated `/parent/*` branch lives here (built in P9).
// Do NOT build the PIN gate now — see the commented seam in app_router.dart.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Padding(
        padding: const EdgeInsets.all(QalamSpace.space8),
        child: Text(
          l10n.settingsPlaceholderBody,
          style: QalamTextStyles.body,
        ),
      ),
    );
  }
}
