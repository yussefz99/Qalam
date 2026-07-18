# HANDOFF — All-Letters-Live + Technion Submission (written 2026-07-18)

> For a FRESH session. Read this first, then the quick-task CONTEXT + PLAN it points to.
> The owner ended the previous session deliberately to start this work with clean context.

## Where the app stands right now (all committed on main, pushed through 4a4f355; later commits local)

- **Phase 19 is COMPLETE** (question presentation overhaul): persistent instruction bar
  per question type, big gap-slot box, hero audio card (auto-play once + tap replay),
  child-controlled hide/peek for copy questions, per-child progress keying
  ((childProfileId, letterId) across all progress tables, v6→v7 migration), LetterReps
  retired, ADR-018. VERIFICATION passed 4/4; code review's 2 criticals + 6 warnings fixed.
- **Owner device-UAT reverts (2026-07-18, AFTER phase close — all committed):**
  - Micro-drills REMOVED from the live graph AGAIN (second on-device rejection —
    2026-07-12 and 2026-07-18). They stay OUT unless the owner explicitly asks on device.
  - The 6 once-gated cards RESTORED (buildSentence.hear/picture, fillBlank.adjective,
    transformWord.dual/plural/opposite) — owner-approved exception in
    test/curriculum/learned_letters_lint_test.dart.
  - kitaab card word is now **بابا (dad)** (owner's pick; signedOff:false pending mother).
  - Live baa graph: 20 nodes, no drills (assets/curriculum/curriculum_graph.json).
- **18.1 partner branch MERGED** (friend's work): tools/audio_pipeline/, tools/content/
  (arabic.py decomposition, validators), tools/review_packets/, draft 19-question sets +
  graphs for letters 4–28 in docs/curriculum/drafts/, review packets for 26 letters in
  docs/curriculum/review-packets/. Audio map covers all 28 letters (39 mp3s shipped).
- **Owner's iPad** (wireless, device id 00008103-0008058426D3401E, iOS 26.1) has the
  current build installed and verified by the owner (all 20 baa questions visible).
  Deploy recipe: `flutter build ios --release --dart-define=TUTOR_BASE_URL=https://qalam-tutor-718707208086.us-central1.run.app`
  then `xcrun devicectl device install app --device <id> build/ios/iphoneos/Runner.app`
  and `xcrun devicectl device process launch --device <id> com.technion.qalam`.
  (flutter run over wireless flakes at the install step; devicectl works.)

## ⚠ Known-stale / open items

1. **Tutor server is STALE**: serving rev qalam-tutor-00028-bzr with the morning data
   (drills IN, 6 cards OUT — opposite of the owner's reverts). server/app/curriculum_data/
   was re-derived on main (20 ids, 0 drills, commit 73fc5ae) but NOT deployed.
   Redeploy needs fresh explicit owner wording (standing rule). Recipe:
   `cd server && gcloud run deploy qalam-tutor --source . --project=qalam-app-bd7d0 --region=us-central1 --allow-unauthenticated --min-instances=0 --timeout=30`
   (NO --set-env-vars → preserves existing env). Verify /health 200, /coach no-token 401.
2. **19-HUMAN-UAT.md**: 3 items still pending (WR-03 audio overlap on device, WR-04
   fast-tap step-down, mother's sign-off of 19-REVIEW-PACKET.md incl. the بابا choice).
3. **Pre-existing test failures (NEVER "fix"/re-bake):** alif_reference cluster (4),
   all_letters_validation signedOff, reference_overlay golden, meet_section img.door,
   mastery_celebration golden, glyph_audit golden. Suite baseline: ~892 pass + these.

## THE PRIORITY: all letters live like baa (owner directive)

Owner wants ALL 25 remaining letters (4–28) to run as full graph-driven units with the
AI tutor, promoted from the friend's drafts. Design principle the owner locked:
**the graph drives everything; code knows zero letters; letters are pure data.**

### Stage 1 (DO FIRST): thaa (ث) end-to-end as the pipeline proof
- Plan READY + committed: `.planning/quick/260718-il4-stage-1-all-letters-live-multi-letter-gr/260718-il4-PLAN.md` (3 tasks)
- Owner-locked amendments in the SAME dir's `260718-il4-CONTEXT.md` — READ IT; it
  overrides the plan on: graph-derived mastery (no per-letter hardcoded id lists;
  baa keeps its 8-id list as the only legacy exception) and script-generated
  units.json sections. Also carries the execution constraints (sequential executor
  on main tree — worktree executors can't commit here; signedOff:false; drills never;
  scorer verdict for non-baa; lint posture; build+install recipe).
- End of Stage 1 = thaa unit playable on the owner's iPad. STOP and let the owner test.

### Stage 2 (after owner verifies thaa on device): the 24-letter loop
- Run the (now-proven) promotion script for the remaining letters, per-letter server
  curriculum data (extend server/app/curriculum_data/generate.py beyond baa), journey
  map unlock ordering by letters.json introOrder, full test sweep, ONE server deploy
  (owner wording), rebuild iPad.

## THE OTHER TRACK: Technion submission (owner deadline "today" as of 2026-07-18)

Owner decided: park roadmap phases 20–23 to backlog (NOT yet done in ROADMAP.md — do it
or leave; the letters work supersedes much of 20/21); the submission needs:
- **Live demo/presentation + written report/README + demo video.** Owner has a full
  instructions file he will upload — ASK FOR IT before drafting deliverables.
- **Platform: Android ONLY for graders** (iPad is the owner's personal test device).
  An Android release build + device/emulator sweep is required. Play upload keystore:
  ~/qalam-upload-keystore.jks, creds in gitignored android/key.properties.
- Demo readiness: warm the server for the demo window
  (`gcloud run services update qalam-tutor --region=us-central1 --project=qalam-app-bd7d0 --min-instances=1`, set back to 0 after).

## How the owner wants to be worked with (hard-learned today)

- **Organized, visible stages** — never hours of invisible work; each stage ends with
  something the owner can see/test on device.
- **Ask at real decision points** (AskUserQuestion), auto-run only mechanical steps.
- **Never relitigate**: drills out; the 6 cards stay; بابا; signedOff:false posture.
- Curriculum content is the mother's domain — model drafts, she signs (packets exist).
- Each production server deploy needs fresh explicit owner wording in-session.

## Opening move for the fresh session

Read this file + the quick-task CONTEXT + PLAN, then execute Stage 1
(`/gsd:quick resume stage-1-all-letters-live-multi-letter-gr` or spawn the executor
directly against the PLAN with the CONTEXT amendments), install to the iPad, and hand
the owner the thaa unit to test. Do not start Stage 2 or any Technion deliverable
without the owner's explicit go.
