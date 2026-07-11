"""Server-side per-letter×criterion evidence capture (Phase 18 / Req 7 / D-13).

The persistent, server-only child-data path. At /coach the server derives per-letter×criterion
evidence rows from the (already non-PII, extra=forbid) FACTS and appends them via the Admin SDK —
OFF the response critical path (a BackgroundTask), so the child never waits on Firestore. Client
Firestore writes stay DENY-ALL (D-13, Phase-06.1 posture); evidence is written where the uid is
trusted (the verified ID-token claim), never by the client.

Two derivation shapes (RESEARCH Pitfall 3 — never fabricate the 5 geometric criteria for a word):

  * ISOLATED-LETTER attempt (`criteria` present)  -> one row per GEOMETRIC criterion
    (strokeCount/strokeOrder/shape/direction/dot), `source == "letter"`.
  * WORD / SEQUENCE attempt (`writtenWord`/`expectedWord` present) -> a COARSE per-letter signal for
    EVERY letter the word touches (باب -> baa AND alif): present/correct, `source == "word"`.
  * Offline-accrued digest (`evidenceDigest`, D-14 backfill) -> aggregated count rows,
    `source == "digest"`, keeping the same letter×criterion keying.

The schema is letter×criterion, so a newly signed letter needs ZERO code branch here — the word
path decodes the expected word to curriculum ids via a DATA map, and the letter path just enumerates
whatever criteria the scorer produced. Nothing branches on a specific letter id.
"""

from __future__ import annotations

import datetime as _dt

from firebase_admin import firestore

# --- Arabic base letter -> curriculum letter id (matches assets/curriculum/letters.json ids). ---
# DATA, not a per-letter code branch: a second signed letter needs no code change here.
_ARABIC_LETTER_IDS: dict[str, str] = {
    "ا": "alif",   # ا
    "ب": "baa",    # ب
    "ت": "taa",    # ت
    "ث": "thaa",   # ث
    "ج": "jeem",   # ج
    "ح": "haa_c",  # ح
    "خ": "khaa",   # خ
    "د": "daal",   # د
    "ذ": "dhaal",  # ذ
    "ر": "raa",    # ر
    "ز": "zaay",   # ز
    "س": "seen",   # س
    "ش": "sheen",  # ش
    "ص": "saad",   # ص
    "ض": "daad",   # ض
    "ط": "taa_h",  # ط
    "ظ": "zhaa",   # ظ
    "ع": "ayn",    # ع
    "غ": "ghayn",  # غ
    "ف": "faa",    # ف
    "ق": "qaaf",   # ق
    "ك": "kaaf",   # ك
    "ل": "laam",   # ل
    "م": "meem",   # م
    "ن": "noon",   # ن
    "ه": "haa_f",  # ه
    "و": "waaw",   # و
    "ي": "yaa",    # ي
}

# Hamza-carrying alef forms, alef-maqsura, and taa-marbuta resolve to their base letter first.
_ARABIC_NORMALIZE: dict[str, str] = {
    "أ": "ا",  # أ -> ا
    "إ": "ا",  # إ -> ا
    "آ": "ا",  # آ -> ا
    "ٱ": "ا",  # ٱ -> ا
    "ى": "ي",  # ى (alef maqsura) -> ي
    "ة": "ت",  # ة (taa marbuta) -> ت
}

# Coarse word-signal criteria (Pitfall 3 — a word attempt never produced the 5 geometric criteria).
_SOURCE_WORD = "word"
_SOURCE_LETTER = "letter"
_SOURCE_DIGEST = "digest"

# Optional Firestore-TTL horizon (defense-in-depth against unbounded on-server growth).
_TTL_DAYS = 90


def _letters_in_word(word: str) -> list[str]:
    """Ordered, de-duplicated curriculum letter ids the Arabic `word` touches.

    Strips tashkeel, normalizes hamza/alef-maqsura/taa-marbuta, maps each base letter to its
    curriculum id. باب -> ['baa', 'alif'] (the Req 7 evidence contract). Purely data-driven.
    """
    ids: list[str] = []
    for ch in word or "":
        # Skip tashkeel / diacritics (U+064B..U+0652 + superscript alef U+0670).
        if "ً" <= ch <= "ْ" or ch == "ٰ":
            continue
        base = _ARABIC_NORMALIZE.get(ch, ch)
        lid = _ARABIC_LETTER_IDS.get(base)
        if lid and lid not in ids:
            ids.append(lid)
    return ids


def _as_dict(facts) -> dict:
    """Accept either a Pydantic `TutorFactsIn` (from /coach) or a plain dict (tests)."""
    if hasattr(facts, "model_dump"):
        return facts.model_dump()
    return dict(facts)


def evidence_rows_from_facts(facts) -> list[dict]:
    """Derive per-letter×criterion evidence rows from a non-PII FACTS payload.

    Branches on the PRESENCE of `criteria` (isolated letter) vs `writtenWord`/`expectedWord` (word) —
    NEVER on a specific letter id (letter-agnostic). Each row is {letter, criterion, passed, source};
    word/digest rows carry the same shape (digest rows add an aggregated `count`).
    """
    data = _as_dict(facts)
    rows: list[dict] = []

    criteria = data.get("criteria") or []
    written = data.get("writtenWord")
    expected = data.get("expectedWord")

    if criteria:
        # ISOLATED-LETTER attempt: one row per geometric criterion (source='letter').
        letter = data.get("letterId")
        for c in criteria:
            # Only 'certainlyWrong' fails (mirrors the scorer's soft-zone semantics).
            passed = c.get("zone") != "certainlyWrong"
            rows.append(
                {
                    "letter": letter,
                    "criterion": c.get("criterion"),
                    "passed": passed,
                    "source": _SOURCE_LETTER,
                }
            )
    elif expected or written:
        # WORD/SEQUENCE attempt: a COARSE present/correct signal for EVERY letter the word touches
        # (Pitfall 3 — never fabricate the 5 geometric criteria for a word). present = the letter
        # appeared in the transcription; correct = the whole word matched expected.
        expected_letters = _letters_in_word(expected or "")
        written_letters = set(_letters_in_word(written or ""))
        word_correct = bool(written) and written == expected
        for lid in expected_letters:
            rows.append(
                {"letter": lid, "criterion": "present", "passed": lid in written_letters, "source": _SOURCE_WORD}
            )
            rows.append(
                {"letter": lid, "criterion": "correct", "passed": word_correct, "source": _SOURCE_WORD}
            )

    # Fold in the offline-accrued digest (D-14 backfill) as aggregated count rows, keeping the
    # letter×criterion keying. Present only when the client queued offline attempts; a normal online
    # turn ships no digest -> no digest rows (the model_dump field name is `pass_`, the wire key `pass`).
    for d in data.get("evidenceDigest") or []:
        passes = d.get("pass", d.get("pass_", 0)) or 0
        fails = d.get("fail", 0) or 0
        lid = d.get("letter")
        crit = d.get("criterion")
        if passes:
            rows.append(
                {"letter": lid, "criterion": crit, "passed": True, "source": _SOURCE_DIGEST, "count": passes}
            )
        if fails:
            rows.append(
                {"letter": lid, "criterion": crit, "passed": False, "source": _SOURCE_DIGEST, "count": fails}
            )

    return rows


def append_evidence(uid: str, rows: list[dict]) -> None:
    """Batch-append derived evidence rows to children/{uid}/evidence/{autoId} (D-13).

    Server-written ONLY, via the already-initialized firebase_admin default app (auth.py inits ADC —
    this reuses it, zero new package). Auto-id docs => append-only (no hot doc, no read-modify-write).
    ONE batch => a single round-trip. Called OFF the /coach critical path (a BackgroundTask), so the
    child never waits on Firestore. No-op on an empty row list (a label-only attempt writes nothing).
    """
    if not rows:
        return
    db = firestore.client()
    batch = db.batch()
    col = db.collection("children").document(uid).collection("evidence")
    now = _dt.datetime.now(_dt.timezone.utc)
    ttl_at = now + _dt.timedelta(days=_TTL_DAYS)
    for row in rows:
        batch.set(col.document(), {**row, "ts": now, "ttlAt": ttl_at})
    batch.commit()
