# Deferred items — Phase 14

Out-of-scope discoveries logged during execution (not fixed — SCOPE BOUNDARY rule).

## From 14-03 (RemoteAgentBrain wiring)

- **`test/features/letter_unit/meet_section_test.dart` Test 1 fails** —
  `find.textContaining('img.door')` finds 0 widgets (the door-image stub caption
  is not rendered in the test environment).
  - **Why out of scope:** 14-03 touched only `lib/tutor/*` and the
    `_onResult`/`_TutorColumn` tutor-line wiring in `exercise_scaffold.dart`. It
    did NOT modify `meet_section.dart`, `prompt_header.dart`, or any image-stub
    rendering. `meet_section` is a teachCard (surface == null) so `_onResult` is
    never invoked and `_TutorColumn` only adds a defaulted `tutorLineProvider`
    read (null → falls back to the controller line). The failure is unrelated to
    the tutor change — a pre-existing image-stub/asset rendering issue in the
    widget-test harness (consistent with the project's known asset/font-drift
    test fragility).
  - **Action:** Not fixed here. Investigate separately (image stub or asset load
    in the meet-section test harness).
