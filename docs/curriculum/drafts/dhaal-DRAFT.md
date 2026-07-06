# Curriculum Draft - ??? ? dhaal (letter 9)

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| ??? (dhaal) | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## ??? - dhaal (?)

**Char:** ? ? **Intro order:** 9 ? **Family:** daal/dhaal hook family
**Forms:** isolated ? ? initial ? ? medial ?? ? final ??
**Strokes (drafted, signed-at-letter pending):** one compact hook, one dot above
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Translit | Gloss | dhaal form | Letters | Source | Audio id | Image id |
|---|---|---|---|---|---|---|---|---|
| tail | ??? | dhayl | tail | initial | ? ? ? | [DRAFT] | `word.dhayl` new | `img.tail` new |
| arm | ???? | dhira | arm | initial | ? ? ? ? | [DRAFT] | `word.dhira` new | `img.arm` new |
| gold | ??? | dhahab | gold | initial | ? ? ? | [DRAFT] | `word.dhahab` new | `img.gold` new |
| ear | ??? | udhun | ear | medial | ? ? ? | [DRAFT] | `word.udhun` new | `img.ear` new |
| corn | ??? | dhura | corn | initial | ? ? ? | [DRAFT] | `word.dhura` new | `img.corn` new |

### Exercise Set

```json
{"id": "dhaal.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.dhaal"}, {"kind": "image", "imageId": "img.tail", "caption": "??? ? dhayl"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "dhaal.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Make the small daal hook, then add one dot above."}, {"kind": "audio", "audioId": "snd.dhaal"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? short hook and one dot above. ?????!", "wrongShape": "Make the hook short and clean ? down, then a small turn left.", "noDot": "Good hook ? now add one dot above."}, "signedOff": false}
{"id": "dhaal.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Dhaal keeps the same small hook, with one dot above."}, {"kind": "audio", "audioId": "snd.dhaal"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? the small dhaal hook with its dot. ?????!", "wrongShape": "Keep it compact ? not a long curve.", "noDot": "The hook is right ? now the dot above makes it dhaal."}, "signedOff": false}
{"id": "dhaal.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, dhaal joins from before and keeps its dot above."}, {"kind": "audio", "audioId": "snd.dhaal"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined from before, dot above. ?????!", "wrongShape": "Keep the hook compact after the joining line.", "noDot": "Add the dot above ? that dot makes it dhaal."}, "signedOff": false}
{"id": "dhaal.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.dhayl"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is dhaal. ?????!", "wrongLetter": "Listen again ? ??? starts with dhaal, the small hook with a dot above."}, "signedOff": false}
{"id": "dhaal.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.arm", "caption": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ???? starts with dhaal. ?????!", "wrongLetter": "Look again ? ???? starts with dhaal, one dot above."}, "signedOff": false}
{"id": "dhaal.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write dhaal in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? short hook and dot above. ?????!", "wrongLetter": "Try dhaal again ? short hook, one dot above."}, "signedOff": false}
{"id": "dhaal.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.dhayl"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "missingDot": "Close ? your dhaal needs one dot above. Listen again: ???."}, "signedOff": false}
{"id": "dhaal.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ????."}, "signedOff": false}
{"id": "dhaal.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.ear", "caption": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ???."}, "signedOff": false}
{"id": "dhaal.connectWord.dhayl", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the letters together as one word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? written as one word. ?????!", "lifted": "Keep the word close and orderly ? dhaal stops, then the next letter begins."}, "signedOff": false}
{"id": "dhaal.connectWord.dhahab", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the letters together as one word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? written as one word. ?????!", "lifted": "Keep the letters close and in order."}, "signedOff": false}
{"id": "dhaal.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "medial dhaal in ???.", "prompt": [{"kind": "say", "line": "Fill in the missing dhaal to finish the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Complete! ???. ?????!", "incomplete": "Fill in the missing dhaal to finish the word."}, "signedOff": false}
{"id": "dhaal.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ???."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "missingEnding": "Add the ending: ?????."}, "signedOff": false}
{"id": "dhaal.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (?????).", "prompt": [{"kind": "say", "line": "Write the plural of ???."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "missingEnding": "Look again ? the plural is ?????."}, "signedOff": false}
{"id": "dhaal.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ??????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ???."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+transformRule", "feedback": {"pass": "??? ? ?????!", "wrongWord": "The opposite of smart is not-smart ? ???."}, "signedOff": false}
{"id": "dhaal.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Yes ? ??? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "dhaal.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.adhdhaylu-taweel"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? ?the tail is long.? A whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
{"id": "dhaal.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.gold", "caption": "???"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "dhayl", "text": "???", "audio": "word.dhayl", "image": "img.tail", "gloss": {"en": "tail"}, "letters": ["dhaal", "yaa", "laam"], "signedOff": false}
{"id": "dhira", "text": "????", "audio": "word.dhira", "image": "img.arm", "gloss": {"en": "arm"}, "letters": ["dhaal", "raa", "alif", "ayn"], "signedOff": false}
{"id": "dhahab", "text": "???", "audio": "word.dhahab", "image": "img.gold", "gloss": {"en": "gold"}, "letters": ["dhaal", "haa_f", "baa"], "signedOff": false}
{"id": "udhun", "text": "???", "audio": "word.udhun", "image": "img.ear", "gloss": {"en": "ear"}, "letters": ["alif", "dhaal", "noon"], "signedOff": false}
{"id": "dhura", "text": "???", "audio": "word.dhura", "image": "img.corn", "gloss": {"en": "corn"}, "letters": ["dhaal", "raa", "taa_marbuta"], "signedOff": false}
```

## Asset Manifest

### Audio
- `snd.dhaal`, `word.dhayl`, `word.dhira`, `word.dhahab`, `word.udhun`, `word.dhura`, `sentence.adhdhaylu-taweel`

### Images
- `img.tail`, `img.arm`, `img.gold`, `img.ear`, `img.corn`

## Sign-Off Checklist for Owner-Mother

- [ ] Word list: tail ? arm ? gold ? ear ? corn - keep / swap?
- [ ] Stroke story: compact hook, one dot above - correct?
- [ ] Non-connecting dhaal wording in connect-word exercises is correct?
- [ ] Grammar transforms: dual `?????`, plural `?????`, opposite `??? -> ???` - correct and age-right?
- [ ] Sentence choices: `?????? ????`, `?????? ????` - keep / swap?
