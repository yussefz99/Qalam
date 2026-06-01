// DemoBaa — the single static, engine-free mock content source for the BAA
// presentation walkthrough (Watch → Trace → Feedback → Celebration).
//
// The 2026-06-02 course-staff demo Home shows "The letter Baa" (ب), and every
// walkthrough mockup (docs/design/kit/.../screenshots/0X-*) says *baa* — so the
// tappable loop is baa end-to-end. Every walkthrough screen reads the baa glyph,
// the reference stroke, the diacritic dot, and the authored named-fix / praise
// copy from HERE and only here (one source of truth, Pitfall 5). There is NO
// scorer, NO Drift, NO capture engine, NO network (DP-01): the demo must be fast
// and impossible to break on stage.
//
// DemoAlif still exists for its own unit + painter tests; baa lives alongside it
// rather than mutating it. Pure Dart only: no widgets, no engine imports, no I/O.
// The reference points are plain normalized 0..1 pairs so the shared painter has
// one geometry source.

/// Static, immutable baa demo content. Not instantiable.
abstract final class DemoBaa {
  const DemoBaa._();

  /// The isolated baa glyph ("ب").
  static const String glyph = 'ب';

  /// English display name.
  static const String displayName = 'Baa';

  /// Romanized name, used inline in the warm headings ("Watch me write baa.").
  static const String romanized = 'baa';

  /// The single reference stroke for baa: the shallow "boat" bowl, sampled from
  /// the design kit's baa path (`M 130 280 Q 300 480 470 280` in a 600 viewBox)
  /// and normalized 0..1. Ordered left → right so the numbered start-dot sits at
  /// the upper-left, matching the mockups. The painter shares this one geometry.
  static const List<List<double>> referencePoints = <List<double>>[
    <double>[0.217, 0.467],
    <double>[0.288, 0.540],
    <double>[0.358, 0.592],
    <double>[0.429, 0.623],
    <double>[0.500, 0.634],
    <double>[0.571, 0.623],
    <double>[0.641, 0.592],
    <double>[0.712, 0.540],
    <double>[0.783, 0.467],
  ];

  /// The single distinguishing dot below the bowl (what makes it baa, not taa or
  /// thaa) — normalized 0..1. Painted as a solid dot in the stroke color.
  static const List<List<double>> diacriticDots = <List<double>>[
    <double>[0.5, 0.85],
  ];

  /// The hero miss line shown on the demo Feedback (miss) screen — a SPECIFIC
  /// named fix in the tutor's warm voice (CLAUDE.md "the tutor's voice"). This
  /// is mock demo copy (baa is not yet a signed-off curriculum letter); it is
  /// never a generic "Oops, try again".
  static const String heroMissFix =
      'Your baa needs a deeper curve at the bottom — try again, slower this time.';

  /// The clean-pass praise — specific warm praise that names what was good (the
  /// smooth, deep curve). Never over-praises sloppy work.
  static const String passPraise =
      'Beautiful — a smooth, deep curve. أحسنت.';

  /// Calm fallback when no named mistake matches (UI-SPEC) — never a throwaway.
  static const String fallbackFix =
      'Something looks off — try again, slower this time.';
}
