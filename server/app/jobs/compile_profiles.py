"""Nightly per-child model compiler — the across-session half of the two-timescale model.

Aggregates each child's per-letter×criterion evidence (``children/{uid}/evidence/*``, written
server-side by ``app/evidence.py``, D-13) into a per-criterion EMA and writes a DERIVED-ONLY,
non-PII profile doc ``child_models/{uid}`` = ``{strengths[], struggles[], perCriterion{},
schemaVersion, updatedAt}`` (D-15 / Req 8). The compiled ``strengths[]``/``struggles[]`` are what
the next session reads (via the Drift boot mirror, 18-06) so a returning child's first pick
reflects the past (Req 2).

EMA PARITY (D-15): the aggregation uses the SAME ``update_ema`` + provisional ``ALPHA/HI/LO/MIN``
as ``server/app/criterion_ema.py`` — the byte-identical mirror of the on-device
``lib/core/scoring/criterion_ema.dart``. The nightly compile and the within-session on-device
estimate therefore AGREE (no re-implemented formula — T-18-09-02).

LETTER-AGNOSTIC BY CONSTRUCTION (Req 8): the compiler keys on ``f"{letter}/{criterion}"`` with
NO per-letter branch — a newly signed letter simply appears in evidence and compiles with ZERO
schema/code change (proven by the second-letter ``alif`` fixture in
``tests/test_compile_profiles.py``).

SPARSE-DATA GATE (Pitfall 4 / T-18-09-04): a criterion is classified strength/struggle only once
it has ``>= MIN`` attempts; sub-count criteria stay "unknown" (never a false struggle).

DERIVED-ONLY / NON-PII (GROUND-04 / T-18-09-01): the profile doc carries ONLY fixed-vocabulary
letter-id + criterion-name keys and floats — no raw strokes, no coordinates, no nickname/PII.

## Nightly Job — Cloud Run Job + Cloud Scheduler (the 18-11 deploy gate, do NOT run here)

This module is a Cloud Run **Job** entrypoint that reuses the EXISTING server image
(``server/Dockerfile``) — zero new package (``firebase_admin`` is already installed and
ADC-initialized in ``app/auth.py``, whose ``_ensure_firebase_initialized`` this reuses). The work
is batch-shaped (aggregate over ALL children) and runs once then exits, so it is a SEPARATE
command on the same image — it does NOT touch the deployed ``/coach`` FastAPI service.

Run it locally against ADC (``gcloud auth application-default login``):

    cd server && uv run python -m app.jobs.compile_profiles

The exact commands the human runs at the 18-11 gate (copy-paste; no deploy happens in this plan):

    # 1. Create the Cloud Run Job from the ALREADY-BUILT server image, overriding the container
    #    command so it runs THIS module instead of uvicorn:
    gcloud run jobs create qalam-compile-profiles \
        --image us-central1-docker.pkg.dev/qalam-app-bd7d0/qalam/qalam-tutor:latest \
        --region us-central1 \
        --service-account qalam-compile-profiles@qalam-app-bd7d0.iam.gserviceaccount.com \
        --command python --args=-m,app.jobs.compile_profiles

    # 2. The Job runtime service account needs ONLY Firestore read/write — least privilege
    #    (T-18-09-03). roles/datastore.user covers both the children/evidence READ and the
    #    child_models WRITE; the Job needs NO Vertex / model access:
    gcloud projects add-iam-policy-binding qalam-app-bd7d0 \
        --member serviceAccount:qalam-compile-profiles@qalam-app-bd7d0.iam.gserviceaccount.com \
        --role roles/datastore.user

    # 3. A Cloud Scheduler cron fires the Job nightly (e.g. 03:00 daily):
    gcloud scheduler jobs create http qalam-compile-profiles-nightly \
        --location us-central1 \
        --schedule "0 3 * * *" \
        --uri "https://us-central1-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/qalam-app-bd7d0/jobs/qalam-compile-profiles:run" \
        --http-method POST \
        --oauth-service-account-email qalam-compile-profiles@qalam-app-bd7d0.iam.gserviceaccount.com

No change to the deployed ``/coach`` service — the Job is a separate command on the same image.
"""

from __future__ import annotations

import argparse
import logging

from firebase_admin import firestore

from app.criterion_ema import ALPHA, HI, LO, MIN, update_ema

logger = logging.getLogger("qalam.tutor.compile_profiles")

# The derived profile doc schema version (the 18-06 client boot mirror reads this; bump on shape change).
PROFILE_SCHEMA_VERSION = 1

# Firestore collection / subcollection names (evidence source + derived profile sink).
_CHILDREN = "children"
_EVIDENCE = "evidence"
_CHILD_MODELS = "child_models"

# Cold-start neutral prior for a never-seen criterion (mirror the on-device 0.5 seed).
_NEUTRAL_PRIOR = 0.5


def compile_child(evidence_rows: list[dict]) -> dict:
    """Aggregate ONE child's evidence rows into the derived-only profile doc (D-15 / Req 8).

    Folds each row through the SAME :func:`update_ema` as ``criterion_ema.py``, keyed on
    ``f"{letter}/{criterion}"`` with NO per-letter branch (letter-agnostic — a second letter
    just adds keys). An offline-digest row (``source == "digest"``) carries an aggregated
    ``count``; it contributes that many attempts so offline-accrued evidence is not
    undercounted. A live isolated-letter / word row is a single attempt.

    Classifies via the HI/LO band + the ``>= MIN`` sparse-data gate (Pitfall 4): a criterion
    under ``MIN`` attempts is neither a strength nor a struggle. Returns EXACTLY
    ``{strengths, struggles, perCriterion, schemaVersion}`` — derived-only, no raw evidence,
    no PII (the ``updatedAt`` server timestamp is added only at write time in :func:`main`).
    """
    ema: dict[str, float] = {}
    counts: dict[str, int] = {}
    for row in evidence_rows:
        key = f"{row['letter']}/{row['criterion']}"
        passed = bool(row.get("passed"))
        # Offline-digest rows aggregate several same-outcome attempts (evidence.py `count`); a
        # live letter/word row is a single attempt. Fold the update per attempt so BOTH the EMA
        # and the min-count gate reflect the true attempt volume.
        attempts = int(row.get("count", 1) or 1)
        for _ in range(attempts):
            ema[key] = update_ema(prior=ema.get(key, _NEUTRAL_PRIOR), passed=passed, alpha=ALPHA)
        counts[key] = counts.get(key, 0) + attempts

    strengths = [k for k, v in ema.items() if v >= HI and counts[k] >= MIN]
    struggles = [k for k, v in ema.items() if v <= LO and counts[k] >= MIN]
    return {
        "strengths": strengths,
        "struggles": struggles,
        "perCriterion": ema,
        "schemaVersion": PROFILE_SCHEMA_VERSION,
    }


def _evidence_rows_for(db, uid: str) -> list[dict]:
    """Read all evidence docs for one child as plain dicts (Admin SDK stream)."""
    col = db.collection(_CHILDREN).document(uid).collection(_EVIDENCE)
    return [doc.to_dict() or {} for doc in col.stream()]


def main(argv: list[str] | None = None) -> None:
    """Cloud Run Job entrypoint: compile EVERY child's evidence into ``child_models/{uid}``.

    Sequential single-task compile (Open Q3 — parallel task sharding is a later scale lever).
    Reuses ``auth.py``'s ADC-initialized ``firebase_admin`` default app (never re-inits — the
    ``_apps`` sentinel). Each child is isolated: one malformed evidence set logs + skips, never
    aborts the batch. A child with no evidence this cycle is left untouched (a prior profile is
    NOT clobbered with empties — e.g. after a raw-evidence TTL prune).
    """
    _parse_args(argv)  # `--help` prints usage and exits HERE, before any Firestore access.

    # Reuse auth.py's ADC init (idempotent via its `_apps` sentinel) — do NOT re-init here.
    # Imported lazily so a bare module import / `compile_child` unit test stays init-free.
    from app.auth import _ensure_firebase_initialized

    _ensure_firebase_initialized()
    db = firestore.client()

    compiled = 0
    for child in db.collection(_CHILDREN).stream():
        uid = child.id
        try:
            rows = _evidence_rows_for(db, uid)
            if not rows:
                continue
            profile = compile_child(rows)
            db.collection(_CHILD_MODELS).document(uid).set(
                {**profile, "updatedAt": firestore.SERVER_TIMESTAMP}
            )
            compiled += 1
        except Exception:  # one bad child must never abort the nightly batch
            logger.exception("compile_profiles: failed to compile child %s; skipping", uid)

    logger.info("compile_profiles: wrote %d child_models profile docs", compiled)


def _parse_args(argv: list[str] | None) -> argparse.Namespace:
    """Parse the (currently argument-free) CLI so ``--help`` is safe and inspectable."""
    parser = argparse.ArgumentParser(
        prog="python -m app.jobs.compile_profiles",
        description=(
            "Nightly per-child model compiler (Cloud Run Job). Aggregates "
            "children/{uid}/evidence into a derived-only child_models/{uid} profile via the "
            "per-criterion EMA (the criterion_ema.py mirror). Reuses the server image + ADC; "
            "takes no arguments."
        ),
    )
    return parser.parse_args(argv)


if __name__ == "__main__":
    main()
