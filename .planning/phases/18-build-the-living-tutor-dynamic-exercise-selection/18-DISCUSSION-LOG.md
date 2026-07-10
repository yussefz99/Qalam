# Phase 18: The Living Tutor — per-child dynamic exercise selection - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-10
**Phase:** 18-build-the-living-tutor-dynamic-exercise-selection
**Areas discussed:** Remediation arc experience, Micro-drill design, Selection brain placement, Child-model data plumbing

---

## Remediation arc experience

| Option | Description | Selected |
|--------|-------------|----------|
| A: The Lean-In | Arc plays out in place on the existing exercise surface, minimal new chrome | |
| B: Ink-First | Ink/canvas stays the hero; arc communicated through the writing surface | |
| C: The Teacher's Margin | Dedicated margin panel narrates the arc alongside the canvas | ✓ |
| Blend / re-sketch first | Mixed verdict or iterate before locking | |

**User's choice:** C: The Teacher's Margin (sketch 001 verdict recorded)

| Option | Description | Selected |
|--------|-------------|----------|
| Same-criterion fail streak | 2 consecutive fails on the SAME criterion enters the arc | ✓ |
| Any fail streak on the exercise | 2 consecutive fails regardless of criterion | |
| KT mastery-estimate drop | Enter when mastery estimate falls below a band | |

**User's choice:** Same-criterion fail streak (recommended option)
**Notes:** Threshold number stays provisional until the mother signs; the SHAPE is locked.

| Option | Description | Selected |
|--------|-------------|----------|
| Warm and named | Tutor names the step-down without shame | ✓ |
| Invisible reframe | Step-down presented as 'quick practice' with no acknowledgment | |
| Structure ours, wording hers | Named-move structure with framing on the mother's sign-off sheet | |

**User's choice:** Warm and named (recommended option)

| Option | Description | Selected |
|--------|-------------|----------|
| Retry the failed exercise | Arc exits on a clean win on the ORIGINAL exercise; floor-fail ends warm on a doable success | ✓ |
| Win anywhere exits | Any clean win at the rebuilt level exits | |
| Session-aware exit | Retry only if session energy allows (needs a session clock — new scope) | |

**User's choice:** Retry the failed exercise (recommended option)

---

## Micro-drill design

| Option | Description | Selected |
|--------|-------------|----------|
| A: Camera Zoom | Canvas zooms into the criterion's region | |
| B: Spotlight | Full letter visible, criterion zone lit, rest dims — child still writes | ✓ |
| C: Three-Pearl Drill | Dedicated tap-placement mini-exercise | |
| Blend / re-sketch first | Mixed verdict or iterate | |

**User's choice:** B: Spotlight (sketch 002 verdict recorded)

| Option | Description | Selected |
|--------|-------------|----------|
| Real graph nodes | New microDrill type + criterion-tagged graph nodes, enrichment-style | ✓ |
| Criterion-keyed side pool | Drills outside the graph with a special legality case | |
| Overlay on existing nodes | Spotlight flag on existing trace/write nodes, no new content | |

**User's choice:** Real graph nodes (recommended option)

| Option | Description | Selected |
|--------|-------------|----------|
| Baa's 3 named criteria | Dot placement, bowl depth/shape, start point (~3-5 drills) | ✓ |
| Dot-only first | Smallest possible sign-off ask | |
| Baa + alif coverage | ~6-8 drills, proves letter-agnostic schema with real content | |

**User's choice:** Baa's 3 named criteria (recommended option)

| Option | Description | Selected |
|--------|-------------|----------|
| Target criterion owns it | Drill passes when the spotlighted criterion passes; others record evidence only | ✓ |
| Target strict, rest loose | All 5 gate with asymmetric bands | |
| Standard full verdict | Same pass rule as any exercise | |

**User's choice:** Target criterion owns it (recommended option)

---

## Selection brain placement

| Option | Description | Selected |
|--------|-------------|----------|
| Policy narrows, agent picks | Pure-Dart policy computes arc state + legal candidate set; agent picks among them and voices why | ✓ |
| Policy picks, agent voices | Policy fully decides; LLM only phrases | |
| Agent picks, policy vetoes | Agent proposes as today; new history-aware veto degrades bad picks | |

**User's choice:** Policy narrows, agent picks (recommended option)

| Option | Description | Selected |
|--------|-------------|----------|
| LLM online, template floor | Coach LLM phrases the WHY online; authored templates offline | ✓ |
| Template everywhere | Deterministic templates online AND offline | |
| LLM only | No justification offline | |

**User's choice:** LLM online, template floor (recommended option)

| Option | Description | Selected |
|--------|-------------|----------|
| Full parity | Walker consumes the same policy layer — offline gets arcs, anti-boredom, drills | ✓ |
| No-regression only | New intelligence online-only this phase | |
| Partial: anti-boredom only | Offline gets only the anti-boredom filter | |

**User's choice:** Full parity (recommended option)

| Option | Description | Selected |
|--------|-------------|----------|
| Persist to Drift | Arc state joins the graph-position cursor (DYN-02 resume pattern) | ✓ |
| Session-only | Arc resets on restart; evidence re-triggers if the struggle persists | |

**User's choice:** Persist to Drift (recommended option)

---

## Child-model data plumbing

| Option | Description | Selected |
|--------|-------------|----------|
| Drift-first, deferred sync | Client uploads aggregates to a uid-scoped collection (opens first client-write rule) | |
| Server captures at /coach time | Cloud Run appends evidence via Admin SDK from TutorFacts; zero new client-write surface | ✓ |
| Compile on-device, upload profile only | Nightly compile in Dart on the tablet | |

**User's choice:** Server captures at /coach time — NOT the recommended option; the owner
prioritized keeping Firestore client-write rules deny-all (the Phase-06.1 child-safety
posture) over the offline-evidence gap, which the follow-up question then closed.

| Option | Description | Selected |
|--------|-------------|----------|
| Backfill through the wire | Offline evidence accumulates in Drift; next online session's facts carry a digest; server writes it | ✓ |
| Drop offline evidence | Across-session memory reflects online sessions only | |
| Within-session Drift covers it | Keep all history on-device; cloud profile only for the agent prompt | |

**User's choice:** Backfill through the wire (recommended option)

| Option | Description | Selected |
|--------|-------------|----------|
| Per-criterion EMA | One α knob, ~15 lines per language, explainable in one sentence | ✓ |
| BKT-lite | Principled learn-probability semantics; needs calibration data that doesn't exist | |
| Let research decide | Defer the call to the phase researcher | |

**User's choice:** Per-criterion EMA (recommended option)

| Option | Description | Selected |
|--------|-------------|----------|
| Local mirror, background refresh | Boot reads the Drift mirror instantly; background Firestore .get() refreshes | ✓ |
| Firestore read with timeout | Every boot pays a network wait | |
| Server injects it | Client never reads the profile; server merges at /coach time | |

**User's choice:** Local mirror, background refresh (recommended option)

---

## Claude's Discretion

- Candidate-set size/shape sent to the agent; pick precompute timing within the feedback moment
- Wire digest exact field shape (fixed-vocabulary, non-PII)
- On-device evidence retention/rollup
- Spotlight-zone authoring format per criterion
- Provisional α / arc-N / eval threshold values (all signed:false until mother signs)
- Nightly job shape (SPEC delegates to planner); Firestore evidence layout; compiler scheduling
- Eval harness extension mechanics; property-test generator design; Riverpod wiring; Drift schema details

## Deferred Ideas

- Cross-letter selection policies — Phase 19 (already SPEC-scoped out)
- Session-aware arc exit — needs a session-clock notion that doesn't exist yet
- BKT / richer KT models — revisit once real calibration data accumulates
- Parent dashboard surfacing of strengths/struggles — future phase (no parent-surface changes now)
