# Curriculum Draft - ? ? kaaf

**Status:** DRAFT - `signedOff: false` on every item. Nothing here reaches a child until Owner-mother reviews and signs.
**Author:** Codex (drafted) ? **Reviewer:** Owner-mother (pending)
**Source basis:** mom's letter order only; vocabulary and enrichment choices are `[DRAFT]`.
**Template:** mirrors the signed `taa` set - same 19-exercise shape, same graph pattern.

## Sourcing Confidence

| Letter | Vocabulary source | Confidence | Needs owner-mother's eye on |
|---|---|---|---|
| kaaf | [DRAFT] standard, concrete grade-1 words selected by Codex | Medium-low | All word choices, sentence choices, and enrichment transforms |

## kaaf

**Char:** ? ? **Family:** kaaf standalone family
**Strokes (drafted, signed-at-letter pending):** tall corner, small inner mark
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Gloss | Source | Audio id | Image id |
|---|---|---|---|---|---|
| kalb | ??? | dog | [DRAFT] | `word.kalb` | `img.dog` |
| kaas | ??? | cup | [DRAFT] | `word.kaas` | `img.cup` |
| kitaab_kaaf | ???? | book | [DRAFT] | `word.kitaab` | `img.book` |
| samakah_kaaf | ???? | fish | [DRAFT] | `word.samakah` | `img.fish` |
| malik | ??? | king | [DRAFT] | `word.malik` | `img.king` |

### Exercise Set

```json
{"id": "kaaf.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches ? the sound and the shapes."}, {"kind": "audio", "audioId": "snd.kaaf"}, {"kind": "image", "imageId": "img.dog", "caption": "??? ? kalb"}, {"kind": "forms", "char": "?", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "kaaf.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Draw the tall corner shape, then the small mark inside."}, {"kind": "audio", "audioId": "snd.kaaf"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful ? tall shape and small inner mark. ?????!", "wrongShape": "Keep the tall corner clear, then tuck the small mark inside.", "noDot": "Keep the tall corner clear, then tuck the small mark inside."}, "signedOff": false}
{"id": "kaaf.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "At the start, kaaf reaches forward with its small mark."}, {"kind": "audio", "audioId": "snd.kaaf"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Yes ? smooth and clean. ?????!", "wrongShape": "Keep the tall corner clear, then tuck the small mark inside.", "noDot": "Keep the tall corner clear, then tuck the small mark inside."}, "signedOff": false}
{"id": "kaaf.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle, kaaf joins on both sides with the small mark inside."}, {"kind": "audio", "audioId": "snd.kaaf"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "?", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Good ? joined clearly. ?????!", "wrongShape": "Keep the tall corner clear, then tuck the small mark inside.", "notConnected": "Keep the form joined where it connects."}, "signedOff": false}
{"id": "kaaf.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.kalb"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? that is kaaf. ?????!", "wrongLetter": "Listen again ? ??? starts with kaaf. tall corner, small inner mark"}, "signedOff": false}
{"id": "kaaf.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.cup", "caption": "???"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? ??? starts with kaaf. ?????!", "wrongLetter": "Look again ? start with kaaf. tall corner, small inner mark"}, "signedOff": false}
{"id": "kaaf.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write kaaf in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "?", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes ? tall shape and small inner mark. ?????!", "wrongLetter": "Try kaaf again ? tall corner, small inner mark"}, "signedOff": false}
{"id": "kaaf.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.kalb"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? from memory. Real writing! ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "Listen again: ???."}, "signedOff": false}
{"id": "kaaf.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "??? ? neatly done. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look again and try ???."}, "signedOff": false}
{"id": "kaaf.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.fish", "caption": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "???? ? from memory. ?????!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That is a different word ? look at the picture and try ????."}, "signedOff": false}
{"id": "kaaf.connectWord.kalb", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "kaaf.connectWord.kaas", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "?  ?  ?"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "??? ? joined beautifully. ?????!", "lifted": "Keep the letters joined where they can join ? one orderly word."}, "signedOff": false}
{"id": "kaaf.completeWord.middle", "type": "completeWord", "skill": "spelling", "_note": "middle kaaf in ????.", "prompt": [{"kind": "say", "line": "Fill in the missing kaaf to finish the word."}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "????"}}, "check": "sequence", "feedback": {"pass": "Complete! ????. ?????!", "incomplete": "Fill in the missing kaaf to finish the word."}, "signedOff": false}
{"id": "kaaf.transformWord.dual", "type": "transformWord", "skill": "grammar", "_review": "Confirm dual choice with owner-mother.", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ????."}, {"kind": "rule", "label": "Dual ? ????"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "??????"}}, "check": "sequence+transformRule", "feedback": {"pass": "?????? ? ?????!", "missingEnding": "Add the ending: ??????."}, "signedOff": false}
{"id": "kaaf.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL ? confirm form with owner-mother (???).", "prompt": [{"kind": "say", "line": "Write the plural of ????."}, {"kind": "rule", "label": "Plural ? ???"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence+transformRule", "feedback": {"pass": "??? ? ?????!", "missingEnding": "Look again ? the plural is ???."}, "signedOff": false}
{"id": "kaaf.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ????????? ? confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ????."}, {"kind": "rule", "label": "Opposite ? ??"}, {"kind": "text", "text": "????"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "????"}}, "check": "sequence+transformRule", "feedback": {"pass": "???? ? ?????!", "wrongWord": "The opposite is ????."}, "signedOff": false}
{"id": "kaaf.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "???"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "???"}}, "check": "sequence", "feedback": {"pass": "Yes ? ??? fits here. ?????!", "wrongWord": "Read the sentence again and write the word that fits."}, "signedOff": false}
{"id": "kaaf.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.alkalbu-sari"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["??????", "????"]}, "check": "order+sequence", "feedback": {"pass": "?????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ?????? ????."}, "signedOff": false}
{"id": "kaaf.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.fish", "caption": "????"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["???????", "????"]}, "check": "order+sequence", "feedback": {"pass": "??????? ???? ? a whole sentence! ?????!", "wrongOrder": "Keep the words in order: ??????? ????."}, "signedOff": false}
```

## `words.json` Additions

```json
{"id": "kalb", "text": "???", "audio": "word.kalb", "image": "img.dog", "gloss": {"en": "dog"}, "letters": ["kaaf", "laam", "baa"], "signedOff": false}
{"id": "kaas", "text": "???", "audio": "word.kaas", "image": "img.cup", "gloss": {"en": "cup"}, "letters": ["kaaf", "alif", "seen"], "signedOff": false}
{"id": "kitaab_kaaf", "text": "????", "audio": "word.kitaab", "image": "img.book", "gloss": {"en": "book"}, "letters": ["kaaf", "taa", "alif", "baa"], "signedOff": false}
{"id": "samakah_kaaf", "text": "????", "audio": "word.samakah", "image": "img.fish", "gloss": {"en": "fish"}, "letters": ["seen", "meem", "kaaf", "taa_marbuta"], "signedOff": false}
{"id": "malik", "text": "???", "audio": "word.malik", "image": "img.king", "gloss": {"en": "king"}, "letters": ["meem", "laam", "kaaf"], "signedOff": false}
```

## Sign-Off Checklist for Owner-Mother

- [ ] Word list - keep / swap?
- [ ] Stroke story: tall corner, small inner mark - correct?
- [ ] Grammar transforms: dual `??????`, plural `???`, opposite `???? -> ????` - correct and age-right?
- [ ] Sentence choices: `?????? ????`, `??????? ????` - keep / swap?
