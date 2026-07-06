# Curriculum Draft - ? ? daad

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| daad | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## daad

**Char:** ? ? **Family:** saad/daad emphatic loop family
**Strokes (drafted, signed-at-letter pending):** round head, smooth base, dot above
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Gloss | Source | Audio id | Image id |
|---|---|---|---|---|---|
| difdaa | ???? | frog | [DRAFT] | `word.difdaa` | `img.frog` |
| dars | ??? | molar | [DRAFT] | `word.dars` | `img.tooth` |
| bayd | ??? | eggs | [DRAFT] | `word.bayd` | `img.eggs` |
| marad | ??? | sickness | [DRAFT] | `word.marad` | `img.sick` |
| ard | ??? | ground | [DRAFT] | `word.ard` | `img.ground` |

### Exercise Set

```json
{"id": "daad.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.daad"}, {"kind": "image", "imageId": "img.frog", "caption": "???? ? difdaa"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "daad.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Make the round head and smooth base, then one dot above."}, {"kind": "audio", "audioId": "snd.daad"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? round head, smooth base, and dot above. ?????!", "wrongShape": "Round the head more, then keep the base steady.", "noDot": "Add one dot above ? that dot makes it daad."}, "signedOff": false}
{"id": "daad.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, daad has a round head and one dot above."}, {"kind": "audio", "audioId": "snd.daad"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? smooth and clean. ?????!", "wrongShape": "Round the head more, then keep the base steady.", "noDot": "Add one dot above ? that dot makes it daad."}, "signedOff": false}
{"id": "daad.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, daad joins on both sides with one dot above."}, {"kind": "audio", "audioId": "snd.daad"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined clearly. ?????!", "wrongShape": "Round the head more, then keep the base steady.", "notConnected": "Keep the form joined where it connects."}, "signedOff": false}
{"id": "daad.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.difdaa"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is daad. ?????!", "wrongLetter": "Listen again ? ???? starts with daad. round head, smooth base, dot above"}, "signedOff": false}
{"id": "daad.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.tooth", "caption": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ??? starts with daad. ?????!", "wrongLetter": "Look again ? start with daad. round head, smooth base, dot above"}, "signedOff": false}
{"id": "daad.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write daad in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? round head, smooth base, and dot above. ?????!", "wrongLetter": "Try daad again ? round head, smooth base, dot above"}, "signedOff": false}
{"id": "daad.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.difdaa"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ????."}, "signedOff": false}
{"id": "daad.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ???."}, "signedOff": false}
{"id": "daad.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.sick", "caption": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ???."}, "signedOff": false}
{"id": "daad.connectWord.difdaa", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "???? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "daad.connectWord.dars", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "daad.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "middle daad in ???.", "prompt": [{"kind": "say", "line": "Fill in the missing daad to finish the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Complete! ???. ?????!", "incomplete": "Fill in the missing daad to finish the word."}, "signedOff": false}
{"id": "daad.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ????."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??????"}}, "check": "sequence+transformRule", "feedback": {"pass": "?????? ? ?????!", "missingEnding": "Add the ending: ??????."}, "signedOff": false}
{"id": "daad.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (?????).", "prompt": [{"kind": "say", "line": "Write the plural of ????."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "missingEnding": "Look again ? the plural is ?????."}, "signedOff": false}
{"id": "daad.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ???????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ???."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite is ????."}, "signedOff": false}
{"id": "daad.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "Yes ? ???? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "daad.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.addifdau-akhdar"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["???????", "????"]}, "check": "order+sequence", "feedback": {"pass": "??????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ??????? ????."}, "signedOff": false}
{"id": "daad.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.sick", "caption": "???"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "difdaa", "text": "????", "audio": "word.difdaa", "image": "img.frog", "gloss": {"en": "frog"}, "letters": ["daad", "faa", "daal", "ayn"], "signedOff": false}
{"id": "dars", "text": "???", "audio": "word.dars", "image": "img.tooth", "gloss": {"en": "molar"}, "letters": ["daad", "raa", "seen"], "signedOff": false}
{"id": "bayd", "text": "???", "audio": "word.bayd", "image": "img.eggs", "gloss": {"en": "eggs"}, "letters": ["baa", "yaa", "daad"], "signedOff": false}
{"id": "marad", "text": "???", "audio": "word.marad", "image": "img.sick", "gloss": {"en": "sickness"}, "letters": ["meem", "raa", "daad"], "signedOff": false}
{"id": "ard", "text": "???", "audio": "word.ard", "image": "img.ground", "gloss": {"en": "ground"}, "letters": ["alif", "raa", "daad"], "signedOff": false}
```

## Sign-Off Checklist for Owner-Mother

- [ ] Word list - keep / swap?
- [ ] Stroke story: round head, smooth base, dot above - correct?
- [ ] Grammar transforms: dual `??????`, plural `?????`, opposite `??? -> ????` - correct and age-right?
- [ ] Sentence choices: `??????? ????`, `?????? ????` - keep / swap?
