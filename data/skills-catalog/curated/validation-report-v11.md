# Walidacja v11

Data: 2026-10-18. To nie jest zatwierdzenie produkcyjne. Stron zewnętrznych nie otwierano.

## Walidatory

`python3 scripts/catalog/validate_pilot_proposals.py data/skills-catalog/curated/pilot-proposals-v11.jsonl --repo /Users/admin/Developer/TimeToSkill`

- Exit 0. Błędy: 0. Ostrzeżenia: 0. Rekordy: 1122.
- Status każdej propozycji: `pilot_proposal`. Poziomy: dokładnie trzy. Identyfikatory unikalne.

`python3 scripts/catalog/validate_skill_catalog.py data/skills-catalog/pilots/final-broad-discovery/approved-skill-pilot-pack-16.jsonl --repo /Users/admin/Developer/TimeToSkill`

- Exit 0. Błędy: 0. Ostrzeżenia: 0. Sugestie: 0. Rekordy: 127.

`git diff --check`: bez zastrzeżeń.

## Integralność

- v11 zaczyna się bajtami v10. v9 i v10 nie były edytowane.
- Kandydatów pack-16: 500. Nowe propozycje: 127. Już reprezentowane: 342. Odrzucenia: 17. Bez źródła: 14.
- Mapowanie dwujęzycznego znaku wskazuje na `practice-expansion-13:read-a-bilingual-sign`, które jest w v10.
- Wpisy ryzyka: 122. Wcześniejsze 101 zostały. Dopisano 21. Żadnego nie oznaczono jako rozwiązany.
- Luki: 50. `needs_source_research`: 20. Wcześniejsze statusy bez zmian poza nową luką pack-16.
