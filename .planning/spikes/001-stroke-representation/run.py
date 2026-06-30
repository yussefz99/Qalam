"""Spike 001 analysis — offline. Run: uv run --directory ../../../server python <abs path>/run.py
(Regenerate the underlying model data with: python ../_lib/experiment.py)
"""
import pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from _lib.spike_runs import spike_001  # noqa
spike_001()
