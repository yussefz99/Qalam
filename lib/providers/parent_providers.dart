// Parent-area gate + read-only progress provider — Phase 9 (S1-11, Plan 09-03).
//
// Two pieces, mirroring profile_providers.dart:
//  1. ParentGate — a ChangeNotifier the router uses as `refreshListenable` and
//     the /parent screen reads as its access boundary. Starts LOCKED every
//     launch (D-07 per-entry: no session unlock). `unlock()` flips it after a
//     correct PIN; `lock()` relocks on "Done"/dispose so the next entry
//     re-prompts. Constructor takes a named `unlocked` (default false) so tests
//     can seed either state — the Wave-0 RED contract pins this exact shape.
//  2. parentProgressProvider — a HAND-WRITTEN FutureProvider<ParentProgress>
//     (NOT @riverpod codegen) assembling the read-only dashboard model from the
//     curriculum letter list + allMastered() + the folded
//     allInProgressByExerciseReps() aggregate (D-15).
//
// KNOWN ANALYZER NOTE: riverpod_lint emits one `unsupported_provider_value`
// warning for `parentGate` below, exactly as it does for `onboardingGate` in
// profile_providers.dart — because `ParentGate` is a ChangeNotifier exposed as a
// provider value (the router's refreshListenable, RESEARCH Pattern 3), not
// Future/Stream state. The plugin honors no inline `// ignore:` for this
// diagnostic in the current toolchain, so it is left visible and documented. It
// is a deliberate-design false-positive, not a defect.
//
// NOTE (deviation policy, same as profile_providers.dart): `parentProgressProvider`
// is hand-written, NOT @riverpod codegen — riverpod_generator 4.0.3 throws
// `InvalidTypeException` when a functional provider's return type touches Drift
// types, and ParentProgress is assembled from Drift rows (Pitfall 3). The
// manual FutureProvider preserves the `parentProgressProvider.overrideWith(...)`
// test contract.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/app_database.dart';
import '../data/curriculum_repository.dart';
import '../features/parent/parent_progress.dart';
import 'auth_providers.dart';
import 'profile_providers.dart';

// Re-export the read-only dashboard view models so the Wave-0 RED contract can
// reach `ParentProgress` / `ParentLetterRow` through `parent_providers.dart`
// (test/screens/parent_dashboard_test.dart imports them from here, not from the
// features/parent path). Keeps the test's single-import surface honest.
export '../features/parent/parent_progress.dart'
    show ParentProgress, ParentLetterRow;

part 'parent_providers.g.dart';

/// The parent-area access gate. A `ChangeNotifier` the router watches as
/// `refreshListenable` and the /parent screen reads as its barrier.
///
/// Starts LOCKED (D-07 per-entry, no session unlock). `unlock()` flips it after
/// a correct PIN; `lock()` relocks on exit so a second entry re-prompts.
class ParentGate extends ChangeNotifier {
  ParentGate({bool unlocked = false}) : _unlocked = unlocked;

  bool _unlocked;

  /// Whether the parent area is currently accessible (true only after a correct
  /// PIN, until the next `lock()`).
  bool get unlocked => _unlocked;

  /// Open the gate after a correct PIN.
  void unlock() {
    if (_unlocked) return;
    _unlocked = true;
    notifyListeners();
  }

  /// Relock the gate (on "Done"/dispose) so the next entry re-prompts the PIN.
  void lock() {
    if (!_unlocked) return;
    _unlocked = false;
    notifyListeners();
  }
}

/// keepAlive — held for the app lifetime.
///
/// PRODUCTION ALWAYS OVERRIDES THIS in main.dart with a fresh LOCKED
/// `ParentGate()` (D-07: starts locked every launch, no boot DB read).
///
/// WR-02: the default is `unlocked: false` (default-DENY). An access-control
/// object must fail safe: any entry point or test that pumps the dashboard
/// without explicitly seeding the gate gets the PIN flow, never the dashboard
/// body. Tests that need the unlocked state opt in explicitly with
/// `parentGateProvider.overrideWith((ref) => ParentGate(unlocked: true))` (see
/// test/screens/parent_dashboard_test.dart). The route-gate test
/// (test/router/parent_gate_test.dart) already overrides this provider
/// explicitly to drive lock/unlock.
///
/// `ParentGate` is a `ChangeNotifier` exposed as a provider value on purpose —
/// the router's `refreshListenable` (Pattern 3). riverpod_lint's
/// `unsupported_provider_value` flags any non-Future/Stream value; the
/// Listenable-as-provider shape is intentional here (see file header).
@Riverpod(keepAlive: true)
ParentGate parentGate(Ref ref) {
  final gate = ParentGate();
  ref.listen(authStateProvider, (_, __) => gate.lock());
  return gate;
}

/// The read-only dashboard model: the "N of M" summary counts + the per-letter
/// rows in curriculum intro order. Hand-written (not codegen) because the
/// assembly reads Drift row types (Pitfall 3).
///
/// Assembly (RESEARCH 09-RESEARCH draft):
///   * `mastered` = {letterId → LetterMasteryData} from `allMastered()`;
///   * `inProgress` = {letterId → cleanReps} from `allInProgressByExerciseReps()`
///     (D-15 fold: the LetterExerciseReps MAX aggregate replaces the legacy
///     `allInProgress()` LetterReps read);
///   * iterate `getLetters()` (already sorted by introOrder) and emit a mastered
///     row for mastered ids, else an in-progress row for ids present in
///     inProgress, else SKIP untouched letters;
///   * `total` = letters.length (NOT a literal 28 — A-01);
///   * `mastered` count = the mastered map size.
final parentProgressProvider = FutureProvider<ParentProgress>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final curriculum = ref.watch(curriculumRepositoryProvider);

  // ADR-018: the dashboard reads only THIS child's rows. Resolve the in-file
  // child id (best-effort; a null/missing profile degrades to the unassigned
  // sentinel so the dashboard renders empty rather than another child's rows).
  int childProfileId;
  try {
    final profile = await ref.watch(childProfileProvider.future);
    childProfileId = profile?.id ?? kUnassignedChildProfileId;
  } catch (_) {
    childProfileId = kUnassignedChildProfileId;
  }

  final masteredRows = await db.allMastered(childProfileId: childProfileId);
  final mastered = {for (final m in masteredRows) m.letterId: m};
  // D-15 fold (19-04): the in-progress list now reads the LetterExerciseReps
  // MAX aggregate (letterId → aggregate clean-reps) instead of the legacy
  // LetterReps `allInProgress()` — LetterReps is off the live read path.
  final inProgress =
      await db.allInProgressByExerciseReps(childProfileId: childProfileId);

  final letters = await curriculum.getLetters(); // sorted by introOrder

  final rows = <ParentLetterRow>[];
  for (final letter in letters) {
    final masteryRow = mastered[letter.id];
    if (masteryRow != null) {
      rows.add(
        ParentLetterRow(
          letterId: letter.id,
          displayName: letter.name.display,
          glyph: letter.char, // WR-03: carry the glyph from this same parse.
          mastered: true,
          cleanReps: masteryRow.cleanReps,
          masteredAtLabel: _formatShortDate(masteryRow.masteredAt),
        ),
      );
    } else if (inProgress.containsKey(letter.id)) {
      rows.add(
        ParentLetterRow(
          letterId: letter.id,
          displayName: letter.name.display,
          glyph: letter.char, // WR-03: carry the glyph from this same parse.
          mastered: false,
          cleanReps: inProgress[letter.id]!,
        ),
      );
    }
    // else: untouched — not shown.
  }

  return ParentProgress(
    mastered: mastered.length,
    total: letters.length,
    rows: rows,
  );
});

/// Device-locale-agnostic short date label (e.g. "Jun 1"). Western numerals.
/// Kept dependency-free (no intl) — a compact month-abbreviation + day.
String _formatShortDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}
