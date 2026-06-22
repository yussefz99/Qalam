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

    def with_structured_output(self, _schema):
        return _FakeStructured(self._insight)


class _FakePlanModel:
    def __init__(self, plan):
        self._plan = plan

    def with_structured_output(self, _schema):
        return _FakeStructured(self._plan)


def _patch_coach(monkeypatch, tool_calls):
    """Patch the whole node set offline: a struggle FACTS run goes analyze -> plan -> coach.

    The coach is patched to force `tool_calls`; analyze returns a struggle Insight (so the router
    takes the plan hop) and plan returns an authored, grounded Plan — both fully offline.
    """
    import app.nodes.analyze as analyze_mod
    import app.nodes.coach as coach_mod
    import app.nodes.plan as plan_mod
    from app.nodes.analyze import Insight
    from app.nodes.plan import Plan

    insight = Insight(
        struggle_tags=["boat-curvature"],
        strength_tags=["steady-hand"],
        pattern_note="shallow bowl recurring",
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


@pytest.mark.parametrize("bad_key", ["strokes", "x", "y", "childName", "nickname"])
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
    """advance is legitimate on a PASS verdict — the guard must NOT rewrite it."""
    _patch_coach(monkeypatch, [{"name": "advance", "args": {}}])

    resp = await client.post("/coach", json=ENLARGED_PASS_FACTS, headers=VALID_AUTH_HEADERS)

    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["toolName"] == "advance"
    assert body["grounded"] is True
