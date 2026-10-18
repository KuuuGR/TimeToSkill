# Walidacja v10

Data: 2026-10-18. To nie jest zatwierdzenie produkcyjne.

## Walidator propozycji

`python3 scripts/catalog/validate_pilot_proposals.py data/skills-catalog/curated/pilot-proposals-v10.jsonl --repo /Users/admin/Developer/TimeToSkill`

- Wynik: exit 0.
- Błędy: 0.
- Ostrzeżenia: 0.
- Rekordy: 995.
- Każdy rekord ma status `pilot_proposal` i dokładnie trzy poziomy.
- Identyfikatory są unikalne.
- Emoji czyta się jako jeden znak. Żadne nie przekracza progu ośmiu użyć.

## Mapowania

- Decyzje: 1001 rekordów v9.
- Scalenia: 6. Każdy cel jest w v10. Żaden scalony identyfikator nie został w v10.
- v9 nadal ma 1001 rekordów i nie było edytowane.
- `git diff --check`: bez zastrzeżeń.

## Spójność rejestrów

- `pack-registry.json` wskazuje v10 i 995 rekordów. Następny pakiet to nadal `pack-16`.
- Luki w `gaps-registry.json` nie zmieniły statusu.
- Lista ryzyk: 101 wpisów, w tym 76 poza rejestrem i 25 w katalogu. Żaden nie jest oznaczony jako rozwiązany.

## Czego walidator nie sprawdza

Nie sprawdza, czy umiejętność jest merytorycznie prawdziwa, ani czy źródło zostało otwarte. Tego w tym przebiegu nie potwierdzono.
