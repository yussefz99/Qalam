# Phase 26: The finished experience — entry, polish, and the 2.0.1 release - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Qalam FEEL finished the moment it opens, then cut the **2.0.1+4** release
(only after grading; Play + webcourse artifacts move in lockstep). Five threads:

1. **Entry & identity** — resolve the Decided-vs-as-built contradiction (the router
   makes a parent account the front door; the Decided doc said accounts live behind
   the PIN gate and don't gate data). Owner has decided — see D-01.
2. **Launcher icon** — ship the real Qalam adaptive icon on Android (+ iOS), replacing
   the stock Flutter default.
3. **Coaching quality** — re-tighten the widened scorer thresholds (D-04) and close the
   two standing tutor-feedback bugs.
4. **Verification** — the Android device pass the submission skipped.
5. **Release** — 2.0.1+4, cut ONLY after grading.

**Not in this phase:** the mother's Phase-25 content verdicts (Phase 25 owns those);
new letters (Phase 27); cross-letter intelligence / parent dashboard (Phase 28).
</domain>

<decisions>
## Implementation Decisions

### Entry & Identity Model  ⚠ AMENDS A DECIDED ITEM

- **D-01 (owner decision, autonomous — 2026-07-20): Entry model = ACCOUNT-FIRST.**
  Ratify the as-built router: a parent account is the **mandatory front door** to the
  whole app. Every launch starts at `/auth`; after sign-in, child onboarding is the
  second gate; then the child experience. The owner selected this with full awareness
  it reverses previously-locked architecture (see D-02) and changes the Play/legal
  posture (see D-03).
- **D-01a — children STILL never get their own login (D-09b intact).** Account-first
  means the *parent* signs in; the child never authenticates. This boundary is
  unchanged and non-negotiable.
- **D-01b — sign-out must never strand.** The bug that triggered this phase (sign-out
  restored an anonymous identity, which the router then bounced back to `/auth`,
  trapping the user) MUST be fixed: under account-first, sign-out routes cleanly to
  `/auth` and stays there. "Ship exactly as-built" is NOT an option — the strand is a
  bug even under the ratified model.

### Decided-Section Amendment (required execution work)

- **D-02 — CLAUDE.md `Decided` section must be formally amended.** Two lines are
  superseded by D-01 and must be rewritten during execution (not silently — an explicit,
  dated amendment):
  - *"Parent accounts … reachable ONLY from behind the PIN-gated parent area"* →
    superseded: the account is now the front door.
  - *"Foundation scope — the account does not yet gate or sync any data"* →
    superseded: the account now gates all use (it does not yet SYNC data — that stays
    future scope; only the GATING clause changes).
  The child-safety core (D-09b child-login ban, D-09c anonymous-boot linking on sign-up)
  is untouched by the amendment.

### Play / Legal Alignment (required execution work)

- **D-03 — Play data-safety form + legal pages must declare account-gating and
  parent-email collection, matching the code word-for-word** (Success Criterion 1).
  Account-first means the app now requires a parent account + email to function; the
  published data-safety declaration, app-access declaration, and legal pages must all
  state exactly that. This is a compliance statement for a children's product — treat
  as blocking release work, not a nicety.

### Scorer Re-tighten

- **D-04 (owner decision — 2026-07-20): Revert tcc/tcw to the ORIGINAL thresholds,
  validate on device.** Restore the original tighter values (undo the 0.12/0.16
  widening, which existed only to work around the painter-stretch bug that is now fixed,
  commit 972427e). Confirm the feel during the Android device pass already scoped in
  this phase (alif→thaa walk). **Fallback:** if the originals demonstrably false-fail
  real clean strokes on-device, re-affirm the widened values WITH the reason recorded
  against the observed device behavior. No new dependency; explicitly NOT gated on a
  mother-labelled calibration set (rejected to avoid adding a task while she is the
  Phase-25 bottleneck).

### Known Fixes (not discussed — planned directly)

- **D-05 — Launcher icon.** Android on-device launcher is still the stock Flutter
  default (git-confirmed: `android/app/src/main/res/mipmap-*/ic_launcher.png` untouched
  since the initial shell, commit e9fc86c, 2026-05-30; no `flutter_launcher_icons`
  config, no adaptive-icon XML). Derive the real Qalam **adaptive** icon from the
  existing brand art (`docs/design/kit/project/assets/logo.svg` + the icons set +
  ICONOGRAPHY.md), parchment background to match the Play listing art. The Play STORE
  mark and the iOS `AppIcon.appiconset` already exist — the gap is the Android
  on-device launcher. Verify visually during the device pass. (Owner noted "there is a
  launcher icon" — that refers to the store mark / iconset; the on-device Android
  launcher is the confirmed gap.)
- **D-06 — Two tutor-feedback bugs (Phase-14/17 debt):** (a) the coach prompt's GOLD
  EXEMPLARS get copied verbatim, so feedback reads static; (b) the bottom feedback bar
  shows the AUTHORED floor line instead of the agent's line
  (`lib/features/letter_unit/widgets/exercise_scaffold.dart`). Both must be closed so
  the on-screen line is the agent's line and repeated attempts produce non-verbatim
  coaching.

### Claude's Discretion

- Icon generation mechanics (tooling: `flutter_launcher_icons` vs manual adaptive-icon
  drawables), router refactor shape, and the exact sign-out routing implementation are
  planner/executor calls, constrained by the decisions above.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Entry / identity / child-safety
- `CLAUDE.md` — the `Decided` section (parent-accounts-LIVE block, D-09b/D-09c). D-02
  amends the gating clauses here; child-login ban + anonymous-boot linking stay.
- `lib/router/app_router.dart` §redirect (lines ~60–75) — the as-built account-front-door
  gate being ratified; the `/auth` bounce that causes the strand.
- `lib/screens/parent_auth_screen.dart` — the front-door auth screen.
- `lib/services/auth_service.dart`, `lib/providers/auth_providers.dart` — sign-in/out +
  anonymous linking; the sign-out routing fix (D-01b) lands near here.

### Scorer
- `lib/core/` scorer (tcc/tcw thresholds); calibration harness is Dart flutter-test
  (deliberate deviation from the Python-tooling rule). Commit 972427e (painter-stretch
  fix) is the reason the widening is now safe to undo.

### Tutor feedback
- `lib/features/letter_unit/widgets/exercise_scaffold.dart` — the bottom feedback bar
  (D-06b: authored line shown instead of agent line).
- `lib/tutor/authored_fallback_brain.dart` — the authored FLOOR line source the scaffold
  mirrors; the coach prompt gold-exemplar copy issue (D-06a) lives in the tutor prompt.

### Launcher icon
- `docs/design/kit/project/assets/logo.svg`, `docs/design/kit/project/assets/icons/`,
  `docs/design/kit/project/assets/ICONOGRAPHY.md` — source brand art for the icon.

### Release / roadmap
- `.planning/ROADMAP.md` §"Phase 26" — goal, 5 success criteria, "cut ONLY after grading",
  Play+webcourse lockstep.
- Project memory: `play-upload-keystore` (upload key at `~/qalam-upload-keystore.jks`),
  `finalization-workspace` (release/2.0 frozen, v2.0.0+3 in Play review — 2.0.1+4 is the
  next cut).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **GoRouter redirect + merged refreshListenable** (`app_router.dart`) — the entry model
  is already implemented account-first; D-01 ratifies it. Work is a SIGN-OUT ROUTING fix
  (D-01b), not a rebuild.
- **AuthService anonymous linking** (D-09c) — already links the boot anonymous identity on
  sign-up; keep intact.
- **Dart calibration harness** — reuse for the scorer revert regression (see
  `calibration-harness-is-dart` memory).
- **AuthoredFallbackBrain._resolveLine** — the scaffold already mirrors it; the D-06b fix
  is swapping which line the bar renders (agent vs authored floor).

### Established Patterns
- Router redirect is SYNCHRONOUS (never awaits Drift — Pitfall 2) and uses two rules to
  avoid redirect loops (Pitfall 1). The sign-out fix must preserve both invariants.
- `--dart-define=DEMO=true` bypasses the gate (`kDemoMode`) — the device pass must run the
  REAL build (no DEMO flag) per the `demo-flag-is-mocked-walkthrough` memory.

### Integration Points
- Sign-out surfaces: `lib/screens/settings_screen.dart`, `lib/features/parent/parent_pin_gate.dart`.
- Android icon: `android/app/src/main/res/mipmap-*` + a new `mipmap-anydpi-v26/ic_launcher.xml`
  for adaptive icons; `pubspec.yaml` if using `flutter_launcher_icons`.
</code_context>

<specifics>
## Specific Ideas

- Owner's stance on the entry decision: "whatever is already built, let's do it" — i.e.
  ratify the account-first router rather than re-architect to anonymous-first, accepting
  the Decided amendment and Play/legal consequences after they were explicitly flagged.
- Release identity: **2.0.1+4**, cut ONLY after grading; Play and webcourse artifacts move
  in lockstep or not at all (from ROADMAP + `finalization-workspace` memory).
</specifics>

<deferred>
## Deferred Ideas

- **Mother-labelled scorer calibration set** — considered for D-04 and rejected for this
  phase (adds a task while she is the Phase-25 bottleneck). If the on-device fallback in
  D-04 fires, revisit building the set in a later calibration pass.
- **Account data SYNC** (backup/restore across devices) — the Decided doc's "does not yet
  sync data" clause stays true; D-02 only changes the GATING clause. Sync is future scope.
- Anonymous-first / hybrid entry models — explicitly rejected by D-01; recorded so a future
  session does not re-propose them.
</deferred>

---

*Phase: 26-the-finished-experience-entry-polish-and-the-2-0-1-release*
*Context gathered: 2026-07-20*
