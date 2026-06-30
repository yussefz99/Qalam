"""The two coaches under comparison (THROWAWAY spike).

* label_only_coach  — the STATUS QUO. Exactly the production coach: COACH_PROMPT (mother's voice +
                      grounding rule) + the frozen FACTS as text + the 4 ACTION tools forced
                      (tool_choice="any"). It NEVER sees strokes — only `mistakeId` + session facts.
* stroke_aware_coach — the SAME base, PLUS a STROKE ADDENDUM and one of the three representations
                      (image / points / geo_diff). It can DESCRIBE the actual attempt; the grounding
                      rule is restated and unchanged (the scorer's verdict stays the frozen judge).

Both reuse the production COACH_PROMPT + ACTION_TOOLS so the comparison isolates ONE variable: does
the coach see the strokes? After the model returns, the production G2/G3/G4 guards are applied so we
can report what would actually SHIP, and separately flag the RAW pre-guard grounding tendency.
"""
from __future__ import annotations

import base64
import time
from typing import Any

# These imports resolve because the spike runner puts `server/` on sys.path.
from app.prompts import COACH_PROMPT
from app.tools import ACTION_TOOLS, ACTION_TOOL_NAMES
from app.curriculum import is_authored
from langchain_core.messages import HumanMessage, SystemMessage

from . import representations as R
from . import vertex

# The stroke-aware coach prompt addendum — encodes the brief's §3 non-negotiables (scorer is the
# frozen judge; the AI is only an explainer) and the §6 new faithfulness checks (describe only what
# you see; stay consistent with the verdict).
# The "cheap win" prompt fix (brief §Interim) — exemplars become register guidance, never copy.
# Used to ISOLATE the value of the prompt fix (Arm B) from the value of strokes (Arm C).
ANTI_PARROT = """\

IMPORTANT — the GOLD EXEMPLARS above show the REGISTER and SHAPE of good feedback. They are NOT
lines to repeat. NEVER reuse an exemplar word-for-word. Write a FRESH line every time, in your own
words, fitted to THIS child's attempt and recent pattern. Two children with the same mistake should
hear two different, specific lines.
"""

STROKE_ADDENDUM = ANTI_PARROT + """\

YOU CAN NOW SEE THE CHILD'S ACTUAL STROKES for this attempt, shown against the correct reference.
Use what you SEE to name the ONE specific thing about THIS attempt — where the curve fell short,
which way it went, exactly where the dot landed — so your help is concrete to this child, not a
generic line.

GROUNDING (unchanged — never break, even now that you can see the strokes):
- The scorer's verdict is STILL the frozen FACT. The strokes are ONLY to help you DESCRIBE and
  COACH the fix — never to re-judge pass/fail.
- If the verdict is FAIL: coach the specific fix and encourage another try. Never praise as done,
  never `advance` — even if the strokes look fine to you.
- If the verdict is PASS: celebrate warmly. Do NOT invent a defect the verdict did not flag, even
  if the strokes look imperfect to you.
- Describe ONLY what you actually see. Never invent a detail (a dot, a tail) that is not there.
"""

_GROUNDED_RETRY_LINE = "Almost — let's try this one more time, slower. You're getting closer."


def _facts(fixture: dict[str, Any]) -> dict[str, Any]:
    """The non-PII frozen FACTS the production coach receives (NO strokes)."""
    return {
        "letterId": fixture["letterId"],
        "section": fixture["section"],
        "passed": fixture["passed"],
        "mistakeId": fixture["mistakeId"],
        "struggleTags": fixture.get("struggleTags", []),
        "recentMistakes": fixture.get("recentMistakes", []),
        "strengthTags": fixture.get("strengthTags", []),
        "trajectory": fixture.get("trajectory", []),
    }


def _extract(resp) -> tuple[str, dict, str]:
    """(tool_name, args, spoken_line) from a forced tool call."""
    tcs = getattr(resp, "tool_calls", None) or []
    if not tcs:
        return "say", {"text": ""}, ""
    call = tcs[0]
    name = call.get("name", "say")
    args = dict(call.get("args", {}) or {})
    line = args.get("text") or args.get("coaching_line") or ""
    return name, args, line


def _apply_guards(name: str, args: dict, line: str, passed: bool) -> dict:
    """Production G2/G3/G4 — returns the shipped action + grounded flag + raw pre-guard violations."""
    raw_advance_on_fail = name == "advance" and not passed
    raw_unauthored = name == "present_activity" and not is_authored(args.get("letter_id"))
    grounded = True
    final_name, final_line = name, line
    if name not in ACTION_TOOL_NAMES:
        final_name, final_line, grounded = "say", _GROUNDED_RETRY_LINE, False
    elif raw_advance_on_fail:
        final_name, final_line, grounded = "say", _GROUNDED_RETRY_LINE, False
    elif raw_unauthored:
        final_name, final_line, grounded = "say", _GROUNDED_RETRY_LINE, False
    return {
        "shipped_tool": final_name,
        "shipped_line": final_line,
        "grounded": grounded,
        "raw_advance_on_fail": raw_advance_on_fail,
        "raw_unauthored_present": raw_unauthored,
    }


def _invoke(model, messages) -> tuple[Any, float]:
    t0 = time.perf_counter()
    resp = model.invoke(messages)
    return resp, time.perf_counter() - t0


def _bound(temperature: float = 0.5):
    return vertex.build_gemini(temperature=temperature, max_tokens=256).bind_tools(
        ACTION_TOOLS, tool_choice="any"
    )


def label_only_coach(fixture: dict[str, Any], *, temperature: float = 0.5,
                     anti_parrot: bool = False) -> dict[str, Any]:
    """The coach with FACTS only, no strokes.

    anti_parrot=False -> Arm A, the TRUE status quo (verbatim-exemplar production prompt).
    anti_parrot=True  -> Arm B, the "cheap win" (exemplars as guidance, fresh wording) WITHOUT strokes.
    """
    facts = _facts(fixture)
    model = _bound(temperature)
    sys = COACH_PROMPT + (ANTI_PARROT if anti_parrot else "")
    messages = [
        SystemMessage(content=sys),
        HumanMessage(content=str({"facts": facts, "insight": {}, "plan": None})),
    ]
    resp, dt = _invoke(model, messages)
    name, args, line = _extract(resp)
    out = {"fixture_id": fixture["id"], "mode": "label_anti_parrot" if anti_parrot else "label_only",
           "representation": None, "tool_name": name, "line": line, "latency_s": round(dt, 3),
           "tokens": _tokens(resp)}
    out.update(_apply_guards(name, args, line, fixture["passed"]))
    return out


def stroke_aware_coach(fixture: dict[str, Any], representation: str, *,
                       temperature: float = 0.5, reps: dict | None = None) -> dict[str, Any]:
    """STROKE-AWARE: facts + one representation (image|points|geo_diff) + the stroke addendum."""
    assert representation in ("image", "points", "geo_diff")
    facts = _facts(fixture)
    reps = reps or R.build_all(fixture)
    model = _bound(temperature)
    sys = SystemMessage(content=COACH_PROMPT + STROKE_ADDENDUM)

    facts_text = str({"facts": facts, "insight": {}, "plan": None})
    if representation == "image":
        b64 = base64.b64encode(reps["image"]).decode()
        human = HumanMessage(content=[
            {"type": "text", "text": facts_text +
             "\n\nThe child's strokes are BLUE; the correct reference is faint GRAY. "
             "Compare them and coach the specific difference."},
            {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{b64}"}},
        ])
    else:
        label = "resampled stroke POINTS (child vs reference)" if representation == "points" \
            else "a precomputed GEOMETRY DIFF (child vs reference)"
        human = HumanMessage(content=facts_text +
                             f"\n\nHere is {label} for this attempt:\n" + reps[representation])

    resp, dt = _invoke(model, [sys, human])
    name, args, line = _extract(resp)
    out = {"fixture_id": fixture["id"], "mode": "stroke_aware", "representation": representation,
           "tool_name": name, "line": line, "latency_s": round(dt, 3), "tokens": _tokens(resp)}
    out.update(_apply_guards(name, args, line, fixture["passed"]))
    return out


def _tokens(resp) -> dict[str, int] | None:
    um = getattr(resp, "usage_metadata", None)
    if not um:
        return None
    return {"input": um.get("input_tokens", 0), "output": um.get("output_tokens", 0),
            "total": um.get("total_tokens", 0)}
