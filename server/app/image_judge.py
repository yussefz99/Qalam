"""AI image-judge for baa (Phase 17.1 — owner directive 2026-06-30).

Owner decision: the deterministic scorer false-FAILS correct handwriting (a fluent writer's
textbook baa was rejected), and its reference is mis-calibrated, so it cannot own pass/fail. When
the client sends a rendered IMAGE of the child's strokes, the AI judges the letter the way a fluent
Arabic teacher would — leniently, on its own expertise — and owns the verdict + the coaching line.

This REVERSES GROUND-01 (scorer owns pass/fail) and GROUND-02 (raw geometry never leaves the
device): a rendered image of the child's handwriting is sent to the model. Owner-authorized for the
demo; must carry consent + an ADR for production.

Validated 2026-06-30: with a frame-filling render, Gemini-on-Vertex passes a perfect baa 3/3 and a
half-depth baa the scorer rejected, while flagging no-dot / dot-above / wrong-letter.
"""
from __future__ import annotations

import json
import logging
import re

from langchain_core.messages import HumanMessage, SystemMessage

logger = logging.getLogger("qalam.tutor.image_judge")

_JUDGE_SYS = """You are a kind, fluent Arabic handwriting teacher grading a young child's handwritten \
letter baa (ب), drawn in dark ink on a white background. A correct baa is a shallow boat / bowl \
body that opens UPWARD with EXACTLY ONE dot BELOW the body.

Grade with a real teacher's eye and a LENIENT standard — a child's hand is not a font. If it is \
clearly a recognizable, well-formed baa (a boat-shaped body with one dot below), it PASSES, even if \
it is not perfectly deep or perfectly smooth. Mark needsWork ONLY for a real problem: no dot, the \
dot above or beside the body, a different letter, or a badly malformed shape.

Speak the coaching line warmly to a 5-10 year old: on a pass, a short specific celebration; on \
needsWork, name the ONE concrete fix. A little Arabic (e.g. أحسنت) is welcome when it fits.

Return ONLY JSON: {"verdict": "pass" | "needsWork", "line": "<one short warm line for the child>"}"""


def _build_judge():
    """Gemini-on-Vertex, keyless (runtime SA ADC on Cloud Run) — temp 0 for a stable verdict."""
    from langchain_google_vertexai import ChatVertexAI
    import os

    return ChatVertexAI(
        model=os.environ.get("COACH_MODEL", "gemini-2.5-flash"),
        project=os.environ["GCP_PROJECT_ID"],
        location="us-central1",
        temperature=0.0,
        max_tokens=200,
        thinking_budget=0,
    )


def _parse(text: str) -> dict:
    """Pull {verdict, line} out of the model reply. Prefer json.loads (correct UTF-8 + escapes —
    keeps Arabic like أحسنت intact); regex only as a fallback. Fail-safe to needsWork (never an
    accidental pass)."""
    # Strip any ```json fence and isolate the JSON object.
    m = re.search(r"\{.*\}", text, re.S)
    if m:
        try:
            obj = json.loads(m.group(0))
            verdict = "pass" if str(obj.get("verdict", "")).strip().lower() == "pass" else "needsWork"
            return {"verdict": verdict, "line": str(obj.get("line", ""))}
        except Exception:  # noqa: BLE001 — fall through to regex
            pass
    verdict = "pass" if re.search(r'"verdict"\s*:\s*"pass"', text, re.I) else "needsWork"
    lm = re.search(r'"line"\s*:\s*"((?:[^"\\]|\\.)*)"', text)
    line = lm.group(1).replace('\\"', '"').replace("\\n", " ") if lm else ""
    return {"verdict": verdict, "line": line}


def judge_baa_image(image_b64: str) -> dict:
    """Judge a rendered baa image → {"verdict": "pass"|"needsWork", "line": str}.

    Fail-safe: on any model/parse error returns needsWork (never a false pass) so a glitch can
    never hand out a star; the caller still shows a grounded coaching line.
    """
    model = _build_judge()
    msg = HumanMessage(content=[
        {"type": "text", "text": "Grade this child's baa attempt."},
        {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{image_b64}"}},
    ])
    reply = model.invoke([SystemMessage(content=_JUDGE_SYS), msg])
    text = getattr(reply, "content", reply)
    text = text if isinstance(text, str) else str(text)
    out = _parse(text)
    logger.warning("image-judge: verdict=%s line=%r", out["verdict"], out["line"][:160])
    return out
