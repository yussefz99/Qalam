# Tutor Research — Findings & Scorer Design

**Clean-room deep research, 2026-07-01** (no repo context; academic + industry
literature; adversarially fact-checked). Full run: 112 agents, 11 verified findings.
This is the evidence base for the Phase-17 scorer redesign. Companion docs:
`TUTOR-REDESIGN.md` (goals/architecture), `17-AI-SPEC.md` (contract).

---

## Bottom line — how the deterministic scorer SHOULD be

**The pass/fail verdict is owned by a deterministic, online, stroke-based,
multi-criteria scorer with soft thresholds — NOT by an LLM/VLM, NOT by a
flattened-image classifier.** The LLM only explains and coaches from the scorer's
output. Concretely, the scorer should be:

1. **Online & stroke-based** — judge the child's *ordered pen strokes* (which we
   already capture), not a final raster image. Recovering stroke order/direction
   from an image is ill-posed; online capture gives it for free. *(F1, F5)*
2. **Multi-criteria, not one score** — evaluate five explicit criteria a teacher
   uses: **shape · direction · stroke order · position · kinematics**, plus an
   explicit **dot** check. *(F1)*
3. **Soft 3-zone thresholds** — per criterion: *certainly-correct / fuzzy /
   certainly-wrong* with a continuous [0,1] score. The tolerant fuzzy middle is
   what stops a shaky-but-correct child being false-failed. *(F2)*
4. **Shape = DTW distance to the per-form reference exemplar** — a validated,
   tolerance-aware letter-form metric that separates good from poor child writers
   independent of speed. **✅ built:** `lib/core/scoring/shape_match.dart`. *(F4)*
5. **Dots judged explicitly (count + above/below), spatially** — i'jam is
   identity-bearing (a dot above baa is a different letter). Do NOT use naive
   stroke-count (children merge dots into 1 vs 3 strokes) — use a spatial dot
   detector. **Partly present:** `letter_scorer._classifyChildDots` already
   classifies dots by spatial extent, not point count. *(F7)*
6. **Corroborating identity signal, advisory only** — an offline CNN / ML Kit is
   a good "*which letter did they draw*" check (~96.8% on 28 isolated Arabic
   letters) but is form-blind and must never own the verdict. **Present:** the
   scorer's advisory ML-Kit identity gate already does exactly this. *(F6)*
7. **Fuse, don't trust one model** — the strongest system combines a dynamic
   (temporal), a geometric, and a visual view. Our DTW (geometric+temporal) +
   spatial-dot + advisory-CNN is a pragmatic version of this. *(F3)*
8. **Thresholds calibrated on real CHILD samples, and personalized** — fixed
   thresholds tuned on adult data false-fail atypical/developing children (~15%
   miss). Calibrate from the owner's-mother-labelled child set; make the bands
   **per-child adaptive** over time (ties to the G8 learner model). *(F8, F11)*
9. **The LLM/VLM must NOT own pass/fail or dot counting** — VLMs fail
   fine-grained counting (40–47% wrong on 1–20 objects) and this is a fundamental,
   unfixed limitation. The LLM receives the scorer's per-criterion result and only
   writes the warm "why" + coaching. *(F9, F10)*

**Net:** the existing scorer already has the right *bones* (spatial dot
classification, advisory ML-Kit identity, firm count/order). What it lacked was
(a) the **DTW shape-match to the reference** — now added — and (b) **soft 3-zone
thresholds** replacing hard predicates. The redesign is an *upgrade*, not a rewrite.

---

## Verified findings (cited)

| # | Finding | Conf. | Source |
|---|---|---|---|
| F1 | Use **online stroke-trajectory** + 5 explicit criteria (shape, direction, stroke order, position, kinematics) — a validated children's tutor (ages 3–8, incl. Arabic). | high | Hamdi et al. 2022, *MTAP* 81:43411 (arxiv 2010.06693) |
| F2 | Pass/fail must be **soft/graded** — twin thresholds → 3 zones (CC/fuzzy/CW), continuous [0,1], explicitly to tolerate child motor variation. | high | Hamdi et al. 2022 |
| F3 | **Fuse** a dynamic (Beta-Elliptic), a geometric (Fourier), and a visual (CNN) model — don't trust one. | high | Hamdi et al. 2022 |
| F4 | **DTW distance-from-reference** is a validated, tolerance-aware letter-form metric (separates good/poor child writers). | high | Guest 2004, *Med Eng Phys* (pubmed 18407363) |
| F5 | Image-only (offline) pays a big accuracy/complexity cost to approximate what online capture gives free; stroke recovery from raster is ill-posed. | high | ar5iv 2105.11559 |
| F6 | An offline CNN gives a strong "which letter" identity (~96.8% / 28 isolated Arabic classes) — corroborating only; form-blind. | high | Sci. Reports 2025 (s41598-025-26658-x) |
| F7 | **i'jam dots must be judged explicitly** (count + above/below); naive stroke-count is confounded in children (dots merge 1↔3 strokes) — use spatial detection. | high | Springer 2023 (s44230-023-00024-4); arXiv 2211.02119 |
| F8 | Children's Arabic handwriting is **materially harder** than adults' — must tune/tolerance-set on real labelled **child** data or it false-fails. | high | Springer 2023 (s44230-023-00024-4) |
| F9 | The **LLM/VLM must NOT own dot counting / enumeration** — best VLMs 40–47% wrong counting 1–20 objects. | high | arXiv 2510.04401 |
| F10 | VLM counting failure is a **fundamental** spatial-semantic deficiency, unfixed by current hallucination-mitigation. | med | arXiv 2603.10978 |
| F11 | Fixed thresholds false-negative on developmentally-varying children (~15% miss); remedy = **personalized/adaptive** thresholds. | med | MDPI Informatics 10(2):52 |

---

## Reference-stroke inventory (`assets/curriculum/letters.json`, 28 letters)

| Data | Coverage |
|---|---|
| **Base reference strokes** (single/isolated) | **28 / 28** ✅ |
| **Per-form references** (isolated/initial/medial/final, real points) | **3 / 28** — `alif`, `baa`, `taa` only |
| Letter-level `signedOff:true` | 2 (`baa`, `taa`) |
| Authored `commonMistakes` | 28 / 28 ✅ |
| Recorded letter audio | **0 / 28** |

**Implication for the build:** the form-aware scorer can be **built + calibrated on
baa (+ taa/alif) now** (full per-form data). **Form-awareness for the other 25
letters is blocked on per-form references** — a curriculum-data track (model drafts
→ owner's mother signs off, per the drafting-strategy rule) that runs *parallel* to
the scorer code. Audio is a separate gap.

---

## Other things worth knowing for the app

- **On-device Gemma becomes viable for the *coaching only*** — because judging left
  the LLM, the coaching task is small/text-only/bounded (verbalize a handed-in
  decision). If a small local model clears the mother's register bar, coaching goes
  fully offline + $0 + private. Decide via a coaching-only bake-off (Gemma-on-device
  vs Gemini-on-Vertex on her rubric). If not, keep the cloud model for the *line* only.
- **The scorer is pure Dart, on-device** → offline, instant, $0, no child data leaves
  the device (a COPPA win). This is a big reason to let it own the verdict.
- **Personalized thresholds (F11) = the learner model earning its keep** — the G8
  per-child model isn't just for coaching; it should *adapt this child's tolerance
  bands* over time, which the research says is the fix for the fixed-threshold miss rate.
