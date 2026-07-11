/// Curriculum Schema v2 — the question-config data spine.
///
/// Pure immutable models mirroring `SCHEMA-V2.md §2` (the LOCKED shape derived
/// from the validated Claude Design baa handoff). These are the contracts every
/// later Phase-07 plan reads — the 5 exercise components, the 6 Letter-Unit
/// sections, and the validators all consume these typed objects.
///
/// **Purity rule (Phase-02 decision):** model files import NOTHING from
/// `lib/data/` or `lib/features/`. They hold curriculum content only — no child
/// PII, no stroke capture, no progress. The Firestore `{x,y}` point codec lives
/// in `lib/data/firestore_curriculum_codec.dart`, not here.
///
/// Every `fromJson` uses the same defensive null-safe idiom as `letter.dart`
/// (`as String?`, `?? default`) so a partially-authored or placeholder config
/// (content TBD, `signedOff:false`) parses without throwing.
library;

/// One question configuration. `surface`/`expected`/`check`/`feedback` are all
/// null for a `teachCard` (a SUPPORT card that only teaches — see SCHEMA-V2 §2).
class Exercise {
  final String id;

  /// Optional template label (#7) — authoring UI + analytics. The type is
  /// otherwise emergent from `surface` + `check`.
  final String? type;

  /// "formation" | "recall" | "spelling" | "grammar" | "syntax" | "comprehension".
  /// A plain String (not an enum) to keep the JSON legible — same rationale as
  /// `StrokeSpec.type` in letter.dart.
  final String skill;

  /// Ordered prompt parts (mascot line, audio, image, text, rule, forms strip).
  final List<PromptPart> prompt;

  final Surface? surface;
  final Answer? expected;
  final Check? check;

  /// `{ pass: praiseLine, <mistakeId>: fixLine }` — the reserved key `pass`
  /// holds the praise line (#1); all other keys are mistakeIds. Consumers read
  /// `feedback['pass']`. Kept as a raw map; null for teachCard.
  final Map<String, String>? feedback;

  /// `{ reps?, noFail? }` — per-exercise progression policy (#2, #10).
  final Policy? policy;

  /// false until the owner's mother signs off the authored content.
  final bool signedOff;

  /// The scorer criteria this exercise spotlights (18-02, `criteria` in the
  /// config — e.g. `['shape']` for the bowl drill). For a `type=='microDrill'`
  /// exercise the FIRST entry is the criterion that OWNS the pass/fail verdict
  /// (D-08); empty for a normal exercise. Carried through to the validator's
  /// `ExerciseSpec` so a live micro-drill scores by its target criterion only.
  final List<String> criteria;

  const Exercise({
    required this.id,
    this.type,
    required this.skill,
    required this.prompt,
    this.surface,
    this.expected,
    this.check,
    this.feedback,
    this.policy,
    required this.signedOff,
    this.criteria = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final rawPrompt = json['prompt'] as List<dynamic>? ?? const [];
    final surfaceJson = json['surface'] as Map<String, dynamic>?;
    final expectedJson = json['expected'] as Map<String, dynamic>?;
    final feedbackJson = json['feedback'] as Map<String, dynamic>?;
    final policyJson = json['policy'] as Map<String, dynamic>?;

    return Exercise(
      id: json['id'] as String,
      type: json['type'] as String?,
      skill: json['skill'] as String,
      prompt: rawPrompt
          .map((p) => PromptPart.fromJson(p as Map<String, dynamic>))
          .toList(),
      surface: surfaceJson != null ? Surface.fromJson(surfaceJson) : null,
      expected: expectedJson != null ? Answer.fromJson(expectedJson) : null,
      // `check` may be a String ("base+modifier") or a structured map. null for
      // teachCard. Check.fromJson accepts both for forward-compat (#9).
      check: json.containsKey('check') && json['check'] != null
          ? Check.fromJson(json['check'] as Object)
          : null,
      feedback: feedbackJson != null
          ? feedbackJson.map((k, v) => MapEntry(k, v as String))
          : null,
      policy: policyJson != null ? Policy.fromJson(policyJson) : null,
      signedOff: json['signedOff'] as bool? ?? false,
      criteria: [
        for (final c in (json['criteria'] as List<dynamic>? ?? const []))
          if (c is String) c,
      ],
    );
  }
}

/// A single prompt element, discriminated by the `kind` field. Abstract base;
/// each concrete kind round-trips only its own fields. An unknown `kind` parses
/// to [UnknownPart] (defensive — never throws on forward-compat content).
abstract class PromptPart {
  /// "say" | "audio" | "image" | "text" | "rule" | "forms".
  final String kind;

  const PromptPart(this.kind);

  factory PromptPart.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String?;
    switch (kind) {
      case 'say':
        return SayPart.fromJson(json);
      case 'audio':
        return AudioPart.fromJson(json);
      case 'image':
        return ImagePart.fromJson(json);
      case 'text':
        return TextPart.fromJson(json);
      case 'rule':
        return RulePart.fromJson(json);
      case 'forms':
        return FormsPart.fromJson(json);
      default:
        return UnknownPart(kind ?? 'unknown');
    }
  }
}

/// `{ kind:"say", line }` — the mascot's spoken/printed prompt line.
class SayPart extends PromptPart {
  final String line;
  const SayPart(this.line) : super('say');
  factory SayPart.fromJson(Map<String, dynamic> json) =>
      SayPart(json['line'] as String? ?? '');
}

/// `{ kind:"audio", audioId }` — a play button bound to an audio asset id.
class AudioPart extends PromptPart {
  final String audioId;
  const AudioPart(this.audioId) : super('audio');
  factory AudioPart.fromJson(Map<String, dynamic> json) =>
      AudioPart(json['audioId'] as String? ?? '');
}

/// `{ kind:"image", imageId, caption? }` — a picture stub + optional caption.
class ImagePart extends PromptPart {
  final String imageId;
  final String? caption;
  const ImagePart(this.imageId, {this.caption}) : super('image');
  factory ImagePart.fromJson(Map<String, dynamic> json) => ImagePart(
        json['imageId'] as String? ?? '',
        caption: json['caption'] as String?,
      );
}

/// `{ kind:"text", text, gaps?, reveal?, loose? }` — an Arabic prompt string.
/// `reveal:"thenHide"` is the copy (نسخ) flash-then-hide flag; `loose:true` is
/// the connect (وصل) spaced-letters flag (#5). `gaps` mark blank slots.
class TextPart extends PromptPart {
  final String text;
  final List<Gap> gaps;

  /// "thenHide" when the word is shown for a moment then hidden, else null.
  final String? reveal;

  /// true when the letters are presented spaced apart (the connect task).
  final bool loose;

  const TextPart({
    required this.text,
    this.gaps = const [],
    this.reveal,
    this.loose = false,
  }) : super('text');

  factory TextPart.fromJson(Map<String, dynamic> json) {
    final rawGaps = json['gaps'] as List<dynamic>? ?? const [];
    return TextPart(
      text: json['text'] as String? ?? '',
      gaps: rawGaps
          .map((g) => Gap.fromJson(g as Map<String, dynamic>))
          .toList(),
      reveal: json['reveal'] as String?,
      loose: json['loose'] as bool? ?? false,
    );
  }
}

/// `{ kind:"rule", label }` — the grammar rule chip («مثنى/جمع/عكس»).
class RulePart extends PromptPart {
  final String label;
  const RulePart(this.label) : super('rule');
  factory RulePart.fromJson(Map<String, dynamic> json) =>
      RulePart(json['label'] as String? ?? '');
}

/// `{ kind:"forms", char, forms }` — the teachCard four-forms strip (#6).
class FormsPart extends PromptPart {
  final String char;

  /// FormName entries: "isolated" | "initial" | "medial" | "final".
  final List<String> forms;
  const FormsPart({required this.char, required this.forms}) : super('forms');
  factory FormsPart.fromJson(Map<String, dynamic> json) {
    final rawForms = json['forms'] as List<dynamic>? ?? const [];
    return FormsPart(
      char: json['char'] as String? ?? '',
      forms: rawForms.map((f) => f as String).toList(),
    );
  }
}

/// Fallback for an unrecognised `kind` — preserves forward-compat without
/// throwing. Carries no payload beyond the kind discriminator.
class UnknownPart extends PromptPart {
  const UnknownPart(super.kind);
}

/// `{ kind:"letter"|"word", index }` — a blank slot inside a [TextPart].
class Gap {
  /// "letter" | "word".
  final String kind;
  final int index;
  const Gap({required this.kind, required this.index});
  factory Gap.fromJson(Map<String, dynamic> json) => Gap(
        kind: json['kind'] as String? ?? 'letter',
        index: json['index'] as int? ?? 0,
      );
}

/// The write/trace canvas configuration.
class Surface {
  /// "trace" | "write".
  final String mode;

  /// "glyph" | "word" | "sentence".
  final String unit;

  /// FormName of the dotted guide shown, when any.
  final String? guideForm;

  /// the animated "Watch me" demo flag (#3).
  final bool demo;

  /// pre-filled word + blank cell for completeWord.
  final Given? given;

  const Surface({
    required this.mode,
    required this.unit,
    this.guideForm,
    this.demo = false,
    this.given,
  });

  factory Surface.fromJson(Map<String, dynamic> json) {
    final givenJson = json['given'] as Map<String, dynamic>?;
    return Surface(
      mode: json['mode'] as String? ?? 'write',
      unit: json['unit'] as String? ?? 'glyph',
      guideForm: json['guideForm'] as String?,
      demo: json['demo'] as bool? ?? false,
      given: givenJson != null ? Given.fromJson(givenJson) : null,
    );
  }
}

/// `{ word, blankIndex }` — the pre-filled word and the index of its blank cell.
class Given {
  final String word;
  final int blankIndex;
  const Given({required this.word, required this.blankIndex});
  factory Given.fromJson(Map<String, dynamic> json) => Given(
        word: json['word'] as String? ?? '',
        blankIndex: json['blankIndex'] as int? ?? 0,
      );
}

/// The expected answer — a tagged one-of:
///   `{ glyph:{char,form} }` | `{ word:{text} }` | `{ words:[text...] }`.
/// Exactly one of [glyph]/[word]/[words] is non-null.
class Answer {
  final GlyphAnswer? glyph;
  final WordAnswer? word;
  final List<String>? words;

  const Answer({this.glyph, this.word, this.words});

  factory Answer.fromJson(Map<String, dynamic> json) {
    final glyphJson = json['glyph'] as Map<String, dynamic>?;
    final wordJson = json['word'] as Map<String, dynamic>?;
    final rawWords = json['words'] as List<dynamic>?;
    return Answer(
      glyph: glyphJson != null ? GlyphAnswer.fromJson(glyphJson) : null,
      word: wordJson != null ? WordAnswer.fromJson(wordJson) : null,
      words: rawWords?.map((w) => w as String).toList(),
    );
  }
}

/// `{ char, form }` — the expected single glyph and its positional form.
class GlyphAnswer {
  final String char;
  final String form;
  const GlyphAnswer({required this.char, required this.form});
  factory GlyphAnswer.fromJson(Map<String, dynamic> json) => GlyphAnswer(
        char: json['char'] as String? ?? '',
        form: json['form'] as String? ?? 'isolated',
      );
}

/// `{ text }` — the expected whole word.
class WordAnswer {
  final String text;
  const WordAnswer(this.text);
  factory WordAnswer.fromJson(Map<String, dynamic> json) =>
      WordAnswer(json['text'] as String? ?? '');
}

/// The structured validator spec (#9). Parses BOTH the string grammar
/// ("base+modifier+modifier") and a structured `{ base, modifiers[] }` map.
class Check {
  /// "glyph" | "sequence" | "order".
  final String base;

  /// any of "positionalForm" | "joinContinuity" | "transformRule"
  /// (or "sequence" when composed onto an "order" base, e.g. "order+sequence").
  final List<String> modifiers;

  const Check({required this.base, this.modifiers = const []});

  /// Accepts a String ("base+mod+mod") or a structured Map
  /// (`{ base, modifiers: [...] }`) — forward-compat (#9).
  factory Check.fromJson(Object raw) {
    if (raw is String) return Check.parse(raw);
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final rawMods = map['modifiers'] as List<dynamic>? ?? const [];
      return Check(
        base: map['base'] as String? ?? 'glyph',
        modifiers: rawMods.map((m) => m as String).toList(),
      );
    }
    return const Check(base: 'glyph');
  }

  /// Parses the "base+mod+mod" string: first token is the base, the rest are
  /// modifiers. Whitespace around `+` is tolerated.
  factory Check.parse(String raw) {
    final parts =
        raw.split('+').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return const Check(base: 'glyph');
    return Check(base: parts.first, modifiers: parts.sublist(1));
  }
}

/// `{ reps?, noFail? }` — per-exercise progression policy (#2, #10).
class Policy {
  /// clean-rep count to advance (owner-tunable; the rep-count TBD lives here).
  final int? reps;

  /// when true the scorer runs but never fails the child (letterMaze, #10).
  final bool? noFail;

  const Policy({this.reps, this.noFail});

  factory Policy.fromJson(Map<String, dynamic> json) => Policy(
        reps: (json['reps'] as num?)?.toInt(),
        noFail: json['noFail'] as bool?,
      );
}
