# Qalam — Design System (drop zone)

This folder is the **canonical design reference** for Qalam's UI. Whatever you put
here is what Phase 1 translates into the Flutter foundation (`lib/theme/`) and what
`/gsd-ui-phase` builds screens against. Source: the design system built in
**Claude Design** (claude.ai/design).

## What to drop here

Pick the highest-fidelity export you can (top is best):

1. **Claude Code handoff bundle** — in Claude Design: `Export → Send to Claude Code`.
   If it produces a downloadable bundle/zip, unzip it into `docs/design/kit/`.
   This carries the design tokens actually used, component structure, layout
   hierarchy, and referenced assets — the richest input.
2. **`.zip` export** — `Export → .zip`. Unzip into `docs/design/kit/`.
3. **Standalone HTML** — `Export → standalone HTML`. Save as
   `docs/design/kit/design.html` (a single file I can read tokens from).

> Internal Claude Design **share URLs** (view/comment/edit) are authenticated and
> can't be fetched automatically — please export files instead. A *public*
> "anyone with the link" URL is OK; paste it in `docs/design/SOURCE.md`.

## Also include (important)

- **Fonts** → `docs/design/fonts/` — the actual `.ttf`/`.otf` files the kit uses.
  Flutter must *bundle* fonts (no runtime fetch, per the offline rule). Include the
  Arabic teaching font here too if your kit specifies one.
- **Screenshots** → `docs/design/screens/` — PNGs of the key screens (home/today's
  lesson, tracing surface, profile/onboarding, parent area) as visual ground-truth.
- **Notes** → `docs/design/SOURCE.md` — where it came from (Claude Design project
  link/name), any tokens not obvious from the export (color names, spacing scale,
  font sizes), and anything the export dropped.

## Suggested layout

```
docs/design/
├── README.md            ← this file
├── SOURCE.md            ← provenance + token notes (you write)
├── kit/                 ← the exported bundle / zip contents / design.html
├── fonts/               ← .ttf / .otf font files
└── screens/             ← screenshot PNGs
```

## What happens next

Once the kit is here, Phase 1 (Foundations & RTL Shell) will:
- extract color / type / spacing / radius tokens → `lib/theme/colors.dart`,
  `text_styles.dart`, `dimens.dart`, `app_theme.dart`
- bundle the fonts in `assets/fonts/` and declare them in `pubspec.yaml`
- wire assets/images into the asset pipeline

and `/gsd-ui-phase 1` will produce the design contract referencing these screens.

*Not covered by a typical UI kit:* the **Arabic teaching font** (the Naskh letterform
the child traces) — if your kit doesn't specify one, we default to Noto Naskh Arabic.
