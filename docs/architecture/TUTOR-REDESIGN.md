# Tutor Redesign — Agent Architecture from First Principles

**Status:** DRAFT / design-in-progress · started 2026-07-01
**Why now:** the baa-isolated tutor was built incrementally and its generalization
seams are architectural, not bugs (see the 2026-07-01 UAT punch-list:
`docs/testing/UAT-FULL-2026-07-01.md` — form-blind judging F5, binary word feedback
F6, full-Arabic coaching F3, generic feedback F4, cold-start strict-fail F2).
Decision (owner, 2026-07-01): **redesign the tutor brain from first principles,
research it thoroughly, produce a design contract, then build — reusing the body.**

---

## Reuse boundary (LOCKED — owner 2026-07-01)

**Redesign (the brain — the tutor intelligence):** how it decides right/wrong,
how it stays grounded, how it coaches, how it generalizes across letters × forms ×
exercise types, its voice/register, its runtime shape, latency/cost/offline.

**Reuse (the body — validated, do NOT rewrite):**
- ML Kit Arabic recognition (works perfectly)
- LangGraph server spine on Cloud Run + the client seam (RemoteAgentBrain → AuthoredFallback floor)
- The deterministic scorer — kept as the **offline floor**
- The curriculum schema + the owner's-mother-authored content
- The app shell + parent accounts (merged 2026-07-01)

---

## Design goals — the north star  *(LOCKED — owner 2026-07-01)*

- **G1 — Real tutoring on every exercise type.** Trace, write-the-form, and
  word/sentence recognition all get a correct verdict **and** warm, specific
  coaching. No binary dead-ends, no "that's wrong" with nothing more.
- **G2 — Form- and letter-aware correctness.** The tutor knows which letter and
  which positional form is being asked and only accepts the right shape
  (medial tooth ≠ isolated bowl). Scales to all 28 letters × 4 forms **from the
  curriculum data** — no per-letter hand-coding, no per-letter prompts.
- **G3 — Grounded, always.** Never praise-on-fail, never advance-on-fail. The star
  means true mastery. The AI's freedom to coach never overrides correctness truth.
- **G4 — The mother's voice.** Warm, specific, a real teacher's patience — the
  child's working language (English) with only a sprinkle of Arabic (أحسنت). Never
  generic, never full-Arabic, never chatbot-cheerful. Her register, signed off by her.
- **G5 — Present & reliable.** Feedback feels immediate (presence budget); the
  first attempt after idle never falls to a strict scorer; graceful offline floor.
- **G6 — Affordable & private.** Cost/latency within budget; child data handled per
  the safety rules; the AI-owns-verdict + image reversals get a proper ADR + consent.
- **G7 — Explain the "why," not just the "what."** When the child is wrong, the
  tutor explains *why* in terms they understand ("your bowl is too flat, so your
  baa looks like a line, not a boat") — a diagnosis, not just a correction. This is
  what a real teacher does, and it depends on the tutor actually seeing the attempt.
- **G8 — A per-child learner model (diagnostic + personal).** The tutor analyzes
  each child's attempts over time, identifies their **specific weaknesses and
  strengths** (which letters, forms, and stroke habits they struggle with),
  **stores** them, and **loads that child's own context** at the start of every
  session — so coaching is personalized and adapts across sessions, and the tutor
  can target a child's known weak spots. This is the project's **two-timescale
  adaptation** made real: within-session (the tutor sees the session history) +
  across-session (each child's `struggles[]` / `strengths[]` recompiled between
  sessions). **Child-data safety (LOCKED Decided rule):** what's stored is
  **derived, minimal, private-by-default, parent-controlled** — learned *patterns*,
  never raw strokes or PII.
- **G9 — Teach by showing (ghost correction).** Beyond explaining the *why* (G7),
  the tutor produces a **visual correction rendered over the child's own attempt** —
  a ghost stroke showing where their line should have gone and how to fix it. This
  makes the agent's output not a verdict + words, but a **renderable teaching
  gesture**, reasoned from the child's actual path vs the target. A teacher's hand
  guiding theirs — the capability that turns "AI feedback" into "a lesson."

---

## Architecture decisions to resolve  *(the design space — research + decide)*

- **D1 — Correctness authority.** How right/wrong is decided per exercise type,
  form/letter-aware, without the scorer's false-fails and without ungrounded AI
  hallucination. (AI judge vs recalibrated scorer vs hybrid-per-type.)
- **D2 — What evidence the tutor sees.** Per exercise type, what does it consume to
  judge + coach? Rendered image? ML-Kit recognized text? scorer geometry signals?
  a mix? — this choice drives everything else.
- **D3 — Grounding mechanism.** The trust boundary + guards that *guarantee* G3
  under the new authority model.
- **D4 — Coaching + voice layer.** One unified coaching component across all
  exercise types; how the mother's register is captured, enforced, and evaluated.
- **D5 — Generalization mechanism.** How correctness + coaching scale to every
  letter/form from curriculum data, not per-letter prompts.
- **D6 — Agent shape + runtime.** Graph (analyze→plan→coach) vs a single
  multimodal judge+coach call vs something else; model choices; latency/cost/
  offline/reliability (incl. the cold-start fix).
- **D7 — Learner-model store + update (G8).** What the per-child model holds
  (`struggles[]` / `strengths[]` and at what granularity — letter, form, stroke
  habit), how it's updated (within-session live + across-session recompile), where
  it lives (Firestore per-child profile / on-device), and the privacy posture
  (derived-only, minimal, parent-controlled, no raw strokes/PII).
- **D8 — How the per-child context feeds the tutor (G7/G8).** How the loaded child
  context shapes the *why*-explanation, the coaching, and the next-exercise
  selection (target known weak spots) — **without breaking grounding (G3):** the
  context personalizes coaching and practice, it never fakes a pass.
- **D9 — Correction-output contract (G9).** How the agent produces a **renderable
  ghost-correction** — a structured path/annotation the client animates over the
  child's own strokes: computed on-device from geometry, generated by the agent, or
  a mix. (This **repurposes the superseded geo_diff geometry as a *teaching
  output*** — showing the fix — rather than as a judging input.)

---

## The redesigned architecture — a diagnosis-centric loop  *(the actual "brain" change)*

The old agent (analyze→plan→coach + a boolean image judge) was built for the
**scorer-owns-verdict** world: the judge answered "is it a baa?" and the coach wrote
words about it. The redesign is **not** that graph with better prompts — it introduces
four genuinely new concepts:

**1. A structured `Diagnosis` is the central artifact (not a verdict + a string).**
Perception produces ONE rich object, and everything else is a *view* of it:
```
Diagnosis {
  strokes: [ { index, label, present, matchesTargetForm, findings:[flat|too-short|curved|…],
               dot:{present,count,side}, severity, confidence } ],
  isCorrectForm: bool,        # for the ASKED positional form, not "is it the letter"
  overallConfidence: 0..1,
  defectTags: [ "shallow_bowl", "dot_above", "tooth_too_big" ]   # curriculum-vocabulary
}
```
The **verdict**, the **why-explanation** (G7), the **coaching line** (G4), and the
**ghost-correction** (G9) are all *derived from the same Diagnosis*. Because they share
one source of truth, they **structurally cannot contradict each other** — that is the
real grounding fix, not a faithfulness checker bolted on after.

**2. The verdict is a grounded FUNCTION, not the model's say-so.** Under AI-owns-verdict,
"faithful to the verdict" is circular (the model can't disagree with itself). So the
verdict = `f(Diagnosis.findings) ∧ geometry-cross-check`: the deterministic scorer/geometry
becomes an **independent cross-check**, not the boss. Model says pass but geometry says the
bowl is a flat line → **hold** (needsWork), never a lucky pass. The scorer stops being the
false-failing judge and becomes the *disagreement sensor* + offline floor. This is the
honest answer to D3 the contract left circular.

**3. The per-child `LearnerModel` is a real subsystem (the "memory"), not a field.**
```
LearnerModel(childId) {
  skills:  { "baa.medial": {attempts, cleanReps, struggle 0..1, lastSeen}, … },
  habits:  { "dropsDot": 0.4, "shallowBowl": 0.7, "leftToRight": 0.2 },   # cross-letter tendencies
}
```
It is *written by* each Diagnosis (within-session live + across-session recompile), and it
*reads into* three places: **perception** (tell the diagnosis what this child tends to get
wrong), **response** (coach the habit, not just this attempt: "your dot slipped above again —
remember baa's dot lives underneath"), and **selection** (target weak spots). Derived
patterns only — never raw strokes (COPPA/G6). This is the biggest missing piece and what
makes the tutor *personal* (G8) instead of stateless.

**4. Re-decompose the loop around perception, not planning.**
```
OLD:  analyze ──▶ plan ──▶ coach                     (scorer owned truth; agent wrote words)
NEW:  perceive ─▶ diagnose ─▶ ground+verdict ─▶ personalize ─▶ respond ─▶ adapt
        │            │             │                  │            │          │
      load child   ONE           verdict = f(findings) update    coach+why+   pick next
      context +    multimodal    ∧ geometry cross-    LearnerModel ghost from  (target weak
      form rubric  Diagnosis     check (no circularity)          one Diagnosis  spots)
```
This still lives inside LangGraph (reuse the runtime), still keyless-Vertex, still has the
offline floor — but the **nodes, the state object, and the data flow are new**. That is the
architecture change you weren't seeing.

**What this changes vs. the AI-SPEC as written:** the AI-SPEC's §4 "collapse judge+coach"
becomes the `diagnose→respond` span over a shared `Diagnosis`; its `Verdict` model grows into
the `Diagnosis` above; D3 grounding gets the geometry-cross-check answer; D7/D8 (the learner
model) get a real schema + read/write points instead of a paragraph. The eval (§5) is
unchanged — it still gates the same behaviors.

---

## Process

1. **Design goals** — owner refines G1–G9 (this doc). **Locked 2026-07-01.**
2. **Research** — thorough investigation of the real unknowns (D1–D3, D5, D6, D9) —
   how grounded LLM handwriting/education tutors are actually built — and D4 with
   the owner's mother. Options + tradeoffs, evidence-backed.
3. **Design contract** — the locked tutor architecture + agent design + eval plan,
   reviewed by the owner (and his mother for pedagogy/voice) before any code.
4. **Build** — clean phases on top of the reused body.

*Deferred / separate tracks:* the alif unit fix; the geo_diff approach as a *judge*
(superseded — but its geometry is reused for G9's correction output); letters beyond
the first proof (decide breadth during design).

---

## Future ideas — product-layer  *(great, but NOT agent-core; parked so we don't lose them)*

Owner's call (2026-07-01): these live *around* the agent, not in it — revisit after
the agent redesign lands. A few are agent-adjacent and may fall out of G7/G8 for free.

- **Weekly "teacher's note" to the parent** — a warm, mother's-voice narrative from
  the learner model (not a metrics dashboard). Uses the merged parent accounts.
- **Anchor letters to the child's family words** (baa → بابا / dad, باب / door) — the
  heritage-learning bridge from heard-at-home to written.
- **Handwriting portfolio** — the child's real best letters improving over time.
- **Session opens on the child's weak spot** — learner-model-driven warm-up *[agent-adjacent]*.
- **Read the room** — frustration-sensing + de-escalation when a child fails repeatedly *[agent-adjacent]*.
- **Watch the hand** — stroke order/direction diagnosis, not just final shape *[agent-adjacent; may fold into the correctness model]*.
- **Voice-first coaching** for pre-literate children *[constraint — affects G4/G5, not a feature]*.
- **Left-handed RTL ergonomics; motor-difference / dysgraphia accommodations** *[constraints]*.
- **Handle-with-care (child data):** family voice recordings, storing writing images — lovely, but need consent + minimization first.
