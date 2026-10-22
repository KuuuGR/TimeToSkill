#!/usr/bin/env python3
"""Offline catalog translation via Argos CTranslate2 packages (no Stanza).

Writes JSONL chunks to data/skills-catalog/localization/out/<lang>-NN.jsonl
Resumable per chunk. Categories prefer category-glossary.json.

Usage:
  /tmp/t4s-argos/bin/python scripts/catalog/translate_catalog_argos.py --langs de,fr,it
  /tmp/t4s-argos/bin/python scripts/catalog/translate_catalog_argos.py --langs all
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import ctranslate2
from argostranslate.package import Package

ROOT = Path(__file__).resolve().parents[2]
LOC = ROOT / "data" / "skills-catalog" / "localization"
CHUNKS = LOC / "chunks"
OUT = LOC / "out"
PROGRESS = LOC / "progress"
PACKAGES = Path.home() / ".local" / "share" / "argos-translate" / "packages"

FIELDS = (
    "title",
    "description",
    "category",
    "oneStarDescription",
    "twoStarDescription",
    "threeStarDescription",
)

# overlay code -> Argos to_code / package discovery hint
LANG_TO_ARGOS = {
    "ar": "ar",
    "ca": "ca",
    "cs": "cs",
    "da": "da",
    "de": "de",
    "el": "el",
    "eo": "eo",
    "es": "es",
    "es-419": "es",
    "fi": "fi",
    "fr": "fr",
    "fr-CA": "fr",
    "he": "he",
    "hi": "hi",
    "hu": "hu",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "ko": "ko",
    "ms": "ms",
    "nb": "nb",
    "nl": "nl",
    "pl": "pl",
    "pt-BR": "pt",
    "pt-PT": "pt",
    "ro": "ro",
    "ru": "ru",
    "sk": "sk",
    "sv": "sv",
    "th": "th",
    "tr": "tr",
    "uk": "uk",
    "vi": "vi",
    "zh-Hans": "zh",
    "zh-Hant": "zh",  # same model; traditionalization can be a later pass
}

# Skip langs already complete from prior human assembly unless forced
SKIP_DEFAULT = {"pl", "es", "eo"}


class ArgosCT2:
    def __init__(self, to_code: str):
        pkg_path = self._find_package(to_code)
        if pkg_path is None:
            raise FileNotFoundError(f"no Argos package for en->{to_code}")
        self.pkg_path = pkg_path
        self.pkg = Package(pkg_path)
        self.translator = ctranslate2.Translator(str(pkg_path / "model"), device="cpu")
        self.tokenizer = self.pkg.tokenizer

    @staticmethod
    def _find_package(to_code: str) -> Path | None:
        if not PACKAGES.exists():
            return None
        candidates = []
        for path in PACKAGES.iterdir():
            name = path.name
            if name in {f"en_{to_code}", f"translate-en_{to_code}"} or name.startswith(
                f"translate-en_{to_code}-"
            ):
                if (path / "model").exists():
                    candidates.append(path)
        if not candidates:
            return None
        # Prefer versioned translate-en_* packages
        candidates.sort(key=lambda p: (0 if p.name.startswith("translate-en_") else 1, p.name))
        return candidates[0]

    def translate_many(self, texts: list[str], batch_size: int = 64) -> list[str]:
        outputs: list[str] = [""] * len(texts)
        pending_idx: list[int] = []
        pending_pieces: list[list[str]] = []
        for i, text in enumerate(texts):
            text = (text or "").strip()
            if not text:
                outputs[i] = text
                continue
            pending_idx.append(i)
            pending_pieces.append(self.tokenizer.encode(text))
        for start in range(0, len(pending_pieces), batch_size):
            batch = pending_pieces[start : start + batch_size]
            results = self.translator.translate_batch(batch, beam_size=2)
            for offset, result in enumerate(results):
                outputs[pending_idx[start + offset]] = self.tokenizer.decode(
                    result.hypotheses[0]
                ).strip()
        return outputs


def load_glossary() -> dict:
    path = LOC / "category-glossary.json"
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def chunk_out_path(lang: str, chunk_path: Path) -> Path:
    idx = chunk_path.stem.replace("source-", "")
    return OUT / f"{lang}-{idx}.jsonl"


def process_lang(lang: str, chunk_paths: list[Path], glossary: dict) -> dict:
    engine = ArgosCT2(LANG_TO_ARGOS[lang])
    new_rows = 0
    category_cache: dict[str, str] = {}
    for chunk_path in chunk_paths:
        out_path = chunk_out_path(lang, chunk_path)
        source_rows = json.loads(chunk_path.read_text(encoding="utf-8"))
        existing: dict[str, dict] = {}
        if out_path.exists():
            for line in out_path.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    row = json.loads(line)
                    existing[row["id"]] = row

        todo: list[dict] = []
        kept: dict[str, dict] = {}
        for row in source_rows:
            prev = existing.get(row["id"])
            if prev and all(str(prev.get(f, "")).strip() for f in FIELDS):
                kept[row["id"]] = prev
            else:
                todo.append(row)

        if todo:
            flat_texts: list[str] = []
            for row in todo:
                for field in FIELDS:
                    if field == "category":
                        gloss = glossary.get(row["category"], {}).get(lang)
                        if gloss and str(gloss).strip():
                            flat_texts.append("")  # placeholder; filled below
                        elif row["category"] in category_cache:
                            flat_texts.append("")
                        else:
                            flat_texts.append(row["category"])
                    else:
                        flat_texts.append(str(row.get(field, "") or ""))
            translated_flat = engine.translate_many(flat_texts)
            cursor = 0
            for row in todo:
                out = {"id": row["id"]}
                for field in FIELDS:
                    if field == "category":
                        gloss = glossary.get(row["category"], {}).get(lang)
                        if gloss and str(gloss).strip():
                            out[field] = str(gloss).strip()
                            cursor += 1
                        elif row["category"] in category_cache:
                            out[field] = category_cache[row["category"]]
                            cursor += 1
                        else:
                            value = translated_flat[cursor]
                            cursor += 1
                            category_cache[row["category"]] = value
                            out[field] = value
                    else:
                        out[field] = translated_flat[cursor]
                        cursor += 1
                kept[row["id"]] = out
                new_rows += 1

        lines = [json.dumps(kept[row["id"]], ensure_ascii=False) for row in source_rows]
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        status = {
            "lang": lang,
            "chunk": out_path.name,
            "new": new_rows,
            "rows": len(lines),
            "ts": time.time(),
        }
        PROGRESS.mkdir(parents=True, exist_ok=True)
        (PROGRESS / f"{lang}.json").write_text(json.dumps(status, ensure_ascii=False, indent=2), encoding="utf-8")
        print(json.dumps(status, ensure_ascii=False), flush=True)
    return {"lang": lang, "new_rows": new_rows, "package": str(engine.pkg_path)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--langs", default="all")
    parser.add_argument("--chunks", default="")
    parser.add_argument("--include-complete", action="store_true")
    args = parser.parse_args()

    if args.langs.strip().lower() == "all":
        langs = [code for code in LANG_TO_ARGOS if args.include_complete or code not in SKIP_DEFAULT]
    else:
        langs = [p.strip() for p in args.langs.split(",") if p.strip()]

    chunk_paths = sorted(CHUNKS.glob("source-*.json"))
    if args.chunks.strip():
        wanted = {f"{int(x):02d}" for x in args.chunks.split(",") if x.strip()}
        chunk_paths = [p for p in chunk_paths if p.stem.replace("source-", "") in wanted]

    glossary = load_glossary()
    OUT.mkdir(parents=True, exist_ok=True)
    results = []
    for lang in langs:
        if lang not in LANG_TO_ARGOS:
            print(f"skip unknown {lang}", file=sys.stderr)
            continue
        try:
            results.append(process_lang(lang, chunk_paths, glossary))
        except Exception as exc:  # noqa: BLE001
            print(json.dumps({"lang": lang, "error": str(exc)}), flush=True)
    print(json.dumps({"done": results}, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
