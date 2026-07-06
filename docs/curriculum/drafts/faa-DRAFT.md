# Curriculum Draft - ? ? faa

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| faa | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## faa

**Char:** ? ? **Family:** faa/qaaf head-arm family
**Strokes (drafted, signed-at-letter pending):** small head, arm, dot above
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Gloss | Source | Audio id | Image id |
|---|---|---|---|---|---|
| fil | ??? | elephant | [DRAFT] | `word.fil` | `img.elephant` |
| fustuq | ???? | pistachio | [DRAFT] | `word.fustuq` | `img.pistachio` |
| farasha_faa | ????? | butterfly | [DRAFT] | `word.farasha` | `img.butterfly` |
| miftaah_faa | ????? | key | [DRAFT] | `word.miftaah` | `img.key` |
| kharoof | ???? | sheep | [DRAFT] | `word.kharuf` | `img.sheep` |

### Exercise Set

```json
{"id": "faa.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.faa"}, {"kind": "image", "imageId": "img.elephant", "caption": "??? ? fil"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "faa.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Make the small head and arm, then one dot above."}, {"kind": "audio", "audioId": "snd.faa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? small head, arm, and dot above. ?????!", "wrongShape": "Keep the head round and the arm smooth.", "noDot": "Add one dot above the head."}, "signedOff": false}
{"id": "faa.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, faa has a small head with one dot above."}, {"kind": "audio", "audioId": "snd.faa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? smooth and clean. ?????!", "wrongShape": "Keep the head round and the arm smooth.", "noDot": "Add one dot above the head."}, "signedOff": false}
{"id": "faa.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, faa joins with one dot above."}, {"kind": "audio", "audioId": "snd.faa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined clearly. ?????!", "wrongShape": "Keep the head round and the arm smooth.", "notConnected": "Keep the form joined where it connects."}, "signedOff": false}
{"id": "faa.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.fil"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is faa. ?????!", "wrongLetter": "Listen again ? ??? starts with faa. small head, arm, dot above"}, "signedOff": false}
{"id": "faa.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.pistachio", "caption": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ???? starts with faa. ?????!", "wrongLetter": "Look again ? start with faa. small head, arm, dot above"}, "signedOff": false}
{"id": "faa.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write faa in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? small head, arm, and dot above. ?????!", "wrongLetter": "Try faa again ? small head, arm, dot above"}, "signedOff": false}
{"id": "faa.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.fil"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ???."}, "signedOff": false}
{"id": "faa.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ????."}, "signedOff": false}
{"id": "faa.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.key", "caption": "?????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "????? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ?????."}, "signedOff": false}
{"id": "faa.connectWord.fil", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "faa.connectWord.fustuq", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "???? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "faa.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "middle faa in ?????.", "prompt": [{"kind": "say", "line": "Fill in the missing faa to finish the word."}, {"kind": "text", "text": "?????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "?????"}}, "check": "sequence", "feedback": {"pass": "Complete! ?????. ?????!", "incomplete": "Fill in the missing faa to finish the word."}, "signedOff": false}
{"id": "faa.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ???."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "missingEnding": "Add the ending: ?????."}, "signedOff": false}
{"id": "faa.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (????).", "prompt": [{"kind": "say", "line": "Write the plural of ???."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "missingEnding": "Look again ? the plural is ????."}, "signedOff": false}
{"id": "faa.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ??????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ???."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+transformRule", "feedback": {"pass": "??? ? ?????!", "wrongWord": "The opposite is ???."}, "signedOff": false}
{"id": "faa.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Yes ? ??? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "faa.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.alfilu-kabeer"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
{"id": "faa.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.key", "caption": "?????"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["????????", "????"]}, "check": "order+sequence", "feedback": {"pass": "???????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ???????? ????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "fil", "text": "???", "audio": "word.fil", "image": "img.elephant", "gloss": {"en": "elephant"}, "letters": ["faa", "yaa", "laam"], "signedOff": false}
{"id": "fustuq", "text": "????", "audio": "word.fustuq", "image": "img.pistachio", "gloss": {"en": "pistachio"}, "letters": ["faa", "seen", "taa", "qaaf"], "signedOff": false}
{"id": "farasha_faa", "text": "?????", "audio": "word.farasha", "image": "img.butterfly", "gloss": {"en": "butterfly"}, "letters": ["faa", "raa", "alif", "sheen", "taa_marbuta"], "signedOff": false}
{"id": "miftaah_faa", "text": "?????", "audio": "word.miftaah", "image": "img.key", "gloss": {"en": "key"}, "letters": ["meem", "faa", "taa", "alif", "haa_c"], "signedOff": false}
{"id": "kharoof", "text": "????", "audio": "word.kharuf", "image": "img.sheep", "gloss": {"en": "sheep"}, "letters": ["khaa", "raa", "waaw", "faa"], "signedOff": false}
```

## Sign-Off Checklist for Owner-Mother

- [ ] Word list - keep / swap?
- [ ] Stroke story: small head, arm, dot above - correct?
- [ ] Grammar transforms: dual `?????`, plural `????`, opposite `??? -> ???` - correct and age-right?
- [ ] Sentence choices: `?????? ????`, `???????? ????` - keep / swap?
