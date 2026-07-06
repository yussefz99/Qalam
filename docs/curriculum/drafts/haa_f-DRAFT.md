# Curriculum Draft - ? ? haa_f

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| haa_f | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## haa_f

**Char:** ? ? **Family:** haa_f loop family
**Strokes (drafted, signed-at-letter pending):** round loop
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Gloss | Source | Audio id | Image id |
|---|---|---|---|---|---|
| hadiyya | ???? | gift | [DRAFT] | `word.hadiyya` | `img.gift` |
| haram | ??? | pyramid | [DRAFT] | `word.haram` | `img.pyramid` |
| hilal | ???? | crescent | [DRAFT] | `word.hilal` | `img.crescent` |
| wajh | ??? | face | [DRAFT] | `word.wajh` | `img.face` |
| miyah | ???? | water | [DRAFT] | `word.miyah` | `img.water` |

### Exercise Set

```json
{"id": "haa_f.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.haa_f"}, {"kind": "image", "imageId": "img.gift", "caption": "???? ? hadiyya"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "haa_f.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Curl around into a round loop."}, {"kind": "audio", "audioId": "snd.haa_f"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? round loop. ?????!", "wrongShape": "Keep the loop round and closed-looking.", "noDot": "Keep the loop round and closed-looking."}, "signedOff": false}
{"id": "haa_f.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, haa is a small loop that reaches forward."}, {"kind": "audio", "audioId": "snd.haa_f"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? smooth and clean. ?????!", "wrongShape": "Keep the loop round and closed-looking.", "noDot": "Keep the loop round and closed-looking."}, "signedOff": false}
{"id": "haa_f.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, haa makes a small loop between joins."}, {"kind": "audio", "audioId": "snd.haa_f"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined clearly. ?????!", "wrongShape": "Keep the loop round and closed-looking.", "notConnected": "Keep the form joined where it connects."}, "signedOff": false}
{"id": "haa_f.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.hadiyya"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is haa_f. ?????!", "wrongLetter": "Listen again ? ???? starts with haa_f. round loop"}, "signedOff": false}
{"id": "haa_f.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.pyramid", "caption": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ??? starts with haa_f. ?????!", "wrongLetter": "Look again ? start with haa_f. round loop"}, "signedOff": false}
{"id": "haa_f.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write haa_f in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? round loop. ?????!", "wrongLetter": "Try haa_f again ? round loop"}, "signedOff": false}
{"id": "haa_f.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.hadiyya"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ????."}, "signedOff": false}
{"id": "haa_f.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ???."}, "signedOff": false}
{"id": "haa_f.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.face", "caption": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ???."}, "signedOff": false}
{"id": "haa_f.connectWord.hadiyya", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "???? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "haa_f.connectWord.haram", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "haa_f.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "middle haa_f in ???.", "prompt": [{"kind": "say", "line": "Fill in the missing haa_f to finish the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Complete! ???. ?????!", "incomplete": "Fill in the missing haa_f to finish the word."}, "signedOff": false}
{"id": "haa_f.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ????."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??????"}}, "check": "sequence+transformRule", "feedback": {"pass": "?????? ? ?????!", "missingEnding": "Add the ending: ??????."}, "signedOff": false}
{"id": "haa_f.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (?????).", "prompt": [{"kind": "say", "line": "Write the plural of ????."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "missingEnding": "Look again ? the plural is ?????."}, "signedOff": false}
{"id": "haa_f.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ????????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ????."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite is ????."}, "signedOff": false}
{"id": "haa_f.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "Yes ? ???? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "haa_f.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.alhadiyyatu-jamiila"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["???????", "?????"]}, "check": "order+sequence", "feedback": {"pass": "??????? ????? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ??????? ?????."}, "signedOff": false}
{"id": "haa_f.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.face", "caption": "???"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "hadiyya", "text": "????", "audio": "word.hadiyya", "image": "img.gift", "gloss": {"en": "gift"}, "letters": ["haa_f", "daal", "yaa", "taa_marbuta"], "signedOff": false}
{"id": "haram", "text": "???", "audio": "word.haram", "image": "img.pyramid", "gloss": {"en": "pyramid"}, "letters": ["haa_f", "raa", "meem"], "signedOff": false}
{"id": "hilal", "text": "????", "audio": "word.hilal", "image": "img.crescent", "gloss": {"en": "crescent"}, "letters": ["haa_f", "laam", "alif", "laam"], "signedOff": false}
{"id": "wajh", "text": "???", "audio": "word.wajh", "image": "img.face", "gloss": {"en": "face"}, "letters": ["waaw", "jeem", "haa_f"], "signedOff": false}
{"id": "miyah", "text": "????", "audio": "word.miyah", "image": "img.water", "gloss": {"en": "water"}, "letters": ["meem", "yaa", "alif", "haa_f"], "signedOff": false}
```

## Sign-Off Checklist for Owner-Mother

- [ ] Word list - keep / swap?
- [ ] Stroke story: round loop - correct?
- [ ] Grammar transforms: dual `??????`, plural `?????`, opposite `???? -> ????` - correct and age-right?
- [ ] Sentence choices: `??????? ?????`, `?????? ????` - keep / swap?
