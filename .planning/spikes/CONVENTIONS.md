# Spike Conventions

Patterns and stack choices established across spike sessions. New spikes follow these unless the
question requires otherwise.

## Stack

- **Backend / harness:** Python via **`uv`**, run against the tutor server's environment:
  `uv run --project server [--with pillow] python <abs path>`. Reuse the deployed server's deps
  (langchain, langchain-google-vertexai) rather than a fresh venv. (CLAUDE.md: Python over TS for
  tooling.)
- **Model access:** Gemini-2.5-flash **on Vertex**, `thinking_budget=0` (else 2.5 returns empty).
  Local harness has no ADC → inject the owner's user token (`gcloud auth print-access-token`) as the
  credential, same project (`qalam-app-bd7d0`), keyless posture. Production auth (runtime SA ADC) is
  unchanged. Tokens expire ~1h; the harness re-mints per run.
- **Frontend:** the GenUI spike (11) used the Flutter app on the Pixel-Tablet emulator. Stroke-aware
  (001–005) is server-side, so it renders to PNG (Pillow) for inspection instead.

## Structure

- `.planning/spikes/NNN-name/` — one dir per spike: `README.md` (frontmatter + Research +
  Investigation Trail + Results), `run.py` (thin, OFFLINE analysis), optional `notes.md`.
- `.planning/spikes/_lib/` — shared throwaway code (underscore = excluded from the `NNN-*` scan).
- `.planning/spikes/_artifacts/` — generated outputs (`results.json`, rendered PNGs). Re-creatable.
- **One expensive model pass** (`_lib/experiment.py`) writes a rich `results.json`; each spike's
  `run.py` reads it offline. Don't re-call the model per spike.

## Patterns

- **Reuse production primitives so spike results map to the real gate.** Stroke-aware imported the
  real `app.prompts.COACH_PROMPT`, `app.tools.ACTION_TOOLS`, `app.faithfulness`, and the production
  `JUDGE_RUBRIC.md` — isolating ONE variable at a time.
- **Control the obvious confound first.** The verbatim GOLD-EXEMPLAR parroting masked every signal
  until an anti-parrot arm was added; always smoke-test for the dominant confound before scaling.
- **Synthetic, no-PII fixtures** perturbed from the real authored reference
  (`assets/curriculum/letters.json`) — never real child data, even in a throwaway.
- **Concurrency** for many Vertex calls: `ThreadPoolExecutor(max_workers=8)` + a retry wrapper.
- **Additive + deletable:** the whole spike lives under `.planning/spikes/` and touches no durable
  app code (mirrors the GenUI spike's SC-4 discipline).

## Tools & Libraries

- `langchain-google-vertexai` `ChatVertexAI` (accepts `credentials=` for token injection;
  `thinking_budget=0`). NOTE: it warns "deprecated → langchain-google-genai" but is what production
  uses — keep parity with `app/models.py`.
- `pillow` for stroke rendering (lightweight; `ImageDraw.line(..., joint="curve")`).
- `gcloud auth print-access-token` for local Vertex creds (NOT `application-default login`, which is
  interactive and absent here).
