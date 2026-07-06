"""The SINGLE source of truth for the /coach wire contract (Plan 01 Task 2).

This module defines the FULL, FINAL, enlarged non-PII request DTO `TutorFactsIn` and the
response DTO `CoachOut`. It is deployed enlarged from day one. Plans 02/03/04 reference
THIS definition — they do not redefine or widen it.

Why enlarged now: per CAPABLE-AGENT-SPEC, the tutor reasons over the attempt *trajectory*
plus the session learner model (strengths AND struggles), not just the last `mistakeId`.
The minimal one-node graph (this plan) ignores `trajectory`/`strengthTags`; Plan 02's
analyze node consumes them. But the DEPLOYED DTO is already the final contract so the live
/coach never 422s a legit enlarged client payload once Plan 03 enlarges the client type.

`extra="forbid"` on BOTH `TutorFactsIn` and the nested `AttemptFactIn` means any unexpected
field — a leaked stroke/PII key (`strokes`, `x`, `y`, `childName`, `nickname`, …) — is a 422,
never silently accepted. This is the server side of the GROUND-02 non-PII guard.

Field names mirror the client whitelist in `lib/tutor/tutor_facts.dart` (the 6 base fields);
Plan 03 enlarges the client type to add `trajectory` + `strengthTags` to match this DTO.
Tool names mirror `lib/tutor/tutor_decision.dart` (`TutorTool`).
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

# The closed action space — mirrors lib/tutor/tutor_decision.dart `TutorTool`.
ToolName = Literal["present_activity", "say", "give_hint", "advance"]


class AttemptFactIn(BaseModel):
    """One non-PII scored-attempt record in the trajectory.

    `extra="forbid"` so a leaked stroke/PII key inside a trajectory entry is also a 422.
    """

    model_config = ConfigDict(extra="forbid")

    passed: bool = Field(description="The scorer's frozen verdict for this attempt.")
    mistakeId: str | None = Field(
        default=None, description="Authored feedback key on a miss; null on a pass."
    )
    section: str = Field(description="The exercise/section id, e.g. 'traceLetter'.")


class StrokeDiffIn(BaseModel):
    """A DERIVED, point-free stroke-geometry diff (Phase 17 / STRK-01 / GROUND-04).

    Computed ON-DEVICE (Dart) from the child's strokes vs the authored reference, then sent so the
    coach can name the SPECIFIC geometry of this attempt. `extra="forbid"` + only scalar/string
    fields means **raw stroke points can never cross the wire** (GROUND-04: only the derived diff
    leaves the device, never raw strokes) — a leaked `points`/`x`/`y` key is a 422. Every field is
    optional so the producer sends only what applies to the current form.
    """

    model_config = ConfigDict(extra="forbid")

    summary: str | None = Field(
        default=None,
        description="One-line natural-language summary of the deviation (e.g. 'bowl much shallower; dot left of center').",
    )
    strokeCount: int | None = None
    bodySegments: int | None = None
    bowlDepthRatio: float | None = Field(default=None, description="child bowl depth / reference depth.")
    bowlDepthVerdict: str | None = Field(
        default=None, description="'much shallower' | 'shallower' | 'matches' | 'deeper'."
    )
    bowlSymmetry: str | None = Field(
        default=None, description="e.g. 'right side flat, left side curves'; null when symmetric."
    )
    sizeVerdict: str | None = Field(default=None, description="'too big' | 'too small' | 'matches'.")
    directionChild: str | None = None
    directionReference: str | None = None
    tailPresent: bool | None = None
    dotPresent: bool | None = None
    dotHorizontal: str | None = Field(
        default=None, description="'left of center' | 'right of center' | 'centered'."
    )
    dotVertical: str | None = Field(default=None, description="'above the bowl' | 'below the bowl'.")
    dotPlacementOk: bool | None = None


class CriterionIn(BaseModel):
    """One DERIVED per-criterion scoring result (Phase 17 / STRK-01 / D-B / GROUND-04).

    Mirrors the Dart `CriterionResult` {criterion, zone, score} (lib/core/scoring/scoring_models.dart);
    the Plan 17-06 client mirror (lib/tutor/tutor_facts.dart) copies these names byte-for-byte
    (Pitfall 1 — the 422 lockstep). `extra="forbid"` + ONLY scalar/string fields means a leaked
    coordinate/point key NESTED inside a criterion record is a 422 (GROUND-04): raw stroke geometry
    can never ride in on a criterion entry.
    """

    model_config = ConfigDict(extra="forbid")

    criterion: str = Field(
        description="Which criterion was scored: 'strokeCount' | 'strokeOrder' | 'shape' | "
        "'direction' | 'dot' (the OWNER-CONFIRMED D-C amendment set, 2026-07-05).",
    )
    zone: str = Field(
        description="The soft zone the criterion landed in: 'certainlyCorrect' | 'fuzzy' | "
        "'certainlyWrong' (only certainlyWrong fails).",
    )
    score: float = Field(description="Continuous 1.0 (perfect) -> 0.0 (certainly wrong).")


class TutorFactsIn(BaseModel):
    """The FINAL, enlarged, non-PII request contract for POST /coach.

    The 6 base fields (mirroring the client whitelist) PLUS the enlarged
    `trajectory` + `strengthTags`. `extra="forbid"` — no PII / raw geometry may enter.
    """

    model_config = ConfigDict(extra="forbid")

    # --- the 6 base whitelisted fields (mirror lib/tutor/tutor_facts.dart) ---
    letterId: str = Field(description="The letter family, e.g. 'baa'.")
    section: str = Field(description="The exercise/section id, e.g. 'traceLetter'.")
    passed: bool = Field(description="The deterministic scorer's frozen verdict for THIS attempt.")
    mistakeId: str | None = Field(
        default=None, description="Authored feedback key the scorer matched; null on a pass."
    )
    struggleTags: list[str] = Field(
        default_factory=list, description="Derived, deduplicated session struggle tags."
    )
    recentMistakes: list[str] = Field(
        default_factory=list, description="Recent session mistake ids, most-recent-first."
    )

    # --- the enlarged fields (the day-one-final shape; Plan 02 consumes them) ---
    trajectory: list[AttemptFactIn] = Field(
        default_factory=list,
        description="The scored-attempt trajectory (per-attempt non-PII records).",
    )
    strengthTags: list[str] = Field(
        default_factory=list,
        description="The session learner-model strengths (what the child does consistently well).",
    )

    # --- the graph-position fields (Plan 15-02; the G5/G6 rail + resume replay reads these) ---
    # Derived string-lists (tier ids / competency ids) — NO PII, NO geometry. The Dart side
    # (lib/tutor/tutor_facts.dart) MUST mirror these in lockstep: the live /coach 422s under
    # extra="forbid" if either side ships the field without the other (Pitfall 1 — the 422 trap).
    # Re-deploy the server only AFTER both sides land (15-04 owns the Dart mirror).
    clearedTiers: list[str] = Field(
        default_factory=list,
        description="The إملاء difficulty tiers the child has cleared (manqul/manzur/ghayrManzur).",
    )
    clearedCompetencies: list[str] = Field(
        default_factory=list,
        description="The curriculum-graph competencies the child has cleared (recognize, copyWrite, …).",
    )

    # --- Phase 17: the DERIVED on-device stroke-geometry diff (STRK-01 / GROUND-04) ---
    # OPTIONAL + point-free (StrokeDiffIn forbids extras). Optional => backward compatible: a client
    # that does not send it still validates (no 422 window — server lands first, client follows).
    strokeDiff: StrokeDiffIn | None = Field(
        default=None,
        description="DERIVED stroke-geometry diff computed on-device (no raw points). Lets the coach name the specific attempt geometry.",
    )

    # --- Phase 17 (17-05, locked D-B): the STRUCTURED per-criterion result + derived word facts ---
    # The scorer (Plan 17-03) now emits LetterScore.criteria (five criteria) + the weakest one — the
    # structured coaching input D-B requires. These four fields carry it (plus the F6 word path) to
    # the coach. ALL optional/defaulted => ADDITIVE (strict-superset): an OLD client that sends none
    # of them still validates — no 422 window. Deploy direction: additive — the server ships FIRST,
    # the Dart mirror (lib/tutor/tutor_facts.dart) follows in Plan 17-06, which copies these field
    # NAMES byte-for-byte (Pitfall 1 — the 422 lockstep). GROUND-04: criteria are point-free scalars
    # (CriterionIn forbids extras) and the word facts are DERIVED text, never geometry.
    criteria: list[CriterionIn] = Field(
        default_factory=list,
        description="DERIVED per-criterion results (strokeCount/strokeOrder/shape/direction/dot). "
        "Lets the coach name the FAILED (certainlyWrong) criterion or, on a pass, the weakest one.",
    )
    weakestCriterion: str | None = Field(
        default=None,
        description="Name of the lowest-score criterion — the coaching target (D-B); null when absent.",
    )
    expectedWord: str | None = Field(
        default=None,
        description="The curriculum's expected word for the F6 word path (DERIVED text, never geometry).",
    )
    writtenWord: str | None = Field(
        default=None,
        description="ML Kit's recognized transcription of what the child wrote (DERIVED text, never geometry).",
    )

    # --- Phase 17.1: a rendered IMAGE of the child's strokes (owner directive 2026-06-30) ---
    # base64 PNG. This is the AI-OWNS-PASS/FAIL path: the scorer false-fails correct writing, so the
    # AI judges the rendered letter on its own expertise (reverses GROUND-01 + GROUND-02 — a rendered
    # image of handwriting leaves the device; owner-authorized for the demo, consent + ADR for prod).
    strokeImage: str | None = Field(
        default=None,
        description="base64 PNG of the child's rendered strokes; when present the AI judges pass/fail.",
    )


class CoachOut(BaseModel):
    """The /coach response DTO.

    Carries the single chosen ACTION (tool name + its args), the source, and whether the
    line was grounded. Plan 02 sets `grounded` from the deeper reasoning; this plan sets it
    from the G3 advance-on-fail guard. The Flutter dispatcher maps `toolName` -> a controller
    call (it never rebuilds the canvas from agent state — ADR-014 grounding rule).
    """

    model_config = ConfigDict(extra="forbid")

    toolName: ToolName = Field(description="The single forced ACTION tool name.")
    args: dict = Field(default_factory=dict, description="The chosen tool's arguments.")
    source: Literal["agent"] = Field(default="agent", description="Who produced this line.")
    grounded: bool = Field(
        default=True,
        description="True when the action honors the frozen verdict; False if the G3 guard had to rewrite it.",
    )
    # Phase 17.1: the AI's pass/fail when it judged a rendered image (owner directive). null on the
    # normal (scorer-owned) path. "pass" lets the client award the star even if the scorer failed.
    verdict: str | None = Field(
        default=None,
        description='AI verdict when an image was judged: "pass" | "needsWork"; null otherwise.',
    )
