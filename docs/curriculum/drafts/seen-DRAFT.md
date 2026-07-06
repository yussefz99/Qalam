# Curriculum Draft - ??? ? seen (letter 12)

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| ??? (seen) | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## ??? - seen (?)

**Char:** ? ? **Intro order:** 12 ? **Family:** seen/sheen teeth family
**Forms:** isolated ? ? initial ?? ? medial ??? ? final ??
**Strokes (drafted, signed-at-letter pending):** three small teeth, then a bowl; no dots
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Translit | Gloss | seen form | Letters | Source | Audio id | Image id |
|---|---|---|---|---|---|---|---|---|
| fish | ??? | samak | fish | initial | ? ? ? | [DRAFT] | `word.samak` new | `img.fish` new |
| car | ????? | sayyara | car | initial | ? ? ? ? ? | [DRAFT] | `word.sayyara` new | `img.car` new |
| fish | ???? | samakah | fish | initial | ? ? ? ? | [DRAFT] | `word.samakah` new | `img.fish` reuse |
| chair | ???? | kursi | chair | medial | ? ? ? ? | [DRAFT] | `word.kursi` new | `img.chair` new |
| sun | ??? | shams | sun | final | ? ? ? | [DRAFT] | `word.shams` new | `img.sun` new |

### Exercise Set

```json
{"id": "seen.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.seen"}, {"kind": "image", "imageId": "img.fish", "caption": "??? ? samak"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "seen.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Make three small teeth, then the final bowl."}, {"kind": "audio", "audioId": "snd.seen"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? three teeth and a smooth bowl. ?????!", "wrongShape": "Make the three teeth small and even, then finish with the bowl.", "tooFlat": "Let the last part curve down into a bowl ? slower this time."}, "signedOff": false}
{"id": "seen.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, seen is three small teeth that reach forward."}, {"kind": "audio", "audioId": "snd.seen"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? three neat starting teeth. ?????!", "wrongShape": "Keep the teeth small and close together.", "tooBig": "Smaller teeth here ? seen starts low and neat."}, "signedOff": false}
{"id": "seen.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, seen is three teeth between two joining lines."}, {"kind": "audio", "audioId": "snd.seen"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined on both sides with small teeth. ?????!", "wrongShape": "Keep the three teeth clear as you connect.", "notConnected": "Keep the line joined on both sides of seen."}, "signedOff": false}
{"id": "seen.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.samak"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is seen. ?????!", "wrongLetter": "Listen again ? ??? starts with seen, three small teeth."}, "signedOff": false}
{"id": "seen.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.car", "caption": "?????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ????? starts with seen. ?????!", "wrongLetter": "Look again ? ????? starts with seen, three little teeth."}, "signedOff": false}
{"id": "seen.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write seen in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? three teeth and the bowl. ?????!", "wrongLetter": "Try seen again ? three teeth, then the bowl."}, "signedOff": false}
{"id": "seen.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.samak"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ???. Start with seen."}, "signedOff": false}
{"id": "seen.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "?????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "????? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ?????."}, "signedOff": false}
{"id": "seen.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.chair", "caption": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ????."}, "signedOff": false}
{"id": "seen.connectWord.samak", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined ? one flowing word, no lifts."}, "signedOff": false}
{"id": "seen.connectWord.sayyara", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "????? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "seen.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "medial seen in ????.", "prompt": [{"kind": "say", "line": "Fill in the missing seen to finish the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "Complete! ????. ?????!", "incomplete": "Fill in the missing seen to finish the word."}, "signedOff": false}
{"id": "seen.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ????."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??????"}}, "check": "sequence+transformRule", "feedback": {"pass": "?????? ? ?????!", "missingEnding": "Add the ending: ??????."}, "signedOff": false}
{"id": "seen.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (?????).", "prompt": [{"kind": "say", "line": "Write the plural of ????."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "missingEnding": "Look again ? the plural is ????."}, "signedOff": false}
{"id": "seen.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ????????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ????."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite of fast is slow ? ????."}, "signedOff": false}
{"id": "seen.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Yes ? ??? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "seen.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.assamak-ladhiidh"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? ?the fish is tasty.? A whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
{"id": "seen.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.car", "caption": "?????"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["????????", "?????"]}, "check": "order+sequence", "feedback": {"pass": "???????? ????? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ???????? ?????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "samak", "text": "???", "audio": "word.samak", "image": "img.fish", "gloss": {"en": "fish"}, "letters": ["seen", "meem", "kaaf"], "signedOff": false}
{"id": "sayyara", "text": "?????", "audio": "word.sayyara", "image": "img.car", "gloss": {"en": "car"}, "letters": ["seen", "yaa", "alif", "raa", "taa_marbuta"], "signedOff": false}
{"id": "samakah", "text": "????", "audio": "word.samakah", "image": "img.fish", "gloss": {"en": "fish"}, "letters": ["seen", "meem", "kaaf", "taa_marbuta"], "signedOff": false}
{"id": "kursi", "text": "????", "audio": "word.kursi", "image": "img.chair", "gloss": {"en": "chair"}, "letters": ["kaaf", "raa", "seen", "yaa"], "signedOff": false}
{"id": "shams", "text": "???", "audio": "word.shams", "image": "img.sun", "gloss": {"en": "sun"}, "letters": ["sheen", "meem", "seen"], "signedOff": false}
```

## Asset Manifest

### Audio
- `snd.seen`, `word.samak`, `word.sayyara`, `word.samakah`, `word.kursi`, `word.shams`, `sentence.assamak-ladhiidh`

### Images
- `img.fish`, `img.car`, `img.chair`, `img.sun`

## Sign-Off Checklist for Owner-Mother

- [ ] Word list: fish ? car ? fish/fish-with-taa-marbuta ? chair ? sun - keep / swap?
- [ ] Stroke story: three small teeth, then a bowl, no dots - correct?
- [ ] Grammar transforms: dual `??????`, plural `????`, opposite `???? -> ????` - correct and age-right?
- [ ] Sentence choices: `?????? ????`, `???????? ?????` - keep / swap?
