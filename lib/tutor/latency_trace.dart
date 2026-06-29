/// Debug/demo-ONLY latency instrumentation for the PRES-01 budget measurement
/// (Phase 16, Plan 16-04 Task 3). NOT a child-facing feature — it never renders
/// anything and is compiled to a silent no-op in a release child build.
///
/// WHY: the written stroke → scorer → client → Cloud Run → model → render →
/// first-TTS latency budget (warm + cold-start delta) is MEASURED on the Pixel
/// Tablet, not researched (16-RESEARCH A6). To capture it we log a monotonic
/// timestamp at each segment boundary and read them off `adb logcat`.
///
/// THE SIX SEGMENT MARKS (the system diagram):
///   1. stylusUp              — the child lifts the stylus (letter complete)
///   2. scorerVerdictRendered — the instant on-screen verdict + star (the local
///                              reflex; D-05 — this must NOT wait on /coach or TTS)
///   3. coachRequestSent      — the /coach POST left the device
///   4. coachResponseReceived — the /coach response (or floor degrade) returned
///   5. lineRendered          — the coaching line painted into the bubble
///   6. firstTtsStart         — the first TTS utterance began
///
/// PRIVACY (GROUND-02 / T-16-04-04): this logs ONLY the segment name + a clock
/// reading. It NEVER logs raw strokes, coordinates, mistakeIds, the coaching
/// text, or any PII — just timings. The whole surface is gated so it cannot fire
/// in a release child build.
library;

import 'package:flutter/foundation.dart';

/// Turn the trace on explicitly with `--dart-define=LATENCY_TRACE=true` for the
/// on-device measurement run. It is ALSO active under `kDebugMode` and the demo
/// flag so a debug/demo build prints the marks without an extra define — but it
/// is ALWAYS a no-op in a release child build (the trace is never child-facing).
const bool _kLatencyTraceFlag = bool.fromEnvironment('LATENCY_TRACE');
const bool _kDemoFlag = bool.fromEnvironment('DEMO');

/// True only in a debug build, a demo build, or when LATENCY_TRACE is defined —
/// never in a plain release child build.
bool get _latencyTraceEnabled =>
    kDebugMode || _kDemoFlag || _kLatencyTraceFlag;

/// The six timed segment boundaries of the written-stroke → first-TTS path.
enum LatencySegment {
  stylusUp,
  scorerVerdictRendered,
  coachRequestSent,
  coachResponseReceived,
  lineRendered,
  firstTtsStart,
}

/// Log a monotonic timestamp for [segment] (debug/demo-only, never in a release
/// child build; never logs PII — just the segment name + a clock reading).
///
/// Read the marks off the device with:
///   `adb logcat | grep LATENCY`
/// then subtract adjacent timestamps to get each segment's delay. Run the seeded
/// baa flow once COLD (first call after idle, min-instances=0) and once WARM
/// (after the warm-up ping / a prior call) and record both, plus the cold-start
/// delta and the first-TTS start, in 16-LATENCY-BUDGET.md.
void markLatency(LatencySegment segment) {
  if (!_latencyTraceEnabled) return; // silent no-op in a release child build.
  // Monotonic, wall-clock-independent microseconds — the right clock for deltas.
  final us = _stopwatch.elapsedMicroseconds;
  // No PII: only the segment name + the elapsed clock reading.
  debugPrint('LATENCY ${segment.name} ${us}us');
}

/// A single process-wide monotonic clock so every mark is on the same timebase
/// (DateTime.now() can jump; a Stopwatch cannot). Started lazily at first use.
final Stopwatch _stopwatch = Stopwatch()..start();
