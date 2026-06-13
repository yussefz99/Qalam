# Deferred Items — Phase 06

Out-of-scope discoveries logged by executors. Not fixed inline (scope boundary).

## From 06-04 (2026-06-11)

- **getting_ready_test fails — PRE-EXISTING (06-03-era debt, not 06-04's).**
  `test/features/practice/getting_ready_test.dart` "model not ready → calm
  getting-ready banner" can't find the "I'll Try" button: since 06-03,
  `PracticeScreen` without a `lessonId` resolves today's lesson via
  `todayLessonProvider`, whose bounded (3s) `childProfileProvider` await never
  elapses under the test's fixed pumps — the screen stays on the loading
  treatment. Verified pre-existing by running the test against the
  base-commit (5e910d6) versions of every lib file 06-04 touched: identical
  failure. Fix belongs with whichever plan owns practice-screen test debt
  (06-05/06-07 cluster): either pass an explicit `lessonId` in the test or
  pump past the 3s timeout / override the progression providers.
