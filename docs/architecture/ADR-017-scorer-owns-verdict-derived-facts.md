# ADR-017: The deterministic on-device scorer owns pass/fail; only derived facts cross the wire

**Status:** ACCEPTED (owner, 2026-07-01 — the D-A decision date). The Decision §5
amendments (kinematics descoped, position folded, demo scores unsigned forms) are
**OWNER-CONFIRMED 2026-07-05** at the `/gsd-plan-phase 17` checkpoint and recorded in
[`17-CONTEXT.md`](../../.planning/phases/17-build-stroke-aware-coaching-on-device-geo-diff-to-coach/17-CONTEXT.md) § Decisions.
**Supersedes:** the Phase-17.1 *AI-owns-pass/fail* owner directive — the `strokeImage` →
`image_judge` short-circuit that let a cloud VLM own the baa verdict. That was a reaction to a
*mis-calibrated* scorer, not evidence the LLM should judge; the research (below) is explicit that
VLMs must not own fine-grained handwriting/dot judgment. This ADR also **supersedes** the
`14-AI-SPEC.md` §1/§4 *"AI owns the verdict"* stance.
**Amends:** **GROUND-02** — *softened, not reversed to the pre-17.1 posture*. A **derived,
point-free** geometry diff + per-criterion result + word facts cross the wire so the coach can name
*this* child's specific error; **raw strokes and rendered images NEVER do**. The off-device
child-data surface shrinks to derived scalars/strings only.
**Affects:** [`server/app/schema.py`](../../server/app/schema.py) (the `TutorFactsIn` wire contract
+ the retired `strokeImage`/`CoachOut.verdict` fields), [`server/app/main.py`](../../server/app/main.py)
(the deleted image-judge short-circuit), the deleted `server/app/image_judge.py`, and the client
`TutorFacts`/`TutorDecision`/`WriteSurface` cutover (17-07). Closes roadmap requirement **GROUND-04**
(with 17-07 + 17-08 + this ADR + the single Cloud Run re-deploy) and satisfies roadmap success
criterion 4 (the softened GROUND-02 reversal + the verdict-authority decision recorded as one ADR).

---

## Context

Phase 17.1 (a hotfix, not a planned phase) handed the baa pass/fail verdict to a cloud VLM: the
client rendered the child's strokes to a PNG (`strokeImage`), posted it, and `image_judge.py`
returned a `CoachOut.verdict` the client honored *over* the deterministic scorer. It was a reaction
to a scorer that false-failed correct writing (a *calibration* bug), and it re-opened a real
child-data cost: a **rendered image of a child's handwriting left the device** — a GROUND-01/GROUND-02
consent debt with no onboarding copy behind it.

Two independent evidence bases then landed:

- **Clean-room deep research** (2026-07-01, [`TUTOR-RESEARCH-FINDINGS.md`](TUTOR-RESEARCH-FINDINGS.md),
  112 agents / 11 verified findings): the pass/fail verdict should be owned by a *deterministic,
  online, stroke-based, multi-criteria* scorer with *soft thresholds* — **not** an LLM/VLM, **not**
  a flattened-image classifier. VLMs fail fine-grained counting (40–47% wrong on 1–20 objects) and
  it is a fundamental, unfixed limitation (F9/F10). The existing scorer already had the right *bones*
  (spatial dot classification, advisory ML-Kit identity, firm count/order); it lacked a DTW
  shape-match to the reference and soft 3-zone thresholds — both now added. It is an *upgrade*, not a
  rewrite (F1–F11).
- **The stroke-aware spike** (2026-06-30, [`SPIKE-FINDINGS.md`](../../.planning/spikes/SPIKE-FINDINGS.md),
  5 spikes / ~375 live Vertex calls): a **precomputed geometry diff** the model only verbalizes was
  accurate (0.87), specific (0.87), and barely hallucinated (0.07); the **multimodal image was the
  worst arm** (0.20 hallucination, ~4× payload, slowest) — the intuitively-richest input lost.
  Grounding held in every stroke-aware arm (0 advance-on-fail, 0 praise-on-fail, even adversarially).
  A precondition surfaced: the eval must move from substring → **semantic** faithfulness before the
  gate can be trusted (delivered in 17-04).

The load-bearing decision for the whole phase is therefore *how the agent decides pass/fail*. This
ADR records it.

---

## Decision

### 1. The deterministic on-device scorer OWNS pass/fail (D-A)

Pass/fail (and the mastery star) is owned by the **on-device, online, stroke-based, per-form,
multi-criteria** scorer with **soft 3-zone thresholds** (certainly-correct / fuzzy / certainly-wrong,
continuous [0,1]). The scorer is pure Dart, runs on-device, is **instant, offline, $0, and private**
(no child data leaves the device to reach a verdict). The LLM **only explains and coaches** from the
scorer's structured per-criterion output (D-B) — it never sees a blank verdict to invent, and it can
never overturn the frozen verdict. **Grounding holds by construction.**

Evidence: VLMs must not own fine-grained handwriting/dot judgment — F1 (online stroke-trajectory +
5 explicit criteria, validated on children incl. Arabic), F2 (soft/graded pass-fail to tolerate child
motor variation), F4 (DTW distance-from-reference is a validated, tolerance-aware letter-form metric),
F9 (LLM/VLM must NOT own dot counting — 40–47% wrong on 1–20 objects), F10 (that counting failure is
a fundamental spatial-semantic deficiency, unfixed by current hallucination mitigation).

### 2. The wire contract — only DERIVED facts cross (GROUND-04)

What crosses the client→server boundary is a strict, non-PII, **derived** superset:
`strokeDiff` + `criteria[]{criterion, zone, score}` + `weakestCriterion` + `expectedWord` /
`writtenWord` — all **derived scalars/strings**, never raw stroke points, `Offset`s, an image, or a
nickname. Both DTOs are `extra="forbid"` (client `TutorFacts` ⇄ server `TutorFactsIn`), the field
names are **byte-for-byte mirrors**, and any stray key 422s at both the DTO and the live `/coach`
boundary. The guard tests that pin this:
[`test/tutor/payload_nonpii_test.dart`](../../test/tutor/payload_nonpii_test.dart) (client whitelist ∪
nested-key sets + the token regex), [`server/tests/test_payload_nonpii.py`](../../server/tests/test_payload_nonpii.py)
(server FORBIDDEN_KEYS + the DTO 422s), [`server/tests/test_criteria_contract.py`](../../server/tests/test_criteria_contract.py)
(the additive criteria DTO — defaults + 422-on-extras), and the client mirror-set assertion in
[`test/tutor/tutor_facts_builder_test.dart`](../../test/tutor/tutor_facts_builder_test.dart)
(`toJson().keys.toSet()` == the whitelist). The additive server-first / removal client-first ordering
(RESEARCH Pattern 3) kept a zero-422 window across both cutovers (server contract 17-05, client mirror
17-06; image removal client 17-07, server 17-08).

### 3. `strokeImage` + `CoachOut.verdict` + `image_judge.py` — RETIRED AND DELETED (not demoted)

CONTEXT increment 6 left open the option of keeping the image path as an *advisory corroborator*. We
**deleted** it instead — from both wire sides and from the tree:

- client (17-07): the `onStrokeImage` callback, the baa-only PNG render (`_renderStrokesToBase64Png`),
  the `TutorFacts.strokeImage` field/param/emission, and the `TutorDecision.verdict` plumbing;
- server (17-08): the `if facts_in.strokeImage:` → `image_judge` short-circuit in `main.py`, the
  `TutorFactsIn` rendered-image field, the `CoachOut` AI-verdict field, and **`server/app/image_judge.py`
  is `git rm`-deleted**; the retired image key joins `FORBIDDEN_KEYS`, so a stale client that still
  posts it now **422s BY DESIGN** — the 422 is the *structural proof* the surface shrank.

**Why deletion, not demotion:** the image was the **worst spike arm** (0.20 hallucination) and an
advisory image call would keep a rendered image of child handwriting leaving the device — re-opening
the exact GROUND-02 consent reversal this ADR closes. **Net privacy improvement:** the GROUND-01/02
consent debt from 17.1 shrinks from *"a rendered image leaves the device"* to *"a derived,
point-free diff leaves the device"* — the residual flow the consent copy (below) must still cover.

### 4. Thresholds are DATA, not code (D-D)

The soft-band thresholds ship as **provisional synthetic** values for the demo (a single shared
band, per-form/per-preset bands not yet diverged). The **production gate is the owner's-mother-labelled
calibration** on real child samples (fixed thresholds tuned on adult data false-fail developing
children ~15%, F8/F11). The per-form calibration harness (17-09) is the mom-facing tuning artifact:
it prints a per letter × form FN/FP confusion table + a **PROVISIONAL, print-only** threshold-fit
report and **never mutates** `Tolerances`/`letters.json`. **Per-child adaptive bands** are deferred to
the G8 learner model.

### 5. OWNER-CONFIRMED amendments (2026-07-05) — kinematics descoped, position folded, unsigned forms scored

Recorded in `17-CONTEXT.md` § Decisions (the D-C amendment + A2), **OWNER-CONFIRMED 2026-07-05**:

- **`kinematics` is DESCOPED this phase.** `StrokeCanvas` captures no timestamps, so speed/rhythm
  cannot be measured — and must **never** be faked from point spacing. FOLLOW-UP (recorded): add
  `PointerEvent.timeStamp` capture in a later phase so the `kinematics` criterion can join with real
  data.
- **Position is folded into the firm dot-placement check** (Open Q3) — it is not a separate scored
  criterion.
- **The five shipped criteria are: shape / direction / strokeOrder / strokeCount / dot.** (The
  research's sixth, `kinematics`, is the descoped one above.)
- **The demo scores unsigned baa initial/medial/final forms (A2).** Those form references render in
  the guides already (precedent `ba3923c`) but carry `signedOff: false`. Scoring them unsigned is the
  **owner-confirmed demo default**; the **mother's per-form sign-off remains the PRODUCTION gate**
  (queued in [`17-HUMAN-UAT.md`](../../.planning/phases/17-build-stroke-aware-coaching-on-device-geo-diff-to-coach/17-HUMAN-UAT.md)).

**Consent copy (pre-production, out of this phase's scope):** the residual derived-diff data flow
(§3) still needs onboarding/consent copy stating that handwriting-derived facts are processed by an
AI service — owner/legal work, listed as a HUMAN-UAT item, not shipped here.

---

## Consequences

**Good**
- The verdict is instant, offline, $0, and un-overrulable; a cold/slow/offline server affects only
  the coaching *words*, never the pass/fail or the star (GROUND-01 restored; UAT F2 flash-then-overwrite
  structurally impossible — nothing is applied twice).
- The off-device child-data surface is the smallest it has been since 17.1: a derived, point-free diff,
  no image, no raw strokes, no PII — a net COPPA/consent win.
- Form-blindness (UAT F5) is fixed *at the scorer*: an isolated bowl offered for the medial/final slot
  fails on shape (`certainlyWrong`), asserted to zero in the Dart calibration harness (17-09) — moved
  out of the LLM eval, where D-A says it belongs.
- Grounding is guaranteed by construction, not by a prompt: the coach reads a frozen verdict and cannot
  re-judge it; the semantic faithfulness gate (17-04) + the two-arm baseline back it with evidence.

**Bad / accepted costs**
- The scorer must be **calibrated on real child data** before production — a synthetic demo band is
  a floor, not a ceiling (D-D; the mom-labelling gate is on the ledger).
- `kinematics` ships unscored until timestamp capture lands (the follow-up above).
- A stale client that still posts `strokeImage` 422s — accepted: the only live client is the same-phase
  demo build, cut over first (removal-ordering held; risk window nil).
- The residual derived-diff flow still owes consent copy before production (owner/legal).

## Alternatives considered

- **Keep the image judge as an advisory corroborator** (CONTEXT increment 6's open option) — rejected:
  worst spike arm at 0.20 hallucination, and any surviving image call re-opens the consent reversal.
- **LLM/VLM owns pass/fail** (the 17.1 directive) — rejected on F9/F10 + the spike's image result.
- **`points` (raw stroke coordinates) cross the wire** (the spike's fallback representation) — rejected:
  the derived `geo_diff` matched it on accuracy/specificity at a lower hallucination + privacy surface,
  so raw points are unnecessary and carry more child data.

## Revisit triggers

- Timestamp capture lands → add the `kinematics` criterion with real data.
- The mother's calibration shifts the bands materially → adopt fitted `tcc`/`tcw` as `letters.json`
  tolerance overrides; wire per-child adaptive bands to the G8 learner model.
- Per-form references for the other 25 letters get signed → generalize form-awareness beyond
  alif/baa/taa (D-E).

## Seam impact

- `TutorFacts` / `TutorFactsIn` carry the derived criteria + word facts; `TutorDecision` no longer
  carries a `verdict`; `RemoteAgentBrain._parseCoachOut` reads only `toolName` + args and tolerates an
  absent verdict key. `WriteSurface`/`ExerciseScaffold` apply the scorer verdict unconditionally and
  synchronously; the brain call can only set/clear the tutor-owned coaching line.
- `AuthoredFallback` (client-side, mother-signed) stays the offline coaching floor; server unreachable
  → a grounded authored line, the trace loop never blocks.
