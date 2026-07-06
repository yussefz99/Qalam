# Curriculum Draft - ??? ? khaa (letter 7)

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until
Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** letter order and ?/?/? family note from existing curriculum docs; vocabulary is proposed and tagged `[DRAFT]` because the available ? worksheet source is image-only.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

---

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| ??? (khaa) | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

Known source facts: mom's order places ? after ?, and the family note says ?/?/? share the same belly shape with the dot position distinguishing them. The exact ? vocabulary could not be extracted from the image-only worksheet, so every word below is `[DRAFT]`.

---

## ??? - khaa (?)

**Char:** ? ? **Intro order:** 7 ? **Family:** jeem family (? ? ? - same belly body)
**Forms:** isolated ? ? initial ?? ? medial ??? ? final ??
**Strokes (drafted, signed-at-letter pending):** body curl with round belly -> one dot above
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Translit | Gloss | khaa form | Letters | Source | Audio id | Image id |
|---|---|---|---|---|---|---|---|---|
| bread | ??? | khubz | bread | initial | ? ? ? | [DRAFT] | `word.khubz` new | `img.bread` new |
| sheep | ???? | kharuf | sheep | initial | ? ? ? ? | [DRAFT] | `word.kharuf` new | `img.sheep` new |
| cucumber | ???? | khiyar | cucumber | initial | ? ? ? ? | [DRAFT] | `word.khiyar` new | `img.cucumber` new |
| ring | ???? | khaatam | ring | initial | ? ? ? ? | [DRAFT] | `word.khaatam` new | `img.ring` new |
| palm tree | ???? | nakhla | palm tree | medial | ? ? ? ? | [DRAFT] | `word.nakhla` new | `img.palm-tree` new |

**Letter sound audio needed:** `snd.khaa` new

### Exercise Set (paste into `exercises.json` -> `exercises[]`)

```json
{"id": "khaa.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.khaa"}, {"kind": "image", "imageId": "img.bread", "caption": "??? ? khubz"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "khaa.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Curl the round belly, then place one dot above."}, {"kind": "audio", "audioId": "snd.khaa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? round belly, dot above. ?????!", "wrongShape": "Round the belly more ? let the curve drop down and around.", "noDot": "Good curl ? now add one dot above the belly."}, "signedOff": false}
{"id": "khaa.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "The starting khaa ? small curl, one dot above."}, {"kind": "audio", "audioId": "snd.khaa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? smooth and clean. ?????!", "wrongShape": "Round the curl a little more ? try again, slower.", "noDot": "Good shape ? now the dot above."}, "signedOff": false}
{"id": "khaa.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle of a word ? connect, curl, dot above."}, {"kind": "audio", "audioId": "snd.khaa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? smooth and connected. ?????!", "wrongShape": "Keep the belly round as you connect ? try again, slower.", "noDot": "Good shape ? now one dot above."}, "signedOff": false}
{"id": "khaa.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.khubz"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is khaa. ?????!", "wrongLetter": "Listen again ? the word starts with khaa. Write the curl with one dot above."}, "signedOff": false}
{"id": "khaa.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.sheep", "caption": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ???? starts with khaa. ?????!", "wrongLetter": "Look again ? ???? starts with khaa, one dot above."}, "signedOff": false}
{"id": "khaa.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write khaa in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? round belly and one dot above. ?????!", "wrongLetter": "One smooth curl, dot above ? try khaa again."}, "signedOff": false}
{"id": "khaa.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.khubz"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "missingDot": "Close ? your khaa needs one dot above. Listen again: ???."}, "signedOff": false}
{"id": "khaa.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ????."}, "signedOff": false}
{"id": "khaa.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.sheep", "caption": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ????."}, "signedOff": false}
{"id": "khaa.connectWord.khubz", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined ? one flowing word, no lifts."}, "signedOff": false}
{"id": "khaa.connectWord.khaatam", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "???? ? joined beautifully. ?????!", "lifted": "Keep the letters joined ? one flowing word, no lifts."}, "signedOff": false}
{"id": "khaa.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "medial khaa in ????.", "prompt": [{"kind": "say", "line": "Fill in the missing khaa to finish the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "Complete! ????. ?????!", "incomplete": "Fill in the missing khaa to finish the word."}, "signedOff": false}
{"id": "khaa.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ????."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??????"}}, "check": "sequence+transformRule", "feedback": {"pass": "?????? ? ?????!", "missingEnding": "Add the ending: ??????."}, "signedOff": false}
{"id": "khaa.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (????).", "prompt": [{"kind": "say", "line": "Write the plural of ????."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "missingEnding": "Look again ? the plural is ????."}, "signedOff": false}
{"id": "khaa.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ????????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ????."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite of light is heavy ? ????."}, "signedOff": false}
{"id": "khaa.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Yes ? ??? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "khaa.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.alkhubzu-taazij"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["????????", "?????"]}, "check": "order+sequence", "feedback": {"pass": "???????? ????? ? ?the bread is fresh.? A whole sentence! ?????!", "wrongOrder": "Keep the words in order: ???????? ?????."}, "signedOff": false}
{"id": "khaa.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.sheep", "caption": "????"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["???????", "?????"]}, "check": "order+sequence", "feedback": {"pass": "??????? ????? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ??????? ?????."}, "signedOff": false}
```

---

## `words.json` Additions

```json
{"id": "khubz", "text": "???", "audio": "word.khubz", "image": "img.bread", "gloss": {"en": "bread"}, "letters": ["khaa", "baa", "zaay"], "signedOff": false}
{"id": "kharuf", "text": "????", "audio": "word.kharuf", "image": "img.sheep", "gloss": {"en": "sheep"}, "letters": ["khaa", "raa", "waaw", "faa"], "signedOff": false}
{"id": "khiyar", "text": "????", "audio": "word.khiyar", "image": "img.cucumber", "gloss": {"en": "cucumber"}, "letters": ["khaa", "yaa", "alif", "raa"], "signedOff": false}
{"id": "khaatam", "text": "????", "audio": "word.khaatam", "image": "img.ring", "gloss": {"en": "ring"}, "letters": ["khaa", "alif", "taa", "meem"], "signedOff": false}
{"id": "nakhla", "text": "????", "audio": "word.nakhla", "image": "img.palm-tree", "gloss": {"en": "palm tree"}, "letters": ["noon", "khaa", "laam", "taa_marbuta"], "signedOff": false}
```

---

## Asset Manifest

### Audio
- snd.khaa, word.khubz, word.kharuf, word.khiyar, word.khaatam, word.nakhla, sentence.alkhubzu-taazij

### Images
- img.bread, img.sheep, img.cucumber, img.ring, img.palm-tree

---

## Sign-Off Checklist for Owner-Mother

- [ ] Word list: bread ? sheep ? cucumber ? ring ? palm tree - keep / swap?
- [ ] Stroke story: "round belly, then one dot above" - correct?
- [ ] Mistake feedback lines read in your voice?
- [ ] Grammar transforms: dual `??????`, plural `????`, opposite `???? -> ????` - correct and age-right?
- [ ] Sentence choices: `???????? ?????`, `??????? ?????` - keep / swap?

When signed, flip only reviewed `khaa` `signedOff` fields to `true`.
