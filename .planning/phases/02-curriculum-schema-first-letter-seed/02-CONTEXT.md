# Phase 2: Curriculum Schema & First-Letter Seed - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a read-only curriculum data schema (typed Dart models + bundled JSON assets)
containing all 28 Arabic letters with their contextual forms, reference stroke paths,
stroke order, intro order, clean-reps-to-advance, per-letter pass tolerances, and
common mistakes with child-friendly fix messages — authored to the extent mom's spec
is available, with explicit placeholders where content is pending. Plus a minimal
`lessons.json` skeleton with `lesson_01` (alif) so Phase 3 can boot the end-to-end
trace loop.

**In scope:** Python font-extraction script; `assets/curriculum/letters.json` (all 28
letters); `assets/curriculum/lessons.json` (lesson_01 skeleton only); typed Dart models
(`Letter`, `LetterForm`, `StrokeSpec`, `CommonMistake`, `Lesson`, `LessonItem`);
`CurriculumRepository` (loads + decodes JSON, returns typed models); Riverpod provider
wiring; the extraction + stroke-mapping authoring workflow.

**Out of scope (later phases):** `exercises.json` (Phase 8); real lesson groupings
beyond lesson_01 (Phase 6/7); full common-mistakes content for all 28 letters (Phase 7
fills placeholders); the geometric scorer (Phase 3); ML Kit integration (Phase 3);
practice UI (Phase 3).

</domain>

<decisions>
## Implementation Decisions

### Reference stroke path authoring

- **D-01:** The owner's mother supplies stroke order as **prose description** (e.g.
  "start top-right, curve down-left, end at baseline") — not coordinate paths. A
  digitization step is required: Phase 2 produces the paths by extracting Noto Naskh
  Arabic font contour components.
- **D-02:** A **Python extraction script** (`tools/extract_reference_paths.py` or
  similar) reads the bundled `assets/fonts/NotoNaskhArabic-*.ttf`, extracts each
  letter's discrete contour components (e.g. baa = bowl contour + dot contour),
  simplifies to a polyline, and normalizes coordinates to a **0..1 bounding box**. The
  script outputs candidate paths for the owner to inspect and map to strokes.
- **D-03:** The **stroke-to-contour mapping** is the owner's job: for each letter the
  owner reads mom's stroke description, identifies which extracted contour corresponds
  to each stroke, and records them in the correct order as the `referenceStrokes` array
  in `letters.json`. This mapping IS the owner's-mother sign-off contribution for the
  path data.
- **D-04:** All four **contextual forms** (isolated/initial/medial/final) are captured
  for each letter where the forms differ. The glyph audit from Phase 1 (D-12) confirmed
  Noto Naskh shapes these correctly.

### Letter coverage

- **D-05:** **All 28 letters** are authored in Phase 2 (not a small seed). The full set
  unblocks Phase 7 from becoming a content-only phase and lets Phase 4 calibrate the
  scorer against real paths for all letters.
- **D-06:** **Stroke order + contextual forms + intro order + `cleanRepsToAdvance`**
  are authored for all 28 letters (mom's spec covers these for the full set).
- **D-07:** **Common mistakes + fix messages** are authored where mom's spec has them;
  entries without spec are set to `null` (or an empty array) and marked with a
  `"mistakesStatus": "placeholder"` field. Phase 7 fills the gaps before lessons ship.
- **D-08:** **Alif (ا) is intro letter #1** in mom's sequence — it is the Phase 3
  trace target and must have a complete entry (including at least placeholder paths)
  before Phase 2 is done.

### Lessons.json scope

- **D-09:** Phase 2 creates a **minimal `lessons.json`** with a single `lesson_01`
  entry containing alif. This is all Phase 3 needs to boot the end-to-end slice. Real
  lesson groupings (which letters go in which lesson) are deferred to Phase 6/7.
- **D-10:** **`exercises.json` is NOT created in Phase 2.** The `CurriculumRepository`
  should gracefully handle the file's absence (return empty list, not throw). Phase 8
  creates and owns exercises content.

### Owner's-mother sign-off gate

- **D-11:** Sign-off is **per-letter, tracked in the JSON** via a `"signedOff": bool`
  field. A letter is marked `signedOff: true` only after the owner has reviewed its
  content (forms, stroke paths as rendered, and available mistakes) with mom
  in-person or over a screen share. Unsigned letters are valid data but are flagged as
  pending in any dev review of Phase 2's output.
- **D-12:** **Phase 2 must have at least alif fully signed off** before declaring done
  (Phase 3 will trace it). The remaining 27 can be `signedOff: false` with complete
  data — Phase 7 is the gate for the full 28.

### Claude's Discretion

- Exact location of the Python extraction script (`tools/`, `scripts/`, `dev/`) —
  implementer's call; keep it out of `assets/` and `lib/`.
- Font contour simplification algorithm (Douglas-Peucker, uniform resampling, or
  direct bezier → polyline at fixed interval). Uniform resampling at N=50–100 points
  is a fine default; the scorer normalizes anyway.
- Whether per-letter `referenceStrokes` live inline in `letters.json` or in a
  companion `reference_paths.json` split by letter ID. Inline is simpler to load.
- Exact Dart model field names and nullability (e.g. `List<CommonMistake>?` vs
  empty list for placeholder mistakes).
- JSON Schema validation (optional `letters.schema.json` alongside the data files —
  nice-to-have for authoring safety; planner decides if it's in scope).
- How the scorer handles a letter with no `commonMistakes` — a generic fallback
  message ("Something looks off — try again slower.") is the scorer's problem,
  not Phase 2's.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Curriculum data model (the schema design)
- `.planning/research/ARCHITECTURE.md` §"Curriculum Data Model" — full JSON schema
  sketch for `letters.json`, `lessons.json`, `exercises.json`; Dart model map;
  `CurriculumRepository` pattern; "one source of truth" principle for reference paths
- `.planning/research/STACK.md` — prescriptive package list and versions; verify at
  plan time

### Project scope & requirements
- `.planning/ROADMAP.md` §"Phase 2: Curriculum Schema & First-Letter Seed" — success
  criteria and research hints; the reference-stroke-path open question is now answered
  (D-01–D-04 above)
- `.planning/REQUIREMENTS.md` §CUR-01 — the seeded-and-signed-off acceptance criteria
  (CUR-01 is seeded here, fully satisfied in Phase 7)
- `.planning/PROJECT.md` §"Curriculum is the owner's mother's domain" — pedagogy
  mandate; we structure, we don't invent
- `docs/USER_STORIES.md` — owner's backlog; S1-04 and S1-05 (scoring) require this
  phase's reference paths

### Font (source of reference glyph outlines)
- `assets/fonts/NotoNaskhArabic-*.ttf` — **the font from which reference contours are
  extracted**; the Phase 1 glyph audit (01-03) confirmed it shapes all four contextual
  forms correctly for curriculum letters (decision D-12 of Phase 1)
- `.planning/phases/01-foundations-rtl-shell/01-CONTEXT.md` §D-12 — glyph audit
  result; Noto Naskh confirmed, Amiri is documented fallback

### Architecture & conventions
- `.planning/research/ARCHITECTURE.md` §"Recommended Project Structure" — where
  `lib/models/`, `lib/data/curriculum_repository.dart`, and `assets/curriculum/` live
- `.planning/codebase/CONVENTIONS.md` — Dart naming, file layout, import rules
  (models must not import from data or services)
- `.planning/codebase/STRUCTURE.md` — current `lib/` layout; Phase 2 adds
  `lib/models/` and `lib/data/curriculum_repository.dart`

### Design system (for any Phase 2 dev/debug rendering)
- `docs/design/kit/project/SKILL.md` — brand hard-rules (gold rewards-only, no red,
  Western numerals, Arabic content sizing rules)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/data/app_database.dart` — the Drift DB and its Riverpod provider pattern
  (`@Riverpod(keepAlive: true)`) are the template for Phase 2's
  `CurriculumRepository` provider (also kept-alive; curriculum is app-scoped).
- `lib/app.dart` — `ProviderScope` root; Phase 2's `CurriculumRepository` provider
  is initialized here (or lazily on first watch).
- `assets/fonts/` — Noto Naskh TTFs are already bundled (Phase 1, D-03); the
  extraction script reads from this path.

### Established Patterns
- **Riverpod codegen** (`@riverpod` / `@Riverpod`) is established (Phase 1, D-11) —
  Phase 2 follows the same codegen pattern for all new providers.
- **Models import nothing** — `lib/models/*.dart` must not import from `lib/data/`
  or `lib/features/`. Matches CONVENTIONS.md.
- **`build_runner`** is already wired (Phase 1) — Phase 2's new codegen annotations
  just need `dart run build_runner build`.

### Integration Points
- `lib/data/curriculum_repository.dart` (new) → reads `rootBundle`-loaded JSON →
  returns typed `Letter` and `Lesson` models consumed by Phase 3's
  `practiceSessionController`.
- `assets/curriculum/letters.json` + `lessons.json` → declared in `pubspec.yaml`
  assets section (Phase 2 adds this declaration).
- Phase 3 wires `todaysLessonProvider` → `CurriculumRepository.getLesson("lesson_01")`
  → `Letter` with `id: "alif"` as the first trace target.

</code_context>

<specifics>
## Specific Ideas

- The research architecture doc already has a complete example `letters.json` snippet
  for `baa` (`.planning/research/ARCHITECTURE.md` §"Curriculum Data Model") — use it
  as the authoring template for all 28 letters. Alif will be simpler (fewer strokes,
  fewer forms).
- Coordinate normalization should use a **per-letter 0..1 bounding box** so the scorer
  and the guide-letter renderer can both use the paths without knowing the device
  screen size. Scale to actual canvas size at render time.
- The `mistakesStatus` field (D-07) is an authoring metadata field — it does NOT need
  to ship in the final curriculum spec. Strip it before Phase 7 sign-off, or keep it
  as a developer flag.
- The Python extraction script is a one-time authoring tool, not a production artifact.
  It can depend on `fonttools` (pip install fonttools). It doesn't need to be
  beautiful — it just needs to produce inspectable JSON.

</specifics>

<deferred>
## Deferred Ideas

- **Real lesson groupings** (which letters go in which lesson, in what week order) →
  Phase 6/7. Mom's full lesson-sequence plan is deferred until progression is built.
- **`exercises.json`** (sentence-building and grammar content) → Phase 8.
- **Full common mistakes for all 28 letters** → Phase 7. Mom's spec covers a few
  letters now; the rest are placeholders.
- **Audio references** in `letters.json` — the `audio` field can be authored as
  placeholders (`null`) now; real audio paths land in Phase 7 when recordings exist.
- **`signedOff` for letters 2–28** → Phase 7's sign-off gate. Only alif must be signed
  off before Phase 2 is done (it's Phase 3's trace target).

</deferred>

---

*Phase: 2-Curriculum Schema & First-Letter Seed*
*Context gathered: 2026-05-31*
