---
created: 2026-07-12
source: 18-11 HUMAN-UAT (owner device session, iPad)
priority: high
---

# Question presentation overhaul — every question self-explanatory on screen

**Owner finding (2026-07-12, on device):** all non-trace questions "do not show
what is being asked — not understandable what is exactly needed to solve the
question. They need serious work."

**Diagnosis (code-verified):** the data reaches the screen (PromptHeader renders
audio/image/text/rule parts; authored configs load — no data loss). The gap is
presentation quality:

- The instruction lives only in the spoken `say` line (TTS once, never shown
  persistently) → miss it and the screen is a bare canvas.
- `writeWord.copy` hides the word by design (reveal-thenHide) — timing/affordance
  unclear.
- `completeWord` / `fillBlank` gap markers render small/literal (`__blank__`).
- Several questions demand unlearned letters regardless of rendering (see the
  audit on the baa-ladder artifact + 18-HUMAN-UAT).

**Proposed scope (next phase or gap plan):**
1. Persistent instruction area — icon + short child-readable text per question
   type (from the design kit; never TTS-only).
2. Large stimulus zone — image / replayable audio / word-to-copy, one per type.
3. Per-type "what to do" affordance (trace ghost, copy model, gap highlight).
4. Content rewrite of the language cards (№ 10, 15–20) with the curriculum
   owner — baa+alif-only words in the first unit; sentences/grammar gated to
   later letters.
5. Micro-drills return (parked 2026-07-12) once presentation + copy are reworked;
   selection logic already pinned by fixture in microdrill_selection_test.dart.
6. **Per-child position keying (found 2026-07-12):** `LetterGraphPosition`,
   arc-state, and profile-mirror rows are keyed by letterId ONLY — the resume
   cursor is shared across child profiles on one device (a new profile resumes
   at the old child's cursor; owner hit this expecting a fresh opening). Key all
   three by (childProfileId, letterId) + migrate. Workaround until then: delete
   + reinstall the app for a clean demo start.

**Related decisions today (owner):** trace all four forms first (baa.traceLetter.final
added, unsigned); micro-drills parked out of the live graph; write trio stays as
dynamic candidates.
