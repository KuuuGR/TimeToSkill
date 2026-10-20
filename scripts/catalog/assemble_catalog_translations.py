#!/usr/bin/env python3
"""Assemble pl/es/eo catalog overlays from translated JSONL chunks.

The English catalog stays in ExemplarySkills.json. Overlay files keep the
original 38 translations and add the 2108 new ids. Ids, emoji, and
difficulty are copied from the base file. User data is not touched.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "TimeToSkill" / "TimeToSkill" / "Resources"
LOC = ROOT / "data" / "skills-catalog" / "localization"
OUT = LOC / "out"
FIELDS = (
    "title",
    "description",
    "category",
    "oneStarDescription",
    "twoStarDescription",
    "threeStarDescription",
)
LANGS = ("pl", "es", "eo")


def load_jsonl(path: Path) -> list[dict]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows


def main() -> int:
    base = json.loads((RES / "ExemplarySkills.json").read_text(encoding="utf-8"))
    new_items = [item for item in base["items"] if ":" in item["id"]]
    old_items = [item for item in base["items"] if ":" not in item["id"]]
    by_id = {item["id"]: item for item in new_items}
    glossary = json.loads((LOC / "category-glossary.json").read_text(encoding="utf-8"))
    report = {
        "source_new": len(new_items),
        "source_original": len(old_items),
        "english_complete": sum(
            1
            for item in new_items
            if all(str(item.get(field, "")).strip() for field in FIELDS)
        ),
    }
    exit_code = 0
    for lang in LANGS:
        found: dict[str, dict] = {}
        duplicate = 0
        for path in sorted(OUT.glob(f"{lang}-*.jsonl")):
            for row in load_jsonl(path):
                skill_id = row.get("id")
                if skill_id in found:
                    duplicate += 1
                found[skill_id] = row
        missing = [skill_id for skill_id in by_id if skill_id not in found]
        extra = [skill_id for skill_id in found if skill_id not in by_id]
        identical = {field: 0 for field in FIELDS if field != "category"}
        empty = {field: 0 for field in FIELDS}
        category_mismatch = 0
        kept_names = []
        for skill_id, row in found.items():
            source = by_id.get(skill_id)
            if source is None:
                continue
            expected = glossary.get(source["category"], {}).get(lang)
            if row.get("category") != expected:
                category_mismatch += 1
            for field in FIELDS:
                value = str(row.get(field, "")).strip()
                if not value:
                    empty[field] += 1
                elif field != "category" and value == str(source.get(field, "")).strip():
                    identical[field] += 1
                    if field == "title" and len(kept_names) < 30:
                        kept_names.append(skill_id)
        complete = 0
        for skill_id, row in found.items():
            if skill_id not in by_id:
                continue
            if all(str(row.get(field, "")).strip() for field in FIELDS):
                complete += 1
        lang_report = {
            "files": len(list(OUT.glob(f"{lang}-*.jsonl"))),
            "rows": len(found),
            "complete": complete,
            "missing": len(missing),
            "extra": len(extra),
            "duplicate_lines": duplicate,
            "empty": empty,
            "identical_to_english": identical,
            "category_mismatch": category_mismatch,
            "sample_identical_titles": kept_names,
        }
        report[lang] = lang_report
        if missing or extra or duplicate or any(empty.values()) or category_mismatch:
            exit_code = 1
            continue
        existing_path = RES / f"ExemplarySkills_{lang}.json"
        existing = []
        if existing_path.exists():
            previous = json.loads(existing_path.read_text(encoding="utf-8"))
            existing = [item for item in previous["items"] if ":" not in item["id"]]
        assembled = []
        for source in new_items:
            row = found[source["id"]]
            assembled.append(
                {
                    "id": source["id"],
                    "title": row["title"].strip(),
                    "description": row["description"].strip(),
                    "imageName": source["imageName"],
                    "category": row["category"].strip(),
                    "difficulty": source["difficulty"],
                    "oneStarDescription": row["oneStarDescription"].strip(),
                    "twoStarDescription": row["twoStarDescription"].strip(),
                    "threeStarDescription": row["threeStarDescription"].strip(),
                }
            )
        payload = {"catalogVersion": base["catalogVersion"], "items": existing + assembled}
        existing_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        lang_report["written"] = str(existing_path)
        lang_report["written_count"] = len(payload["items"])
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
