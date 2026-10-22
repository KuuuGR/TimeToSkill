#!/usr/bin/env python3
"""Bulk-translate ExemplarySkills expansion rows into JSONL chunks via MyMemory.

Resumable. Writes data/skills-catalog/localization/out/<lang>-<chunk>.jsonl
matching source chunks. Categories come from category-glossary.json when present.

Usage:
  python3 scripts/catalog/translate_catalog_bulk.py --langs de,fr,it
  python3 scripts/catalog/translate_catalog_bulk.py --langs all --workers 1
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOC = ROOT / "data" / "skills-catalog" / "localization"
CHUNKS = LOC / "chunks"
OUT = LOC / "out"
PROGRESS = LOC / "progress"
FIELDS = (
    "title",
    "description",
    "category",
    "oneStarDescription",
    "twoStarDescription",
    "threeStarDescription",
)
SEP = " ◇ "

# MyMemory langpair targets (right side). Left is always en.
MYMEMORY_TARGET = {
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

DEFAULT_LANGS = tuple(
    code
    for code in MYMEMORY_TARGET
    if code not in {"pl", "es", "eo"}  # already assembled from prior work
)


def load_glossary() -> dict[str, dict[str, str]]:
    path = LOC / "category-glossary.json"
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def mymemory_translate(text: str, target: str, retries: int = 6) -> str:
    if not text.strip():
        return text
    q = urllib.parse.urlencode({"q": text, "langpair": f"en|{target}"})
    url = f"https://api.mymemory.translated.net/get?{q}"
    last_err: Exception | None = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Time4SkillCatalog/1.0"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            if data.get("quotaFinished"):
                raise RuntimeError("MyMemory quota finished")
            status = int(data.get("responseStatus") or 0)
            translated = (data.get("responseData") or {}).get("translatedText") or ""
            if status != 200 or not translated.strip():
                raise RuntimeError(f"bad response status={status} body={data!r}"[:300])
            # MyMemory sometimes echoes QUERY LENGTH LIMIT messages
            if "MYMEMORY WARNING" in translated.upper():
                raise RuntimeError(translated[:200])
            return translated
        except Exception as exc:  # noqa: BLE001 - resume-oriented network loop
            last_err = exc
            time.sleep(min(2 ** attempt, 30))
    raise RuntimeError(f"translate failed after retries: {last_err}")


def pack_fields(row: dict) -> str:
    return SEP.join(str(row.get(field, "") or "") for field in FIELDS if field != "category")


def unpack_fields(translated: str, expected: int) -> list[str]:
    parts = translated.split(SEP)
    if len(parts) == expected:
        return [p.strip() for p in parts]
    # Fallback: try alternate separators some MT engines invent
    for alt in ("◇", " | ", "||"):
        parts = [p.strip() for p in translated.split(alt) if p.strip() or True]
        # keep empties
        parts = translated.split(alt)
        if len(parts) == expected:
            return [p.strip() for p in parts]
    raise ValueError(f"separator mismatch: got {len(parts)} expected {expected}: {translated[:120]!r}")


def translate_row(row: dict, lang: str, glossary: dict[str, dict[str, str]]) -> dict:
    target = MYMEMORY_TARGET[lang]
    packed = pack_fields(row)
    translated = mymemory_translate(packed, target)
    values = unpack_fields(translated, expected=5)
    title, description, one, two, three = values
    cat_en = row["category"]
    category = glossary.get(cat_en, {}).get(lang) or mymemory_translate(cat_en, target)
    return {
        "id": row["id"],
        "title": title,
        "description": description,
        "category": category,
        "oneStarDescription": one,
        "twoStarDescription": two,
        "threeStarDescription": three,
    }


def chunk_out_path(lang: str, chunk_name: str) -> Path:
    # source-00.json -> de-00.jsonl
    idx = chunk_name.replace("source-", "").replace(".json", "")
    return OUT / f"{lang}-{idx}.jsonl"


def translate_chunk(lang: str, chunk_path: Path, glossary: dict, sleep_s: float) -> tuple[str, int]:
    out_path = chunk_out_path(lang, chunk_path.name)
    if out_path.exists() and out_path.stat().st_size > 0:
        existing = [json.loads(line) for line in out_path.read_text(encoding="utf-8").splitlines() if line.strip()]
        by_id = {row["id"]: row for row in existing}
    else:
        by_id = {}
    source_rows = json.loads(chunk_path.read_text(encoding="utf-8"))
    written = 0
    lines: list[str] = []
    for row in source_rows:
        if row["id"] in by_id and all(str(by_id[row["id"]].get(f, "")).strip() for f in FIELDS):
            lines.append(json.dumps(by_id[row["id"]], ensure_ascii=False))
            continue
        translated = translate_row(row, lang, glossary)
        lines.append(json.dumps(translated, ensure_ascii=False))
        written += 1
        time.sleep(sleep_s)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return out_path.name, written


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--langs", default="all", help="Comma list or 'all'")
    parser.add_argument("--sleep", type=float, default=0.35, help="Delay between MT calls")
    parser.add_argument("--workers", type=int, default=1, help="Parallel languages")
    parser.add_argument("--chunks", default="", help="Optional comma chunk indexes, e.g. 00,01")
    args = parser.parse_args()

    if args.langs.strip().lower() == "all":
        langs = list(DEFAULT_LANGS)
    else:
        langs = [part.strip() for part in args.langs.split(",") if part.strip()]
    for lang in langs:
        if lang not in MYMEMORY_TARGET:
            print(f"unknown lang {lang}", file=sys.stderr)
            return 2

    chunk_paths = sorted(CHUNKS.glob("source-*.json"))
    if args.chunks.strip():
        wanted = {f"{int(x):02d}" for x in args.chunks.split(",") if x.strip()}
        chunk_paths = [p for p in chunk_paths if p.stem.replace("source-", "") in wanted]

    glossary = load_glossary()
    OUT.mkdir(parents=True, exist_ok=True)
    PROGRESS.mkdir(parents=True, exist_ok=True)

    def run_lang(lang: str) -> dict:
        total_new = 0
        for chunk_path in chunk_paths:
            name, written = translate_chunk(lang, chunk_path, glossary, args.sleep)
            total_new += written
            status = {"lang": lang, "chunk": name, "written": written, "ts": time.time()}
            (PROGRESS / f"{lang}.json").write_text(json.dumps(status, ensure_ascii=False, indent=2), encoding="utf-8")
            print(json.dumps(status, ensure_ascii=False), flush=True)
        return {"lang": lang, "new_rows": total_new}

    results = []
    if args.workers <= 1:
        for lang in langs:
            results.append(run_lang(lang))
    else:
        with ThreadPoolExecutor(max_workers=args.workers) as pool:
            futs = {pool.submit(run_lang, lang): lang for lang in langs}
            for fut in as_completed(futs):
                results.append(fut.result())

    print(json.dumps({"done": results}, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
