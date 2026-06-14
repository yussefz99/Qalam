// RED — implemented in 09-03 (ParentDashboardScreen + parentProgressProvider).
//
// Plan 09-01 (Wave 0) — the read-only dashboard contract (S1-11, T-09-04).
//
// INTENTIONALLY RED at Wave 0: references the not-yet-built
// ParentDashboardScreen and parentProgressProvider (a ParentProgress value) from
// package:qalam/providers/parent_providers.dart. A later plan (09-03) builds the
// screen + provider and turns this green. Do NOT add a lib/ stub here.
//
// Encodes the T-09-04 mitigation + the UI-SPEC dashboard contract:
//   * the summary renders "{mastered} of {total} letters mastered" matching the
//     seeded counts — asserted via the ARB-resolved string, NEVER hardcoded 28;
//   * one mastered + one in-progress letter each render a row with the correct
//     status label and clean-reps;
//   * with empty rows, the empty-state copy shows — never a spinner or error;
//   * READ-ONLY: there is NO edit / delete / reset affordance (hard constraint).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/providers/parent_providers.dart';
import 'package:qalam/screens/parent_dashboard_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildDashboard(ParentProgress progress) {
  return ProviderScope(
    overrides: [
      // WR-02: the gate now defaults to LOCKED (default-deny), so a body-only
      // dashboard test must opt in to the unlocked state explicitly. Without
      // this override the screen would render the PIN flow, not the dashboard.
      parentGateProvider.overrideWith((ref) => ParentGate(unlocked: true)),
      parentProgressProvider.overrideWith((ref) async => progress),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ParentDashboardScreen(),
    ),
  );
}

/// A seeded dashboard fixture: [mastered] mastered of [total] total, plus the
/// per-letter rows the screen renders.
ParentProgress _progress({
  required int mastered,
  required int total,
  required List<ParentLetterRow> rows,
}) =>
    ParentProgress(mastered: mastered, total: total, rows: rows);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'summary renders "{mastered} of {total} letters mastered" matching the '
      'seeded counts (denominator NOT hardcoded, T-09-04)', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.pumpWidget(_buildDashboard(_progress(
      mastered: 3,
      total: 28,
      rows: const [
        ParentLetterRow(
          letterId: 'alif',
          displayName: 'alif',
          mastered: true,
          cleanReps: 3,
          masteredAtLabel: 'Jun 1',
        ),
      ],
    )));
    await tester.pumpAndSettle();

    expect(find.text(l10n.parentSummary(3, 28)), findsOneWidget,
        reason: 'the summary must reflect the seeded mastered/total counts');
  });

  testWidgets(
      'one mastered + one in-progress row each render their status label and '
      'clean-reps', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.pumpWidget(_buildDashboard(_progress(
      mastered: 1,
      total: 28,
      rows: const [
        ParentLetterRow(
          letterId: 'alif',
          displayName: 'alif',
          mastered: true,
          cleanReps: 3,
          masteredAtLabel: 'Jun 1',
        ),
        ParentLetterRow(
          letterId: 'baa',
          displayName: 'baa',
          mastered: false,
          cleanReps: 2,
          masteredAtLabel: null,
        ),
      ],
    )));
    await tester.pumpAndSettle();

    expect(find.text(l10n.parentRowMastered(3, 'Jun 1')), findsOneWidget,
        reason: 'the mastered row shows "Mastered · N clean reps · date"');
    expect(find.text(l10n.parentRowInProgress(2)), findsOneWidget,
        reason: 'the in-progress row shows "In progress · N clean reps"');
  });

  testWidgets(
      'empty rows render the calm empty-state copy, never a spinner or error '
      '(D-04)', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.pumpWidget(_buildDashboard(_progress(
      mastered: 0,
      total: 28,
      rows: const [],
    )));
    await tester.pumpAndSettle();

    expect(find.text(l10n.parentEmptyTitle), findsOneWidget,
        reason: 'an empty dashboard shows the calm empty-state title');
    expect(find.text(l10n.parentEmptyBody), findsOneWidget,
        reason: 'an empty dashboard shows the empty-state body');
    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'the empty state is never a spinner (D-04)');
  });

  testWidgets(
      'READ-ONLY: there is NO edit / delete / reset affordance (hard '
      'constraint, T-09-04)', (tester) async {
    await tester.pumpWidget(_buildDashboard(_progress(
      mastered: 1,
      total: 28,
      rows: const [
        ParentLetterRow(
          letterId: 'alif',
          displayName: 'alif',
          mastered: true,
          cleanReps: 3,
          masteredAtLabel: 'Jun 1',
        ),
      ],
    )));
    await tester.pumpAndSettle();

    // No destructive icon buttons.
    for (final icon in [Icons.delete, Icons.edit, Icons.restore, Icons.clear]) {
      expect(find.byIcon(icon), findsNothing,
          reason: 'the dashboard is read-only — no $icon affordance');
    }

    // No text control matching delete/edit/reset semantics (case-insensitive).
    final forbidden = RegExp(r'delete|edit|reset|remove|clear', caseSensitive: false);
    final labels = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((s) => forbidden.hasMatch(s));
    expect(labels, isEmpty,
        reason: 'no edit/delete/reset text affordance may appear (read-only)');
  });
}
