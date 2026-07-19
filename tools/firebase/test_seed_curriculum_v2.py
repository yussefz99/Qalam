"""Crafted-fixture refusal test for the seeder's seen-letters wall (L2, criterion 2).

Proves ``seed_curriculum_v2`` refuses reach-ahead content BEFORE the first Firestore
write — nothing the bundle lint would refuse can reach prod — WITHOUT a live Firestore
or the service-account key (mirrors ``test_roundtrip.py``'s off-device strategy). The
Firestore client is a tiny in-memory stub whose ``.collection(...).document(...).set()``
chain appends to a ``writes`` list, so we can assert exactly which docs were written
(and, on refusal, that ZERO were).

Four guarantees (threat T-25-04-T — crafted content bypassing the shape-only validator):
  (1) REFUSAL — a crafted illegal card that IS a live graph node raises ``SystemExit``.
  (2) FAIL-FAST — when the refusal fires in ``seed()``, the stub records ZERO writes
      (no partial seed — not even the valid graph / legal sibling card is written).
  (3) LIVE-NODE SCOPING — a DORMANT reach-ahead config (same reach-ahead ``letters[]``
      but id NOT a live node) is seeded normally, matching the L0 audit / L1 lint.
  (4) NOT OVER-BROAD — a legal card and each of the 4 baa D-09 owner-approved
      exceptions are accepted (the stub records their writes).

Run from the repo root::

    pytest tools/firebase/test_seed_curriculum_v2.py -q

No real service-account key, no ``firebase_admin.credentials.ApplicationDefault`` live
path, no network — the seed path takes an injectable ``db``; the last test proves
``_init_app`` / ``firestore.client`` are never reached.
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

# Make the sibling seeder + the repo-root ``tools.content.validate`` importable no
# matter how this test is launched (pytest from the repo root, or ``python -m pytest``).
# Mirrors test_roundtrip.py's sys.path bootstrap. Import the seeder FIRST — it inserts
# the repo root so the ``from tools.content.validate import ...`` below resolves.
_HERE = Path(__file__).resolve().parent          # tools/firebase
_REPO_ROOT = _HERE.parents[1]                     # repo root
for _p in (str(_REPO_ROOT), str(_HERE)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

import seed_curriculum_v2 as S  # noqa: E402
from tools.content.validate import (  # noqa: E402
    OWNER_APPROVED_EXCEPTIONS,
    load_intro_order,
)

# The 4 baa cards owner-approved from device UAT (D-09). Named explicitly here (not
# imported from validate's PRIVATE group) — the test only imports the PUBLIC union
# ``OWNER_APPROVED_EXCEPTIONS`` and asserts each of these belongs to it.
_BAA_D09_IDS = [
    "baa.fillBlank.adjective",
    "baa.transformWord.dual",
    "baa.transformWord.plural",
    "baa.transformWord.opposite",
]


# --------------------------------------------------------------------------- #
# In-memory Firestore stub — no network, no key. Records every write as
# (collection, doc_id) so a refusal can be proven to have written NOTHING.
# --------------------------------------------------------------------------- #

class _StubDoc:
    def __init__(self, db, collection, doc_id):
        self._db = db
        self._collection = collection
        self._id = doc_id

    def set(self, payload):
        self._db.writes.append((self._collection, self._id))


class _StubCollection:
    def __init__(self, db, name):
        self._db = db
        self._name = name

    def document(self, doc_id):
        return _StubDoc(self._db, self._name, doc_id)


class _StubFirestore:
    """A stand-in for the Admin-SDK client: ``.collection(n).document(id).set(p)``."""

    def __init__(self):
        self.writes: list[tuple[str, str]] = []

    def collection(self, name):
        return _StubCollection(self, name)


def _install_content(monkeypatch, *, exercises, live_ids, graph_letters=("baa",)):
    """Inject crafted curriculum into ``seed()`` with NO disk / network access.

    Patches the seeder's loaders + the live-node scoping so ``seed(stub, None)`` runs
    over exactly the crafted ``exercises`` and treats ``live_ids`` as the live set.
    Graphs/units are minimal, Firestore-legal placeholders (empty ``nodes``).
    """
    graphs = {lid: {"letterId": lid, "nodes": []} for lid in graph_letters}
    units = [{"letterId": lid} for lid in graph_letters]

    def _fake_load(path):
        p = str(path)
        if p == str(S._EXERCISES_JSON):
            return {"exercises": exercises}
        if p == str(S._UNITS_JSON):
            return {"units": units}
        return graphs[Path(p).stem]  # a per-letter graph file

    monkeypatch.setattr(S, "_load_json", _fake_load)
    monkeypatch.setattr(S, "_graph_letter_ids", lambda: list(graph_letters))
    monkeypatch.setattr(S, "live_graph_node_ids", lambda: set(live_ids))


# --------------------------------------------------------------------------- #
# (1)+(2) REFUSAL + FAIL-FAST
# --------------------------------------------------------------------------- #

def test_guard_refuses_illegal_live_node_card():
    """The guard raises SystemExit for a reach-ahead card that IS a live node, and
    the message names the doc id + the unseen letter (no child data — T-25-04-I)."""
    order = load_intro_order()
    card = {"id": "baa.x", "type": "writeWord", "letters": ["taa"]}  # taa reaches past baa
    with pytest.raises(SystemExit) as exc:
        S._assert_learned_letters_legal(card, order, live_ids={"baa.x"})
    msg = str(exc.value)
    assert "baa.x" in msg
    assert "taa" in msg
    assert "nothing was written" in msg


def test_seed_refuses_illegal_live_card_before_any_write(monkeypatch):
    """End-to-end fail-fast: a live-node reach-ahead card makes ``seed()`` raise, and
    the stub records ZERO writes — not even the valid graph or the legal sibling card
    (validation runs fully BEFORE the first ``doc(id).set(...)``)."""
    exercises = [
        {"id": "baa.legal", "type": "writeWord", "letters": ["alif", "baa"]},
        {"id": "baa.illegal", "type": "writeWord", "letters": ["taa"]},  # reach-ahead, live
    ]
    _install_content(
        monkeypatch, exercises=exercises, live_ids={"baa.legal", "baa.illegal"}
    )
    stub = _StubFirestore()
    with pytest.raises(SystemExit) as exc:
        S.seed(stub, None)
    assert "baa.illegal" in str(exc.value)
    assert stub.writes == []  # no partial seed — NOTHING was written


# --------------------------------------------------------------------------- #
# (3) LIVE-NODE SCOPING — a dormant reach-ahead config is seeded normally
# --------------------------------------------------------------------------- #

def test_dormant_reach_ahead_config_is_not_refused():
    """The guard is a no-op for a reach-ahead card that is NOT a live node."""
    order = load_intro_order()
    dormant = {"id": "baa.dormant", "type": "buildSentence", "letters": ["taa"]}
    # No raise even though it reaches ahead — it is referenced by no live graph node.
    S._assert_learned_letters_legal(dormant, order, live_ids=set())


def test_dormant_reach_ahead_config_is_seeded(monkeypatch):
    """End-to-end: a dormant reach-ahead config (same reach-ahead ``letters[]``, id NOT
    in the live set) is written normally — the guard is live-node-scoped, not
    config-scoped (matches L0/L1)."""
    exercises = [{"id": "baa.dormant", "type": "buildSentence", "letters": ["taa"]}]
    _install_content(monkeypatch, exercises=exercises, live_ids=set())  # no live nodes
    stub = _StubFirestore()
    summary = S.seed(stub, None)
    assert ("exercises", "baa.dormant") in stub.writes
    assert summary["exercises"] == 1


# --------------------------------------------------------------------------- #
# (4) NOT OVER-BROAD — a legal card + the 4 D-09 exceptions are accepted
# --------------------------------------------------------------------------- #

def test_legal_card_is_seeded(monkeypatch):
    """A crafted legal live-node card (every letter already introduced) is written."""
    exercises = [{"id": "baa.legal", "type": "writeWord", "letters": ["alif", "baa"]}]
    _install_content(monkeypatch, exercises=exercises, live_ids={"baa.legal"})
    stub = _StubFirestore()
    summary = S.seed(stub, None)
    assert ("exercises", "baa.legal") in stub.writes
    assert summary["exercises"] == 1


def test_d09_exceptions_are_not_refused():
    """Each of the 4 baa D-09 cards is in the PUBLIC exception union AND is a no-op for
    the guard even though it reaches ahead and IS a live node."""
    order = load_intro_order()
    for ex_id in _BAA_D09_IDS:
        assert ex_id in OWNER_APPROVED_EXCEPTIONS
        card = {"id": ex_id, "type": "fillBlank", "letters": ["taa"]}  # reach-ahead
        # No raise: owner-approved (mother-verdict pending).
        S._assert_learned_letters_legal(card, order, live_ids={ex_id})


def test_d09_exception_cards_are_seeded(monkeypatch):
    """End-to-end: all 4 D-09 exception cards are written despite reaching ahead."""
    exercises = [
        {"id": ex_id, "type": "fillBlank", "letters": ["taa"]} for ex_id in _BAA_D09_IDS
    ]
    _install_content(
        monkeypatch, exercises=exercises, live_ids=set(_BAA_D09_IDS)
    )
    stub = _StubFirestore()
    summary = S.seed(stub, None)
    for ex_id in _BAA_D09_IDS:
        assert ("exercises", ex_id) in stub.writes
    assert summary["exercises"] == len(_BAA_D09_IDS)


# --------------------------------------------------------------------------- #
# (5) NO LIVE FIREBASE — the seed path never reaches the credential/live client
# --------------------------------------------------------------------------- #

def test_seed_never_touches_live_firebase(monkeypatch):
    """``seed()`` uses only the injected stub db — it never calls ``_init_app`` or
    ``firestore.client`` (which read the service-account key). Patch both to explode
    and prove a legal seed still completes against the stub."""
    def _boom(*args, **kwargs):
        raise AssertionError("the live Firebase path must not be reached in tests")

    monkeypatch.setattr(S, "_init_app", _boom)
    monkeypatch.setattr(S.firestore, "client", _boom)

    exercises = [{"id": "baa.legal", "type": "writeWord", "letters": ["alif", "baa"]}]
    _install_content(monkeypatch, exercises=exercises, live_ids={"baa.legal"})
    stub = _StubFirestore()
    S.seed(stub, None)  # no _init_app, no firestore.client — only the stub db
    assert ("exercises", "baa.legal") in stub.writes
