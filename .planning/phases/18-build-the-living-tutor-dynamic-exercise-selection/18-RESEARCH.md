# Phase 18: The Living Tutor — per-child dynamic exercise selection - Research

**Researched:** 2026-07-11
**Domain:** Two-timescale learner modeling · knowledge tracing (EMA) · nightly batch compile (Cloud Run/Firestore Admin SDK) · policy-narrowed agent selection · Vertex Gemini cost/latency · Drift schema evolution · Dart property testing
**Confidence:** HIGH (codebase seams verified by direct read; external claims cited/verified below; a handful of pedagogy/measurement items are correctly `[ASSUMED]` pending device measurement or mother sign-off)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Remediation arc experience (sketch 001 = Variant C "The Teacher's Margin")**
- **D-01:** Sketch 001 verdict = Variant C, "The Teacher's Margin." A dedicated teacher's-margin panel narrates the arc alongside the canvas — pairs with the 17.2 Teacher's Eye strip and carries the justification line.
- **D-02:** Arc entry trigger = same-criterion fail streak. Two consecutive fails on the SAME criterion enter the arc — one mechanism drives both the arc and the anti-boredom rule, off the per-criterion verdicts already in `TutorFacts`. The threshold number ships provisional (`signed:false`) until the mother signs.
- **D-03:** Step-down framing = warm and named. The tutor names the move without shame ("Let's practice just the dot for a moment — then we'll come back"). Exact copy is provisional until mother sign-off; the NAMED structure is locked.
- **D-04:** Arc exit = retry the ORIGINAL failed exercise. The clean win that exits the arc is on the exercise that started it. If even the arc's floor step fails, land on a guaranteed-doable success (e.g. trace) and end the arc warm — never an endless loop.

**Micro-drill design (sketch 002 = Variant B "Spotlight")**
- **D-05:** Sketch 002 verdict = Variant B, "Spotlight." The full letter stays visible; the failing criterion's zone is lit and everything else dims. The child still WRITES — the existing canvas/scorer path carries the drill (no new interaction paradigm).
- **D-06:** Micro-drills are REAL graph nodes. New `microDrill` exercise type authored in `assets/curriculum/exercises.json` + criterion-tagged nodes in the curriculum graph, enrichment-style (never gate the star). `isLegalSelection` and G5/G6 cover them with zero rail changes; the mother signs them like any node.
- **D-07:** Initial drill set = baa's 3 named criteria — dot placement, bowl depth/shape, start point (~3–5 drills). Ships `signed:false` until she flips it. The one pedagogy ask — schedule it early.
- **D-08:** Drill scoring — the target criterion owns the verdict. The drill passes when the spotlighted criterion passes; the other 4 criteria are RECORDED as evidence but cannot fail the drill. A dot drill never fails for a shaky bowl.

**Selection brain placement**
- **D-09:** Policy narrows, agent picks. A pure-Dart policy layer computes the arc state + the legal candidate set (anti-boredom filter, drill injection, arc-step constraints) and sends THAT to the agent; the agent picks among policy-legal candidates and voices why. Deterministic acceptance tests pass by construction; the trust boundary is unchanged (agent stays untrusted, client + server legality enforcement exactly as today).
- **D-10:** Justification line = LLM online, authored-template floor offline. Online the coach LLM phrases the WHY from policy facts; offline a small authored template set fills the same slot deterministically — the existing `AuthoredFallback` degradation axis extended to the WHY line.
- **D-11:** FULL offline parity for the new intelligence. The walker consumes the same pure-Dart policy layer: airplane-mode children get arcs, anti-boredom, and micro-drills with templated lines.
- **D-12:** Arc state persists to Drift. Arc step, target criterion, and the exercise-to-retry join the graph-position cursor (same DYN-02 resume pattern as Phase 15). A restart mid-arc resumes the arc.

**Child-model data plumbing**
- **D-13:** Evidence is written SERVER-SIDE ONLY, at /coach time. The Cloud Run server appends per-letter×criterion evidence rows via the Admin SDK from the `TutorFacts` it already receives. Firestore client-write rules stay deny-all — ZERO new client-write surface.
- **D-14:** Offline evidence backfills through the wire. Offline attempts accumulate in Drift; the next ONLINE session's facts carry a compact, fixed-vocabulary digest of unsynced evidence (letter×criterion pass/fail counts), and the server writes it. One new wire field — guard-tested both sides (422 lockstep, server ships first).
- **D-15:** KT model = per-criterion EMA. Exponential moving average of pass/fail per letter×criterion with one α knob. Trivially mirrored pure-Dart/Python, explainable in one sentence ("recent attempts count more"). No BKT.
- **D-16:** Profile read = local Drift mirror at boot, background refresh. The compiled profile is mirrored into Drift whenever fetched; session boot reads the mirror instantly and a background one-shot Firestore `.get()` refreshes it. Offline boots get the last-known profile. Same Firestore-first-with-fallback idiom as CurriculumRepository. The practice path never blocks (Req 6).

### Claude's Discretion
- Candidate-set size/shape sent to the agent; pick precompute timing within the feedback moment (no perceptible selection latency).
- The wire digest's exact field shape (fixed-vocabulary, non-PII — GROUND-04).
- On-device evidence retention/rollup (cap growth on the tablet).
- Spotlight-zone authoring format per criterion.
- Provisional α (EMA); provisional arc-N; provisional eval threshold — all `signed:false` until the mother signs.
- Nightly job shape: Cloud Run job vs scheduled Function; evidence-collection layout in Firestore; compiler scheduling details.
- Eval-harness extension mechanics; property-test generator design; Riverpod wiring; Drift schema details.

### Deferred Ideas (OUT OF SCOPE)
- Cross-letter selection POLICIES (spaced review, interleaving, transfer coaching) — Phase 19.
- Session-aware arc exit (retry-if-energy-allows) — needs a session clock that doesn't exist.
- BKT or richer KT models — revisit once real calibration data accumulates.
- Parent-dashboard surfacing of strengths/struggles — out of this phase (no parent-surface changes).
- Authoring/signing the remaining ~26 letters — parallel workstream, never a Phase-18 gate.
</user_constraints>

<phase_requirements>
## Phase Requirements

The authoritative set is the 9 locked requirements in `18-SPEC.md`. ROADMAP assigns no REQ-IDs to Phase 18; the requirements below are the SPEC's numbered list.

| ID | Description | Research Support |
|----|-------------|------------------|
| Req 1 | Anti-boredom + explainable pick (no identical 3rd repeat; line names WHY) | Pure-Dart policy layer over `TutorFacts.trajectory`+`weakestCriterion`; anti-boredom filter + D-02 fail-streak counter; justification via coach LLM (online) / authored template (offline). See Architecture Patterns §1–2. |
| Req 2 | Across-session memory (first pick/line reflects last session) | Profile doc keyed by uid → Drift mirror (D-16) → new `TutorFacts.profile` wire field (422 lockstep, server-first). See §Wire-Contract Evolution + §Firestore Layout. |
| Req 3 | Just-this-part micro-drills (dominant failing criterion → its drill) | New `microDrill` exercise type + criterion-tagged enrichment graph nodes (D-06); target-criterion-owns-verdict scoring (D-08); calibration-harness-style selection test. See §Micro-drills. |
| Req 4 | Remediation arc (fail streak → step-down/rebuild/retry, win within N) | Arc state machine in the pure-Dart policy layer; arc state persisted to Drift (D-12); Teacher's Margin panel (D-01). See Architecture §3 + §Drift Schema. |
| Req 5 | Rails hold (100% agent picks graph-legal under property testing) | `isLegalSelection`+G5/G6 unchanged; **seeded-random generative tests in plain flutter_test** (NOT glados — analyzer conflict, see §Don't Hand-Roll + §Property Testing). |
| Req 6 | Offline floor preserved (airplane-mode coherent via walker) | Policy layer is pure Dart consumed by both `RouterExerciseSelector` and `CurriculumGraphWalker`; profile read is non-blocking Drift mirror (D-16). |
| Req 7 | Cross-letter evidence from day one (word attempt credits every letter) | NEW `letters`+`criteria` labels on every exercise (none exist today); server writes per-letter×criterion evidence rows. **Open Q: word-attempt evidence granularity.** See §Cross-letter Evidence. |
| Req 8 | Nightly compiler over all letters (Python job → per-child profile doc) | **Cloud Run Job + Cloud Scheduler** (recommended) reusing the existing server image; EMA compile; PII/token guard test. See §Nightly Job + §EMA. |
| Req 9 | Selection-policy eval dimension ("would a teacher make this pick?") | 5th dimension on the 16-03 harness (`run_eval.py`) + a selection gold set; deterministic property tests complement the judged dimension. See §Validation Architecture. |
</phase_requirements>

## Summary

Phase 18 animates plumbing that already exists. The within-session half of the two-timescale
model is largely built: `TutorFacts` already carries `trajectory` (per-attempt records),
`weakestCriterion`, `criteria`, `struggleTags`/`strengthTags`, and `legalNextExerciseIds`; the
selection seam (`RouterExerciseSelector` accept-if-legal → `CurriculumGraphWalker` degrade) and the
graph-legality rails (client `isLegalSelection`, server G5/G6) are shipped and battle-tested. The
delta is a **persistent per-child model** and a **pure-Dart selection policy layer** that consumes
both timescales, plus the server/nightly plumbing to compile and persist the across-session half.

The architecture writes itself from the locked decisions: a **pure-Dart policy layer** (D-09/D-11)
computes arc state + the legal candidate set and slots *behind* the existing selectors so both the
online router and the offline walker share it. Evidence is written **server-side only** at /coach
time via the Admin SDK (D-13) — `firebase_admin` is already initialized with ADC in the deployed
server, so Firestore writes need **zero new packages**. A **nightly Python job** aggregates evidence
with a **per-criterion EMA** (D-15) into a derived-only, non-PII profile doc keyed by uid; the client
mirrors it into the account-scoped Drift DB at boot (D-16) and refreshes it with one background
`.get()`. Cost/latency closes favorably: **implicit context caching is on by default for Gemini 2.5
Flash on Vertex** (no code change) and the selection pick rides the *same* /coach round-trip the
17.2 work already added, so it adds no perceptible latency.

**Primary recommendation:** Build a pure-Dart `SelectionPolicy` (arc state machine + anti-boredom
filter + drill injection) that both selectors consume; write evidence server-side via the
already-initialized Admin SDK into an **append-only evidence subcollection** keyed by uid; run the
nightly compile as a **Cloud Run Job triggered by Cloud Scheduler** reusing the existing server
image; add **no new packages** — property tests are seeded-random plain `flutter_test` (glados is
Dart-3-incompatible and conflicts with analyzer 9). Ship the wire fields server-first (422 lockstep),
add one owner-read Firestore rule for the profile doc (writes stay Admin-only), and gate all
pedagogy values (`α`, arc-N, drill content, eval threshold) behind mother sign-off (`signed:false`).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Within-session per-criterion history → selection | Client (pure-Dart policy) | — | Already on-device in `TutorFacts.trajectory`; the policy layer reads it. Offline parity (D-11) demands pure Dart. |
| Selection policy (arc state, anti-boredom filter, drill injection, candidate narrowing) | Client (pure-Dart `SelectionPolicy`) | API (coach node picks among candidates, D-09) | Trust boundary unchanged: agent picks among *policy-legal* candidates; client re-checks legality. |
| Nightly compile of `strengths[]`/`struggles[]` + per-criterion EMA | API/Backend (Python nightly job) | — | Aggregates over ALL letters/children; batch-shaped; Admin SDK + ADC already in the server. |
| Evidence capture (per-letter×criterion) | API/Backend (server /coach, Admin SDK, D-13) | Client (Drift accrual for offline backfill, D-14) | Zero new client-write surface; Firestore rules stay deny-all for writes. |
| Compiled profile persistence | Database/Storage (Firestore doc keyed by uid) | Client (Drift mirror, D-16) | Server-owned truth; client mirror makes boot non-blocking (Req 6). |
| Micro-drill definitions | Database/Storage (`assets/curriculum/*.json`, signed) | Client graph + Backend `generate.py` copy | Real graph nodes (D-06); single-source asset derived to the server. |
| Justification ("why this pick") line | API (coach LLM online, D-10) | Client (authored template offline, D-10) | Same degradation axis as coaching; offline determinism preserved. |
| Rails / graph-legality enforcement | Client (`isLegalSelection`) + Backend (G5/G6) | — | Both tiers, exactly as today — the policy layer narrows, it does not replace the rails. |

## Standard Stack

### Core (all already present — Phase 18 adds NO new runtime packages)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `firebase-admin` (Python) | `>=7.0,<8` (installed) `[VERIFIED: server/pyproject.toml]` | Admin-SDK Firestore writes (evidence + profile) via ADC | Already initialized at import in `server/app/auth.py` with ADC (Cloud Run runtime SA / `gcloud auth application-default login` locally). `firebase_admin.firestore` ships in the package — no separate `google-cloud-firestore` install. |
| `drift` / `drift_dev` | `^2.31.0` (installed) `[VERIFIED: pubspec]` | New on-device tables: evidence accrual, arc state, profile mirror | Existing persistence spine; schemaVersion bump 5→6 with additive `createTable` migrations (LetterGraphPosition precedent). |
| `flutter_riverpod` / `riverpod_generator` | `3.1.3` / `4.0.3` (installed) `[VERIFIED: pubspec]` | Wiring the policy seam + profile-mirror provider | Riverpod-only (CLAUDE.md Decided). Hand-write providers that return Drift data classes (codegen `InvalidTypeException`, Phase-05 precedent). |
| `flutter_test` | SDK (installed) | Property/seeded-random tests, arc/EMA unit tests, calibration-style drill selection | Existing calibration-harness precedent (`test/core/scoring/calibration_harness_test.dart`) is the exact shape. |
| `fake_cloud_firestore` | `^4.1.1` (installed, client) `[VERIFIED: pubspec]` | Client-side Firestore-mirror tests | Already used for `CurriculumRepository` Firestore-first tests. |
| `langgraph` / `langchain-google-vertexai` | `>=1.2,<2` / `>=3.2.4` (installed) `[VERIFIED: server/pyproject.toml]` | Coach node picks among policy-legal candidates; keyless Vertex Gemini | Unchanged topology; the WHY line is a coach-node concern (D-10). |

### Supporting (server-side, for the nightly job — reuse, don't add)
| Component | Purpose | When to Use |
|-----------|---------|-------------|
| Cloud Run **Job** (new, same image) | Nightly EMA compile over all children | Recommended nightly-job shape — see §Nightly Job. Reuses `server/Dockerfile` + ADC; a new `app/jobs/compile_profiles.py` entrypoint. |
| Cloud Scheduler | Cron trigger for the job | `$0.10/job/month`, 3 free/account `[VERIFIED: WebSearch — oneuptime/GCP]`. One nightly cron. |
| Firestore TTL policy | Raw-evidence retention/rollup | Optional: TTL field on evidence docs so the store self-prunes after the nightly rollup (cost cap). |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Cloud Run Job + Scheduler | Firebase Scheduled Function (Python `scheduler_fn.on_schedule`) | Simpler `firebase deploy`, but introduces a NEW deploy surface (a functions codebase the repo doesn't have yet) separate from the existing Cloud Run server; the Cloud Run Job reuses the existing image, ADC, and gcloud deploy story. `[VERIFIED: WebSearch — firebase docs]` |
| Per-criterion EMA (D-15, locked) | BKT / logistic KT | Locked out by D-15 (no calibration data for guess/slip). EMA is one α, mirrors trivially in Dart+Python. |
| Seeded-random `flutter_test` (Req 5) | `glados` / `flutter_glados` | **glados base is capped `<3.0.0`** (won't resolve on Dart 3.11); **flutter_glados 1.1.18 pins `analyzer ^7.4.5`** while the project resolves analyzer 9.0.0 — a hard conflict that would break riverpod_lint 3.1.3. See §Don't Hand-Roll. |
| Append-only evidence subcollection | Per-child aggregate counter doc | A single hot counter doc risks write contention + unbounded fields; append-only avoids both (each write is a fresh doc). |

**Installation:** None. Phase 18 adds no new pub or PyPI packages. All plumbing reuses installed
dependencies. (See §Package Legitimacy Audit.)

**Version verification (external claims):**
- Gemini 2.5 Flash on Vertex: `$0.30`/M input, `$2.50`/M output; implicit caching on by default (min 1,024 tokens for 2.5 Flash), ~75% discount on cached prefix, caches deleted within 24h `[VERIFIED: WebSearch — developers.googleblog.com + Vertex context-cache blog]`.
- `glados` 1.1.7 (2023-12-04, sdk `>=2.12.0 <3.0.0`); `flutter_glados` 1.1.18 (2025-06-14, sdk `<4.0.0`, deps `analyzer ^7.4.5`) `[VERIFIED: pub.dev API]`.

## Package Legitimacy Audit

> Phase 18 installs **no new external packages**. This audit records the evaluation of the one
> package considered (and rejected) plus confirmation that the server-side Firestore path needs no
> new dependency.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `flutter_glados` | pub.dev | 1.1.18, 2025-06-14 | (popular, well-known author MarcelGarus) | github.com/MarcelGarus/glados | n/a (pub, slopcheck unavailable) | **REJECTED — not slop; hard `analyzer ^7.4.5` vs project analyzer 9.0.0 conflict.** Use plain `flutter_test`. |
| `glados` | pub.dev | 1.1.7, 2023-12-04 | (base pkg) | github.com/MarcelGarus/glados | n/a | **REJECTED — sdk cap `<3.0.0` incompatible with Dart 3.11.** |
| `firebase-admin` (Python, Firestore) | PyPI | installed `>=7.0,<8` | — | github.com/firebase/firebase-admin-python | n/a | **Already installed.** `firebase_admin.firestore` needs no new package. |

**Packages removed due to slopcheck [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

*slopcheck was unavailable at research time and does not cover pub.dev anyway. This is immaterial:
no new package is recommended. Both glados variants were rejected on verifiable compatibility grounds
(pub.dev API-confirmed SDK/analyzer constraints), not on legitimacy. If a future planner reconsiders
a package, gate it behind a `checkpoint:human-verify`.*

## Architecture Patterns

### System Architecture Diagram

```
                        ┌────────────────────────── ON-DEVICE (pure Dart, offline floor) ──────────────────────────┐
   child stroke  ──►  scorer (owns pass/fail, ADR-017) ──►  CheckResult / LetterScore.criteria + weakestCriterion
                                                                     │
                                                                     ▼
                                                   buildTutorFacts()  (the non-PII chokepoint)
                                                                     │  trajectory + criteria + weakest + profile(mirror) + digest
                                                                     ▼
      ┌──────────────── SelectionPolicy  (NEW, pure Dart) ────────────────┐
      │  arc state machine (D-02 streak → step-down → rebuild → retry)     │
      │  anti-boredom filter (no identical 3rd repeat on same criterion)   │
      │  micro-drill injection (dominant failing criterion → its drill)    │──►  legalCandidates[]  +  arcStep  +  targetCriterion  +  whyFacts
      │  reads: TutorFacts.trajectory, weakestCriterion, GraphPosition,    │
      │         profile mirror (strengths/struggles/EMA)                    │
      └───────────────────────────────────────────────────────────────────┘
                          │                                              │
             ONLINE       ▼                              OFFLINE         ▼
   RouterExerciseSelector (accept agent pick IFF          CurriculumGraphWalker (deterministic
   isLegalSelection over candidates)                       pick from the SAME candidates)
                          │                                              │
   POST /coach ──────────┘                                              └──► authored-template WHY line (D-10)
      │  TutorFactsIn (+profile +evidenceDigest, extra=forbid, 422 lockstep)
      ▼
  ┌──────────────────────── CLOUD RUN  qalam-tutor (existing) ────────────────────────┐
  │  verify_caller → uid  │  coach node picks among legalNextExerciseIds + voices WHY  │
  │  D-13: Admin SDK append evidence rows  children/{uid}/evidence/{autoId}            │──► Firestore
  │        (per-letter×criterion, from criteria + evidenceDigest; BackgroundTask)      │
  └───────────────────────────────────────────────────────────────────────────────────┘
                                                                                    │
   ┌──────── CLOUD RUN JOB (NEW, same image) ── nightly via Cloud Scheduler ────────┘
   │  read children/{uid}/evidence/*  →  per-criterion EMA  →  strengths[]/struggles[]
   │  write child_models/{uid}  (derived-only, fixed-vocabulary, non-PII)  → (optional) TTL-prune raw evidence
   └───────────────────────────────────────────────────────────────────────────────
                                                                                    │
   next session boot: Drift mirror read (instant) ◄── background one-shot Firestore .get() (owner-read rule) ◄─┘
```

### Recommended Project Structure
```
lib/
├── tutor/
│   ├── selection_policy.dart          # NEW — pure Dart: arc SM + anti-boredom + drill injection (D-09/D-11)
│   ├── selection_policy.dart          #        (no Riverpod/Firebase/render import — durable-layer guarded)
│   ├── exercise_selector_provider.dart# EXTEND — RouterExerciseSelector consumes SelectionPolicy candidates
│   ├── tutor_facts.dart               # EXTEND — +profile +evidenceDigest fields (mirror server schema.py)
│   └── tutor_facts_builder.dart       # EXTEND — thread profile (from mirror) + digest (from Drift)
├── curriculum/
│   ├── curriculum_graph.dart          # unchanged rails; microDrill nodes are just more nodes
│   └── curriculum_graph_walker.dart   # EXTEND — offline path consumes SelectionPolicy candidates
├── core/scoring/
│   └── criterion_ema.dart             # NEW — pure Dart EMA (mirrored 1:1 in Python)
├── data/
│   ├── app_database.dart              # EXTEND — schemaVersion 6: evidence, arc-state, profile-mirror tables
│   └── child_model_repository.dart    # NEW — Firestore-first-with-Drift-fallback (CurriculumRepository idiom)
└── screens/ (widgets)                 # EXTEND — Teacher's Margin panel (D-01) + Spotlight overlay (D-05)

assets/curriculum/
├── exercises.json                     # EXTEND — +letters +criteria labels on EVERY exercise; +microDrill.* nodes
└── curriculum_graph.json              # EXTEND — criterion-tagged enrichment microDrill nodes (signedOff:false)

server/app/
├── schema.py                          # EXTEND — TutorFactsIn +profile +evidenceDigest (extra=forbid, ships FIRST)
├── evidence.py                        # NEW — Admin-SDK append (per-letter×criterion) from facts (D-13)
├── criterion_ema.py                   # NEW — EMA, byte-identical logic to criterion_ema.dart
├── jobs/compile_profiles.py           # NEW — Cloud Run Job entrypoint (nightly compile)
├── nodes/plan.py                      # EXTEND — pick among policy candidates + rationale (WHY)
└── curriculum_data/generate.py        # EXTEND — derive microDrill nodes + letters/criteria labels to server copy

server/tests/test_eval/
├── run_eval.py                        # EXTEND — 5th "selection_policy" dimension
└── selection_gold_set.jsonl           # NEW — fail-streak / returning-child / boredom-trap scenarios (signed:false)
```

### Pattern 1: Pure-Dart policy layer behind the existing selector seam (D-09/D-11)
**What:** A pure `SelectionPolicy` that, given `TutorFacts` + `GraphPosition` + the profile mirror,
returns `(legalCandidates, arcStep, targetCriterion, whyFacts)`. It lives in `lib/tutor/` (like the
router) but imports nothing from Riverpod/Firebase/render — it is a durable-layer citizen guarded by
`test/tutor/durable_layers_no_agent_imports_test.dart`.
**When to use:** Always — both `RouterExerciseSelector` (online) and `CurriculumGraphWalker` (offline)
consume the *same* candidate set, guaranteeing offline parity (D-11) by construction.
**Example (shape — grounded in the existing `RouterExerciseSelector`):**
```dart
// Source: lib/tutor/exercise_selector_provider.dart (existing accept-if-legal seam, extended)
final policy = SelectionPolicy(graph);
final decisionInputs = policy.narrow(facts, position, profile); // arc/anti-boredom/drill injection
// ONLINE: accept the agent pick ONLY if it is one of decisionInputs.candidates AND graph-legal.
final proposed = decision?.plan?.nextExerciseId;
if (proposed != null &&
    decisionInputs.candidates.contains(proposed) &&
    graph.isLegalSelection(proposed,
        clearedTiers: position.clearedTiers,
        clearedCompetencies: position.clearedCompetencies)) {
  return proposed;                       // agent picked a policy-legal, graph-legal candidate
}
return _walker.selectFrom(decisionInputs, facts, position); // offline / illegal → deterministic
```

### Pattern 2: Anti-boredom + arc entry off the SAME per-criterion signal (D-02)
**What:** One counter drives both the anti-boredom rule (Req 1) and arc entry (Req 4): consecutive
fails on the SAME `weakestCriterion`. Read straight off `TutorFacts.trajectory` + `weakestCriterion`
(already on-device). Two same-criterion fails → (a) forbid a third identical exercise, and (b) enter
the arc targeting that criterion.
**When to use:** Every fail. The threshold N ships as a named `signed:false` constant (D-02).
**Anti-pattern avoided:** re-deriving "struggle" from scratch — reuse the existing
`_deriveStruggleTags` idiom (already requires 2+ occurrences before a tag counts).

### Pattern 3: Arc state machine persisted to Drift (D-04/D-12)
**What:** `ArcState = {active, step, targetCriterion, exerciseToRetry}`. Steps: `entry → stepDown
(micro-drill on targetCriterion) → rebuild → retryOriginal`. Exit = a clean win on
`exerciseToRetry` (D-04). Floor guard: if even the drill's floor fails, land on a guaranteed-doable
success (trace) and end warm — never loop (D-04).
**When to use:** Persist on every transition (DYN-02 resume pattern) so a mid-arc restart resumes.
**Example (persistence shape — grounded in the existing resume cursor):**
```dart
// Source: lib/data/app_database.dart (LetterGraphPosition/LetterExerciseReps resume precedent)
// New sibling table ArcState (letterId PK), JSON-encoded like clearedTiers/clearedCompetencies.
await db.setArcState(letterId: 'baa', active: true, step: 'stepDown',
    targetCriterion: 'dot', exerciseToRetry: 'baa.writeLetter.fromSound');
```

### Anti-Patterns to Avoid
- **Blocking the practice path on the child model (violates Req 6/D-16):** never `await` a Firestore
  `.get()` on the selection path. Boot reads the Drift mirror synchronously; the refresh is a
  fire-and-forget background one-shot. Bare `StreamProvider.future` HANGS under Riverpod 3 (project
  memory) — use `FutureProvider`/one-shot reads.
- **Evidence write on the /coach critical path:** the Admin-SDK append must not delay `CoachOut`. Use a
  FastAPI `BackgroundTask` (or write after building the response) so the child never waits on Firestore.
- **A hot per-child counter doc:** append-only evidence docs, not field increments on one doc.
- **Letting a micro-drill gate the star:** microDrill nodes are enrichment (`essential:false`) — they
  never enter the 70/30 mastery core (D-06). The one quiet star's condition is untouched.
- **Widening the wire without server-first deploy:** any new `TutorFactsIn` field 422s the live
  /coach the instant the client sends it before the server ships it (`extra=forbid`). Server ships
  first, additive+defaulted, then the Dart mirror (15-02/15-04, 17-05/17-06 precedent).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Property/generative tests for the rails (Req 5) | A glados/flutter_glados integration | **Seeded-random loop in plain `flutter_test`** (`Random(seed)` generating agent proposals/histories; assert 100% legal, illegal→walker) | glados base sdk `<3.0.0` won't resolve on Dart 3.11; flutter_glados pins `analyzer ^7.4.5` vs the project's analyzer 9.0.0 — a hard conflict that would break riverpod_lint. Seeded plain tests are deterministic (fixed seed = reproducible CI), need no dependency, and match the calibration-harness precedent. |
| Firestore access from the nightly job | A raw REST client / new SDK | `firebase_admin.firestore` (already installed + ADC-initialized) | Zero new package; the server already inits `firebase_admin` at import in `auth.py`. |
| Cron scheduling | A self-managed timer/`while True` | Cloud Scheduler → Cloud Run Job | Managed cron, scale-to-zero, $0.10/job/mo, no idle cost. |
| Prompt-cost optimization | Hand-rolled prompt-prefix cache | Vertex **implicit caching** (on by default, Gemini 2.5+) | No code change; ~75% discount on the stable curriculum prefix; the COACH/PLAN prompts are already designed as "cache-stable" prefixes. |
| KT model | BKT/DKT with guess/slip params | Per-criterion EMA (D-15) | Locked; no calibration data exists; one α, mirrors Dart↔Python. |
| List/map columns in Drift | A new relational sub-table | JSON-encode into a `text` column (existing idiom) | `clearedTiers`/`clearedCompetencies` already do this; Drift has no native list column. |

**Key insight:** Almost every "hard" piece is already solved in this codebase — the seam
(`ExerciseSelector`), the rails (`isLegalSelection`/G5/G6), the non-PII chokepoint (`buildTutorFacts`),
the resume-persistence pattern (`LetterGraphPosition`), the Firestore-first-with-fallback idiom
(`CurriculumRepository`), the 422-lockstep discipline, and the eval harness. Phase 18 is mostly
*composition*, not new invention. The one genuinely new algorithm (EMA) is trivial by design.

## Runtime State Inventory

> Phase 18 is additive (new tables, new fields, new nodes) — not a rename/refactor. This section is
> included because the phase introduces **persistent server-side state** (Firestore) for the first
> time in the child's data path, which has migration-adjacent concerns.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | (1) **Firestore `child_models/{uid}`** (NEW — profile doc, derived-only). (2) **Firestore `children/{uid}/evidence/*`** (NEW — append-only evidence). (3) **Drift schema v5→v6** (NEW evidence/arc/profile-mirror tables). | New collections + new Drift tables (additive `createTable`). No existing data to migrate — first-run children start clean. |
| Live service config | **Cloud Scheduler cron** (NEW) + **Cloud Run Job** (NEW, same image) must be created/deployed. Not in git as running config until deployed. | Deploy job + create scheduler cron (gcloud; a human/deploy gate like 17-10). |
| OS-registered state | None (mobile app + managed cloud only). | None — verified: no Task Scheduler/launchd/pm2 equivalents in scope. |
| Secrets/env vars | None new. Vertex stays **keyless** (ADC/Technion credits); `firebase_admin` uses ADC. No new secret. | None. Confirm the Cloud Run **Job**'s runtime service account has Firestore read/write (Datastore User) + Vertex is not needed for the job. |
| Build artifacts | `assets/curriculum/*.json` changes must be re-derived to the server copy via `generate.py`; the Docker image rebuilds on the single re-deploy. | Run `generate.py` after authoring microDrill nodes + letters/criteria labels; rebuild+redeploy image once (server-first, 422 lockstep). |

**The canonical question — what runtime state persists the old shape after code lands?** The only
cross-system coupling is the **wire contract** (server `TutorFactsIn` must ship the new fields before
the client sends them) and the **Firestore rules** (the profile doc needs an owner-read rule before
the client's D-16 `.get()` succeeds). Both are ordered-deploy gates, not data migrations.

## Common Pitfalls

### Pitfall 1: The profile `.get()` is blocked by deny-all Firestore rules
**What goes wrong:** D-16's background refresh does a client-side Firestore `.get()` on
`child_models/{uid}`. Today `firestore.rules` has a **deny-by-default catch-all** (`allow read,
write: if false`) for any unmatched path — so the read returns permission-denied and the mirror never
refreshes (silently, since the practice path doesn't block).
**Why it happens:** The current rules deliberately have NO child-data collection match (Phase 06.1
D-11). The profile doc is a new child-data path.
**How to avoid:** Add an owner-scoped read rule (writes stay Admin-only):
```
match /child_models/{uid} {
  allow read: if request.auth != null && request.auth.uid == uid; // owner-only read (D-16 refresh)
  allow write: if false;                                          // Admin SDK only (D-13)
}
```
This preserves deny-all-client-writes (D-13) and adds a uid-scoped read (elevation-of-privilege
guard — account A can't read account B). Deploy the rule alongside the server. **Warning sign:** the
mirror never updates on a real device; `permission-denied` in logs.

### Pitfall 2: 422 lockstep on the new wire fields
**What goes wrong:** Adding `profile`/`evidenceDigest` to the client `TutorFacts.toMap()` before the
server ships them makes the live /coach 422 (`extra="forbid"`), silently degrading every online
session to the AuthoredFallback floor.
**How to avoid:** Server ships FIRST (additive, `default=None`/`default_factory=list`), then the Dart
mirror, then the single re-deploy — exactly the 15-02/15-04 and 17-05/17-06 discipline. Guard KEY
names on both sides (17-05: `extra=forbid` is the real teeth; the KEY-name guard catches PII keys).

### Pitfall 3: Word-attempt evidence granularity mismatch (Req 7)
**What goes wrong:** Req 7 wants "evidence rows per letter×criterion for every letter in the word,"
but the scorer's 5 geometric criteria (strokeCount/strokeOrder/shape/direction/dot) exist for
**isolated-letter** attempts. A `writeWord` attempt (`check: "sequence"`) produces a word-level
verdict + `writtenWord` transcription, NOT per-letter geometric criteria. Blindly writing 5 criteria
per letter for a word attempt fabricates signal the scorer never produced.
**Why it happens:** `TutorFacts.criteria` is single-letter-form scoped; a word touches N letters
(e.g. باب = baa·alif·baa) with no per-letter geometry.
**How to avoid:** Define the word-attempt evidence shape explicitly in the plan (this is an **Open
Question** below). Recommended: word attempts write a **coarser** per-letter signal (letter
present/correct/dot-present derived from the transcription), tagged with a `source:"word"` marker so
the compiler can weight it differently from isolated-letter geometric evidence. The 5-criteria rows
are written only for isolated-letter attempts. Keep the schema letter×criterion so it is "all-letters
by construction" (Req 8) while being honest about which criteria a word attempt can populate.

### Pitfall 4: EMA over sparse data declares false struggles
**What goes wrong:** One fail on a criterion drives its EMA down and mislabels it a "struggle,"
producing a jittery child model.
**Why it happens:** EMA reacts immediately; a single noisy attempt shouldn't be a verdict.
**How to avoid:** Gate `struggles[]`/`strengths[]` membership on BOTH an EMA threshold AND a minimum
attempt count (mirror the existing `_deriveStruggleTags` "≥2 occurrences" rule). Initialize EMA at a
neutral prior (0.5) and treat sub-threshold-count criteria as "unknown," not struggle/strength.
`[ASSUMED]` for the exact count/thresholds — provisional, `signed:false` until the mother signs (D-15).

### Pitfall 5: Selection latency creeps onto the feedback moment
**What goes wrong:** Precomputing the pick after the feedback animation, or issuing a second network
call for selection, adds perceptible delay (violates the SPEC latency constraint).
**How to avoid:** The pick rides the **same** /coach round-trip 17.2 already established
(`legalNextExerciseIds` → coach proposes `nextExerciseId`). The policy narrowing is pure Dart
(microseconds); the agent pick is already in the response the feedback moment masks. Offline the
walker picks synchronously. No new call, no new latency.

### Pitfall 6: Riverpod codegen chokes on a Drift-returning provider
**What goes wrong:** `@riverpod` on a provider returning a Drift-generated data class throws
`InvalidTypeException` (riverpod_generator 4.0.3) — the exact Phase-05 `childProfileProvider` bug.
**How to avoid:** Hand-write the profile-mirror provider as a plain `FutureProvider` (not codegen),
mirroring `childProfileProvider`. Keep the Drift `.watch()` bridge pattern (`_bindDriftStream`
AsyncNotifier) if a live stream is ever needed — never a bare `StreamProvider.future`.

## Code Examples

### Per-criterion EMA (D-15) — mirrored Dart ↔ Python
```dart
// Source: standard EMA formulation [CITED: recency-weighted mastery, EDM/knowledge-tracing literature]
// lib/core/scoring/criterion_ema.dart  (pure Dart — no Flutter/Firebase import)
double updateEma(double prior, bool passed, double alpha) {
  final outcome = passed ? 1.0 : 0.0;
  return alpha * outcome + (1.0 - alpha) * prior;      // "recent attempts count more"
}
// cold start: prior defaults to 0.5 (neutral); a criterion needs >= kMinAttempts before it
// can be labelled strength/struggle (Pitfall 4). alpha is provisional (signed:false, D-15).
```
```python
# server/app/criterion_ema.py — byte-identical logic so on-device and nightly agree
def update_ema(prior: float, passed: bool, alpha: float) -> float:
    outcome = 1.0 if passed else 0.0
    return alpha * outcome + (1.0 - alpha) * prior
```

### Append-only evidence write, off the /coach critical path (D-13)
```python
# Source: server/app/auth.py already initializes firebase_admin with ADC — reuse it.
# server/app/evidence.py
from firebase_admin import firestore
def append_evidence(uid: str, rows: list[dict]) -> None:
    db = firestore.client()
    batch = db.batch()                                   # up to 500 ops, one round-trip
    col = db.collection("children").document(uid).collection("evidence")
    for r in rows:                                       # r = {letter, criterion, passed, source, ts, ttlAt}
        batch.set(col.document(), r)                     # auto-id → append-only, no hot doc
    batch.commit()
# main.py /coach: schedule this as a BackgroundTask so CoachOut is not delayed.
```

### Nightly compile entrypoint (Cloud Run Job)
```python
# server/app/jobs/compile_profiles.py  — run as a Cloud Run Job, triggered nightly by Cloud Scheduler
from firebase_admin import firestore
from app.criterion_ema import update_ema
def main() -> None:
    db = firestore.client()
    for child in db.collection("children").stream():
        uid = child.id
        ema: dict[str, float] = {}          # key "letter/criterion" -> mastery
        counts: dict[str, int] = {}
        for ev in db.collection("children").document(uid).collection("evidence").stream():
            e = ev.to_dict(); k = f"{e['letter']}/{e['criterion']}"
            ema[k] = update_ema(ema.get(k, 0.5), e["passed"], ALPHA); counts[k] = counts.get(k, 0) + 1
        strengths = [k for k, v in ema.items() if v >= HI and counts[k] >= MIN]
        struggles = [k for k, v in ema.items() if v <= LO and counts[k] >= MIN]
        db.collection("child_models").document(uid).set({          # derived-only, non-PII, fixed-vocab
            "strengths": strengths, "struggles": struggles, "perCriterion": ema,
            "schemaVersion": 1, "updatedAt": firestore.SERVER_TIMESTAMP})
```

### Drift schema bump 5 → 6 (additive, version-guarded)
```dart
// Source: lib/data/app_database.dart migration (LetterGraphPosition v5 precedent)
@override int get schemaVersion => 6;
// in onUpgrade:
if (from < 6) {
  await m.createTable(letterCriterionEvidence); // offline accrual for the D-14 digest
  await m.createTable(arcState);                // D-12 resume: step/targetCriterion/exerciseToRetry
  await m.createTable(childProfileMirror);      // D-16 boot mirror (JSON-encoded strengths/struggles/EMA)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Mechanical `remediateOneTier ?? drill-in-place` on fail | Arc state machine (step-down → rebuild → retry-original) | Phase 18 | Remediation becomes an *experience*, not a rule (Req 4). |
| Selection sees only this attempt + session strengths/struggles | Two-timescale model (session trajectory + nightly EMA profile) | Phase 18 | First per-child memory across sessions (Req 2). |
| Explicit prompt-prefix caching effort | Vertex **implicit caching on by default** (Gemini 2.5+) | 2025 (Gemini 2.5 GA) | ~75% cached-prefix discount with zero code; closes cost side of the open question. `[VERIFIED: developers.googleblog.com]` |
| glados for Dart property testing | Seeded-random `flutter_test` (glados stalled on Dart 2, analyzer conflict) | — | No new dependency; deterministic CI. |

**Deprecated/outdated:**
- `glados` base package (last release 2023, capped `<3.0.0`) — not viable on Dart 3.x.
- `langchain-anthropic` in server deps is a documented REMOVE candidate (nothing imports it) — not a Phase-18 concern but noted.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Calls/session ≈ 7–15 (one /coach per scored attempt in a baa session) | §Cost/Latency | Cost estimate scales with the real count; the plan MUST measure the actual number on-device to CLOSE the open question. |
| A2 | Word-attempt evidence should be a coarser per-letter signal (not the 5 geometric criteria) | Pitfall 3 / §Cross-letter | If the mother/owner wants finer word-level per-letter geometry, the scorer/word path needs more work than planned. Resolve in discuss/plan. |
| A3 | EMA cold-start prior 0.5 + a minimum-attempt-count gate for strength/struggle | §EMA / Pitfall 4 | Wrong init/threshold → jittery or over-confident model. Provisional, mother-signed (D-15). |
| A4 | α, arc-N, drill content, eval threshold are all provisional `signed:false` | multiple | These are pedagogy calls — must not ship as locked values without mother sign-off (Phase 15/17 precedent). |
| A5 | Cloud Run Job (not Firebase Scheduled Function) is the better nightly-job fit | §Nightly Job | If the team prefers `firebase deploy`, a Scheduled Function also works; the choice is Claude's discretion per CONTEXT. |
| A6 | Implicit caching's ~75% discount applies to the stable COACH/PLAN prompt prefix | §Cost/Latency | If the prefix isn't stable enough for cache hits, savings are lower (still keyless/credit-covered). Measure cached-token % from /coach logs. |
| A7 | Firestore write cost at child scale is negligible (free-tier 20k writes/day) | §Firestore Layout | At large scale, per-attempt appends + per-word N×M rows could add up; TTL-prune + batched writes keep it bounded. |

**If this table were empty:** it is not — these are the items discuss-phase / the planner must confirm
(especially A2, A3, A4 which touch pedagogy and the mother's sign-off).

## Open Questions (RESOLVED)

> All 4 questions were resolved during planning (plan set 18-01 … 18-11, committed 31c7e3a).

1. **Word-attempt evidence granularity (Req 7).**
   - **RESOLVED:** 18-02 Task 1 + 18-05 Task 2 — coarse per-letter signal tagged `source:"word"`;
     the 5 geometric criteria are reserved for isolated-letter attempts (`source:"letter"`).
   - What we know: word attempts (`check:"sequence"`) produce a word-level verdict + `writtenWord`
     transcription, not per-letter geometric criteria; the word باب touches baa·alif·baa.
   - What's unclear: exactly which per-letter criteria a word attempt can honestly populate.
   - Recommendation: write a coarse per-letter signal (present/correct/dot) tagged `source:"word"`;
     reserve the 5 geometric criteria for isolated-letter attempts. Confirm with owner in discuss/plan.

2. **Which uid keys the model — anonymous vs permanent account.**
   - **RESOLVED:** evidence/profile keyed on the current account uid throughout (18-05, D-13 path);
     D-09c anon→permanent linking (same uid) covers the common path; the fresh-device-signup edge is
     documented out-of-scope (no parent-account surface changes this phase).
   - What we know: children never log in; the account uid is the parent's (or the anonymous boot
     identity); sign-up links anon→permanent keeping the SAME uid (D-09c); Drift DB is already
     account-scoped per uid.
   - What's unclear: whether evidence written under an anonymous uid must be migrated if the parent
     later signs up on a fresh device (no local link).
   - Recommendation: key evidence/profile on the current account uid; rely on D-09c linking (same
     uid) for the common path; document the fresh-device-signup edge as out-of-scope (parent-account
     surface changes are deferred).

3. **Nightly job scaling model (single-task vs parallel).**
   - **RESOLVED:** 18-09 — single-task sequential compile for this phase; parallel-task sharding
     noted as a later scale lever.
   - What we know: Cloud Run Jobs support parallel task instances over sharded input.
   - What's unclear: child count at Technion-demo scale (likely tens) — parallelism is almost
     certainly unnecessary now.
   - Recommendation: single-task sequential compile for this phase; note parallel-task sharding as a
     later scale lever.

4. **Exact measured cost/latency numbers (the open research question this phase must CLOSE).**
   - **RESOLVED (task scheduled):** 18-11 Task 2 — device+server measurement writes
     `docs/architecture/COST-LATENCY-CLOSURE.md` with measured calls/session, cached-token %, and
     stroke→feedback→pick wall-clock.
   - What we know: the *expected* shape (implicit caching, TTFT ≈ 0.59s Vertex, 8s timeout budget,
     pick rides the existing round-trip).
   - What's unclear: the real per-session call count, cached-token %, and stroke→feedback→pick
     wall-clock on a Pixel Tablet / iPad.
   - Recommendation: the plan MUST include a measurement task (device timing + /coach-log token
     accounting) that writes the CLOSED numbers into a short cost/latency note. Research provides the
     framework; only a device+server run produces the signed numbers.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `firebase_admin` + ADC (server) | Evidence + profile writes (D-13), nightly job | ✓ | `>=7.0,<8` | — (ADC on Cloud Run runtime SA / `gcloud auth application-default login` locally) |
| Cloud Run (existing `qalam-tutor`) | Server evidence path + the nightly Job (same image) | ✓ | project qalam-app-bd7d0, us-central1 | — |
| Cloud Scheduler | Nightly cron trigger | ✓ (GCP project) | — | manual job run / any cron |
| Vertex AI Gemini 2.5 Flash (keyless) | Coach WHY line + eval judge | ✓ | keyless ADC, Technion credits | AuthoredFallback template (offline WHY line, D-10) |
| Firestore | Evidence + profile doc | ✓ | qalam-app-bd7d0 | Drift mirror (offline boot, D-16) |
| Drift/Riverpod/flutter_test (client) | Tables, wiring, tests | ✓ | installed | — |
| `glados`/`flutter_glados` | (considered for Req 5) | ✗ | incompatible | **plain `flutter_test` seeded-random (the recommendation)** |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** property-testing library → seeded plain `flutter_test`.
**Deploy prerequisites (human/gated, like 17-10):** (1) server re-deploy carrying the new
`TutorFactsIn` fields BEFORE the client sends them; (2) create the Cloud Run Job + Cloud Scheduler
cron; (3) deploy the `child_models` owner-read Firestore rule; (4) confirm the Job's runtime SA has
Firestore read/write.

## Cost + Latency Closure (the open research question)

**This phase must CLOSE the open research question with measured numbers.** Research supplies the
framework and expected values; the plan supplies a measurement task that writes the signed numbers.

- **Calls per session:** one POST /coach per scored attempt/coaching moment (grounded in `main.py` +
  `buildTutorFacts` — each attempt builds facts and calls the coach). A baa session ≈ 7–15 exercises
  → **~7–15 coach calls** + one `/health` warm-up at unit entry. `[ASSUMED A1 — measure on device]`
- **Prompt caching:** **implicit caching is ON by default** for Gemini 2.5 Flash on Vertex — no code
  change; min 1,024 tokens; ~75% discount on the shared prefix; caches deleted within 24h `[VERIFIED:
  developers.googleblog.com/gemini-2-5-models-now-support-implicit-caching + Vertex context-cache
  blog]`. The COACH_PROMPT/PLAN_PROMPT are already authored as cache-stable curriculum prefixes
  (`SystemMessage`, see `plan.py`), so intra-session calls hit the cache. Explicit caching (min
  2,048 tokens + storage fee) is available if predictable savings are ever needed — not required now.
- **Token/price context:** Gemini 2.5 Flash `$0.30`/M input, `$2.50`/M output `[VERIFIED: WebSearch —
  multiple pricing sources]`; keyless Vertex on Technion credits, min-instances=0 idle. The new
  `profile`/`evidenceDigest` fields add a small fixed-vocabulary payload — negligible token growth.
- **Selection latency:** the pick rides the **same** /coach round-trip (17.2 `legalNextExerciseIds` →
  coach proposes `nextExerciseId`); no second call. Policy narrowing is pure Dart (microseconds).
  Vertex TTFT ≈ 0.59s; graph budget 8s (`COACH_TIMEOUT_SECONDS`) with 503→AuthoredFallback. Offline
  walker picks synchronously. **Net: selection adds no perceptible latency (Pitfall 5).**
- **What the plan must MEASURE to sign the closure:** real calls/session, cached-token % from
  /coach logs, and stroke-up→feedback→next-pick wall-clock on a Pixel Tablet/iPad.

## Firestore Evidence + Profile Layout

- **Evidence (append-only):** `children/{uid}/evidence/{autoId}` = `{letter, criterion, passed,
  source, ts, ttlAt}`. Auto-id ⇒ every write is a new doc ⇒ **no hot document, no write contention**.
  Written server-side only (D-13) via `batch()` (one word attempt → N×M rows in one round-trip),
  scheduled off the /coach critical path (BackgroundTask).
- **Profile (derived-only):** `child_models/{uid}` = `{strengths[], struggles[], perCriterion{}, 
  schemaVersion, updatedAt}` — fixed-vocabulary (letter ids + criterion names + floats), non-PII.
  A **PII/token guard test over this schema** is a Req 8 acceptance criterion (GROUND-04 discipline).
- **Rules:** deny-all client WRITES stay (D-13); ADD an owner-scoped READ on `child_models/{uid}` for
  the D-16 refresh (Pitfall 1). Evidence subcollection: no client access at all (Admin-only).
- **Retention/rollup:** the nightly compile rolls raw evidence into the EMA profile; set a Firestore
  **TTL policy** on `ttlAt` (or delete during compile) so raw evidence self-prunes and cost stays
  bounded. `[ASSUMED A7]`
- **Cost at child scale:** free-tier 20k writes/day comfortably covers tens–hundreds of children at
  ~10–15 evidence writes/session + 1 profile write/child/night. `[ASSUMED A7 — measure at scale]`

## Nightly Job (Req 8)

**Recommendation: Cloud Run Job triggered by Cloud Scheduler.** `[ASSUMED A5 — Claude's discretion]`
- **Why:** reuses the existing `server/Dockerfile`, the already-initialized `firebase_admin`+ADC, and
  the existing gcloud deploy story. The work is batch-shaped (aggregate over ALL children/letters),
  runs once and exits — exactly the Cloud Run Jobs use case `[VERIFIED: WebSearch — oneuptime/GCP]`.
  Scale-to-zero; no idle cost; Cloud Scheduler cron $0.10/mo (3 free) `[VERIFIED: WebSearch]`.
- **Shape:** a new entrypoint `app/jobs/compile_profiles.py` in the SAME image; the Job overrides the
  container command to run it; Cloud Scheduler fires nightly (e.g. `0 3 * * *`).
- **Alternative:** Firebase Scheduled Function (Python `scheduler_fn.on_schedule`, 2nd-gen, Cloud-Run-
  backed) `[VERIFIED: WebSearch — firebase docs]` — simpler `firebase deploy`, but a NEW deploy
  surface the repo doesn't have. Prefer the Job to keep one deployment story.
- **Letter-agnostic by construction (Req 8 acceptance):** the compiler iterates evidence keys
  (`letter/criterion`) with no per-letter branching — a newly signed letter appears in evidence and
  compiles with ZERO schema/code change. A second-letter fixture proves this.

## EMA Knowledge Tracing (D-15)

- **Formula:** `ema_new = α·outcome + (1−α)·ema_prior`, outcome ∈ {1.0 pass, 0.0 fail}, per
  letter×criterion, one α. "Recent attempts count more." `[CITED: recency-weighted mastery, EDM/KT
  literature — arxiv/EDM cold-start papers]`
- **Cold start:** neutral prior 0.5; a criterion is "unknown" (neither strength nor struggle) until
  it has ≥ `kMinAttempts` (mirror the existing `_deriveStruggleTags` ≥2 rule). `[ASSUMED A3]`
- **Strength/struggle vocabulary:** `perCriterion[k] ≥ HI ∧ count ≥ MIN → strength`; `≤ LO ∧ count ≥
  MIN → struggle`. Tags are fixed-vocabulary `letter/criterion` ids — non-PII.
- **Mirrored Dart↔Python:** identical formula in `criterion_ema.dart` and `criterion_ema.py` so the
  on-device within-session estimate and the nightly compile agree. Unit-test both against the same
  fixtures.
- **Provisional:** α, HI/LO, MIN, kMinAttempts all `signed:false` until the mother signs (D-15/A4).

## Cross-letter Evidence (Req 7)

- **NEW labels needed:** no exercise carries `letters` or `criteria` today (verified — only a coarse
  `skill` field like "formation"/"spelling"). Add `letters` (the letters the exercise touches) and
  `criteria` (the criteria it exercises) to EVERY exercise in `exercises.json`, derived to the server
  via `generate.py`.
- **Word attempts credit every letter:** a `writeWord` attempt on باب records evidence for baa AND
  alif — see Pitfall 3 for the granularity caveat (coarse per-letter signal, `source:"word"`).
- **Schema is all-letters; content is what's signed (baa, alif today)** — the Req 8 second-letter
  fixture proves adding a signed letter needs zero schema change.

## Validation Architecture

> Nyquist validation is enabled (`workflow.nyquist_validation` absent → treated as enabled).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Dart `flutter_test` (client) + Python `pytest` (server) |
| Config file | `pubspec.yaml` (dev_dependencies), `server/pyproject.toml` (`[tool.pytest.ini_options]`, `markers = ["code"]`) |
| Quick run command | `flutter test` (client) · `cd server && uv run pytest -m code -q` (server model-free) |
| Full suite command | `flutter test` + `cd server && make eval` (adds the Vertex judge legs) |

### Phase Requirements → Test Map
| Req | Behavior | Test Type | Automated Command | File Exists? |
|-----|----------|-----------|-------------------|-------------|
| Req 1 | 3rd pick ≠ identical after 2 same-criterion fails; line names the criterion | unit + widget | `flutter test test/tutor/selection_policy_test.dart` | ❌ Wave 0 |
| Req 2 | seeded profile → outgoing facts carry profile; first pick references it | fixture | `flutter test test/tutor/across_session_memory_test.dart` | ❌ Wave 0 |
| Req 3 | dominant failing criterion selects its micro-drill (per letter×form) | calibration-harness style | `flutter test test/tutor/microdrill_selection_test.dart` | ❌ Wave 0 |
| Req 4 | fail-streak scenario reaches a clean win within N via observable arc states | scenario/unit | `flutter test test/tutor/remediation_arc_test.dart` | ❌ Wave 0 |
| Req 5 | 100% agent picks graph-legal; illegal → walker | **seeded-random property (plain flutter_test)** | `flutter test test/tutor/selection_rails_property_test.dart` | ❌ Wave 0 |
| Req 6 | airplane-mode multi-exercise session via walker, no block | integration | `flutter test test/tutor/offline_floor_test.dart` | ❌ Wave 0 |
| Req 7 | word attempt records evidence for every letter×criterion | fixture | `cd server && uv run pytest tests/test_evidence.py -m code` | ❌ Wave 0 |
| Req 8 | multi-letter compile; second-letter fixture = zero schema change; PII/token guard | unit | `cd server && uv run pytest tests/test_compile_profiles.py -m code` | ❌ Wave 0 |
| Req 8 | EMA Dart↔Python parity | unit ×2 | `flutter test test/core/scoring/criterion_ema_test.dart` + `uv run pytest tests/test_criterion_ema.py -m code` | ❌ Wave 0 |
| Req 9 | `make eval` includes selection dimension, passes ≥ threshold on signed gold set | eval | `cd server && make eval` (+ `uv run pytest tests/test_eval/test_selection_dimension.py -m code`) | ❌ Wave 0 |
| D-14 | wire digest guard both sides (KEY-name + extra=forbid) | guard | `flutter test test/tutor/payload_nonpii_test.dart` (extend) + `uv run pytest tests/test_schema_forbid.py -m code` | partial (extend) |

### Sampling Rate
- **Per task commit:** `flutter test <changed test>` · `uv run pytest -m code -q` (model-free, no network).
- **Per wave merge:** full `flutter test` + `cd server && uv run pytest -m code`.
- **Phase gate:** `make eval` green (adds the Vertex judge + selection dimension) before `/gsd-verify-work`.

### HUMAN-UAT Sign-off Gates (mother-parameterized — `signed:false` until flipped)
- **Micro-drill content (D-07):** baa's 3-criterion drill set signed by the mother; the flip is the
  only content change (Req 3 acceptance). **Schedule early** (the one pedagogy ask).
- **Arc-N (D-02/D-04):** the fail-streak threshold + "win within N" number is the mother's; provisional
  until signed (Req 4 acceptance).
- **α / EMA thresholds (D-15):** provisional until signed.
- **Eval threshold (Req 9):** the selection-dimension gate bar agreed with the mother; provisional
  until signed; the selection gold set (fail-streak / returning-child / boredom-trap) is mother-signed.
- **Deploy gates (human, like 17-10):** server re-deploy (new wire fields) · Cloud Run Job + Scheduler
  creation · `child_models` owner-read rule deploy.

### Wave 0 Gaps
- [ ] `test/tutor/selection_policy_test.dart` — Req 1 anti-boredom + WHY line
- [ ] `test/tutor/across_session_memory_test.dart` — Req 2 profile-in-facts + referencing pick
- [ ] `test/tutor/microdrill_selection_test.dart` — Req 3 calibration-harness-style drill selection
- [ ] `test/tutor/remediation_arc_test.dart` — Req 4 arc state machine + win-within-N
- [ ] `test/tutor/selection_rails_property_test.dart` — Req 5 seeded-random rails property
- [ ] `test/tutor/offline_floor_test.dart` — Req 6 airplane-mode coherence
- [ ] `test/core/scoring/criterion_ema_test.dart` + `server/tests/test_criterion_ema.py` — EMA parity
- [ ] `server/tests/test_evidence.py` — Req 7 word→per-letter×criterion evidence
- [ ] `server/tests/test_compile_profiles.py` — Req 8 compile + second-letter + PII guard
- [ ] `server/tests/test_eval/test_selection_dimension.py` + `selection_gold_set.jsonl` — Req 9
- [ ] Extend `test/tutor/payload_nonpii_test.dart` + `server/tests/test_schema_forbid.py` — D-14 guards

## Security Domain

> `security_enforcement: true`, ASVS L1, `security_block_on: high`.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (unchanged) | `verify_caller` (Firebase ID token + App Check) already gates /coach; uid drives evidence keying. |
| V3 Session Management | no | Server is stateless (COPPA posture); resume state is on-device Drift. |
| V4 Access Control | yes (NEW) | Firestore `child_models/{uid}` owner-only READ (`request.auth.uid == uid`); all writes Admin-only; evidence subcollection no client access. |
| V5 Input Validation | yes | `TutorFactsIn` `extra=forbid` (server) + KEY-name PII guard (client) on the new `profile`/`evidenceDigest` fields; compiler validates evidence shape. |
| V6 Cryptography | no (none new) | Account DB already sha256-per-uid file isolation; no new crypto. |
| — Privacy / child-safety (dominant) | yes | Derived-only, fixed-vocabulary, non-PII profile + evidence; PII/token guard test (Req 8); nightly job on aggregates only; no raw strokes/PII ever cross the wire (GROUND-04/ADR-017 unchanged). |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Child model leaks PII into Firestore | Information disclosure | Fixed-vocabulary non-PII schema + PII/token guard test + `extra=forbid` on the wire; evidence is derived-only. |
| Account A reads account B's model | Elevation of privilege | uid-scoped owner-read rule (`request.auth.uid == uid`); Drift DB already per-uid file. |
| Client writes/forges child model | Tampering | Firestore client writes stay deny-all (D-13); model written only by Admin SDK (bypasses rules). |
| Agent picks an illegal/off-graph exercise | Tampering | Unchanged rails: client `isLegalSelection` + server G5/G6; policy narrows candidates but the legality re-check stays; Req 5 property tests prove 100% legal. |
| New wire field smuggles PII/geometry | Information disclosure | Server-first 422 lockstep; `extra=forbid` nested models; KEY-name guard (17-05 precedent). |
| Evidence write stalls the child (DoS-on-UX) | Denial of service (UX) | Off-critical-path BackgroundTask + batched writes; the practice path never blocks (Req 6). |

## Sources

### Primary (HIGH confidence)
- Codebase (direct read): `lib/tutor/exercise_selector_provider.dart`, `lib/tutor/tutor_facts.dart`,
  `lib/tutor/tutor_facts_builder.dart`, `lib/curriculum/curriculum_graph.dart`,
  `lib/curriculum/curriculum_graph_walker.dart`, `lib/data/app_database.dart`,
  `server/app/schema.py`, `server/app/main.py`, `server/app/auth.py`, `server/app/nodes/plan.py`,
  `server/app/curriculum.py`, `server/app/curriculum_data/generate.py`,
  `server/tests/test_eval/run_eval.py`, `firestore.rules`, `assets/curriculum/*.json`,
  `server/pyproject.toml`, `pubspec.yaml`/`pubspec.lock`.
- pub.dev API — glados 1.1.7 / flutter_glados 1.1.18 versions + SDK/analyzer constraints (verified).
- [developers.googleblog.com — Gemini 2.5 models now support implicit caching](https://developers.googleblog.com/gemini-2-5-models-now-support-implicit-caching/) — implicit caching default, min 1,024 tokens (2.5 Flash), ~75% discount.
- [Vertex AI context caching — Google Cloud Blog](https://cloud.google.com/blog/products/ai-machine-learning/vertex-ai-context-caching) — implicit vs explicit, retention <24h.
- [Schedule functions — Cloud Functions for Firebase](https://firebase.google.com/docs/functions/schedule-functions) — Python `scheduler_fn.on_schedule` (the alternative).

### Secondary (MEDIUM confidence)
- [Cloud Run Jobs vs Cloud Functions vs Cloud Scheduler — oneuptime](https://oneuptime.com/blog/post/2026-02-17-how-to-compare-cloud-run-jobs-vs-cloud-functions-vs-cloud-scheduler-for-background-tasks/view) — batch-job fit + Cloud Scheduler pricing.
- [glados — GitHub (MarcelGarus)](https://github.com/MarcelGarus/glados) / [flutter_glados — pub.dev](https://pub.dev/packages/flutter_glados) — property-testing shape.
- Gemini 2.5 Flash pricing (multiple: Future AGI, OpenRouter, Artificial Analysis) — $0.30/M in, $2.50/M out; Vertex TTFT ≈ 0.59s.

### Tertiary (LOW confidence — flagged for validation)
- KT/EMA cold-start formulation (arxiv/EDM cold-start papers) — standard recency-weighted mastery; the
  specific α/thresholds are provisional and mother-signed (A3/A4).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every runtime dependency verified installed; no new packages; server Admin
  SDK + ADC confirmed by reading `auth.py`.
- Architecture: HIGH — the policy-layer/seam/rails/persistence patterns are read directly from the
  shipped code; Phase 18 is composition over existing seams.
- Nightly job / cost-latency: MEDIUM-HIGH — GCP options and Gemini caching verified via docs/search;
  the actual measured numbers require a device+server run (A1/A6, Open Q4).
- Pitfalls: HIGH — the 422 lockstep, Riverpod-codegen-vs-Drift, deny-all-rules-vs-`.get()`, and
  Drift-list-column pitfalls are all grounded in prior-phase decisions in STATE.md.
- Pedagogy values (α, arc-N, drill content, thresholds): LOW by design — provisional, mother-signed.

**Research date:** 2026-07-11
**Valid until:** ~2026-08-10 for the codebase seams (stable); ~2026-07-25 for the Vertex pricing/caching
and GCP job claims (fast-moving cloud docs — re-verify pricing before signing the cost note).
