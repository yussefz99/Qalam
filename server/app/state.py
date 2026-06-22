"""The graph's typed state (Plan 01 Task 2).

`TutorState` is the single shared state schema for the analyze->plan->coach graph. This plan
wires only the `coach` node; `insight`/`plan` fields are reserved for Plan 02's nodes.

AI-SPEC pitfall 1: `log` carries an `Annotated[list, add]` reducer so each node APPENDS to the
trace instead of last-write-wins overwriting it. Without the reducer the second writer silently
drops the first writer's entry — the #1 LangGraph state bug.
"""

from __future__ import annotations

from operator import add
from typing import Annotated

from typing_extensions import TypedDict


class TutorState(TypedDict, total=False):
    facts: dict                     # the frozen, non-PII FACTS from the request (verdict + trajectory)
    insight: dict                   # analyze node writes this (Plan 02)
    plan: dict                      # plan node writes this (Plan 02; skipped on a clean pass)
    decision: dict                  # coach node writes the single ACTION tool call (name + args)
    grounded: bool                  # the G3 verdict-lock result (False if advance-on-fail was rewritten)
    log: Annotated[list, add]       # append-only trace (reducer = list concat) — pitfall 1
