# Curriculum Draft - ??? ? zaay (letter 11)

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| ??? (zaay) | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## ??? - zaay (?)

**Char:** ? ? **Intro order:** 11 ? **Family:** raa/zaay descender family
**Forms:** isolated ? ? initial ? ? medial ?? ? final ??
**Strokes (drafted, signed-at-letter pending):** one curve dipping below the line, one dot above
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Translit | Gloss | zaay form | Letters | Source | Audio id | Image id |
|---|---|---|---|---|---|---|---|---|
| oil | ??? | zayt | oil | initial | ? ? ? | [DRAFT] | `word.zayt` new | `img.oil` new |
| flower | ???? | zahra | flower | initial | ? ? ? ? | [DRAFT] | `word.zahra` new | `img.flower` new |
| giraffe | ????? | zuraafa | giraffe | initial | ? ? ? ? ? | [DRAFT] | `word.zuraafa` new | `img.giraffe` new |
| banana | ??? | mawz | banana | final | ? ? ? | [DRAFT] | `word.mawz` new | `img.banana` new |
| carrots | ??? | jazar | carrots | medial | ? ? ? | [DRAFT/reuse] | `word.jazar` reuse | `img.carrots` reuse |

### Exercise Set

```json
{"id": "zaay.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.zaay"}, {"kind": "image", "imageId": "img.oil", "caption": "??? ? zayt"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "zaay.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Curve down like raa, then add one dot above."}, {"kind": "audio", "audioId": "snd.zaay"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? the curve drops down and the dot sits above. ?????!", "wrongShape": "Let the curve dip down below the line ? slower this time.", "noDot": "Good curve ? now add one dot above to make zaay."}, "signedOff": false}
{"id": "zaay.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Zaay keeps the same curve, with one dot above."}, {"kind": "audio", "audioId": "snd.zaay"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? a clean zaay curve with its dot. ?????!", "wrongShape": "Curve down gently ? not a straight line.", "noDot": "Add the dot above ? that dot makes it zaay."}, "signedOff": false}
{"id": "zaay.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, zaay joins from before, curves down, then dot above."}, {"kind": "audio", "audioId": "snd.zaay"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined from before, dot above. ?????!", "wrongShape": "Keep the curve soft after the joining line.", "noDot": "Add the dot above ? zaay needs that dot."}, "signedOff": false}
{"id": "zaay.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.zayt"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is zaay. ?????!", "wrongLetter": "Listen again ? ??? starts with zaay, the curve with a dot above."}, "signedOff": false}
{"id": "zaay.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.flower", "caption": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ???? starts with zaay. ?????!", "wrongLetter": "Look again ? ???? starts with zaay, one dot above."}, "signedOff": false}
{"id": "zaay.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write zaay in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? curve and one dot above. ?????!", "wrongLetter": "Try zaay again ? one curve, one dot above."}, "signedOff": false}
{"id": "zaay.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.zayt"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "missingDot": "Close ? your zaay needs one dot above. Listen again: ???."}, "signedOff": false}
{"id": "zaay.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ????."}, "signedOff": false}
{"id": "zaay.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.banana", "caption": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ???."}, "signedOff": false}
{"id": "zaay.connectWord.zayt", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the letters together as one word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? written as one word. ?????!", "lifted": "Keep the word close and orderly ? zaay stops, then the next letter begins."}, "signedOff": false}
{"id": "zaay.connectWord.zuraafa", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the letters together as one word."}, {"kind": "text", "text": "?  ?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "????? ? written as one word. ?????!", "lifted": "Keep the letters close and in order."}, "signedOff": false}
{"id": "zaay.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "medial zaay in ???.", "prompt": [{"kind": "say", "line": "Fill in the missing zaay to finish the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Complete! ???. ?????!", "incomplete": "Fill in the missing zaay to finish the word."}, "signedOff": false}
{"id": "zaay.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ????."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??????"}}, "check": "sequence+transformRule", "feedback": {"pass": "?????? ? ?????!", "missingEnding": "Add the ending: ??????."}, "signedOff": false}
{"id": "zaay.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (?????).", "prompt": [{"kind": "say", "line": "Write the plural of ????."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "missingEnding": "Look again ? the plural is ?????."}, "signedOff": false}
{"id": "zaay.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ??????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ???."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+transformRule", "feedback": {"pass": "??? ? ?????!", "wrongWord": "The opposite of increased is decreased ? ???."}, "signedOff": false}
{"id": "zaay.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Yes ? ??? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "zaay.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.azahratu-jamiila"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["???????", "?????"]}, "check": "order+sequence", "feedback": {"pass": "??????? ????? ? ?the flower is beautiful.? A whole sentence! ?????!", "wrongOrder": "Keep the words in order: ??????? ?????."}, "signedOff": false}
{"id": "zaay.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.banana", "caption": "???"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "zayt", "text": "???", "audio": "word.zayt", "image": "img.oil", "gloss": {"en": "oil"}, "letters": ["zaay", "yaa", "taa"], "signedOff": false}
{"id": "zahra", "text": "????", "audio": "word.zahra", "image": "img.flower", "gloss": {"en": "flower"}, "letters": ["zaay", "haa_f", "raa", "taa_marbuta"], "signedOff": false}
{"id": "zuraafa", "text": "?????", "audio": "word.zuraafa", "image": "img.giraffe", "gloss": {"en": "giraffe"}, "letters": ["zaay", "raa", "alif", "faa", "taa_marbuta"], "signedOff": false}
{"id": "mawz", "text": "???", "audio": "word.mawz", "image": "img.banana", "gloss": {"en": "banana"}, "letters": ["meem", "waaw", "zaay"], "signedOff": false}
{"id": "jazar", "text": "???", "audio": "word.jazar", "image": "img.carrots", "gloss": {"en": "carrots"}, "letters": ["jeem", "zaay", "raa"], "signedOff": false}
```

## Asset Manifest

### Audio
- `snd.zaay`, `word.zayt`, `word.zahra`, `word.zuraafa`, `word.mawz`, `sentence.azahratu-jamiila`
- Reused: `word.jazar`

### Images
- `img.oil`, `img.flower`, `img.giraffe`, `img.banana`
- Reused: `img.carrots`

## Sign-Off Checklist for Owner-Mother

- [ ] Word list: oil ? flower ? giraffe ? banana ? carrots - keep / swap?
- [ ] Stroke story: curve dipping below line, one dot above - correct?
- [ ] Non-connecting zaay wording in connect-word exercises is correct?
- [ ] Grammar transforms: dual `??????`, plural `?????`, opposite `??? -> ???` - correct and age-right?
- [ ] Sentence choices: `??????? ?????`, `?????? ????` - keep / swap?
