# Curriculum Draft - ??? ? sheen (letter 13)

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| ??? (sheen) | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## ??? - sheen (?)

**Char:** ? ? **Intro order:** 13 ? **Family:** seen/sheen teeth family
**Forms:** isolated ? ? initial ?? ? medial ??? ? final ??
**Strokes (drafted, signed-at-letter pending):** three small teeth, then a bowl; three dots above
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Translit | Gloss | sheen form | Letters | Source | Audio id | Image id |
|---|---|---|---|---|---|---|---|---|
| sun | ??? | shams | sun | initial | ? ? ? | [DRAFT] | `word.shams` new/reuse | `img.sun` new/reuse |
| tree | ???? | shajara | tree | initial | ? ? ? ? | [DRAFT] | `word.shajara` new | `img.tree` new |
| window | ???? | shubbaak | window | initial | ? ? ? ? | [DRAFT] | `word.shubbaak` new | `img.window` new |
| butterfly | ????? | farasha | butterfly | medial | ? ? ? ? ? | [DRAFT] | `word.farasha` new | `img.butterfly` new |
| nest | ?? | aash | nest | final | ? ? | [DRAFT] | `word.aash` new | `img.nest` new |

### Exercise Set

```json
{"id": "sheen.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.sheen"}, {"kind": "image", "imageId": "img.sun", "caption": "??? ? shams"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "sheen.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Make three small teeth and a bowl, then three dots above."}, {"kind": "audio", "audioId": "snd.sheen"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? three teeth, a smooth bowl, and three dots above. ?????!", "wrongShape": "Make the three teeth small and even, then finish with the bowl.", "noDot": "Good seen-shape ? now add three dots above to make sheen."}, "signedOff": false}
{"id": "sheen.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, sheen is three small teeth with three dots above."}, {"kind": "audio", "audioId": "snd.sheen"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? three neat teeth and three dots. ?????!", "wrongShape": "Keep the teeth small and close together.", "noDot": "Add the three dots above ? that makes it sheen."}, "signedOff": false}
{"id": "sheen.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, sheen is three teeth between joins, with three dots above."}, {"kind": "audio", "audioId": "snd.sheen"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined on both sides, three dots above. ?????!", "wrongShape": "Keep the three teeth clear as you connect.", "noDot": "Now add the three dots above the teeth."}, "signedOff": false}
{"id": "sheen.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.shams"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is sheen. ?????!", "wrongLetter": "Listen again ? ??? starts with sheen, three teeth and three dots."}, "signedOff": false}
{"id": "sheen.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.tree", "caption": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ???? starts with sheen. ?????!", "wrongLetter": "Look again ? ???? starts with sheen, three dots above."}, "signedOff": false}
{"id": "sheen.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write sheen in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? three teeth, bowl, and three dots. ?????!", "wrongLetter": "Try sheen again ? three teeth and three dots above."}, "signedOff": false}
{"id": "sheen.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.shams"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "missingDot": "Close ? your sheen needs three dots above. Listen again: ???."}, "signedOff": false}
{"id": "sheen.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ????."}, "signedOff": false}
{"id": "sheen.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.butterfly", "caption": "?????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "????? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ?????."}, "signedOff": false}
{"id": "sheen.connectWord.shams", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined ? one flowing word, no lifts."}, "signedOff": false}
{"id": "sheen.connectWord.shajara", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "???? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "sheen.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "medial sheen in ?????.", "prompt": [{"kind": "say", "line": "Fill in the missing sheen to finish the word."}, {"kind": "text", "text": "?????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "Complete! ?????. ?????!", "incomplete": "Fill in the missing sheen to finish the word."}, "signedOff": false}
{"id": "sheen.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ????."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??????"}}, "check": "sequence+transformRule", "feedback": {"pass": "?????? ? ?????!", "missingEnding": "Add the ending: ??????."}, "signedOff": false}
{"id": "sheen.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (?????).", "prompt": [{"kind": "say", "line": "Write the plural of ????."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "missingEnding": "Look again ? the plural is ?????."}, "signedOff": false}
{"id": "sheen.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ????????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ????."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite of brave is afraid ? ????."}, "signedOff": false}
{"id": "sheen.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Yes ? ??? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "sheen.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.ashshamsu-daafia"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "?????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ????? ? ?the sun is warm.? A whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ?????."}, "signedOff": false}
{"id": "sheen.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.tree", "caption": "????"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["???????", "?????"]}, "check": "order+sequence", "feedback": {"pass": "??????? ????? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ??????? ?????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "shams_sheen", "text": "???", "audio": "word.shams", "image": "img.sun", "gloss": {"en": "sun"}, "letters": ["sheen", "meem", "seen"], "signedOff": false}
{"id": "shajara", "text": "????", "audio": "word.shajara", "image": "img.tree", "gloss": {"en": "tree"}, "letters": ["sheen", "jeem", "raa", "taa_marbuta"], "signedOff": false}
{"id": "shubbaak", "text": "????", "audio": "word.shubbaak", "image": "img.window", "gloss": {"en": "window"}, "letters": ["sheen", "baa", "alif", "kaaf"], "signedOff": false}
{"id": "farasha", "text": "?????", "audio": "word.farasha", "image": "img.butterfly", "gloss": {"en": "butterfly"}, "letters": ["faa", "raa", "alif", "sheen", "taa_marbuta"], "signedOff": false}
{"id": "aash", "text": "??", "audio": "word.aash", "image": "img.nest", "gloss": {"en": "nest"}, "letters": ["ayn", "sheen"], "signedOff": false}
```

## Asset Manifest

### Audio
- `snd.sheen`, `word.shams`, `word.shajara`, `word.shubbaak`, `word.farasha`, `word.aash`, `sentence.ashshamsu-daafia`

### Images
- `img.sun`, `img.tree`, `img.window`, `img.butterfly`, `img.nest`

## Sign-Off Checklist for Owner-Mother

- [ ] Word list: sun ? tree ? window ? butterfly ? nest - keep / swap?
- [ ] Stroke story: three teeth, bowl, three dots above - correct?
- [ ] Grammar transforms: dual `??????`, plural `?????`, opposite `???? -> ????` - correct and age-right?
- [ ] Sentence choices: `?????? ?????`, `??????? ?????` - keep / swap?
