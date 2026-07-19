# Phase 25: Trusted content — the seen-letters wall + the mother's confirmation - Context

**Gathered:** 2026-07-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Make content mechanically **trustworthy** — two legs, both scoped here, nothing else.

**Leg 1 — The wall.** Enforce the owner's rule (*a question may only demand letters
the child has already seen* — D-12 / QP-07) at four layers instead of aspirationally:
- **L0 — label.** Generate a `letters[]` for every word/inflection any exercise
  references (the mother-reviewable diff).
- **L1 — lint.** The learned-letters lint holds **every** live letter — the draft
  exemption is removed; the 34 audited cards are re-pointed / removed / excepted; the
  baa allowlist is reduced to mother-approved exceptions only.
- **L2 — seeder.** `seed_curriculum_v2.py` refuses violating content (closes the
  Firestore-first bypass — nothing the bundle lint would refuse can reach prod).
- **L3 — runtime guard.** The walker/selector never presents an illegal card even if
  bad data ships; the star always stays reachable; every firing is logged loudly.

**Leg 2 — The confirmation.** Every owner-directed change since the mother's last
sign-off goes back to her as ONE packet; her verdicts are ingested (`signedOff` flips
where she confirms; rejects are restored or re-worked to her instruction).

**Explicitly NOT in this phase** (belongs to 26–29): the entry-model decision, launcher
icon, scorer re-tighten (26); server un-fencing + promoting the remaining 24 letters
(27); cross-letter selection + parent dashboard (28); final release hardening + ledger
(29). Server stays **baa-only** this phase.
</domain>

<decisions>
## Implementation Decisions

### L3 — runtime-guard degradation (the roadmap's reserved discuss-phase decision)
- **D-01: Behavior = SKIP.** When an illegal card (one demanding an unseen letter)
  reaches runtime, the guard drops it and the walker advances to the next legal node.
  Owner chose "the simplest option."
- **D-02: Mandatory star-reachability backstop.** Skipping must **never** strand the
  mastery star. The common case (illegal card is enrichment, or its essential node has
  another legal card) is a clean skip. The one case needing care — an illegal card on an
  **essential** node with no other legal path — must still leave a route to mastery
  (this is a hard invariant from the roadmap + Decided "star must stay reachable", NOT
  waivable by the simplicity preference). Success criterion 3's live-path test proves
  the star stays reachable.
- **D-03: Every firing logged loudly** (e.g. `L3 guard: <id> illegal (demands <letter>),
  skipped`) — no silent swallow.

### L1 / L2 — the wall's enforcement
- **D-04: Draft exemption removed.** The lint enforces **every** live letter regardless
  of `signedOff` (today it only enforces signed letters and merely "acknowledges"
  unsigned ones — `learned_letters_lint_test.dart`). After this phase, `signedOff` no
  longer controls enforcement.
- **D-05: `signedOff` is decoupled from lint enforcement.** It now means only "the
  mother has confirmed THIS content." A letter can be legal-and-enforced while
  `signedOff:false` (e.g. taa, thaa).
- **D-06: L2 seeder gains a learned-letters refusal.** `seed_curriculum_v2.py` currently
  validates payload shape only; add the learned-letters check so violating content is
  refused before the first Firestore write (proven by a crafted-fixture test —
  criterion 2).

### 34-card disposition (the 2026-07-19 audit worklist)
- **D-07: Default = RE-POINT, else REMOVE, else EXCEPT.** Prefer relabeling the card's
  word to one using only already-learned letters (keeps the exercise). If no
  learned-letter word preserves the teaching point, remove the card from the live graph.
  Keep a reaching-ahead card as-is (EXCEPT) **only** with the mother's explicit approval.
- **D-08: Owner triages now; mother reviews the diff.** The owner (relaying the model's
  drafts) does the re-point/remove triage so the build goes clean and the audit hits
  zero immediately (criteria 1–3 don't wait on her). The mother reviews the **full
  re-point diff** (every word that changed) in her packet and must approve every
  EXCEPTION.
- **D-09: The 4 current baa exceptions are NOT mother-approved yet.**
  `baa.fillBlank.adjective`, `baa.transformWord.dual`, `baa.transformWord.plural`,
  `baa.transformWord.opposite` are "owner-approved" from device UAT (2026-07-18). Each
  must become mother-approved in the packet, or be re-pointed/removed.
- **D-10: taa + thaa are triaged now too** (consequence of D-04). Their violating cards
  get re-pointed/removed/excepted in this phase, but the **letters stay `signedOff:false`**
  — signing taa/thaa as letters is Phase 27's batch work, not this phase.

### The mother's packet (Leg 2)
- **D-11: Delivery = live walkthrough, owner captures verdicts.** The mother is
  physically next to the owner. The packet is a walkthrough-ready checklist (one row per
  change, verdict + optional rework note captured inline); the owner reads each item and
  records confirm / reject / rework on the spot.
- **D-12: Wall lands non-blocking; ingestion is same-session.** L0–L3 + the zero-violation
  audit + packet assembly complete without waiting for her. Because she's next to the
  owner, verdict ingestion (flip `signedOff`, restore/rework rejects) runs in-session —
  so criterion 4 (verdicts recorded, `signedOff` matches her answers) can be satisfied
  **in-phase**. Build the async-ingestion path anyway so it's robust if she's ever
  unavailable, but the happy path is same-session.
- **D-13: Packet scope = every owner-directed change since her last sign-off:**
  minCleanReps=1 across all graphs (including baa's signed spec), both buildSentence
  removals (baa/taa/thaa), the alif letter-level shrink + the new
  `alif.writeLetter.fromPicture` draft card, Lane-B image re-points / feedback
  rewordings, the full re-point diff (D-08), and the 4 baa exceptions (D-09). Each item
  carries an inline `_review` note.

### baa's stale-signed flag + the new alif card
- **D-14: baa — flip `signedOff:false` during packet assembly, reconfirm live → true.**
  baa.json is `signedOff:true` but its live content diverged from what she signed
  (minCleanReps forced 1 vs her signed 3-for-writing/tracing spec — 15-07; both
  buildSentence cards removed; 4 exceptions). Set it false while assembling the packet
  (honest state), list every divergence, then flip back to true per item she confirms;
  rework what she rejects. The "false" window is minutes (she's next to the owner). This
  is **Claude's discretion pick** — owner said "do what you think is best." Chosen for
  mechanical truthfulness (the flag never claims "confirmed" while content isn't), which
  is the phase's whole thesis. Safe because enforcement no longer depends on the flag (D-04/D-05).
- **D-15: New alif card — author as draft, show her live, promote on approval.**
  `alif.writeLetter.fromPicture` does not exist yet. Author it now as `signedOff:false`
  (draft) so she sees the REAL card in context during the walkthrough; promote it to
  live-confirmed only if she approves.

### Claude's Discretion
- **D-14** (baa flag behavior) — owner delegated ("do what you think is best"); recorded above.
- Packet checklist FORMAT (exact file/columns) — any clear per-item confirm/reject/rework
  structure the owner can read aloud and mark; not owner-specified.
- The precise L3 seam (filter-in-selector vs guard-in-walker) — implementation detail for
  the planner, constrained by D-01/D-02/D-03.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase spec & requirements
- `.planning/ROADMAP.md` §"Phase 25" (≈ lines 1058–1087) — the four legs (L0–L3 + the
  confirmation) and the 4 success criteria. Research hint: **no** — mechanism is known.
- `.planning/REQUIREMENTS.md` — QP-07 / D-12 (universal learned-letters bar), CUR-01
  (curriculum authority = the owner's mother).

### The wall — lint, audit, seeder, promoter (L0–L2)
- `test/curriculum/learned_letters_lint_test.dart` — **L1.** The lint today: signed =
  enforced (+ 4-card baa allowlist), unsigned = acknowledged (the draft exemption to
  remove). `_discoverUnitGraphs` + the `signedOff` dispatch are what change.
- `tools/content/validate.py` + `tools/content/validation_report.md` — the audit
  machinery ("content demanding unlearned letters"); regenerate to reproduce the
  34-card worklist and to gate the build.
- `tools/firebase/seed_curriculum_v2.py` — **L2.** Validates payload shape only today;
  add the learned-letters refusal (criterion 2's crafted-fixture test targets this).
- `tools/content/promote_letter.py` + `tools/content/README.md` — draft→live promoter
  (forces `signedOff:false`); the authoring path for the new alif draft card (D-15).

### The wall — L3 runtime guard surfaces
- `lib/features/letter_unit/letter_unit_controller.dart` — the mastery gate
  (`recordMasteryIfMet`), the baa-hardcoded `_presentedExerciseIds()`, and the silent
  `catch (_) { return false; }` (≈ line 575) that must become loud (D-03).
- `lib/tutor/exercise_selector_provider.dart` — the selector; per-letter graph load; the
  natural home for the illegal-card filter.
- `lib/curriculum/` — `CurriculumGraph` / `CurriculumGraphWalker` (`nextForward`,
  `remediateOneTier`) and `mastery_condition.dart` (`isMasteryMet` over essential 70/30
  nodes) — the star-reachability invariant D-02 must preserve.

### Content assets under enforcement
- `assets/curriculum/exercises.json` (the cards + `letters[]`),
  `assets/curriculum/letters.json` (`introOrder` — the learned-set order),
  `assets/curriculum/curriculum_graph.json` (canonical baa, server source),
  `assets/curriculum/graphs/{alif,baa,taa,thaa}.json` (the 4 live per-letter graphs).

### The confirmation packet — source material & precedents
- `.planning/finalization/FINDINGS.md` + `.planning/finalization/README.md` — the
  predecessor whole-project audit and owner-locked decisions (onboarding stays as-is;
  known-red tests never re-baked; the demo content state that produced the packet items).
- `.planning/phases/15-build-dynamic-grounded-exercise-selection-on-baa/15-HUMAN-UAT.md`
  — baa's mother-signed graph (writing/tracing = 3 clean reps) — the spec minCleanReps=1
  diverges from.
- `.planning/phases/19-question-presentation-overhaul-every-question-self-explanato/19-REVIEW-PACKET.md`
  + `19-HUMAN-UAT.md` — the mother's card-review format precedent (packet structure to mirror).
- `docs/curriculum/drafts/` — 18.1 draft sets/graphs/packets for letters 4–28 (source of
  taa/thaa live content; context, not this phase's promotion target).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`CurriculumGraphWalker` (`lib/curriculum/`)** — `nextForward` is exactly "advance to
  the next legal node" for D-01's skip. `remediateOneTier` + `isMasteryMet` are the
  levers for the D-02 star-reachability backstop.
- **`validate.py`** already computes unlearned-letter violations — reuse/extend it to
  produce the audit report AND to feed a build gate + the L2 seeder refusal.
- **`promote_letter.py`** — idempotent, letter-generic, forces `signedOff:false`; the
  clean path to author the new alif draft card (D-15) and to re-derive graphs after
  re-points/removes.
- **`learned_letters_lint_test.dart` `_discoverUnitGraphs`** — already visits every live
  graph (baa + graphs/*.json) with full coverage assertion; only the `signedOff` dispatch
  branch needs to change (enforce all).

### Established Patterns
- **`signedOff` currently gates enforcement; this phase decouples it** (D-04/D-05) — the
  single biggest behavioral change; verify no other code reads `signedOff` as an
  enforcement switch.
- **Firestore-first content path** (memory: letters-firestore-first) — the seeder is the
  write path and the device reads Firestore-first; a stale/bad seed reaches the child even
  if the bundle lint passes. That's exactly why L2 (seeder refusal) AND L3 (runtime guard)
  both exist — the bundle lint alone is not sufficient.
- **Live-path test mandate** (memories: tests-pin-progression-not-presentation;
  phase15-dynamic-selection-was-dead-code) — criterion 3's guard test MUST drive the real
  data + selection path (seed an illegal card via the data path, prove the walker never
  presents it, prove the star still fires), never a mock.
- **Known-red tests are never "fixed"/re-baked** (memory: golden-tests-font-drift) —
  alif_reference cluster, font-drift goldens; keep them red.

### Integration Points
- L3 guard sits in the selector→walker path
  (`exercise_selector_provider` → `CurriculumGraphWalker`); the star gate is
  `recordMasteryIfMet` in `letter_unit_controller`.
- L2 seeder writes Firestore; the client reads Firestore-first — so L2 and L3 defend
  different surfaces of the same bypass.
- **Server is baa-only this phase.** If the mother restores baa's minCleanReps to 3
  (rejecting the demo's =1), check whether the baa graph change requires a Cloud Run
  redeploy — and if so, that redeploy needs **fresh explicit owner authorization**
  (memory: tutor-server-deployed; each prod deploy is owner-gated). Flag for the planner;
  do not assume a redeploy is free.
</code_context>

<specifics>
## Specific Ideas

- Owner steered terse and toward simplicity: **"the simplest option"** for L3 (→ skip),
  **"the fastest option"** for delivery (→ live walkthrough), and confirmed the mother is
  **"immediately when it's done, next to me"** — so in-session verdict capture is the
  real workflow, not an async doc.
- baa packet items are concrete and known: minCleanReps=1 (vs her signed 3 for
  writing/tracing), both buildSentence removals, and the 4 exceptions listed in D-09.
- The new alif card is `alif.writeLetter.fromPicture` — mirror the existing
  `baa.writeLetter.fromPicture` / `taa.writeLetter.fromPicture` shape; alif stays
  letter-level only (memory: alif is a child's FIRST letter — no sentence work).
</specifics>

<deferred>
## Deferred Ideas

- **Server un-fencing + per-letter tutor data + promoting the remaining 24 letters in
  mother-signed batches** → Phase 27 (the wall + the confirmation cadence built here are
  its prerequisites).
- **Entry-model decision, Qalam launcher icon, scorer tcc/tcw re-tighten, the two
  tutor-feedback debts, the Android device pass, the 2.0.1 release cut** → Phase 26.
- **Cross-letter selection, next-day planner, parent strengths/struggles dashboard** →
  Phase 28.
- **Final airplane-mode/offline hardening + release audit + the debt ledger to zero
  (incl. 18-11 residue, eval-trust legs)** → Phase 29.
- If baa's re-confirmation changes its graph and forces a server redeploy, that redeploy
  (owner-authorized) is the tail of this phase or a Phase-26 item — noted in code_context,
  not silently absorbed.

### Reviewed Todos (not folded)
None — the todo list is empty (0 pending).
</deferred>

---

*Phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat*
*Context gathered: 2026-07-19*
