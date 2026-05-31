// Practice screen — PLACEHOLDER for plan 01-03 (the stylus ink spike).
//
// This plan only needs the route to exist so the router compiles and the Home
// CTA has a destination. The live ink canvas, Clear action, and confirmation
// dialog land in plan 01-03 per the UI-SPEC. No interactive behavior here yet.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.writeHere)),
      body: Padding(
        padding: const EdgeInsets.all(QalamSpace.space8),
        child: Center(
          child: Text(
            l10n.practiceEmptyBody,
            style: QalamTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
