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
