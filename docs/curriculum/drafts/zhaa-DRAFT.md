# Curriculum Draft - ? ? zhaa

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| zhaa | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## zhaa

**Char:** ? ? **Family:** taa_h/zhaa emphatic stem family
**Strokes (drafted, signed-at-letter pending):** rounded body, tall line, dot above
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Gloss | Source | Audio id | Image id |
|---|---|---|---|---|---|
| zarf | ??? | envelope | [DRAFT] | `word.zarf` | `img.envelope` |
| zill | ?? | shadow | [DRAFT] | `word.zill` | `img.shadow` |
| zaby | ??? | gazelle | [DRAFT] | `word.zaby` | `img.gazelle` |
| nazzara | ????? | glasses | [DRAFT] | `word.nazzara` | `img.glasses` |
| hafiz | ???? | guard | [DRAFT] | `word.hafiz` | `img.guard` |

### Exercise Set

```json
{"id": "zhaa.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.zhaa"}, {"kind": "image", "imageId": "img.envelope", "caption": "??? ? zarf"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "zhaa.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Draw the rounded body and tall line, then one dot above."}, {"kind": "audio", "audioId": "snd.zhaa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? rounded body, tall line, and dot above. ?????!", "wrongShape": "Keep the tall line clear and the body rounded.", "noDot": "Add one dot above ? that dot makes it zhaa."}, "signedOff": false}
{"id": "zhaa.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, zhaa has the tall line and one dot above."}, {"kind": "audio", "audioId": "snd.zhaa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? smooth and clean. ?????!", "wrongShape": "Keep the tall line clear and the body rounded.", "noDot": "Add one dot above ? that dot makes it zhaa."}, "signedOff": false}
{"id": "zhaa.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, zhaa joins with one dot above."}, {"kind": "audio", "audioId": "snd.zhaa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined clearly. ?????!", "wrongShape": "Keep the tall line clear and the body rounded.", "notConnected": "Keep the form joined where it connects."}, "signedOff": false}
{"id": "zhaa.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.zarf"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is zhaa. ?????!", "wrongLetter": "Listen again ? ??? starts with zhaa. rounded body, tall line, dot above"}, "signedOff": false}
{"id": "zhaa.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.shadow", "caption": "??"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ?? starts with zhaa. ?????!", "wrongLetter": "Look again ? start with zhaa. rounded body, tall line, dot above"}, "signedOff": false}
{"id": "zhaa.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write zhaa in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? rounded body, tall line, and dot above. ?????!", "wrongLetter": "Try zhaa again ? rounded body, tall line, dot above"}, "signedOff": false}
{"id": "zhaa.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.zarf"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ???."}, "signedOff": false}
{"id": "zhaa.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "??"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??"}}, "check": "sequence", "feedback": {"pass": "?? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ??."}, "signedOff": false}
{"id": "zhaa.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.glasses", "caption": "?????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "????? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ?????."}, "signedOff": false}
{"id": "zhaa.connectWord.zarf", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "zhaa.connectWord.zill", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "?? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "zhaa.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "middle zhaa in ?????.", "prompt": [{"kind": "say", "line": "Fill in the missing zhaa to finish the word."}, {"kind": "text", "text": "?????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "Complete! ?????. ?????!", "incomplete": "Fill in the missing zhaa to finish the word."}, "signedOff": false}
{"id": "zhaa.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ???."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "missingEnding": "Add the ending: ?????."}, "signedOff": false}
{"id": "zhaa.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (????).", "prompt": [{"kind": "say", "line": "Write the plural of ???."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "missingEnding": "Look again ? the plural is ????."}, "signedOff": false}
{"id": "zhaa.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ????????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ????."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite is ????."}, "signedOff": false}
{"id": "zhaa.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Yes ? ??? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "zhaa.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.azzillu-baarid"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["?????", "????"]}, "check": "order+sequence", "feedback": {"pass": "????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ????? ????."}, "signedOff": false}
{"id": "zhaa.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.glasses", "caption": "?????"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["????????", "?????"]}, "check": "order+sequence", "feedback": {"pass": "???????? ????? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ???????? ?????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "zarf", "text": "???", "audio": "word.zarf", "image": "img.envelope", "gloss": {"en": "envelope"}, "letters": ["zhaa", "raa", "faa"], "signedOff": false}
{"id": "zill", "text": "??", "audio": "word.zill", "image": "img.shadow", "gloss": {"en": "shadow"}, "letters": ["zhaa", "laam"], "signedOff": false}
{"id": "zaby", "text": "???", "audio": "word.zaby", "image": "img.gazelle", "gloss": {"en": "gazelle"}, "letters": ["zhaa", "baa", "yaa"], "signedOff": false}
{"id": "nazzara", "text": "?????", "audio": "word.nazzara", "image": "img.glasses", "gloss": {"en": "glasses"}, "letters": ["noon", "zhaa", "alif", "raa", "taa_marbuta"], "signedOff": false}
{"id": "hafiz", "text": "????", "audio": "word.hafiz", "image": "img.guard", "gloss": {"en": "guard"}, "letters": ["haa_c", "alif", "faa", "zhaa"], "signedOff": false}
```

## Sign-Off Checklist for Owner-Mother

- [ ] Word list - keep / swap?
- [ ] Stroke story: rounded body, tall line, dot above - correct?
- [ ] Grammar transforms: dual `?????`, plural `????`, opposite `???? -> ????` - correct and age-right?
- [ ] Sentence choices: `????? ????`, `???????? ?????` - keep / swap?
