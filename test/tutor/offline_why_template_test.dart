// Phase 18 — D-10 (offline WHY template).
//
// When there is no coach line (airplane mode / brain unavailable), the offline
// floor still explains WHY the next exercise was chosen: `authoredWhyLine` turns
// the pure `SelectionPolicy` `whyFacts` (`criterion:<name>`, `arcStep:<step>`)
// into one warm, child-facing sentence NAMING the criterion + arc step. It is the
// selection-side twin of `AuthoredFallbackBrain` — deterministic, zero model.

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('names the criterion and reflects the arc step (entry)', () {
    final line = authoredWhyLine(const ['criterion:shape', 'arcStep:entry']);
    expect(line, isNotEmpty);
    expect(line.toLowerCase(), contains('bowl'),
        reason: 'the `shape` criterion is spoken as "the bowl" (the tutor voice)');
  });

  test('the retryOriginal step invites another try', () {
    final line =
        authoredWhyLine(const ['criterion:shape', 'arcStep:retryOriginal']);
    expect(line.toLowerCase(), contains('again'));
  });

  test('names the dot criterion', () {
    final line = authoredWhyLine(const ['criterion:dot', 'arcStep:stepDown']);
    expect(line.toLowerCase(), contains('dot'));
  });

  test('empty whyFacts → empty line (nothing to justify)', () {
    expect(authoredWhyLine(const []), isEmpty);
  });
}
