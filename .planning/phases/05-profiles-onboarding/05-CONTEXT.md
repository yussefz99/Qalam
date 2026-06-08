---
phase: 5
name: Profiles & Onboarding
status: discussed
discussed_date: 2026-06-08
requirements: [S1-02, S1-03]
---

# Phase 5 — Profiles & Onboarding: Design Context

## Phase Goal

First-launch onboarding lets a parent create one child profile: the parent picks the
**grade** (which maps to a curriculum entry point), and the child picks an **avatar** and a
**nickname** from fixed sets — no free-text identity. After setup the child lands on the Home
screen. Subsequent launches skip onboarding entirely.

> **Reconciled 2026-06-08 against S1-02 / S1-03.** Earlier discuss-phase drafts had the parent
> *type the child's name* and treated grade as *stored-only*. Both conflicted with the locked
> requirements (S1-03 mandates fixed-set choices with no free-text identity leak; S1-02 mandates
> grade → starting lesson). This CONTEXT now follows the requirements.

---

## Locked Decisions

### 1. Onboarding gate

- **Trigger:** One-time only, on first launch (no profile exists in local DB).
- **Block:** Block at the app launch route — do not let the child reach Home until a profile is created.
- **Guard:** Check for existing profile in Drift on startup; redirect to onboarding if absent.
- **No multi-profile support in this phase.** Single child profile only.

### 2. Screen layout

- **One combined screen** for the entire setup — not split into a "parent intro" screen + a "child picks avatar" screen. Parent and child sit together; the parent sets grade, the child picks avatar + nickname.
- **One scrollable card** containing all fields. No multi-step wizard, no page transitions.
- **Fields (in order):**
  1. Grade (chip selector — the parent's pick)
  2. Avatar (grid picker — the child's pick)
  3. Nickname (fixed-set picker — the child's pick)
- **No free-text input anywhere** (S1-03). No name typed, no keyboard — all choices are taps from fixed sets. This is the strongest child-data posture and the easiest interaction for a young child.
- A single **"Let's go"** CTA button at the bottom of the card saves and navigates to Home.
- No "skip" option — the profile must be completed to proceed.

### 3. Avatar set

- **Count:** 6 avatars.
- **Style:** Simple illustrated child characters (diverse kids — not animals, not mascot variants).
- **Launch art:** Placeholder colored circles with initials or simple geometric child shapes.
  Real illustrated art replaces the placeholders before v1 with no code change (swap assets only).
- Avatar is stored as an ID string (e.g. `"avatar_1"`) in the child profile. The widget maps ID → asset path.

### 4. Nickname set (S1-03)

- **Fixed set** of child-friendly nicknames — the child taps one, same interaction as the avatar grid.
- **No free-text.** The chosen nickname is the child's display identity (shown on the Home screen);
  no real name is ever stored.
- **Count:** ~8–10 nicknames so there's real choice without overwhelming.
- **Voice is the owner's domain:** nicknames are kid-facing identity and should be warm and ideally
  Arabic-flavored (e.g. نجمة *Najma* — "star", قمر *Qamar* — "moon", أسد *Asad* — "lion"). Ship a
  **placeholder set** for Phase 5 (parallel to the placeholder avatars); the owner's mother finalizes
  the real list. Flag this clearly for her sign-off — do **not** invent the final wording.
- Stored as a nickname ID string (e.g. `"nick_star"`); the widget maps ID → display label, so the
  label can change without a data migration.

### 5. Grade field → curriculum entry point (S1-02)

- **Options:** KG · Grade 1 · Grade 2 · Grade 3 · Grade 4+
- **Effect in Phase 5:** grade **maps to a starting lesson** (curriculum entry point), satisfying S1-02.
- **Mechanism, not pedagogy:** implement a structural `grade → startingLessonId` lookup map. The
  *mechanism* is ours to build; the *actual entry-point values* are the owner's mother's domain.
- **Default:** all grades → `alif` (lesson 0) until the owner specifies real per-grade entry points.
  Leave a clear, single-source seam (one map/table) and a TODO for her to fill in. Do **not** invent
  which grade starts where.
- The resolved entry point is stored on the profile as `startingLessonId` so Home/lesson screens
  (Phase 6) can read it directly without re-deriving from grade.

---

## Data Model (Drift)

New table: `ChildProfile`

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PRIMARY KEY | Auto-increment |
| `nicknameId` | TEXT NOT NULL | Fixed-set ID, e.g. "nick_star". Maps to a display label. No real name stored. |
| `avatarId` | TEXT NOT NULL | Fixed-set ID, e.g. "avatar_1".."avatar_6" |
| `grade` | TEXT NOT NULL | One of: kg, grade1, grade2, grade3, grade4plus |
| `startingLessonId` | TEXT NOT NULL | Curriculum entry point resolved from `grade` at creation (default "alif"). Satisfies S1-02. |
| `createdAt` | INTEGER NOT NULL | Unix epoch ms |

**No free-text fields, no real name** (S1-03 / minimum child data). No parent account, no auth,
no Firebase in this phase. Local-only.

---

## Authentication — explicitly deferred (decided 2026-06-08)

**No sign-up / sign-in / accounts in Phase 5.** This was raised and consciously deferred:

- Honors the **Decided** item: *v1 is local-only, on-device, no Firebase.*
- A real (email/password) sign-up would pull Firebase Auth + network into this phase and
  add friction before a child can trace a single letter — against the "minimum child data,
  private by default" principle.
- **The account layer lands in the Firebase / Parent-area phase (Phase 9)**, where parent
  sign-up will gate the existing `/parent/*` router seam. Sign-up will be a *parent* action,
  not a child one.

**Migration intent (for whoever builds Phase 9):** the `ChildProfile` row is a real local
record from day one. When parent accounts arrive, the existing local profile must be
*claimable* — associated with the new parent account rather than discarded. Design the
Phase 9 auth flow to adopt any pre-existing local `ChildProfile`, not to force a fresh start.

---

## Navigation / Routing

- New route: `/onboarding`
- On app start, router checks for existing `ChildProfile` row:
  - **None found → redirect to `/onboarding`**
  - **Found → proceed to `/` (Home)**
- After form submission → `context.go('/')`.
- No back navigation from onboarding (the child cannot skip by pressing back — use `PopScope` or `WillPopScope` to block).

---

## Home Screen Integration

- After Phase 5, the Home screen greeting reads the saved **nickname** (its display label) from the profile.
- Replace the hardcoded `"Welcome back, Layla."` with the chosen nickname from the `ChildProfile` provider.
- Avatar is displayed in the greeting header area (small circle, top-left or next to the greeting text).

---

## Out of Scope (deferred)

- Multi-child profiles (Phase 9 parent dashboard)
- Parent PIN / parent-gated profile editing
- Firebase sync of the child profile
- **Real per-grade entry-point values** (owner's mother supplies; Phase 5 ships the mechanism with all grades → alif)
- **Final nickname wording** (owner's mother supplies; Phase 5 ships a placeholder set)
- Real illustrated avatar art (art swap is a non-code task)
- Onboarding analytics or funnel tracking

---

## Open Questions for Research

1. **Drift schema migration:** This adds a new table to the existing `AppDatabase`. Research the correct Drift migration path (schema version bump, `MigrationStrategy`).
2. **GoRouter redirect guard pattern in Riverpod:** The startup redirect needs to read from Drift asynchronously before the first route resolves. Confirm the correct pattern with `ref.watch` + `redirect` callback in codegen router.
3. **PopScope / back-button blocking:** Confirm the correct Flutter widget for preventing back navigation on the onboarding screen (Android back button + gesture).
4. **Curriculum entry point reference:** Confirm how lessons/letters are identified in the existing curriculum data (Phase 2 `letters.json` / CurriculumRepository) so `startingLessonId` references a real lesson ID. Locate the single best place for the `grade → startingLessonId` map.
