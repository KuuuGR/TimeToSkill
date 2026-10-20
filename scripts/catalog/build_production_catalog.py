#!/usr/bin/env python3
"""Build the app catalog from the original production set plus accepted pilots.

Pilot files stay pilot files. ``review_status`` is not rewritten. A row is
included only when the latest copy of its ``proposal_id`` has
``pilot_review_status == "accepted"``, a stable id, a name, a description,
and three non-empty completion criteria. Difficulty is stored as 1 because
the proposals do not carry a difficulty rating. The original 38 production
rows are kept as they are.

The app reads ``ExemplarySkills.json`` and overlays a localized file by id.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CURATED = ROOT / "data" / "skills-catalog" / "curated"
OUTPUT = ROOT / "TimeToSkill" / "TimeToSkill" / "Resources" / "ExemplarySkills.json"
CATALOG_VERSION = 3


def latest_accepted() -> tuple[list[dict], dict[str, int]]:
    files = sorted(CURATED.glob("pilot-proposals-v*.jsonl"), key=lambda path: int(path.stem.split("-v")[-1]))
    latest: dict[str, dict] = {}
    skipped = {"missing_id": 0, "not_accepted": 0, "incomplete": 0, "duplicate_name": 0}
    for path in files:
        for line in path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            row = json.loads(line)
            proposal_id = (row.get("proposal_id") or "").strip()
            if not proposal_id:
                skipped["missing_id"] += 1
                continue
            latest[proposal_id] = row

    names: set[str] = set()
    ready: list[dict] = []
    for proposal_id, row in latest.items():
        if row.get("pilot_review_status") != "accepted" or row.get("review_status") != "pilot_proposal":
            skipped["not_accepted"] += 1
            continue
        levels = row.get("levels")
        criteria = []
        if isinstance(levels, list):
            criteria = [str(level.get("completion_criterion") or "").strip() for level in levels[:3]]
        name = str(row.get("name") or "").strip()
        description = str(row.get("description") or "").strip()
        category = str(row.get("category") or "").strip()
        emoji = str(row.get("emoji") or "").strip()
        folded = name.casefold()
        if not name or not description or not category or not emoji or len(criteria) != 3 or any(not item for item in criteria):
            skipped["incomplete"] += 1
            continue
        if folded in names:
            skipped["duplicate_name"] += 1
            continue
        names.add(folded)
        ready.append(
            {
                "id": proposal_id,
                "title": name,
                "description": description,
                "imageName": emoji,
                "category": category,
                "difficulty": 1,
                "oneStarDescription": criteria[0],
                "twoStarDescription": criteria[1],
                "threeStarDescription": criteria[2],
            }
        )
    skipped["source_rows"] = len(latest)
    skipped["accepted_ready"] = len(ready)
    return ready, skipped


def main() -> None:
    current = json.loads(OUTPUT.read_text(encoding="utf-8"))
    original = current["items"]
    original_ids = {item["id"] for item in original}
    added, counts = latest_accepted()
    fresh = [item for item in added if item["id"] not in original_ids]
    original_names = {item["title"].casefold() for item in original}
    fresh = [item for item in fresh if item["title"].casefold() not in original_names]
    merged = list(original) + fresh
    merged.sort(key=lambda item: (item["title"].casefold(), item["id"]))
    payload = {"catalogVersion": CATALOG_VERSION, "items": merged}
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        json.dumps(
            {
                "original": len(original),
                "source_unique": counts["source_rows"],
                "accepted_ready": counts["accepted_ready"],
                "added": len(fresh),
                "output": len(merged),
                "skipped": {key: value for key, value in counts.items() if key not in {"source_rows", "accepted_ready"}},
                "catalogVersion": CATALOG_VERSION,
                "output_path": str(OUTPUT),
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
