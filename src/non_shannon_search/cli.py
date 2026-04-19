# SPDX-FileCopyrightText: 2026 Christopher Boone
#
# SPDX-License-Identifier: MIT

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

from .canonical import canonicalize_candidate
from .emit_lean import emit_candidate_constant
from .schema import load_candidate, validate_candidate_path


def build_parser() -> argparse.ArgumentParser:
    """Builds the CLI argument parser."""

    parser = argparse.ArgumentParser(prog="non-shannon-search")
    subparsers = parser.add_subparsers(dest="command", required=True)

    validate_schema = subparsers.add_parser("validate-schema", help="validate a candidate inequality JSON file")
    validate_schema.add_argument("path", type=Path)

    canonicalize = subparsers.add_parser("canonicalize", help="canonicalize a candidate inequality JSON file")
    canonicalize.add_argument("path", type=Path)

    emit_lean = subparsers.add_parser("emit-lean", help="emit a Lean fixture skeleton for a candidate")
    emit_lean.add_argument("path", type=Path)
    emit_lean.add_argument("--name", dest="constant_name", default=None)

    return parser


def main(argv: list[str] | None = None) -> int:
    """Runs the CLI entry point."""

    args = build_parser().parse_args(argv)

    if args.command == "validate-schema":
        validate_candidate_path(args.path)
        print(f"Validated {args.path}")
        return 0

    if args.command == "canonicalize":
        candidate = canonicalize_candidate(load_candidate(args.path))
        json.dump(candidate.to_dict(), sys.stdout, indent=2)
        sys.stdout.write("\n")
        return 0

    if args.command == "emit-lean":
        candidate = load_candidate(args.path)
        print(emit_candidate_constant(candidate, constant_name=args.constant_name))
        return 0

    raise ValueError(f"Unknown command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
