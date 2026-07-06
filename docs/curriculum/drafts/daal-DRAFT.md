# Curriculum Draft - ??? ? daal (letter 8)

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

---

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| ??? (daal) | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

---

## ??? - daal (?)

**Char:** ? ? **Intro order:** 8 ? **Family:** daal/dhaal hook family
**Forms:** isolated ? ? initial ? ? medial ?? ? final ??
**Strokes (drafted, signed-at-letter pending):** one compact hook, no dot
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Translit | Gloss | daal form | Letters | Source | Audio id | Image id |
|---|---|---|---|---|---|---|---|---|
| bear | ?? | dubb | bear | initial | ? ? | [DRAFT] | `word.dubb` new | `img.bear` new |
| house | ??? | daar | house | initial | ? ? ? | [DRAFT] | `word.daar` new | `img.house` reuse/new confirm |
| bucket | ??? | dalw | bucket | initial | ? ? ? | [DRAFT] | `word.dalw` new | `img.bucket` new |
| hand | ?? | yad | hand | final | ? ? | [DRAFT] | `word.yad` new | `img.hand` new |
| school | ????? | madrasa | school | medial | ? ? ? ? ? | [DRAFT] | `word.madrasa` new | `img.school` new |

### Exercise Set

```json
{"id": "daal.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.daal"}, {"kind": "image", "imageId": "img.bear", "caption": "?? ? dubb"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "daal.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Start at the top and make a short hook down and left."}, {"kind": "audio", "audioId": "snd.daal"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? short hook, smooth turn. ?????!", "wrongShape": "Make the hook shorter and cleaner ? down, then a small turn left.", "tooLong": "Daal is compact ? keep the hook short."}, "signedOff": false}
{"id": "daal.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Daal keeps the same small hook at the start of a word."}, {"kind": "audio", "audioId": "snd.daal"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? the small daal hook. ?????!", "wrongShape": "Keep it like a small hook ? not a long curve.", "tooLong": "A little shorter ? daal does not stretch forward."}, "signedOff": false}
{"id": "daal.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, daal joins from before and keeps its short hook."}, {"kind": "audio", "audioId": "snd.daal"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined from before, short hook after. ?????!", "wrongShape": "Keep the hook compact after the joining line.", "tooLong": "Daal stops here ? do not stretch it into the next letter."}, "signedOff": false}
{"id": "daal.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.dubb"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is daal. ?????!", "wrongLetter": "Listen again ? ?? starts with daal, a short hook."}, "signedOff": false}
{"id": "daal.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.bucket", "caption": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ??? starts with daal. ?????!", "wrongLetter": "Look again ? ??? starts with the short daal hook."}, "signedOff": false}
{"id": "daal.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write daal in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? short and clear. ?????!", "wrongLetter": "Try daal again ? a short hook, no dot."}, "signedOff": false}
{"id": "daal.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.dubb"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??"}}, "check": "sequence", "feedback": {"pass": "?? ? from memory. Real writing! ?????!", "incomplete": "Look again and write both letters.", "wrongWord": "Listen again: ??. Start with the short daal hook."}, "signedOff": false}
{"id": "daal.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ???."}, "signedOff": false}
{"id": "daal.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.hand", "caption": "??"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??"}}, "check": "sequence", "feedback": {"pass": "?? ? from memory. ?????!", "incomplete": "Look again and write both letters.", "wrongWord": "That is a different word ? look at the picture and try ??."}, "signedOff": false}
{"id": "daal.connectWord.dubb", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the letters together as one word."}, {"kind": "text", "text": "?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "?? ? the letters sit close as one word. ?????!", "lifted": "Keep the letters close together ? daal stops, then baa begins."}, "signedOff": false}
{"id": "daal.connectWord.dalw", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the letters together as one word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? written as one word. ?????!", "lifted": "Keep the word close and orderly ? ? then ??."}, "signedOff": false}
{"id": "daal.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "medial daal in ?????.", "prompt": [{"kind": "say", "line": "Fill in the missing daal to finish the word."}, {"kind": "text", "text": "?????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "Complete! ?????. ?????!", "incomplete": "Fill in the missing daal to finish the word."}, "signedOff": false}
{"id": "daal.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ??."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "??"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "missingEnding": "Add the ending: ????."}, "signedOff": false}
{"id": "daal.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (????).", "prompt": [{"kind": "say", "line": "Write the plural of ??."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "??"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "missingEnding": "Look again ? the plural is ????."}, "signedOff": false}
{"id": "daal.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ????????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ????."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite of inside is outside ? ????."}, "signedOff": false}
{"id": "daal.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "??"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??"}}, "check": "sequence", "feedback": {"pass": "Yes ? ?? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "daal.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.addubbu-kabeer"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["?????", "????"]}, "check": "order+sequence", "feedback": {"pass": "????? ???? ? ?the bear is big.? A whole sentence! ?????!", "wrongOrder": "Keep the words in order: ????? ????."}, "signedOff": false}
{"id": "daal.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.bucket", "caption": "???"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
```

---

## `words.json` Additions

```json
{"id": "dubb", "text": "??", "audio": "word.dubb", "image": "img.bear", "gloss": {"en": "bear"}, "letters": ["daal", "baa"], "signedOff": false}
{"id": "daar", "text": "???", "audio": "word.daar", "image": "img.house", "gloss": {"en": "house"}, "letters": ["daal", "alif", "raa"], "signedOff": false}
{"id": "dalw", "text": "???", "audio": "word.dalw", "image": "img.bucket", "gloss": {"en": "bucket"}, "letters": ["daal", "laam", "waaw"], "signedOff": false}
{"id": "yad", "text": "??", "audio": "word.yad", "image": "img.hand", "gloss": {"en": "hand"}, "letters": ["yaa", "daal"], "signedOff": false}
{"id": "madrasa", "text": "?????", "audio": "word.madrasa", "image": "img.school", "gloss": {"en": "school"}, "letters": ["meem", "daal", "raa", "seen", "taa_marbuta"], "signedOff": false}
```

---

## Asset Manifest

### Audio
- `snd.daal`, `word.dubb`, `word.daar`, `word.dalw`, `word.yad`, `word.madrasa`, `sentence.addubbu-kabeer`

### Images
- `img.bear`, `img.house`, `img.bucket`, `img.hand`, `img.school`

---

## Sign-Off Checklist for Owner-Mother

- [ ] Word list: bear ? house ? bucket ? hand ? school - keep / swap?
- [ ] Stroke story: compact hook, no dot - correct?
- [ ] Non-connecting daal wording in connect-word exercises is correct?
- [ ] Grammar transforms: dual `????`, plural `????`, opposite `???? -> ????` - correct and age-right?
- [ ] Sentence choices: `????? ????`, `?????? ????` - keep / swap?
