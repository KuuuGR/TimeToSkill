#!/usr/bin/env python3
"""Periodically assemble overlays that have all 53 JSONL chunks."""
import json, time, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "data/skills-catalog/localization/out"
RES = ROOT / "TimeToSkill/TimeToSkill/Resources"
EXPECTED_CHUNKS = 53
EXPECTED_ROWS = 2108

def ready_langs():
    langs = {}
    for path in OUT.glob("*.jsonl"):
        stem = path.stem
        if stem.endswith("-all"):
            continue
        # lang may contain hyphens: es-419-00, zh-Hans-00, de-00
        parts = stem.rsplit("-", 1)
        if len(parts) != 2 or not parts[1].isdigit():
            continue
        lang, idx = parts
        langs.setdefault(lang, set()).add(idx)
    ready = []
    for lang, idxs in langs.items():
        if len(idxs) < EXPECTED_CHUNKS:
            continue
        # count rows
        rows = 0
        for path in OUT.glob(f"{lang}-*.jsonl"):
            if path.stem.rsplit("-", 1)[-1].isdigit():
                rows += sum(1 for line in path.read_text(encoding="utf-8").splitlines() if line.strip())
        if rows >= EXPECTED_ROWS:
            ready.append(lang)
    return ready

def clone(src_code: str, dst_code: str):
    src = RES / f"ExemplarySkills_{src_code}.json"
    dst = RES / f"ExemplarySkills_{dst_code}.json"
    if not src.exists():
        return False
    data = json.loads(src.read_text(encoding="utf-8"))
    # Prefer existing dst legacy overrides
    if dst.exists():
        old = {i["id"]: i for i in json.loads(dst.read_text(encoding="utf-8")).get("items", [])}
        for item in data["items"]:
            prev = old.get(item["id"])
            if prev and ":" not in item["id"]:
                for f in ("title", "description", "category", "oneStarDescription", "twoStarDescription", "threeStarDescription"):
                    if str(prev.get(f, "")).strip():
                        item[f] = prev[f]
    dst.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return True

def main():
    while True:
        ready = ready_langs()
        for lang in ready:
            print(f"assembling {lang}", flush=True)
            subprocess.check_call(
                [sys.executable, str(ROOT / "scripts/catalog/assemble_all_catalog_overlays.py"),
                 "--langs", lang, "--write"],
            )
        # Regional clones when parents ready
        if (RES / "ExemplarySkills_es.json").exists():
            clone("es", "es-419")
        if (RES / "ExemplarySkills_fr.json").exists() and len(json.loads((RES/"ExemplarySkills_fr.json").read_text()).get("items",[])) >= 2146:
            clone("fr", "fr-CA")
        if (RES / "ExemplarySkills_zh-Hans.json").exists() and len(json.loads((RES/"ExemplarySkills_zh-Hans.json").read_text()).get("items",[])) >= 2146:
            clone("zh-Hans", "zh-Hant")
        time.sleep(60)

if __name__ == "__main__":
    main()
