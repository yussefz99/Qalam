// Journey letter-list provider (Phase 06, plan 06).
//
// Phase 03.1's static mock journey-progress provider lived here; plan 06-06
// retired it.
// The Journey screen now lights from the LIVE progression snapshot
// (progressionProvider in progression_providers.dart) and derives its 28
// node records from the curriculum itself — letters.json is the single
// source of truth for letter ids, glyphs, and display names (RESEARCH
// anti-pattern: no second hardcoded letter list anywhere).
//
// Hand-written provider (not @riverpod codegen) — same file-consistency
// policy as progression_providers.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/curriculum_repository.dart';
import '../models/letter.dart';

/// The 28 curriculum letters in introOrder — the Journey map's node list,
/// loaded from assets/curriculum/letters.json via [CurriculumRepository]
/// (cached for the app lifetime by the kept-alive repository provider).
///
/// Every Journey node id equals a letters.json id BY CONSTRUCTION, which is
/// what makes live mastery lighting correct (the 03.1 hardcoded list drifted
/// from canonical ids in 19 of 28 cases and silently never lit).
final journeyLettersProvider = FutureProvider<List<Letter>>(
  (ref) => ref.watch(curriculumRepositoryProvider).getLetters(),
);
