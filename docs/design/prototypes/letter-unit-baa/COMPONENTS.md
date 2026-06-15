# COMPONENTS.md — component inventory

The prototype is **5 components + 1 reused primitive**, matching
`COMPONENT-SYSTEM.md §2` exactly. Names below are 1:1 with the spec. Source lives in
`prototype/exercise-components/components.js` (`window.QC`) and `components.css`; the reused
ink primitive is `prototype/shared/core.js` (`window.Q`).

> Mental model: **ExerciseScaffold** is the page. It hosts **PromptHeader** (top), **WriteSurface**
> (center), **FeedbackPanel** + CTA (bottom), and **ProgressRibbon** (edge), with the **mascot** as
> presenter/reactor. Every question type and every unit section is these same parts fed different config.

---

## 1. `ExerciseScaffold`
The page shell. RTL, landscape (1280×800 design frame, JS-scaled to fit).

**Props / config** (`load(config)`):
| field | type | drives |
|---|---|---|
| `kick` | string | the small eyebrow label (e.g. "Q3 · writeWord") |
| `pose` | mascot state | initial mascot pose |
| `prompt` | `PromptPart[]` | handed to PromptHeader |
| `surface` | object \| omitted | handed to WriteSurface; omit for teach/section screens |
| `customSurface` | fn → el | escape hatch for a non-writing panel (teachCard forms) |
| `feedback` | `{pass, fix}` *(prototype shape)* | handed to FeedbackPanel |
| `ribbon` | `{total, active}` | handed to ProgressRibbon |
| `tutorExtra` | fn → el | optional panel under the speech bubble (e.g. "support screen" chip) |
| `supportCta` | string | CTA label for non-graded screens |
| `onNext` | fn | advance handler |

**Slots:** `[data-mascot] [data-speech] [data-tutorslot]` (left column) · `[data-kick] [data-ribbon] [data-prompt] [data-surface] [data-feedback] [data-cta]` (main column).

**States:** drives mascot pose + speech tone via one `tutorAndFeedback(pose, html, tone)` callback that the validator calls — `coral`→fix, `leaf`→pass. `showState('prompt'|'fix'|'pass')` exists for the gallery's preview toggle.

**Used in:** every screen — the 6 question types, 2 support screens, and (conceptually) all 6 unit sections.

---

## 2. `PromptHeader`
Renders an **ordered list of PromptParts** — this is the composition engine.

**PromptPart kinds** (discriminator `kind`):
| kind | fields | renders |
|---|---|---|
| `say` | `line` | pulled out → mascot speech bubble (always present) |
| `audio` | `audioId` *(prototype: `label`)* | teal play button (visual-only ping) |
| `image` | `imageId`, `caption?` | hatched picture stub + caption |
| `text` | `text`, `gaps?` | Arabic text; tokens `__blank__` (missing word) and `_letter_` (missing-letter slot); `hidden`/`reveal` for copy; `loose` for connect |
| `rule` | `label` *(prototype also `labelAr`)* | gold instruction chip («مثنى» / «عكس») |

**States:** static (cue only). Empty (only `say`) → header collapses.

**Used in:** all screens. The teachCard adds a non-spec `forms` part (see §6).

---

## 3. `WriteSurface`
The one canvas. Wraps the **existing ink/trace primitive** (`Q.makeWrite`, see §"Reused primitive").

**Props:**
| field | values | effect |
|---|---|---|
| `mode` | `trace` \| `write` | `trace` = faint guide overlay; `write` = blank ruled line |
| `unit` | `glyph` \| `word` \| `sentence` | canvas width / glyph size / ruled-line length |
| `guideForm` | `isolated`\|`initial`\|`medial`\|`final` | (trace) which contextual form the guide shows |
| `given` | `{word, blankIndex}` | pre-fills letters the child does NOT write (completeWord); renders a dashed blank cell |
| `demo` | bool | (trace) animated stroke demo available ("Watch me") |
| `corner` | bool | shows the in-canvas "Watch Me" replay button |
| `ghost` | bool | on a miss, overlays the correct path in green (connect/firstFix) |
| `reps` | int | clean-rep pips required before pass |

**States:** idle → drawing → `think` (validating) → `pass` | `fix`. Emits stroke length → validator stub. `clear()`, `markCorrect()`, `replayDemo()` on the returned controller.

**Used in:** traceLetter (mode=trace), writeLetter/writeWord/connectWord/transformWord/fillBlank (mode=write), buildSentence (unit=sentence), completeWord (given), letterMaze (trace, relaxed). NOT used by teachCard.

---

## 4. `FeedbackPanel`
Two states, shared by all graded types. Driven entirely by the validator result.

| state | renders |
|---|---|
| `pass` | one quiet gold **star** + praise line (tutor voice) |
| `fix` | coral panel + ✕ icon + the **specific** authored fix line |
| *(idle)* | the "write on the surface" hint |

**Used in:** all 6 question types + letterMaze (pass only). NOT teachCard.

---

## 5. `ProgressRibbon`
R→L position dots. **Position, not score** — no numbers, no streaks.

**Props:** `total`, `active`. **States:** per dot — `done` / `active` / upcoming.
**Used in:** every screen (unit section index; in the gallery it mirrors the question number).

---

## Reused primitive (not a new component)
**`Q.makeWrite`** (`shared/core.js`) — the pre-existing geometric ink/trace canvas from the built
Practice screen: dotted guide, gold start-dot, animated demo, clean-rep pips, green ghost-correction,
and the `think→pass/fix` validation stub. **WriteSurface is a thin config wrapper over this.** The
**mascot** (`Q.M`, states `idle/think/write/cheer/try-again`) and the **design tokens** are likewise
reused as-is, per the spec.

---

## Components added beyond the 5
**None that are structural.** Two honest call-outs:

1. **`teachCard` "forms" strip** — the Meet/teach section needs to show the four contextual forms.
   It's rendered as a `customSurface` panel inside ExerciseScaffold, and modeled as a non-spec
   `prompt.kind:"forms"` part in the config. This is **content, not a new component** — but the spec's
   PromptPart list doesn't include it. *Reconcile:* add `forms` as a PromptPart kind, or compose it
   from `image`+`text`. Flagged in SCHEMA-BINDINGS.md.
2. **CTA buttons** (Clear / Mark correct / Try again / Next / Got it) live in ExerciseScaffold's
   bottom slot beside FeedbackPanel — matching the spec's "FeedbackPanel/CTA (bottom)". Not a separate
   component.

So: **5 components, 1 reused canvas, 0 new structural components** — the system held.
