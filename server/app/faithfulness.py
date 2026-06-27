"""GROUND-03 — the model-free grounding-faithfulness check (Plan 15-06, D-10).

A deterministic, **model-AGNOSTIC** check over a small labeled `(verdict, coaching)` set.
It scores coaching lines against FIXED scorer verdicts and flags two failure modes:

  * (a) **praise-on-fail** — a FAIL whose coaching contains a praise token
        (beautiful / perfect / great job / well done / أحسنت / mastered); and
  * (b) **wrong-fix** — a FAIL whose coaching does NOT name the expected-fix token.

`evaluate_faithfulness` reads the labeled JSONL set and REPORTS a faithfulness RATE
(`faithful / total`) alongside the list of flagged (contradicting) cases.

WHY IT IS A FLOOR, NOT A CEILING (RESEARCH Assumption A6, threat T-15-06-R, accepted):
  The `_PRAISE` lexicon + the expected-fix-token substring rule are COARSE BY DESIGN.
  They can miss a *paraphrased* praise ("what a lovely bowl on a failed stroke") or a
  *semantically* wrong fix that happens to contain the token. That is acceptable for the
  deliberately MINIMAL D-10 slice: this is the SEED that Phase 13/16 grow into the full
  Claude-vs-Gemini bake-off + the calibrated-judge regression gate (the AI-SPEC §5 D1/D2
  dimensions). It is the GROUND-03 floor — a regression that re-introduces praise-on-fail
  or wrong-fix drops the rate and fails the gate.

MODEL-AGNOSTIC + OFFLINE: this module calls NO model and needs NO auth / Firebase. It is a
pure offline file read scored against fixed verdicts, so it works for Claude OR Gemini
output identically and does NOT pre-empt the Phase-13 model choice. The accompanying test
carries `pytestmark = pytest.mark.code` (a model-free `code` check that gates every PR).

NOTE: `.dockerignore` excludes `tests/` (and its fixtures) from the image, so the labeled
set never ships to the deployed server — this is an offline-CI artifact only. Correct.
"""

from __future__ import annotations

import json
import pathlib
from typing import Any, Optional, Union

# Praise tokens that must NOT appear in coaching for a FAILED stroke. Lower-cased substring
# match; includes the Arabic أحسنت ("well done"). FLOOR lexicon (A6) — coarse on purpose.
_PRAISE: tuple[str, ...] = (
    "beautiful",
    "perfect",
    "great job",
    "well done",
    "أحسنت",
    "mastered",
)


def _contradicts(passed: bool, coaching: str, expected_fix: Optional[str]) -> bool:
    """Return True when the coaching contradicts the fixed verdict.

    Model-agnostic and deterministic. Two failure modes, BOTH gated on a FAIL — praise and
    expected-fix are evaluated ONLY when ``passed`` is False, so a faithful PASS that warmly
    praises clean work ("Beautiful — a deep, smooth bowl. أحسنت!") is correctly NOT flagged.

    (a) praise-on-fail: a fail whose coaching contains any ``_PRAISE`` token.
    (b) wrong-fix:       a fail whose coaching omits the ``expected_fix`` token (when one is
                         given). The substring match is the coarse FLOOR (A6).
    """
    line = coaching.lower()
    # (a) praising a FAILED stroke
    if not passed and any(p in line for p in _PRAISE):
        return True
    # (b) naming the WRONG fix: on a fail, the coaching must mention the expected-fix token
    if not passed and expected_fix and expected_fix.lower() not in line:
        return True
    return False


def faithfulness_rate(cases: list[dict[str, Any]]) -> float:
    """The faithfulness RATE = faithful / total over a list of labeled cases.

    A case is *faithful* when ``_contradicts`` is False. Returns 0.0 for an empty list
    (no cases ⇒ nothing proven faithful). Each case carries ``passed``, ``coaching`` and an
    optional ``expectedFix`` (mirrors the JSONL fixture keys).
    """
    total = len(cases)
    if total == 0:
        return 0.0
    faithful = sum(
        0 if _contradicts(c["passed"], c["coaching"], c.get("expectedFix")) else 1
        for c in cases
    )
    return faithful / total


def evaluate_faithfulness(path: Union[str, pathlib.Path]) -> dict[str, Any]:
    """Score the labeled JSONL set at ``path`` and report the faithfulness rate.

    Returns a report dict:
      * ``faithful`` — count of cases that do NOT contradict their verdict;
      * ``flagged``  — the list of contradicting cases (each annotated with its ``label``);
      * ``total``    — number of labeled cases;
      * ``rate``     — ``faithful / total`` in [0, 1].

    Pure offline file read — no model, no auth, no network.
    """
    set_path = pathlib.Path(path)
    cases = [
        json.loads(line)
        for line in set_path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]

    flagged = [
        c for c in cases if _contradicts(c["passed"], c["coaching"], c.get("expectedFix"))
    ]
    total = len(cases)
    faithful = total - len(flagged)
    rate = faithful / total if total else 0.0

    return {
        "faithful": faithful,
        "flagged": flagged,
        "total": total,
        "rate": rate,
    }


if __name__ == "__main__":  # pragma: no cover - offline convenience reporter
    _default_set = (
        pathlib.Path(__file__).resolve().parents[1]
        / "tests"
        / "fixtures"
        / "faithfulness_set.jsonl"
    )
    report = evaluate_faithfulness(_default_set)
    print(
        f"GROUND-03 faithfulness rate: {report['faithful']}/{report['total']} = "
        f"{report['rate']:.2%}  ({len(report['flagged'])} flagged)"
    )
