"""Endpoint + wire-contract tests (Plan 01 Task 2) — the single, final DTO.

Model-free `code` checks (14-AI-SPEC §5 CI leg 1):
  1. The enlarged payload (populated trajectory + strengthTags) is ACCEPTED -> 200 with a
     CoachOut whose toolName is in the closed set (proves the deployed DTO is the day-one
     enlarged contract — no "widen later" 422 gap).
  2. Any extra/PII key (strokes, x, y, childName, nickname) -> 422 on BOTH TutorFactsIn and
     the nested AttemptFactIn (extra=forbid).
  3. An `advance`-on-fail forced call is rewritten to a grounded `say` (G3 verdict lock).

The coach model is monkeypatched (offline) to return a forced tool call.
"""

from __future__ import annotations

import pytest

from tests.conftest import VALID_AUTH_HEADERS

pytestmark = pytest.mark.code


# --- Fake models: the coach returns a forced tool call; analyze/plan return canned structure. ---


class _FakeResp:
    def __init__(self, tool_calls):
        self.tool_calls = tool_calls


class _FakeBoundCoach:
    def __init__(self, tool_calls):
        self._tool_calls = tool_calls

    def invoke(self, _messages):
        return _FakeResp(self._tool_calls)


class _FakeStructured:
    """A with_structured_output(...) stand-in that returns a fixed parsed model."""

    def __init__(self, obj):
        self._obj = obj

    def invoke(self, _messages):
        return self._obj


class _FakeAnalyzeModel:
    def __init__(self, insight):
        self._insight = insight

    def with_structured_output(self, _schema, method=None):
        return _FakeStructured(self._insight)


class _FakePlanModel:
    def __init__(self, plan):
        self._plan = plan

    def with_structured_output(self, _schema, method=None):
        return _FakeStructured(self._plan)


def _patch_coach(monkeypatch, tool_calls, clean_pass: bool = False):
    """Patch the whole node set offline: a struggle FACTS run goes analyze -> plan -> coach.

    The coach is patched to force `tool_calls`; analyze returns a struggle Insight (so the router
    takes the plan hop) and plan returns an authored, grounded Plan — both fully offline.

    `clean_pass=True` makes analyze return an EMPTY-struggle Insight so `needs_plan` shortcuts
    analyze -> coach directly (the plan node is SKIPPED, graph.py). This is the exact routing the
    owner tested (a clean pass): the per-attempt WHY can then ONLY reach the client via the coach
    tool-call args (next_exercise_id + rationale) — the mechanism 18-14 unblocks.
    """
    import app.nodes.analyze as analyze_mod
    import app.nodes.coach as coach_mod
    import app.nodes.plan as plan_mod
    from app.nodes.analyze import Insight
    from app.nodes.plan import Plan

    insight = (
        Insight(
            struggle_tags=[],
            strength_tags=["steady-hand", "deep-bowl"],
            pattern_note="clean, confident pass",
        )
        if clean_pass
        else Insight(
            struggle_tags=["boat-curvature"],
            strength_tags=["steady-hand"],
            pattern_note="shallow bowl recurring",
        )
    )
    plan_obj = Plan(
        next_exercise_id="baa.traceLetter.isolated",
        intent="drill_isolated",
        rationale="drill the failed trace",
    )

    monkeypatch.setattr(analyze_mod, "build_analyze_model", lambda: _FakeAnalyzeModel(insight))
    monkeypatch.setattr(plan_mod, "build_plan_model", lambda: _FakePlanModel(plan_obj))
    monkeypatch.setattr(
        coach_mod, "build_coach_with_tools", lambda: _FakeBoundCoach(tool_calls)
    )


# --- Sample enlarged FACTS payloads ---

ENLARGED_FAIL_FACTS = {
    "letterId": "baa",
    "section": "traceLetter",
    "passed": False,
    "mistakeId": "shallowBowl",
    "struggleTags": ["boat-curvature"],
    "recentMistakes": ["shallowBowl", "shallowBowl"],
    # the ENLARGED fields — populated, to prove the deployed DTO accepts them:
    "trajectory": [
        {"passed": False, "mistakeId": "shallowBowl", "section": "traceLetter"},
        {"passed": False, "mistakeId": "dotMisplaced", "section": "traceLetter"},
    ],
    "strengthTags": ["steady-hand"],
}

ENLARGED_PASS_FACTS = {
    "letterId": "baa",
    "section": "traceLetter",
    "passed": True,
    "mistakeId": None,
    "struggleTags": [],
    "recentMistakes": [],
    "trajectory": [{"passed": True, "mistakeId": None, "section": "traceLetter"}],
    "strengthTags": ["steady-hand", "deep-bowl"],
}

# A CLEAN-PASS payload carrying the graph-legal next-exercise candidates (18-14). The coach node's
# next-exercise rail validates any proposed next_exercise_id against THIS list; a pick inside it
# survives to the wire, a pick outside it is stripped (with its orphaned rationale).
_LEGAL_NEXT = "baa.traceLetter.initial"
PASS_FACTS_WITH_CANDIDATES = {
    **ENLARGED_PASS_FACTS,
    "weakestCriterion": "shape",
    "legalNextExerciseIds": [_LEGAL_NEXT, "baa.traceLetter.medial"],
}


# --- 1. The enlarged payload is accepted (200) and yields an in-set ACTION. ---


async def test_enlarged_payload_accepted_returns_in_set_action(client, monkeypatch):
    _patch_coach(monkeypatch, [{"name": "say", "args": {"text": "Lovely, deeper curve!"}}])

    resp = await client.post("/coach", json=ENLARGED_FAIL_FACTS, headers=VALID_AUTH_HEADERS)

    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["toolName"] in {"present_activity", "say", "give_hint", "advance"}
    assert body["toolName"] == "say"
    assert body["source"] == "agent"


# --- 2. Extra / PII keys -> 422 (extra=forbid) on the top-level model and the nested model. ---


# `strokeImage` is in the list from Plan 17-08 (D-A): the retired Phase-17.1 rendered-image field
# was deleted from TutorFactsIn, so an image key now 422s over the live /coach boundary too — the
# server can no longer receive a rendered image of child handwriting (GROUND-04 server half).
@pytest.mark.parametrize("bad_key", ["strokes", "x", "y", "childName", "nickname", "strokeImage"])
async def test_top_level_extra_key_rejected_422(client, monkeypatch, bad_key):
    _patch_coach(monkeypatch, [{"name": "say", "args": {"text": "hi"}}])
    body = dict(ENLARGED_FAIL_FACTS)
    body[bad_key] = "leaked-value"

    resp = await client.post("/coach", json=body, headers=VALID_AUTH_HEADERS)
    assert resp.status_code == 422


async def test_nested_attempt_extra_key_rejected_422(client, monkeypatch):
    """extra=forbid on AttemptFactIn — a leaked key inside a trajectory entry is a 422."""
    _patch_coach(monkeypatch, [{"name": "say", "args": {"text": "hi"}}])
    body = dict(ENLARGED_FAIL_FACTS)
    body["trajectory"] = [
        {"passed": False, "mistakeId": "shallowBowl", "section": "traceLetter", "x": 12.5}
    ]

    resp = await client.post("/coach", json=body, headers=VALID_AUTH_HEADERS)
    assert resp.status_code == 422


# --- 3. G3 verdict lock: advance-on-fail is rewritten to a grounded say. ---


async def test_advance_on_fail_rewritten_to_grounded_say(client, monkeypatch):
    # The model (wrongly) forces `advance` on a FAIL verdict — the guard must rewrite it.
    _patch_coach(monkeypatch, [{"name": "advance", "args": {}}])

    resp = await client.post("/coach", json=ENLARGED_FAIL_FACTS, headers=VALID_AUTH_HEADERS)

    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["toolName"] == "say"          # rewritten away from advance
    assert body["grounded"] is False          # flagged as a guard rewrite
    assert body["args"].get("text")           # carries a grounded line


async def test_advance_on_pass_is_allowed(client, monkeypatch):
    """advance on a PASS stays grounded (G3 silent) but is coerced to a SPOKEN say by the
    17.2 always-speak rail — a word-less action renders as silence on-device now that the
    authored floor is retired (owner directive 2026-07-07)."""
    _patch_coach(monkeypatch, [{"name": "advance", "args": {}}])

    resp = await client.post("/coach", json=ENLARGED_PASS_FACTS, headers=VALID_AUTH_HEADERS)

    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["toolName"] == "say"
    assert body["args"].get("text")  # never word-less
    assert body["grounded"] is True


# --- 3. The present_activity wire contract is camelCase (matches the Dart client). ---


async def test_present_activity_args_are_camelcase_on_the_wire(client, monkeypatch):
    """The coach tool emits snake_case param names (`letter_id`/`coaching_line`); the WIRE
    must expose them camelCase (`letterId`/`coachingLine`) so the Dart client's _parseCoachOut
    reads them — otherwise a present_activity line parses null and silently degrades to the floor.
    `baa` is an authored id, so the G4 curriculum guard does NOT rewrite this to `say`.
    """
    _patch_coach(
        monkeypatch,
        [{"name": "present_activity", "args": {"letter_id": "baa", "coaching_line": "Let's try the boat again."}}],
    )

    resp = await client.post("/coach", json=ENLARGED_PASS_FACTS, headers=VALID_AUTH_HEADERS)

    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["toolName"] == "present_activity"
    # camelCase on the wire (the single response casing contract) ...
    assert body["args"]["letterId"] == "baa"
    assert body["args"]["coachingLine"] == "Let's try the boat again."
    # ... and the internal snake_case keys must NOT leak onto the wire.
    assert "letter_id" not in body["args"]
    assert "coaching_line" not in body["args"]


# --- 4. The clean-pass per-attempt WHY survives the wire (18-14 — the structural fix). ---


async def test_clean_pass_legal_next_and_rationale_reach_the_wire(client, monkeypatch):
    """A CLEAN PASS: the coach attaches a LEGAL next_exercise_id + a rationale on its tool call
    (now that tools.py declares those params). The wire CoachOut.args must carry BOTH the camelCase
    `nextExerciseId` (via _to_wire_args) AND `rationale` — proving the per-attempt WHY now reaches
    the client on the common clean-pass path (the plan node is SKIPPED here, so the coach args are
    the ONLY carrier). `baa` is authored, so the G4 guard leaves present_activity intact.
    """
    _patch_coach(
        monkeypatch,
        [
            {
                "name": "present_activity",
                "args": {
                    "letter_id": "baa",
                    "coaching_line": "Beautiful — a deep, smooth bowl. Ready for the initial form?",
                    "next_exercise_id": _LEGAL_NEXT,
                    "rationale": "smooth deep bowl — ready for the initial form",
                },
            }
        ],
        clean_pass=True,
    )

    resp = await client.post("/coach", json=PASS_FACTS_WITH_CANDIDATES, headers=VALID_AUTH_HEADERS)

    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["toolName"] == "present_activity"
    # The legal pick reached the wire, renamed to camelCase (the Dart TutorPlan parser reads this) ...
    assert body["args"]["nextExerciseId"] == _LEGAL_NEXT
    # ... the internal snake_case key must NOT leak, and the WHY rides alongside it.
    assert "next_exercise_id" not in body["args"]
    assert body["args"]["rationale"] == "smooth deep bowl — ready for the initial form"


async def test_clean_pass_rationale_survives_on_a_say(client, monkeypatch):
    """Same clean-pass WHY, carried on a `say` (the always-speak floor) rather than present_activity —
    a legal pick + rationale still serialize to nextExerciseId + rationale on the wire."""
    _patch_coach(
        monkeypatch,
        [
            {
                "name": "say",
                "args": {
                    "text": "أحسنت! A lovely deep bowl — let's try the initial form next.",
                    "next_exercise_id": _LEGAL_NEXT,
                    "rationale": "confident bowl — step to the initial form",
                },
            }
        ],
        clean_pass=True,
    )

    resp = await client.post("/coach", json=PASS_FACTS_WITH_CANDIDATES, headers=VALID_AUTH_HEADERS)

    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["toolName"] == "say"
    assert body["args"]["nextExerciseId"] == _LEGAL_NEXT
    assert body["args"]["rationale"] == "confident bowl — step to the initial form"


async def test_illegal_next_exercise_and_orphaned_rationale_are_stripped(client, monkeypatch):
    """The trust boundary holds (T-18-14-01): a proposed next_exercise_id NOT in the request's
    `legalNextExerciseIds` is stripped by the coach rail and NEVER forwarded — and its now-orphaned
    `rationale` is dropped with it. An off-graph / hallucinated pick can never reach the client.
    """
    _patch_coach(
        monkeypatch,
        [
            {
                "name": "present_activity",
                "args": {
                    "letter_id": "baa",
                    "coaching_line": "Beautiful bowl!",
                    # NOT in PASS_FACTS_WITH_CANDIDATES.legalNextExerciseIds -> must be stripped.
                    "next_exercise_id": "baa.writeWord.dictation",
                    "rationale": "jump straight to dictation",
                },
            }
        ],
        clean_pass=True,
    )

    resp = await client.post("/coach", json=PASS_FACTS_WITH_CANDIDATES, headers=VALID_AUTH_HEADERS)

    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["toolName"] == "present_activity"
    # The illegal id was stripped (never forwarded under EITHER casing) ...
    assert "nextExerciseId" not in body["args"]
    assert "next_exercise_id" not in body["args"]
    # ... and the orphaned rationale went with it (no dangling WHY for a pick that never survived).
    assert "rationale" not in body["args"]
    # The advisory spoken line is left intact (the rail only guards the id, not the words).
    assert body["args"]["coachingLine"] == "Beautiful bowl!"
