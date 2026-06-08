---
phase: 04-scoring-quality-calibration
plan: 03
subsystem: recognition
tags: [dart, mlkit, recognition, riverpod, codegen, advisory-gate, model-download]

# Dependency graph
requires:
  - phase: 04-scoring-quality-calibration
    plan: 01
    provides: "HandwritingRecognizer interface seam + RecognitionResult, the D-04 advisory-only / 0.5-confidence-floor contract"
  - phase: 04-scoring-quality-calibration
    plan: 02
    provides: "scoreLetter spine — consumes the HandwritingRecognizer seam as an advisory-only identity gate (the call site this plan re-wires to the widened seam)"
provides:
  - "MlKitRecognizer — on-device google_mlkit_digital_ink_recognition implementation of HandwritingRecognizer (SC#2 scribble/wrong-letter net), advisory-only, degrades to 'no opinion' on empty/failed recognition"
  - "Widened HandwritingRecognizer.identify seam: whole multi-stroke letter List<List<List<double>>> (a baa is body line + dot, recognised together)"
  - "Pure inkFromStrokes / resultFromCandidates helpers (device-free, unit-tested) carrying all the Ink-building + candidate-mapping logic"
  - "ModelDownloadService @Riverpod(keepAlive) — best-effort background ar-model fetch with isReady + calm getting-ready degradation (D-05)"
  - "inkModelManagerProvider — overridable seam so the model manager is injectable/testable without a device"
affects: [practice-screen-scoring, calibration-harness, model-availability-ui]

# Tech tracking
tech-stack:
  added:
    - "google_mlkit_digital_ink_recognition ^0.14.2 (on-device Arabic ink recognition — owner-validated, STACK.md-prescribed)"
    - "google_mlkit_commons 0.11.1 (transitive — ModelManager)"
  patterns:
    - "Advisory-only recogniser: reports {topCandidate, confidence}, NEVER a pass/fail verdict — the gating policy lives entirely in scoreLetter (D-04)"
    - "Pure device-independent helpers (inkFromStrokes/resultFromCandidates) factored out so on-device plugin logic is unit-testable via mocktail"
    - "Best-effort async service mirroring PracticeSessionController: prime isReady:false → background fetch → flip true, swallow all failures (D-05)"
    - "Overridable provider seam (inkModelManagerProvider) for injecting a platform dependency into a @riverpod Notifier under test"

key-files:
  created:
    - lib/core/recognition/ml_kit_recognizer.dart
    - lib/services/model_download_service.dart
    - lib/services/model_download_service.g.dart
    - test/core/recognition/ml_kit_recognizer_test.dart
    - test/services/model_download_service_test.dart
  modified:
    - lib/core/recognition/handwriting_recognizer.dart
    - lib/core/scoring/letter_scorer.dart
    - test/core/scoring/letter_scorer_test.dart
    - pubspec.yaml
    - pubspec.lock

key-decisions:
  - "Widened identify to List<List<List<double>>> (whole letter) per the documented Claude's-discretion interface decision — a baa is multi-stroke; flattening would collapse body+dot into one stroke and degrade recognition"
  - "ML Kit RecognitionCandidate.score is sparse + inverted ('more likely candidates get LOWER values', unpopulated for some models) so it is NOT mapped to confidence directly; the top candidate gets a fixed advisory confidence (0.9) and the policy decision stays entirely in scoreLetter — we never invent a fine confidence from an unreliable signal"
  - "MlKitRecognizer wraps recognize() in try/catch → returns 'no opinion' (null candidate, confidence 0) on any failure so a geometric pass always stands (D-04 / Pitfall 1 / RESEARCH A4 graceful-degradation)"
  - "Model manager injected via an overridable inkModelManagerProvider rather than a debugSet setter — the setter fired AFTER build()/ensureModel(), too late; the provider override is the idiomatic, race-free Riverpod test seam"
  - "ModelDownloadService is @Riverpod(keepAlive) — the model is an app-lifetime resource, never torn down/refetched on screen dispose"

patterns-established:
  - "Advisory-only recogniser contract: a platform recogniser REPORTS identity; the orchestrator OWNS the verdict (no co-judging)"
  - "Pure-helper extraction for device-bound plugins so logic is unit-testable headless"

requirements-completed: [S1-05, PLAT-03]

# Metrics
duration: 5min
completed: 2026-06-08
---

# Phase 4 Plan 03: ML Kit Advisory Identity Gate + Model Download Summary

**MlKitRecognizer — the on-device `google_mlkit_digital_ink_recognition` implementation of the `HandwritingRecognizer` seam that REPORTS a letter's identity (SC#2 scribble/wrong-letter net) but never a verdict (D-04), behind a seam widened to a whole multi-stroke letter; plus a best-effort `ModelDownloadService` that background-fetches the Arabic `ar` model on first launch, exposes `isReady`, and degrades to a calm getting-ready state on any failure without ever hard-blocking the child (D-05).**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-08T13:30:39Z
- **Completed:** 2026-06-08T13:36:29Z
- **Tasks:** 2
- **Files modified:** 10 (5 created, 5 modified)

## Accomplishments
- Added `google_mlkit_digital_ink_recognition ^0.14.2` (owner-validated, STACK.md-prescribed; resolved cleanly against Flutter 3.41.9 — no version relaxation needed). The plugin raises Android minSdk to 21 via manifest-merge over `flutter.minSdkVersion`.
- **Widened the `HandwritingRecognizer.identify` seam** from one stroke (`List<List<double>>`) to a whole multi-stroke letter (`List<List<List<double>>>`) — the documented interface decision (a baa is body line + dot, recognised together) — and re-wired the Plan 04-02 spine call site + its mocktail fallback so the existing 28-test scoring suite stays green.
- Built `MlKitRecognizer implements HandwritingRecognizer`: builds an ML Kit `Ink` (one `Stroke` per child stroke), calls `DigitalInkRecognizer.recognize`, maps the top `RecognitionCandidate.text` to `RecognitionResult.topCandidate`. **No pass/fail logic in the class** — the D-04 advisory rule stays in `scoreLetter`. A thrown/empty recognition degrades to a null candidate + confidence 0 so the geometric pass stands (RESEARCH A4 graceful degradation).
- Factored the device-bound logic into pure `inkFromStrokes` / `resultFromCandidates` helpers and unit-tested them headless, plus the `identify` orchestration over a mocked `DigitalInkRecognizer` (recognised candidate flows through; empty input skips the call; a thrown recognition never rethrows).
- Built `ModelDownloadService` (`@Riverpod(keepAlive)`): primes `isReady:false`, checks `isModelDownloaded('ar')`, background-downloads if absent, flips `isReady:true` once cached. Wrapped in best-effort try/catch — a failed presence-check OR download leaves a calm not-ready state and NEVER throws (D-05). Codegen `.g.dart` part generated.

## Task Commits

Each task was committed atomically (explicit file paths only — pre-existing unrelated working-tree changes were left untouched):

1. **Task 1: ML Kit advisory identity gate + widen recognizer seam** — `cd00cb4` (feat)
2. **Task 2: best-effort ML Kit model download service (D-05)** — `20f1b5c` (feat)

## Files Created/Modified
- `lib/core/recognition/ml_kit_recognizer.dart` (created) — `MlKitRecognizer implements HandwritingRecognizer`; pure `inkFromStrokes`/`resultFromCandidates` helpers; `kArabicModelCode = 'ar'`; advisory-only, on-device, graceful degradation.
- `lib/core/recognition/handwriting_recognizer.dart` (modified) — widened `identify` to `List<List<List<double>>>` (whole letter); documented the seam-widening decision and the advisory-only / no-verdict contract.
- `lib/core/scoring/letter_scorer.dart` (modified) — `_identityGate` now passes the multi-stroke letter directly instead of flattening (honours the widened seam; flattening would degrade recognition).
- `lib/services/model_download_service.dart` (created) — `ModelDownloadService @Riverpod(keepAlive)` + `ModelDownloadState{isReady}` + overridable `inkModelManagerProvider`; best-effort background fetch, never hard-blocks.
- `lib/services/model_download_service.g.dart` (created) — generated Riverpod part.
- `test/core/recognition/ml_kit_recognizer_test.dart` (created) — pure-helper + mocked-recognizer tests (11 cases).
- `test/services/model_download_service_test.dart` (created) — 6 cases: not-ready prime, already-downloaded (no fetch), fetch-success, fetch-failure, thrown-download, thrown-check.
- `test/core/scoring/letter_scorer_test.dart` (modified) — `registerFallbackValue` updated to the widened `List<List<List<double>>>` arg type (kept the 04-02 suite green).
- `pubspec.yaml` / `pubspec.lock` (modified) — added the ML Kit dependency + transitive `google_mlkit_commons`.

## Decisions Made
- **Seam widened to the whole letter** (`List<List<List<double>>>`). A baa is multi-stroke; ML Kit recognises a letter from all its strokes together. The previous single-stroke signature forced the spine to flatten — which would collapse the body line and dot into one stroke and degrade recognition.
- **ML Kit's `score` is not used as confidence.** Per the plugin docs the score is sparse (unpopulated for some models) and inverted (lower = more likely). Treating it as a 0..1 confidence would be unsound, so the top candidate is reported with a fixed advisory confidence and the actual gating decision stays entirely in `scoreLetter` (the orchestrator already enforces the 0.5 floor and the same-char check). This keeps the class a pure reporter (D-04).
- **Graceful degradation over false rejection (RESEARCH A4).** Any recognition failure → "no opinion" (null candidate, confidence 0). Because the gate is advisory-only, SC#1/SC#3/SC#4 ship regardless; only SC#2 (the scribble net) abstains if the `ar` model under-recognises an isolated letter — never a false rejection of a good baa/taa/thaa.
- **Manager injected via an overridable provider, not a setter.** A `debugSetManager` setter would run after `build()` had already kicked off `_ensureModel()`, racing the fetch. The `inkModelManagerProvider` override is the idiomatic, deterministic Riverpod test seam.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Spine call site + spine-test fallback had to track the widened seam**
- **Found during:** Task 1
- **Issue:** Widening `identify` to `List<List<List<double>>>` made the Plan 04-02 spine (`letter_scorer.dart` `_identityGate`, which flattened to `List<List<double>>`) and its test's `registerFallbackValue(<List<double>>[])` non-matching — the scoring suite would not compile/run.
- **Fix:** `_identityGate` now passes `childStrokes` (the multi-stroke letter) directly; the spine test's `registerFallbackValue` was updated to `<List<List<double>>>[]`. Both are the necessary downstream of the planned seam-widening (the plan's Task 1 action explicitly authorises updating the seam and notes the spine consumes it).
- **Files modified:** lib/core/scoring/letter_scorer.dart, test/core/scoring/letter_scorer_test.dart
- **Verification:** `flutter test test/core/scoring/` → 61 passed (full scoring suite, incl. the 6 D-04 contract tests); `flutter analyze lib/core/recognition/` → clean.
- **Committed in:** cd00cb4 (Task 1 commit)

**Total deviations:** 1 auto-fixed (1 blocking). No architectural changes, no scope creep.

## Issues Encountered
- An incidental `lib/router/app_router.g.dart` hash-only drift appeared when `build_runner` re-ran over all inputs (a deterministic generated `_$appRouterHash()` string, no behaviour change, unrelated to this plan). Reverted with `git checkout -- lib/router/app_router.g.dart` to keep the commit scoped to the plan's files — not swept into the task commit.
- No package-manager risk: `google_mlkit_digital_ink_recognition` is the owner-validated, STACK.md-prescribed official Google package (T-04-SC: Approved; slopcheck targets npm/PyPI/crates, N/A for pub.dev). No human-verify checkpoint required.

## Known Stubs
None. Both deliverables are fully wired against the official plugin and unit-tested. The `ar` single-letter recognition QUALITY is spike-confirmed on-tablet later (Plan 06 Task 1), but the gate is advisory-only by design, so under-recognition degrades to abstention, not a stub or dead code (RESEARCH A4 — explicitly acknowledged in the plan's acceptance criteria).

## User Setup Required
None for code/test. (Operationally, the ~20 MB `ar` model downloads once on first launch over the network; `ModelDownloadService` handles this best-effort and the app is fully offline thereafter — D-05.)

## Next Phase Readiness
- The practice screen / orchestrator can construct a real `MlKitRecognizer` and pass it to `scoreLetter` to activate the SC#2 net; until the model is ready (`ModelDownloadService.isReady == false`) the gate abstains and the geometric scorer runs unchanged.
- A "getting ready" UI can watch `modelDownloadServiceProvider.isReady`.
- The calibration harness (later plan) can exercise the real `MlKitRecognizer` helpers headless via `inkFromStrokes`/`resultFromCandidates`, or inject a fake recogniser into `scoreLetter` over labeled fixtures.

## Threat Flags
None beyond the plan's threat model. T-04-05 (fetch only via `DigitalInkRecognizerModelManager`, no custom URLs, presence-checked), T-04-06 (best-effort background fetch → getting-ready, never hard-block), and T-04-07 (child strokes → Ink on-device only, never transmitted/logged) are all honoured. No new network endpoint beyond the one-time Google model fetch already in the register.

## Self-Check: PASSED

- Created files verified present: ml_kit_recognizer.dart, model_download_service.dart, model_download_service.g.dart, ml_kit_recognizer_test.dart, model_download_service_test.dart, 04-03-SUMMARY.md.
- Commits verified in git log: cd00cb4 (Task 1), 20f1b5c (Task 2).
- `flutter test test/core/recognition/ test/services/ test/core/scoring/` → 61 passed / 0 failed; `flutter analyze lib/core/recognition/ lib/services/` → clean; `MlKitRecognizer implements HandwritingRecognizer` grep confirmed; `isModelDownloaded` grep = 1; `.g.dart` part present.

---
*Phase: 04-scoring-quality-calibration*
*Completed: 2026-06-08*
