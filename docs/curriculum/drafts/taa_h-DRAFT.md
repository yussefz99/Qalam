# Curriculum Draft - ? ? taa_h

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| taa_h | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## taa_h

**Char:** ? ? **Family:** taa_h/zhaa emphatic stem family
**Strokes (drafted, signed-at-letter pending):** rounded body, tall line
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Gloss | Source | Audio id | Image id |
|---|---|---|---|---|---|
| taair | ???? | bird | [DRAFT] | `word.taair` | `img.bird` |
| tifl | ??? | child | [DRAFT] | `word.tifl` | `img.child` |
| tamaatim | ????? | tomatoes | [DRAFT] | `word.tamaatim` | `img.tomatoes` |
| batata | ????? | potato | [DRAFT] | `word.batata` | `img.potato` |
| matbakh | ???? | kitchen | [DRAFT] | `word.matbakh` | `img.kitchen` |

### Exercise Set

```json
{"id": "taa_h.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.taa_h"}, {"kind": "image", "imageId": "img.bird", "caption": "???? ? taair"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "taa_h.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Draw the rounded body, then the tall standing line."}, {"kind": "audio", "audioId": "snd.taa_h"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? rounded body and tall line. ?????!", "wrongShape": "Keep the standing line tall and the body rounded.", "noDot": "Taa has no dot ? keep it clean above."}, "signedOff": false}
{"id": "taa_h.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, taa has a rounded body and a tall line."}, {"kind": "audio", "audioId": "snd.taa_h"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? smooth and clean. ?????!", "wrongShape": "Keep the standing line tall and the body rounded.", "noDot": "Taa has no dot ? keep it clean above."}, "signedOff": false}
{"id": "taa_h.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, taa keeps the body joined with the tall line."}, {"kind": "audio", "audioId": "snd.taa_h"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined clearly. ?????!", "wrongShape": "Keep the standing line tall and the body rounded.", "notConnected": "Keep the form joined where it connects."}, "signedOff": false}
{"id": "taa_h.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.taair"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is taa_h. ?????!", "wrongLetter": "Listen again ? ???? starts with taa_h. rounded body, tall line"}, "signedOff": false}
{"id": "taa_h.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.child", "caption": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ??? starts with taa_h. ?????!", "wrongLetter": "Look again ? start with taa_h. rounded body, tall line"}, "signedOff": false}
{"id": "taa_h.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write taa_h in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? rounded body and tall line. ?????!", "wrongLetter": "Try taa_h again ? rounded body, tall line"}, "signedOff": false}
{"id": "taa_h.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.taair"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ????."}, "signedOff": false}
{"id": "taa_h.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ???."}, "signedOff": false}
{"id": "taa_h.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.potato", "caption": "?????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "????? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ?????."}, "signedOff": false}
{"id": "taa_h.connectWord.taair", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "???? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "taa_h.connectWord.tifl", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "taa_h.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "middle taa_h in ?????.", "prompt": [{"kind": "say", "line": "Fill in the missing taa_h to finish the word."}, {"kind": "text", "text": "?????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "Complete! ?????. ?????!", "incomplete": "Fill in the missing taa_h to finish the word."}, "signedOff": false}
{"id": "taa_h.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ????."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??????"}}, "check": "sequence+transformRule", "feedback": {"pass": "?????? ? ?????!", "missingEnding": "Add the ending: ??????."}, "signedOff": false}
{"id": "taa_h.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (????).", "prompt": [{"kind": "say", "line": "Write the plural of ????."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "missingEnding": "Look again ? the plural is ????."}, "signedOff": false}
{"id": "taa_h.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ????????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ????."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite is ????."}, "signedOff": false}
{"id": "taa_h.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "Yes ? ???? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "taa_h.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.attaairu-yatiir"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["???????", "????"]}, "check": "order+sequence", "feedback": {"pass": "??????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ??????? ????."}, "signedOff": false}
{"id": "taa_h.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.potato", "caption": "?????"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "taair", "text": "????", "audio": "word.taair", "image": "img.bird", "gloss": {"en": "bird"}, "letters": ["taa_h", "alif", "yaa", "raa"], "signedOff": false}
{"id": "tifl", "text": "???", "audio": "word.tifl", "image": "img.child", "gloss": {"en": "child"}, "letters": ["taa_h", "faa", "laam"], "signedOff": false}
{"id": "tamaatim", "text": "?????", "audio": "word.tamaatim", "image": "img.tomatoes", "gloss": {"en": "tomatoes"}, "letters": ["taa_h", "meem", "alif", "taa_h", "meem"], "signedOff": false}
{"id": "batata", "text": "?????", "audio": "word.batata", "image": "img.potato", "gloss": {"en": "potato"}, "letters": ["baa", "taa_h", "alif", "taa_h", "alif"], "signedOff": false}
{"id": "matbakh", "text": "????", "audio": "word.matbakh", "image": "img.kitchen", "gloss": {"en": "kitchen"}, "letters": ["meem", "taa_h", "baa", "khaa"], "signedOff": false}
```

## Sign-Off Checklist for Owner-Mother

- [ ] Word list - keep / swap?
- [ ] Stroke story: rounded body, tall line - correct?
- [ ] Grammar transforms: dual `??????`, plural `????`, opposite `???? -> ????` - correct and age-right?
- [ ] Sentence choices: `??????? ????`, `?????? ????` - keep / swap?
