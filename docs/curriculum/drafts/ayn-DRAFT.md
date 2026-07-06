# Curriculum Draft - ? ? ayn

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| ayn | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## ayn

**Char:** ? ? **Family:** ayn/ghayn belly-open family
**Strokes (drafted, signed-at-letter pending):** open head, round belly
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Gloss | Source | Audio id | Image id |
|---|---|---|---|---|---|
| aynab | ??? | grapes | [DRAFT] | `word.aynab` | `img.grapes` |
| asal | ??? | honey | [DRAFT] | `word.asal` | `img.honey` |
| ayn_eye | ??? | eye | [DRAFT] | `word.ayn` | `img.eye` |
| luba | ???? | toy | [DRAFT] | `word.luba` | `img.toy` |
| saaah | ???? | clock | [DRAFT] | `word.saaah` | `img.clock` |

### Exercise Set

```json
{"id": "ayn.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.ayn"}, {"kind": "image", "imageId": "img.grapes", "caption": "??? ? aynab"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "ayn.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Start with the small open head, then curve into the round belly."}, {"kind": "audio", "audioId": "snd.ayn"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? open head and round belly. ?????!", "wrongShape": "Open the head clearly, then round the belly.", "noDot": "Ayn has no dot ? leave it bare."}, "signedOff": false}
{"id": "ayn.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, ayn is a small open head reaching forward."}, {"kind": "audio", "audioId": "snd.ayn"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? smooth and clean. ?????!", "wrongShape": "Open the head clearly, then round the belly.", "noDot": "Ayn has no dot ? leave it bare."}, "signedOff": false}
{"id": "ayn.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, ayn keeps its open head between joins."}, {"kind": "audio", "audioId": "snd.ayn"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined clearly. ?????!", "wrongShape": "Open the head clearly, then round the belly.", "notConnected": "Keep the form joined where it connects."}, "signedOff": false}
{"id": "ayn.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.aynab"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is ayn. ?????!", "wrongLetter": "Listen again ? ??? starts with ayn. open head, round belly"}, "signedOff": false}
{"id": "ayn.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.honey", "caption": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ??? starts with ayn. ?????!", "wrongLetter": "Look again ? start with ayn. open head, round belly"}, "signedOff": false}
{"id": "ayn.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write ayn in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? open head and round belly. ?????!", "wrongLetter": "Try ayn again ? open head, round belly"}, "signedOff": false}
{"id": "ayn.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.aynab"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ???."}, "signedOff": false}
{"id": "ayn.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ???."}, "signedOff": false}
{"id": "ayn.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.toy", "caption": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ????."}, "signedOff": false}
{"id": "ayn.connectWord.aynab", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "ayn.connectWord.asal", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "ayn.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "middle ayn in ????.", "prompt": [{"kind": "say", "line": "Fill in the missing ayn to finish the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "Complete! ????. ?????!", "incomplete": "Fill in the missing ayn to finish the word."}, "signedOff": false}
{"id": "ayn.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ???."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "missingEnding": "Add the ending: ?????."}, "signedOff": false}
{"id": "ayn.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (????).", "prompt": [{"kind": "say", "line": "Write the plural of ???."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "missingEnding": "Look again ? the plural is ????."}, "signedOff": false}
{"id": "ayn.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ????????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ???."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "?????"}}, "check": "sequence+transformRule", "feedback": {"pass": "????? ? ?????!", "wrongWord": "The opposite is ?????."}, "signedOff": false}
{"id": "ayn.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Yes ? ??? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "ayn.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.alaynabu-hulw"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "???"]}, "check": "order+sequence", "feedback": {"pass": "?????? ??? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ???."}, "signedOff": false}
{"id": "ayn.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.toy", "caption": "????"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "?????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ????? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ?????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "aynab", "text": "???", "audio": "word.aynab", "image": "img.grapes", "gloss": {"en": "grapes"}, "letters": ["ayn", "noon", "baa"], "signedOff": false}
{"id": "asal", "text": "???", "audio": "word.asal", "image": "img.honey", "gloss": {"en": "honey"}, "letters": ["ayn", "seen", "laam"], "signedOff": false}
{"id": "ayn_eye", "text": "???", "audio": "word.ayn", "image": "img.eye", "gloss": {"en": "eye"}, "letters": ["ayn", "yaa", "noon"], "signedOff": false}
{"id": "luba", "text": "????", "audio": "word.luba", "image": "img.toy", "gloss": {"en": "toy"}, "letters": ["laam", "ayn", "baa", "taa_marbuta"], "signedOff": false}
{"id": "saaah", "text": "????", "audio": "word.saaah", "image": "img.clock", "gloss": {"en": "clock"}, "letters": ["seen", "alif", "ayn", "taa_marbuta"], "signedOff": false}
```

## Sign-Off Checklist for Owner-Mother

- [ ] Word list - keep / swap?
- [ ] Stroke story: open head, round belly - correct?
- [ ] Grammar transforms: dual `?????`, plural `????`, opposite `??? -> ?????` - correct and age-right?
- [ ] Sentence choices: `?????? ???`, `?????? ?????` - keep / swap?
