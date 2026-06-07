// JourneyScreen — placeholder scaffold (Phase 03.1, plan 01).
//
// This file will be replaced entirely by plan 03.1-02 which builds the full
// winding-path Journey Map. It exists only to give the /journey route a valid
// widget target so routing and nav-rail plumbing can be verified in Wave 1.

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

/// Placeholder Journey screen.
///
/// Renders a parchment scaffold with a centered placeholder line.
/// Will be fully replaced in plan 03.1-02.
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QalamColors.bg,
      body: Center(
        child: Text(
          'Journey — coming in plan 02',
          style: QalamTextStyles.body,
        ),
      ),
    );
  }
}
