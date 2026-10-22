#!/usr/bin/env python3
"""Assemble ExemplarySkills_<lang>.json overlays from JSONL translation chunks.

Preserves existing legacy rows (ids without ':') from the current overlay when
present; otherwise leaves them absent (English base remains for those ids until
translated). Copies imageName/difficulty from the English base. Never deletes ids.
"""

from __future__ import annotations

import argparse
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


def load_jsonl(path: Path) -> list[dict]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows


def assemble_lang(lang: str, base: dict, glossary: dict, write: bool) -> dict:
    new_items = [item for item in base["items"] if ":" in item["id"]]
    by_id = {item["id"]: item for item in new_items}
    found: dict[str, dict] = {}
    for path in sorted(OUT.glob(f"{lang}-*.jsonl")):
        # Avoid matching es-419 when lang is es: require exact prefix before digits
        stem = path.stem  # e.g. de-00, es-419-00
        prefix, _, rest = stem.partition("-")
        if lang == "es" and stem.startswith("es-419"):
            continue
        if lang == "fr" and stem.startswith("fr-CA"):
            continue
        if lang == "pt-BR" and not stem.startswith("pt-BR-"):
            continue
        if lang == "pt-PT" and not stem.startswith("pt-PT-"):
            continue
        if lang == "zh-Hans" and not stem.startswith("zh-Hans-"):
            continue
        if lang == "zh-Hant" and not stem.startswith("zh-Hant-"):
            continue
        if lang in {"es", "fr", "pt", "zh"}:
            pass
        # Generic: file must start with f"{lang}-"
        if not stem.startswith(f"{lang}-"):
            continue
        for row in load_jsonl(path):
            found[row["id"]] = row

    missing = [sid for sid in by_id if sid not in found]
    empty = {field: 0 for field in FIELDS}
    identical = {field: 0 for field in FIELDS if field != "category"}
    category_mismatch = 0
    complete = 0
    for sid, row in found.items():
        source = by_id.get(sid)
        if source is None:
            continue
        expected = glossary.get(source["category"], {}).get(lang)
        if expected and row.get("category") != expected:
            category_mismatch += 1
        ok = True
        for field in FIELDS:
            value = str(row.get(field, "")).strip()
            if not value:
                empty[field] += 1
                ok = False
            elif field != "category" and value == str(source.get(field, "")).strip():
                identical[field] += 1
        if ok:
            complete += 1

    report = {
        "lang": lang,
        "rows": len(found),
        "complete": complete,
        "missing": len(missing),
        "empty": empty,
        "identical_to_english": identical,
        "category_mismatch": category_mismatch,
    }

    if missing or any(empty.values()):
        report["ready"] = False
        return report

    existing_path = RES / f"ExemplarySkills_{lang}.json"
    legacy: list[dict] = []
    if existing_path.exists():
        previous = json.loads(existing_path.read_text(encoding="utf-8"))
        legacy = [item for item in previous["items"] if ":" not in item["id"]]

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
    # Keep legacy first (original 38), then expansion — matches pl/es layout.
    payload = {"catalogVersion": base["catalogVersion"], "items": legacy + assembled}
    report["ready"] = True
    report["written_count"] = len(payload["items"])
    if write:
        existing_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        report["written"] = str(existing_path)
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--langs", default="", help="Comma list; default = langs with out/*.jsonl")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    base = json.loads((RES / "ExemplarySkills.json").read_text(encoding="utf-8"))
    glossary = {}
    gloss_path = LOC / "category-glossary.json"
    if gloss_path.exists():
        glossary = json.loads(gloss_path.read_text(encoding="utf-8"))

    if args.langs.strip():
        langs = [p.strip() for p in args.langs.split(",") if p.strip()]
    else:
        langs = sorted({p.name.rsplit("-", 1)[0] for p in OUT.glob("*.jsonl")})

    reports = [assemble_lang(lang, base, glossary, write=args.write) for lang in langs]
    print(json.dumps(reports, ensure_ascii=False, indent=2))
    return 0 if all(r.get("ready") for r in reports) else 1


if __name__ == "__main__":
    sys.exit(main())
