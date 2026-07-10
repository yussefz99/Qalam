# Phase 18: The Living Tutor — per-child dynamic exercise selection - Context

**Gathered:** 2026-07-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Every "next exercise" pick becomes a deliberate, explainable teaching move informed by a
persistent model of THIS child — a two-timescale child model (within-session per-criterion
attempt history + nightly Python compile of `strengths[]`/`struggles[]`), remediation arcs
(sketch 001), just-this-part micro-drills (sketch 002), and an anti-boredom rule with a
teacher-justification line — while staying railed to the signed curriculum graph, preserving
the offline walker floor, and closing the cost/latency open research question with measured
numbers.

**Precondition:** branch `gsd/phase-17.2-demo-extras` merged to `main` before the phase-18
branch is cut.

</domain>

<spec_lock>
## Requirements (locked via SPEC.md)

**9 requirements are locked.** See `18-SPEC.md` for full requirements, boundaries, and acceptance criteria.

Downstream agents MUST read `18-SPEC.md` before planning or implementing. Requirements are not duplicated here.

**In scope (from SPEC.md):**
- Two-timescale child model: within-session per-criterion attempt history feeding selection + nightly Python compile of per-child `strengths[]`/`struggles[]`.
- Compiled child model persisted as a derived-only, fixed-vocabulary, non-PII Firestore doc keyed by uid.
- Selection intelligence: history-aware agent pick, remediation arc (sketch 001), just-this-part micro-drills (sketch 002), anti-boredom rule, teacher-justification line.
- Cross-letter DATA model: letters+criteria labels on every exercise, per-letter×criterion evidence (including from word/sentence attempts), letter-agnostic compiler + planning.
- A SMALL set of new mother-signed micro-exercises (provisional → sign-off pattern).
- Eval: selection-policy dimension on the 16-03 harness + property tests for the rails.
- Closing the cost/latency open research question with measured numbers.

**Out of scope (from SPEC.md):**
- Cross-letter selection POLICIES (spaced review, interleaving, transfer coaching) — Phase 19.
- Authoring/signing the remaining ~26 letters' content — parallel workstream, never a Phase-18 gate.
- Any change to verdict authority — the on-device scorer owns pass/fail (D-A, ADR-017).
- Voice/UX redesign; any new child PII; parent-account surface changes.

</spec_lock>

<decisions>
## Implementation Decisions

### Remediation arc experience (sketch 001 verdict recorded)
- **D-01: Sketch 001 verdict = Variant C, "The Teacher's Margin."** A dedicated
  teacher's-margin panel narrates the arc alongside the canvas — pairs with the 17.2
  Teacher's Eye strip and carries the justification line.
- **D-02: Arc entry trigger = same-criterion fail streak.** Two consecutive fails on the
  SAME criterion enter the arc — one mechanism drives both the arc and the anti-boredom
  rule, straight off the per-criterion verdicts already in `TutorFacts`. The threshold
  number ships provisional (`signed:false` pattern) until the mother signs.
- **D-03: Step-down framing = warm and named.** The tutor names the move without shame
  ("Let's practice just the dot for a moment — then we'll come back"). Never fake cheer,
  never hide the move. Exact copy is provisional until mother sign-off; the NAMED structure
  is locked.
- **D-04: Arc exit = retry the ORIGINAL failed exercise.** The clean win that exits the arc
  is on the exercise that started it. If even the arc's floor step fails, land on a
  guaranteed-doable success (e.g. trace) and end the arc warm — never an endless loop.

### Micro-drill design (sketch 002 verdict recorded)
- **D-05: Sketch 002 verdict = Variant B, "Spotlight."** The full letter stays visible;
  the failing criterion's zone is lit and everything else dims. The child still WRITES —
  the existing canvas/scorer path carries the drill (no new interaction paradigm).
- **D-06: Micro-drills are REAL graph nodes.** New `microDrill` exercise type authored in
  `assets/curriculum/exercises.json` + criterion-tagged nodes in the curriculum graph,
  enrichment-style (never gate the star). `isLegalSelection` and G5/G6 cover them with
  zero rail changes; the mother signs them like any node.
- **D-07: Initial drill set = baa's 3 named criteria** — dot placement, bowl depth/shape,
  start point (~3–5 drills). Small enough to sign in one sitting; ships `signed:false`
  until she flips it. This is the one pedagogy ask — schedule it early.
- **D-08: Drill scoring — the target criterion owns the verdict.** The drill passes when
  the spotlighted criterion passes; the other 4 criteria are RECORDED as evidence but
  cannot fail the drill. A dot drill never fails for a shaky bowl.

### Selection brain placement
- **D-09: Policy narrows, agent picks.** A pure-Dart policy layer computes the arc state +
  the legal candidate set (anti-boredom filter, drill injection, arc-step constraints) and
  sends THAT to the agent; the agent picks among policy-legal candidates and voices why.
  Deterministic acceptance tests pass by construction; the 17.2 "coach proposes" story
  survives; the trust boundary is unchanged (agent stays untrusted, client + server
  legality enforcement exactly as today).
- **D-10: Justification line = LLM online, authored-template floor offline.** Online the
  coach LLM phrases the WHY from policy facts (criterion, arc step); offline a small
  authored template set fills the same slot deterministically — the existing
  `AuthoredFallback` degradation axis, extended to the WHY line.
- **D-11: FULL offline parity for the new intelligence.** The walker consumes the same
  pure-Dart policy layer: airplane-mode children get arcs, anti-boredom, and micro-drills
  with templated lines. (SPEC only demands no-regression; parity is the owner's call —
  the child model is most valuable exactly where the brain isn't.)
- **D-12: Arc state persists to Drift.** Arc step, target criterion, and the
  exercise-to-retry join the graph-position cursor (same DYN-02 resume pattern as
  Phase 15). A restart mid-arc resumes the arc.

### Child-model data plumbing
- **D-13: Evidence is written SERVER-SIDE ONLY, at /coach time.** The Cloud Run server
  appends per-letter×criterion evidence rows via the Admin SDK from the `TutorFacts` it
  already receives. Firestore client-write rules stay deny-all — ZERO new client-write
  surface (the Phase-06.1 child-safety posture holds).
- **D-14: Offline evidence backfills through the wire.** Offline attempts accumulate in
  Drift; the next ONLINE session's facts carry a compact, fixed-vocabulary digest of
  unsynced evidence (letter×criterion pass/fail counts), and the server writes it.
  Evidence arrives late; the client never writes Firestore. One new wire field —
  guard-tested on both sides (422 lockstep discipline, server ships first).
- **D-15: KT model = per-criterion EMA.** Exponential moving average of pass/fail per
  letter×criterion with one α knob. Trivially mirrored pure-Dart/Python, explainable to
  the mother in one sentence ("recent attempts count more"). No BKT — calibration data
  for guess/slip parameters doesn't exist yet.
- **D-16: Profile read = local Drift mirror at boot, background refresh.** The compiled
  profile is mirrored into Drift whenever fetched; session boot reads the mirror
  instantly and a background one-shot Firestore `.get()` refreshes it. Offline boots get
  the last-known profile. Same Firestore-first-with-fallback idiom as
  CurriculumRepository (06.1-04). The practice path never blocks (Req 6).

### Claude's Discretion
- Candidate-set size/shape sent to the agent; pick precompute timing within the feedback
  moment (SPEC constraint: no perceptible selection latency).
- The wire digest's exact field shape (fixed-vocabulary, non-PII — GROUND-04 discipline).
- On-device evidence retention/rollup (cap growth on the tablet).
- Spotlight-zone authoring format per criterion (how a drill names its lit region).
- Provisional α value for the EMA; provisional arc-N; provisional eval threshold —
  all `signed:false` until the mother signs (Phase 15/17 pattern).
- Nightly job shape: Cloud Run job vs scheduled Function (SPEC explicitly delegates to
  planner); evidence collection layout in Firestore; compiler scheduling details.
- Eval harness extension mechanics (scenario file format, judge prompt); property-test
  generator design; Riverpod wiring; Drift schema details.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 18 spec + intent
- `.planning/phases/18-build-the-living-tutor-dynamic-exercise-selection/18-SPEC.md` —
  Locked requirements — MUST read before planning (9 requirements, boundaries, acceptance criteria).
- `.planning/PHASE-18-BRIEF.md` — the owner's intent brief (research pointers, inputs/dependencies).
- `.planning/sketches/001-remediation-arc/index.html` — the arc's target experience;
  **verdict recorded: Variant C "The Teacher's Margin" (D-01).**
- `.planning/sketches/002-just-this-part/index.html` — the micro-drill target experience;
  **verdict recorded: Variant B "Spotlight" (D-05).**

### The locked tutor spine (do NOT relitigate)
- `docs/architecture/ADR-017-scorer-owns-verdict-derived-facts.md` — scorer owns pass/fail;
  only derived facts cross the wire (GROUND-04). Evidence/digest fields must obey it.
- `docs/architecture/ADR-014-v2-tutor-agent-architecture.md` — grounding invariant: agent
  owns only words + sequence, never verdicts/mastery.
- `docs/architecture/ADR-015-v2-tutor-server-langgraph-agent.md` — server topology the
  evidence capture + nightly compiler attach to.
- `docs/curriculum/national-curriculum-grade1.md` — the curriculum ground truth behind the
  graph; micro-drill nodes must stay consistent with it.

### Code seams to extend (client)
- `lib/tutor/exercise_selector_provider.dart` — `RouterExerciseSelector` (agent pick
  accepted only when graph-legal) — the seam the policy layer wraps (D-09).
- `lib/curriculum/curriculum_graph_walker.dart` + `lib/curriculum/curriculum_graph.dart` —
  the offline walker + `isLegalSelection`; consumes the shared policy layer (D-11).
- `lib/tutor/tutor_facts.dart` + `lib/tutor/tutor_facts_builder.dart` — session-scoped
  `struggleTags`/`strengthTags`/`trajectory`/`criteria`/`weakestCriterion` already exist;
  gains compiled-profile fields + the offline-evidence digest (D-14, Req 2).
- `lib/data/app_database.dart` — Drift home for evidence rows, arc state (D-12), and the
  profile mirror (D-16); 6 tables today, `LetterGraphPosition`/`LetterExerciseReps` are the
  resume-pattern precedents.
- `assets/curriculum/curriculum_graph.json` + `assets/curriculum/exercises.json` — where
  `microDrill` nodes are authored (D-06); letters+criteria labels land here (Req 7).

### Code seams to extend (server)
- `server/app/nodes/plan.py` + `server/app/curriculum.py` — G5/G6 rails; candidate-set
  handling for the policy-narrowed set (D-09).
- `server/app/schema.py` — `TutorFactsIn` gains profile + digest fields (extra=forbid,
  422 lockstep: server ships FIRST).
- `server/app/curriculum_data/generate.py` — derive-from-assets pattern; extends to
  micro-drill nodes + criteria labels.
- `server/tests/test_eval/run_eval.py` + `server/tests/test_eval/gold_set.jsonl` — the
  16-03 harness gaining the selection-policy dimension (Req 9).
- `firestore.rules` — currently deny-all client writes; STAYS deny-all (D-13) — the
  nightly job + evidence capture use the Admin SDK server-side.

### Prior phase context (decisions carried forward)
- `.planning/phases/17-build-stroke-aware-coaching-on-device-geo-diff-to-coach/17-CONTEXT.md` —
  D-A scorer authority, per-criterion verdicts, D-D thresholds-as-data.
- `.planning/phases/15-build-dynamic-grounded-exercise-selection-on-baa/15-CONTEXT.md` —
  graph rails, walker, resume pattern, sign-off gate pattern.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`TutorFacts` / `tutor_facts_builder.dart`**: already carries session-scoped
  `struggleTags`/`strengthTags`, `trajectory` (List<AttemptFact>), `criteria`,
  `weakestCriterion`, `legalNextExerciseIds` — the within-session half of the two-timescale
  model largely exists as wire plumbing; Phase 18 makes selection consume it and adds the
  persistent half.
- **`RouterExerciseSelector` + `CurriculumGraphWalker`**: the accept-if-legal/degrade
  pattern the policy layer slots into — policy computes candidates, both selectors consume.
- **Drift resume pattern (`LetterGraphPosition`, `LetterExerciseReps`)**: the exact shape
  for arc-state persistence (D-12) and the profile mirror (D-16).
- **`AuthoredFallback` + always-speak rail (17.2)**: the degradation axis the templated
  justification line (D-10) extends.
- **Teacher's Eye strip (17.2)**: the demo surface the Teacher's Margin (D-01) builds on.
- **`generate.py` derive-from-assets pattern**: extends to micro-drill nodes and
  letters+criteria labels — server copy can never drift from the signed asset.
- **16-03 eval harness (`run_eval.py`, `make eval`)**: the selection-policy dimension
  lands as a 5th dimension, same gold-set + judge machinery.
- **Calibration-harness style (`test/core/scoring/calibration_harness_test.dart`)**: the
  per-letter×form test shape Req 3's micro-drill acceptance mirrors.

### Established Patterns
- **Scorer owns verdicts (ADR-017)**: micro-drill scoring (D-08) is a scorer-side pass
  rule, never an agent call.
- **Non-PII fixed-vocabulary wire (GROUND-04)**: profile fields + evidence digest must be
  key-name-guarded like `criteria`/`strokeDiff` were (17-05 precedent: guard KEY names,
  extra=forbid is the real teeth).
- **422 lockstep**: any new wire field ships server-first (additive, defaulted), client
  mirror second — zero 422 window.
- **Provisional → mother-signs**: `signed:false` content/values flip only behind
  HUMAN-UAT (15-07, 17-10 precedent). Applies to drills, arc-N, framing copy, α, eval
  threshold.
- **Anti-gamification**: drills and arcs produce no new reward surfaces; the one quiet
  star's mastery condition is untouched (enrichment nodes never gate it).

### Integration Points
- Policy layer (new, pure Dart) → both `RouterExerciseSelector` (online candidates) and
  `CurriculumGraphWalker` (offline picks).
- `TutorFacts` → server `/coach` → Admin-SDK evidence append (D-13) → nightly Python
  compiler → profile doc keyed by uid → boot fetch → Drift mirror (D-16) → next session's
  facts + first pick (Req 2).
- Offline Drift evidence → next-online-session digest field → server backfill (D-14).
- Micro-drill nodes (assets) → `generate.py` → server graph copy → G5/G6 legality covers
  drills with no rail change (D-06).

</code_context>

<specifics>
## Specific Ideas

- The Teacher's Margin panel is where the arc narration and the WHY line live — it should
  read like a teacher's pencil notes in a workbook margin, consistent with the 17.2
  Teacher's Eye strip (which was demo tooling; the margin is child-facing).
- Step-down line register: "Let's practice just the dot for a moment — then we'll come
  back." Honest, warm, names the move — never "oops, too hard for you."
- The arc's emotional contract: the child always ends an arc on a win — the original
  exercise if possible, a guaranteed-doable success if not.
- A dot drill never fails for a shaky bowl — "just this part" means the verdict is about
  exactly that part.

</specifics>

<deferred>
## Deferred Ideas

- **Cross-letter selection policies** (spaced review, interleaving, transfer coaching) —
  Phase 19, thin by construction over Phase 18's data.
- **Session-aware arc exit** (retry-if-energy-allows) — needs a session-clock notion that
  doesn't exist; revisit if a future phase adds session pacing.
- **BKT or richer KT models** — revisit once real calibration data accumulates from the
  evidence store; EMA is the deliberate v1.
- **Parent dashboard surfacing of strengths/struggles** — the compiled profile is
  parent-visible material eventually; out of this phase's scope (no parent-surface changes).

None of the discussion left phase scope otherwise.

</deferred>

---

*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Context gathered: 2026-07-10*
