"""Repository paths for the 1001 Skills catalog tools.

Paths come from this file's location, not from the process working directory.
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DATA = REPO / "data" / "skills-catalog"
RESEARCH = DATA / "research"
BATCHES = DATA / "review-batches"
DOCS = REPO / "docs" / "catalog-research"


def check_only(required: list[Path]) -> None:
    """Exit before any write when the process was started with --check."""
    if "--check" not in sys.argv:
        return
    missing = [path for path in required if not path.is_file()]
    if missing:
        print("missing paths:", file=sys.stderr)
        for path in missing:
            print(f"  {path}", file=sys.stderr)
        raise SystemExit(1)
    print("paths ok")
    for path in required:
        print(path)
    raise SystemExit(0)
