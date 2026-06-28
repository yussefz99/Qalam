# Phase 16: BUILD — presence + voice + eval gate + demo-harden - Pattern Map

**Mapped:** 2026-06-29
**Files analyzed:** 9 (3 NEW, 6 EDIT/GROW)
**Analogs found:** 9 / 9 (all surfaces have a real in-repo analog)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/tutor/tts_coach_speaker.dart` | service (on-device speaker) | request-response (text → audio), graceful-degrade | `lib/services/asset_audio_player.dart` | role-match (audio out, never-block) |
| `lib/tutor/tts_coach_speaker.dart` (provider) | provider | — | `lib/providers/audio_providers.dart` (`audioPlayerProvider`) | exact (Provider + onDispose seam) |
| `lib/features/letter_unit/widgets/exercise_scaffold.dart` | component (widget) | event-driven (verdict → line → speak) | itself (`_onResult`, lines 169-218; `_TutorColumn`, 391-508) | self-edit |
| `lib/tutor/remote_agent_brain.dart` | service (brain) | request-response (HTTP → decision) | itself + `tutor_brain.dart` seam | self-edit |
| `lib/tutor/authored_fallback_brain.dart` | service (brain, offline floor) | transform (facts → authored line) | itself | self-edit |
| `lib/tutor/tutor_dispatcher.dart` | utility (closed switch) | event-driven (tool name → controller call) | itself | self-edit |
| `server/app/models.py` | config (per-node routing table) | transform (env → bound model) | itself (`build_coach_model`, lines 83-97) | self-edit |
| `server/app/faithfulness.py` + `server/tests/test_faithfulness.py` | service + test (model-free gate) | batch (JSONL → rate report) | itself (15-06 seed) | self-grow |
| `server/tests/test_eval/` (NEW: cases + judge runner) | test (eval harness) | batch (labeled set → per-dimension scores) | `server/tests/test_faithfulness.py` + `fixtures/faithfulness_set.jsonl` | role-match |
| `server/Makefile` (or `run_eval.py`) | config (gate entrypoint) | batch (run → exit code) | `pyproject.toml` `[tool.pytest.ini_options]` + `uv run pytest -m code` convention | role-match |
| `server/app/main.py` | controller (FastAPI routes) | request-response | itself (`/health` lines 61-68, `/coach` lines 71-128) | self-edit |
| AndroidManifest `<queries>` TTS_SERVICE | config | — | `android/app/src/main/AndroidManifest.xml` (existing `<queries>` block lines 40-46) | exact (extend the block) |
| `flutter_tts` legitimacy checkpoint | gate (plan task) | — | 07-02-PLAN `T-07-02-01` / `checkpoint:human-verify gate="blocking-human"` | exact (copy task shape) |

---

## Pattern Assignments

### `lib/tutor/tts_coach_speaker.dart` (NEW — service, request-response + graceful-degrade)

**Analog:** `lib/services/asset_audio_player.dart` (the only on-device audio-out seam; same never-block posture)

**Why this analog:** it is the established "speak/play audio, swallow every error, never gate the trace loop" surface. TTS is a *separate coaching-voice surface* alongside it (CONTEXT: "S1-06's 'no TTS' applies only to letter/word *pronunciation*, not the coach voice"), but it must copy the same discipline: one reusable native handle, a pure unit-testable resolver, and silent degrade.

**Never-block posture to replicate** (`asset_audio_player.dart` lines 96-116):
```dart
  @override
  Future<void> playLetter(String assetPath) async {
    final String? asset = audioAssetFor(assetPath);
    if (asset == null) return;            // nothing to play → silent no-op
    try {
      await _player.stop();               // re-tap restarts cleanly, no overlap
      await _player.play(AssetSource(sourcePath));
    } catch (_) {
      // Missing file / decode error / platform hiccup → swallow. Audio is an
      // enhancement, never a gate on the trace loop (T-07-02-04).
    }
  }
```

**Pure, device-free resolver to replicate** (`asset_audio_player.dart` lines 78-94, `static String? audioAssetFor`): the new file's `segmentByScript(line)` is the analog — a `static` pure-Dart function (Arabic block U+0600–U+06FF + presentation forms vs the rest) that returns `[(locale, text)]` runs, **unit-tested with no device** (mirrors the `audioAssetFor` resolver tests).

**Conventions the executor MUST replicate:**
- One reusable `FlutterTts` instance for the app lifetime (mirrors the single `AudioPlayer _player`), with a `dispose()` method called from provider disposal.
- The implemented mixed-language pattern (RESEARCH Pattern 2): `await tts.awaitSpeakCompletion(true)` → check `await tts.isLanguageAvailable('ar')` once → per-segment `setLanguage('ar'|'en-US')` + sequential `await tts.speak(text)`; `if (locale == 'ar' && !arOk) continue;` graceful-degrade (skip the Arabic token, keep flow).
- TTS is **display-only** (ADR-014): never throw to the caller, never block the visual; a missing voice is a silent skip, exactly like an unknown audioId.
- File-header doc-comment block in the project house style (see `asset_audio_player.dart` lines 1-25): purpose, seam contract, NEVER-BLOCK POSTURE, degrade rules — the executor should write the same kind of header.

**Provider wiring analog:** `lib/providers/audio_providers.dart` lines 13-35:
```dart
abstract interface class LetterAudioPlayer {
  Future<void> playLetter(String assetPath);
}

final audioPlayerProvider = Provider<LetterAudioPlayer>((ref) {
  final player = AssetLetterAudioPlayer();
  ref.onDispose(player.dispose);   // dispose native handle on teardown
  return player;
});
```
Replicate: an `abstract interface class` seam (so a Noop can be injected in tests, like `NoopLetterAudioPlayer`), a `Provider<...>` returning the real impl, and `ref.onDispose(speaker.dispose)`. **Riverpod-only** (CLAUDE.md Decided). Define a `NoopTtsCoachSpeaker` for widget/unit-test overrides (mirrors `NoopLetterAudioPlayer`, lines 17-21).

---

### `lib/features/letter_unit/widgets/exercise_scaffold.dart` (EDIT — component, event-driven)

**Analog:** itself — the brain→line wiring already lives in `_onResult` (lines 169-218) and the line surfaces in `_TutorColumn._bubbleText` (lines 494-508).

**The exact hook point** — after the verdict and after `tutorLineProvider.set(line)` (lines 206-217):
```dart
    brain.next(facts).then((decision) {
      if (!mounted) return;
      final line = _lineOf(decision);
      ref.read(tutorLineProvider.notifier).set(line.isNotEmpty ? line : null);
      // ← PHASE 16 HOOK: a BEAT after the visual, speak `line` (pass OR miss, D-05)
    }).catchError((_) {
      if (mounted) ref.read(tutorLineProvider.notifier).clear();
    });
```

**Conventions the executor MUST replicate:**
- The **two clocks** (D-05): the scorer verdict already renders instantly via `applyResult` (line 171, runs FIRST, unchanged — GROUND-01). The spoken line is fired **a beat later**, inside the `.then(...)` after `set(line)`, on **both** pass and miss. Read the speaker via `ref.read(ttsCoachSpeakerProvider).speak(line)` — do NOT `await` it in a way that blocks the UI; fire-and-forget so a slow synth never stalls the child.
- Guard with `if (!mounted) return;` (already present, line 207) before touching providers/speaker.
- Speak the same `line` the bubble shows: prefer the agent line, degrade to the authored floor (`_bubbleText`, lines 499-507). When `line` is empty the floor's verdict-side authored line is what shows — the speaker should speak that authored line too (D-04: the floor speaks in airplane mode). Practically: pass the resolved bubble text to the speaker, not just the agent line, so the offline floor is voiced.
- `initState` clears stale state (lines 155-159); on `_clear()` (lines 229-235) also stop/clear any in-flight TTS so a cleared idle is silent.

---

### `lib/tutor/remote_agent_brain.dart` / `authored_fallback_brain.dart` / `tutor_dispatcher.dart` (EDIT — TTS hooks / floor already here)

**Analog:** these files themselves; the seam is already built.

**`remote_agent_brain.dart` — the degrade contract to preserve** (lines 70-106): every failure path (`null` token, non-200, parse fail, timeout, offline, any exception) returns `fallback.next(facts)` and **NEVER throws** (G5/TUTOR-02). The Phase-16 edits must NOT change this — the spoken line rides whatever decision this returns. The TTS is invoked downstream in the scaffold, not inside the brain (keep the brain a pure FACTS→ACTION transform with no audio import).

**`authored_fallback_brain.dart` — the floor that must also speak** (lines 26-32, 39-53): it returns a `PresentActivity(coachingLine: line, ...)` resolving `feedback['pass']` / `feedback[mistakeId]` / first-non-pass line. D-04 makes THIS line speak via on-device TTS in airplane mode. No change to the resolution logic; the voicing happens in the scaffold hook above. Keep it **pure Dart, zero cloud/model/Firebase/network imports** (the file's library doc-comment lines 1-11 states this invariant — preserve it).

**`tutor_dispatcher.dart` — the closed grounding switch** (lines 38-78): the `switch` over the sealed `TutorDecision` (lines 39-49) and the raw-name dispatch (lines 58-78) are exhaustive; **there is no `setVerdict`/`awardStar` branch** and an unrecognized tool is a logged no-op (line 76: `debugPrint('TutorDispatcher: ignoring unrecognized tool "$name"')`). Any Phase-16 touch here must keep both grounding rules. TTS is NOT a new dispatch branch — voice is display-only, layered in the scaffold, never a dispatched action.

**Convention:** all three files carry a `library;`-style file-header doc-comment asserting "pure Dart, no cloud-AI / on-device-model imports." Keep that true — the TTS package (`flutter_tts`) is imported only in `tts_coach_speaker.dart` and used from the widget/provider layer, never inside these brain/dispatcher contract files.

---

### `server/app/models.py` (EDIT — config, per-node routing table)

**Analog:** itself — `build_coach_model()` (lines 83-97) + the env-driven default block (lines 38-41).

**The branch point to extend** (lines 83-97):
```python
def build_coach_model():
    from langchain.chat_models import init_chat_model
    return init_chat_model(
        COACH_MODEL,
        model_provider=COACH_MODEL_PROVIDER,
        temperature=COACH_TEMPERATURE,
        max_tokens=COACH_MAX_TOKENS,            # never unbounded (4b.3)
        **_provider_kwargs(COACH_MODEL_PROVIDER),
    )
```

**Env-default convention to replicate** (lines 38-41):
```python
COACH_MODEL = os.environ.get("COACH_MODEL", "claude-haiku-4-5")
COACH_MODEL_PROVIDER = os.environ.get("COACH_MODEL_PROVIDER", "anthropic")
COACH_TEMPERATURE = float(os.environ.get("COACH_TEMPERATURE", "0.5"))
COACH_MAX_TOKENS = int(os.environ.get("COACH_MAX_TOKENS", "256"))
```

**Conventions the executor MUST replicate:**
- Add a `COACH_MODEL_PROVIDER == "anthropic_vertex"` branch in `build_coach_model()` that builds `ChatAnthropicVertex` (RESEARCH Pattern 1) instead of `init_chat_model`; add a `COACH_LOCATION = os.environ.get("COACH_LOCATION", "global")` env (Claude does NOT serve us-central1). Return the model **UNbound** — `coach.py:build_coach_with_tools()` (coach.py line 46) calls `.bind_tools(ACTION_TOOLS, tool_choice="any")`; that stays in the node.
```python
    # the D-03 branch (only after a human Enables Claude in Model Garden):
    if COACH_MODEL_PROVIDER == "anthropic_vertex":
        from langchain_google_vertexai.model_garden import ChatAnthropicVertex
        return ChatAnthropicVertex(
            model_name=COACH_MODEL,            # claude-haiku-4-5@20251001
            project=os.environ["GCP_PROJECT_ID"],
            location=COACH_LOCATION,           # "global" — NOT us-central1
            temperature=COACH_TEMPERATURE, max_tokens=COACH_MAX_TOKENS,
        )                                      # keyless: runtime SA ADC
```
- **D-02 supersedes the current defaults:** the live deploy already runs all 3 nodes on `google_vertexai`/`gemini-2.5-flash` (RESEARCH: live probe). Update the in-file default strings + the docstring table (lines 8-13) to the keyless-Vertex truth (`google_vertexai`), and update `server/.env.example` + `server/README.md` (RESEARCH: both stale). Keep Gemini the shippable default; Claude is the env-swap upgrade.
- Keep the **lazy-import** convention (line 84 doc + line 89 import-inside-function) so importing the module needs no provider key; tests monkeypatch `build_coach_with_tools` (test_endpoint.py lines 90-92).
- Keep `_provider_kwargs` (lines 44-54): `thinking_budget=0` for `google_vertexai` only.

---

### `server/app/faithfulness.py` + `server/tests/test_faithfulness.py` (GROW — service + test, model-free zero-tolerance gate)

**Analog:** itself — the 15-06 seed. Grow it; do NOT build a new engine (RESEARCH "Don't Hand-Roll": faithfulness is at 69% baseline, model-free).

**The deterministic predicate to grow** (`faithfulness.py` lines 49-67): `_contradicts(passed, coaching, expected_fix)` flags (a) praise-on-fail (any `_PRAISE` token on a fail) and (b) wrong-fix (a fail whose coaching omits `expected_fix`). The `_PRAISE` lexicon (lines 39-46) includes `أحسنت`. The rate reporter is `evaluate_faithfulness(path)` (lines 87-117) returning `{faithful, flagged, total, rate}`.

**The test marker + fixture-load convention to replicate** (`test_faithfulness.py` lines 27, 34-38):
```python
pytestmark = pytest.mark.code        # model-free check that gates every PR
...
_SET = pathlib.Path(__file__).parent / "fixtures" / "faithfulness_set.jsonl"
def _load_cases() -> list[dict]:
    return [json.loads(line) for line in _SET.read_text(encoding="utf-8").splitlines() if line.strip()]
```

**The JSONL case shape to extend** (`fixtures/faithfulness_set.jsonl`):
```json
{"passed": false, "mistakeId": "shallowBowl", "expectedFix": "deeper curve", "coaching": "Your baa needs a deeper curve at the bottom — try again, slower this time.", "label": "faithful"}
{"passed": false, "mistakeId": "shallowBowl", "expectedFix": "deeper curve", "coaching": "Great job! That looks perfect.", "label": "adversarial_praise_on_fail"}
```

**Conventions the executor MUST replicate:**
- **Zero-tolerance (D-08):** the grown faithfulness gate fails the build on ANY contradiction (D1 = 100%). Keep the model-free predicate as the floor; widen the labeled set (every baa mistake × pass/fail) rather than adding a model judge here.
- `pytestmark = pytest.mark.code` on every model-free test (the `code` marker is registered in `pyproject.toml` lines 36-38 and gates every PR — `uv run pytest -m code -q`).
- Keys mirror the fixture: `passed`, `mistakeId`, `expectedFix`, `coaching`, `label` (labels `faithful` / `adversarial_praise_on_fail` / `adversarial_wrong_fix`).
- `.dockerignore` excludes `tests/` (faithfulness.py header lines 27-28) — the labeled set is an offline-CI artifact, never shipped. Keep it that way.

---

### `server/tests/test_eval/` (NEW — test, batch; the EVAL-01/02 harness)

**Analog:** `server/tests/test_faithfulness.py` (the model-free leg) + `fixtures/faithfulness_set.jsonl` (the labeled-set format) + `conftest.py` (the offline-monkeypatch pattern) + `test_endpoint.py` (the fake-model injection).

**Conventions the executor MUST replicate:**
- **Two legs in one harness (D-10):** (1) the model-free zero-tolerance faithfulness leg (reuse `evaluate_faithfulness`, `pytest.mark.code`, offline); (2) a **Vertex LLM-judge** leg for register + correct-Arabic scored on a **threshold** (NOT zero-tolerance), which calls Vertex (integration, not `code`-marked). The judge runner is `server/tests/test_eval/run_judge.py` (RESEARCH Test Map) invoked by `make eval`.
- **Labeled-case format:** mirror `faithfulness_set.jsonl` — JSONL of `(verdict, learner-state)` cases (lowest-friction per RESEARCH Wave-0). The **mom-signed gold set** is a separate JSONL (Claude DRAFTS, owner's mother REVIEWS+SIGNS — the curriculum sign-off gate; nothing register-shaping ships unsigned).
- **Coach-under-test ≠ judge model** (RESEARCH Open Q2: avoid self-grading bias); start the judge on `gemini-2.5-flash` (keyless, us-central1), require ≥0.7 correlation with mom's labels before trusting it.
- **Offline fakes for the `code` leg** (conftest.py lines 32-55: `fake_firebase` monkeypatches; test_endpoint.py lines 26-92: `_FakeBoundCoach` / `_FakeStructured` / `_patch_coach`). The model-free leg must run offline; only the LLM-judge leg touches Vertex.
- Regulatory note (D-10 / 14-AI-SPEC §1b): the labeled set / transcripts must NOT train/fine-tune models without separate verifiable parental consent. The gold set is synthetic/authored non-PII.

---

### `server/Makefile` (or `server/tests/test_eval/run_eval.py`) (NEW — config, gate entrypoint)

**Analog:** the existing test-invocation convention (no Makefile exists today): `pyproject.toml` `[tool.pytest.ini_options]` (lines 34-38) + `cd server && uv run pytest -m code -q` (RESEARCH Validation Architecture).

**Conventions the executor MUST replicate:**
- `make eval` wraps the faithfulness (model-free, zero-tolerance) + Vertex LLM-judge run and **exits non-zero** below threshold (D-07/D-08): fail on D1 < 100% (faithfulness) OR D5/D2 below the register/Arabic threshold. This is the **local documented pre-merge step** — NOT CI (D-07).
- The bake-off (D-13) reuses the same target by env-swap: `COACH_MODEL_PROVIDER=anthropic_vertex COACH_LOCATION=global make eval` vs the Gemini run (RESEARCH Test Map).
- Use `uv run` (the project's runner) inside the Makefile target, consistent with `uv run pytest`. Keep `[tool.uv] package = false` (pyproject lines 43-44) — the server is a deployed app, not an installable package; the Makefile must not assume an installed package.

---

### `server/app/main.py` (EDIT — controller; `/coach` + warm-up)

**Analog:** itself — `/health` (lines 61-68) is the warm-up path already; `/coach` (lines 71-128) is the endpoint.

**The warm-up route is already correct** (lines 61-68): `GET /health`, no auth, returns `{"status": "ok"}`. The header (lines 1-7) documents WHY it must be `/health` not `/healthz` (Google's edge reserves `/healthz`). The client warm-up-ping (D-11) targets THIS route at session/unit start.

**The degrade contract to preserve** (lines 84-108): every failure (`asyncio.TimeoutError`, `StructuredOutputError`, any `Exception`) raises a structured **503** the client maps to its AuthoredFallback floor — NEVER 200-with-empty (G5 / no-dead-end). The exception handler (lines 131-134) is belt-and-suspenders.

**Conventions the executor MUST replicate:**
- Keep the timeout budget env-driven: `_TIMEOUT_SECONDS = float(os.environ.get("COACH_TIMEOUT_SECONDS", "8"))` (line 34; live deploy uses 12).
- Keep the wire-key camelCase normalization (`_to_wire_args`, lines 41-50) — the Dart `_parseCoachOut` reads `coachingLine`/`letterId`.
- Keep `_graph()` `@lru_cache(maxsize=1)` (lines 55-58) — build the graph once per process (stateless `InMemorySaver`).
- If streaming the coach turn (OPTIONAL per D-05), do it as a NEW path; the single-JSON `CoachOut` path stays the baseline. `await` the graph in the route; never `asyncio.run` inside (line 13 / 4b Async-First).

---

## Shared Patterns

### Package-legitimacy checkpoint (`flutter_tts`)
**Source:** `07-02-PLAN.md` `T-07-02-01` + the `<task type="checkpoint:human-verify" gate="blocking-human">` block (07-02-PLAN lines 82-92).
**Apply to:** the plan that adds `flutter_tts` (D-06; `autonomous: false`).
**Copy this exact task shape** (07-02-PLAN lines 82-92):
```xml
<task type="checkpoint:human-verify" gate="blocking-human">
  <name>Checkpoint: Package legitimacy gate — verify flutter_tts before install</name>
  <what-built>Selected flutter_tts 4.2.5 for on-device coach TTS — to be verified for legitimacy before install per the Package Legitimacy Gate.</what-built>
  <how-to-verify>
    1. Confirm on pub.dev: verified publisher (eyedeadevelopment.com / dlutton), recent releases, high likes/pub-points (1586 likes, 150/160 pts, ~267k/30d).
    2. Confirm it speaks a bundled string on Android offline with per-utterance setLanguage.
    3. Approve the exact version to pin (4.2.5), or name an alternative.
  </how-to-verify>
  <action>Blocking human checkpoint (gate="blocking-human"). Present what-built, perform how-to-verify WITH the human, HALT until the resume-signal. Do not proceed autonomously past this gate.</action>
  <resume-signal>Type "approved: flutter_tts@4.2.5" or name a different package/version.</resume-signal>
</task>
```
slopcheck does NOT cover pub.dev (Dart) — legitimacy rests on pub.dev signals + the blocking-human checkpoint, identical basis to `audioplayers`. Pin the version in `pubspec.yaml` (style: `flutter_tts: ^4.2.5` matching `audioplayers: ^6.5.0`, pubspec line 71).

### AndroidManifest `<queries>` TTS discoverability
**Source:** `android/app/src/main/AndroidManifest.xml` existing `<queries>` block (lines 40-46, currently a `PROCESS_TEXT` intent).
**Apply to:** the TTS plan (RESEARCH Pitfall 5 — Android 11+ package visibility).
**Add** a sibling `<intent>` inside the existing `<queries>` element (do not create a second `<queries>`):
```xml
<queries>
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
    <intent><action android:name="android.intent.action.TTS_SERVICE" /></intent>
</queries>
```

### Never-block / silent-degrade (the project's audio + brain invariant)
**Source:** `asset_audio_player.dart` (lines 96-116) + `remote_agent_brain.dart` (lines 70-106).
**Apply to:** `tts_coach_speaker.dart` and the scaffold speak-hook.
TTS is display-only (ADR-014): a missing Arabic voice, a synth error, or a slow first-synthesis must NEVER throw, block the visual, or stall the trace loop. Swallow everything; the instant on-screen verdict already rendered.

### pytest `code` marker (model-free PR gate)
**Source:** `pyproject.toml` lines 36-38 (`markers = ["code: ..."]`) + `pytestmark = pytest.mark.code` (test_faithfulness.py line 27, test_endpoint.py line 20, test_grounding.py line 17).
**Apply to:** every new model-free server test (faithfulness growth, the eval `code` leg). The Vertex LLM-judge leg is integration (calls Vertex) and is NOT `code`-marked — it runs under `make eval`, not the per-commit `uv run pytest -m code -q`.

### Riverpod-only provider style
**Source:** `audio_providers.dart` (`Provider` + `ref.onDispose`) + `tutor_providers.dart` (`NotifierProvider`, lines 98-111; `Provider` switch points lines 28-88).
**Apply to:** the new `ttsCoachSpeakerProvider`. CLAUDE.md Decided: Riverpod only (reject BLoC/GetX). Note `tutor_providers.dart` line 96: Riverpod 3 dropped `StateProvider` → use a `Notifier`/`NotifierProvider` (as `TutorLineNotifier` does) for any mutable line/state.

---

## No Analog Found

None. Every Phase-16 surface has a real in-repo analog (the seams were deliberately built in Phases 7/14/15 to be extended here).

**Two surfaces are device/console gated (not code analogs):**
| Surface | Why no code analog |
|---------|--------------------|
| Claude Model-Garden **Enable** click | A one-time human GCP console action (RESEARCH Pitfall 1) — model as a `checkpoint:human-verify` task; verify with a `rawPredict` 200 probe (RESEARCH Code Examples). |
| PRES-01 latency budget numbers + on-device Arabic-voice availability | Measured on the real Pixel Tablet in-phase (ROADMAP hint=no; RESEARCH A3/A6) — no code to copy; instrumentation placement is Claude's discretion. |

## Metadata

**Analog search scope:** `lib/tutor/`, `lib/services/`, `lib/providers/`, `lib/features/letter_unit/widgets/`, `server/app/`, `server/app/nodes/`, `server/tests/`, `server/tests/fixtures/`, `android/app/src/main/`, `.planning/phases/07-…/07-02-PLAN.md`.
**Files scanned:** ~20 (read in full or targeted): asset_audio_player.dart, audio_providers.dart, remote_agent_brain.dart, authored_fallback_brain.dart, tutor_dispatcher.dart, tutor_brain.dart, tutor_providers.dart, exercise_scaffold.dart (key ranges), models.py, faithfulness.py, main.py, coach.py, test_faithfulness.py, conftest.py, test_endpoint.py, faithfulness_set.jsonl, pyproject.toml, AndroidManifest.xml, pubspec.yaml, 07-02-PLAN.md.
**Pattern extraction date:** 2026-06-29
