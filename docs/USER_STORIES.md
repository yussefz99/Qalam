# Qalam — User Stories

Source backlog for GSD. Project in Android Development · 236272 · Spring 2025/26.
Stories are grouped by the owner's planned sprints and carry stable IDs (S1-, S2-,
NTH-) for traceability into REQUIREMENTS.md and the roadmap. Wording is the owner's;
do not silently re-scope.

---

## Sprint 1 — Core Learning Loop

- **S1-01** (child) — I want to open the app and immediately see today's lesson already prepared for me, so that I know exactly what to study without navigating.
- **S1-02** (parent) — I want to create a profile for my child with their name and grade, so that the app prepares the right curriculum for them.
- **S1-03** (child) — I want to pick an avatar and nickname when I first open the app, so that it feels personal to me.
- **S1-04** (child) — I want to watch an animation of the correct stroke order before writing a letter, so that I know how to form it properly.
- **S1-05** (child) — I want to trace Arabic letters with my stylus and receive instant feedback on my shape and stroke order, so that I can correct my mistakes immediately.
- **S1-06** (child) — I want to hear the correct pronunciation of each letter and word, so that I learn how to say it, not just write it.
- **S1-07** (child) — I want to complete sentence-building exercises, so that I learn how Arabic words connect to form meaning.
- **S1-08** (child) — I want to complete grammar exercises at my level, so that I learn Arabic grammar rules step by step.
- **S1-09** (child) — I want the next lesson to unlock only after I pass the current one, so that I always build on solid foundations.
- **S1-10** (child) — I want to earn stars when I complete a lesson, so that I feel rewarded for my effort.
- **S1-11** (parent) — I want to see my child's completed lessons and scores, so that I can follow their progress.

---

## Sprint 2 — Qalam AI Tutor

- **S2-01** (child) — I want to take a placement exam when I first join, so that the app places me at the correct level across all subjects.
- **S2-02** (child) — I want the Qalam character to give me specific voice feedback in English on exactly what I did wrong, so that I understand how to improve like a real teacher would explain.
- **S2-03** (child) — I want to press a button and ask Qalam a question out loud, so that I can get help the same way I would from a real teacher sitting next to me.
- **S2-04** (child) — I want Qalam to give me extra practice on the topics and letters I keep getting wrong, so that my weak areas become strong.
- **S2-05** (child) — I want the app to adjust my daily lesson based on my recent performance, so that I always study what I need most.
- **S2-06** (parent) — I want to see which specific topics and letters my child struggles with, so that I know where to support them at home.
- **S2-07** (parent) — I want to set a daily practice duration goal for my child, so that they build a consistent learning habit.
- **S2-08** (child) — I want to practice vocabulary through flashcard exercises with pictures, so that I learn the meaning of Arabic words.
- **S2-09** (child) — I want to read short Arabic passages and answer questions about them, so that I practice understanding written Arabic.
- **S2-10** (parent) — I want to receive a weekly progress report, so that I can track my child's improvement over time.

---

## Nice to Have

- **NTH-01** (child) — I want to keep a daily streak, so that I am motivated to open Qalam every day without skipping.
- **NTH-02** (child) — I want to collect badges for milestones like finishing all 28 letters, so that I feel proud of big achievements.
- **NTH-03** (parent) — I want my child to receive a gentle reminder notification when they haven't practiced today, so that they stay consistent.
- **NTH-04** (parent) — I want to manage multiple child profiles under one account, so that all my children can use Qalam.
- **NTH-05** (child) — I want to practice letter tracing without an internet connection, so that I can study anywhere.
- **NTH-06** (teacher) — I want to view the progress of all my students, so that I can identify who needs extra support.
- **NTH-07** (teacher) — I want to assign specific lessons to a student, so that I can align Qalam with what we cover in class.

---

## Scoping decisions (resolved during /gsd-new-project, 2026-05-30)

- **Sprint 1 → v1 milestone; Sprint 2 → v2 milestone; Nice-to-Have → backlog.**
- **Gentle stars only:** S1-10 kept as a quiet, non-pressuring per-lesson acknowledgment.
  NTH-01 (streak) and NTH-02 (badges) are **out of scope** — they conflict with the
  anti-gamification stance.
- **AI tutor (S2-xx) is v2.** v1's S1-05 feedback is **on-device ML Kit** shape and
  stroke-order scoring (deterministic), not the Claude tutor.
- **v1 is local-only, on-device, no auth.** Firebase Auth / Firestore sync / Cloud
  Functions enter in v2 with the tutor. NTH-05 (offline) is satisfied by v1's design.
