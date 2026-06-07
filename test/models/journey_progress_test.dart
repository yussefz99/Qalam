import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/models/journey_progress.dart';

void main() {
  group('JourneyNodeState.compute', () {
    const masteredIds = {'alif', 'baa', 'taa'};
    const currentId = 'thaa';

    test('returns complete when letterId is in masteredIds', () {
      expect(
        JourneyNodeState.compute('alif', masteredIds, currentId),
        JourneyNodeState.complete,
      );
    });

    test('returns current when letterId equals currentId', () {
      expect(
        JourneyNodeState.compute('thaa', masteredIds, currentId),
        JourneyNodeState.current,
      );
    });

    test('returns future when letterId is neither mastered nor current', () {
      expect(
        JourneyNodeState.compute('jeem', masteredIds, currentId),
        JourneyNodeState.future,
      );
    });

    test('returns locked when letterId is an empty string (edge guard)', () {
      expect(
        JourneyNodeState.compute('', masteredIds, currentId),
        JourneyNodeState.locked,
      );
    });
  });

  group('JourneyProgress', () {
    test('const constructor stores masteredIds and currentId', () {
      const progress = JourneyProgress(
        masteredIds: {'alif', 'baa'},
        currentId: 'taa',
      );
      expect(progress.masteredIds, containsAll(['alif', 'baa']));
      expect(progress.currentId, 'taa');
    });

    test('JourneyProgress.empty() constructs with empty set and empty string', () {
      final empty = JourneyProgress.empty();
      expect(empty.masteredIds, isEmpty);
      expect(empty.currentId, '');
    });
  });
}
