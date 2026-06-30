"""Spike 002 analysis — offline. Run: uv run --directory ../../../server python <abs path>/run.py"""
import pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from _lib.spike_runs import spike_002  # noqa
spike_002()
