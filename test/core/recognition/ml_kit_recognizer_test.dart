// Unit tests for MlKitRecognizer (Plan 04-03, Task 1).
//
// Real ML Kit recognition needs a device + the downloaded model, so these tests
// exercise the DEVICE-INDEPENDENT logic: the pure Ink-building and candidate-
// mapping helpers, plus the `identify` orchestration over a MOCKED
// DigitalInkRecognizer (mocktail). They prove the seam REPORTS identity and
// degrades to "no opinion" on empty/failed recognition — and that it never
// returns a pass/fail verdict (D-04 advisory-only; that decision lives in
// scoreLetter, not here).

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qalam/core/recognition/handwriting_recognizer.dart';
import 'package:qalam/core/recognition/ml_kit_recognizer.dart';

class _MockDigitalInkRecognizer extends Mock implements DigitalInkRecognizer {}

class _FakeInk extends Fake implements Ink {}

/// A small multi-stroke baa: a body line plus a single dot.
List<List<List<double>>> baaStrokes() => [
      [
        [10.0, 50.0],
        [30.0, 48.0],
        [50.0, 50.0],
      ],
      [
        [30.0, 70.0],
      ],
    ];

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeInk());
  });

  group('inkFromStrokes — pure conversion', () {
    test('each child stroke becomes one ML Kit Stroke', () {
      final ink = inkFromStrokes(baaStrokes());
      expect(ink.strokes.length, equals(2));
      expect(ink.strokes[0].points.length, equals(3));
      expect(ink.strokes[1].points.length, equals(1));
    });

    test('each [x, y] pair becomes a StrokePoint with monotonic t', () {
      final ink = inkFromStrokes(baaStrokes());
      final first = ink.strokes[0].points.first;
      expect(first.x, equals(10.0));
      expect(first.y, equals(50.0));
      // Timestamps increase monotonically across the whole letter.
      final allT = [
        for (final s in ink.strokes)
          for (final p in s.points) p.t,
      ];
      for (var i = 1; i < allT.length; i++) {
        expect(allT[i], greaterThan(allT[i - 1]));
      }
    });

    test('malformed points (fewer than 2 coords) are skipped defensively', () {
      final ink = inkFromStrokes([
        [
          [10.0, 50.0],
          [99.0], // malformed — dropped
          [30.0, 48.0],
        ],
      ]);
      expect(ink.strokes.single.points.length, equals(2));
    });
  });

  group('resultFromCandidates — pure mapping', () {
    test('top candidate maps to RecognitionResult.topCandidate', () {
      final result = resultFromCandidates([
        RecognitionCandidate(text: 'ب', score: -1.0),
        RecognitionCandidate(text: 'ت', score: -0.5),
      ]);
      expect(result.topCandidate, equals('ب'));
      expect(result.confidence, greaterThan(0.0));
    });

    test('empty candidate list maps to null candidate, confidence 0', () {
      final result = resultFromCandidates(const []);
      expect(result.topCandidate, isNull);
      expect(result.confidence, equals(0.0));
    });

    test('empty-text top candidate degrades to no opinion', () {
      final result = resultFromCandidates([
        RecognitionCandidate(text: '', score: -1.0),
      ]);
      expect(result.topCandidate, isNull);
      expect(result.confidence, equals(0.0));
    });
  });

  group('MlKitRecognizer.identify — orchestration over a mocked recognizer', () {
    test('implements the HandwritingRecognizer seam', () {
      expect(MlKitRecognizer(recognizer: _MockDigitalInkRecognizer()),
          isA<HandwritingRecognizer>());
    });

    test('a recognized candidate flows through to RecognitionResult', () async {
      final mock = _MockDigitalInkRecognizer();
      when(() => mock.recognize(any())).thenAnswer(
        (_) async => [RecognitionCandidate(text: 'ب', score: -1.0)],
      );
      final sut = MlKitRecognizer(recognizer: mock);

      final result = await sut.identify(baaStrokes());

      expect(result.topCandidate, equals('ب'));
      expect(result.confidence, greaterThan(0.0));
    });

    test('empty input → no opinion, recognizer not even called', () async {
      final mock = _MockDigitalInkRecognizer();
      final sut = MlKitRecognizer(recognizer: mock);

      final result = await sut.identify(const []);

      expect(result.topCandidate, isNull);
      expect(result.confidence, equals(0.0));
      verifyNever(() => mock.recognize(any()));
    });

    test('a thrown recognition degrades to no opinion (never rethrows) — D-04',
        () async {
      final mock = _MockDigitalInkRecognizer();
      when(() => mock.recognize(any())).thenThrow(Exception('model not present'));
      final sut = MlKitRecognizer(recognizer: mock);

      final result = await sut.identify(baaStrokes());

      // Graceful: a null candidate / confidence 0 so the geometric pass stands.
      expect(result.topCandidate, isNull);
      expect(result.confidence, equals(0.0));
    });

    test('empty recognition result → no opinion (graceful)', () async {
      final mock = _MockDigitalInkRecognizer();
      when(() => mock.recognize(any())).thenAnswer((_) async => []);
      final sut = MlKitRecognizer(recognizer: mock);

      final result = await sut.identify(baaStrokes());

      expect(result.topCandidate, isNull);
      expect(result.confidence, equals(0.0));
    });
  });
}
