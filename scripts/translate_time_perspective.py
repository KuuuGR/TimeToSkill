#!/usr/bin/env python3
"""Batch-translate Time Perspective strings into all app locales."""

from __future__ import annotations

import json
import time
from pathlib import Path

from deep_translator import GoogleTranslator

ROOT = Path("/Users/admin/Developer/TimeToSkill")
EN_PATH = ROOT / "TimeToSkill/TimeToSkill/Resources/_tp_en.json"
CACHE_PATH = ROOT / ".venv-translate/tp_translations_cache.json"
OUT_PATH = ROOT / "TimeToSkill/TimeToSkill/Resources/TimePerspective.xcstrings"
CATALOG_PATH = OUT_PATH

# App locale -> Google Translate code
LOCALE_TO_GOOGLE = {
    "ar": "ar",
    "ca": "ca",
    "cs": "cs",
    "da": "da",
    "de": "de",
    "el": "el",
    "es": "es",
    "es-419": "es",
    "fi": "fi",
    "fr": "fr",
    "fr-CA": "fr",
    "he": "iw",
    "hi": "hi",
    "hr": "hr",
    "hu": "hu",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "ko": "ko",
    "ms": "ms",
    "nb": "no",
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
    "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW",
}

# English regional variants: start from EN, apply light spelling tweaks
EN_VARIANTS = ("en-AU", "en-CA", "en-GB", "en-IN")

CHROME_KEYS = (
    "time_perspective.card.empty_prompt",
    "time_perspective.card.empty_tagline",
    "time_perspective.card.title",
)


def en_variant(text: str, locale: str) -> str:
    if locale in ("en-GB", "en-AU", "en-IN"):
        return text.replace("kilometers", "kilometres").replace(" kilometer", " kilometre")
    return text


def load_cache() -> dict:
    if CACHE_PATH.exists():
        return json.loads(CACHE_PATH.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict) -> None:
    CACHE_PATH.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")


def translate_one(translator: GoogleTranslator, text: str, attempts: int = 8) -> str | None:
    last_exc: Exception | None = None
    for attempt in range(attempts):
        try:
            result = translator.translate(text)
            if result and str(result).strip():
                return str(result).strip()
            last_exc = RuntimeError("empty result")
        except Exception as exc:  # noqa: BLE001
            last_exc = exc
        time.sleep(1.5 * (attempt + 1))
    if last_exc:
        print(f"    one-key fail: {last_exc}", flush=True)
    return None


def translate_texts(translator: GoogleTranslator, texts: list[str]) -> list[str]:
    """Translate a list; fall back to per-item on batch failure."""
    if not texts:
        return []
    for attempt in range(4):
        try:
            results = translator.translate_batch(texts)
            if isinstance(results, list) and len(results) == len(texts):
                if all(r and str(r).strip() for r in results):
                    return [str(r).strip() for r in results]
            raise RuntimeError("batch returned incomplete results")
        except Exception as exc:  # noqa: BLE001
            print(f"  batch retry {attempt + 1}: {exc}", flush=True)
            time.sleep(2.0 * (attempt + 1))

    out: list[str] = []
    for text in texts:
        translated = translate_one(translator, text)
        if translated is None:
            # Proper-noun / short titles often fail; keep English as last resort.
            if len(text) <= 40 and "." not in text:
                print(f"  WARN keep-EN short: {text!r}", flush=True)
                translated = text
            else:
                # Final slow retry
                time.sleep(5)
                translated = translate_one(translator, text, attempts=5)
                if translated is None:
                    print(f"  WARN keep-EN long: {text[:60]!r}...", flush=True)
                    translated = text
        out.append(translated)
        time.sleep(0.2)
    return out


def translate_locale(locale: str, google_code: str, keys: list[str], en: dict, cache: dict) -> None:
    locale_cache = cache.setdefault(locale, {})
    pending_keys = [k for k in keys if k not in locale_cache or not locale_cache[k]]
    if not pending_keys:
        print(f"[skip] {locale}: already complete ({len(keys)})", flush=True)
        return

    # Reuse a completed sibling locale that shares the same Google target.
    for other, other_code in LOCALE_TO_GOOGLE.items():
        if other == locale or other_code != google_code:
            continue
        other_cache = cache.get(other) or {}
        if all(other_cache.get(k) for k in keys):
            print(f"[copy] {locale} <- {other} ({google_code})", flush=True)
            cache[locale] = {k: other_cache[k] for k in keys}
            save_cache(cache)
            return

    print(f"[translate] {locale} via {google_code}: {len(pending_keys)} pending", flush=True)
    translator = GoogleTranslator(source="en", target=google_code)
    batch_size = 12
    for i in range(0, len(pending_keys), batch_size):
        batch = pending_keys[i : i + batch_size]
        texts = [en[k] for k in batch]
        results = translate_texts(translator, texts)
        for k, translated in zip(batch, results):
            if not translated or not str(translated).strip():
                raise RuntimeError(f"Empty translation for {locale} {k}")
            locale_cache[k] = str(translated).strip()
        save_cache(cache)
        print(f"  {locale}: {min(i + batch_size, len(pending_keys))}/{len(pending_keys)}", flush=True)
        time.sleep(0.35)


def chrome_en_values(catalog: dict) -> dict[str, str]:
    out: dict[str, str] = {}
    for key in CHROME_KEYS:
        unit = (
            catalog.get("strings", {})
            .get(key, {})
            .get("localizations", {})
            .get("en", {})
            .get("stringUnit", {})
        )
        val = unit.get("value")
        if val:
            out[key] = val
    return out


def build_catalog(en: dict, cache: dict, chrome: dict[str, str]) -> dict:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    strings = catalog["strings"]

    locales = list(LOCALE_TO_GOOGLE) + list(EN_VARIANTS)
    all_keys = dict(en)
    all_keys.update(chrome)

    for key, en_value in all_keys.items():
        entry = strings.setdefault(key, {"extractionState": "manual", "localizations": {}})
        locs = entry.setdefault("localizations", {})
        locs["en"] = {"stringUnit": {"state": "translated", "value": en_value}}
        for locale in locales:
            if locale in EN_VARIANTS:
                value = en_variant(en_value, locale)
            else:
                value = cache[locale][key]
            locs[locale] = {"stringUnit": {"state": "translated", "value": value}}

    catalog["strings"] = dict(sorted(strings.items(), key=lambda kv: kv[0]))
    return catalog


def validate(catalog: dict, en: dict, chrome: dict[str, str]) -> None:
    locales = ["en", *LOCALE_TO_GOOGLE, *EN_VARIANTS]
    missing = []
    empty = []
    required = {**en, **chrome}
    for key in required:
        locs = catalog["strings"][key].get("localizations", {})
        for locale in locales:
            unit = locs.get(locale, {}).get("stringUnit", {})
            val = unit.get("value")
            if locale not in locs:
                missing.append((locale, key))
            elif not val or not str(val).strip():
                empty.append((locale, key))

    print("=== VALIDATION ===")
    print(f"perspective keys: {len(en)}")
    print(f"chrome keys: {len(chrome)}")
    print(f"locales expected: {len(locales)}")
    print(f"missing: {len(missing)}")
    print(f"empty: {len(empty)}")
    if missing[:10]:
        print("sample missing", missing[:10])
    if empty[:10]:
        print("sample empty", empty[:10])
    if missing or empty:
        raise SystemExit(1)
    print("OK")


def main() -> None:
    en = json.loads(EN_PATH.read_text(encoding="utf-8"))
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    chrome = chrome_en_values(catalog)
    keys = sorted(set(en) | set(chrome))
    cache = load_cache()

    for locale, google_code in LOCALE_TO_GOOGLE.items():
        translate_locale(locale, google_code, keys, {**en, **chrome}, cache)

    # English variants don't need MT
    for locale in EN_VARIANTS:
        locale_map = cache.setdefault(locale, {})
        for k in keys:
            src = chrome.get(k, en.get(k, ""))
            locale_map[k] = en_variant(src, locale)
    save_cache(cache)

    catalog = build_catalog(en, cache, chrome)
    OUT_PATH.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    validate(catalog, en, chrome)
    print(f"Wrote {OUT_PATH}")


if __name__ == "__main__":
    main()
