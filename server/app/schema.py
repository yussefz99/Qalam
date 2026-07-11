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


class ChildProfileIn(BaseModel):
    """The DERIVED, fixed-vocabulary across-session child model (Phase 18 / Req 2 / D-14 / D-16).

    Compiled server-side (the nightly `compile_child`, 18-09) and mirrored to the device, then sent
    BACK on the next /coach turn so the tutor reasons over the child's persistent strengths/struggles,
    not just this-session facts. Every field is fixed-vocabulary + non-PII: `strengths`/`struggles`
    are `<letter>/<criterion>` competency ids, `perCriterion` maps those same ids to an EMA in [0,1],
    `schemaVersion` is an int. `extra="forbid"` + only scalar/list/dict-of-scalar fields means a
    stray coordinate/point key (`x`, `points`) NESTED inside the profile is a 422 (GROUND-04: raw
    geometry can never ride in on the child model).
    """

    model_config = ConfigDict(extra="forbid")

    strengths: list[str] = Field(
        default_factory=list,
        description="Derived competency ids the child does consistently well, e.g. 'baa/shape'.",
    )
    struggles: list[str] = Field(
        default_factory=list,
        description="Derived competency ids the child struggles with, e.g. 'baa/dot'.",
    )
    perCriterion: dict[str, float] = Field(
        default_factory=dict,
        description="EMA in [0,1] keyed by '<letter>/<criterion>' id — the across-session estimate.",
    )
    schemaVersion: int = Field(
        default=1, description="Provisional child-model schema version (bumped when the shape changes)."
    )


class EvidenceDigestRowIn(BaseModel):
    """One offline-accrued evidence-digest row (Phase 18 / Req 8 / D-14 offline backfill).

    While the device is offline it accrues per-letter×criterion pass/fail COUNTS locally; on the next
    online /coach turn it ships the aggregated digest so the server can fold the offline attempts into
    the persistent model. Fixed-vocabulary, non-PII: `letter`/`criterion` are curriculum ids, `pass`/
    `fail` are counts. `extra="forbid"` — a stray coordinate key (`x`) nested in a digest row is a 422.
    The wire key is `pass` (a Python keyword) so the field is `pass_` with `alias="pass"`.
    """

    model_config = ConfigDict(extra="forbid")

    letter: str = Field(description="The letter family id the counts belong to, e.g. 'baa'.")
    criterion: str = Field(description="The criterion id the counts belong to, e.g. 'dot'.")
    pass_: int = Field(default=0, alias="pass", description="Offline count of passing attempts.")
    fail: int = Field(default=0, description="Offline count of failing attempts.")


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

    # --- Phase 17.2 (demo, owner directive 2026-07-07): the graph-LEGAL next-exercise candidates ---
    # The client computes the SAME set its selection router would accept (CurriculumGraph.isLegalSelection
    # over the child's cleared tiers/competencies) and sends it so the coach can propose the NEXT exercise
    # FROM the graph rather than invent one. Exercise ids are CURRICULUM CONSTANTS — non-PII (no geometry,
    # no child data). OPTIONAL + default None => ADDITIVE / backward-compatible: an OLD client that omits it
    # still validates (no 422 window — deploy the server FIRST, the client follows). The coach node rails
    # any proposed nextExerciseId against THIS list; an id outside it is stripped and never forwarded.
    legalNextExerciseIds: list[str] | None = Field(
        default=None,
        description="Graph-legal next-exercise candidate ids the coach must pick FROM (non-PII curriculum "
        "constants); null/omitted when the client sends none.",
    )

    # --- Phase 18 (18-05, D-14 / D-16 / Req 2): the across-session child model + offline backfill ---
    # The DERIVED persistent child model (`profile`) + the offline-accrued evidence digest
    # (`evidenceDigest`). BOTH optional/defaulted => ADDITIVE (strict-superset): an OLD client that
    # sends neither still validates — no 422 window. Deploy direction: the SERVER ships FIRST (this
    # plan), the Dart mirror (lib/tutor/tutor_facts.dart) follows in 18-06 and copies these field
    # NAMES + the nested keys byte-for-byte (Pitfall 1 — the 422 lockstep). GROUND-04: both nested
    # models are extra="forbid", fixed-vocabulary scalars/ids — a nested coordinate/point key 422s,
    # so raw geometry / PII can never ride in on the child model or the digest.
    profile: ChildProfileIn | None = Field(
        default=None,
        description="The DERIVED across-session child model (strengths/struggles/perCriterion EMA); "
        "null when the client has no compiled profile yet.",
    )
    evidenceDigest: list[EvidenceDigestRowIn] = Field(
        default_factory=list,
        description="Offline-accrued per-letter×criterion pass/fail counts (D-14 backfill); "
        "empty when the client has nothing queued.",
    )

    # --- RETIRED by Plan 17-08 under D-A (scorer owns pass/fail; ADR-017 at 17-10) ---
    # The Phase-17.1 rendered-image field (base64 PNG → AI-owns-verdict) is DELETED here. Under D-A
    # the deterministic on-device scorer owns pass/fail, so no rendered image of child handwriting
    # may reach the server — a net privacy win (GROUND-04 surface shrink, server half). The client
    # stopped sending it in 17-07 (client-first removal ordering, RESEARCH Pattern 3); with the field
    # gone from this extra="forbid" DTO, a stale client that still posts the retired image key now
    # 422s BY DESIGN — the only live client is the same-phase demo build, cut over first (T-17-18).


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
        description="True when the action honors the scorer's frozen pass/fail; False if the G3 guard had to rewrite it.",
    )
    # NOTE: the Phase-17.1 AI pass/fail field is RETIRED here (Plan 17-08, D-A). Under D-A the
    # scorer owns pass/fail, so no response field may carry a model pass/fail for the client to
    # honor over the scorer — the elevation-of-privilege surface (T-17-16) is closed by construction.
    # 17-07 verified the Dart parser tolerates its absence (the normal path never carried one).
