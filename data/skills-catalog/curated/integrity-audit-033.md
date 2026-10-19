# Audyt integralności 033

Data: 2026-10-19. Rejestr: `curated/pilot-proposals-v21.jsonl`.

- Rekordy: 2101
- Unikalne proposal_id: 2101
- Statusy: {'pilot_proposal': 2101}
- Ryzyka: 186
- Luki: 59
- Produkcyjne: 0
- Grupy identycznych nazw po normalizacji: 0

## Problemy techniczne

Łańcuch v10–v21 jest przedrostkiem bajtów: każda późniejsza wersja zaczyna się od poprzedniej. v21 zaczyna się od v20.

Dwie starsze pary nie są przedrostkiem i nie były ruszane:

- v5 nie zaczyna się od v4. v5 ma 123 linie i jest historyczną rewizją, nie uszkodzeniem v21.
- v10 nie zaczyna się od v9. v9 ma 1001 linii, v10 ma 995. To wcześniejsza rewizja, która nie była dopiskiem. Plików nie nadpisano.

Innych błędów technicznych w v21 nie znaleziono.

## Problemy redakcyjne
- Brak w automatycznym teście długości kryteriów.

## Duplikaty
- Grup identycznych nazw: 0. Rekordów nie usunięto.

## Źródła
- Źródła pack-25 i pack-26 są w sources.json.

## Do decyzji merytorycznej
- Ściana ściegów RSN i glosariusz origami nadal mają nazwy bez otwartej metody. Nie zamykać tych luk.
- 186 ryzyk zostaje otwartych. Żadnego nie oznaczono jako rozwiązane.
- Identyczne nazwy, jeśli są, zostają do ręcznej oceny. Automatycznego scalania nie było.

## Naprawy
- Nie zmieniano sensu istniejących propozycji.
- v21 jest v20 plus dwie nowe linie. Wcześniejsze pliki nie były nadpisywane.
- Walidator pilota: 0 błędów na 2101 rekordach.

## Nierozwiązane
- Kolejki bez metody: gap-pack-23, gap-pack-24, gap-pack-25 oraz couching.
- Semantyczne bliskie duplikaty poza identyczną nazwą nie były masowo przebudowywane.
