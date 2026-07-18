/// Curriculum Schema v2 — the `LetterUnit` section-ordering model (#8).
///
/// Pure immutable, no `lib/data/` or `lib/features/` import (Phase-02 rule).
/// A LetterUnit owns the ordered sections of a letter's lesson; `ProgressRibbon`
/// reads its position. Each section lists the exercise ids it contains, in
/// order. The 6 baa sections are:
///   meet · watchTrace · forms · words · listenWrite · mastery.
library;

/// One ordered section of a [LetterUnit]: an id and the exercise ids it holds.
class UnitSection {
  /// "meet" | "watchTrace" | "forms" | "words" | "listenWrite" | "mastery".
  final String id;

  /// the exercise ids in this section, in presentation order.
  final List<String> exercises;

  const UnitSection({required this.id, this.exercises = const []});

  factory UnitSection.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'] as List<dynamic>? ?? const [];
    return UnitSection(
      id: json['id'] as String? ?? '',
      exercises: rawExercises.map((e) => e as String).toList(),
    );
  }
}

/// Sequences the sections (and the exercises within each) for one letter.
/// Progression is section-by-section, gated by `policy.reps`, with ONE quiet
/// star at unit mastery (anti-gamification — see CLAUDE.md Decided).
class LetterUnit {
  final String letterId;
  final List<UnitSection> sections;

  /// The exercise ids this unit's UI actually presents AND records clean-reps
  /// for — the DATA declaration the scoped mastery gate derives from
  /// (finalization Lane A: the presented set comes from the unit CONFIG, never
  /// a letter-id literal in code). EMPTY (the default, and what the promotion
  /// pipeline emits) means "no scoped subset" — the mastery gate falls back to
  /// the FULL-graph `isMasteryMet` over the letter's own essential nodes. Only
  /// baa declares a subset today (its legacy 6-section shell surfaces 8 of the
  /// 16 graph essentials); a new letter needs NO code change and NO declaration.
  final List<String> presentedEssentials;

  const LetterUnit({
    required this.letterId,
    this.sections = const [],
    this.presentedEssentials = const [],
  });

  factory LetterUnit.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>? ?? const [];
    final rawPresented =
        json['presentedEssentials'] as List<dynamic>? ?? const [];
    return LetterUnit(
      letterId: json['letterId'] as String,
      sections: rawSections
          .map((s) => UnitSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      presentedEssentials: rawPresented.whereType<String>().toList(),
    );
  }
}
