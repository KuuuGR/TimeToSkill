#!/usr/bin/env python3
"""Fill category-glossary.json using Argos CT2 for every supported overlay language."""

from __future__ import annotations

import json
import sys
from pathlib import Path

# Reuse translator
sys.path.insert(0, str(Path(__file__).resolve().parent))
from translate_catalog_argos import LANG_TO_ARGOS, ArgosCT2  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "TimeToSkill" / "TimeToSkill" / "Resources"
LOC = ROOT / "data" / "skills-catalog" / "localization"
GLOSSARY = LOC / "category-glossary.json"

# Minimal Interslavic (Latin) for any category not yet filled.
# Extended map generated below from English with Slavic-aware wording.
ISV_EXTRA = {
    "Creative & Crafts": "Tvorčestvo i remeslo",
    "Games & Recreation": "Igry i odpočinok",
    "Health & Endurance": "Zdravje i izdržljivost",
    "Learning & Memory": "Učenje i paměť",
    "Mindfulness & Discipline": "Svědomost i disciplina",
    "Outdoor & Nature": "Na dvorě i priroda",
    "Sports": "Sport",
}


def main() -> int:
    base = json.loads((RES / "ExemplarySkills.json").read_text(encoding="utf-8"))
    categories = sorted({item["category"] for item in base["items"]})
    glossary: dict[str, dict[str, str]] = {}
    if GLOSSARY.exists():
        glossary = json.loads(GLOSSARY.read_text(encoding="utf-8"))

    engines: dict[str, ArgosCT2] = {}
    for lang, argos in LANG_TO_ARGOS.items():
        if argos not in engines:
            try:
                engines[argos] = ArgosCT2(argos)
                print(f"loaded {argos}", flush=True)
            except Exception as exc:  # noqa: BLE001
                print(f"skip engine {argos}: {exc}", flush=True)

    filled = 0
    for cat in categories:
        entry = glossary.setdefault(cat, {})
        # isv
        if not str(entry.get("isv", "")).strip():
            if cat in ISV_EXTRA:
                entry["isv"] = ISV_EXTRA[cat]
                filled += 1
        for lang, argos in LANG_TO_ARGOS.items():
            if str(entry.get(lang, "")).strip():
                continue
            engine = engines.get(argos)
            if engine is None:
                continue
            entry[lang] = engine.translate_many([cat])[0]
            filled += 1
        glossary[cat] = entry

    GLOSSARY.write_text(json.dumps(glossary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    missing_isv = [c for c in categories if not str(glossary[c].get("isv", "")).strip()]
    print(json.dumps({"filled": filled, "categories": len(categories), "missing_isv": len(missing_isv)}, indent=2))
    if missing_isv:
        print("missing_isv_sample", missing_isv[:30])
    return 0


if __name__ == "__main__":
    sys.exit(main())
