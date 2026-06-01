// DemoAlif — the single static, engine-free mock content source for the whole
// alif presentation demo (DP-01/DP-05).
//
// Every demo screen (Watch, Trace, Feedback, Celebration) reads the alif glyph,
// the authored named-fix copy, and the reference stroke from HERE — and only
// here. There is NO scorer, NO Drift, NO capture engine, NO network: the demo
// must be fast and impossible to break on stage (DP-01). This keeps one source
// of truth so the screens stay in sync without any runtime dependency.
//
// The named-fix strings are copied VERBATIM from assets/curriculum/letters.json
// (alif commonMistakes[].feedback) — the tutor's voice is the contract, not a
// paraphrase (DP-05, CLAUDE.md "the tutor's voice"). The fallback line is the
// UI-SPEC calm fallback; it is never the generic try-again throwaway line.
//
// Pure Dart only: no widgets, no engine imports, no I/O. The reference points
// are plain `List<double>` pairs (normalized 0..1) so the Trace/Watch painter
// has one shared geometry source without importing this file's concerns.

/// Static, immutable alif demo content. Not instantiable.
abstract final class DemoAlif {
  const DemoAlif._();

  /// The isolated alif glyph ("ا").
  static const String glyph = 'ا';

  /// English display name.
  static const String displayName = 'Alif';

  /// Vocalized Arabic name ("اَلِف"), from letters.json name.ar.
  static const String arabicName = 'اَلِف';

  /// The single reference stroke for alif: a straight vertical line, normalized
  /// 0..1, drawn top (y=0) to bottom (y=1). Reused verbatim from letters.json
  /// alif referenceStrokes[0].points so the painter shares one geometry.
  static const List<List<double>> referencePoints = <List<double>>[
    <double>[0.5, 0.0],
    <double>[0.5, 0.25],
    <double>[0.5, 0.5],
    <double>[0.5, 0.75],
    <double>[0.5, 1.0],
  ];

  /// The reference stroke direction (the teaching hint).
  static const String referenceDirection = 'topToBottom';

  /// The three authored common-mistake fixes, keyed by mistake id. Copied
  /// VERBATIM from letters.json alif commonMistakes[].feedback (DP-05).
  static const Map<String, String> namedFixes = <String, String>{
    'too_short':
        'Your alif needs to be taller — draw it from the top all the way down.',
    'wrong_direction':
        'Start your alif at the top and come down — not from the bottom up.',
    'too_curved':
        'Alif is a straight line — try to keep it as straight as you can.',
  };

  /// The hero miss line shown on the demo Feedback (miss) screen — the
  /// wrong-direction fix, the most teachable alif error.
  static String get heroMissFix => namedFixes['wrong_direction']!;

  /// Calm fallback when no named mistake matches (UI-SPEC) — never a throwaway.
  static const String fallbackFix =
      'Something looks off — try again, slower this time.';
}
