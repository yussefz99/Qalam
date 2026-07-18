// Finalization Lane A — taa (after alif+baa) mastery→progression proof.
// One case per FILE by design: see mastery_progression_harness.dart's header
// (a second testWidgets in the same process stalls forever on rootBundle).
import 'mastery_progression_harness.dart';

void main() {
  runMasteryProgressionCase(
    letter: 'taa',
    preMastered: const ['alif', 'baa'],
    target: 'taa.traceLetter.isolated',
  );
}
