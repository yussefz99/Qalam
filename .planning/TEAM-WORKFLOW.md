# Qalam — Team Working Framework

How the owner, the partner, and the mother work in parallel without blocking or colliding.
The core idea: **two tracks running at once, meeting at one fixed contract.**

---

## Roles

| Who | Owns | |
|---|---|---|
| **Partner** | **Engineering** — the codebase, Firebase, the Phase 7 engine build | the builder |
| **Owner (Rami)** | **Product + content + coordination** — design fidelity, the curriculum (with mother), roadmap/GSD, illustrations | the driver |
| **Mother** | **Curriculum authority** — content decisions, audio, form-tracing, sign-off | the source of truth |
| **Claude** | **Shared builder** — plans engineering, drafts content, mines sources, writes scripts/specs | used by both tracks |

---

## Two parallel tracks

- **Track A — the Engine (Partner + Claude).** Phase 7: the 5 components, Schema v2 in Firestore, validators, the Letter Unit, baa wired. *Builds the machine.*
- **Track B — the Content (Owner + Mother + Claude).** Phase 8 prep: mine the Drive, draft content, record audio, source art, mother's decisions + sign-off. *Fills the machine.*

They run **at the same time** and meet at the schema. Track A builds something that *reads* Schema v2; Track B produces Schema v2 *data*. As long as both honor the contract below, they never wait on each other.

---

## The contract (the one rule that makes parallel work safe)

Three **LOCKED** artifacts are the shared interface between the tracks:
- `docs/design/prototypes/letter-unit-baa/` — the **UI** (build exactly; no redesign).
- `.planning/research/learning-experience/SCHEMA-V2.md` — the **data shape**.
- `.planning/research/learning-experience/COMPONENT-SYSTEM.md` — the **architecture**.

**Neither track changes these alone.** A change to Schema v2 *is* a change to the interface — it needs **both** of you to agree before it lands. Everything else, each track owns freely.

---

## File-area ownership (prevents git collisions)

| Area | Owner |
|---|---|
| `lib/`, `test/`, `android/`, `tools/firebase/*.py`, `pubspec.yaml` | **Partner** (engine) |
| `.planning/`, `docs/design/`, `assets/curriculum/*.json`, audio/image assets | **Owner / Claude** (content) |
| `ROADMAP.md`, `STATE.md`, `firestore.rules`, `SCHEMA-V2.md` | **Shared — coordinate before editing** |

Because the two tracks touch mostly different folders, you can both commit to `main` all day with near-zero conflicts.

---

## Integration via `main`

- **Land work on `main`; pull `main` before you start; push small, frequent commits.** (Feature branches have caused "I can't find it" here — `main` is the single integration point.)
- **baa is the first integration test:** when the engine (Track A) and baa's real content (Track B) both land, they meet. If baa renders from real Firestore content, both tracks are proven compatible — *then* scale to 27 more letters.

---

## Sync points (not daily meetings — just these checkpoints)

1. **Schema lock** — both confirm Schema v2 is agreed *before* heavy building. *(Now.)*
2. **baa integration** — the engine renders the baa unit from real content end-to-end.
3. **Content ready** — all 28 letters drafted/recorded/illustrated → batch load + mother's sign-off.
4. **Any schema change** — whoever needs it flags it immediately; both agree before it lands.

Shared status board between syncs = **`ROADMAP.md` + `STATE.md`** (GSD keeps them current).

---

## Who points Claude at what

- **Partner:** `/gsd:plan-phase 7`, executing plans, code review, debugging the engine.
- **Owner:** Drive mining, content drafting, recording/illustration scripts, the mother's question sheet, roadmap/GSD.

---

## This week

- **Partner (Track A):** finish the Phase 7 plan → start the engine (components + Schema v2 + baa wiring), building to the prototype.
- **Owner + Claude (Track B):** A1 mine the Drive → A2 draft content; C1 mother's question sheet; B1 recording script; B3 illustration list.
- **Mother:** start answering the 8 TBDs and recording audio (both are zero-dependency, longest-lead).
