# Curriculum Draft - ??? ? raa (letter 10)

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| ??? (raa) | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## ??? - raa (?)

**Char:** ? ? **Intro order:** 10 ? **Family:** raa/zaay descender family
**Forms:** isolated ? ? initial ? ? medial ?? ? final ??
**Strokes (drafted, signed-at-letter pending):** one curve dipping below the line, no dot
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Translit | Gloss | raa form | Letters | Source | Audio id | Image id |
|---|---|---|---|---|---|---|---|---|
| head | ??? | ras | head | initial | ? ? ? | [DRAFT] | `word.ras` new | `img.head` new |
| leg | ??? | rijl | leg | initial | ? ? ? | [DRAFT] | `word.rijl` new | `img.leg` new |
| pomegranate | ???? | rumman | pomegranate | initial | ? ? ? ? | [DRAFT] | `word.rumman` new | `img.pomegranate` new |
| moon | ??? | qamar | moon | final | ? ? ? | [DRAFT] | `word.qamar` new | `img.moon` new |
| bed | ???? | sareer | bed | medial/final | ? ? ? ? | [DRAFT] | `word.sareer` new | `img.bed` new |

### Exercise Set

```json
{"id": "raa.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.raa"}, {"kind": "image", "imageId": "img.head", "caption": "??? ? ras"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "raa.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Start high, then curve down below the line."}, {"kind": "audio", "audioId": "snd.raa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? the curve drops down smoothly. ?????!", "wrongShape": "Let the curve dip down below the line ? slower this time.", "tooShort": "Bring raa lower ? it needs a small tail below."}, "signedOff": false}
{"id": "raa.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Raa keeps its same curve at the start of a word."}, {"kind": "audio", "audioId": "snd.raa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? a clean raa curve. ?????!", "wrongShape": "Curve down gently ? not a straight line.", "tooShort": "Let the tail drop a little lower."}, "signedOff": false}
{"id": "raa.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, raa joins from before and curves down."}, {"kind": "audio", "audioId": "snd.raa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined from before, then the curve drops. ?????!", "wrongShape": "Keep the curve soft after the joining line.", "tooShort": "Let raa dip below the line."}, "signedOff": false}
{"id": "raa.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.ras"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is raa. ?????!", "wrongLetter": "Listen again ? ??? starts with raa, the curve with no dot."}, "signedOff": false}
{"id": "raa.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.pomegranate", "caption": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ???? starts with raa. ?????!", "wrongLetter": "Look again ? ???? starts with raa, no dot."}, "signedOff": false}
{"id": "raa.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write raa in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? a smooth raa curve. ?????!", "wrongLetter": "Try raa again ? one curve, no dot."}, "signedOff": false}
{"id": "raa.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.ras"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ???. Start with raa."}, "signedOff": false}
{"id": "raa.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ????."}, "signedOff": false}
{"id": "raa.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.moon", "caption": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ???."}, "signedOff": false}
{"id": "raa.connectWord.ras", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the letters together as one word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? written as one word. ?????!", "lifted": "Keep the word close and orderly ? raa stops, then the next letter begins."}, "signedOff": false}
{"id": "raa.connectWord.rijl", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the letters together as one word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? written as one word. ?????!", "lifted": "Keep the letters close and in order."}, "signedOff": false}
{"id": "raa.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "medial raa in ????.", "prompt": [{"kind": "say", "line": "Fill in the missing raa to finish the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "Complete! ????. ?????!", "incomplete": "Fill in the missing raa to finish the word."}, "signedOff": false}
{"id": "raa.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ????."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??????"}}, "check": "sequence+transformRule", "feedback": {"pass": "?????? ? ?????!", "missingEnding": "Add the ending: ??????."}, "signedOff": false}
{"id": "raa.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (????).", "prompt": [{"kind": "say", "line": "Write the plural of ????."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "missingEnding": "Look again ? the plural is ????."}, "signedOff": false}
{"id": "raa.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ??????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ???."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+transformRule", "feedback": {"pass": "??? ? ?????!", "wrongWord": "The opposite of wet is dry ? ???."}, "signedOff": false}
{"id": "raa.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Yes ? ??? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "raa.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.arummanu-ahmar"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["???????", "????"]}, "check": "order+sequence", "feedback": {"pass": "??????? ???? ? ?the pomegranate is red.? A whole sentence! ?????!", "wrongOrder": "Keep the words in order: ??????? ????."}, "signedOff": false}
{"id": "raa.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.moon", "caption": "???"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "ras", "text": "???", "audio": "word.ras", "image": "img.head", "gloss": {"en": "head"}, "letters": ["raa", "alif", "seen"], "signedOff": false}
{"id": "rijl", "text": "???", "audio": "word.rijl", "image": "img.leg", "gloss": {"en": "leg"}, "letters": ["raa", "jeem", "laam"], "signedOff": false}
{"id": "rumman", "text": "????", "audio": "word.rumman", "image": "img.pomegranate", "gloss": {"en": "pomegranate"}, "letters": ["raa", "meem", "alif", "noon"], "signedOff": false}
{"id": "qamar", "text": "???", "audio": "word.qamar", "image": "img.moon", "gloss": {"en": "moon"}, "letters": ["qaaf", "meem", "raa"], "signedOff": false}
{"id": "sareer", "text": "????", "audio": "word.sareer", "image": "img.bed", "gloss": {"en": "bed"}, "letters": ["seen", "raa", "yaa", "raa"], "signedOff": false}
```

## Asset Manifest

### Audio
- `snd.raa`, `word.ras`, `word.rijl`, `word.rumman`, `word.qamar`, `word.sareer`, `sentence.arummanu-ahmar`

### Images
- `img.head`, `img.leg`, `img.pomegranate`, `img.moon`, `img.bed`

## Sign-Off Checklist for Owner-Mother

- [ ] Word list: head ? leg ? pomegranate ? moon ? bed - keep / swap?
- [ ] Stroke story: curve dipping below line, no dot - correct?
- [ ] Non-connecting raa wording in connect-word exercises is correct?
- [ ] Grammar transforms: dual `??????`, plural `????`, opposite `??? -> ???` - correct and age-right?
- [ ] Sentence choices: `??????? ????`, `?????? ????` - keep / swap?
