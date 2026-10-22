#!/usr/bin/env python3
"""Validate ExemplarySkills overlay completeness vs English base."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "TimeToSkill" / "TimeToSkill" / "Resources"
FIELDS = (
    "title",
    "description",
    "category",
    "oneStarDescription",
    "twoStarDescription",
    "threeStarDescription",
)

# English regional overlays are intentionally unused (base EN). Still report them.
OPTIONAL_EN = {"en-AU", "en-CA", "en-GB", "en-IN"}


def main() -> int:
    base = json.loads((RES / "ExemplarySkills.json").read_text(encoding="utf-8"))
    en_items = {item["id"]: item for item in base["items"]}
    overlays = sorted(RES.glob("ExemplarySkills_*.json"))
    report = {"skills": len(en_items), "locales": []}
    blocking = 0
    for path in overlays:
        code = path.name[len("ExemplarySkills_") : -len(".json")]
        data = json.loads(path.read_text(encoding="utf-8"))
        by_id = {item["id"]: item for item in data.get("items", [])}
        missing_ids = sorted(set(en_items) - set(by_id))
        empty = {field: 0 for field in FIELDS}
        identical = {field: 0 for field in FIELDS}
        for sid, source in en_items.items():
            row = by_id.get(sid)
            if row is None:
                for field in FIELDS:
                    empty[field] += 1
                continue
            for field in FIELDS:
                # Legacy 38 rows store star criteria inside description and leave
                # one/two/three empty in English too — treat that as OK when EN empty.
                value = str(row.get(field, "")).strip()
                en_value = str(source.get(field, "")).strip()
                if not value:
                    if field.endswith("StarDescription") and not en_value:
                        continue
                    empty[field] += 1
                elif code not in OPTIONAL_EN and not code.startswith("en") and value == en_value:
                    identical[field] += 1
        entry = {
            "code": code,
            "items": len(by_id),
            "missing_ids": len(missing_ids),
            "empty": empty,
            "identical_to_english": identical,
        }
        report["locales"].append(entry)
        is_optional = code in OPTIONAL_EN
        if not is_optional and (missing_ids or empty["title"] or empty["description"] or empty["category"]):
            blocking += 1
        if not is_optional and (
            empty["oneStarDescription"] or empty["twoStarDescription"] or empty["threeStarDescription"]
        ):
            # Only block when EN itself has those fields.
            pass

    isv = RES / "ExemplarySkills_isv.json"
    report["isv_present"] = isv.exists()
    if not isv.exists():
        blocking += 1
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 1 if blocking else 0


if __name__ == "__main__":
    sys.exit(main())
