# Phase 18 Brief — The Living Tutor (per-child dynamic selection)

> Prep artifact written 2026-07-10 for the add-phase → spec-phase → discuss-phase flow.
> Owner intent: this is the most important phase in the app — turn each child's session
> into a dynamic, per-child experience where the AI picks the next exercise like a real
> teacher would. Consume this brief as the owner's opening answer to the spec interview.

## Why now / what triggers this

Phases 15 + 17 + 17.2 built the plumbing: a signed per-letter curriculum graph (baa),
a deterministic offline walker, an agent that picks from graph-legal candidates, and a
coach that announces its pick. Phase 17 gave the scorer per-criterion verdicts with a
`weakest` target. But the experience still doesn't FEEL dynamic, because:

1. **The AI has no model of the child.** It sees only this attempt's facts — not that
   this child always fails the dot, not what happened last session, not that she's been
   struggling for 10 minutes. The Decided two-timescale adaptation (within-session
   history + nightly `strengths[]`/`struggles[]` compile) was never built.
2. **Remediation is a rule, not an experience.** Fail → "one tier down" is mechanical.
   Sketches 001 (The Remediation Arc) and 002 (Just This Part — the dot desk) in
   `.planning/sketches/` show the intended experience: a deliberate confidence-rebuilding
   arc, and micro-drills that isolate the failing criterion.

## Goal (one sentence)

Every "next exercise" pick is a deliberate, explainable teaching move informed by a
persistent model of THIS child — targeting the weakest criterion, building remediation
arcs back to confidence — while staying railed to the signed curriculum graph.

## In scope

1. **Child model — two-timescale (the Decided architecture, finally built):**
   - Within-session: attempt history with per-criterion verdicts available to the
     selection brain (session memory).
   - Across-session: nightly compile of per-child `strengths[]` / `struggles[]`
     (Python — Cloud Run job or Cloud Function, per stack decision), persisted and
     fed into the next session's facts.
   - Wire discipline unchanged: only derived, fixed-vocabulary, non-PII facts cross
     (GROUND-04 / ADR-017). Raw strokes and PII never leave the device.
2. **Selection intelligence:**
   - Agent pick informed by child model + criterion history, not just this attempt.
   - **Remediation arc** (sketch 001): a fail streak triggers a deliberate arc —
     step down, rebuild, retry — not a single mechanical tier-down.
   - **Just-this-part micro-drills** (sketch 002): target the weakest criterion
     (dot placement, bowl depth, start point) with small isolated exercises.
     ⚠ Needs a SMALL set of new authored micro-exercises → mother's sign-off.
     This is the one pedagogy ask — schedule it early.
   - Anti-boredom rule: a child never sees the identical exercise a third time on
     the same failure; the tutor line says WHY it picked (teacher justification —
     builds on the 17.2 Teacher's Eye strip).
3. **Cross-letter data model from day one (owner decision, 2026-07-10):**
   - Every exercise is labeled with the letters AND criteria/skills it touches.
     Word/sentence exercises credit EVERY letter in the word — a writeWord attempt
     for the baa unit also records evidence for alif, lam, etc. Today that signal
     is discarded; stop discarding it.
   - Child evidence stored per letter × criterion; the nightly compiler aggregates
     across ALL letters the child has ever touched; next-session ("next day") unit
     planning is letter-agnostic by construction.
   - The SCHEMA is all-letters; the shipped CONTENT is whatever is signed (baa,
     alif today). Acceptance: adding a newly signed letter requires ZERO schema
     change — proven by a second-letter test fixture.
4. **Eval:** extend the Phase-16 eval harness with a selection-policy dimension
   ("would a teacher make this pick?") over gold scenarios, plus deterministic
   property tests for the rails.

## Out of scope (explicit)

- Cross-letter selection POLICIES — spaced review, interleaving, transfer coaching
  ("the bowl in taa is the bowl from baa") — Phase 19. These are pedagogy calls
  (mother's domain) and only meaningful once several letters have signed content.
  NOTE the split (owner decision 2026-07-10): the cross-letter DATA model IS in
  scope (see In scope #3); only the cross-letter selection policies defer. Phase 19
  becomes thin — switching policies on over data Phase 18 already captures.
- Authoring/signing the remaining ~26 letters' exercises + graphs — a PARALLEL
  content workstream (model drafts, mother reviews + signs, per the standing
  curriculum-drafting strategy), never a Phase-18 gate. Each letter she signs
  immediately enriches the already-running child model.
- Any change to verdict authority: the on-device scorer OWNS pass/fail (D-A, ADR-017).
- Voice/UX redesign; new child PII of any kind; changes to the parent-account surface.

## Constraints

- **Child safety:** child model = minimal derived data, on-device/private by default,
  parent-controlled. The nightly compiler works on non-PII aggregates only.
- **Cost + latency:** this phase must CLOSE the open research question (calls per
  session, prompt caching, acceptable delay). Selection must add no perceptible
  latency — pick during the feedback moment / precompute candidates.
- **Offline floor:** the walker remains the offline selector; the app never blocks
  on the brain (existing degradation axis preserved).
- **Trust boundary:** agent stays untrusted; graph-legality enforced client-side
  (isLegalSelection) and server-side (G5/G6) exactly as today.

## Acceptance criteria (falsifiable — candidate requirement seeds)

- A child failing the same criterion twice gets a DIFFERENT, targeted next exercise
  (never an identical third repeat). [anti-boredom]
- A returning child's first pick/tutor line demonstrably reflects the previous
  session (a stored struggle or strength is referenced). [across-session memory]
- The dominant failing criterion triggers its micro-drill, verified per letter×form
  in the calibration-harness style. [just-this-part]
- 100% of agent picks are graph-legal under property testing; illegal proposals
  degrade to the walker. [rails hold]
- Selection-policy eval dimension ≥ agreed threshold on a gold scenario set signed
  by the mother. [eval gate]
- Airplane-mode session is still coherent via the walker — no hang, no dead end.
- A struggling child reaches a clean win within N attempts via the remediation arc
  (N is the mother's number, not ours).
- A word/sentence attempt records evidence for EVERY letter it touches, not only
  the unit's letter. [cross-letter capture]
- The nightly compile emits strengths/struggles spanning all letters with evidence;
  a second-letter fixture proves a newly signed letter needs zero schema change.
  [letter-agnostic by construction]

## Inputs & dependencies

- Phase 15: curriculum graph, walker, RouterExerciseSelector, G5/G6 rails.
- Phase 17: LetterScore criteria + `weakest`; ADR-017 trust boundary.
- Phase 17.2 (branch `gsd/phase-17.2-demo-extras`): graph-legal candidates over the
  wire, coach proposes+announces, Teacher's Eye strip. **Merge to main before
  branching phase-18.**
- Phase 16 eval harness (16-03) for the new selection dimension.
- Sketches: `.planning/sketches/001-remediation-arc/`, `.planning/sketches/002-just-this-part/`
  (currently untracked — fold in and record verdicts via /gsd:sketch).
- Mother (pedagogy authority): micro-drill content, remediation-arc shape, N.

## Research pointers (for discuss/plan researchers)

- Lightweight knowledge tracing: per-criterion mastery estimate (EMA or BKT-lite)
  is sufficient — no deep-learning KT; must run in pure Dart on-device and mirror
  in Python for the nightly compile.
- Prompt caching + per-pick token budget on Vertex (keyless, Technion credits).
- Nightly job shape: Cloud Run job vs scheduled Function; where the compiled
  profile lives (Firestore doc keyed by uid? on-device only?) — child-safety first.
