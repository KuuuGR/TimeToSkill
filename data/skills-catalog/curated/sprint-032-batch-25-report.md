# Program 032, partia pack-25

Data: 2026-10-19. To nie jest 20000 kandydatów. Czasu sesji nie podaję.

## Licznik

- Unikalni przeanalizowani kandydaci programu: **648** (643 ze sprintu 031 oraz 5 nowych).
- Cel: 20000. Zostało 19352.
- Wiersze decyzji tej partii: 23. To nie jest 23 nowych kandydatów.
- Nowe propozycje pilotażowe: 6. Aktywne propozycje: 2099. Produkcyjne: 0.
- Już reprezentowane: 6 wierszy, w tym ścieg koca, jeden ścieg muchowy, satyna, liść prosty i złożony, trop sezonu, ryż.
- Odrzucone warianty: 9 (trzy nadzienia omleta i sześć portretów gatunków).
- Bez otwartej metody: 2 (gruby omlet, odrośle).
- Ściegi piórkowy, długi i krótki, nasionkowy oraz dziurki od guzika były już w 643. Ich strony metod otwarto teraz. Do licznika unikalnych nie weszły drugi raz.

## Domeny nowych propozycji

- Haft: 3 (piórkowy, długi i krótki, nasionkowy).
- Jedzenie: 1 (omlet składany, póki środek jest miękki).
- Czytanie drzew: 2 (układ pąków i stop, igły albo łuski).

## Źródła otwarte

Sześć stron, lista w `review-inputs/pack-25-methods-not-indexes/sources-opened.md`. Strona couching nie zwróciła treści i nie jest oznaczona jako otwarta.

## Walidacja

Uruchomione 2026-10-19 z katalogu TimeToSkill:

- `validate_pilot_proposals.py` na `pilot-proposals-v20.jsonl`: 0 błędów, 0 ostrzeżeń, 2099 rekordów.
- `validate_skill_catalog.py` na `approved-skill-pilot-pack-25.jsonl`: 0 błędów, 0 ostrzeżeń, 6 rekordów.
- v20 zaczyna się bajtami v19. v19 nie był nadpisywany.
- Ryzyka: 186, bez nowych wierszy.
- `git diff --check` na zmienionych plikach śledzonych: 0.

## Następny krok

Otworzyć jedną stronę metody, na przykład fishbone stitch albo scrambled eggs z BBC Good Food, porównać z v20 i dopiero wtedy pisać pack-26. Nie zbierać kolejnej ściany nazw. Nie zamykać luk ryzyka. Stan: `discovery-program-032-state.json`.
