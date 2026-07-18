"""Qalam content tooling — Arabic decomposition, the draft vocab bank, and the
letter-legality validator.

Run from the ``tools/`` directory:
  * ``python -m content.build_draft`` — regenerate ``words_draft.json``.
  * ``python -m content.validate``    — report letter legality (draft + live).
"""

from __future__ import annotations

__all__ = ["arabic", "build_draft", "validate"]
