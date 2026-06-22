"""Bundled, owner-signed curriculum seed (Plan 14-02).

`baa_authored_ids.json` is a verbatim transcription of the canonical baa id set from the
Flutter bundled seed (`assets/curriculum/units.json` + `assets/curriculum/exercises.json`) —
the SAME seed `CurriculumRepository.getUnit/getExercises` reads. It is bundled here so the
server (whose Docker image copies only `app/`) can validate curriculum membership without
shipping the whole Flutter assets tree.

Regenerate it from the repo seed (when the repo is present) with:

    cd server && uv run python -m app.curriculum_data.generate

The generator reads the two canonical asset files and rewrites this JSON, so the bundled
copy can never silently drift from the owner-signed source.
"""
