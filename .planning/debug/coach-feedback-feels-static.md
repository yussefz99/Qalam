---
status: diagnosed
trigger: "coach-feedback-feels-static: Qalam's AI tutor gives spoken/written feedback after a scored handwriting attempt. During fresh UAT on 2026-07-17, the owner observed that the pass feedback appears to always show the SAME specific-sounding line (\"your baa wants a deeper bowl, a low smooth scoop before you lift\") regardless of the actual attempt, rather than being generated fresh each time."
created: "2026-07-17T00:00:00.000Z"
updated: "2026-07-17T00:10:00.000Z"
---

## Current Focus

hypothesis: CONFIRMED (see Resolution). Root cause is a client-side (Dart) hardcoded fallback string in TeacherMarginPanel, not a server-side prompt-exemplar echo.
test: n/a — root cause confirmed, mode is find_root_cause_only.
expecting: n/a
next_action: Return ROOT CAUSE FOUND to caller. Do not fix (find_root_cause_only mode).

## Symptoms

expected: After a correct attempt, the tutor's feedback names something specific about THAT attempt/exercise — generated per-attempt, not a fixed canned line.
actual: "its feels static always showing your baa wants a deeprer bowl a low smooth scoop before you lift" — the same specific-sounding feedback line recurs across different attempts/exercises instead of varying with context.
errors: None reported
reproduction: Complete several different baa exercises correctly (and across a few fail->retry cycles) and compare the coach's rendered/spoken feedback text across attempts — check whether it's identical or varies.
started: Discovered during Phase 18 UAT on 2026-07-17. Suspected PRIOR KNOWN issue from Phase 14 (project memory, unfixed): coach prompt GOLD EXEMPLARS get copied verbatim -> feedback looks static.

## Eliminated

- hypothesis: "Coach system prompt's GOLD EXEMPLARS (server/app/prompts.py) get echoed verbatim by the LLM instead of generating fresh per-attempt text (the Phase-14 suspected cause carried into this UAT)."
  evidence: |
    Read prompts.py COACH_PROMPT + COACH_STROKE_ADDENDUM in full. The exemplars ARE present
    ("Beautiful — a deep, smooth bowl. أحسنت!" etc.) but are wrapped in explicit, repeated
    anti-echo instructions added in Phase 17 (17-05): "NEVER copy, quote, or lightly rephrase
    an exemplar; compose EVERY line fresh" and "On repeated tries at the SAME mistake, VARY the
    wording every time... never fall back on an exemplar." More decisively: the EXACT reported
    phrase ("Your baa wants a deeper bowl — a low, smooth scoop before you lift.") does not
    appear anywhere in prompts.py (no "scoop", no "before you lift", no "low, smooth"). It DOES
    appear byte-for-byte as a hardcoded Dart string in
    lib/features/letter_unit/widgets/teacher_margin_panel.dart:183.
  timestamp: "2026-07-17T00:05:00.000Z"

## Evidence

- timestamp: "2026-07-17T00:03:00.000Z"
  checked: "grep -rn 'scoop' / 'before you lift' / 'deep smooth' across repo"
  found: |
    Exact match: lib/features/letter_unit/widgets/teacher_margin_panel.dart:183
      'shape' => 'Your baa wants a deeper bowl — a low, smooth scoop before you lift.'
    This is a hardcoded, criterion-keyed literal in `_authoredWhy(String? criterion)`,
    documented in the file header as "PROVISIONAL (signed:false)... the OFFLINE floor the
    panel shows when the coach `rationale` is absent (D-10)."
  implication: "The owner's exact reported phrase is a client-side fallback template, not LLM output."

- timestamp: "2026-07-17T00:04:00.000Z"
  checked: "TeacherMarginPanel.build() — where `why` and `criterion` come from"
  found: |
    `why = insight.rationale?.trim().isNotEmpty == true ? rationale : _authoredWhy(criterion)`.
    `criterion = _targetedCriterion(insight)` returns the FIRST criterion in `insight.criteria`
    whose zone is NOT 'certainlyCorrect' (else the first listed). insight.criteria is populated
    at verdict time from the real scorer result (result.criteria) — this part is genuinely
    per-attempt. The FALLBACK TEMPLATE keyed by that criterion is NOT per-attempt (6 fixed
    strings total, one per criterion name).
  implication: "Whether the child sees a fresh line depends entirely on whether insight.rationale got populated; if not, the SAME fixed template shows for whichever criterion is 'targeted'."

- timestamp: "2026-07-17T00:05:30.000Z"
  checked: "exercise_scaffold.dart _onResult() — where insight.rationale is set"
  found: |
    insight.rationale is set ONLY inside `if (_isAgentPath && plan?.nextExerciseId != null)`
    (line ~402), from `plan.rationale` where `plan = decision.plan` (a TutorPlan parsed by
    lib/tutor/remote_agent_brain.dart from the coach's tool-call `args` map: `args['nextExerciseId']`
    / `args['rationale']`). If nextExerciseId is null, `decision.plan` itself is null
    (remote_agent_brain.dart:159 `if (nextId == null && intent == null && rationale == null)
    return null;`), so this whole block is skipped and insight.rationale is NEVER updated past
    verdict time (stays null from the initial `TutorInsight(criteria:..., diffSummary:...)` at
    line ~320, which never sets rationale at all).
  implication: "insight.rationale is gated behind a next-exercise id surviving; it is a distinct code path from the tutor's actual free-form spoken feedback line (_lineOf(decision) / tutorLineProvider), which DOES vary per attempt and is unaffected by this bug."

- timestamp: "2026-07-17T00:06:30.000Z"
  checked: "server/app/tools.py ACTION_TOOLS schemas vs server/app/prompts.py COACH_NEXT_EXERCISE_ADDENDUM"
  found: |
    The 4 bound ACTION tools are declared with FIXED, narrow signatures:
      present_activity(letter_id: str, coaching_line: str)
      say(text: str)
      give_hint()
      advance()
    None declares `nextExerciseId` or `rationale` as a parameter. coach.py builds
    `coach_with_tools = build_coach_model().bind_tools(ACTION_TOOLS, tool_choice="any")` —
    a real LangChain tool-schema binding. COACH_NEXT_EXERCISE_ADDENDUM (prompts.py) is PURELY
    prose asking the model to "Return your pick as an extra `nextExerciseId` argument on
    whichever tool you call, together with a one-phrase `rationale` argument" — but function-
    calling APIs (Gemini/Vertex, the deployed provider per app/models.py) constrain returned
    tool-call arguments to the tool's DECLARED schema; a real (non-mocked) model call cannot
    attach undeclared extra keys to present_activity/say/give_hint/advance's arguments.
  implication: "The nextExerciseId+rationale mechanism on the COACH node is prompted-only, not schema-backed — structurally unable to work against a real function-calling model, regardless of how well the model 'wants' to comply."

- timestamp: "2026-07-17T00:07:30.000Z"
  checked: "server/app/graph.py needs_plan() — which turns run the `plan` node (the OTHER, schema-backed nextExerciseId/rationale source, via Plan pydantic structured output in nodes/plan.py)"
  found: |
    `needs_plan`: "a clean pass with NO struggle_tags" routes analyze -> coach directly,
    SKIPPING `plan` entirely. Only a struggle/fail routes analyze -> plan -> coach. Test 5 in
    18-UAT.md is specifically about the PASS case ("A pass gives a specific reason"). On a
    clean pass, `plan` node never runs, so state["plan"] is never set, and the coach node's
    `plan = state.get("plan")` is None — the ONLY other source of `rationale` is the broken,
    schema-less coach-tool-args mechanism above.
  implication: "On the exact scenario the owner tested (a PASS), there is NO working path to populate insight.rationale — it is null by construction on essentially every clean pass."

- timestamp: "2026-07-17T00:08:30.000Z"
  checked: "lib/core/scoring/shape_match.dart zoneFor() + memory note on Phase 17-02 provisional tolerance bands"
  found: |
    `zoneFor(distance)`: <= tcc -> certainlyCorrect, >= tcw -> certainlyWrong, else fuzzy
    (PASSES but not 'certainlyCorrect'). Per project memory (Phase 17-02): "all Tolerances
    presets share the PROVISIONAL soft-band defaults (0.10/0.15/0.3/-0.3)... the loose/strict
    ramp temporarily has NO shape discrimination until the mom-labelled calibration sets
    per-preset bands." The 'shape' (bowl) criterion is one of the two SOFT criteria
    (shape/direction SOFT; count/order/dot FIRM per 17-03).
  implication: "'shape' rarely lands in 'certainlyCorrect' even on a genuinely good attempt (provisional/uncalibrated band), so `_targetedCriterion` picks 'shape' as 'the part being worked on' on nearly every attempt — routing to the SAME fixed fallback string, 'Your baa wants a deeper bowl — a low, smooth scoop before you lift.', virtually every time. This is exactly the 'always the same line' symptom."

- timestamp: "2026-07-17T00:09:00.000Z"
  checked: "server/tests/test_endpoint.py _patch_coach() — whether any test exercises the real tool schema for nextExerciseId/rationale on the coach node"
  found: |
    All server tests monkeypatch `build_coach_with_tools` to return a `_FakeBoundCoach` that
    just replays a hand-supplied Python dict of tool_calls — never constrained by the real
    LangChain/Vertex function-calling schema. The one test that exercises `next_exercise_id`/
    `rationale` (test_endpoint.py `_patch_coach`) sets them on the `plan` node's Pydantic
    `Plan` object (a genuinely schema-backed field, the OTHER older mechanism), not on a coach
    tool-call's args. No test proves the coach-node's undeclared-extra-arg mechanism actually
    survives a real model's function-calling constraints.
  implication: "This gap was invisible in CI (mirrors the Phase-15 'dead wire' pattern in project memory: a mechanism that looks wired but was never proven against the real interface it depends on) and only surfaces in live/device UAT."

## Resolution

root_cause: |
  The static line the owner sees ("Your baa wants a deeper bowl — a low, smooth scoop before
  you lift.") is NOT the LLM coach echoing a GOLD EXEMPLAR (that Phase-14 mechanism was already
  hardened with explicit anti-echo instructions in Phase 17, and the exact phrase does not
  appear anywhere in server/app/prompts.py). It is a hardcoded, criterion-keyed fallback
  template literally written in the CLIENT: `_authoredWhy('shape')` in
  lib/features/letter_unit/widgets/teacher_margin_panel.dart:183, rendered by TeacherMarginPanel
  whenever `insight.rationale` is null.

  `insight.rationale` is null essentially every time on a PASS (the scenario the owner tested)
  because of a genuine wiring/architecture gap: the mechanism meant to carry the LLM's live,
  per-attempt "why" onto this panel (COACH_NEXT_EXERCISE_ADDENDUM in prompts.py, asking the
  model to add `nextExerciseId`/`rationale` as EXTRA arguments on whichever ACTION tool it
  calls) is prompt-text-only — the four bound ACTION tools declared in server/app/tools.py
  (present_activity, say, give_hint, advance) do NOT declare `nextExerciseId`/`rationale` as
  parameters, so a real function-calling model (Gemini/Vertex, per app/models.py) structurally
  cannot attach those undeclared keys to its tool call. The ONE other, genuinely schema-backed
  source of `rationale` is the `plan` node's Pydantic `Plan.rationale` — but `graph.py`'s
  `needs_plan()` SKIPS the `plan` node entirely on a clean pass, so that source is also absent
  for exactly the case the owner tested.

  With `insight.rationale` always null on a pass, `TeacherMarginPanel` falls back to
  `_authoredWhy(criterion)`, a 6-line fixed lookup table keyed by `_targetedCriterion(insight)`
  (the first scorer criterion whose zone isn't `certainlyCorrect`). Because the 'shape' (bowl)
  criterion still uses PROVISIONAL, uncalibrated soft-band tolerances (Phase 17-02), it is very
  rarely `certainlyCorrect` even on a clean, correct attempt — so `_targetedCriterion` returns
  'shape' on nearly every turn, and the SAME fixed string fires almost every time. This
  combination (rationale-population gap + criterion-selection skew toward 'shape') produces the
  exact "always shows the same specific-sounding line" symptom.

  Note: the tutor's main spoken/bubble feedback line (`tutorLineProvider` / `_lineOf(decision)`,
  driven by the coach's `say`/`present_activity` `text`/`coaching_line` args) is a SEPARATE,
  genuinely-generated-per-attempt code path and is NOT affected by this bug — the static line
  the owner is seeing is specifically the Teacher's Margin panel's "why" line (and the related
  demo "Teacher's Eye" strip at exercise_scaffold.dart ~line 533, which reads the same
  `insight.rationale`).
fix: (not applied — find_root_cause_only mode)
verification: (not applicable — diagnosis only)
files_changed: []
