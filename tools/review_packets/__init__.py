"""Qalam sign-off review packets.

Generates one self-contained, printable, RTL-correct HTML page per unsigned
letter so the owner's mother can review a letter's drafted stroke data in
minutes instead of half an hour. Run from ``tools/``:

  ``python -m review_packets``
"""

from __future__ import annotations

__all__ = ["generate"]
