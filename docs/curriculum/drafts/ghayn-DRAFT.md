# Curriculum Draft - ? ? ghayn

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| ghayn | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## ghayn

**Char:** ? ? **Family:** ayn/ghayn belly-open family
**Strokes (drafted, signed-at-letter pending):** open head, round belly, dot above
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Gloss | Source | Audio id | Image id |
|---|---|---|---|---|---|
| ghazal | ???? | deer | [DRAFT] | `word.ghazal` | `img.deer` |
| ghayma | ???? | cloud | [DRAFT] | `word.ghayma` | `img.cloud` |
| ghurab | ???? | crow | [DRAFT] | `word.ghurab` | `img.crow` |
| babbagha | ????? | parrot | [DRAFT] | `word.babbagha` | `img.parrot` |
| sagheer | ???? | small | [DRAFT] | `word.sagheer` | `img.small` |

### Exercise Set

```json
{"id": "ghayn.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.ghayn"}, {"kind": "image", "imageId": "img.deer", "caption": "???? ? ghazal"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "ghayn.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Make the open head and round belly, then one dot above."}, {"kind": "audio", "audioId": "snd.ghayn"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? open head, round belly, and dot above. ?????!", "wrongShape": "Open the head clearly, then round the belly.", "noDot": "Add one dot above ? that dot makes it ghayn."}, "signedOff": false}
{"id": "ghayn.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, ghayn is an open head with one dot above."}, {"kind": "audio", "audioId": "snd.ghayn"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? smooth and clean. ?????!", "wrongShape": "Open the head clearly, then round the belly.", "noDot": "Add one dot above ? that dot makes it ghayn."}, "signedOff": false}
{"id": "ghayn.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, ghayn joins with one dot above."}, {"kind": "audio", "audioId": "snd.ghayn"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined clearly. ?????!", "wrongShape": "Open the head clearly, then round the belly.", "notConnected": "Keep the form joined where it connects."}, "signedOff": false}
{"id": "ghayn.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.ghazal"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is ghayn. ?????!", "wrongLetter": "Listen again ? ???? starts with ghayn. open head, round belly, dot above"}, "signedOff": false}
{"id": "ghayn.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.cloud", "caption": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ???? starts with ghayn. ?????!", "wrongLetter": "Look again ? start with ghayn. open head, round belly, dot above"}, "signedOff": false}
{"id": "ghayn.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write ghayn in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? open head, round belly, and dot above. ?????!", "wrongLetter": "Try ghayn again ? open head, round belly, dot above"}, "signedOff": false}
{"id": "ghayn.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.ghazal"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ????."}, "signedOff": false}
{"id": "ghayn.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ????."}, "signedOff": false}
{"id": "ghayn.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.parrot", "caption": "?????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "????? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ?????."}, "signedOff": false}
{"id": "ghayn.connectWord.ghazal", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "???? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "ghayn.connectWord.ghayma", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "???? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "ghayn.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "middle ghayn in ?????.", "prompt": [{"kind": "say", "line": "Fill in the missing ghayn to finish the word."}, {"kind": "text", "text": "?????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "Complete! ?????. ?????!", "incomplete": "Fill in the missing ghayn to finish the word."}, "signedOff": false}
{"id": "ghayn.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ????."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??????"}}, "check": "sequence+transformRule", "feedback": {"pass": "?????? ? ?????!", "missingEnding": "Add the ending: ??????."}, "signedOff": false}
{"id": "ghayn.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (?????).", "prompt": [{"kind": "say", "line": "Write the plural of ????."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "missingEnding": "Look again ? the plural is ?????."}, "signedOff": false}
{"id": "ghayn.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ???????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ???."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite is ????."}, "signedOff": false}
{"id": "ghayn.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "Yes ? ???? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "ghayn.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.alghaymatu-baydaa"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["???????", "?????"]}, "check": "order+sequence", "feedback": {"pass": "??????? ????? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ??????? ?????."}, "signedOff": false}
{"id": "ghayn.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.parrot", "caption": "?????"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["???????", "????"]}, "check": "order+sequence", "feedback": {"pass": "??????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ??????? ????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "ghazal", "text": "????", "audio": "word.ghazal", "image": "img.deer", "gloss": {"en": "deer"}, "letters": ["ghayn", "zaay", "alif", "laam"], "signedOff": false}
{"id": "ghayma", "text": "????", "audio": "word.ghayma", "image": "img.cloud", "gloss": {"en": "cloud"}, "letters": ["ghayn", "yaa", "meem", "taa_marbuta"], "signedOff": false}
{"id": "ghurab", "text": "????", "audio": "word.ghurab", "image": "img.crow", "gloss": {"en": "crow"}, "letters": ["ghayn", "raa", "alif", "baa"], "signedOff": false}
{"id": "babbagha", "text": "?????", "audio": "word.babbagha", "image": "img.parrot", "gloss": {"en": "parrot"}, "letters": ["baa", "baa", "ghayn", "alif"], "signedOff": false}
{"id": "sagheer", "text": "????", "audio": "word.sagheer", "image": "img.small", "gloss": {"en": "small"}, "letters": ["saad", "ghayn", "yaa", "raa"], "signedOff": false}
```

## Sign-Off Checklist for Owner-Mother

- [ ] Word list - keep / swap?
- [ ] Stroke story: open head, round belly, dot above - correct?
- [ ] Grammar transforms: dual `??????`, plural `?????`, opposite `??? -> ????` - correct and age-right?
- [ ] Sentence choices: `??????? ?????`, `??????? ????` - keep / swap?
