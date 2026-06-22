"""Bounded structured-output retry (Plan 14-02 — AI-SPEC §4b.1).

`analyze` / `plan` must return VALIDATED Pydantic structure (the graph routes on those fields).
A model can occasionally emit malformed JSON or `None`. The discipline (AI-SPEC §4b.1):

  * retry at most TWICE on `pydantic.ValidationError` / a `None`/empty parse (3 attempts total),
  * then FAIL CLOSED by raising `StructuredOutputError` — never loop forever, never block the
    child; the caller degrades to AuthoredFallback (G5 / D9),
  * log node / model / raw-text / error on every retry so a spike (a prompt or model regression)
    is visible to monitoring (Section 7).

This is model-agnostic: it takes a zero-arg callable that performs ONE structured invocation and
returns a parsed Pydantic model (or `None` on a soft failure). Tests monkeypatch the node's model
so the callable returns canned objects (or raises) with no network.
"""

from __future__ import annotations

import logging
from collections.abc import Callable
from typing import TypeVar

from pydantic import BaseModel, ValidationError

logger = logging.getLogger("qalam.tutor.nodes")

T = TypeVar("T", bound=BaseModel)

# 2 retries on top of the first attempt = 3 attempts total (AI-SPEC §4b.1).
_MAX_RETRIES = 2


class StructuredOutputError(RuntimeError):
    """A structured node exhausted its bounded retries — the run fails closed to AuthoredFallback."""


class _EmptyParse(RuntimeError):
    """Internal: a None/empty structured parse, treated as a soft retryable failure."""


def with_structured_retry(
    node: str,
    model_id: str,
    invoke: Callable[[], T | None],
) -> T:
    """Run `invoke()` with a bounded retry; raise `StructuredOutputError` when exhausted.

    `invoke` performs ONE structured-output call and returns a validated Pydantic model, or
    `None`/raises `ValidationError` on a soft failure. Retries at most `_MAX_RETRIES` times.
    """
    last_error: Exception | None = None

    for attempt in range(_MAX_RETRIES + 1):  # attempt 0 = first try, then 2 retries
        try:
            result = invoke()
            if result is None:
                # Treat a None/empty parse as a soft, retryable failure (AI-SPEC §4b.1).
                raise _EmptyParse(f"{node} returned no structured output")
            return result
        except ValidationError as exc:
            last_error = exc
            logger.warning(
                "structured-output retry: node=%s model=%s attempt=%d/%d error=%s",
                node,
                model_id,
                attempt + 1,
                _MAX_RETRIES + 1,
                type(exc).__name__,
            )
        except StructuredOutputError:
            raise
        except Exception as exc:  # any other parse failure is also a soft, retryable failure
            last_error = exc
            logger.warning(
                "structured-output retry: node=%s model=%s attempt=%d/%d error=%s",
                node,
                model_id,
                attempt + 1,
                _MAX_RETRIES + 1,
                type(exc).__name__,
            )

    logger.error(
        "structured-output FAILED CLOSED: node=%s model=%s after %d attempts; degrading to fallback.",
        node,
        model_id,
        _MAX_RETRIES + 1,
    )
    raise StructuredOutputError(
        f"{node} structured output failed after {_MAX_RETRIES + 1} attempts"
    ) from last_error
