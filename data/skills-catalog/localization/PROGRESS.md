# Catalog localization progress — complete

## Result (2026-10-21)
- English base skills: **2146**
- Full overlays (title + description + category + star fields where EN has them): **37 locales**
- Intentional EN-base only: `en-AU`, `en-CA`, `en-GB`, `en-IN` (seeder returns `nil`)

## Locales with full `ExemplarySkills_<code>.json`
ar, ca, cs, da, de, el, eo, es, es-419, fi, fr, fr-CA, he, hi, hr, hu, id, isv, it, ja, ko, ms, nb, nl, pl, pt-BR, pt-PT, ro, ru, sk, sv, th, tr, uk, vi, zh-Hans, zh-Hant

## Notes
- Bulk fill via offline Argos CT2 (`scripts/catalog/translate_catalog_argos.py`); `pl`/`es`/`eo` were prior human/assembled baselines
- `isv`: Czech-pivoted Interslavic Latin draft (`draft_isv_from_cs.py`) for script transliteration
- `hr`: Slovak-pivoted draft; 5 empty legacy descriptions backfilled from SK
- `es-419` / `fr-CA` / `zh-Hant`: cloned from `es` / `fr` / `zh-Hans` (regional editorial pass still optional)
- Overlay loader fixed for `zh-Hans`/`zh-Hant`/`pt-BR`/`pt-PT`/`isv` (`SkillSeeder.catalogOverlayCode`)

## Validate
```bash
python3 scripts/catalog/validate_catalog_l10n.py
```
