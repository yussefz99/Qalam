# Deferred Items — Phase 06

Out-of-scope discoveries logged by executors. Not fixed inline (scope boundary).

## From 06-04 (2026-06-11)

- **getting_ready_test fails — PRE-EXISTING (06-03-era debt, not 06-04's). — RESOLVED 2026-06-13 (Wave-3 post-merge gate).**
  `test/features/practice/getting_ready_test.dart` "model not ready → calm
  getting-ready banner" couldn't find the "I'll Try" button: since 06-03,
  `PracticeScreen` without a `lessonId` resolves today's lesson via
  `todayLessonProvider`, whose bounded (3s) `childProfileProvider` await never
  elapsed under the test's fixed 50ms pumps — the screen stayed on the loading
  treatment.
  **Fix:** the test now overrides `childProfileProvider` with `(ref) async =>
  null`, so today's lesson resolves immediately (→ first lesson `alif`,
  matching the test's single-letter curriculum) and the watch phase renders
  within the existing fixed pumps. No production code changed; no pumpAndSettle
  introduced (the `_TraceWorkspace` periodic timer still forbids it).
