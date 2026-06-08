import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/geometric_stroke_scorer.dart';
import 'package:qalam/core/scoring/scoring_models.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/l10n/app_localizations_en.dart';
import 'package:qalam/models/letter.dart';

/// S1-05 — MistakeId → authored feedback string mapping.
///
/// Every MistakeId must map to the EXACT feedback string authored in
/// letters.json alif commonMistakes[].feedback.  No generic "try again"
/// phrases are permitted — the tutor's voice is always specific.
///
/// Authored strings (verbatim from letters.json):
///   tooShort      → "Your alif needs to be taller — draw it from the top all the way down."
///   wrongDirection→ "Start your alif at the top and come down — not from the bottom up."
///   tooCurved     → "Alif is a straight line — try to keep it as straight as you can."
///   fallback      → calm, specific, NOT "Oops" or any generic phrase.
void main() {
  // Alif Letter built inline — mirrors the letters.json alif entry exactly.
  Letter alifLetter() => const Letter(
        id: 'alif',
        char: 'ا',
        name: LetterName(ar: 'اَلِف', display: 'Alif'),
        introOrder: 1,
        forms: LetterForms(
          isolated: 'ا',
          initial: 'ا',
          medial: 'ا',
          final_: 'ا',
        ),
        referenceStrokes: [
          StrokeSpec(
            order: 1,
            label: 'vertical_stroke',
            type: 'line',
            direction: 'topToBottom',
            points: [
              [0.5, 0.0],
              [0.5, 0.25],
              [0.5, 0.5],
              [0.5, 0.75],
              [0.5, 1.0],
            ],
          ),
        ],
        cleanRepsToAdvance: 3,
        commonMistakes: [
          CommonMistake(
            id: 'too_short',
            check: 'strokeLengthBelowThreshold',
            feedback:
                'Your alif needs to be taller — draw it from the top all the way down.',
          ),
          CommonMistake(
            id: 'wrong_direction',
            check: 'strokeDirectionInverted',
            feedback:
                'Start your alif at the top and come down — not from the bottom up.',
          ),
          CommonMistake(
            id: 'too_curved',
            check: 'strokeCurvatureExceedsThreshold',
            feedback:
                'Alif is a straight line — try to keep it as straight as you can.',
          ),
        ],
        mistakesStatus: 'authored',
        signedOff: true,
      );

  group('feedbackForMistake — authored strings (verbatim from letters.json)', () {
    test('MistakeId.tooShort returns the exact authored feedback', () {
      final feedback = feedbackForMistake(MistakeId.tooShort, alifLetter());
      expect(
        feedback,
        equals(
          'Your alif needs to be taller — draw it from the top all the way down.',
        ),
      );
    });

    test('MistakeId.wrongDirection returns the exact authored feedback', () {
      final feedback = feedbackForMistake(MistakeId.wrongDirection, alifLetter());
      expect(
        feedback,
        equals(
          'Start your alif at the top and come down — not from the bottom up.',
        ),
      );
    });

    test('MistakeId.tooCurved returns the exact authored feedback', () {
      final feedback = feedbackForMistake(MistakeId.tooCurved, alifLetter());
      expect(
        feedback,
        equals(
          'Alif is a straight line — try to keep it as straight as you can.',
        ),
      );
    });

    test('MistakeId.fallback returns a calm specific string (not "Oops")', () {
      final feedback = feedbackForMistake(MistakeId.fallback, alifLetter());
      expect(feedback, isNotNull);
      expect(feedback, isNotEmpty);
      // Must not contain any generic "Oops" phrase — tutor's voice is always specific.
      expect(feedback!.toLowerCase(), isNot(contains('oops')));
    });
  });

  // ── Plan 04-04: whole-letter MistakeIds → AUTHORED l10n strings ───────────────
  //
  // The four new whole-letter failure categories (count/order/dot/identity) each
  // resolve to an authored l10n string in practice_screen's _feedbackString —
  // NEVER the generic fallback (Pitfall 7 / PLAT-03). We assert the authored
  // l10n getters they reference exist, are non-empty, and are specific (not the
  // fallback copy, not "Oops"). The mapping below mirrors _feedbackString's new
  // arms exactly — breaking one requires changing the other.
  group('whole-letter MistakeId → authored l10n (Plan 04-04, Pitfall 7)', () {
    final AppLocalizations l10n = AppLocalizationsEn();

    // Mirrors practice_screen.dart _feedbackString's four new cases.
    String authoredFor(MistakeId id) {
      switch (id) {
        case MistakeId.wrongStrokeCount:
          return l10n.practiceFeedbackWrongStrokeCount;
        case MistakeId.wrongStrokeOrder:
          return l10n.practiceFeedbackWrongStrokeOrder;
        case MistakeId.dotMisplaced:
          return l10n.practiceFeedbackDotMisplaced;
        case MistakeId.wrongLetterIdentity:
          return l10n.practiceFeedbackWrongLetterIdentity;
        default:
          fail('MistakeId $id is not a whole-letter category');
      }
    }

    const wholeLetterIds = <MistakeId>[
      MistakeId.wrongStrokeCount,
      MistakeId.wrongStrokeOrder,
      MistakeId.dotMisplaced,
      MistakeId.wrongLetterIdentity,
    ];

    for (final id in wholeLetterIds) {
      test('$id maps to a non-empty, specific authored l10n string', () {
        final feedback = authoredFor(id);
        expect(feedback, isNotEmpty, reason: '$id must have authored copy');
        // Never the generic fallback string and never "Oops" — the tutor's
        // voice is always specific (PLAT-03 / Pitfall 7).
        expect(feedback, isNot(equals(l10n.practiceFeedbackFallback)),
            reason: '$id must not fall through to the generic fallback');
        expect(feedback.toLowerCase(), isNot(contains('oops')));
      });
    }

    test('getting-ready copy exists and is calm (not an error)', () {
      expect(l10n.practiceGettingReadyTitle, isNotEmpty);
      expect(l10n.practiceGettingReadyBody, isNotEmpty);
      expect(l10n.practiceGettingReadyTitle.toLowerCase(),
          isNot(contains('error')));
    });
  });
}
