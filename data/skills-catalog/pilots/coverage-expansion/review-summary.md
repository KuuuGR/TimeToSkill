# Selekcja v7

To nie jest katalog produkcyjny. v1–v6 nie zostały nadpisane. Rekordów źródłowych nie usunięto. Dopisano 500 wierszy na końcu `candidates-raw.jsonl`.

## Liczby

- Kandydatury surowe: 500.
- Kandydatury po odłożeniu duplikatów (`already_represented`): 330.
- Nowe propozycje pilotażowe: 232.
- Już reprezentowane: 170.
- Odrzucenia: 79.
- Pozycje bez źródła: 19.
- Pozycje wysokiego ryzyka zostawione do recenzji: 19. Wszystkie mają status `needs_source`. Procedur nie napisano.
- Odłożone do człowieka poza tym zbiorem: 0.
- Mapowania tej samej umiejętności: 170. Scalenia istniejących propozycji: 0.
- Unikalne propozycje pilotażowe po v7: 538.
- Propozycje produkcyjne: 0.
- Dystans do 1001: 463 propozycji pilotażowych. Katalog produkcyjny nadal ma 0 skilli.

## Pokrycie

v6 jest gęste w gotowaniu, domu, komunikacji, organizacji, nawigacji i grach. Pack-13 poszedł w dostęp i prosty język, kulturę miejsca, praktyczną naukę, pracę z informacją, myślenie w grupie, występ, ręczne wykonanie, słuchanie, towarzyszenie, życie obywatelskie, światło i przestrzeń oraz widoczną naprawę.

## Podstawa

Wszystkie 500 kandydatur ma podstawę `editorial_synthesis`, poza pozycjami `needs_source`, które mają `source_needed`. Źródło `t4s-editorial-synthesis-pack-13` nie jest stroną zewnętrzną i nie wolno go cytować jako autorytetu. Stron nie otwierano dla tego pakietu.

## Walidacja

Porównaj v7 z v6 bajt po bajcie na początku pliku. Uruchom walidator propozycji na v7 i walidator skilli na `approved-skill-pilot-pack-13.jsonl`. Sprawdź `git diff --check`. Nie importuj propozycji do aplikacji.
