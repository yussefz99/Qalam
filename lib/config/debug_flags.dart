abstract final class DebugFlags {
  // D-13/D-14: Allow finger/touch input through the stroke canvas in debug
  // builds so the owner can develop on finger-only hardware. Read only behind
  // kDebugMode at the call site. Production always ignores touch.
  static const bool allowFingerInput = true;
}
