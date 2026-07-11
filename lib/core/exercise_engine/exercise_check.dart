/// Pure Dart, no dart:ui, no Flutter imports.
///
/// THE VALIDATOR-FACING VIEW OF AN EXERCISE (Plan 07-03).
///
/// `validateExercise` does NOT need the whole Schema-v2 `Exercise` (id, prompt
/// parts, surface, policy, …) — it needs exactly three things to render a
/// verdict: the structured **check** (base + modifiers), the **expected** answer
/// (glyph / word / words), and the **feedback** map (so the matched mistakeId is
/// always an authored key). This file defines that narrow contract.
///
/// WHY A SEPARATE VIEW (and not `lib/models/exercise.dart` directly):
/// Plan 07-01 OWNS `lib/models/exercise.dart` (the full `Exercise`/`Check`/
/// `Answer` models) and lands in the SAME wave as this plan. Depending on those
/// concrete classes here would couple two parallel work-streams and collide on
/// merge. Instead the validator depends on this minimal view — a structural
/// mirror of SCHEMA-V2.md §2's `Check` + `Answer` — and Plan 07-04 adapts the
/// real `Exercise` onto it with a one-line mapping
/// (`ExerciseSpec.fromExercise(e)`), once 07-01's model has merged.
///
/// The field names (`check.base`, `check.modifiers`, `expected`, `feedback`)
/// match the locked schema verbatim, so the adapter is mechanical.
library;

/// The structured check that drives validator dispatch (SCHEMA-V2.md §2, #9).
///
/// `base` is one of `glyph` | `sequence` | `order`; `modifiers` layer extra rule
/// checks (`positionalForm` | `joinContinuity` | `transformRule`).
class CheckSpec {
  /// `glyph` | `sequence` | `order`.
  final String base;

  /// Zero or more of `positionalForm` | `joinContinuity` | `transformRule`.
  final List<String> modifiers;

  const CheckSpec({required this.base, this.modifiers = const []});

  bool get hasPositionalForm => modifiers.contains('positionalForm');
  bool get hasJoinContinuity => modifiers.contains('joinContinuity');
  bool get hasTransformRule => modifiers.contains('transformRule');

  /// Parses the prototype's `"base+mod+mod"` string form (EXERCISE-CONFIGS.json)
  /// OR a structured `{ base, modifiers[] }` map (the locked schema form), so the
  /// validator's tests can read the real configs as-authored.
  factory CheckSpec.parse(Object? raw) {
    if (raw is Map) {
      final mods = (raw['modifiers'] as List<dynamic>? ?? const [])
          .map((m) => m as String)
          .toList();
      return CheckSpec(base: raw['base'] as String, modifiers: mods);
    }
    final parts = (raw as String).split('+').map((s) => s.trim()).toList();
    return CheckSpec(base: parts.first, modifiers: parts.skip(1).toList());
  }
}

/// The expected answer, a tagged one-of (SCHEMA-V2.md §2 `Answer`):
/// a single glyph, a whole word, or an ordered list of words (a sentence).
class AnswerSpec {
  /// `{ char, form }` for a glyph answer; null otherwise.
  final GlyphAnswer? glyph;

  /// The target word text (`"باب"`) for a word answer; null otherwise.
  final String? word;

  /// The ordered word list for a sentence answer (`["البابُ","كبير"]`); null
  /// otherwise.
  final List<String>? words;

  const AnswerSpec({this.glyph, this.word, this.words});

  factory AnswerSpec.fromJson(Map<String, dynamic> json) {
    final g = json['glyph'] as Map<String, dynamic>?;
    final w = json['word'] as Map<String, dynamic>?;
    final ws = json['words'] as List<dynamic>?;
    return AnswerSpec(
      glyph: g != null ? GlyphAnswer.fromJson(g) : null,
      word: w != null ? w['text'] as String? : null,
      words: ws?.map((e) => e as String).toList(),
    );
  }
}

/// A single-glyph expected answer: the character and its contextual form.
class GlyphAnswer {
  final String char;

  /// `isolated` | `initial` | `medial` | `final`.
  final String form;

  const GlyphAnswer({required this.char, required this.form});

  factory GlyphAnswer.fromJson(Map<String, dynamic> json) =>
      GlyphAnswer(char: json['char'] as String, form: json['form'] as String);
}

/// The validator-facing slice of an Exercise: just the check, the expected
/// answer, and the authored feedback map.
///
/// Plan 07-04 builds this from the real `Exercise` via `fromExercise`; tests and
/// Plan 07-03's GREEN suite build it from EXERCISE-CONFIGS.json via [fromJson].
class ExerciseSpec {
  final String id;

  /// The optional template label (`type` in the config). `'microDrill'` marks a
  /// just-this-part enrichment drill (18-02) whose verdict the validator scores by
  /// the spotlighted criterion ONLY (D-08 — "a dot drill never fails for a shaky
  /// bowl"). Null / any other value scores normally.
  final String? type;

  final CheckSpec? check;
  final AnswerSpec? expected;

  /// `{ pass: line, <mistakeId>: line }` — the AUTHORED keys the matched
  /// mistakeId must come from (`'pass'` reserved for the praise line, #1).
  final Map<String, String> feedback;

  /// The scorer criteria this exercise spotlights (18-02, `criteria` in the
  /// config — e.g. `['shape']` for the bowl drill). For a `type=='microDrill'`
  /// exercise the FIRST entry is the criterion that OWNS the pass/fail verdict
  /// (D-08); empty for a normal exercise (all criteria count).
  final List<String> criteria;

  const ExerciseSpec({
    required this.id,
    this.type,
    this.check,
    this.expected,
    this.feedback = const {},
    this.criteria = const [],
  });

  /// The single scorer criterion a `microDrill` scores by (D-08), or null when
  /// this is not a spotlighted drill / no criterion is authored.
  String? get spotlightCriterion =>
      type == 'microDrill' && criteria.isNotEmpty ? criteria.first : null;

  /// Builds the view straight from a decoded EXERCISE-CONFIGS.json entry.
  factory ExerciseSpec.fromJson(Map<String, dynamic> json) {
    final checkRaw = json['check'];
    final expectedRaw = json['expected'] as Map<String, dynamic>?;
    final feedbackRaw = json['feedback'] as Map<String, dynamic>?;
    return ExerciseSpec(
      id: json['id'] as String,
      type: json['type'] as String?,
      check: checkRaw != null ? CheckSpec.parse(checkRaw) : null,
      expected: expectedRaw != null ? AnswerSpec.fromJson(expectedRaw) : null,
      feedback:
          feedbackRaw?.map((k, v) => MapEntry(k, v as String)) ?? const {},
      criteria: [
        for (final c in (json['criteria'] as List<dynamic>? ?? const []))
          if (c is String) c,
      ],
    );
  }
}
