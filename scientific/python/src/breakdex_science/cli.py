from __future__ import annotations

import argparse
import json
from pathlib import Path

from .ai_stack import ai_stack_summary
from .export_validation import load_export, summarize_export


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="breakdex-science")
    subparsers = parser.add_subparsers(dest="command", required=True)

    validate_export = subparsers.add_parser(
        "validate-export",
        help="Summarize a Breakdex JSON export fixture or backup.",
    )
    validate_export.add_argument("path", type=Path)

    subparsers.add_parser(
        "smoke-ai",
        help="Report installed AI/scientific package versions and tracing config.",
    )

    return parser


def main() -> None:
    parser = _build_parser()
    args = parser.parse_args()

    if args.command == "validate-export":
        payload = load_export(args.path)
        print(json.dumps(summarize_export(payload), indent=2, sort_keys=True))
        return

    if args.command == "smoke-ai":
        print(json.dumps(ai_stack_summary(), indent=2, sort_keys=True))
        return

    parser.error(f"Unknown command: {args.command}")


if __name__ == "__main__":
    main()
