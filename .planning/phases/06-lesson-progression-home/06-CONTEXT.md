# Phase 6: Lesson Progression & Home - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the mocked/hardcoded progression with the real thing: Home shows the actual
next unlocked lesson for the active child with one prominent Start (S1-01); lessons
unlock strictly by the curriculum's clean-reps-to-advance rule, immediately on pass
(S1-09); the Journey map reads live mastery data. Plus five approved ride-alongs
that deepen the same surfaces: prepared-desk entrance, ink-fill progress, a
"show someone at home" tutor line, a data-driven scaffolding fade for rep scoring,
and a slow-motion ghost comparison in feedback.

**Key starting facts:** `lessons.json` contains only `lesson_01` (alif);
`PracticeScreen` is hardwired to `lesson_01`; the Journey screen reads a static
mock provider; 27 of 28 letters are DRAFT (`signedOff: false`); clean reps exist
only in-session today (DB persists only mastery records).

</domain>

<decisions>
## Implementation Decisions

### Lesson catalog & draft-letter policy
- **D-01:** Expand `lessons.json` from 1 to 28 lessons — one lesson per letter in
  curriculum order, each with `unlock.requires = [previous lesson id]`. Curriculum
  stays data, not code; the owner's mother can reorder/regroup by editing JSON.
- **D-02:** The unlock engine evaluates `unlock.requires[]` generically: a lesson is
  unlocked when every lesson in its `requires[]` is passed. Behaves linearly with
  today's data but supports future grouping/branching as a data-only change.
- **D-03:** Progression flows freely through DRAFT (`signedOff: false`) letters.
  Sign-off is a content milestone (tracked via 04-06), enforced before real release —
  NOT a code gate in the unlock engine.
- **D-04:** Draft status is invisible to the child — no markers on Home or Journey.
  The /dev authoring tools remain the adults' view of sign-off state.

### Grade entry point & skipped lessons
- **D-05:** Lessons earlier than the profile's `startingLessonId` are **unlocked but
  not mastered** — revisitable anytime from the Journey, no fake mastery rows, stars
  appear only when actually passed.
- **D-06:** Today's lesson = first non-passed lesson **at or after** `startingLessonId`
  (marches forward; supersedes 03.1 D-07's "first non-mastered overall" once an entry
  point exists). Skipped earlier letters never become "today" on their own.
- **D-07:** On the Journey map, skipped-but-unlocked letters reuse the existing
  "future" visual (white, dashed border) but are tappable → practice. No new visual
  state in this phase.

### Home today-card
- **D-08:** Card keeps its existing layout with live data (letter glyph, name) PLUS
  progress context for the current letter's clean reps.
- **D-09:** Progress context renders as **ink-fill**: the day's letter itself fills
  with ink — one clean rep = one shade deeper, fully inked = mastered. This REPLACES
  plain rep-dots. Pure design-system rendering (parchment/ink), no gamification.
- **D-10:** Partial clean reps **persist across sessions** in the DB (new per-letter
  rep count, updated as reps accrue; new schema migration). Home and practice both
  read it. ⚠️ **Flagged for the owner's mother:** whether reps must be same-sitting/
  consecutive is her pedagogy call — persisting across sessions is the shipped default
  until she rules.
- **D-11:** End state when every available lesson is passed: a calm, dignified
  "you've mastered all your letters" card; Start offers review practice via the
  Journey. Factual, no hype, no Level-2 teasing.
- **D-12:** Replay of mastered lessons happens via Journey green nodes only. Home
  stays single-purpose: one clear Start (S1-01).
- **D-13:** "Prepared desk" entrance: when Home opens, the lesson card settles in like
  a teacher laying out today's worksheet (paper slides in, dotted letter fades up).
  One small entrance animation; respects reduced-motion if the platform requests it.

### Pass → unlock moment
- **D-14:** The mastery celebration gains a primary **"Next lesson"** button that goes
  straight into the newly unlocked letter's practice, alongside the existing
  "See journey". Returning Home also shows the new lesson.
- **D-15:** Fold in the 03.1-deferred journey highlight: arriving from the celebration
  (`/journey?highlight=<id>` or equivalent), the just-mastered node gets a brief
  emphasis (star badge settles in) before the pulse moves to the new current node.
- **D-16:** When the child passes the LAST lesson, the "Next lesson" slot becomes
  "See journey"; Home then shows the D-11 completion state. No special capstone screen
  in this phase.
- **D-17:** "Show someone at home": after a mastery, the celebration includes one warm
  tutor line — e.g. *"Go show your baa to someone at home."* One l10n string, tutor
  voice rules apply (warm, specific, never chatbot-cheerful).

### Scaffolding fade (rep → tolerance ramp)
- **D-18:** Within a lesson, rep N scores against a tolerance preset from a
  **data-driven ramp**, default `[loose, normal, strict]` (Phase 4 presets, already
  data). Rep 1 = loose, rep 2 = normal, final rep = strict.
- **D-19:** The ramp lives as data (per-lesson with a global default), NOT hardcoded —
  the owner's mother can flatten it to all-`normal` or reorder it without code change.
  ⚠️ **Flagged for her sign-off:** this changes what "clean rep" means; the mechanism
  ships, the rule is hers.
- **D-20:** The ramp follows the **persisted rep index** (D-10), not the sitting — a
  child resuming at rep 2 scores at rep 2's preset.

### Slow-motion ghost comparison
- **D-21:** When a stroke is wobbly (fails shape checks), the feedback zone can replay
  the child's stroke beside the reference at half speed — "Watch the difference."
  Uses **in-memory strokes only**; stroke points are NEVER persisted (T-03-01 holds).

### Claude's Discretion
- Route parameterization mechanics (`/practice?lesson=X` vs path param vs extra) —
  pick what fits the existing GoRouter codegen pattern.
- How "lesson passed" is derived (existing `LetterMastery` rows are the pass record
  for single-letter lessons; no separate lesson-pass table needed unless planning
  finds otherwise).
- Whether the live journey provider replaces `mockJourneyProgress` in place or is a
  new provider the screen switches to (03.1 D-08 says screen doesn't change).
- Lesson title strings for lessons 2–28 (placeholder "Lesson N — <Letter>" pattern;
  final wording is content, not code).
- Exact ink-fill rendering technique and the prepared-desk animation curve/timing —
  follow design-system tokens.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & prior context
- `.planning/REQUIREMENTS.md` — S1-01 and S1-09 acceptance criteria (this phase's contract).
- `.planning/phases/03.1-journey-map-screen/03.1-CONTEXT.md` — Journey screen decisions; D-07/D-08 are amended by this phase's D-06 and live-provider swap.
- `.planning/phases/05-profiles-onboarding/05-CONTEXT.md` — `startingLessonId` seam, grade→entry-point mechanism, child-data posture.

### Curriculum data
- `assets/curriculum/lessons.json` — current single-lesson file; the `unlock.requires[]` + `passRule` schema to expand to 28 lessons.
- `assets/curriculum/letters.json` — 28 letters with `cleanRepsToAdvance`, `signedOff`, curriculum order.

### Design
- `docs/design/kit/project/colors_and_type.css` — design tokens (parchment/ink palette) for ink-fill and prepared-desk.
- `docs/design/kit/project/SKILL.md` — brand rules; tutor voice for the D-17 line.
- `docs/design/practice-redesign/` — the 2026-06-07 practice-screen three-zone redesign spec (Trace/ShowFix/ShowPraise); the slow-motion ghost (D-21) lands in its feedback zone.

### Existing code — read before planning
- `lib/screens/home_screen.dart` — `_TodaysLessonCard` (hardcoded alif → `/practice`); greeting already reads `childProfileProvider`.
- `lib/providers/journey_providers.dart` — `mockJourneyProgress` to be replaced with live data (per 03.1 D-08, screen unchanged).
- `lib/features/journey/journey_screen.dart` — node tap currently `context.go('/practice')` with no letter; needs lesson param + highlight arrival.
- `lib/providers/practice_providers.dart` — `practiceSessionController` already family-keyed by `lessonId`; rep counting + `_recordMastery` live here; the tolerance ramp (D-18) hooks in where `scoreStroke`/`scoreLetter` receive `Tolerances`.
- `lib/features/practice/practice_screen.dart` — hardwired `_lessonId = 'lesson_01'`; mastery celebration wiring.
- `lib/features/practice/widgets/mastery_celebration.dart` — gains "Next lesson" (D-14) and the D-17 tutor line.
- `lib/data/progress_repository.dart` + `lib/data/drift_progress_repository.dart` — `recordMastery`/`isMastered`; extend for persisted partial reps (D-10).
- `lib/data/app_database.dart` — `LetterMastery` table; schema v3 → v4 migration for rep persistence (follow the v2→v3 idempotent pattern from Phase 5).
- `lib/data/curriculum_repository.dart` — `getLessons()`/`getLesson(id)`; lesson order source.
- `lib/data/child_profile_repository.dart` — active child + `startingLessonId`.
- `lib/router/app_router.dart` — `/practice` and `/journey` routes to parameterize.
- `lib/core/scoring/` — `Tolerances` presets (loose/normal/strict) from Phase 4; D-18 consumes them unchanged.

### Project rules
- `CLAUDE.md` §"Decided" — anti-gamification invariants; tutor voice; curriculum is the owner's mother's domain (D-10/D-19 sign-off flags follow from this).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `practiceSessionController` family-keyed by `lessonId` — progression only needs to pass a different key; the controller already loads the right letter and counts reps.
- `Tolerances.loose/normal/strict` (Phase 4) — the scaffolding ramp is pure data reuse.
- `JourneyProgress` model + journey screen state computation — swap the provider, keep the screen (03.1 D-08).
- Phase 5's v2→v3 Drift migration — the idempotent migration pattern to copy for the rep-persistence schema change.
- `ArabicText` widget — letter glyph on the live Home card.
- `StrokeOrderAnimation` machinery — the slow-motion ghost replay can reuse the same path-animation approach with the child's in-memory stroke.

### Established Patterns
- Riverpod codegen providers (`@riverpod`, `keepAlive: true` for repositories); NOTE: hand-written `FutureProvider` needed when returning Drift data classes (riverpod_generator 4.0.3 bug — see Phase 5 decision).
- GoRouter codegen with synchronous redirect gate (Phase 5) — lesson param should not break the onboarding redirect.
- `import 'package:drift/drift.dart' hide isNull, isNotNull;` in tests mixing flutter_test matchers with Drift.
- Anti-gamification: stars = mastery markers only; "N of 28 mastered" is information, not score.

### Integration Points
- `home_screen.dart` `_TodaysLessonCard` → live "today's lesson" provider (new).
- `journey_providers.dart` → live progression provider reading ProgressRepository + CurriculumRepository + ChildProfileRepository.
- `app_router.dart` → `/practice` lesson param; `/journey` highlight param.
- `app_database.dart` → schema v4 (persisted partial reps).
- `mastery_celebration.dart` → "Next lesson" + tutor line.
- `assets/curriculum/lessons.json` → 28 lesson entries.

### Known test debt (don't mistake for regressions)
- Golden font drift: `glyph_audit` + `mastery_celebration` goldens fail locally from font rendering — do not re-bake.
- Stale Phase 03.1 nav tests: `home_screen` "Coming soon" + `mastery_celebration` "no See Journey button" tests are stale debt; Phase 6 touches both surfaces and should finally reconcile them.

</code_context>

<specifics>
## Specific Ideas

- **Ink-fill metaphor:** the progress indicator IS the letter — each clean rep deepens
  the ink shade until fully inked = mastered. "The progress is the letter."
- **Prepared desk:** Home card arrives like a teacher laying out a worksheet — paper
  slides onto the desk, dotted letter fades up. Sells "the lesson was prepared before
  you arrived" (S1-01's spirit).
- **Tutor line wording direction (D-17):** warm, specific, family-oriented — e.g.
  "Go show your baa to someone at home." Final copy follows tutor-voice rules; a
  little Arabic welcome.
- **Ghost comparison framing:** "Watch the difference" — side-by-side, half speed,
  child's stroke vs reference. Teaching moment, not error-shaming.

</specifics>

<deferred>
## Deferred Ideas

Captured during the creative ideation round (researched 2026-06-11: traditional
calligraphy pedagogy, Kumon method, protégé-effect, haptics research, heritage-language
motivation research). High-impact candidates marked ★.

- ★ **A1 Ijaza** — dignified calligraphy-tradition certificate on Level 1 completion,
  possibly carrying the owner's mother's real signature (Phase 7-ish; the anti-badge).
- **A2 Nuqta ruler** — traditional dot-grid proportion overlay in practice (her call).
- **A3 Mashq sheets** — printable PDF dotted worksheets for today's letter (Phase 9/10;
  paper bridge + offline story).
- **B4 Haptic ink** — vibration while stylus stays on path (motor-learning research).
- **B3 Pressure-sensitive ink** — stylus pressure drives line thickness.
- **B5 Mirror-writing check** — mirrored-stroke detector via the commonMistakes
  machinery (her call on which letters).
- ★ **C1 Write your own name** — capstone when the child has mastered the letters of
  their chosen Arabic nickname (نجمة/قمر/أسد…); all data already exists.
- **C2 First words are family words** — ماما/بابا first when word-writing arrives in
  Phase 8 (her call on order).
- **C4 Teach Qalam** — protégé-effect review: the reed pen "forgets" a letter and asks
  the child to demonstrate it (v2; strongest for struggling learners per research).
- **C5 Mom's voice as pronunciation audio** — record the owner's mother as the literal
  letter voice (Phase 7 content task).
- **D3 Warm-up rep** — one rep of yesterday's letter before today's; needs multi-item
  lesson support in the practice screen — natural for Phase 7 (her call).
- **D4 Qalam closes the notebook** — bounded daily session; the tutor warmly ends the
  session after today's work (her call on session size; Phase 7+).
- **E1 Fridge page** — weekly one-page parent PDF of real progress in tutor voice (Phase 9).
- **E2 My-handwriting notebook** — child's best-rep strokes archive; requires conscious
  revision of the never-persist-strokes rule T-03-01 (Phase 9; decision-gated).
- **E3 Teacher insight loop** — aggregate which commonMistakes fire most per letter for
  the curriculum owner (Phase 9).
- **E4 Left-handed mode** — hand-position offset + selective UI mirroring (before release).

</deferred>

---

*Phase: 06-lesson-progression-home*
*Context gathered: 2026-06-11*
