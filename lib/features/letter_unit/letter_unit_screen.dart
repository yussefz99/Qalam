// LetterUnitScreen — the 6-section unit SHELL for the baa Letter Unit
// (Plan 07-06). Reproduces the prototype `index.html` shell 1:1: a top app bar
// (back / close + the R→L ProgressRibbon of 6 dots + the kid chip) over a body
// that hosts the CURRENT section widget. The 6 sections — Meet · Watch&Trace ·
// Forms · Words · Listen&Write · Mastery — are sequenced by the
// [LetterUnitController] (the prototype's `go(n)` + `visited`), R→L, and the
// unit is RESUME-AWARE: re-entering returns to where the child left off.
//
// CONFIG-DRIVEN: the shell loads the section order from `getUnit(letterId)` and
// feeds each section the baa Exercise config(s) it needs (from `getExercises()`)
// + the vocab Words (from `getWords()`). It builds NO bespoke exercise UI — the
// sections render entirely through the 07-04 engine components.
//
// GRACEFUL: every load degrades calmly (a quiet "preparing" state, never a raw
// error to the child); a missing exercise id falls back so a section is always
// navigable. The unknown-letter degrade is handled at the route (app_router).
//
// ANTI-GAMIFICATION: the ProgressRibbon is position-only (never gold); Mastery
// shows the one quiet star via the reused MasteryCelebration. No totals.

import 'dart:async';

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../data/curriculum_repository.dart';
import '../../models/exercise.dart';
import '../../models/letter.dart';
import '../../providers/audio_providers.dart';
import '../../services/model_download_service.dart';
import '../../models/letter_unit.dart';
import '../../models/word.dart';
import '../../theme/qalam_tokens.dart';
import '../../theme/text_styles.dart';
import '../../tutor/coach_warmup.dart';
import '../../tutor/exercise_selector_provider.dart';
import '../../tutor/tutor_providers.dart';
import '../../widgets/arabic_text.dart';
import 'exercise_presenter.dart';
import 'letter_unit_controller.dart';
import 'sections/forms_section.dart';
import 'sections/listen_write_section.dart';
import 'sections/mastery_section.dart';
import 'sections/meet_section.dart';
import 'sections/watch_trace_section.dart';
import 'sections/words_section.dart';

/// Everything the shell needs to render every section of a letter unit: the
/// ordered [unit], the [letter], an id→Exercise map, and the vocab [words].
class LetterUnitData {
  const LetterUnitData({
    required this.unit,
    required this.letter,
    required this.exercises,
    required this.words,
  });

  final LetterUnit unit;
  final Letter letter;
  final Map<String, Exercise> exercises;
  final List<Word> words;

  Exercise? exercise(String id) => exercises[id];
}

/// Loads the [LetterUnitData] for [letterId] (Firestore-first via the repo, with
/// the bundled-seed fallback). Returns null when no unit/letter exists for that
/// id — the screen degrades to a calm "preparing" state and the route degrades
/// the unknown id upstream.
final letterUnitDataProvider =
    FutureProvider.family<LetterUnitData?, String>((ref, letterId) async {
  final repo = ref.watch(curriculumRepositoryProvider);
  final unit = await repo.getUnit(letterId);
  final letter = await repo.getLetter(letterId);
  if (unit == null || letter == null) return null;
  final exercises = await repo.getExercises();
  final words = await repo.getWords();
  return LetterUnitData(
    unit: unit,
    letter: letter,
    exercises: {for (final e in exercises) e.id: e},
    words: words,
  );
});

/// Static chrome copy for the unit shell (English defaults; call site passes
/// l10n — keeps the widget test independent of `flutter gen-l10n`).
class LetterUnitStrings {
  const LetterUnitStrings({
    this.unitLabel = 'Letter Unit',
    this.back = 'Back',
    this.close = 'Close unit',
    this.preparing = 'Getting your letter ready…',
  });

  final String unitLabel;
  final String back;
  final String close;
  final String preparing;
}

/// The 6-section baa Letter Unit shell. Pass the [letterId] (and an optional
/// [resumeSection] to force a starting section); the unit otherwise resumes
/// where the child left off.
class LetterUnitScreen extends ConsumerWidget {
  const LetterUnitScreen({
    super.key,
    required this.letterId,
    this.resumeSection,
    this.strings = const LetterUnitStrings(),
    this.onExit,
  });

  /// Which letter's unit to open (validated upstream at the route).
  final String letterId;

  /// Optional forced starting section (else the persisted resume position).
  final int? resumeSection;

  /// Shell chrome copy.
  final LetterUnitStrings strings;

  /// Called when the child taps back from section 0 or closes the unit; when
  /// null the shell pops the route (or goes home if it cannot pop).
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kick off the ML Kit Arabic model download the moment the unit opens, so the
    // word-recognition scorer (Words / Listen & Write sections) is ready by the
    // time the child gets there — best-effort, never blocks (D-05).
    ref.watch(modelDownloadServiceProvider);
    final async = ref.watch(letterUnitDataProvider(letterId));
    return Scaffold(
      backgroundColor: QalamTokens.parchment,
      body: SafeArea(
        child: async.when(
          data: (data) {
            if (data == null) return _Preparing(label: strings.preparing);
            return _UnitShell(
              data: data,
              resumeSection: resumeSection,
              strings: strings,
              onExit: onExit,
            );
          },
          // Loading / error degrade to the same calm "preparing" panel — a raw
          // error is NEVER shown to the child (UI-SPEC error contract).
          loading: () => _Preparing(label: strings.preparing),
          error: (_, _) => _Preparing(label: strings.preparing),
        ),
      ),
    );
  }
}

/// The loaded shell: app bar (back/close + R→L ribbon + kid chip) over the
/// current section. Drives section sequencing via the [LetterUnitController].
class _UnitShell extends ConsumerStatefulWidget {
  const _UnitShell({
    required this.data,
    required this.resumeSection,
    required this.strings,
    required this.onExit,
  });

  final LetterUnitData data;
  final int? resumeSection;
  final LetterUnitStrings strings;
  final VoidCallback? onExit;

  @override
  ConsumerState<_UnitShell> createState() => _UnitShellState();
}

class _UnitShellState extends ConsumerState<_UnitShell> {
  late final String _letterId = widget.data.unit.letterId;

  /// The graph node the exercise PRESENTER is currently rendering (18-07 Task 3).
  /// Null → the shell renders the legacy `_section(index)` walk. Non-null → the
  /// shell renders `presentGraphExercise(_presentedId)`. It changes ONLY on the
  /// pass/continue CTA (never at verdict time), so the feedback moment survives.
  String? _presentedId;

  /// 18-12 (UAT T3 + T6): a monotonic presentation epoch folded into the presenter
  /// key. Incremented on EVERY advance so a re-present of the SAME id still yields
  /// a DIFFERENT key → a fresh mount → `_ExerciseScaffoldState.initState()` re-runs
  /// (resets phase, clears the canvas, re-arms the instruction hold). Without it a
  /// same-id re-present (a first-fail retry-in-place, or an active-arc pass
  /// re-present of the floor trace) reused the Element, stranding the child on a
  /// dead CTA that only a force-quit could escape.
  int _presentEpoch = 0;

  @override
  void initState() {
    super.initState();
    // D-11: fire a best-effort GET /health the moment the unit opens to mask the
    // Cloud Run cold-start (min-instances=0), so the first /coach call — and the
    // first spoken coach line — does not stall. Fire-and-forget: warmUpCoach
    // no-ops on an empty baseUrl (no --dart-define) and swallows every error, so
    // it never blocks the unit-open path (RemoteAgentBrain never-throw posture).
    unawaited(warmUpCoach(
      ref.read(tutorHttpClientProvider),
      ref.read(tutorBaseUrlProvider),
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final controller =
          ref.read(letterUnitControllerProvider(_letterId).notifier);
      // start() reads the DURABLE Drift graph position (D-08) and, when the saved
      // cursor is a real authored node, RESTORES selection mode (18-15 Task 1).
      await controller.start(
        letterId: _letterId,
        total: widget.data.unit.sections.length,
        resumeSection: widget.resumeSection,
      );
      if (!mounted) return;
      // 18-15 Task 2 — RESUME IN PLACE after a cold boot (UAT T7). This fresh
      // screen state has no presented node yet (`_presentedId == null`). When
      // start() restored selection mode from the durable cursor
      // (`selectionActive` true), SEED `_presentedId` from that restored
      // `currentExerciseId` so the presenter re-enters on the EXACT node the child
      // left off — bypassing the legacy `_section` walk (whose coarse
      // `_sectionHintFor` heuristic commonly lands on section 0 = "Meet"). Seeding
      // `_presentedId` here (rather than a build-time `?? currentExerciseId`
      // fallback) keeps it AUTHORITATIVE: a later verdict-time cursor advance
      // (selectNext) does NOT swap the view — only "Next exercise" does, so the
      // 18-07 "swap on Continue, never at verdict" timing is preserved. A truly-
      // fresh child (null/unauthored cursor → selectionActive false) skips this
      // and keeps the legacy walk (no false resume).
      final resumed = ref.read(letterUnitControllerProvider(_letterId));
      if (_presentedId == null &&
          resumed.selectionActive &&
          resumed.currentExerciseId != null) {
        setState(() => _presentedId = resumed.currentExerciseId);
      }
    });
  }

  /// Record the quiet star ONLY when the on-device mastery condition is met
  /// (D-06 / Pitfall 2). Called when the Mastery section is actually presented —
  /// it never grants the star for merely navigating there; a clicked-through unit
  /// with unmet essential reps records NOTHING. Replaces the deleted
  /// `state.atMastery → recordMastery(cleanReps:0)` auto-write.
  void _recordMasteryIfMet() {
    ref.read(letterUnitControllerProvider(_letterId).notifier).recordMasteryIfMet();
  }

  /// T2 + T1 scoring chokepoint — called by a section when it reports a clean pass
  /// on [graphExerciseId] (a canonical graph node id, not a synthetic per-word id):
  ///   1. Increments the Drift clean-rep count for the node (T2).
  ///   2. Calls [markNodeCleared] so cleared state grows when the threshold is met
  ///      (T1 — makes reachableTiers/prerequisitesMet and resume advance with real
  ///      progress).
  /// Both are fire-and-forget async: they must never block the UI or crash.
  ///
  /// SELECTION (T3) is NO LONGER driven here (18-07). The Phase-15 dead wire was
  /// exactly this: a decision-LESS `selectNext(facts)` on the PASS-only path, so
  /// the coach's `plan.nextExerciseId` never reached the selector. Selection now
  /// runs on EVERY feedback moment (pass AND fail) INSIDE the exercise scaffold,
  /// where the coach's `TutorDecision` is threaded into
  /// `controller.selectNext(facts, decision: decision)` — see ExerciseScaffold.
  void _onNodePassed(String graphExerciseId) {
    final db = ref.read(appDatabaseProvider);
    final controller =
        ref.read(letterUnitControllerProvider(_letterId).notifier);

    // 1) Increment the Drift clean-rep count (T2), keyed by the in-file child
    // the controller resolved at start() (ADR-018). Read the CACHED id — never an
    // inline childProfileProvider.future read on this scored-feedback path
    // (Pitfall 4).
    db
        .incrementExerciseCleanReps(
          childProfileId: controller.childProfileId(),
          letterId: _letterId,
          exerciseId: graphExerciseId,
        )
        .then((_) {
      // 2) T1: update cleared competencies/tiers once threshold is met.
      return controller.markNodeCleared(graphExerciseId);
    }).catchError((_) {
      // Any failure in the async chain must never crash the UI (Pitfall 2 /
      // the "a failed LOCAL write must never crash" convention from the controller).
    });
  }

  /// A section's onAdvance / onFinish (the Next / Got-it CTA). Before selection
  /// activates (teach card, the first legacy section) this is the plain linear
  /// advance. Once the first scored moment hands control to the selector
  /// (`selectionActive`), the SAME CTA ENTERS the presenter — the content swap
  /// happens HERE (on Next), never at verdict time, so the feedback moment lives.
  void _advance() {
    final state = ref.read(letterUnitControllerProvider(_letterId));
    if (state.selectionActive && _presentedId == null) {
      _advanceSelection();
    } else {
      ref.read(letterUnitControllerProvider(_letterId).notifier).advance();
    }
  }

  /// The pass/continue CTA while the presenter drives (18-07 Task 3). It AWAITS the
  /// controller's in-flight selection (`nextReady`) — so a fast Next tap reads the
  /// FRESH cursor, never a stale one (audit finding §5) — then swaps the presented
  /// node (a fresh `graph:<id>#<epoch>` scaffold). Graph exhausted (null) → route
  /// to the Mastery section, where the quiet star stays reachable
  /// (`_recordMasteryIfMet`).
  Future<void> _advanceSelection() async {
    final ctrl = ref.read(letterUnitControllerProvider(_letterId).notifier);
    final pending = ctrl.nextReady();
    final next = pending == null
        ? ref.read(letterUnitControllerProvider(_letterId)).currentExerciseId
        : await pending;
    if (!mounted) return;
    final total = widget.data.unit.sections.length;
    if (next == null) {
      // Graph exhausted → the Mastery section (index total-1), which fires
      // _recordMasteryIfMet post-frame. Leave presenter mode so the star renders.
      // Do NOT bump the epoch — it only matters for a presented node (18-12).
      setState(() => _presentedId = null);
      ctrl.goTo(total > 0 ? total - 1 : 0);
      return;
    }
    _followRibbon(next);
    // 18-12: bump the presentation epoch on EVERY real advance in the SAME
    // setState as the id swap. A monotonic increment guarantees a fresh mount
    // whether `next` is the SAME id as the current one (a legitimate
    // retry-in-place or an active-arc pass re-present — the UAT T3/T6 stuck
    // states) or a different id (which already remounts; the epoch is harmless).
    setState(() {
      _presentEpoch++;
      _presentedId = next;
    });
  }

  /// The section ribbon FOLLOWS the presented node: map its competency → a section
  /// index so the dots track where the child is, even though the content is now
  /// selection-driven. Enrichment / drill nodes leave the ribbon where it is.
  void _followRibbon(String exerciseId) {
    final graph = ref.read(curriculumGraphProvider).asData?.value;
    if (graph == null) return;
    final section = _sectionForCompetency(graph.competencyOf(exerciseId));
    if (section != null) {
      ref.read(letterUnitControllerProvider(_letterId).notifier).goTo(section);
    }
  }

  /// The section index a graph competency maps onto for the ribbon (recognize→Meet,
  /// positionalForms→Watch&Trace, copyWrite→Words, fluentReading→Listen&Write).
  /// Enrichment competencies (wordBuilding/grammarTransform/microDrill) return null
  /// (the ribbon holds its place — those are asides, not ribbon steps).
  int? _sectionForCompetency(String? competency) => switch (competency) {
        'recognize' => 0,
        'positionalForms' => 1,
        'copyWrite' => 3,
        'fluentReading' => 4,
        _ => null,
      };

  /// Play a prompt clip (the presenter's audio tap) via the offline letter player.
  void _onAudioTap(String audioId) =>
      ref.read(audioPlayerProvider).playLetter(audioId);

  void _exit() {
    if (widget.onExit != null) {
      widget.onExit!.call();
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    } else {
      GoRouter.maybeOf(context)?.go('/');
    }
  }

  void _back() {
    final state = ref.read(letterUnitControllerProvider(_letterId));
    if (state.index <= 0) {
      _exit();
    } else {
      ref.read(letterUnitControllerProvider(_letterId).notifier).back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(letterUnitControllerProvider(_letterId));
    final data = widget.data;
    final total = data.unit.sections.length;
    final index = state.total == 0 ? 0 : state.index;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // ── APP BAR ──────────────────────────────────────────────────────
          _AppBar(
            letterGlyph: data.letter.char,
            unitLabel: widget.strings.unitLabel,
            total: total,
            active: index,
            backLabel: widget.strings.back,
            closeLabel: widget.strings.close,
            onBack: _back,
            onClose: _exit,
            // In selection mode the ribbon is DISPLAY-ONLY: a tap must not jump
            // sections (goTo would fight the presenter override). It resumes being
            // tappable in the legacy pre-selection walk.
            onRibbonTap: (i) {
              if (state.selectionActive) return;
              ref.read(letterUnitControllerProvider(_letterId).notifier).goTo(i);
            },
          ),
          // ── BODY: the selected graph node (selection mode) or the legacy
          //         section walk (before the first scored moment) ─────────────
          Expanded(
            child: (state.selectionActive && _presentedId != null)
                ? presentGraphExercise(
                    data: data,
                    exerciseId: _presentedId!,
                    onNodeResult: _onNodePassed,
                    onNext: _advanceSelection,
                    onAudioTap: _onAudioTap,
                    // 18-12: the monotonic epoch → a same-id re-present remounts.
                    presentEpoch: _presentEpoch,
                  )
                : _section(data, index),
          ),
        ],
      ),
    );
  }

  /// Renders the section widget for [index], fed its baa config(s) + the letter.
  Widget _section(LetterUnitData data, int index) {
    final sections = data.unit.sections;
    if (sections.isEmpty) return const SizedBox.shrink();
    final id = sections[index.clamp(0, sections.length - 1)].id;
    final letter = data.letter;

    switch (id) {
      case 'meet':
        return MeetSection(
          key: const ValueKey('section:meet'),
          exercise: _meetExercise(data),
          letter: letter,
          onAdvance: _advance,
          // baa.teachCard.meet has minCleanReps:1 in the graph; record via the
          // onNext (the "Got it/Start Writing" CTA) since teachCards aren't scored
          // through _onResult (surface == null → no grading pass event).
          onGraphNodePassed: _onNodePassed,
        );
      case 'watchTrace':
        return WatchTraceSection(
          key: const ValueKey('section:watchTrace'),
          exercise: _traceIsolated(data),
          letter: letter,
          onAdvance: _advance,
          onGraphNodePassed: _onNodePassed,
        );
      case 'forms':
        return FormsSection(
          key: const ValueKey('section:forms'),
          initial: _traceForm(data, 'initial'),
          medial: _traceForm(data, 'medial'),
          finalForm: _traceForm(data, 'final'),
          join: _join(data),
          letter: letter,
          onAdvance: _advance,
          onGraphNodePassed: _onNodePassed,
        );
      case 'words':
        // Per-word exercises use synthetic ids (baa.writeWord.door, etc.) —
        // these are not graph nodes, so no clean-rep recording here (null).
        return WordsSection(
          key: const ValueKey('section:words'),
          words: _wordTraces(data),
          letter: letter,
          onAdvance: _advance,
        );
      case 'listenWrite':
        return ListenWriteSection(
          key: const ValueKey('section:listenWrite'),
          writeWord: _writeWord(data),
          writeLetter: _writeLetter(data),
          letter: letter,
          onFinish: _advance,
          onGraphNodePassed: _onNodePassed,
        );
      case 'mastery':
        // The quiet star is gated on the on-device mastery condition (D-06 /
        // Pitfall 2): recording is attempted ONLY when the Mastery section is
        // actually presented, and the controller records NOTHING unless every
        // essential node has met the owner-mother's clean-reps. Fired post-frame
        // so it never mutates provider state during a build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _recordMasteryIfMet();
        });
        return MasterySection(
          key: const ValueKey('section:mastery'),
          letter: letter,
          onNext: _exit,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ── exercise resolution (id → Exercise, with prototype-faithful fallbacks) ──

  Exercise _meetExercise(LetterUnitData d) =>
      d.exercise('${_letterId}.teachCard.meet') ?? _fallbackTeach();

  Exercise _traceIsolated(LetterUnitData d) =>
      d.exercise('${_letterId}.traceLetter.isolated') ??
      _fallbackTrace('isolated', demo: true);

  Exercise _traceForm(LetterUnitData d, String form) =>
      d.exercise('${_letterId}.traceLetter.$form') ?? _fallbackTrace(form);

  Exercise _join(LetterUnitData d) =>
      d.exercise('${_letterId}.connectWord.baab') ??
      d.exercise('${_letterId}.writeWord.dictation') ??
      _fallbackWriteWord();

  Exercise _writeWord(LetterUnitData d) =>
      d.exercise('${_letterId}.writeWord.dictation') ?? _fallbackWriteWord();

  Exercise _writeLetter(LetterUnitData d) =>
      d.exercise('${_letterId}.writeLetter.fromSound') ?? _fallbackWriteLetter();

  /// The three vocab words (door/duck/milk), each paired with a write exercise
  /// that checks THAT word. The authored baa configs all target باب, so pairing
  /// them by index made every card check "door" with the wrong prompt (owner
  /// bug); instead each card gets a per-word write exercise built from the word's
  /// own data (text + audio), so door→باب, duck→بطة, milk→حليب.
  List<WordTrace> _wordTraces(LetterUnitData d) {
    // Only the baa-family words that actually contain this letter, capped at 3.
    final words =
        d.words.where((w) => w.letters.contains(_letterId)).take(3).toList();
    return [
      for (final w in words)
        WordTrace(word: w, exercise: _wordExercise(w)),
    ];
  }

  /// A write-the-word exercise for one vocab [w] — its OWN word is the answer and
  /// its OWN clip is the prompt audio. Distinct id per word so the canvas resets
  /// cleanly between cards.
  Exercise _wordExercise(Word w) => Exercise(
        id: '${_letterId}.writeWord.${w.id}',
        type: 'writeWord',
        skill: 'spelling',
        prompt: [
          const SayPart('Write the word.'),
          if ((w.audio ?? '').isNotEmpty) AudioPart(w.audio!),
        ],
        surface: const Surface(mode: 'write', unit: 'word'),
        expected: Answer(word: WordAnswer(w.text)),
        check: const Check(base: 'sequence'),
        feedback: const {
          'pass': 'Well written.',
          'incomplete': 'Look at the word and write all of its letters.',
          'wrongWord':
              'That is a different word — look at the picture and try again.',
        },
        signedOff: false,
      );

  // ── calm fallbacks (a section is always navigable; never a crash) ───────────

  Exercise _fallbackTeach() => Exercise(
        id: '${_letterId}.teachCard.meet',
        type: 'teachCard',
        skill: 'comprehension',
        prompt: [SayPart('Meet the letter.'), AudioPart('snd.$_letterId')],
        signedOff: false,
      );

  Exercise _fallbackTrace(String form, {bool demo = false}) => Exercise(
        id: '${_letterId}.traceLetter.$form',
        type: 'traceLetter',
        skill: 'formation',
        prompt: [SayPart('Trace the letter.'), AudioPart('snd.$_letterId')],
        surface:
            Surface(mode: 'trace', unit: 'glyph', guideForm: form, demo: demo),
        expected: Answer(
            glyph: GlyphAnswer(char: widget.data.letter.char, form: form)),
        check: const Check(base: 'glyph'),
        feedback: const {'pass': 'Well done.'},
        signedOff: false,
      );

  Exercise _fallbackWriteWord({String text = 'باب'}) => Exercise(
        id: '${_letterId}.writeWord.dictation',
        type: 'writeWord',
        skill: 'spelling',
        prompt: [SayPart('Write the word.'), const AudioPart('word.baab')],
        surface: const Surface(mode: 'write', unit: 'word'),
        expected: Answer(word: WordAnswer(text)),
        check: const Check(base: 'sequence'),
        feedback: const {'pass': 'Well written.'},
        signedOff: false,
      );

  Exercise _fallbackWriteLetter() => Exercise(
        id: '${_letterId}.writeLetter.fromSound',
        type: 'writeLetter',
        skill: 'recall',
        prompt: [SayPart('Write the first letter.'), const AudioPart('word.batta')],
        surface: const Surface(mode: 'write', unit: 'glyph'),
        expected: Answer(
            glyph: GlyphAnswer(char: widget.data.letter.char, form: 'isolated')),
        check: const Check(base: 'glyph'),
        feedback: const {'pass': 'That is it.'},
        signedOff: false,
      );
}

/// The prototype `.appbar` — back / close icon buttons, the kid chip, and the
/// centred unit label + R→L ProgressRibbon.
class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.letterGlyph,
    required this.unitLabel,
    required this.total,
    required this.active,
    required this.backLabel,
    required this.closeLabel,
    required this.onBack,
    required this.onClose,
    required this.onRibbonTap,
  });

  final String letterGlyph;
  final String unitLabel;
  final int total;
  final int active;
  final String backLabel;
  final String closeLabel;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final ValueChanged<int> onRibbonTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68, // .appbar height:68px
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: const BoxDecoration(
        border: Border(
          // .appbar border-bottom:1px solid var(--parchment-edge) #E8DFC9
          bottom: BorderSide(color: Color(0xFFE8DFC9)),
        ),
      ),
      child: Row(
        children: [
          // back (start) — hidden visually at section 0 would still pop the
          // unit; we always show it so the child can always leave.
          _IconBtn(
            icon: Icons.arrow_back_rounded,
            label: backLabel,
            onTap: onBack,
          ),
          const SizedBox(width: 18),
          // the centred unit label + the R→L unit ribbon.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      unitLabel.toUpperCase(),
                      style: QalamTextStyles.label.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.14 * 11,
                        color: QalamTokens.fgMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ArabicText(
                      letterGlyph,
                      style: QalamTextStyles.arBody.copyWith(
                        fontSize: 17, // .unitlbl .g
                        fontWeight: FontWeight.w600,
                        color: QalamTokens.deepInk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7), // .unitwrap gap:7
                _UnitRibbon(total: total, active: active, onTap: onRibbonTap),
              ],
            ),
          ),
          const SizedBox(width: 18),
          // close (end).
          _IconBtn(
            icon: Icons.close_rounded,
            label: closeLabel,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

/// The R→L unit ribbon — 6 tappable dots, dot 0 on the RIGHT (row-reverse),
/// position-only (never gold). Reuses the ProgressRibbon visual grammar but is
/// tappable for the unit's section jumps (the prototype's `buildRibbon`).
class _UnitRibbon extends StatelessWidget {
  const _UnitRibbon({
    required this.total,
    required this.active,
    required this.onTap,
  });

  final int total;
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    return Semantics(
      label: 'Section ${active + 1} of $total',
      child: Row(
        // R→L: section 1 sits on the right (.ribbon flex-direction:row-reverse).
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 9), // .ribbon gap:9
            _RibbonDot(
              key: ValueKey<String>('unitRibbonDot:$i'),
              done: i < active,
              active: i == active,
              onTap: () => onTap(i),
            ),
          ],
        ],
      ),
    );
  }
}

/// One `.dot` of the unit ribbon (done / active / upcoming; never gold).
class _RibbonDot extends StatelessWidget {
  const _RibbonDot({
    super.key,
    required this.done,
    required this.active,
    required this.onTap,
  });

  final bool done;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const base = 13.0; // .dot width/height:13px
    final size = active ? base * 1.32 : base; // .dot.active scale(1.32)
    final Color fill = done
        ? QalamTokens.inkTeal
        : active
            ? QalamTokens.tealTint
            : Colors.transparent;
    final Color border = done || active
        ? QalamTokens.inkTeal
        : QalamTokens.aquaEdge;
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: border, width: 2),
            boxShadow: active
                ? const [
                    BoxShadow(
                        color: Color(0x1F168A8F),
                        blurRadius: 0,
                        spreadRadius: 4),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

/// `.iconbtn` — a 46×46 ghost icon button (back / close).
class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 46, // .iconbtn 46×46
            height: 46,
            child: Icon(icon, size: 24, color: QalamTokens.fgMuted),
          ),
        ),
      ),
    );
  }
}

/// The calm "preparing" panel shown while the unit loads or when the letter is
/// not yet available (never a raw error or spinner chrome to the child).
class _Preparing extends StatelessWidget {
  const _Preparing({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: QalamTextStyles.body.copyWith(color: QalamTokens.fgMuted),
        textAlign: TextAlign.center,
      ),
    );
  }
}
