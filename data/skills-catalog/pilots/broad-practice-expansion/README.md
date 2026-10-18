# pack-12 — szeroka ekspansja

Kandydatury leżą w `review-inputs/pack-12-broad-practice-expansion/`. Ten katalog jest kopią roboczą recenzji.

500 rekordów dostało decyzję. 183 weszło do `curated/pilot-proposals-v6.jsonl` jako `pilot_proposal`. To nie jest katalog produkcyjny.

Podstawa każdej kandydatury to `editorial_synthesis`. Nie ma zewnętrznego URL i nie należy udawać, że poziomy pochodzą z cytowanej strony.

Walidacja z katalogu repozytorium:

```bash
python3 scripts/catalog/validate_pilot_proposals.py data/skills-catalog/curated/pilot-proposals-v6.jsonl
python3 scripts/catalog/validate_skill_catalog.py data/skills-catalog/pilots/broad-practice-expansion/approved-skill-pilot-pack-12.jsonl
```
