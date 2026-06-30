"""Spike 003 analysis — offline. Run: uv run --directory ../../../server python <abs path>/run.py"""
import pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from _lib.spike_runs import spike_003  # noqa
spike_003()
