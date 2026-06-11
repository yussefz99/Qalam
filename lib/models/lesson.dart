class LessonTitle {
  final String display;

  const LessonTitle({required this.display});

  factory LessonTitle.fromJson(Map<String, dynamic> json) =>
      LessonTitle(display: json['display'] as String);
}

class LessonItem {
  final String type; // "letter" | "exercise"
  final String ref; // references a letter.id or exercise.id

  const LessonItem({required this.type, required this.ref});

  factory LessonItem.fromJson(Map<String, dynamic> json) =>
      LessonItem(type: json['type'] as String, ref: json['ref'] as String);
}

class LessonUnlock {
  final List<String> requires; // lesson ids that must be complete first
  final String passRule; // "allItemsPassed"

  const LessonUnlock({required this.requires, required this.passRule});

  factory LessonUnlock.fromJson(Map<String, dynamic> json) {
    final raw = json['requires'] as List<dynamic>? ?? [];
    return LessonUnlock(
      requires: raw.map((r) => r as String).toList(),
      passRule: json['passRule'] as String,
    );
  }
}

class Lesson {
  final String id;
  final int order;
  final LessonTitle title;
  final List<LessonItem> items;
  final LessonUnlock unlock;

  /// Optional per-lesson tolerance ramp override (D-19), e.g.
  /// ["loose", "normal", "strict"]. Null when the lesson has no override —
  /// consumers fall back to the file-level defaultToleranceRamp.
  final List<String>? toleranceRamp;

  const Lesson({
    required this.id,
    required this.order,
    required this.title,
    required this.items,
    required this.unlock,
    this.toleranceRamp,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    // Defensive parse (D-19): absent or malformed toleranceRamp → null,
    // never throw — the owner's mother edits this data by hand.
    final rawRamp = json['toleranceRamp'];
    final ramp = rawRamp is List
        ? rawRamp.whereType<String>().toList()
        : null;
    return Lesson(
      id: json['id'] as String,
      order: json['order'] as int,
      title: LessonTitle.fromJson(json['title'] as Map<String, dynamic>),
      items: rawItems
          .map((i) => LessonItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      unlock: LessonUnlock.fromJson(json['unlock'] as Map<String, dynamic>),
      toleranceRamp: ramp,
    );
  }
}
