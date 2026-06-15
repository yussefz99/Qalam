# 07 baa Letter Unit — on-device bug list (owner-reported, 2026-06-15)

Found by running the app on the Pixel Tablet emulator. Forms data now loads
(Part A backfill worked — #4 "working now"). Remaining = UI/interaction bugs.

## STATUS (2026-06-15) — code fixes landed; NOT yet device-verified
- ✅ Shared root (duplicate Hear + overlap + blocked Clear/Next): ListenCard overlay removed.
- ✅ #2a two Hears on Meet; ✅ #2b white box under mascot; ✅ #3a/#3b trace Hear/Clear;
  ✅ #3c demo persists → now one-shot on Watch-me; ✅ #4 Forms Clear/Next; ✅ #5 Words Continue.
- ⚠️ #1 home "ghost" = the SPEC'd D-09 ink-fill (next letter at 0.25 alpha, 0 reps). Left as-is —
  changing the ramp is an owner design call (a UI-SPEC test enforces 0.5 at 1/3 reps).
- ⏳ STILL TO DO: verify all of the above on the emulator (widget tests pass, not device-proven).

## SHARED ROOT (hits Meet / Trace / Forms / Words — fix once in the engine)
- **Duplicate "Hear" button.** Every section shows TWO hear buttons. Cause: the
  section adds its own `ListenCard` AND the engine scaffold/prompt header renders
  an audio button. → Keep ONE.
- **The Hear button overlaps/blocks other buttons** (a tab, the Clear, the Next).
  Layout/z-order: the ListenCard side card sits on top of the scaffold controls.
- **Missing Clear and Submit/Next controls** on the write/trace surfaces, and
  **can't advance** to the next section (the advance control is absent or hidden
  under the overlapping Hear). This is why the unit feels "locked."

## PER-SCREEN
1. **Home screen** — a "ghost" (placeholder mascot) shows instead of the NEXT
   letter on the today's-lesson card. Expected: the next letter (baa). [home_screen.dart]
2. **Meet / welcome (Section 1)** — (a) TWO hear buttons; (b) a stray **white box
   under the mascot**. [meet_section.dart]
3. **Watch → Trace (Section 2)** — Watch animation + tip OK (tip COPY needs work).
   After "I'll try" → trace page: (a) two hear buttons, one blocking other buttons;
   (b) **no Clear button**; (c) the **demo animation stays on the canvas** — it must
   clear so the child can write on a blank guide. [watch_trace_section.dart, write_surface.dart]
4. **Forms in context (Section 3)** — forms now load ✓, BUT hear button blocks a
   tab, and **can't clear nor move to the next part**. [forms_section.dart]
5. **Join them / Words (Section 4)** — write the word; hear button blocks a button;
   **no submit or clear**; can't move to the next level. [words_section.dart]

## CONTENT (needs owner/mother, not a code fix)
- Tip wording on the Watch step (#3) — refine copy.
- initial/medial/final stroke shapes are DRAFTS → tablet re-capture at sign-off.

## FIX STRATEGY
Most of 1–5 trace to ONE engine-level layout problem (duplicate Hear + overlap +
missing Clear/Next). Fix the shared engine controls (exercise_scaffold / write_surface
/ prompt_header + how sections mount ListenCard) FIRST — that clears the majority across
all sections at once. Then per-screen: home ghost (#1), Meet white box (#2b), demo-clear
on trace (#3c). MUST verify each on the emulator — these were missed by widget tests.
