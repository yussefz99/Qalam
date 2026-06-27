# Phase 15: BUILD — dynamic grounded exercise selection on baa - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-27
**Phase:** 15-build-dynamic-grounded-exercise-selection-on-baa
**Areas discussed:** Selection policy, Resume & mastery, Offline selection, Faithfulness measure, Curriculum graph artifact

**Mid-discussion input:** The owner supplied the official Israeli MoE grade-1 Arabic
curriculum (ref 1-08-2014). It was read, extracted into
`docs/curriculum/national-curriculum-grade1.md`, and used to ground the selection-policy and
mastery decisions. It is a language/reading competency curriculum (not stroke mechanics) — it
complements, not replaces, the owner-mother's hand-formation spec.

---

## Selection policy

| Option | Description | Selected |
|--------|-------------|----------|
| Curriculum-graph gated | Section order + difficulty tiers (منقول→منظور→غير منظور) as the rail; forward along the chain, free within tier, backward remediation | ✓ |
| Section-gated only | Gate by 6 sections, free within, no explicit per-exercise difficulty tiers | |
| Free within rails | Any of 19 configs any order, bounded only by membership + verdict lock | |

**User's choice:** Curriculum-graph gated (after explicit request to discuss it deeply — "I
don't think that question should be answered quickly"). Locked once the national curriculum
independently backed the prerequisite chain + supplied the difficulty lattice.
**Notes:** The "rails" go from membership-only to a curriculum-grounded prerequisite/difficulty
graph. Backward remediation is the primary visible dynamism for SC-1.

---

## Resume & mastery

| Option (Mastery) | Description | Selected |
|--------|-------------|----------|
| Essential-core cleared | 70% essential through mastery section, mom's clean-reps; enrichment optional; scorer-owned | ✓ |
| Flat clean-reps on core | A single clean-reps count on core formation exercises | |
| Full 19-config coverage | Every config passed cleanly | |

| Option (Resume) | Description | Selected |
|--------|-------------|----------|
| Graph position + replay trajectory | Persist cleared tiers to Drift + replay recent trajectory to the agent; survives restart | ✓ |
| Graph position only | Persist cleared tiers; agent re-reasons fresh | |
| In-memory only | Survives navigation, not app restart (today's behavior) | |

**User's choice:** Essential-core cleared + Graph position with trajectory replay.
**Notes:** Mastery stays scorer-owned (ADR-014). The 70/30 national split defines essential vs
enrichment. Resume state lives entirely on-device (stateless server).

---

## Offline selection

| Option | Description | Selected |
|--------|-------------|----------|
| Deterministic graph walk | Pure-Dart walk of the SAME graph (forward on pass, remediate on fail); AuthoredFallback lines | ✓ |
| Fixed section walk | Revert to old linear LetterUnitController walk offline | |
| Freeze on current exercise | Repeat current exercise until agent reachable | |

**User's choice:** Deterministic graph walk.
**Notes:** Makes the curriculum graph the single source of truth — agent-reasoned online,
deterministically walked offline. Offline floor stays grounded AND adaptive.

---

## Faithfulness measure

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal check here, seed for later | Narrow GROUND-03 slice (verdict-vs-coaching contradiction over a small labeled set); seeds Phase 13/16 | ✓ |
| Do Phase 13 first | Pause Phase 15, run the full eval harness + bake-off, then return | |
| Descope SC-4 to Phase 16 | Defer all faithfulness measurement | |

**User's choice:** Asked for Claude's recommendation; accepted "Minimal check here, seed for
later."
**Notes:** GROUND-03 is child-safety (never praise a failed stroke). SC-4's ask is narrow and
model-agnostic — buildable without mom and without pre-empting the Phase 13 Claude-vs-Gemini
choice. Flagged separately: Phases 12/13 spikes remain unrun and both 15 and 16 depend on them.

---

## Curriculum graph artifact

| Option (Home) | Description | Selected |
|--------|-------------|----------|
| Flutter assets + generate.py | Author in assets; generate.py derives server copy; Dart walker reads assets directly | ✓ |
| Server-authoritative + client cache | Graph server-side; client fetches/caches | |
| Duplicate + drift test | Author in both, test parity | |

| Option (Sign-off) | Description | Selected |
|--------|-------------|----------|
| Full graph, I draft → she reviews | Claude drafts all 19 configs; mom reviews/signs at tier level | ✓ |
| Structural only | Mom signs coarse structure; within-section tiers stay model-drafted | |

| Option (ta/tha) | Description | Selected |
|--------|-------------|----------|
| Reinforce baa's own dot only | Coaching reinforces baa's dot; no ta/tha; contrast deferred | ✓ |
| Allow ta/tha via authored lines | Mother-signed contrast lines only | |
| Allow free contrast | Agent generates contrasts freely | |

**User's choice:** Flutter assets + generate.py / Full graph I-draft-she-reviews / Reinforce
baa's own dot only.
**Notes:** Reuses the proven `AUTHORED_BAA_IDS` single-source pattern. The graph is new
curriculum data → owner-mother sign-off required before it ships.

---

## Claude's Discretion

- Curriculum-graph schema shape + the `generate.py` extension; Dart walker API + placement
  relative to the `TutorBrain`/`TutorDecision` seam; plan-node prompt thickening; Drift schema
  for resume position; labeled-set format/size for the faithfulness check; Riverpod wiring.

## Deferred Ideas

- Cross-letter ب/ت/ث contrast unit (future multi-letter phase).
- Roadmap-sequencing flag: Phases 12 (latency) + 13 (model bake-off) spikes unrun; both 15 and
  16 depend on them — decide before Phase 16.
- Broader national curriculum (grades 1–6, all domains) — future curriculum work.
