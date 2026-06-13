// Parent dashboard — Phase 9 (S1-11, Plan 09-03).
//
// The /parent route widget AND the read-only progress view. It is the access
// boundary: while parentGate is LOCKED it renders the PIN gate (ParentPinGate);
// once UNLOCKED it renders the read-only dashboard. This single-route, switch-
// in-widget shape is RESEARCH Pattern 3 (no sub-routes, no redirect loop).
//
// Dashboard (unlocked) renders, from parentProgressProvider:
//   * a plain "N of M letters mastered" summary line (Heading) — INFORMATION,
//     never gold, never a 0-100 score (PLAT-03);
//   * a scrollable per-letter list: mastered rows carry the leaf check glyph +
//     "Mastered · N clean reps · date" in success; in-progress rows carry
//     "In progress · N clean reps" in fgMuted, no glyph, no date;
//   * the calm empty state when no letter has been touched (D-04);
//   * a "Done" control that relocks the gate (D-07) then returns to child Home.
//
// READ-ONLY hard constraint (T-09-09): NO edit/delete/reset affordance, NO
// QalamColors.reward (gold), NO mascot, NO celebration motion. The Arabic glyph
// (ArabicText) is the ONLY RTL island; all chrome stays LTR English.
//
// Provider degradation (T-09-10): loading/error degrade to the calm empty state,
// never a spinner or a raw stack trace.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/curriculum_repository.dart';
import '../features/parent/parent_pin_gate.dart';
import '../features/parent/parent_progress.dart';
import '../l10n/app_localizations.dart';
import '../models/letter.dart';
import '../providers/parent_providers.dart';
import '../theme/colors.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';
import '../widgets/arabic_text.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The access boundary: watch the gate flag and render the PIN flow until it
    // flips unlocked. A child who reaches /parent sees only the PIN gate.
    final unlocked = ref.watch(parentGateProvider.select((g) => g.unlocked));
    if (!unlocked) {
      return const ParentPinGate();
    }
    return const _ParentDashboardBody();
  }
}

class _ParentDashboardBody extends ConsumerWidget {
  const _ParentDashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progress = ref.watch(parentProgressProvider);

    return Scaffold(
      backgroundColor: QalamColors.bg,
      appBar: AppBar(
        backgroundColor: QalamColors.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(l10n.parentTitle, style: QalamTextStyles.heading),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: progress.when(
            // loading / error degrade to the calm empty state — never a spinner
            // or a raw stack trace (T-09-10 / D-04 convention).
            loading: () => _EmptyState(l10n: l10n),
            error: (_, __) => _EmptyState(l10n: l10n),
            data: (p) => _DashboardContent(l10n: l10n, progress: p),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerStatefulWidget {
  const _DashboardContent({required this.l10n, required this.progress});

  final AppLocalizations l10n;
  final ParentProgress progress;

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  // CR-01 / D-07: cache the gate while the State is alive so we can relock in
  // dispose() WITHOUT reading `ref` after it has been disposed (the Ref is
  // already torn down by the time State.dispose runs). The ParentGate is a
  // keepAlive ChangeNotifier held for the app lifetime, so this reference stays
  // valid through dispose.
  ParentGate? _gate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _gate = ref.read(parentGateProvider);
  }

  @override
  void dispose() {
    // Relock the gate whenever the dashboard unmounts — not only on "Done".
    // This catches EVERY exit path (Android system back, predictive back,
    // programmatic nav, deep-link clobber), so the gate can never be left
    // unlocked for a second entry to bypass the PIN. lock() is idempotent, so
    // the explicit lock() in _done() followed by this dispose() lock() is
    // harmless.
    _gate?.lock();
    super.dispose();
  }

  void _done(BuildContext context) {
    // D-07: relock BEFORE navigating so a second entry re-prompts the PIN.
    // (dispose() also relocks; lock() is idempotent.)
    ref.read(parentGateProvider).lock();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final progress = widget.progress;
    final letters = ref.watch(_lettersByIdProvider);

    return Padding(
      padding: const EdgeInsets.all(QalamSpace.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Summary line — plain INFORMATION, never gold, never a score.
          Text(
            l10n.parentSummary(progress.mastered, progress.total),
            style: QalamTextStyles.heading,
          ),
          const SizedBox(height: QalamSpace.space6),
          Expanded(
            child: progress.rows.isEmpty
                ? _EmptyState(l10n: l10n)
                : ListView.builder(
                    itemCount: progress.rows.length,
                    itemBuilder: (context, i) {
                      final row = progress.rows[i];
                      final letterChar = letters.maybeWhen(
                        data: (map) => map[row.letterId]?.char,
                        orElse: () => null,
                      );
                      return _LetterRow(
                        l10n: l10n,
                        row: row,
                        glyph: letterChar,
                      );
                    },
                  ),
          ),
          const SizedBox(height: QalamSpace.space5),
          SizedBox(
            width: double.infinity,
            height: QalamTargets.targetComfy,
            child: TextButton(
              onPressed: () => _done(context),
              style: TextButton.styleFrom(
                backgroundColor: QalamColors.primary,
                foregroundColor: QalamColors.fgOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(QalamRadii.lg),
                ),
              ),
              child: Text(l10n.commonDone, style: QalamTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}

/// One read-only progress row on a soft-aqua surface (reuses the settings_screen
/// _PlaceholderRow shape). No edit/delete affordance, no gold.
class _LetterRow extends StatelessWidget {
  const _LetterRow({
    required this.l10n,
    required this.row,
    required this.glyph,
  });

  final AppLocalizations l10n;
  final ParentLetterRow row;
  final String? glyph;

  @override
  Widget build(BuildContext context) {
    final String statusLine = row.mastered
        ? l10n.parentRowMastered(row.cleanReps, row.masteredAtLabel ?? '')
        : l10n.parentRowInProgress(row.cleanReps);
    final Color statusColor =
        row.mastered ? QalamColors.success : QalamColors.fgMuted;

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
      child: Row(
        children: <Widget>[
          // The ONLY RTL island — the Arabic glyph.
          if (glyph != null)
            ArabicText(
              glyph!,
              style: QalamTextStyles.heading,
            ),
          if (glyph != null) const SizedBox(width: QalamSpace.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(row.displayName, style: QalamTextStyles.body),
                const SizedBox(height: QalamSpace.space1),
                Text(
                  statusLine,
                  style: QalamTextStyles.label.copyWith(color: statusColor),
                ),
              ],
            ),
          ),
          if (row.mastered)
            SvgPicture.asset(
              'assets/icons/check-complete.svg',
              width: QalamSpace.space6,
              height: QalamSpace.space6,
              colorFilter:
                  const ColorFilter.mode(QalamColors.success, BlendMode.srcIn),
              placeholderBuilder: (_) => const SizedBox(
                width: QalamSpace.space6,
                height: QalamSpace.space6,
              ),
            ),
        ],
      ),
    );
  }
}

/// The calm empty state — never a spinner or error (D-04 / T-09-10).
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QalamSpace.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.parentEmptyTitle,
              style: QalamTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: QalamSpace.space3),
            Text(
              l10n.parentEmptyBody,
              style: QalamTextStyles.body.copyWith(color: QalamColors.fgMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A by-id curriculum letter lookup so each row can source its glyph. Resolves
/// to an empty map on any failure — a missing glyph degrades to a glyph-free row
/// (never an error surface).
final _lettersByIdProvider = FutureProvider<Map<String, Letter>>((ref) async {
  final letters = await ref.watch(curriculumRepositoryProvider).getLetters();
  return {for (final l in letters) l.id: l};
});
