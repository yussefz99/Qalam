# Curriculum Draft - ? ? laam

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| laam | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## laam

**Char:** ? ? **Family:** laam tall-stem family
**Strokes (drafted, signed-at-letter pending):** tall line, bottom hook
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Gloss | Source | Audio id | Image id |
|---|---|---|---|---|---|
| laymun | ????? | lemon | [DRAFT] | `word.laymun` | `img.lemon` |
| laban | ??? | yogurt | [DRAFT] | `word.laban` | `img.yogurt` |
| lisaan | ???? | tongue | [DRAFT] | `word.lisaan` | `img.tongue` |
| qalam_laam | ??? | pen | [DRAFT] | `word.qalam` | `img.pen` |
| jabal_laam | ??? | mountain | [DRAFT] | `word.jabal` | `img.mountain` |

### Exercise Set

```json
{"id": "laam.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.laam"}, {"kind": "image", "imageId": "img.lemon", "caption": "????? ? laymun"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "laam.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Start tall, come down, then hook along the bottom."}, {"kind": "audio", "audioId": "snd.laam"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? tall line and bottom hook. ?????!", "wrongShape": "Start at the top, come down, then make the bottom hook.", "noDot": "Start at the top, come down, then make the bottom hook."}, "signedOff": false}
{"id": "laam.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, laam is tall and reaches forward."}, {"kind": "audio", "audioId": "snd.laam"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? smooth and clean. ?????!", "wrongShape": "Start at the top, come down, then make the bottom hook.", "noDot": "Start at the top, come down, then make the bottom hook."}, "signedOff": false}
{"id": "laam.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, laam joins through a tall stroke."}, {"kind": "audio", "audioId": "snd.laam"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined clearly. ?????!", "wrongShape": "Start at the top, come down, then make the bottom hook.", "notConnected": "Keep the form joined where it connects."}, "signedOff": false}
{"id": "laam.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.laymun"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is laam. ?????!", "wrongLetter": "Listen again ? ????? starts with laam. tall line, bottom hook"}, "signedOff": false}
{"id": "laam.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.yogurt", "caption": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ??? starts with laam. ?????!", "wrongLetter": "Look again ? start with laam. tall line, bottom hook"}, "signedOff": false}
{"id": "laam.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write laam in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? tall line and bottom hook. ?????!", "wrongLetter": "Try laam again ? tall line, bottom hook"}, "signedOff": false}
{"id": "laam.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.laymun"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "????? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ?????."}, "signedOff": false}
{"id": "laam.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ???."}, "signedOff": false}
{"id": "laam.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.pen", "caption": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ???."}, "signedOff": false}
{"id": "laam.connectWord.laymun", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "????? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "laam.connectWord.laban", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "laam.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "middle laam in ???.", "prompt": [{"kind": "say", "line": "Fill in the missing laam to finish the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Complete! ???. ?????!", "incomplete": "Fill in the missing laam to finish the word."}, "signedOff": false}
{"id": "laam.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ???."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "missingEnding": "Add the ending: ?????."}, "signedOff": false}
{"id": "laam.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (?????).", "prompt": [{"kind": "say", "line": "Write the plural of ???."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "missingEnding": "Look again ? the plural is ?????."}, "signedOff": false}
{"id": "laam.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ???????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ???."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite is ????."}, "signedOff": false}
{"id": "laam.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "?????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "Yes ? ????? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "laam.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.allaymunu-asfar"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["????????", "????"]}, "check": "order+sequence", "feedback": {"pass": "???????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ???????? ????."}, "signedOff": false}
{"id": "laam.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.pen", "caption": "???"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "laymun", "text": "?????", "audio": "word.laymun", "image": "img.lemon", "gloss": {"en": "lemon"}, "letters": ["laam", "yaa", "meem", "waaw", "noon"], "signedOff": false}
{"id": "laban", "text": "???", "audio": "word.laban", "image": "img.yogurt", "gloss": {"en": "yogurt"}, "letters": ["laam", "baa", "noon"], "signedOff": false}
{"id": "lisaan", "text": "????", "audio": "word.lisaan", "image": "img.tongue", "gloss": {"en": "tongue"}, "letters": ["laam", "seen", "alif", "noon"], "signedOff": false}
{"id": "qalam_laam", "text": "???", "audio": "word.qalam", "image": "img.pen", "gloss": {"en": "pen"}, "letters": ["qaaf", "laam", "meem"], "signedOff": false}
{"id": "jabal_laam", "text": "???", "audio": "word.jabal", "image": "img.mountain", "gloss": {"en": "mountain"}, "letters": ["jeem", "baa", "laam"], "signedOff": false}
```

## Sign-Off Checklist for Owner-Mother

- [ ] Word list - keep / swap?
- [ ] Stroke story: tall line, bottom hook - correct?
- [ ] Grammar transforms: dual `?????`, plural `?????`, opposite `??? -> ????` - correct and age-right?
- [ ] Sentence choices: `???????? ????`, `?????? ????` - keep / swap?
