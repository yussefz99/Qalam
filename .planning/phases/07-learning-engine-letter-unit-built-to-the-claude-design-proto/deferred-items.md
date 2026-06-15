# Deferred Items — Phase 07

Out-of-scope discoveries logged during execution. Do NOT fix inline; track here.

## From Plan 07-03 (validator spine)

- **`test/core/scoring/mistake_mapping_test.dart` fails to COMPILE in a fresh
  worktree** — `Error when reading 'lib/l10n/app_localizations.dart': No such
  file or directory`. This is the known, pre-existing gitignored-l10n issue
  (MEMORY: "l10n generated is gitignored" — run `flutter gen-l10n` after a fresh
  checkout). NOT a regression from 07-03 (no scoring/l10n file was touched). The
  rest of `test/core/scoring/` (44+ tests: geometric scorer, resampler,
  tolerances, reference path, calibration) passes. Resolve by running
  `flutter gen-l10n` before the suite; out of scope for this plan.
