# Curriculum Draft — ثاء · جيم · حاء (letters 4, 5, 6)

**Status:** DRAFT — `signedOff: false` on every item. Nothing here reaches a child until
Owner-mother reviews and signs (mirrors the baa/taa gate).
**Author:** Claude (drafted) · **Reviewer:** Owner-mother (pending)
**Source basis:** her own Drive materials where extractable; standard grade-1 vocab
where her worksheets were image-only (flagged per word below).
**Template:** mirrors the signed `taa` set — same 19-exercise shape, same voice.

> **How to read this:** each letter has (1) a vocabulary table with the *source* of every
> word and the *assets it needs*, then (2) the full exercise set as ready-to-paste JSON for
> `exercises.json`. The consolidated `words.json` additions and the asset manifest (audio +
> images to produce) are at the bottom, followed by your sign-off checklist.

---

## Sourcing confidence (read first)

| Letter | Vocabulary source | Confidence | Needs your eye on |
|---|---|---|---|
| ثاء (thaa) | **Her worksheet `أ - ب - ت - ث.docx`** — words lifted directly | High | Word *choice* for a 5–10yo (fox/snow/snake/garlic) |
| جيم (jeem) | Her `وعي صوتي حرف ال ج.docx` (جنزير, جِرذ) + standard primer vocab | Medium | Whether to use camel/carrots/mountain vs. her preferred set |
| حاء (haa) | Picture-word PDF (حصان, حمار, مفتاح recoverable) + standard | Medium | Same — confirm the word list reflects how you teach ح |

Her thaa worksheet listed: **ثَعْلَب، مُثَلّث، حَديث، ثَلْج، ثُعْبان، ثِياب، مُمَثّل، ثَلّاجة، ثوم**.
I picked the most concrete/picture-able of these for the questions. The jeem/haa worksheets
(`حرف الحاء والخاء والجيم.docx`, the إملاء sheet) are scanned images — their words couldn't
be auto-extracted, so jeem/haa vocab is my best draft for her to confirm or swap.

---

## 1 · ثاء — thaa (ث)

**Char:** ث · **Intro order:** 4 · **Family:** baa family (same boat body)
**Forms:** isolated ث · initial ثـ · medial ـثـ · final ـث
**Strokes (drafted, signed-at-letter pending):** body (line) → three dots on top (right, left, top — a little triangle)
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Translit | Gloss | thaa form | Letters | Source | Audio id | Image id |
|---|---|---|---|---|---|---|---|---|
| fox | ثَعْلَب | tha'lab | fox | initial | ث ع ل ب | her worksheet | `word.thalab` 🆕 | `img.fox` 🆕 |
| snow | ثَلْج | thalj | snow | initial | ث ل ج | her worksheet | `word.thalj` 🆕 | `img.snow` 🆕 |
| snake | ثُعْبان | thu'baan | snake | initial | ث ع ب ا ن | her worksheet | `word.thuban` 🆕 | `img.snake` 🆕 |
| garlic | ثوم | thawm | garlic | initial | ث و م | her worksheet | `word.thawm` 🆕 | `img.garlic` 🆕 |
| triangle | مُثَلّث | muthallath | triangle | medial | م ث ل ث | her worksheet | `word.muthallath` 🆕 | `img.triangle` 🆕 |

**Letter sound audio needed:** `snd.thaa` 🆕

### Exercise set (paste into `exercises.json` → `exercises[]`)

```json
{"id": "thaa.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches — the sound and the shapes."}, {"kind": "audio", "audioId": "snd.thaa"}, {"kind": "image", "imageId": "img.fox", "caption": "ثَعْلَب · tha'lab"}, {"kind": "forms", "char": "ث", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "thaa.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Sweep the boat, then three dots on top — one, two, three."}, {"kind": "audio", "audioId": "snd.thaa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "ث", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful — a deep boat and three neat dots. أحسنت!", "shallowBowl": "A little more curve in the boat — try again, slower.", "noDot": "Good boat — now three dots above it, like a little triangle."}, "signedOff": false}
{"id": "thaa.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "The starting thaa — flat and low, three dots on top."}, {"kind": "audio", "audioId": "snd.thaa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "ث", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Beautiful — smooth and clean. أحسنت!", "shallowBowl": "A little more curve — try again, slower.", "noDot": "Good shape — now the three dots."}, "signedOff": false}
{"id": "thaa.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "A little tooth in the middle, three dots above."}, {"kind": "audio", "audioId": "snd.thaa"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "ث", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Beautiful — smooth and clean. أحسنت!", "shallowBowl": "A little more curve — try again, slower.", "noDot": "Good shape — now the three dots."}, "signedOff": false}
{"id": "thaa.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.thalab"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "ث", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes — that's it. أحسنت!", "wrongLetter": "Listen again — which letter makes that sound?"}, "signedOff": false}
{"id": "thaa.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.snow", "caption": "ثَلْج"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "ث", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes — that's it. أحسنت!", "wrongLetter": "Listen again — which letter makes that sound?"}, "signedOff": false}
{"id": "thaa.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write thaa in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "ث", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes — that's it. أحسنت!", "wrongLetter": "Three dots on top — try thaa again."}, "signedOff": false}
{"id": "thaa.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.thalj"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "ثَلْج"}}, "check": "sequence", "feedback": {"pass": "ثَلْج — from memory. Real writing! أحسنت!", "incomplete": "Look again and write all of its letters.", "missingDot": "Close — your thaa needs its three dots. Listen again: ثَلْج."}, "signedOff": false}
{"id": "thaa.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "ثوم"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "ثوم"}}, "check": "sequence", "feedback": {"pass": "ثوم — neatly done. أحسنت!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That's a different word — look again and try ثوم."}, "signedOff": false}
{"id": "thaa.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.fox", "caption": "ثَعْلَب"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "ثعلب"}}, "check": "sequence", "feedback": {"pass": "ثعلب — from memory. Real writing! أحسنت!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That's a different word — look at the picture and try again."}, "signedOff": false}
{"id": "thaa.connectWord.thalab", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "ث  ع  ل  ب"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "ثعلب"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "ثعلب — joined beautifully. أحسنت!", "lifted": "Keep the letters joined — one flowing word, no lifts."}, "signedOff": false}
{"id": "thaa.connectWord.thawm", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "ث  و  م"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "ثوم"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "ثوم — joined beautifully. أحسنت!", "lifted": "Keep the letters joined — one flowing word, no lifts."}, "signedOff": false}
{"id": "thaa.completeWord.middle", "type": "completeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Fill in the missing thaa to finish the word."}, {"kind": "text", "text": "مثلث"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "مثلث"}}, "check": "sequence", "feedback": {"pass": "Complete! مثلث. أحسنت!", "incomplete": "Fill in the missing thaa to finish the word."}, "signedOff": false}
{"id": "thaa.transformWord.dual", "type": "transformWord", "skill": "grammar", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of ثعلب."}, {"kind": "rule", "label": "Dual · مثنى"}, {"kind": "text", "text": "ثعلب"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "ثعلبان"}}, "check": "sequence+transformRule", "feedback": {"pass": "ثعلبان — أحسنت!", "missingEnding": "Add the ending: ثعلبان."}, "signedOff": false}
{"id": "thaa.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL — confirm form with owner-mother (ثعالب).", "prompt": [{"kind": "say", "line": "Write the plural of ثعلب."}, {"kind": "rule", "label": "Plural · جمع"}, {"kind": "text", "text": "ثعلب"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "ثعالب"}}, "check": "sequence+transformRule", "feedback": {"pass": "ثعالب — أحسنت!", "missingEnding": "Look again — the plural is ثعالب."}, "signedOff": false}
{"id": "thaa.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair ثقيل→خفيف — confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of ثقيل."}, {"kind": "rule", "label": "Opposite · ضد"}, {"kind": "text", "text": "ثقيل"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "خفيف"}}, "check": "sequence+transformRule", "feedback": {"pass": "خفيف — أحسنت!", "wrongWord": "The opposite of heavy is light — خفيف."}, "signedOff": false}
{"id": "thaa.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "ثلج"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "ثلج"}}, "check": "sequence", "feedback": {"pass": "Yes! أحسنت!", "wrongWord": "Read the sentence again and pick the word that fits."}, "signedOff": false}
{"id": "thaa.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.aththalju-baarid"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["الثَّلْجُ", "بارِد"]}, "check": "order+sequence", "feedback": {"pass": "الثَّلْجُ بارِد — “the snow is cold.” A whole sentence! أحسنت!", "wrongOrder": "Keep the words in order: الثَّلْجُ بارِد."}, "signedOff": false}
{"id": "thaa.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.snake", "caption": "ثُعْبان"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["الثُّعْبانُ", "طَويل"]}, "check": "order+sequence", "feedback": {"pass": "الثُّعْبانُ طَويل — a whole sentence! أحسنت!", "wrongOrder": "Keep the words in order: الثُّعْبانُ طَويل."}, "signedOff": false}
```

---

## 2 · جيم — jeem (ج)

**Char:** ج · **Intro order:** 5 · **Family:** jeem family (ج ح خ — same body, dot differs)
**Forms:** isolated ج · initial جـ · medial ـجـ · final ـج
**Strokes (drafted):** body (curl with a round belly) → one dot inside, underneath
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Translit | Gloss | jeem form | Letters | Source | Audio id | Image id |
|---|---|---|---|---|---|---|---|---|
| camel | جَمَل | jamal | camel | initial | ج م ل | standard primer | `word.jamal` 🆕 | `img.camel` 🆕 |
| carrots | جَزَر | jazar | carrots | initial | ج ز ر | standard primer | `word.jazar` 🆕 | `img.carrots` 🆕 |
| mountain | جَبَل | jabal | mountain | initial | ج ب ل | standard primer | `word.jabal` 🆕 | `img.mountain` 🆕 |
| hen | دَجاجة | dajaaja | hen | medial | د ج ا ج ة | standard primer | `word.dajaja` 🆕 | `img.hen` 🆕 |
| crown | تاج | taaj | crown | final | ت ا ج | **reuses `img.crown`** | `word.taaj` ♻️ | `img.crown` ♻️ |

**Letter sound audio needed:** `snd.jeem` 🆕 · ♻️ = asset already exists (from baa/taa)

### Exercise set (paste into `exercises.json` → `exercises[]`)

```json
{"id": "jeem.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches — the sound and the shapes."}, {"kind": "audio", "audioId": "snd.jeem"}, {"kind": "image", "imageId": "img.camel", "caption": "جَمَل · jamal"}, {"kind": "forms", "char": "ج", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "jeem.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "Curl a round belly, then one dot inside, underneath."}, {"kind": "audio", "audioId": "snd.jeem"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "ج", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful — a round belly and the dot tucked inside. أحسنت!", "wrongShape": "Round the belly more — let it curl down and around.", "noDot": "Good curl — now one dot inside, below the line."}, "signedOff": false}
{"id": "jeem.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "The starting jeem — a small curl, dot underneath."}, {"kind": "audio", "audioId": "snd.jeem"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "ج", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Beautiful — smooth and clean. أحسنت!", "wrongShape": "Round the curl a little more — try again, slower.", "noDot": "Good shape — now the dot underneath."}, "signedOff": false}
{"id": "jeem.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle of a word — connect, curl, dot underneath."}, {"kind": "audio", "audioId": "snd.jeem"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "ج", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Beautiful — smooth and clean. أحسنت!", "wrongShape": "Keep the belly round as you connect — try again, slower.", "noDot": "Good shape — now the dot underneath."}, "signedOff": false}
{"id": "jeem.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.jamal"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "ج", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes — that's it. أحسنت!", "wrongLetter": "Listen again — which letter makes that sound?"}, "signedOff": false}
{"id": "jeem.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.carrots", "caption": "جَزَر"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "ج", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes — that's it. أحسنت!", "wrongLetter": "Listen again — which letter makes that sound?"}, "signedOff": false}
{"id": "jeem.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write jeem in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "ج", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes — that's it. أحسنت!", "wrongLetter": "One dot inside, underneath — try jeem again."}, "signedOff": false}
{"id": "jeem.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.jamal"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "جَمَل"}}, "check": "sequence", "feedback": {"pass": "جَمَل — from memory. Real writing! أحسنت!", "incomplete": "Look again and write all of its letters.", "missingDot": "Close — your jeem needs its dot underneath. Listen again: جَمَل."}, "signedOff": false}
{"id": "jeem.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "جبل"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "جبل"}}, "check": "sequence", "feedback": {"pass": "جبل — neatly done. أحسنت!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That's a different word — look again and try جبل."}, "signedOff": false}
{"id": "jeem.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.camel", "caption": "جَمَل"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "جمل"}}, "check": "sequence", "feedback": {"pass": "جمل — from memory. Real writing! أحسنت!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That's a different word — look at the picture and try again."}, "signedOff": false}
{"id": "jeem.connectWord.jamal", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "ج  م  ل"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "جمل"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "جمل — joined beautifully. أحسنت!", "lifted": "Keep the letters joined — one flowing word, no lifts."}, "signedOff": false}
{"id": "jeem.connectWord.dajaja", "type": "connectWord", "skill": "spelling", "_note": "medial jeem joins on both sides — the harder, valuable case.", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "د  ج  ا  ج  ة"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "دجاجة"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "دجاجة — both jeems joined! أحسنت!", "lifted": "Keep the letters joined — one flowing word, no lifts."}, "signedOff": false}
{"id": "jeem.completeWord.final", "type": "completeWord", "skill": "spelling", "_note": "final jeem; reuses the crown picture/word from baa/taa.", "prompt": [{"kind": "say", "line": "Fill in the missing jeem to finish the word."}, {"kind": "text", "text": "تاج"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "تاج"}}, "check": "sequence", "feedback": {"pass": "Complete! تاج. أحسنت!", "incomplete": "Fill in the missing jeem to finish the word."}, "signedOff": false}
{"id": "jeem.transformWord.dual", "type": "transformWord", "skill": "grammar", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of جمل."}, {"kind": "rule", "label": "Dual · مثنى"}, {"kind": "text", "text": "جمل"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "جملان"}}, "check": "sequence+transformRule", "feedback": {"pass": "جملان — أحسنت!", "missingEnding": "Add the ending: جملان."}, "signedOff": false}
{"id": "jeem.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL — confirm form with owner-mother (جبال).", "prompt": [{"kind": "say", "line": "Write the plural of جبل."}, {"kind": "rule", "label": "Plural · جمع"}, {"kind": "text", "text": "جبل"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "جبال"}}, "check": "sequence+transformRule", "feedback": {"pass": "جبال — أحسنت!", "missingEnding": "Look again — the plural is جبال."}, "signedOff": false}
{"id": "jeem.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair جميل→قبيح — confirm appropriate for age.", "prompt": [{"kind": "say", "line": "Write the opposite of جميل."}, {"kind": "rule", "label": "Opposite · ضد"}, {"kind": "text", "text": "جميل"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "قبيح"}}, "check": "sequence+transformRule", "feedback": {"pass": "قبيح — أحسنت!", "wrongWord": "The opposite of beautiful is قبيح."}, "signedOff": false}
{"id": "jeem.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "جمل"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "جمل"}}, "check": "sequence", "feedback": {"pass": "Yes! أحسنت!", "wrongWord": "Read the sentence again and pick the word that fits."}, "signedOff": false}
{"id": "jeem.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.aljamalu-kabeer"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["الجَمَلُ", "كَبير"]}, "check": "order+sequence", "feedback": {"pass": "الجَمَلُ كَبير — “the camel is big.” A whole sentence! أحسنت!", "wrongOrder": "Keep the words in order: الجَمَلُ كَبير."}, "signedOff": false}
{"id": "jeem.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.mountain", "caption": "جَبَل"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["الجَبَلُ", "عالٍ"]}, "check": "order+sequence", "feedback": {"pass": "الجَبَلُ عالٍ — a whole sentence! أحسنت!", "wrongOrder": "Keep the words in order: الجَبَلُ عالٍ."}, "signedOff": false}
```

---

## 3 · حاء — haa (ح)

**Char:** ح · **Intro order:** 6 · **Family:** jeem family (ج ح خ — same body, **no dot**)
**Forms:** isolated ح · initial حـ · medial ـحـ · final ـح
**Strokes (drafted):** one smooth curl with a round belly — **no dot at all** (this is the key contrast with jeem/khaa)
**Clean reps to advance:** 3

### Vocabulary

| Word | Arabic | Translit | Gloss | haa form | Letters | Source | Audio id | Image id |
|---|---|---|---|---|---|---|---|---|
| horse | حِصان | hisaan | horse | initial | ح ص ا ن | picture-word PDF | `word.hisaan` 🆕 | `img.horse` 🆕 |
| whale | حوت | hoot | whale | initial | ح و ت | standard primer | `word.hoot` 🆕 | `img.whale` 🆕 |
| key | مِفتاح | miftaah | key | final | م ف ت ا ح | picture-word PDF | `word.miftaah` 🆕 | `img.key` 🆕 |
| apple | تُفّاح | tuffaah | apple | medial | ت ف ف ا ح | standard primer | `word.tuffah` 🆕 | `img.apple` 🆕 |
| milk | حليب | haleeb | milk | initial | ح ل ي ب | **reuses `img.milk`** | `word.haliib` ♻️ | `img.milk` ♻️ |

**Letter sound audio needed:** `snd.haa_c` 🆕

### Exercise set (paste into `exercises.json` → `exercises[]`)

```json
{"id": "haa_c.teachCard.meet", "type": "teachCard", "skill": "comprehension", "_note": "SUPPORT section: PromptHeader only, no WriteSurface.", "prompt": [{"kind": "say", "line": "This card just teaches — the sound and the shapes."}, {"kind": "audio", "audioId": "snd.haa_c"}, {"kind": "image", "imageId": "img.horse", "caption": "حِصان · hisaan"}, {"kind": "forms", "char": "ح", "forms": ["isolated", "initial", "medial", "final"]}], "surface": null, "expected": null, "check": null, "feedback": null, "signedOff": false}
{"id": "haa_c.traceLetter.isolated", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "One smooth curl with a round belly. No dot — haa is bare."}, {"kind": "audio", "audioId": "snd.haa_c"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "isolated", "demo": true}, "expected": {"glyph": {"char": "ح", "form": "isolated"}}, "check": "glyph", "feedback": {"pass": "Beautiful — one smooth curl, nice and round. أحسنت!", "wrongShape": "Round the belly more — let the curve drop down.", "extraDot": "Haa has no dot — leave it bare. That's how we know it's not jeem."}, "signedOff": false}
{"id": "haa_c.traceLetter.initial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "The starting haa — a small open curl, no dot."}, {"kind": "audio", "audioId": "snd.haa_c"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "initial", "demo": true}, "expected": {"glyph": {"char": "ح", "form": "initial"}}, "check": "glyph", "feedback": {"pass": "Beautiful — smooth and clean. أحسنت!", "wrongShape": "Start at the top and sweep down into the belly — try again, slower.", "extraDot": "No dot on haa — leave it bare."}, "signedOff": false}
{"id": "haa_c.traceLetter.medial", "type": "traceLetter", "skill": "formation", "prompt": [{"kind": "say", "line": "In the middle of a word — connect into the round belly, no dot."}, {"kind": "audio", "audioId": "snd.haa_c"}], "surface": {"mode": "trace", "unit": "glyph", "guideForm": "medial", "demo": true}, "expected": {"glyph": {"char": "ح", "form": "medial"}}, "check": "glyph", "feedback": {"pass": "Beautiful — smooth and clean. أحسنت!", "wrongShape": "Keep the belly round as you connect — try again, slower.", "extraDot": "No dot on haa — leave it bare."}, "signedOff": false}
{"id": "haa_c.writeLetter.fromSound", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."}, {"kind": "audio", "audioId": "word.hisaan"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "ح", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes — that's it. أحسنت!", "wrongLetter": "Listen again — which letter makes that sound?"}, "signedOff": false}
{"id": "haa_c.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."}, {"kind": "image", "imageId": "img.whale", "caption": "حوت"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "ح", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes — that's it. أحسنت!", "wrongLetter": "Listen again — which letter makes that sound?"}, "signedOff": false}
{"id": "haa_c.writeLetter.writeForm", "type": "writeLetter", "skill": "recall", "prompt": [{"kind": "say", "line": "Write haa in its isolated form."}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"glyph": {"char": "ح", "form": "isolated"}}, "check": "glyph+positionalForm", "feedback": {"pass": "Yes — that's it. أحسنت!", "wrongLetter": "One smooth curl, no dot — try haa again."}, "signedOff": false}
{"id": "haa_c.writeWord.dictation", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Listen and write the whole word."}, {"kind": "audio", "audioId": "word.hoot"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "حوت"}}, "check": "sequence", "feedback": {"pass": "حوت — from memory. Real writing! أحسنت!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That's a different word — listen again: حوت."}, "signedOff": false}
{"id": "haa_c.writeWord.copy", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": "حليب"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "حليب"}}, "check": "sequence", "feedback": {"pass": "حليب — neatly done. أحسنت!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That's a different word — look again and try حليب."}, "signedOff": false}
{"id": "haa_c.writeWord.picture", "type": "writeWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Write the word for the picture."}, {"kind": "image", "imageId": "img.horse", "caption": "حِصان"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "حصان"}}, "check": "sequence", "feedback": {"pass": "حصان — from memory. Real writing! أحسنت!", "incomplete": "Look again and write all of its letters.", "wrongWord": "That's a different word — look at the picture and try again."}, "signedOff": false}
{"id": "haa_c.connectWord.hisaan", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "ح  ص  ا  ن"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "حصان"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "حصان — joined beautifully. أحسنت!", "lifted": "Keep the letters joined — one flowing word, no lifts."}, "signedOff": false}
{"id": "haa_c.connectWord.hoot", "type": "connectWord", "skill": "spelling", "prompt": [{"kind": "say", "line": "Join the letters into one connected word."}, {"kind": "text", "text": "ح  و  ت"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "حوت"}}, "check": "sequence+joinContinuity", "feedback": {"pass": "حوت — joined beautifully. أحسنت!", "lifted": "Keep the letters joined — one flowing word, no lifts."}, "signedOff": false}
{"id": "haa_c.completeWord.final", "type": "completeWord", "skill": "spelling", "_note": "final haa.", "prompt": [{"kind": "say", "line": "Fill in the missing haa to finish the word."}, {"kind": "text", "text": "مفتاح"}], "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": "مفتاح"}}, "check": "sequence", "feedback": {"pass": "Complete! مفتاح. أحسنت!", "incomplete": "Fill in the missing haa to finish the word."}, "signedOff": false}
{"id": "haa_c.transformWord.dual", "type": "transformWord", "skill": "grammar", "prompt": [{"kind": "say", "line": "One becomes two. Write the dual of حصان."}, {"kind": "rule", "label": "Dual · مثنى"}, {"kind": "text", "text": "حصان"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "حصانان"}}, "check": "sequence+transformRule", "feedback": {"pass": "حصانان — أحسنت!", "missingEnding": "Add the ending: حصانان."}, "signedOff": false}
{"id": "haa_c.transformWord.plural", "type": "transformWord", "skill": "grammar", "_review": "BROKEN PLURAL — confirm form with owner-mother (حيتان).", "prompt": [{"kind": "say", "line": "Write the plural of حوت."}, {"kind": "rule", "label": "Plural · جمع"}, {"kind": "text", "text": "حوت"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "حيتان"}}, "check": "sequence+transformRule", "feedback": {"pass": "حيتان — أحسنت!", "missingEnding": "Look again — the plural is حيتان."}, "signedOff": false}
{"id": "haa_c.transformWord.opposite", "type": "transformWord", "skill": "grammar", "_review": "Opposite pair حلو→مُرّ — confirm appropriate.", "prompt": [{"kind": "say", "line": "Write the opposite of حلو."}, {"kind": "rule", "label": "Opposite · ضد"}, {"kind": "text", "text": "حلو"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "مر"}}, "check": "sequence+transformRule", "feedback": {"pass": "مُرّ — أحسنت!", "wrongWord": "The opposite of sweet is مُرّ."}, "signedOff": false}
{"id": "haa_c.fillBlank.noun", "type": "fillBlank", "skill": "vocabulary", "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."}, {"kind": "text", "text": "حصان"}], "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": "حصان"}}, "check": "sequence", "feedback": {"pass": "Yes! أحسنت!", "wrongWord": "Read the sentence again and pick the word that fits."}, "signedOff": false}
{"id": "haa_c.buildSentence.hear", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."}, {"kind": "audio", "audioId": "sentence.alhisaanu-saree"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["الحِصانُ", "سَريع"]}, "check": "order+sequence", "feedback": {"pass": "الحِصانُ سَريع — “the horse is fast.” A whole sentence! أحسنت!", "wrongOrder": "Keep the words in order: الحِصانُ سَريع."}, "signedOff": false}
{"id": "haa_c.buildSentence.picture", "type": "buildSentence", "skill": "syntax", "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."}, {"kind": "image", "imageId": "img.whale", "caption": "حوت"}], "surface": {"mode": "write", "unit": "sentence"}, "expected": {"words": ["الحوتُ", "كَبير"]}, "check": "order+sequence", "feedback": {"pass": "الحوتُ كَبير — a whole sentence! أحسنت!", "wrongOrder": "Keep the words in order: الحوتُ كَبير."}, "signedOff": false}
```

---

## 4 · `words.json` additions

Paste into `words.json` → `words[]` (only words not already present; تاج/حليب already exist):

```json
{"id": "thalab", "text": "ثعلب", "audio": "word.thalab", "image": "img.fox", "gloss": {"en": "fox"}, "letters": ["thaa", "ayn", "laam", "baa"]}
{"id": "thalj", "text": "ثلج", "audio": "word.thalj", "image": "img.snow", "gloss": {"en": "snow"}, "letters": ["thaa", "laam", "jeem"]}
{"id": "thuban", "text": "ثعبان", "audio": "word.thuban", "image": "img.snake", "gloss": {"en": "snake"}, "letters": ["thaa", "ayn", "baa", "alif", "noon"]}
{"id": "thawm", "text": "ثوم", "audio": "word.thawm", "image": "img.garlic", "gloss": {"en": "garlic"}, "letters": ["thaa", "waaw", "meem"]}
{"id": "muthallath", "text": "مثلث", "audio": "word.muthallath", "image": "img.triangle", "gloss": {"en": "triangle"}, "letters": ["meem", "thaa", "laam", "thaa"]}
{"id": "jamal", "text": "جمل", "audio": "word.jamal", "image": "img.camel", "gloss": {"en": "camel"}, "letters": ["jeem", "meem", "laam"]}
{"id": "jazar", "text": "جزر", "audio": "word.jazar", "image": "img.carrots", "gloss": {"en": "carrots"}, "letters": ["jeem", "zaay", "raa"]}
{"id": "jabal", "text": "جبل", "audio": "word.jabal", "image": "img.mountain", "gloss": {"en": "mountain"}, "letters": ["jeem", "baa", "laam"]}
{"id": "dajaja", "text": "دجاجة", "audio": "word.dajaja", "image": "img.hen", "gloss": {"en": "hen"}, "letters": ["daal", "jeem", "alif", "jeem", "taa_marbuta"]}
{"id": "hisaan", "text": "حصان", "audio": "word.hisaan", "image": "img.horse", "gloss": {"en": "horse"}, "letters": ["haa_c", "saad", "alif", "noon"]}
{"id": "hoot", "text": "حوت", "audio": "word.hoot", "image": "img.whale", "gloss": {"en": "whale"}, "letters": ["haa_c", "waaw", "taa"]}
{"id": "miftaah", "text": "مفتاح", "audio": "word.miftaah", "image": "img.key", "gloss": {"en": "key"}, "letters": ["meem", "faa", "taa", "alif", "haa_c"]}
{"id": "tuffah", "text": "تفاح", "audio": "word.tuffah", "image": "img.apple", "gloss": {"en": "apple"}, "letters": ["taa", "faa", "faa", "alif", "haa_c"]}
```

---

## 5 · Asset manifest (must exist before any of this is presentable)

A word is hollow without its sound and picture. These IDs are referenced above and need producing.

### Audio (TTS via `tools/tts/`)
- Letter sounds: `snd.thaa`, `snd.jeem`, `snd.haa_c`
- Words: `word.thalab`, `word.thalj`, `word.thuban`, `word.thawm`, `word.muthallath`, `word.jamal`, `word.jazar`, `word.jabal`, `word.dajaja`, `word.hisaan`, `word.hoot`, `word.miftaah`, `word.tuffah`
- Sentences: `sentence.aththalju-baarid`, `sentence.aththubaanu-taweel`, `sentence.aljamalu-kabeer`, `sentence.aljabalu-aalin`, `sentence.alhisaanu-saree`, `sentence.alhootu-kabeer`
- Already exist (reused): `word.taaj`, `word.haliib`

### Images (illustrations)
- New: `img.fox`, `img.snow`, `img.snake`, `img.garlic`, `img.triangle`, `img.camel`, `img.carrots`, `img.mountain`, `img.hen`, `img.horse`, `img.whale`, `img.key`, `img.apple`
- Already exist (reused): `img.crown`, `img.milk`

**Counts:** 3 letter sounds · 13 word clips · 6 sentence clips · 13 images to produce.

---

## 6 · Sign-off checklist for Owner-mother

Per letter, please confirm or correct (this is the gate — nothing ships until ✔):

**ثاء (thaa)** — *vocab came straight from your `أ - ب - ت - ث` worksheet*
- [ ] Word choice for a 5–10yo: fox · snow · snake · garlic · triangle — keep / swap?
- [ ] Stroke story: "boat, then three dots like a little triangle" — right?
- [ ] Mistake feedback lines read in your voice?
- [ ] Grammar transforms: dual ثعلبان · plural **ثعالب** · opposite ثقيل→خفيف — correct & age-right?

**جيم (jeem)** — *vocab is my draft (your worksheet was image-only)*
- [ ] Replace any of camel · carrots · mountain · hen · crown with words you prefer?
- [ ] Stroke story: "round belly, one dot inside underneath" — right?
- [ ] Plural **جبال**, opposite جميل→قبيح — keep?

**حاء (haa)** — *vocab partly from the picture-word PDF*
- [ ] Word list: horse · whale · key · apple · milk — keep / swap?
- [ ] The "**no dot — that's how we know it's not jeem**" contrast — teach it this way?
- [ ] Plural **حيتان** — confirm.

When signed: I (1) flip `signedOff: true` on the confirmed items, (2) add the ids to
`server/app/curriculum_data/baa_authored_ids.json`'s authored set (rename/extend for these
letters) so the server rail will present them, (3) build the per-letter curriculum graphs,
and (4) queue the audio + image assets. All of that runs through `/gsd-quick`.

---

*Drafted 2026-06-28. 3 letters · 57 exercises · 13 new words · 32 assets to produce.*
*Family note: thaa completes the baa family (boat + dots); jeem & haa open the ج ح خ family
(same body, dot position is the whole lesson) — khaa (letter 7) is the natural next batch.*
