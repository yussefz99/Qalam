"""CLI entrypoint — ``python -m audio_pipeline <command>`` (run from tools/).

Commands:
  normalize   Ingest + normalize raw recordings from staging/ into assets/audio/.
  generate    Rewrite the README table + the Dart _audioIdToAsset map from the manifest.
  check       Fail (exit 1) on any drift between manifest, files, README and Dart map.
"""

from __future__ import annotations

import argparse
import sys

from . import check as check_mod
from . import generators
from . import normalize as normalize_mod
from .manifest import ManifestError, REPO_ROOT, load_manifest


def _cmd_generate(_: argparse.Namespace) -> int:
    entries = load_manifest()
    changed = generators.write_generated(entries)
    if changed:
        for path in changed:
            print(f"  updated {path.relative_to(REPO_ROOT)}")
        print(f"Regenerated {len(changed)} file(s) from {len(entries)} manifest entries.")
    else:
        print(f"Already up to date — {len(entries)} entries, nothing to rewrite.")
    return 0


def _cmd_check(_: argparse.Namespace) -> int:
    return check_mod.run_check()


def _cmd_normalize(_: argparse.Namespace) -> int:
    return normalize_mod.run_normalize()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="audio_pipeline",
        description="Manifest-driven audio pipeline for Qalam bundled pronunciation clips.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("normalize", help="ingest + normalize raw recordings from staging/").set_defaults(
        func=_cmd_normalize
    )
    sub.add_parser("generate", help="rewrite README table + Dart map from the manifest").set_defaults(
        func=_cmd_generate
    )
    sub.add_parser("check", help="fail on any drift (CI-friendly)").set_defaults(func=_cmd_check)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except ManifestError as exc:
        print(f"MANIFEST ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
