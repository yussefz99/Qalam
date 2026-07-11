"""The FastAPI app (Plan 01 Task 2) — the REST boundary the Flutter client calls.

  * GET /health             -> 200, no auth. The session-start warm-up ping (masks cold start).
                               NOTE: must NOT be "/healthz" — Google's edge reserves/intercepts
                               that exact path before it reaches Cloud Run, so the container never
                               sees it. "/health" reaches the app normally.
  * POST /coach             -> gated by Depends(verify_caller) (Firebase ID token + App Check).
                               Parses the enlarged TutorFactsIn, runs the minimal graph under
                               asyncio.wait_for, maps state["decision"] -> CoachOut.

On timeout/exception we return a structured non-200 error (503) the client maps to its
AuthoredFallback floor — NEVER 200-with-empty (G5 / the no-dead-end rule). We `await` the
graph; never `asyncio.run` inside the route (4b Async-First).
"""

from __future__ import annotations

import asyncio
import logging
import os
from functools import lru_cache

from fastapi import BackgroundTasks, Depends, FastAPI, HTTPException, status
from fastapi.responses import JSONResponse

from app.auth import verify_caller
from app.evidence import append_evidence, evidence_rows_from_facts
from app.graph import build_graph
from app.nodes import StructuredOutputError
from app.schema import CoachOut, TutorFactsIn

logger = logging.getLogger("qalam.tutor.main")

# Per-request graph budget. A slow model returns fast so the client degrades (G5).
_TIMEOUT_SECONDS = float(os.environ.get("COACH_TIMEOUT_SECONDS", "8"))

# Wire-key normalization (the single response casing contract). Internally the nodes
# keep the tool's snake_case arg names (the G4 guard reads `letter_id`); on the wire we
# emit camelCase so CoachOut.args matches the camelCase request DTO (TutorFactsIn) and the
# Dart client's `_parseCoachOut` (coachingLine/letterId). Without this, a `present_activity`
# line parses null on the client → empty → silent degrade to the floor.
_WIRE_ARG_KEYS = {
    "letter_id": "letterId",
    "coaching_line": "coachingLine",
    "next_exercise_id": "nextExerciseId",
}


def _to_wire_args(args: dict) -> dict:
    """Rename known snake_case decision-arg keys to their camelCase wire form."""
    return {_WIRE_ARG_KEYS.get(k, k): v for k, v in (args or {}).items()}


def _safe_append_evidence(claims: dict, facts_in: TutorFactsIn) -> None:
    """Derive + append per-letter×criterion evidence for THIS attempt (D-13, Req 7).

    Runs OFF the /coach critical path (a BackgroundTask) so the child never waits on Firestore. The
    uid is the TRUSTED verify_caller ID-token claim, NEVER the request body (T-18-05-01). Fully wrapped
    so a Firestore/derivation failure is display-only degradation and can never break /coach
    (T-18-05-05). A label-only attempt derives no rows and writes nothing.
    """
    try:
        uid = (claims or {}).get("uid")
        if not uid:
            return
        rows = evidence_rows_from_facts(facts_in)
        if not rows:
            return
        append_evidence(uid, rows)
    except Exception as exc:  # never let an evidence write break the response
        logger.warning("evidence append failed (display-only degradation): %s", type(exc).__name__)

app = FastAPI(title="Qalam Tutor Server", version="0.1.0")


@lru_cache(maxsize=1)
def _graph():
    """Build the graph once per process (stateless InMemorySaver — AI-SPEC pitfall 4)."""
    return build_graph()


@app.get("/health")
async def health() -> dict:
    """Warm-up ping. No auth — the client fires this when the child opens a unit.

    Path is "/health" not "/healthz": Google's edge intercepts the exact path "/healthz"
    before Cloud Run, so the container never receives it (verified at deploy).
    """
    return {"status": "ok"}


@app.post("/coach", response_model=CoachOut)
async def coach(
    facts_in: TutorFactsIn,
    background_tasks: BackgroundTasks,
    claims: dict = Depends(verify_caller),
) -> CoachOut:
    """Run the minimal grounding graph and return one grounded ACTION.

    `facts_in` is the FINAL enlarged, extra=forbid DTO — an extra/PII key 422s before we get
    here. Auth (Depends(verify_caller)) has already rejected unauthenticated callers with 401;
    `claims` carries the verified ID-token uid used to key the evidence write (never the body).
    """
    facts = facts_in.model_dump()
    config = {"configurable": {"thread_id": "stateless"}}

    # Retired by Plan 17-08 under D-A (the deterministic scorer owns pass/fail; ADR-017 at 17-10):
    # the Phase-17.1 rendered-image → AI-owns-verdict short-circuit is DELETED. The client stopped
    # sending the image in 17-07 (client-first removal ordering, RESEARCH Pattern 3), and the field
    # is gone from TutorFactsIn, so a stale client that still posts the retired image key now 422s
    # BY DESIGN under extra="forbid". The normal scorer-bounded graph path below is all that remains.
    try:
        result = await asyncio.wait_for(
            _graph().ainvoke({"facts": facts, "log": []}, config),
            timeout=_TIMEOUT_SECONDS,
        )
    except asyncio.TimeoutError:
        logger.warning("coach graph timed out after %ss; client degrades to fallback.", _TIMEOUT_SECONDS)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="coach_timeout",
        )
    except HTTPException:
        raise
    except StructuredOutputError as exc:  # retries exhausted / curriculum guard -> degrade (G5/D9)
        logger.warning("coach graph failed closed (%s); client degrades to AuthoredFallback.", exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="coach_degraded",
        )
    except Exception as exc:  # any other model/graph error -> structured 503 -> client AuthoredFallback
        logger.exception("coach graph failed: %s", type(exc).__name__)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="coach_error",
        )

    decision = result.get("decision") or {}
    out = CoachOut(
        toolName=decision.get("name", "say"),
        args=_to_wire_args(decision.get("args", {})),
        source="agent",
        grounded=bool(result.get("grounded", True)),
    )
    # Observability: the exact line the child sees (Section 7). Lets us confirm a real
    # online coaching turn vs the client's offline floor without a device probe.
    _line = out.args.get("text") or out.args.get("coachingLine") or ""
    # Phase 17 diagnostic: log the DERIVED (point-free) strokeDiff so we can confirm the
    # on-device geometry is reaching the server and cross-check the scorer's verdict (e.g.
    # dotPresent vs a noDot verdict). Non-PII derived data — safe to log.
    _sd = facts_in.strokeDiff.model_dump(exclude_none=True) if facts_in.strokeDiff else None
    # Phase 17 (17-05): also log the DERIVED per-criterion result + the weakest criterion (the
    # D-B coaching target) so we can confirm the structured scorer output is reaching the coach.
    # Same non-PII posture as _sd: exclude_none, derived-only scalars — no child geometry.
    _criteria = [c.model_dump(exclude_none=True) for c in facts_in.criteria] or None
    logger.warning(
        "coach decision: passed=%s mistakeId=%s strokeDiff=%s criteria=%s weakest=%s tool=%s grounded=%s line=%r",
        facts_in.passed,
        facts_in.mistakeId,
        _sd,
        _criteria,
        facts_in.weakestCriterion,
        out.toolName,
        out.grounded,
        _line[:200],
    )
    # Persist per-letter×criterion evidence OFF the critical path (D-13, Req 7). The CoachOut is
    # already built; the write runs AFTER the response is sent (BackgroundTask), keyed by the TRUSTED
    # uid claim (never facts_in) — the practice path never blocks on Firestore and a write failure
    # degrades display-only. Client Firestore writes stay deny-all; only this server path writes.
    background_tasks.add_task(_safe_append_evidence, claims, facts_in)
    return out


@app.exception_handler(asyncio.TimeoutError)
async def _timeout_handler(_request, _exc) -> JSONResponse:
    # Belt-and-suspenders: a timeout that escapes the route still degrades, never dead-ends.
    return JSONResponse(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, content={"detail": "coach_timeout"})
