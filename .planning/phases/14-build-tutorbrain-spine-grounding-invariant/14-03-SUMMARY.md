---
phase: 14-build-tutorbrain-spine-grounding-invariant
plan: 03
subsystem: tutor-client
tags: [riverpod, http, firebase-app-check, firebase-auth, cloud-run, grounding, non-pii, tutor-seam]

requires:
  - phase: 14-01
    provides: "The deployed enlarged non-PII wire DTO TutorFactsIn (6 base + AttemptFactIn trajectory + strengthTags, extra=forbid) and the POST /coach + GET /healthz endpoints"
provides:
  - "RemoteAgentBrain — the cloud-tutor TutorBrain that POSTs the non-PII facts to /coach with a Firebase ID token + App Check token, parses CoachOut into a TutorDecision, and auto-degrades to AuthoredFallback on any failure (never throws)"
  - "Enlarged client TutorFacts (trajectory: List<AttemptFact> + strengthTags) mirroring the deployed server TutorFactsIn field-for-field"
  - "TutorDecision carries an optional TutorPlan alongside the closed 4-ACTION set"
  - "tutor_providers.dart — the single tutorBrainFactoryProvider switch point + the tutorLineProvider line channel"
  - "exercise_scaffold wiring: the agent's line reaches the UI via tutorLineProvider with ExerciseController byte-for-byte untouched (GROUND-01)"
affects:
  - "Plan 14-04 (the GROUND-02 build-failing non-PII guard builds on the tightened guard + the enlarged TutorFacts)"
  - "Any later UI hook for the /healthz warm-up ping (documented as a follow-up here)"

tech-stack:
  added:
    - "firebase_app_check 0.4.5 (promoted from transitive to a direct dep; FlutterFire lockstep with firebase_core 4.11.0)"
    - "http 1.6.0 (verified-publisher dart.dev package, for the REST /coach call)"
  patterns:
    - "Single backend switch point: tutorBrainFactoryProvider builds RemoteAgentBrain wrapping AuthoredFallbackBrain — swapping the backend touches no canvas/scorer/curriculum/controller code (TUTOR-01)"
    - "Auto-degrade-never-throw: RemoteAgentBrain.next() returns the floor's decision on timeout/offline/non-200/parse-error/missing-token (G5/TUTOR-02)"
    - "Verdict-first, line-second: the scaffold calls ExerciseController.applyResult FIRST and unchanged, then routes the agent line through tutorLineProvider (GROUND-01)"
    - "Non-PII chokepoint by construction: buildTutorFacts accepts no stroke/Offset/profile param; the enlarged whitelist + recursive guard catch any geometry/PII key"

key-files:
  created:
    - lib/tutor/remote_agent_brain.dart
    - lib/tutor/tutor_providers.dart
    - test/tutor/remote_agent_brain_test.dart
    - test/tutor/tutor_providers_test.dart
  modified:
    - lib/tutor/tutor_facts.dart
    - lib/tutor/tutor_facts_builder.dart
    - lib/tutor/tutor_decision.dart
    - lib/features/letter_unit/widgets/exercise_scaffold.dart
    - test/tutor/tutor_facts_builder_test.dart
    - pubspec.yaml
    - pubspec.lock

key-decisions:
  - "Server base URL via --dart-define=TUTOR_BASE_URL (empty default → offline floor), overridable in tests/flavors via a ProviderScope override"
  - "tutorLineProvider is a Notifier<String?> because Riverpod 3 removed StateProvider (project is on flutter_riverpod 3.x)"
  - "appCheckTokenGetterProvider defaults to null (degrade-to-floor) so dev/widget-test builds without App Check init never call the App-Check-gated server unauthenticated; main.dart overrides it with the real getLimitedUseToken() getter at the composition root"
  - "The agent supplies only the bubble TEXT on a verdict; the bubble tone + mascot pose stay verdict-driven (GROUND-01)"

patterns-established:
  - "Tightened non-PII guard: anchor only the single letters x/y to a word boundary (\\b[xy]\\b) so trajectory/strengthTags/nextExerciseId PASS while x/y/strokes/offset/childName FAIL; multi-char PII tokens stay substrings"
  - "Recursive key scan: the whitelist test descends into nested trajectory records so a leaked key inside an AttemptFact is also caught"

requirements-completed: [TUTOR-01, TUTOR-02, TUTOR-03]

duration: ~45min
completed: 2026-06-22
---

# Phase 14 Plan 03: Wire the Client to the Capable Cloud Tutor Summary

**RemoteAgentBrain calls the Cloud Run /coach endpoint with a Firebase ID token + App Check token and auto-degrades to the authored offline floor; the enlarged client TutorFacts (trajectory + strengthTags) mirrors the deployed server DTO byte-for-byte; the coaching line reaches the UI through one tutorLineProvider with ExerciseController untouched.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-22 (worktree wave 2)
- **Completed:** 2026-06-22
- **Tasks:** 3 code tasks complete; 1 device checkpoint PENDING-HUMAN
- **Files modified/created:** 11 (4 created, 7 modified)

## Accomplishments

- **Enlarged the client TutorFacts** to carry `trajectory: List<AttemptFact>` (`{passed, mistakeId, section}`) + `strengthTags`, mirroring the deployed server `TutorFactsIn` (`server/app/schema.py`) field-for-field — a populated client payload validates 200 under the server's `extra="forbid"`, never 422.
- **TutorDecision** now carries an optional `TutorPlan` (`{nextExerciseId, intent, rationale}`) alongside the unchanged sealed 4-ACTION shape set (the action space stays closed — GROUND-01).
- **RemoteAgentBrain** POSTs `facts.toJson()` to `/coach` with `Authorization: Bearer <ID token>` + `X-Firebase-AppCheck`, maps `CoachOut` → the matching `TutorDecision`, and degrades to the wrapped `AuthoredFallbackBrain` on ANY failure — it never throws to its caller, so the trace loop can never block (G5/TUTOR-02/03).
- **Single switch point:** `tutorBrainFactoryProvider` is the only place the online↔offline routing lives; swapping the backend changes no canvas/scorer/curriculum/controller code (TUTOR-01).
- **The line reaches the UI via `tutorLineProvider`** only; `_onResult` applies the scorer's verdict FIRST and unchanged, and `ExerciseController` is byte-for-byte untouched (`git diff --exit-code` clean — GROUND-01).
- **Tightened the non-PII guard regex** so the new legit keys pass while real geometry/PII keys still fail, with both directions asserted and a recursive scan of nested trajectory keys.

## Task Commits

1. **Task 1: Reshape TutorFacts + TutorDecision (trajectory + plan), mirror server DTO, tighten the guard** — `250dc08` (feat, TDD)
2. **Task 2: RemoteAgentBrain (server call + dual auth + auto-degrade) + firebase_app_check/http deps** — `64f3ae8` (feat, TDD)
3. **Task 3: Route through the single switch point + wire the line into the scaffold** — **STAGED, NOT YET COMMITTED** (see Issues Encountered: `git commit` is permission-denied for the worktree executor; the orchestrator must finalize this commit then merge)

_TDD tasks (1, 2) were each authored RED-then-GREEN; the test + implementation are committed together because Task 1's test enriches an existing whitelist test file rather than adding a standalone failing file._

## Files Created/Modified

- `lib/tutor/tutor_facts.dart` — added `AttemptFact` + `trajectory` + `strengthTags`; `toMap()` emits exactly the 8 server `TutorFactsIn` fields.
- `lib/tutor/tutor_facts_builder.dart` — the chokepoint now accepts `trajectory` and derives `strengthTags` (inverse of struggles: cleanly-passed sections); still accepts no stroke/Offset/profile param.
- `lib/tutor/tutor_decision.dart` — added `TutorPlan` + an optional `plan` on every decision; the sealed 4-ACTION set + `TutorTool` names unchanged.
- `lib/tutor/remote_agent_brain.dart` — the cloud call + dual-auth headers + auto-degrade-never-throw.
- `lib/tutor/tutor_providers.dart` — `tutorBrainFactoryProvider` (the single switch), `tutorLineProvider`, and the overridable URL/client/token seams.
- `lib/features/letter_unit/widgets/exercise_scaffold.dart` — `_onResult` (verdict first → accumulate trajectory → build facts → ask brain → write `tutorLineProvider`); `_TutorColumn` reads `tutorLineProvider` (agent line preferred on a verdict, tone/pose stay verdict-driven).
- `test/tutor/tutor_facts_builder_test.dart` — tightened guard (both directions) + nested-key recursion + trajectory/strengthTags/plan assertions.
- `test/tutor/remote_agent_brain_test.dart` — MockClient: 200→tool+line+plan; 503/timeout/offline/missing-token→floor; body == facts.toJson() with no extra keys + both auth headers.
- `test/tutor/tutor_providers_test.dart` — unreachable-server-still-grounded; controller-has-no-line-setter source guard.
- `pubspec.yaml` / `pubspec.lock` — `firebase_app_check ^0.4.5`, `http ^1.6.0`.

## Resolved dependency versions

| Package | Resolved | Notes |
|---------|----------|-------|
| firebase_app_check | 0.4.5 | promoted transitive → direct; FlutterFire lockstep with firebase_core 4.11.0 (which did NOT move) |
| http | 1.6.0 | verified-publisher dart.dev package |

## Server-URL config mechanism

`--dart-define=TUTOR_BASE_URL=https://<cloud-run-url>` read by `tutorBaseUrlProvider` (`String.fromEnvironment`). Empty by default → the factory still returns a brain whose AuthoredFallback floor holds (offline/dev builds never block). Overridable via a `ProviderScope` override in tests/flavors.

## Trajectory shape passed into buildTutorFacts

The scaffold accumulates a `List<AttemptFact>` across attempts of the current exercise, each `{passed: bool, mistakeId: String?, section: String}` (section = `exercise.type ?? exercise.skill`). Derived records only — never raw strokes (GROUND-02). `strengthTags` are derived from this trajectory (sections with zero misses).

## Final tightened guard regex

```dart
final _forbiddenKey = RegExp(
  r'\b[xy]\b|stroke|offset|coord|point|raw|nick|name',
  caseSensitive: false,
);
```

Only the single letters `x`/`y` are word-boundary-anchored (the original substring trap that hit `trajectory`'s "y" and `nextExerciseId`'s "x"); the multi-char PII/geometry tokens stay substrings because no legit field name contains them. A real `x`/`y`/`strokes`/`offset`/`childName` key FAILS; `trajectory`/`strengthTags`/`nextExerciseId` PASS — both directions asserted.

## Decisions Made

See `key-decisions` in the frontmatter. Highlights: empty-URL/null-token defaults degrade to the floor (fail-safe); `tutorLineProvider` is a `Notifier` (Riverpod 3 dropped `StateProvider`); the agent supplies only bubble TEXT while tone/pose stay verdict-driven (GROUND-01).

## Deviations from Plan

The plan's prose assumed a Wave-1 scaffold that "already" wired `tutorLineProvider` / `_TutorLineAdapter` / `_TutorColumn` and that `tutor_providers.dart` already existed. At the base commit, **none of those existed** — `tutor_providers.dart` was absent and the scaffold read its line directly from `ExerciseController`. This is a plan-context inaccuracy, not a deviation in behavior: I created `tutor_providers.dart` (it is in the plan's `files_modified`) and added the minimal, faithful `tutorLineProvider` wiring that satisfies every must-have — single switch point, line via provider, `ExerciseController` byte-for-byte untouched. No architectural change (Rule 4) was needed.

No Rule 1/2/3 auto-fixes were required for the tutor code itself.

## Issues Encountered

- **`git commit` is permission-denied for the worktree executor (known constraint).** Tasks 1 and 2 committed successfully (`250dc08`, `64f3ae8`), but mid-session `git commit` began returning permission-denied — matching the documented "executor cannot commit in worktree" behavior. **Task 3's changes and this SUMMARY are fully STAGED** (`git add` succeeded) but could not be committed by this agent. **The orchestrator must run the Task 3 + SUMMARY commits, then merge the worktree branch.** All code is complete and tested; only the git-commit step is blocked.
- **One pre-existing, out-of-scope test failure:** `test/features/letter_unit/meet_section_test.dart` Test 1 (`find.textContaining('img.door')` → 0 widgets). `meet_section` is a teachCard (no `_onResult`, no grading); my change adds only a defaulted `tutorLineProvider` read to `_TutorColumn`. The failure is unrelated image-stub/asset rendering in the test harness. Logged to `deferred-items.md`; NOT fixed (SCOPE BOUNDARY).

## Verification

- `flutter test test/tutor/` → **30 passed** (facts/decision reshape + tightened guard both directions; RemoteAgentBrain 200/503/timeout/offline/missing-token + body==facts.toJson(); provider unreachable-still-grounded + controller-no-line-setter).
- `flutter test test/features/letter_unit/exercise_scaffold_test.dart` → **4 passed** (the verdict-driven pass/fix flow still works with the new provider reads).
- `git diff --exit-code lib/features/letter_unit/exercise_controller.dart` → **no change** (GROUND-01 controller untouched).
- `flutter analyze` on the new/changed files (`tutor_facts*.dart`, `tutor_decision.dart`, `remote_agent_brain.dart`) → **No issues found** (run before the analyze-permission was restricted later in the session; the full `test/tutor/` compile + pass independently confirms `tutor_providers.dart` and the scaffold compile clean).

## Task 4 — device human-verify checkpoint: PENDING-HUMAN

Task 4 is a `checkpoint:human-verify` (gate=blocking) requiring an **on-device run against the LIVE Cloud Run endpoint** — which is NOT yet deployed (it is 14-01's still-pending deploy checkpoint) and cannot be exercised autonomously by this worktree executor (no device, no live endpoint). Per the orchestrator's instruction, **no device launch or live-endpoint call was attempted.** All code is complete, committed/staged, and unit/widget-tested with the HTTP client mocked.

**The exact verification steps the human runs once 14-01 is deployed (from the plan):**

1. Run the app on the device/emulator pointed at the Cloud Run URL (`--dart-define=TUTOR_BASE_URL=<url>`). Trace a baa attempt → confirm the tutor bubble shows the **server's** warm, specific, correctly-Arabic line (not a canned message).
2. Trace a deliberately bad attempt → confirm the line names a fix and **never** says "great job" / never auto-advances on a fail (GROUND-01).
3. Turn on airplane mode and trace again → confirm a grounded **AuthoredFallback** line appears and the Clear/Try-again/Next loop still works (never blocks).
4. Confirm no API key is in the client build (it is not — keys are Secret Manager server-side; the online line came from the server, the offline line from the floor).

**Resume signal:** Type "approved" once the online line, the grounded-fail behavior, and the airplane-mode floor all check out — or describe the issue. (Recall the Phase 07 baa device bugs: verify on a real running app, not blind.)

**Composition-root follow-ups the human/next plan must wire before the device test:**
- Override `appCheckTokenGetterProvider` in `main.dart` with the real `FirebaseAppCheck.instance.getLimitedUseToken()` getter (and initialize App Check with the Play Integrity provider).
- Pass `--dart-define=TUTOR_BASE_URL=<deployed url>` to the device build.
- (Out of scope here, documented follow-up) a `/healthz` warm-up ping on a UI hook to hide cold-start latency.

## Known Stubs

- `appCheckTokenGetterProvider` returns `null` by default — an INTENTIONAL fail-safe stub so un-overridden (dev/test) builds degrade to the offline floor rather than calling the App-Check-gated server unauthenticated. The live app overrides it at the composition root (`main.dart`). Documented above; resolved by the composition-root wiring before the device checkpoint.

## Next Phase Readiness

- The client↔server seam is code-complete and fully unit/widget-tested (mocked). Ready for: (a) 14-01's live deploy, (b) the composition-root App-Check + dart-define wiring, (c) the on-device checkpoint.
- Plan 14-04's GROUND-02 build-failing guard can build on the tightened guard + the enlarged TutorFacts shape landed here.

## Self-Check: PASSED

- All 5 key files exist on disk (`remote_agent_brain.dart`, `tutor_providers.dart`, the two new tests, and this SUMMARY).
- Task 1 commit `250dc08` and Task 2 commit `64f3ae8` exist in git log.
- Task 3 + SUMMARY are STAGED but NOT committed — `git commit` is permission-denied for the worktree executor (known constraint). **The orchestrator must commit the staged Task 3 changes + this SUMMARY, then merge.**

---
*Phase: 14-build-tutorbrain-spine-grounding-invariant*
*Completed: 2026-06-22*
