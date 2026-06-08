// Plan 05-02 — onboarding fixed sets + grade→startingLessonId resolver.
//
// MECHANISM ONLY (D-5). The actual per-grade entry-point values and the final
// nickname wording are the OWNER'S MOTHER'S domain — Phase 5 ships placeholders
// plus a loud TODO. Do NOT invent the pedagogy here.
//
// SECURITY (T-05-02 / S1-03): these are the only IDs that may ever flow into a
// child profile. Choices are taps from these fixed sets — there is no free-text
// identity anywhere. ID→label and ID→asset mapping live HERE in code, never in
// the DB, so wording/art can change with no data migration.

/// A nickname choice: a stable fixed-set id + its display label. The label is a
/// placeholder pending the owner's mother's sign-off; because the profile stores
/// only the id, the label can change with no data migration.
typedef NicknameOption = ({String id, String label});

/// Exactly 6 fixed avatar IDs (S1-03). The widget maps each id → an asset path;
/// launch art is placeholder geometry swapped to real illustration with no code
/// change.
const List<String> kAvatarIds = <String>[
  'avatar_1',
  'avatar_2',
  'avatar_3',
  'avatar_4',
  'avatar_5',
  'avatar_6',
];

// TODO(owner's-mother sign-off): finalize the nickname wording — these Arabic
// labels are PLACEHOLDERS only. The ids are stable; only the display labels (and
// possibly which nicknames appear) change after her review. No data migration is
// needed because the profile stores the id, not the label.
const List<NicknameOption> kNicknames = <NicknameOption>[
  (id: 'nick_star', label: 'نجمة'), // Najma — "star"
  (id: 'nick_moon', label: 'قمر'), // Qamar — "moon"
  (id: 'nick_lion', label: 'أسد'), // Asad — "lion"
  (id: 'nick_sun', label: 'شمس'), // Shams — "sun"
  (id: 'nick_flower', label: 'وردة'), // Warda — "rose"
  (id: 'nick_bird', label: 'عصفور'), // Usfur — "bird"
  (id: 'nick_sea', label: 'بحر'), // Bahr — "sea"
  (id: 'nick_cloud', label: 'غيمة'), // Ghayma — "cloud"
];

// TODO(owner's-mother sign-off): replace 'alif' with the real per-grade
// entry-point ids. Phase 5 ships every grade → 'alif' (lesson 0) until she
// specifies real entry points. The MECHANISM (a single-source map) is ours; the
// VALUES are hers. Keep this the single source so a future change is one edit.
//
// NAMESPACE FLAG (RESEARCH Open-Q1 / Assumption A2): the value below is a LETTER
// id ('alif', from assets/curriculum/letters.json) for now. Phase 6 decides
// whether startingLessonId references a letter id or a distinct lesson id; the
// single-source map keeps that future rename to one place.
const Map<String, String> gradeToStartingLessonId = <String, String>{
  'kg': 'alif',
  'grade1': 'alif',
  'grade2': 'alif',
  'grade3': 'alif',
  'grade4plus': 'alif',
};

/// Resolve a grade to its curriculum entry point. Unknown/unmapped grades fall
/// back to 'alif' so the resolver never returns null or crashes (T-05-04).
String resolveStartingLessonId(String grade) =>
    gradeToStartingLessonId[grade] ?? 'alif';

/// Resolve a fixed-set nickname id to its display label (presentation only).
///
/// ID→label mapping lives HERE in code, never in the DB (S1-03 / D-3): the
/// profile stores only the id, so labels change with no data migration. Returns
/// `null` for an unknown id so callers degrade gracefully (no crash, no PII).
String? resolveNicknameLabel(String nicknameId) {
  for (final NicknameOption option in kNicknames) {
    if (option.id == nicknameId) return option.label;
  }
  return null;
}
