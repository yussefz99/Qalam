/// Curriculum Schema v2 — the vocab `Word` model (SCHEMA-V2.md §2).
///
/// Pure immutable, no `lib/data/` or `lib/features/` import (Phase-02 rule).
/// `{ id, text, audio, image, gloss:{en}, letters:[letterId...] }`.
library;

/// A vocabulary word used across exercises (e.g. باب "door").
class Word {
  final String id;

  /// The Arabic word, e.g. "باب".
  final String text;

  /// audio asset id (placeholder until the owner records it).
  final String? audio;

  /// image asset id (placeholder until art lands).
  final String? image;

  /// English gloss keyed by language: `{ en: "door" }`.
  final Map<String, String> gloss;

  /// the letter ids this word is composed of (refs into `letters/`).
  final List<String> letters;

  const Word({
    required this.id,
    required this.text,
    this.audio,
    this.image,
    this.gloss = const {},
    this.letters = const [],
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    final glossJson = json['gloss'] as Map<String, dynamic>?;
    final rawLetters = json['letters'] as List<dynamic>? ?? const [];
    return Word(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      audio: json['audio'] as String?,
      image: json['image'] as String?,
      gloss: glossJson != null
          ? glossJson.map((k, v) => MapEntry(k, v as String))
          : const {},
      letters: rawLetters.map((l) => l as String).toList(),
    );
  }
}
