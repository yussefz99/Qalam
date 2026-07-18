// WR-03 regression (Phase-19 code review) — a listen-and-write mount must not
// play two audio streams at once.
//
// On mounting a `[say, audio]` node (e.g. baa.writeWord.dictation) two
// post-frame callbacks used to fire in the SAME frame: the scaffold's
// `_speakInstructionThenRelease` spoke the say line through the TTS seam AND
// the hero audio card (PromptHeader D-07) auto-played the word clip through
// `onAudioTap` — the child heard both simultaneously on the one exercise type
// where hearing the word clearly IS the question (the Phase-07 double-Hear
// device bug is the recorded precedent for this overlap class).
//
// The fix: the mount auto-speak is SUPPRESSED when the lone visual stimulus is
// the auto-playing hero AudioPart — the clip is the audible instruction; the
// say line stays as the instruction bar's TEXT (readable with sound off, D-01)
// and a DELIBERATE bar tap still re-speaks it (UI-SPEC: the spoken line is
// reinforcement). Mounted through the LIVE `presentGraphExercise` seam — never
// a bare scaffold (the Phase-15 dead-wire lesson). NOTE: the two channels are
// separately mocked here — the real no-overlap behaviour must also be verified
// on device.

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/curriculum/child_model_snapshot.dart';
import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/graph_position_repository.dart';
import 'package:qalam/features/letter_unit/exercise_presenter.dart';
import 'package:qalam/features/letter_unit/letter_unit_screen.dart'
    show LetterUnitData;
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/models/word.dart';
import 'package:qalam/tutor/child_model_providers.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart'
    show curriculumGraphProvider;
import 'package:qalam/tutor/tts_coach_speaker.dart';
import 'package:qalam/providers/tts_providers.dart';

const _sayLine = 'Listen to the word, then write it in the box.';

CurriculumGraph _loadGraph() {
  final raw = json.decode(
    File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return CurriculumGraph.fromJson(raw);
}

/// A CoachSpeaker spy — records every `speak` so the test can prove the say
/// line is NOT auto-spoken on a hero-audio mount but IS spoken on a bar tap.
class _SpyCoachSpeaker implements CoachSpeaker {
  final List<String> speakCalls = <String>[];

  @override
  Future<void> speak(String line) async => speakCalls.add(line);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _NullPositionRepo implements GraphPositionRepository {
  @override
  Future<GraphPosition?> getPosition(String letterId,
          {required int childProfileId}) async =>
      null;

  @override
  Future<void> setPosition(GraphPosition position) async {}
}

Letter _baa() {
  const body = StrokeSpec(
    order: 1,
    label: 'boat',
    type: 'curve',
    points: [
      [0.2, 0.4],
      [0.5, 0.6],
      [0.8, 0.4],
    ],
    direction: 'rightToLeft',
  );
  const dot = StrokeSpec(
    order: 2,
    label: 'dot',
    type: 'dot',
    points: [
      [0.5, 0.75],
    ],
    direction: 'none',
  );
  return Letter(
    id: 'baa',
    char: 'ب',
    name: const LetterName(ar: 'باء', display: 'baa'),
    introOrder: 2,
    forms: const LetterForms(
        isolated: 'ب', initial: 'بـ', medial: 'ـبـ', final_: 'ـب'),
    referenceStrokes: const [body, dot],
    cleanRepsToAdvance: 1,
    commonMistakes: const [],
    mistakesStatus: 'placeholder',
    signedOff: false,
    contextualForms: const {'isolated': Form(referenceStrokes: [body, dot])},
  );
}

/// The listen-and-write shape — the say line + a LONE AudioPart stimulus, which
/// PromptHeader renders as the auto-playing hero card (D-07).
Exercise _listenAndWrite() => const Exercise(
      id: 'baa.writeWord.dictation',
      type: 'writeWord',
      skill: 'spelling',
      prompt: [
        SayPart(_sayLine),
        AudioPart('snd.baab'),
      ],
      surface: Surface(mode: 'write', unit: 'word'),
      expected: Answer(word: WordAnswer('باب')),
      check: Check(base: 'word'),
      feedback: {'pass': 'أحسنت'},
      signedOff: false,
    );

LetterUnitData _data(Exercise exercise) => LetterUnitData(
      unit: LetterUnit(
        letterId: 'baa',
        sections: [
          UnitSection(id: 'listenWrite', exercises: [exercise.id]),
        ],
      ),
      letter: _baa(),
      exercises: {exercise.id: exercise},
      words: const <Word>[],
    );

Future<({_SpyCoachSpeaker tts, List<String> clips})> _pumpNode(
  WidgetTester tester,
  Exercise exercise,
) async {
  final spy = _SpyCoachSpeaker();
  final clips = <String>[];
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
  addTearDown(db.close);
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        graphPositionRepositoryProvider.overrideWithValue(_NullPositionRepo()),
        curriculumGraphProvider.overrideWith((ref) async => _loadGraph()),
        childModelProvider
            .overrideWith((ref) async => ChildModelSnapshot.empty()),
        ttsCoachSpeakerProvider.overrideWithValue(spy),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: presentGraphExercise(
            data: _data(exercise),
            exerciseId: exercise.id,
            onNodeResult: (_) {},
            onNext: () {},
            onAudioTap: clips.add,
            presentEpoch: 1,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (tts: spy, clips: clips);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
      'a listen-and-write mount auto-plays ONLY the hero clip — the say-line '
      'TTS is suppressed (no two simultaneous audio streams, WR-03)',
      (tester) async {
    final seams = await _pumpNode(tester, _listenAndWrite());

    // The hero card auto-played the dictation clip once (D-07).
    expect(seams.clips, ['snd.baab'],
        reason: 'the word clip is the audible instruction — it auto-plays '
            'exactly once on mount');
    // The say line was NOT spoken over it in the same frame.
    expect(seams.tts.speakCalls, isNot(contains(_sayLine)),
        reason: 'the mount auto-speak is suppressed when the lone visual is '
            'the auto-playing hero audio card — the child must hear the '
            'dictation word clearly (WR-03)');
  });

  testWidgets(
      'the instruction bar still re-speaks the say line on a DELIBERATE tap '
      '(the spoken line stays available as reinforcement)', (tester) async {
    final seams = await _pumpNode(tester, _listenAndWrite());
    seams.tts.speakCalls.clear();

    await tester.tap(find.byKey(const Key('instructionBar')));
    await tester.pumpAndSettle();

    expect(seams.tts.speakCalls, contains(_sayLine),
        reason: 'suppression is scoped to the MOUNT auto-speak only — a bar '
            'tap is a deliberate child action and must still re-hear the '
            'instruction (QP-02)');
  });
}
