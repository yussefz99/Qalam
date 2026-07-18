# Quick Task 260718-il4: Stage 1 all-letters-live — Context

**Gathered:** 2026-07-18 (owner discussion, this session)
**Status:** Ready for execution — plan already written and committed (cc6e237)

<domain>
## Task Boundary

Stage 1 of all-letters-live: make letter-unit graph loading multi-letter (per-letter
graph assets, provider parameterized by letterId) and promote thaa (ث) from
docs/curriculum/drafts (exercises + graph) into the live app so a thaa unit runs
end-to-end exactly like baa — walker, instruction bar, stimulus zone, per-child
keying, scorer verdict, AI coaching. Stop after thaa is build-ready for device.

Stage 2 (SEPARATE, after owner verifies thaa on iPad): run the same promotion
script for the remaining 24 letters + per-letter server curriculum data + one
owner-authorized server deploy.
</domain>

<decisions>
## Implementation Decisions (OWNER-LOCKED — do not revisit)

### Graph-derived mastery (owner amendment 1, overrides the PLAN where they conflict)
- Do NOT extend `_presentedExerciseIds()` per-letter. For any letter other than baa,
  the mastery gate derives from the letter's graph itself (essential-competency nodes
  + minCleanReps → the existing full-graph `isMasteryMet(graph, reps)` check).
- Baa keeps its scoped 8-id list as a documented legacy exception — do NOT change baa.
- Structure: `_presentedExerciseIds()` returns the baa set only when letterId == 'baa',
  otherwise empty → existing fallback to `isMasteryMet` fires.
- Add a test pinning: a thaa unit's star requires exactly the thaa graph's essential nodes.

### Graph as single source for unit sections (owner amendment 2)
- The promotion script GENERATES the letter's units.json entry from its graph +
  question types (type→section mapping) — never hand-authored. Document the mapping
  in the script.

### Content posture
- ALL promoted content ships `signedOff: false` (the mother reviews via the 18.1
  review packets in docs/curriculum/review-packets/).
- Micro-drills NEVER enter any graph (owner rejected them on device TWICE —
  2026-07-12 and 2026-07-18; see memory + graph _meta.owner_removal_2026_07_18).
- Scorer owns pass/fail for thaa and all non-baa letters. Do NOT touch the baa
  AI-judge path, the tutor prompt, or the server this stage.
- Learned-letters lint for the thaa unit: learned set = introOrder ≤ 4 (alif, baa,
  taa, thaa). If a thaa draft card demands letters beyond that, DEFAULT disposition
  is keep-it-live with a documented owner-approved-style exception (the owner
  explicitly restored such cards for baa — mirror that posture; list them in the
  SUMMARY for the mother's packet).

### Execution constraints
- SEQUENTIAL executor on the main working tree (worktree executors cannot commit in
  this environment — recorded project memory). Atomic commits with hooks.
- Live-path widget tests mount via `presentGraphExercise` (Phase-15 dead-wire lesson).
- Known pre-existing test failures to IGNORE (never "fix"/re-bake): alif_reference
  cluster, all_letters_validation signedOff, reference_overlay golden,
  meet_section img.door, mastery_celebration golden, glyph_audit golden.
- End state: `flutter build ios --release
  --dart-define=TUTOR_BASE_URL=https://qalam-tutor-718707208086.us-central1.run.app`
  succeeds. Install to the owner's iPad (wireless id 00008103-0008058426D3401E) via
  `xcrun devicectl device install app --device <id> build/ios/iphoneos/Runner.app`
  then `... process launch ... com.technion.qalam`.
- Do NOT update ROADMAP.md (quick task). Do NOT deploy the server.

### Claude's Discretion
- Per-letter graph asset layout details (assets/curriculum/graphs/<letterId>.json as
  planned), provider family mechanics, test-override sweep mechanics.
</decisions>

<specifics>
## Specific Ideas

- The 18.1 drafts lack `letters` and `criteria` fields: derive `letters` via
  tools/content/arabic.py decomposition of the expected text (teachCard/null →
  [letterId]); `criteria` is a fixed per-type map mirroring live baa configs
  (trace/write/complete → stroke set; word/sentence → present/correct/dot;
  teachCard → []). The planner verified this rule against all live baa configs.
- units.json has NO thaa unit — the script must generate it (see amendment 2).
- pubspec.yaml lists assets/curriculum/ as a bare dir — subdirectories are NOT
  bundled; add assets/curriculum/graphs/ explicitly.
- curriculum_graph.json (baa) must STAY PUT for the server's generate.py; the new
  graphs/baa.json is a parity-guarded duplicate (parity test in the plan).
</specifics>

<canonical_refs>
## Canonical References

- .planning/quick/260718-il4-stage-1-all-letters-live-multi-letter-gr/260718-il4-PLAN.md (the plan — 3 tasks)
- .planning/HANDOFF-ALL-LETTERS.md (full project-state handoff for a fresh session)
- docs/curriculum/drafts/ (the 18.1 draft exercises + graphs, letters 4–28)
- tools/content/ (arabic.py decomposition, validate.py)
- assets/curriculum/curriculum_graph.json (live baa graph — the target shape; 20 nodes, no drills)
</canonical_refs>
