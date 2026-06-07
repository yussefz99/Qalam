// Journey progress Riverpod provider (Phase 03.1, plan 01).
//
// Provides mock journey progress data for Wave 2 (plan 03.1-02) to build the
// Journey Map screen against. No real DB wiring until Phase 6 — this provider
// returns a static snapshot baked at compile time.
//
// Mock state (D-06): first 3 letters mastered (alif, baa, taa), letter 4
// (thaa) is current, letters 5-28 are future.
//
// Phase 6 swaps this provider for a live ProgressRepository integration;
// the screen itself (journey_screen.dart) does not change — only this provider.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/journey_progress.dart';

part 'journey_providers.g.dart';

/// Static mock journey progress provider.
///
/// Returns the Phase 03.1 demo state: alif, baa, taa mastered; thaa current.
/// keepAlive: true — held for the app lifetime (same pattern as curriculumRepository).
@Riverpod(keepAlive: true)
JourneyProgress mockJourneyProgress(Ref ref) {
  return const JourneyProgress(
    masteredIds: {'alif', 'baa', 'taa'},
    currentId: 'thaa',
  );
}
