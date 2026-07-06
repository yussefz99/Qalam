# Curriculum Draft - ? ? saad

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| saad | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## saad

**Char:** ? ? **Family:** saad/daad emphatic loop family
**Strokes (drafted, signed-at-letter pending):** round head, smooth base
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Gloss | Source | Audio id | Image id |
|---|---|---|---|---|---|
| sunduq | ????? | box | [DRAFT] | `word.sunduq` | `img.box` |
| sabr | ??? | patience | [DRAFT] | `word.sabr` | `img.cactus` |
| saqar | ??? | falcon | [DRAFT] | `word.saqar` | `img.falcon` |
| qamis | ???? | shirt | [DRAFT] | `word.qamis` | `img.shirt` |
| asaa | ??? | stick | [DRAFT] | `word.asaa` | `img.stick` |

### Exercise Set

```json
{"id": "saad.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.saad"}, {"kind": "image", "imageId": "img.box", "caption": "????? ? sunduq"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "saad.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Make the round head, then stretch the base smoothly."}, {"kind": "audio", "audioId": "snd.saad"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? round head and smooth base. ?????!", "wrongShape": "Round the head more, then keep the base steady.", "noDot": "Saad has no dot ? keep the top clean."}, "signedOff": false}
{"id": "saad.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, saad has a round head that reaches forward."}, {"kind": "audio", "audioId": "snd.saad"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? smooth and clean. ?????!", "wrongShape": "Round the head more, then keep the base steady.", "noDot": "Saad has no dot ? keep the top clean."}, "signedOff": false}
{"id": "saad.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, saad keeps its round head joined on both sides."}, {"kind": "audio", "audioId": "snd.saad"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined clearly. ?????!", "wrongShape": "Round the head more, then keep the base steady.", "notConnected": "Keep the form joined where it connects."}, "signedOff": false}
{"id": "saad.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.sunduq"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is saad. ?????!", "wrongLetter": "Listen again ? ????? starts with saad. round head, smooth base"}, "signedOff": false}
{"id": "saad.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.cactus", "caption": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ??? starts with saad. ?????!", "wrongLetter": "Look again ? start with saad. round head, smooth base"}, "signedOff": false}
{"id": "saad.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write saad in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? round head and smooth base. ?????!", "wrongLetter": "Try saad again ? round head, smooth base"}, "signedOff": false}
{"id": "saad.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.sunduq"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "????? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ?????."}, "signedOff": false}
{"id": "saad.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ???."}, "signedOff": false}
{"id": "saad.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.shirt", "caption": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ????."}, "signedOff": false}
{"id": "saad.connectWord.sunduq", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "????? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "saad.connectWord.sabr", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "saad.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "middle saad in ????.", "prompt": [{"kind": "say", "line": "Fill in the missing saad to finish the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "Complete! ????. ?????!", "incomplete": "Fill in the missing saad to finish the word."}, "signedOff": false}
{"id": "saad.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ?????."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "?????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???????"}}, "check": "sequence+transformRule", "feedback": {"pass": "??????? ? ?????!", "missingEnding": "Add the ending: ???????."}, "signedOff": false}
{"id": "saad.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (??????).", "prompt": [{"kind": "say", "line": "Write the plural of ?????."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "?????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??????"}}, "check": "sequence+transformRule", "feedback": {"pass": "?????? ? ?????!", "missingEnding": "Look again ? the plural is ??????."}, "signedOff": false}
{"id": "saad.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ????????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ????."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite is ????."}, "signedOff": false}
{"id": "saad.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "?????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "Yes ? ????? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "saad.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.assunduqu-kabeer"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["????????", "????"]}, "check": "order+sequence", "feedback": {"pass": "???????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ???????? ????."}, "signedOff": false}
{"id": "saad.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.shirt", "caption": "????"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["???????", "????"]}, "check": "order+sequence", "feedback": {"pass": "??????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ??????? ????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "sunduq", "text": "?????", "audio": "word.sunduq", "image": "img.box", "gloss": {"en": "box"}, "letters": ["saad", "noon", "daal", "waaw", "qaaf"], "signedOff": false}
{"id": "sabr", "text": "???", "audio": "word.sabr", "image": "img.cactus", "gloss": {"en": "patience"}, "letters": ["saad", "baa", "raa"], "signedOff": false}
{"id": "saqar", "text": "???", "audio": "word.saqar", "image": "img.falcon", "gloss": {"en": "falcon"}, "letters": ["saad", "qaaf", "raa"], "signedOff": false}
{"id": "qamis", "text": "????", "audio": "word.qamis", "image": "img.shirt", "gloss": {"en": "shirt"}, "letters": ["qaaf", "meem", "yaa", "saad"], "signedOff": false}
{"id": "asaa", "text": "???", "audio": "word.asaa", "image": "img.stick", "gloss": {"en": "stick"}, "letters": ["ayn", "saad", "alif"], "signedOff": false}
```

## Sign-Off Checklist for Owner-Mother

- [ ] Word list - keep / swap?
- [ ] Stroke story: round head, smooth base - correct?
- [ ] Grammar transforms: dual `???????`, plural `??????`, opposite `???? -> ????` - correct and age-right?
- [ ] Sentence choices: `???????? ????`, `??????? ????` - keep / swap?
