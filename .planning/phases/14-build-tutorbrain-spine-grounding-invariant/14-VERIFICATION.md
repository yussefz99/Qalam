---
phase: 14-build-tutorbrain-spine-grounding-invariant
verified: 2026-06-22T00:00:00Z
status: human_needed
score: 5/5 must-have truths verified (code/automated); 3 human-only gates pending; 1 cross-seam warning RESOLVED (commit 5fecd3b), 1 deferred (App Check composition-root wiring)
overrides_applied: 0
requirements_verified: [TUTOR-01, TUTOR-02, TUTOR-03, TUTOR-04, TUTOR-05, GROUND-01, GROUND-02]
warnings:
  - concern: "present_activity arg-casing mismatch across the client↔server seam — RESOLVED"
    detail: >-
      RESOLVED in commit 5fecd3b (post-verification finalize). server/app/main.py now
      normalizes CoachOut.args to camelCase at the wire boundary via _to_wire_args
      (letter_id→letterId, coaching_line→coachingLine, next_exercise_id→nextExerciseId),
      matching the camelCase request DTO and the Dart client's _parseCoachOut; internal
      snake_case guards (G4 reads letter_id) are untouched. New endpoint test
      test_present_activity_args_are_camelcase_on_the_wire locks the contract and asserts
      snake_case keys never leak. 62 server tests pass; redeployed as revision 00003.
      Original defect: server emitted snake_case while the client read camelCase, so an
      online present_activity line would have parsed null → degraded to the floor.
    severity: resolved
    surface_at: "fixed before the 14-03 on-device gate — no action needed"
  - concern: "appCheckTokenGetterProvider not overridden at the composition root (main.dart)"
    detail: >-
      lib/main.dart does not override appCheckTokenGetterProvider with a real
      FirebaseAppCheck.instance.getLimitedUseToken() getter, and App Check is not
      initialized anywhere in lib outside the seam. This is documented by SUMMARY 14-03
      as a composition-root follow-up required before the device test, and main.dart was
      NOT in any Phase-14 plan's files_modified (out of scope for this phase). The default
      null getter is an intentional fail-safe (degrades to the offline floor rather than
      calling the App-Check-gated server unauthenticated). Tracked under the Firebase
      App Check human gate.
    severity: warning
human_verification:
  - test: "On-device online coaching against the live Cloud Run URL (14-03 gate)"
    expected: "App run with --dart-define=TUTOR_BASE_URL=<service URL>: a traced baa attempt shows an online coaching line; a grounded fail never says/auto-advances; airplane mode falls to the authored floor without blocking the Clear/Try-again/Next loop"
    why_human: "Requires a real device + a real Anthropic key (provider keys are currently placeholders). Cannot be exercised from code. NOTE: confirm a present_activity online action shows a real line, not the floor — see the casing warning."
  - test: "Firebase App Check console registration"
    expected: "The Android app (qalam-app-bd7d0) is registered with the Play Integrity provider so the client can mint limited-use tokens the server verifies"
    why_human: "Console-side configuration; not observable from the codebase"
  - test: "Curriculum sign-off on AUTHORED_BAA_IDS"
    expected: "The owner's mother confirms the 26-id set (6 sections + 19 baa.* exercises + the 'baa' family token) in server/app/curriculum_data/baa_authored_ids.json matches the signed baa curriculum"
    why_human: "Pedagogical correctness is the curriculum owner's domain (CLAUDE.md); code only verifies the set was transcribed verbatim from the canonical seed"
deferred:
  - truth: "GemmaBrain on-device backend (the literal REQUIREMENTS.md text of TUTOR-04)"
    addressed_in: "Phase 16"
    evidence: "REQUIREMENTS.md §Phase 13 SPIKE / v2 roadmap: 'the TUTOR-04 Gemma-adoption decision (finalized in Phase 16)'. The v2 milestone was re-aimed at the server-side LangGraph architecture (ADR-015, commits 1786971/3a71d64/9d709d6); the Phase-14 success criteria re-bind TUTOR-04 to 'durable layers carry zero agent/framework imports', which IS verified here."
---

# Phase 14: build-tutorbrain-spine-grounding-invariant Verification Report

**Phase Goal:** Build the capable server-side tutoring agent + its client seam — a Python LangGraph agent on Cloud Run (analyze→plan→coach, per-node model routing, 4 ACTION tools via tool_choice="any", FACTS-as-text, keys in Secret Manager, Firebase-ID-token + App-Check gated) PLUS the swappable client TutorBrain (RemoteAgentBrain + AuthoredFallback floor + dispatcher + the agent-owns-line/scorer-owns-verdict seam at the untouched ExerciseController + the non-PII guard), keeping the durable layers free of agent/framework imports.

**Verified:** 2026-06-22
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | One TutorBrain interface hosts swappable RemoteAgentBrain + AuthoredFallback; swapping changes no canvas/scorer/curriculum code; durable layers carry zero agent/framework/network imports (TUTOR-01, TUTOR-04) | ✓ VERIFIED | `tutor_providers.dart` `tutorBrainFactoryProvider` is the single switch (builds RemoteAgentBrain wrapping AuthoredFallbackBrain); both implement `TutorBrain`. `durable_layers_no_agent_imports_test.dart` scans lib/core (13), lib/features/practice (8), lib/models (7), lib/data (10) — 38 files — and asserts zero firebase_ai/genui/flutter_gemma/langgraph/http/remote_agent_brain/json_schema_builder imports; includes a non-vacuous self-test + scanned>0 guard. Passes. |
| 2 | Airplane mode always shows a grounded correctly-Arabic AuthoredFallback line, loop never blocks; online the LangGraph server coaches and auto-degrades on timeout/offline; keys never in client (Secret Manager; App-Check + Firebase-ID-token gated) (TUTOR-02, TUTOR-03) | ✓ VERIFIED (online line: human gate) | `RemoteAgentBrain.next()` returns `fallback.next(facts)` on null token / non-200 / timeout / parse-error / any exception — never throws (verified lines 70-106). `authored_fallback_offline_test.dart` covers every baa pass + mistakeId + unknown-id, byte-identical to applyResult, no throw/block. `grep` confirms NO `sk-ant`/`AIza` key in server/ and no provider key in lib/. Auth gate (`verify_caller`) 401s before the graph. Live deploy verified by orchestrator (revision qalam-tutor-00002-4sf, /health→200, unauth /coach→401, keys are Secret Manager refs). |
| 3 | The agent acts only through the 4 ACTION tools; the geometry verdict + learner state arrive as injected FACTS; the model cannot request or fabricate a verdict (TUTOR-05) | ✓ VERIFIED | `tools.py` ACTION_TOOLS = exactly {present_activity, say, give_hint, advance}; no verdict/star tool exists. `coach.py` binds `tool_choice="any"` + rejects out-of-set names to `say`. `analyze.py`/`plan.py` inject FACTS as `HumanMessage` TEXT (never a tool result). `test_grounding.py` asserts the decision is always exactly one in-set tool. 61 server tests pass. |
| 4 | pass/fail + star decided by the deterministic scorer at the ExerciseController seam; no agent path can flip a fail to a pass; the agent only supplies the line (GROUND-01) | ✓ VERIFIED | `exercise_controller.dart` is byte-for-byte untouched by Phase 14 (last modified Phase 07, commit 2b34843); carries no agent/network import and no line-setter. `exercise_scaffold._onResult` calls `applyResult` FIRST (line 152) then routes only the line via `tutorLineProvider`. Server G3 guards: `plan.py` downgrades advance-on-fail to retest_whole; `coach.py` rewrites advance-on-fail to a grounded `say`. `test_grounding.py` asserts advance is never emitted on a fail. |
| 5 | A guard/test fails the build if raw stroke coordinates or any PII field can reach the network payload — only derived non-PII facts cross (GROUND-02) | ✓ VERIFIED | Client: `payload_nonpii_test.dart` serializes a fully-populated TutorFacts, recurses nested trajectory keys, asserts whitelist-only + the tightened token guard (both directions). Server: `TutorFactsIn` + `AttemptFactIn` both `extra="forbid"`; `test_payload_nonpii.py` asserts each PII key 422s. `tutor_facts.dart` builder accepts no Offset/stroke param (geometry physically cannot enter). SUMMARY 14-04 records deliberate-breakage proofs (both guards go red on a real leak). 94 Dart + 61 server tests pass. |

**Score:** 5/5 truths verified at the code/automated level. The online-coaching *line content* in truth 2 and the present_activity line in truth 3's UI surface require the on-device human gate (real key + device).

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | GemmaBrain on-device backend (literal REQUIREMENTS.md TUTOR-04 text) | Phase 16 | REQUIREMENTS.md ties the TUTOR-04 Gemma decision to Phase 16; the v2 milestone was re-aimed at server-side LangGraph (ADR-015), and Phase 14's success criteria re-bind TUTOR-04 to "durable layers carry zero agent/framework imports" — which IS verified (truth 1). |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `server/app/schema.py` | Final enlarged TutorFactsIn (8 fields) + AttemptFactIn, both extra=forbid; CoachOut | ✓ VERIFIED | Matches contract exactly; both models extra=forbid |
| `server/app/graph.py` | analyze→{plan|coach}→coach with conditional edge | ✓ VERIFIED | `add_conditional_edges("analyze", needs_plan)`; InMemorySaver (stateless) |
| `server/app/nodes/coach.py` | bind_tools tool_choice="any" + G3/G4 online guards | ✓ VERIFIED | Action-space lock + advance-on-fail rewrite + unauthored-id reject |
| `server/app/nodes/plan.py` | Plan schema + curriculum guard + advance-on-fail downgrade | ✓ VERIFIED | is_authored guard raises; advance-on-fail → retest_whole |
| `server/app/nodes/analyze.py` | Insight schema + FACTS-as-text + bounded retry | ✓ VERIFIED | with_structured_retry, fail-closed |
| `server/app/curriculum.py` | AUTHORED_BAA_IDS from bundled signed seed | ✓ VERIFIED | Loads baa_authored_ids.json (26 ids); is_authored() membership check |
| `server/app/auth.py` | Firebase ID token + App Check verify, 401 before graph | ✓ VERIFIED | Both tokens verified; 401 on either failure |
| `lib/tutor/remote_agent_brain.dart` | server call + dual auth headers + auto-degrade | ✓ VERIFIED | Never throws; degrades on any failure. _parseCoachOut reads camelCase args; server now emits camelCase on the wire (commit 5fecd3b) — seam aligned |
| `lib/tutor/tutor_providers.dart` | single switch point + tutorLineProvider | ✓ VERIFIED | tutorBrainFactoryProvider is the only routing site |
| `lib/tutor/tutor_facts.dart` | enlarged non-PII TutorFacts mirroring server DTO | ✓ VERIFIED | 8-field toJson, no Offset/stroke representable |
| `lib/tutor/authored_fallback_brain.dart` | zero-model offline floor mirroring applyResult | ✓ VERIFIED | Pure Dart, no Firebase/network/model imports |
| `test/tutor/payload_nonpii_test.dart` | build-failing GROUND-02 client guard | ✓ VERIFIED | Recursive scan + both directions |
| `test/tutor/durable_layers_no_agent_imports_test.dart` | TUTOR-04 import guard | ✓ VERIFIED | Non-vacuous, scanned>0 |
| `server/tests/test_grounding.py` | D1/D7/D9 grounding hard checks | ✓ VERIFIED | All pass within the 61 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| main.py | auth.py | Depends(verify_caller) on POST /coach | ✓ WIRED | Confirmed in main.py line 58 |
| main.py | graph.py | await asyncio.wait_for(graph.ainvoke) | ✓ WIRED | Lines 69-72 |
| coach.py | tools.py | bind_tools(ACTION_TOOLS, tool_choice="any") | ✓ WIRED | build_coach_with_tools |
| graph.py | needs_plan | add_conditional_edges | ✓ WIRED | Line 54 |
| plan.py | curriculum.py | is_authored(next_exercise_id) | ✓ WIRED | Lines 76-83 |
| remote_agent_brain.dart | /coach | http POST + Authorization + X-Firebase-AppCheck | ✓ WIRED | Lines 83-93 |
| remote_agent_brain.dart | authored_fallback_brain.dart | catch → fallback.next(facts) | ✓ WIRED | Lines 76-105 |
| exercise_scaffold.dart | tutor_providers.dart | reads tutorBrainFactoryProvider + tutorLineProvider (controller untouched) | ✓ WIRED | applyResult-first, line via provider |
| server tool args | client _parseCoachOut | present_activity arg keys | ⚠️ PARTIAL | snake_case (server) vs camelCase (client) — see warning; `say.text` matches |

### Behavioral Spot-Checks / Probe Execution

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Server test suite | `uv run pytest -q` | 61 passed | ✓ PASS |
| Dart tutor test suite | `flutter test test/tutor/` | 94 passed | ✓ PASS |
| No committed provider keys (server) | `grep -rEi "sk-ant\|AIza[…]" server/` | no matches | ✓ PASS |
| No provider key in client | `grep -rEi "sk-ant\|ANTHROPIC_API_KEY" lib/` | no matches | ✓ PASS |
| Controller untouched | `git log -- exercise_controller.dart` | last touched Phase 07 | ✓ PASS |
| Live /health | (orchestrator-verified) | 200 {"status":"ok"} | ✓ PASS |
| Live unauth /coach | (orchestrator-verified) | 401 | ✓ PASS |
| Keys are Secret Manager refs | (orchestrator-verified) | not plaintext | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| TUTOR-01 | 14-03, 14-04 | Swappable TutorBrain, durable layers unchanged | ✓ SATISFIED | Single switch point + import guard (truth 1) |
| TUTOR-02 | 14-03, 14-04 | Offline AuthoredFallback floor, never blocks | ✓ SATISFIED | Offline-floor test (truth 2) |
| TUTOR-03 | 14-01, 14-03 | Online coaching, auto-degrade, keys server-side | ✓ SATISFIED (online line = human gate) | Auth gate + degrade + no client key (truth 2) |
| TUTOR-04 | 14-04 | (Re-bound) durable layers carry zero agent/framework imports | ✓ SATISFIED | Import guard (truth 1). Gemma backend deferred to Phase 16. |
| TUTOR-05 | 14-01, 14-02 | Agent acts only through 4 ACTION tools; verdict/state as FACTS | ✓ SATISFIED | Closed tool set + FACTS-as-text (truth 3) |
| GROUND-01 | 14-02, 14-03 | Scorer owns verdict; agent can't override | ✓ SATISFIED | Untouched controller + G3 guards (truth 4) |
| GROUND-02 | 14-04 | Only non-PII facts cross, enforced automatically | ✓ SATISFIED | Build-failing guards both sides (truth 5) |

**Note on requirement text drift:** REQUIREMENTS.md still carries the OLD client-only wording (GeminiBrain/GemmaBrain, "Firebase AI Logic") for TUTOR-03/04. The v2 milestone was deliberately re-aimed at the server-side LangGraph architecture (ADR-015, roadmap commits 1786971/9d709d6) and Phase 14's ROADMAP success criteria are the binding contract. All 7 IDs are accounted for; the literal Gemma-backend clause of TUTOR-04 is correctly deferred to Phase 16. The REQUIREMENTS.md prose should be refreshed to match ADR-015 (informational, not a phase blocker).

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `remote_agent_brain.dart` ↔ `tools.py` | present_activity arg-casing seam mismatch (camelCase parse vs snake_case emit), each side tested in isolation | ⚠️ Warning | Online present_activity line degrades to the floor; safe direction (no block, no grounding violation); currently moot (placeholder keys). Surface at the device gate. |
| `tutor_providers.dart` appCheckTokenGetterProvider | returns null by default (not wired in main.dart) | ℹ️ Info | Intentional fail-safe; composition-root wiring is an out-of-scope documented follow-up before the device test |

No TBD/FIXME/XXX debt markers found in phase-modified files. No stub return values flowing to user-visible output (the null-token/null-line paths are deliberate degrade-to-floor logic, not stubs).

### Human Verification Required

1. **On-device online coaching (14-03 gate)** — run with `--dart-define=TUTOR_BASE_URL=<service URL>` + a real Anthropic key; confirm an online line appears, a grounded fail never advances, and airplane mode falls to the authored floor without blocking. **Also confirm a `present_activity` online action shows a real line and not the floor** (validates the arg-casing seam).
2. **Firebase App Check console** — confirm the Android app is registered with the Play Integrity provider.
3. **Curriculum sign-off** — owner's mother confirms the 26-id AUTHORED_BAA_IDS set matches the signed curriculum.

### Gaps Summary

No goal-blocking gaps. All 5 ROADMAP success-criteria truths are verified in the codebase at the automated level, all 7 requirement IDs are accounted for (TUTOR-04's Gemma clause correctly deferred to Phase 16), 61 server + 94 Dart tests pass, the durable spine is provably import-clean, the non-PII guard is build-failing on both wire sides, and the ExerciseController scorer seam is byte-for-byte untouched.

Status is **human_needed** (not passed) because three irreducibly human gates remain: the on-device live-coaching run, the Firebase App Check console registration, and the curriculum sign-off — all flagged by the plans themselves as blocking checkpoints.

Two warnings to carry into the device gate: (1) the `present_activity` arg-casing mismatch between server (snake_case) and client (camelCase), which silently degrades present_activity lines to the floor and was masked by isolated per-side unit tests — fixable with a one-line key alignment, best validated on-device; (2) the App Check composition-root wiring in main.dart, an explicitly-documented out-of-scope follow-up. Neither breaks a must-have truth (the loop never blocks, grounding holds, the floor always coaches), so neither is a blocker — but the casing mismatch should be fixed before real provider keys go live so online present_activity lines actually display.

---

_Verified: 2026-06-22_
_Verifier: Claude (gsd-verifier)_
