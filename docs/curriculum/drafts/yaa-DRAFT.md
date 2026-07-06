# Curriculum Draft - ? ? yaa

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| yaa | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## yaa

**Char:** ? ? **Family:** yaa body-two-dots family
**Strokes (drafted, signed-at-letter pending):** body curve, two dots underneath
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Gloss | Source | Audio id | Image id |
|---|---|---|---|---|---|
| yad_yaa | ?? | hand | [DRAFT] | `word.yad` | `img.hand` |
| yamin | ???? | right side | [DRAFT] | `word.yamin` | `img.right-side` |
| yasmin | ?????? | jasmine | [DRAFT] | `word.yasmin` | `img.jasmine` |
| bayt_yaa | ??? | house | [DRAFT] | `word.bayt` | `img.house` |
| kursi_yaa | ???? | chair | [DRAFT] | `word.kursi` | `img.chair` |

### Exercise Set

```json
{"id": "yaa.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.yaa"}, {"kind": "image", "imageId": "img.hand", "caption": "?? ? yad_yaa"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "yaa.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Draw the body curve, then two dots underneath."}, {"kind": "audio", "audioId": "snd.yaa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? body curve and two dots underneath. ?????!", "wrongShape": "Keep the body smooth, then place two dots underneath.", "noDot": "Add two dots underneath ? count them: one, two."}, "signedOff": false}
{"id": "yaa.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, yaa is a small shape with two dots underneath."}, {"kind": "audio", "audioId": "snd.yaa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? smooth and clean. ?????!", "wrongShape": "Keep the body smooth, then place two dots underneath.", "noDot": "Add two dots underneath ? count them: one, two."}, "signedOff": false}
{"id": "yaa.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, yaa joins on both sides with two dots underneath."}, {"kind": "audio", "audioId": "snd.yaa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined clearly. ?????!", "wrongShape": "Keep the body smooth, then place two dots underneath.", "notConnected": "Keep the form joined where it connects."}, "signedOff": false}
{"id": "yaa.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.yad"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is yaa. ?????!", "wrongLetter": "Listen again ? ?? starts with yaa. body curve, two dots underneath"}, "signedOff": false}
{"id": "yaa.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.right-side", "caption": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ???? starts with yaa. ?????!", "wrongLetter": "Look again ? start with yaa. body curve, two dots underneath"}, "signedOff": false}
{"id": "yaa.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write yaa in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? body curve and two dots underneath. ?????!", "wrongLetter": "Try yaa again ? body curve, two dots underneath"}, "signedOff": false}
{"id": "yaa.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.yad"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??"}}, "check": "sequence", "feedback": {"pass": "?? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ??."}, "signedOff": false}
{"id": "yaa.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ????."}, "signedOff": false}
{"id": "yaa.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.house", "caption": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ???."}, "signedOff": false}
{"id": "yaa.connectWord.yad_yaa", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "?? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "yaa.connectWord.yamin", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "???? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "yaa.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "middle yaa in ???.", "prompt": [{"kind": "say", "line": "Fill in the missing yaa to finish the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Complete! ???. ?????!", "incomplete": "Fill in the missing yaa to finish the word."}, "signedOff": false}
{"id": "yaa.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ??."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "??"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "missingEnding": "Add the ending: ????."}, "signedOff": false}
{"id": "yaa.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (???).", "prompt": [{"kind": "say", "line": "Write the plural of ??."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "??"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+transformRule", "feedback": {"pass": "??? ? ?????!", "missingEnding": "Look again ? the plural is ???."}, "signedOff": false}
{"id": "yaa.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ????????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ????."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite is ????."}, "signedOff": false}
{"id": "yaa.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "??"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??"}}, "check": "sequence", "feedback": {"pass": "Yes ? ?? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "yaa.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.alyadu-naziifa"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["?????", "?????"]}, "check": "order+sequence", "feedback": {"pass": "????? ????? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ????? ?????."}, "signedOff": false}
{"id": "yaa.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.house", "caption": "???"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "yad_yaa", "text": "??", "audio": "word.yad", "image": "img.hand", "gloss": {"en": "hand"}, "letters": ["yaa", "daal"], "signedOff": false}
{"id": "yamin", "text": "????", "audio": "word.yamin", "image": "img.right-side", "gloss": {"en": "right side"}, "letters": ["yaa", "meem", "yaa", "noon"], "signedOff": false}
{"id": "yasmin", "text": "??????", "audio": "word.yasmin", "image": "img.jasmine", "gloss": {"en": "jasmine"}, "letters": ["yaa", "alif", "seen", "meem", "yaa", "noon"], "signedOff": false}
{"id": "bayt_yaa", "text": "???", "audio": "word.bayt", "image": "img.house", "gloss": {"en": "house"}, "letters": ["baa", "yaa", "taa"], "signedOff": false}
{"id": "kursi_yaa", "text": "????", "audio": "word.kursi", "image": "img.chair", "gloss": {"en": "chair"}, "letters": ["kaaf", "raa", "seen", "yaa"], "signedOff": false}
```

## Sign-Off Checklist for Owner-Mother

- [ ] Word list - keep / swap?
- [ ] Stroke story: body curve, two dots underneath - correct?
- [ ] Grammar transforms: dual `????`, plural `???`, opposite `???? -> ????` - correct and age-right?
- [ ] Sentence choices: `????? ?????`, `?????? ????` - keep / swap?
