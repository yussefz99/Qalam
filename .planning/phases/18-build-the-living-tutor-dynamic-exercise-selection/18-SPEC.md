# Phase 18: The Living Tutor — per-child dynamic exercise selection — Specification

**Created:** 2026-07-10
**Ambiguity score:** 0.12 (gate: ≤ 0.20)
**Requirements:** 9 locked

## Goal

Every "next exercise" pick becomes a deliberate, explainable teaching move informed by a
persistent model of THIS child — targeting the weakest criterion, building remediation
arcs back to confidence — while staying railed to the signed curriculum graph.

## Background

Phases 15/16/17/17.2 built the plumbing this phase animates:

- **Selection rails exist:** signed baa curriculum graph (19 nodes), deterministic offline
  walker (`lib/curriculum/curriculum_graph_walker.dart`), `RouterExerciseSelector`
  (`lib/tutor/exercise_selector_provider.dart`) accepting the agent's pick only when
  graph-legal (`CurriculumGraph.isLegalSelection`), mirrored server-side by G5/G6.
  17.2 added graph-legal candidates over the wire, coach proposes + announces its pick,
  and the Teacher's Eye strip.
- **Per-criterion verdicts exist:** the on-device scorer OWNS pass/fail (D-A, ADR-017)
  and emits 5 criteria (strokeCount/strokeOrder/shape/direction/dot) with a
  `weakestCriterion` coaching target traveling point-free on the wire (GROUND-04).
- **Eval harness exists:** 16-03 `run_eval.py` + `gold_set.jsonl`, 4 dimensions, `make eval`.

**The delta:** the selection brain has NO model of the child — it sees only this attempt's
facts plus a session-scoped, section-level strengths/struggles list. The Decided
two-timescale adaptation (within-session history + nightly `strengths[]`/`struggles[]`
compile) was never built. Remediation is a mechanical one-tier-down rule. Per-criterion
verdicts drive coaching lines but NOT selection. Word/sentence attempts discard their
per-letter signal entirely. Sketches 001 (The Remediation Arc) and 002 (Just This Part)
in `.planning/sketches/` show the target experience.

**Precondition:** branch `gsd/phase-17.2-demo-extras` merged to `main` before the
phase-18 branch is cut.

## Requirements

1. **Anti-boredom + explainable pick**: A child failing the same criterion twice never
   sees the identical exercise a third time; the pick targets the failing criterion and
   the tutor line says WHY it picked.
   - Current: the walker's fail path is `remediateOneTier ?? drill-in-place` — nothing
     prevents an identical third repeat; the tutor line never justifies the pick.
   - Target: selection is attempt-history-aware; after two fails on the same criterion,
     the next pick is a different, criterion-targeted exercise with a teacher-justification
     line (builds on the 17.2 Teacher's Eye strip).
   - Acceptance: deterministic test simulating two identical failures asserts the third
     pick ≠ that exercise AND targets the failed criterion; a widget/unit test asserts the
     justification line is present and names the criterion.

2. **Across-session memory**: A returning child's first pick and tutor line demonstrably
   reflect the previous session.
   - Current: the brain sees only this attempt's facts + session-scoped section-level
     strengths/struggles; nothing persists across sessions.
   - Target: the next session's first `TutorFacts` include the compiled per-child
     `strengths[]`/`struggles[]` (fixed-vocabulary, non-PII); the first pick or tutor line
     references a stored struggle or strength.
   - Acceptance: fixture test — seed a compiled profile, boot a fresh session, assert the
     outgoing facts carry the profile fields and the first pick/line references them.

3. **Just-this-part micro-drills**: The dominant failing criterion triggers its
   micro-drill (sketch 002).
   - Current: no micro-drill exercise type exists; the smallest selectable unit is a full
     graph exercise node.
   - Target: a SMALL mother-authored set of micro-exercises isolating criteria (dot
     placement, bowl depth, start point); when a criterion dominates the fail history, its
     micro-drill is selected. Content ships `signed:false` (provisional) until the mother's
     sign-off flips it — the one pedagogy ask, scheduled early.
   - Acceptance: calibration-harness-style test per letter×form — a dominant failing
     criterion selects its micro-drill; the sign-off gate is recorded as HUMAN-UAT and the
     flip is the only content change.

4. **Remediation arc**: A fail streak triggers a deliberate confidence-rebuilding arc
   (sketch 001), not a single mechanical tier-down.
   - Current: fail → one tier down, once; no arc state, no rebuild/retry shape.
   - Target: a fail streak enters an arc — step down, rebuild, retry — and a struggling
     child reaches a clean win within N attempts (N is the mother's number; provisional
     value ships flagged until she signs).
   - Acceptance: simulated fail-streak scenario test reaches a clean win within N attempts
     via observable arc states; N is a named constant with a sign-off flag, not a magic number.

5. **Rails hold**: 100% of agent picks are graph-legal under property testing.
   - Current: `isLegalSelection` + G5/G6 exist, but no property tests cover the new
     history-aware selection intelligence.
   - Target: property tests generate arbitrary agent proposals/histories against the new
     selector; illegal proposals always degrade to the walker; trust boundary unchanged
     (agent untrusted, client + server enforcement exactly as today).
   - Acceptance: property test suite asserts zero illegal picks accepted across generated
     cases; degradation to walker asserted on every illegal proposal.

6. **Offline floor preserved**: An airplane-mode session stays coherent via the walker.
   - Current: the walker is the offline selector today; the new child-model plumbing must
     not regress it.
   - Target: airplane-mode session completes with no hang and no dead end; child-model
     reads/writes never block the practice path.
   - Acceptance: integration test with the brain unavailable completes a multi-exercise
     session via the walker; no selection call blocks on network.

7. **Cross-letter evidence from day one**: A word/sentence attempt records evidence for
   EVERY letter it touches (owner decision, 2026-07-10).
   - Current: word/sentence attempts produce a verdict for the exercise only; the
     per-letter signal is discarded.
   - Target: every exercise is labeled with the letters AND criteria it touches; an
     attempt writes evidence rows per letter×criterion for every letter in the word.
     Schema is all-letters by construction; shipped content is whatever is signed
     (baa, alif today).
   - Acceptance: word-attempt fixture asserts evidence recorded for every letter in the
     word, keyed letter×criterion.

8. **Nightly compiler over all letters**: A nightly Python job compiles the per-child model.
   - Current: no compiler, no per-child profile store.
   - Target: nightly Python job (Cloud Run job or scheduled Function — planner decides)
     aggregates evidence across ALL letters into derived-only `strengths[]`/`struggles[]`
     + per-criterion mastery estimates (EMA or BKT-lite; KT logic pure Dart on-device,
     mirrored in Python), persisted in a Firestore doc keyed by uid — fixed-vocabulary,
     non-PII fields only; the next session's facts read it.
   - Acceptance: compiler unit tests over multi-letter evidence fixtures; a second-letter
     fixture proves a newly signed letter needs ZERO schema change; a PII/token guard test
     over the profile doc schema (GROUND-04 discipline).

9. **Selection-policy eval dimension**: The 16-03 harness gains "would a teacher make
   this pick?".
   - Current: `run_eval.py` scores 4 dimensions; none evaluate selection.
   - Target: a selection-policy dimension scored over a gold scenario set signed by the
     mother; gate threshold agreed with her (provisional threshold ships flagged until
     signed); deterministic property tests for the rails complement the judged dimension.
   - Acceptance: `make eval` includes the new dimension and passes ≥ the threshold on the
     signed gold set; scenario set includes fail-streak, returning-child, and
     boredom-trap cases.

## Boundaries

**In scope:**
- Two-timescale child model: within-session per-criterion attempt history feeding
  selection + nightly Python compile of per-child `strengths[]`/`struggles[]`.
- Compiled child model persisted as a derived-only, fixed-vocabulary, non-PII Firestore
  doc keyed by uid (locked this spec).
- Selection intelligence: history-aware agent pick, remediation arc (sketch 001),
  just-this-part micro-drills (sketch 002), anti-boredom rule, teacher-justification line.
- Cross-letter DATA model: letters+criteria labels on every exercise, per-letter×criterion
  evidence (including from word/sentence attempts), letter-agnostic compiler + planning.
- A SMALL set of new mother-signed micro-exercises (provisional → sign-off pattern).
- Eval: selection-policy dimension on the 16-03 harness + property tests for the rails.
- Closing the cost/latency open research question (calls/session, prompt caching,
  acceptable delay) with measured numbers.

**Out of scope:**
- Cross-letter selection POLICIES — spaced review, interleaving, transfer coaching
  ("the bowl in taa is the bowl from baa") — Phase 19, which becomes thin because
  Phase 18 already captures the data.
- Authoring/signing the remaining ~26 letters' content — parallel workstream (model
  drafts, mother signs); NEVER a Phase-18 gate.
- Any change to verdict authority — the on-device scorer owns pass/fail (D-A, ADR-017).
- Voice/UX redesign; any new child PII; parent-account surface changes.

## Constraints

- **Child safety:** child model = minimal derived data, private by default,
  parent-controlled; the nightly compiler works on non-PII aggregates only; only derived,
  fixed-vocabulary facts cross the wire (GROUND-04 / ADR-017 unchanged).
- **Cost + latency:** this phase must CLOSE the open research question (calls per
  session, prompt caching, acceptable delay). Selection adds no perceptible latency —
  pick during the feedback moment / precompute candidates. Vertex keyless (Technion
  credits) unchanged.
- **Offline floor:** the walker remains the offline selector; the app never blocks on
  the brain (existing degradation axis preserved).
- **Trust boundary:** agent stays untrusted; graph-legality enforced client-side
  (`isLegalSelection`) and server-side (G5/G6) exactly as today.
- **Stack:** selection/knowledge-tracing logic pure Dart on-device, mirrored in Python
  for the nightly job; lightweight KT only (per-criterion EMA or BKT-lite), no
  deep-learning KT.

## Acceptance Criteria

- [ ] A child failing the same criterion twice gets a DIFFERENT, targeted next exercise —
      never an identical third repeat
- [ ] The tutor line states WHY the exercise was picked, naming the targeted criterion
- [ ] A returning child's first pick/tutor line demonstrably references a stored struggle
      or strength from the previous session
- [ ] The dominant failing criterion triggers its micro-drill, verified per letter×form in
      the calibration-harness style
- [ ] 100% of agent picks are graph-legal under property testing; illegal proposals
      degrade to the walker
- [ ] Selection-policy eval dimension ≥ agreed threshold on a mother-signed gold scenario
      set (`make eval` green)
- [ ] Airplane-mode session is coherent via the walker — no hang, no dead end
- [ ] A struggling child reaches a clean win within N attempts via the remediation arc
      (N provisional until the mother signs)
- [ ] A word/sentence attempt records evidence for EVERY letter it touches
      (letter×criterion keyed)
- [ ] Nightly compile emits strengths/struggles spanning all letters; a second-letter
      fixture proves a newly signed letter needs ZERO schema change
- [ ] The compiled profile doc contains only fixed-vocabulary, non-PII derived fields
      (guard test)
- [ ] The cost/latency research question is documented as CLOSED with measured
      calls/session, caching strategy, and selection-latency numbers

## Ambiguity Report

| Dimension          | Score | Min  | Status | Notes                                        |
|--------------------|-------|------|--------|----------------------------------------------|
| Goal Clarity       | 0.90  | 0.75 | ✓      | One-sentence goal + 9 falsifiable requirements |
| Boundary Clarity   | 0.92  | 0.70 | ✓      | Cross-letter resolved: DATA in, POLICY out   |
| Constraint Clarity | 0.82  | 0.65 | ✓      | Storage, stack, KT approach locked; job shape delegated to planner |
| Acceptance Criteria| 0.85  | 0.70 | ✓      | 12 pass/fail checks; N + threshold mother-parameterized via sign-off pattern |
| **Ambiguity**      | 0.12  | ≤0.20| ✓      |                                              |

## Interview Log

| Round | Perspective     | Question summary                                  | Decision locked                                                        |
|-------|-----------------|---------------------------------------------------|------------------------------------------------------------------------|
| 1     | Researcher      | What exists / what's the delta?                   | PHASE-18-BRIEF.md consumed as the owner's opening answer; codebase scout confirmed rails + criteria exist, child model does not |
| 2     | Boundary Keeper | Defer cross-letter to Phase 19?                   | Owner superseded the file brief with an authoritative inline version: cross-letter DATA model in scope from day one (labels, per-letter×criterion evidence, word attempts credit every letter); cross-letter selection POLICIES out → Phase 19 |
| 2     | Boundary Keeper | Where does the compiled child model live?         | Firestore doc keyed by uid, derived-only, fixed-vocabulary, non-PII; nightly Python compile (matches Decided two-timescale architecture) |
| 2     | Failure Analyst | How to handle mother-gated parameters (N, eval threshold, drill content)? | Provisional values/content ship `signed:false`; HUMAN-UAT sign-off flips them (Phase 15/17 pattern); micro-drill ask scheduled early |
| 3     | Seed Closer     | Gate passed at 0.12 — proceed?                    | Write SPEC.md                                                          |

---

*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Spec created: 2026-07-10*
*Next step: /gsd-discuss-phase 18 — implementation decisions (KT model choice, evidence schema, arc state machine, nightly job shape)*
