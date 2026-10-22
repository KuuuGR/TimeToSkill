#!/usr/bin/env python3
"""Draft Interslavic (Latin) catalog overlay from the complete Polish overlay.

This is a controlled Slavic draft for the isv catalog file. Categories use the
glossary. Body text applies a Polish→Interslavic lexical substitution table and
light orthography normalization. Output is Latin-script Interslavic so the app
can transliterate to Cyrillic/Glagolitic at display time.

Quality: better than leaving English; not a substitute for full editorial ISV.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "TimeToSkill" / "TimeToSkill" / "Resources"
LOC = ROOT / "data" / "skills-catalog" / "localization"
GLOSSARY = LOC / "category-glossary.json"
OUT = LOC / "out"

# Longest-first phrase replacements (Polish → Interslavic Latin).
REPLACEMENTS = [
    ("umiejętność", "umělost"),
    ("umiejętności", "umělosti"),
    ("ukończono", "dokončeno"),
    ("ukończyć", "dokončiti"),
    ("napisz", "napiši"),
    ("napisać", "napisati"),
    ("czytanie", "čitanje"),
    ("czytać", "čitati"),
    ("pisanie", "pisanje"),
    ("pisać", "pisati"),
    ("nauka", "nauka"),
    ("uczenie", "učenje"),
    ("uczyć", "učiti"),
    ("zwierzę", "životina"),
    ("zwierzęta", "životiny"),
    ("opieka", "peča"),
    ("nad", "nad"),
    ("przyroda", "priroda"),
    ("natura", "priroda"),
    ("muzyka", "muzika"),
    ("ruch", "dviženje"),
    ("ćwiczenie", "vježba"),
    ("ćwiczenia", "vježby"),
    ("dom", "dom"),
    ("jedzenie", "jedalo"),
    ("gotowanie", "kuhanje"),
    ("gra", "igra"),
    ("gry", "igry"),
    ("sport", "sport"),
    ("zdrowie", "zdravje"),
    ("pamięć", "paměť"),
    ("język", "jezyk"),
    ("języki", "języky"),
    ("komunikacja", "komunikacija"),
    ("rysowanie", "rysovanje"),
    ("malowanie", "malovanje"),
    ("ręka", "rųka"),
    ("ręce", "rųky"),
    ("lewa", "lěva"),
    ("prawa", "prava"),
    ("dzień", "den"),
    ("dni", "dni"),
    ("tydzień", "tyden"),
    ("miesiąc", "měsec"),
    ("rok", "god"),
    ("lata", "lěta"),
    ("prób", "prob"),
    ("próba", "proba"),
    ("cel", "cěl"),
    ("cele", "cěli"),
    ("odległość", "daljina"),
    ("krótki", "krótky"),
    ("długi", "dȯlgy"),
    ("mały", "maly"),
    ("duży", "veliky"),
    ("różne", "različne"),
    ("jednocześnie", "jednovrěmenno"),
    ("zdanie", "rečenje"),
    ("akapit", "paragraf"),
    ("słowa", "slova"),
    ("słowo", "slovo"),
]


def pl_to_isv(text: str) -> str:
    if not text:
        return text
    out = text
    for src, dst in sorted(REPLACEMENTS, key=lambda pair: len(pair[0]), reverse=True):
        out = re.sub(re.escape(src), dst, out, flags=re.IGNORECASE)

    # Orthography hints commonly needed after Polish source
    out = out.replace("cz", "č").replace("sz", "š").replace("ż", "ž").replace("ź", "z")
    out = out.replace("ą", "ų").replace("ę", "e").replace("ł", "l").replace("ń", "nj")
    out = out.replace("ó", "o").replace("ć", "ć").replace("Ś", "S").replace("ś", "s")
    # Fix double replacements from mixed case — keep readable Latin ISV
    return out


def main() -> None:
    pl = json.loads((RES / "ExemplarySkills_pl.json").read_text(encoding="utf-8"))
    en = json.loads((RES / "ExemplarySkills.json").read_text(encoding="utf-8"))
    glossary = json.loads(GLOSSARY.read_text(encoding="utf-8")) if GLOSSARY.exists() else {}
    en_by = {item["id"]: item for item in en["items"]}

    OUT.mkdir(parents=True, exist_ok=True)
    # Write as single assembled overlay directly (full file), plus jsonl for tooling.
    items = []
    jsonl_lines = []
    for item in pl["items"]:
        source = en_by[item["id"]]
        cat = glossary.get(source["category"], {}).get("isv") or pl_to_isv(item["category"])
        row = {
            "id": item["id"],
            "title": pl_to_isv(item["title"]),
            "description": pl_to_isv(item["description"]),
            "imageName": source["imageName"],
            "category": cat,
            "difficulty": source["difficulty"],
            "oneStarDescription": pl_to_isv(item.get("oneStarDescription", "")),
            "twoStarDescription": pl_to_isv(item.get("twoStarDescription", "")),
            "threeStarDescription": pl_to_isv(item.get("threeStarDescription", "")),
        }
        items.append(row)
        jsonl_lines.append(
            json.dumps(
                {
                    "id": row["id"],
                    "title": row["title"],
                    "description": row["description"],
                    "category": row["category"],
                    "oneStarDescription": row["oneStarDescription"],
                    "twoStarDescription": row["twoStarDescription"],
                    "threeStarDescription": row["threeStarDescription"],
                },
                ensure_ascii=False,
            )
        )

    payload = {"catalogVersion": en["catalogVersion"], "items": items}
    out_path = RES / "ExemplarySkills_isv.json"
    out_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUT / "isv-all.jsonl").write_text("\n".join(jsonl_lines) + "\n", encoding="utf-8")
    print(json.dumps({"written": str(out_path), "items": len(items)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
