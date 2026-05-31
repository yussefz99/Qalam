// Home screen — minimal shell (Task 2). The full wiring (قلم logo, ArabicText
// sample, round-tripped DB value, Open Practice CTA) lands in Task 3 of this plan.
// This stub exists so the router and the D-05 direction test compile.
//
// Resilience: AppLocalizations may be absent under a bare test MaterialApp
// (the D-05 direction test pumps `MaterialApp(home: HomeScreen())` with no
// delegates), so copy reads are null-safe with the canonical English fallback.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final heading = l10n?.homePlaceholderHeading ?? 'Your Journey Starts Soon';
    return Scaffold(
      body: Center(
        child: Text(heading, style: QalamTextStyles.heading),
      ),
    );
  }
}
