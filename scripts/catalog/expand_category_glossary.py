#!/usr/bin/env python3
"""Fill category-glossary.json for every catalog overlay language via MyMemory.

Keeps existing pl/es/eo entries. Adds the 7 categories missing from the original
glossary. Resumable.
"""

from __future__ import annotations

import json
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "TimeToSkill" / "TimeToSkill" / "Resources"
LOC = ROOT / "data" / "skills-catalog" / "localization"
GLOSSARY = LOC / "category-glossary.json"

TARGET = {
    "ar": "ar-SA",
    "ca": "ca-ES",
    "cs": "cs-CZ",
    "da": "da-DK",
    "de": "de-DE",
    "el": "el-GR",
    "eo": "eo",
    "es": "es-ES",
    "es-419": "es-MX",
    "fi": "fi-FI",
    "fr": "fr-FR",
    "fr-CA": "fr-CA",
    "he": "he-IL",
    "hi": "hi-IN",
    "hr": "hr-HR",
    "hu": "hu-HU",
    "id": "id-ID",
    "isv": None,  # filled manually after Slavic pass
    "it": "it-IT",
    "ja": "ja-JP",
    "ko": "ko-KR",
    "ms": "ms-MY",
    "nb": "no-NO",
    "nl": "nl-NL",
    "pl": "pl-PL",
    "pt-BR": "pt-BR",
    "pt-PT": "pt-PT",
    "ro": "ro-RO",
    "ru": "ru-RU",
    "sk": "sk-SK",
    "sv": "sv-SE",
    "th": "th-TH",
    "tr": "tr-TR",
    "uk": "uk-UA",
    "vi": "vi-VN",
    "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW",
}

# Hand-authored Interslavic (Latin) for categories — not MT.
ISV_CATEGORIES = {
    "Access": "Dostupnost",
    "Access and plain language": "Dostupnost i prosty jezyk",
    "Agreements": "Dogovory",
    "Animal care": "Pečenje o životinah",
    "Animal care and nature": "Pečenje o životinah i priroda",
    "Aquatic skills": "Vodne umělosti",
    "Astronomy and observation": "Astronomija i observacija",
    "Bike and walk": "Kolo i hodženje",
    "Buildings": "Budynky",
    "Buying decisions": "Kupne rěšenja",
    "Care and accompaniment": "Pečenje i soprovođenje",
    "Care in the room": "Pečenje v sobě",
    "Chess": "Šahy",
    "Citizen science": "Građanska nauka",
    "Citizen science and research": "Građanska nauka i izslědovanje",
    "City reading": "Čitanje grada",
    "Collections": "Kolekcije",
    "Communication": "Komunikacija",
    "Community": "Občina",
    "Cooking": "Kuhanje",
    "Creative & Crafts": "Tvorčestvo i remeslo",
    "Culture": "Kultura",
    "Drawing": "Rysovanje",
    "Everyday organisation": "Svakodnevna organizacija",
    "Food": "Jedalo",
    "Games": "Igry",
    "Games & Recreation": "Igry i odpočinok",
    "Hand tricks": "Ručne triki",
    "Health & Endurance": "Zdravje i izdržljivost",
    "Home": "Dom",
    "Learning & Memory": "Učenje i paměť",
    "Materials": "Materialy",
    "Mindfulness & Discipline": "Svědomost i disciplina",
    "Movement": "Dviženje",
    "Music practice": "Muzična praktika",
    "Nature reading": "Čitanje prirody",
    "Outdoor & Nature": "Na dvorě i priroda",
    "Paper builds": "Papierne konstrukcije",
    "Science table": "Naučny stol",
    "Small experiments": "Male eksperimenty",
    "Small making": "Male tvorjenje",
    "Sound tricks": "Zvučne triki",
    "Sports": "Sport",
    "Talk": "Besěda",
    "Writing": "Pisanje",
}


def translate(text: str, target: str) -> str:
    q = urllib.parse.urlencode({"q": text, "langpair": f"en|{target}"})
    url = f"https://api.mymemory.translated.net/get?{q}"
    for attempt in range(6):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Time4SkillCatalog/1.0"})
            with urllib.request.urlopen(req, timeout=45) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            if data.get("quotaFinished"):
                raise RuntimeError("quota finished")
            out = (data.get("responseData") or {}).get("translatedText") or ""
            if int(data.get("responseStatus") or 0) != 200 or not out.strip():
                raise RuntimeError(str(data)[:200])
            if "MYMEMORY WARNING" in out.upper():
                raise RuntimeError(out)
            return out.strip()
        except Exception:
            time.sleep(min(2 ** attempt, 20))
    raise RuntimeError(f"failed: {text} -> {target}")


def main() -> int:
    base = json.loads((RES / "ExemplarySkills.json").read_text(encoding="utf-8"))
    categories = sorted({item["category"] for item in base["items"]})
    glossary: dict[str, dict[str, str]] = {}
    if GLOSSARY.exists():
        glossary = json.loads(GLOSSARY.read_text(encoding="utf-8"))

    langs = [code for code, target in TARGET.items() if target or code == "isv"]
    filled = 0
    for cat in categories:
        entry = glossary.setdefault(cat, {})
        for lang in langs:
            if str(entry.get(lang, "")).strip():
                continue
            if lang == "isv":
                # Prefer hand map; otherwise leave for later Slavic pass (do not MT).
                if cat in ISV_CATEGORIES:
                    entry[lang] = ISV_CATEGORIES[cat]
                    filled += 1
                continue
            entry[lang] = translate(cat, TARGET[lang])
            filled += 1
            time.sleep(0.25)
            if filled % 25 == 0:
                GLOSSARY.write_text(json.dumps(glossary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
                print(f"checkpoint filled={filled} last={cat}/{lang}", flush=True)
        glossary[cat] = entry

    # Fill remaining isv via Polish-informed fallbacks already in ISV map only
    GLOSSARY.write_text(json.dumps(glossary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    missing_isv = [c for c in categories if not str(glossary.get(c, {}).get("isv", "")).strip()]
    report = {
        "categories": len(categories),
        "langs": langs,
        "filled_this_run": filled,
        "missing_isv": missing_isv,
        "path": str(GLOSSARY),
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not missing_isv else 0  # isv gaps filled in a later pass


if __name__ == "__main__":
    sys.exit(main())
