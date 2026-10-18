#!/usr/bin/env python3
"""Validate the combined pilot-proposal register.

Separate from validate_skill_catalog.py because these records use
proposal_id and review_status pilot_proposal. Pilot files keep skill_id
and their own review statuses. This script does not modify input.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

from validate_skill_catalog import (
    emoji_parts,
    emoji_section,
    load_known_ids,
    looks_observable,
    repo_root_from_script,
)

ALLOWED_STATUS = {"pilot_proposal"}
ORIGIN = {
    "kitchen-finance",
    "movement-sport-dance",
    "technology-science-niches",
    "communication-cognition-nature",
    "general-practical-skills",
    "broad-practice-expansion",
    "practice-expansion-13",
    "practice-expansion-14",
    "practice-expansion-15",
    "practice-expansion-16",
}


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate pilot proposals.")
    parser.add_argument("data", type=Path)
    parser.add_argument("--repo", type=Path, default=None)
    parser.add_argument("--summary", action="store_true")
    args = parser.parse_args()
    repo = args.repo.resolve() if args.repo else repo_root_from_script()
    if not args.data.is_file():
        print(f"error: data file does not exist: {args.data}", file=sys.stderr)
        return 2
    errors: list[str] = []
    warnings: list[str] = []
    records = []
    for line_no, line in enumerate(args.data.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError as exc:
            print(f"error: {args.data}:{line_no}: {exc}", file=sys.stderr)
            return 2
    known_candidates, known_sources, notes = load_known_ids(repo)
    seen: dict[str, int] = {}
    emoji_owners: dict[str, list[str]] = defaultdict(list)
    for index, record in enumerate(records, 1):
        if not isinstance(record, dict):
            errors.append(f"record {index} is not an object")
            continue
        proposal_id = record.get("proposal_id")
        where = proposal_id if isinstance(proposal_id, str) and proposal_id.strip() else f"record {index}"
        if not isinstance(proposal_id, str) or not proposal_id.strip():
            errors.append(f"{where} field 'proposal_id' must be a non-empty string")
        elif proposal_id in seen:
            errors.append(f"{where} duplicates proposal_id first seen at record {seen[proposal_id]}")
        else:
            seen[proposal_id] = index
        for field in ("name", "description", "category", "emoji"):
            value = record.get(field)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{where} field '{field}' must be a non-empty string")
        if record.get("origin_pilot") not in ORIGIN:
            errors.append(f"{where} origin_pilot must be one of: {', '.join(sorted(ORIGIN))}")
        if record.get("review_status") not in ALLOWED_STATUS:
            errors.append(f"{where} review_status must be pilot_proposal")
        if not isinstance(record.get("pilot_review_status"), str) or not record.get("pilot_review_status", "").strip():
            errors.append(f"{where} pilot_review_status must preserve the pilot decision")
        levels = record.get("levels")
        if not isinstance(levels, list) or len(levels) != 3:
            errors.append(f"{where} field 'levels' must contain exactly 3 objects")
        else:
            for number, level in enumerate(levels, 1):
                if not isinstance(level, dict):
                    errors.append(f"{where} level {number} is not an object")
                    continue
                name = level.get("name")
                criterion = level.get("completion_criterion")
                if not isinstance(name, str) or not name.strip():
                    errors.append(f"{where} level {number} field 'name' must be a non-empty string")
                if not isinstance(criterion, str) or not criterion.strip():
                    errors.append(f"{where} level {number} completion_criterion must be a non-empty string")
                elif not looks_observable(criterion):
                    warnings.append(f"{where} level {number} completion_criterion is short or not clearly observable")
        for field, known in (
            ("source_candidate_ids", known_candidates),
            ("source_ids", known_sources),
        ):
            values = record.get(field)
            if not isinstance(values, list) or not values:
                errors.append(f"{where} field '{field}' must be a non-empty array of strings")
                continue
            for item in values:
                if not isinstance(item, str) or not item.strip():
                    errors.append(f"{where} field '{field}' contains an empty or non-string value")
                elif known is not None and item not in known:
                    label = "candidates-raw.jsonl" if field == "source_candidate_ids" else "sources.json"
                    errors.append(f"{where} {field} '{item}' is not in {label}")
        emoji = record.get("emoji")
        if isinstance(emoji, str) and emoji.strip() and isinstance(proposal_id, str):
            clusters, leftover = emoji_parts(emoji.strip())
            if leftover or len(clusters) != 1:
                errors.append(f"{where} emoji cannot be read as one symbol")
            else:
                emoji_owners[clusters[0]].append(proposal_id)
    counts = Counter(record.get("emoji") for record in records if isinstance(record, dict))
    top = counts.most_common(1)
    if records and top and top[0][1] >= 8:
        warnings.append(f"emoji {top[0][0]} is used {top[0][1]} times")
    lines = [
        f"errors: {len(errors)}",
        f"warnings: {len(warnings)}",
        f"records read: {len(records)}",
    ]
    if notes and not args.summary:
        lines.append("notes:")
        lines.extend(f"  {note}" for note in notes)
    if not args.summary:
        lines.append("errors:")
        lines.extend(f"  - {item}" for item in errors) if errors else lines.append("  - none")
        lines.append("warnings:")
        lines.extend(f"  - {item}" for item in warnings) if warnings else lines.append("  - none")
    lines.append("emoji:")
    shown = emoji_section(emoji_owners, len(records))
    lines.extend(f"  {line}" for line in (shown[:4] if args.summary else shown))
    sys.stdout.write("\n".join(lines) + "\n")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
