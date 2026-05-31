import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/models/lesson.dart';

void main() {
  group('Lesson.fromJson', () {
    final lesson01Json = {
      'id': 'lesson_01',
      'order': 1,
      'title': {'display': 'Lesson 1'},
      'items': [
        {'type': 'letter', 'ref': 'alif'},
      ],
      'unlock': {'requires': [], 'passRule': 'allItemsPassed'},
    };

    test('lesson_01 shape deserialises all fields', () {
      final lesson = Lesson.fromJson(lesson01Json);

      expect(lesson.id, 'lesson_01');
      expect(lesson.order, 1);
      expect(lesson.title.display, 'Lesson 1');
      expect(lesson.items.length, 1);
      expect(lesson.items[0].ref, 'alif');
      expect(lesson.unlock.requires.isEmpty, true);
      expect(lesson.unlock.passRule, 'allItemsPassed');
    });

    test('LessonItem.fromJson maps type and ref as non-null strings', () {
      final itemJson = {'type': 'letter', 'ref': 'alif'};

      final item = LessonItem.fromJson(itemJson);

      expect(item.type, 'letter');
      expect(item.ref, 'alif');
    });

    test('LessonUnlock with empty requires deserialises correctly', () {
      final unlockJson = {'requires': [], 'passRule': 'allItemsPassed'};

      final unlock = LessonUnlock.fromJson(unlockJson);

      expect(unlock.requires.isEmpty, true);
      expect(unlock.passRule, 'allItemsPassed');
    });
  });
}
