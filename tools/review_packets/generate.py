"""Generate the per-letter sign-off review packets.

Reads ``assets/curriculum/letters.json`` (read-only) and, for every letter with
``signedOff: false``, writes a self-contained HTML page rendering:

  * the letter char + name and its four positional forms;
  * its ``referenceStrokes`` as SVG, with stroke-order numbers and direction
    arrows, plus a plain-language stroke legend;
  * its ``commonMistakes`` (the tutor's voice) and ``cleanRepsToAdvance``;
  * a per-section review checklist (approve / needs-correction + notes).

Every page is stamped **DRAFT — model-authored, awaiting review**, is RTL-correct
for the Arabic, and is print-friendly. An ``index.html`` links them in intro order.

Run from ``tools/``:  ``python -m review_packets``
"""

from __future__ import annotations

import html
import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LETTERS_JSON = REPO_ROOT / "assets" / "curriculum" / "letters.json"
OUT_DIR = REPO_ROOT / "docs" / "curriculum" / "review-packets"

# Per-stroke-order colours (ink-on-parchment palette; colour-blind-safe order).
STROKE_COLORS = ["#1f5673", "#b5502a", "#3c6e47", "#7a4e9e", "#a8871f"]

DIRECTION_LABEL = {
    "topToBottom": "top → bottom",
    "bottomToTop": "bottom → top",
    "rightToLeft": "right → left",
    "leftToRight": "left → right",
    "tap": "tap (place the dot)",
}


def _esc(text: str) -> str:
    return html.escape(str(text), quote=True)


# --------------------------------------------------------------------------- #
# SVG rendering of referenceStrokes
# --------------------------------------------------------------------------- #

def _fit_transform(strokes: list[dict]) -> "callable":
    """Return a fn mapping normalized 0..1 points into a padded 100-box.

    The reference points for most letters occupy only the middle of their frame,
    which makes the drawing (and its order badges) tiny and overlapping. We fit
    the whole glyph uniformly (aspect preserved) into the 10..90 region so stroke
    order and direction read clearly — the point of the packet.
    """
    xs, ys = [], []
    for s in strokes:
        for x, y in s.get("points", []):
            xs.append(float(x))
            ys.append(float(y))
    if not xs:
        return lambda x, y: (x * 100, y * 100)
    min_x, max_x, min_y, max_y = min(xs), max(xs), min(ys), max(ys)
    span = max(max_x - min_x, max_y - min_y, 1e-6)
    scale = 80.0 / span  # fit into an 80-wide region
    # Centre the fitted glyph in the 100-box.
    off_x = (100 - (max_x - min_x) * scale) / 2 - min_x * scale
    off_y = (100 - (max_y - min_y) * scale) / 2 - min_y * scale
    return lambda x, y: (x * scale + off_x, y * scale + off_y)


def render_strokes_svg(strokes: list[dict]) -> str:
    """Render ordered strokes to an SVG string (normalized coords fitted to a 100 box)."""
    parts: list[str] = []
    fit = _fit_transform(strokes)
    # Faint guide box so the reviewer sees the writing frame.
    parts.append(
        '<rect x="0" y="0" width="100" height="100" fill="none" '
        'stroke="#d8ccb4" stroke-width="0.5" />'
    )

    for i, stroke in enumerate(strokes):
        color = STROKE_COLORS[i % len(STROKE_COLORS)]
        order = stroke.get("order", i + 1)
        pts = [fit(float(x), float(y)) for x, y in stroke.get("points", [])]
        if not pts:
            continue
        marker_id = f"arrow{i}"

        if stroke.get("type") == "dot" or len(pts) == 1:
            cx, cy = pts[0]
            parts.append(f'<circle cx="{cx:.2f}" cy="{cy:.2f}" r="3.2" fill="{color}" />')
            _badge(parts, cx + 5, cy - 5, order, color)
            continue

        # Arrowhead marker oriented along the path end.
        parts.append(
            f'<defs><marker id="{marker_id}" markerWidth="6" markerHeight="6" '
            f'refX="4" refY="3" orient="auto" markerUnits="strokeWidth">'
            f'<path d="M0,0 L6,3 L0,6 Z" fill="{color}" /></marker></defs>'
        )
        poly = " ".join(f"{x:.2f},{y:.2f}" for x, y in pts)
        parts.append(
            f'<polyline points="{poly}" fill="none" stroke="{color}" '
            f'stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" '
            f'marker-end="url(#{marker_id})" />'
        )
        # Order badge at the start of the stroke.
        sx, sy = pts[0]
        _badge(parts, sx, sy, order, color)

    return (
        '<svg viewBox="-10 -10 120 120" width="320" height="320" '
        'role="img" xmlns="http://www.w3.org/2000/svg">'
        + "".join(parts)
        + "</svg>"
    )


def _badge(parts: list[str], x: float, y: float, order: int, color: str) -> None:
    parts.append(
        f'<circle cx="{x:.2f}" cy="{y:.2f}" r="5" fill="#fffaf0" stroke="{color}" stroke-width="1" />'
    )
    parts.append(
        f'<text x="{x:.2f}" y="{y:.2f}" font-size="6" fill="{color}" '
        f'text-anchor="middle" dominant-baseline="central" '
        f'font-family="sans-serif" font-weight="700">{order}</text>'
    )


def render_stroke_legend(strokes: list[dict]) -> str:
    rows = []
    for i, s in enumerate(strokes):
        color = STROKE_COLORS[i % len(STROKE_COLORS)]
        direction = DIRECTION_LABEL.get(s.get("direction", ""), _esc(s.get("direction", "")))
        rows.append(
            f"<tr>"
            f'<td><span class="dot" style="background:{color}"></span>{_esc(s.get("order", i + 1))}</td>'
            f"<td>{_esc(s.get('label', ''))}</td>"
            f"<td>{_esc(s.get('type', ''))}</td>"
            f"<td>{direction}</td>"
            f"</tr>"
        )
    return "\n".join(rows)


# --------------------------------------------------------------------------- #
# Checklist helpers
# --------------------------------------------------------------------------- #

def _check_row(label_html: str) -> str:
    """One review row: approve / needs-correction boxes + a notes line."""
    return (
        '<div class="check-row">'
        f'<div class="check-label">{label_html}</div>'
        '<label class="opt"><span class="box"></span> approve</label>'
        '<label class="opt"><span class="box"></span> needs correction</label>'
        '<div class="notes">notes:</div>'
        "</div>"
    )


# --------------------------------------------------------------------------- #
# Page + index
# --------------------------------------------------------------------------- #

_STYLE = """
:root { --parchment:#fbf5e6; --ink:#2b2320; --rule:#d8ccb4; --accent:#7a4e9e; }
* { box-sizing: border-box; }
body { margin:0; background:#efe6d2; color:var(--ink);
  font-family: 'Segoe UI', system-ui, sans-serif; line-height:1.5; }
.arabic { font-family: 'Noto Naskh Arabic', 'Amiri', 'Segoe UI', 'Traditional Arabic', serif; }
.page { max-width: 900px; margin: 24px auto; background: var(--parchment);
  padding: 32px 40px; box-shadow: 0 2px 10px rgba(0,0,0,.12); }
.stamp { background:#8a1f1f; color:#fff; font-weight:700; letter-spacing:.04em;
  padding:8px 14px; border-radius:4px; display:inline-block; margin-bottom:18px;
  text-transform:uppercase; font-size:14px; }
h1 { margin:.2em 0; font-size:28px; }
h2 { margin:1.4em 0 .5em; font-size:20px; border-bottom:2px solid var(--rule); padding-bottom:4px; }
.subtle { color:#6b5f52; font-size:14px; }
.glyph { font-size:96px; line-height:1; }
.grid { display:flex; gap:20px; flex-wrap:wrap; align-items:flex-start; }
.forms { display:flex; gap:14px; flex-wrap:wrap; direction:rtl; }
.form-card { background:#fffaf0; border:1px solid var(--rule); border-radius:8px;
  padding:12px 16px; text-align:center; min-width:96px; }
.form-card .g { font-size:48px; line-height:1.1; }
.form-card .lbl { font-size:12px; color:#6b5f52; margin-top:6px; direction:ltr; }
svg { background:#fffaf0; border:1px solid var(--rule); border-radius:8px; }
table { border-collapse:collapse; width:100%; margin-top:8px; font-size:14px; }
th, td { border:1px solid var(--rule); padding:6px 10px; text-align:left; }
th { background:#f0e7d3; }
.dot { display:inline-block; width:10px; height:10px; border-radius:50%; margin-right:6px; vertical-align:middle; }
.mistake { background:#fffaf0; border:1px solid var(--rule); border-left:4px solid var(--accent);
  border-radius:6px; padding:10px 14px; margin:8px 0; }
.mistake .fb { font-size:16px; }
.mistake .meta { font-size:12px; color:#6b5f52; margin-top:4px; font-family:monospace; }
.reps { font-size:16px; }
.reps b { font-size:22px; }
.check-row { display:flex; align-items:center; gap:16px; flex-wrap:wrap;
  padding:8px 0; border-bottom:1px dashed var(--rule); }
.check-label { flex:1 1 260px; min-width:220px; }
.opt { font-size:14px; white-space:nowrap; }
.box { display:inline-block; width:16px; height:16px; border:2px solid var(--ink);
  border-radius:3px; vertical-align:middle; margin-right:4px; }
.notes { flex:1 1 200px; border-bottom:1px solid var(--ink); min-height:22px; color:#6b5f52; font-size:13px; }
.nav { display:flex; justify-content:space-between; margin-top:28px; font-size:14px; }
.nav a { color:var(--accent); text-decoration:none; }
.foot { margin-top:22px; font-size:12px; color:#6b5f52; border-top:1px solid var(--rule); padding-top:10px; }
@media print {
  body { background:#fff; }
  .page { box-shadow:none; margin:0; max-width:none; }
  .stamp { -webkit-print-color-adjust:exact; print-color-adjust:exact; }
  a { color:var(--ink); }
}
"""


def _html_shell(title: str, body: str) -> str:
    return (
        "<!doctype html>\n"
        '<html lang="en" dir="ltr">\n<head>\n'
        '<meta charset="utf-8" />\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1" />\n'
        f"<title>{_esc(title)}</title>\n"
        f"<style>{_STYLE}</style>\n"
        "</head>\n<body>\n"
        f'<div class="page">\n{body}\n</div>\n'
        "</body>\n</html>\n"
    )


def render_letter_page(letter: dict, prev_link: tuple[str, str] | None,
                       next_link: tuple[str, str] | None) -> str:
    name = letter.get("name", {})
    display = name.get("display", letter["id"])
    ar_name = name.get("ar", "")
    char = letter.get("char", "")
    order = letter.get("introOrder", "?")
    forms = letter.get("forms", {})
    strokes = letter.get("referenceStrokes", [])
    mistakes = letter.get("commonMistakes", [])
    reps = letter.get("cleanRepsToAdvance", "?")

    form_cards = "".join(
        f'<div class="form-card"><div class="g arabic">{_esc(forms.get(f, ""))}</div>'
        f'<div class="lbl">{f}</div></div>'
        for f in ("isolated", "initial", "medial", "final")
    )

    mistake_html = "".join(
        f'<div class="mistake"><div class="fb arabic-ok">{_esc(m.get("feedback", ""))}</div>'
        f'<div class="meta">id: {_esc(m.get("id", ""))} · check: {_esc(m.get("check", ""))}</div></div>'
        for m in mistakes
    )

    # Checklist: one row per reviewable facet.
    checklist_rows = [
        _check_row("<b>Stroke order &amp; direction</b> — is this how you draw it?"),
        _check_row("<b>Number of strokes / parts</b> — correct count (body, dots)?"),
        _check_row("<b>Dot count &amp; placement</b> — right number, right side?"),
        _check_row("<b>The four forms</b> — isolated / initial / medial / final look right?"),
    ]
    for m in mistakes:
        fb = _esc(m.get("feedback", ""))
        checklist_rows.append(
            _check_row(f'Common mistake — feedback wording in <i>your</i> voice:<br>'
                       f'<span class="arabic-ok">“{fb}”</span>')
        )
    checklist_rows.append(
        _check_row(f"<b>Clean reps to advance</b> — is <b>{_esc(reps)}</b> right for this letter?")
    )
    checklist_rows.append(_check_row("<b>Overall</b> — ready to sign off?"))

    nav_prev = f'<a href="{prev_link[0]}">← {_esc(prev_link[1])}</a>' if prev_link else "<span></span>"
    nav_next = f'<a href="{next_link[0]}">{_esc(next_link[1])} →</a>' if next_link else "<span></span>"

    body = f"""
<div class="stamp">Draft — model-authored, awaiting review</div>
<div class="grid">
  <div>
    <div class="glyph arabic">{_esc(char)}</div>
  </div>
  <div>
    <h1>{_esc(display)} &nbsp;<span class="arabic">{_esc(ar_name)}</span></h1>
    <div class="subtle">letterId <code>{_esc(letter["id"])}</code> · intro order {_esc(order)}
      · <b>signedOff: false</b></div>
    <p class="subtle">Please confirm or correct each item below. Nothing reaches a
      child until you sign it. A little Arabic in the feedback is welcome (أحسنت).</p>
  </div>
</div>

<h2>The four forms</h2>
<div class="forms">{form_cards}</div>

<h2>How the letter is written (drafted stroke order)</h2>
<div class="grid">
  <div>{render_strokes_svg(strokes)}</div>
  <div style="flex:1 1 320px">
    <p class="subtle">Numbers show the order; arrows show the direction the pen
      travels. Dots are placed after the body.</p>
    <table>
      <thead><tr><th>#</th><th>part</th><th>type</th><th>direction</th></tr></thead>
      <tbody>{render_stroke_legend(strokes)}</tbody>
    </table>
  </div>
</div>

<h2>Common mistakes (the tutor's voice)</h2>
{mistake_html or '<p class="subtle">None drafted.</p>'}

<h2>Mastery</h2>
<p class="reps">Clean repetitions to advance: <b>{_esc(reps)}</b></p>

<h2>Your review &amp; sign-off</h2>
{''.join(checklist_rows)}

<div class="check-row" style="border-bottom:none; margin-top:10px">
  <div class="check-label"><b>Reviewer</b></div>
  <div class="notes">name:</div>
  <div class="notes">date:</div>
</div>

<div class="nav">{nav_prev}<a href="index.html">index</a>{nav_next}</div>
<div class="foot">Qalam · Phase 18.1 content review · generated from
  <code>assets/curriculum/letters.json</code> by <code>tools/review_packets</code>.
  Stroke geometry is a model draft; the visible glyph the child traces comes from the
  app font, not these strokes.</div>
"""
    # Apply the Arabic font to feedback text (mixed-language, so scope a class).
    body = body.replace("arabic-ok", "arabic")
    return _html_shell(f"Review · {display} ({letter['id']})", body)


def render_index(letters: list[dict]) -> str:
    rows = []
    for l in letters:
        fname = f"{int(l['introOrder']):02d}-{l['id']}.html"
        rows.append(
            f"<tr>"
            f"<td>{_esc(l['introOrder'])}</td>"
            f'<td class="arabic" style="font-size:28px">{_esc(l.get("char",""))}</td>'
            f'<td>{_esc(l.get("name",{}).get("display", l["id"]))}</td>'
            f"<td><code>{_esc(l['id'])}</code></td>"
            f'<td><a href="{fname}">open review packet →</a></td>'
            f"</tr>"
        )
    body = f"""
<div class="stamp">Draft — model-authored, awaiting review</div>
<h1>Letter sign-off review packets</h1>
<p class="subtle">{len(letters)} letters still need the owner's-mother's sign-off
  (<code>signedOff: false</code>). Each packet shows the drafted stroke order,
  the four forms, the common mistakes and a sign-off checklist. Print or mark up
  on iPad. Ordered by intro order.</p>
<table>
  <thead><tr><th>order</th><th>letter</th><th>name</th><th>id</th><th></th></tr></thead>
  <tbody>{''.join(rows)}</tbody>
</table>
<div class="foot">Qalam · Phase 18.1 · regenerate any time with
  <code>python -m review_packets</code> (from <code>tools/</code>).</div>
"""
    return _html_shell("Qalam — letter review packets", body)


def main() -> int:
    data = json.loads(LETTERS_JSON.read_text(encoding="utf-8"))
    unsigned = [l for l in data["letters"] if not l.get("signedOff", False)]
    unsigned.sort(key=lambda l: int(l["introOrder"]))

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    written = 0
    for i, letter in enumerate(unsigned):
        fname = f"{int(letter['introOrder']):02d}-{letter['id']}.html"
        prev_link = None
        if i > 0:
            p = unsigned[i - 1]
            prev_link = (f"{int(p['introOrder']):02d}-{p['id']}.html",
                         p.get("name", {}).get("display", p["id"]))
        next_link = None
        if i < len(unsigned) - 1:
            n = unsigned[i + 1]
            next_link = (f"{int(n['introOrder']):02d}-{n['id']}.html",
                         n.get("name", {}).get("display", n["id"]))
        (OUT_DIR / fname).write_text(
            render_letter_page(letter, prev_link, next_link), encoding="utf-8", newline="\n"
        )
        written += 1

    (OUT_DIR / "index.html").write_text(
        render_index(unsigned), encoding="utf-8", newline="\n"
    )

    print(f"Wrote {written} review packet(s) + index.html to "
          f"{OUT_DIR.relative_to(REPO_ROOT)}")
    signed = [l["id"] for l in data["letters"] if l.get("signedOff", False)]
    print(f"  ({len(signed)} already signed, skipped: {', '.join(signed) or 'none'})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
