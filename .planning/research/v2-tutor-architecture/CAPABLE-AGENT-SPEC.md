# Capable-Agent Capability Spec — the corrected premise

> **Why this exists:** ADR-014 chose client-only partly because it assumed the agent's job was
> tiny ("emit one coaching line + pick the next exercise"). The owner has corrected that: the
> tutor must be a genuine reasoning agent. This spec pins what the agent must *do*, so the
> topology re-evaluation (client-side vs server+framework) is judged against the real workload.
> Owner direction, 2026-06-22: "capable slice for the demo, architected for the full vision."

## What the agent must DO (demo target — baa)

1. **Analyze the child's scored attempts.** Not just the last `mistakeId` — the *trajectory*:
   which strokes failed, across the session, repetition/pattern (e.g. "over-curved the boat on
   3 of the last 4 tries; dot misplaced twice"). Input is the deterministic scorer's structured
   results, never the raw geometry re-judged.
2. **Build within-session insight.** Maintain a running learner model for the session — emerging
   struggle/strength tags derived from the attempt analysis (e.g. `struggles:[boat-curvature]`).
3. **Plan, not just react.** Decide a short sequence, not a single line: e.g. "drill the boat
   curve in isolation → re-test the whole baa → if clean, advance; if the dot is the problem,
   switch to the dot-placement exercise." Choose the next exercise from baa's authored configs
   based on the insight, and decide hint-vs-advance.
4. **Coach** with warm, specific, grounded lines that reflect the analysis (the owner's-mother
   voice), pitched to a 5–10-year-old.
5. **Degrade gracefully.** Offline / no model → the AuthoredFallback floor still coaches and the
   loop never blocks.

## Architected-for (NOT built for the demo, but the design must not preclude)

- **Cross-session insight** — persist the learner model across sessions (the deferred "nightly
  profile compiler"; needs durable per-child storage and possibly a server).
- **Multi-unit planning** — sequence across letters/families, not just within baa.
- **Richer memory / retrieval** — longer histories, possibly retrieval over past sessions.

## The invariant that holds at every capability level (non-negotiable)

- **The deterministic scorer owns pass/fail + the mastery star.** The agent analyzes the
  *scored* attempts and decides what to teach/say/sequence — it never re-judges the handwriting
  and can never flip a fail to a pass. This is what makes a *more capable* agent *trustworthy*,
  not less — its insight sits on top of ground truth.
- **Only derived, non-PII facts** ever cross any process/network boundary — never raw strokes,
  never nickname/PII — no matter where the agent runs.

## What this premise changes vs ADR-014

- The "agent's job is tiny → no orchestration/memory/planning needed" argument is **void**. A
  planning agent with a session (and later cross-session) learner model is exactly the workload
  agent frameworks and/or a server are built for.
- So the topology question genuinely re-opens: **sophisticated client-side agent** (firebase_ai
  multi-turn function-calling + local Drift memory + Dart planning) **vs a thin server-side
  agent** (LangGraph / Google ADK / Genkit, or a small custom loop) over a **plain custom
  REST/SSE API** (NOT AG-UI — that conflation sank Path B unfairly last time). A server also
  re-opens **Claude server-side** (the original CLAUDE.md tutor vision), which the client-only
  constraint had ruled out.

## Seam implications (for re-planning Phase 14 after topology is decided)

- `TutorFacts` must carry the attempt **trajectory + session learner model**, not just the last
  `mistakeId`.
- `TutorDecision` must be able to express a **plan/sequence + memory update**, not only one of
  the 4 ACTION tools.
- A **learner-model store** (session-scoped now, durable later) is a first-class component.
- The Wave-1 work already built (`lib/tutor/` seam + AuthoredFallback + dispatcher) is the
  small-agent version — it is a starting point to reshape, not the final seam.
