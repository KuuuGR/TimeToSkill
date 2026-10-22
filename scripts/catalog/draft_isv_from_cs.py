#!/usr/bin/env python3
"""Build ExemplarySkills_isv.json from English via Czech Argos + Interslavic Latin polish.

Categories come from category-glossary.json (isv). Body text is Czech MT adapted
toward Interslavic Latin orthography and a small lexical overlay so the app can
transliterate to Cyrillic/Glagolitic. This is a full-catalog draft for isv.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from translate_catalog_argos import ArgosCT2, FIELDS  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "TimeToSkill" / "TimeToSkill" / "Resources"
LOC = ROOT / "data" / "skills-catalog" / "localization"
GLOSSARY = LOC / "category-glossary.json"
OUT = LOC / "out"

LEXICON = [
    (r"\bpéče\b", "peča"),
    (r"\bzvířat\w*", "životin"),
    (r"\bzvíře\b", "životina"),
    (r"\bházení\b", "metanje"),
    (r"\bházet\b", "metati"),
    (r"\bpřesné\b", "točno"),
    (r"\bpřesný\b", "točny"),
    (r"\bumění\b", "uměnje"),
    (r"\bdovednost\w*", "umělost"),
    (r"\bčtení\b", "čitanje"),
    (r"\bpsaní\b", "pisanje"),
    (r"\bučení\b", "učenje"),
    (r"\bhru\b", "igru"),
    (r"\bhry\b", "igry"),
    (r"\bhra\b", "igra"),
    (r"\bhudba\b", "muzika"),
    (r"\bpohyb\b", "dviženje"),
    (r"\bpříroda\b", "priroda"),
    (r"\bdomácí\b", "domačy"),
    (r"\bjídlo\b", "jedalo"),
    (r"\bvaření\b", "kuhanje"),
]


def czech_toward_isv(text: str) -> str:
    if not text:
        return text
    out = text
    for pattern, repl in LEXICON:
        out = re.sub(pattern, repl, out, flags=re.IGNORECASE)
    # Diacritic normalization toward Interslavic Latin
    trans = str.maketrans(
        {
            "ř": "r",
            "Ř": "R",
            "ů": "u",
            "Ů": "U",
            "ď": "d",
            "Ď": "D",
            "ť": "t",
            "Ť": "T",
            "ň": "n",
            "Ň": "N",
            "ě": "e",
            "Ě": "E",
            "á": "a",
            "Á": "A",
            "é": "e",
            "É": "E",
            "í": "i",
            "Í": "I",
            "ó": "o",
            "Ó": "O",
            "ú": "u",
            "Ú": "U",
            "ý": "y",
            "Ý": "Y",
        }
    )
    out = out.translate(trans)
    # Keep č š ž ě-less; restore č/š/ž which maketrans didn't touch — good.
    return out


def main() -> int:
    en = json.loads((RES / "ExemplarySkills.json").read_text(encoding="utf-8"))
    glossary = json.loads(GLOSSARY.read_text(encoding="utf-8")) if GLOSSARY.exists() else {}
    engine = ArgosCT2("cs")

    # Translate all non-category fields in batches of skills
    items_out = []
    batch_skills = []
    BATCH = 40

    def flush(batch: list[dict]) -> None:
        flat = []
        for row in batch:
            for field in FIELDS:
                if field == "category":
                    flat.append("")  # filled from glossary
                else:
                    flat.append(str(row.get(field, "") or ""))
        translated = engine.translate_many(flat)
        cursor = 0
        for row in batch:
            out = {
                "id": row["id"],
                "imageName": row["imageName"],
                "difficulty": row["difficulty"],
            }
            for field in FIELDS:
                if field == "category":
                    cat = glossary.get(row["category"], {}).get("isv") or czech_toward_isv(
                        engine.translate_many([row["category"]])[0]
                    )
                    out[field] = cat
                    cursor += 1
                else:
                    out[field] = czech_toward_isv(translated[cursor])
                    cursor += 1
            items_out.append(out)
            print(json.dumps({"id": out["id"], "title": out["title"]}, ensure_ascii=False), flush=True)

    for item in en["items"]:
        batch_skills.append(item)
        if len(batch_skills) >= BATCH:
            flush(batch_skills)
            batch_skills = []
    if batch_skills:
        flush(batch_skills)

    payload = {"catalogVersion": en["catalogVersion"], "items": items_out}
    path = RES / "ExemplarySkills_isv.json"
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "isv-all.jsonl").write_text(
        "\n".join(
            json.dumps({k: it[k] for k in ("id",) + FIELDS}, ensure_ascii=False) for it in items_out
        )
        + "\n",
        encoding="utf-8",
    )
    print(json.dumps({"written": str(path), "items": len(items_out)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
