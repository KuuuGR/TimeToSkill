# Rewizja v2 rejestru propozycji

Data: 2026-10-18. Plik: `pilot-proposals-v2.jsonl`. To nadal 71 propozycji o statusie `pilot_proposal`, nie katalog produkcyjny.

Rejestr bazowy `pilot-proposals.jsonl` nie został nadpisany. Pilotaże źródłowe nie były zmieniane.

## Czego brakowało w pakiecie

Katalog `skills-pilot/curated-review-decisions/` nie był w repozytorium. Nie było plików `human-review-decisions.json` ani `proposed-catalog-edits.json`. Nie odtworzono ich z pamięci.

Rozstrzygnięcie „wszystkie wskazane pary i rodziny pozostają osobne” oraz trzy poprawki pól pochodzą z treści zadania. Nowe kryteria `running-and-pacing` nie zostały wpisane, bo ich tekst był tylko w brakującym pliku.

## Zastosowane poprawki

- `kitchen-finance:compare-financial-offers`: emoji `🏷️`. `emoji_rationale` zostaje przy wadze, bo zadanie kazało zachować pozostałe pola.
- `movement-sport-dance:breaking-foundations`: emoji `🌀`. Uzasadnienie nadal mówi o kuli dyskotekowej.
- `movement-sport-dance:latin-partner-dance-foundations`: nazwa `Latin ballroom dance foundations`. `proposal_id` bez zmiany.
- `movement-sport-dance:running-and-pacing`: trzy poziomy i `safety_requirements` (`null`) bez zmiany.

`proposal_id`, `source_candidate_ids`, `source_ids`, `origin_pilot` i `review_status` nie były ruszane.

## Wytyczne przed akceptacją produkcyjną

To nie są nowe fakty źródłowe i nie weszły do kryteriów.

- Każdy z dziesięciu skillów tanecznych ma mieć kryteria swojego stylu. Sama fraza, wariacja i wykonanie nie wystarczą jako jedyna różnica.
- Modelarstwo papierowe: konstrukcja z arkuszy. Modele w skali: proporcje i wierność wzorcowi. Modelarstwo inżynieryjne: mechanizm i funkcja. Modelowanie balonów: kształtowanie i łączenie balonów.
- Jazda na rowerze: codzienna jazda i bezpieczeństwo. Kolarstwo górskie: technika na odpowiednim szlaku.
- Bieg: regulacja wysiłku i tempa. Bieg terenowy: poruszanie się po zmiennej nawierzchni.
- Wędrówka: przygotowanie trasy i nawigacja, nie technika biegowa.

## Nadal bez źródeł w `source_ids`

Poziomy są konkretniejsze niż opis w Wikidanych, a strony redakcyjne są tylko jako `reference_id` w `pilots/technology-science-niches/additional-sources.json`:

- `technology-science-niches:sky-observation`
- `technology-science-niches:fishkeeping-basics`
- `technology-science-niches:wildlife-observation`
- `technology-science-niches:genealogy-research`
- `technology-science-niches:beginner-electronics-prototyping`
- `technology-science-niches:wikimedia-contribution`
- `technology-science-niches:growing-plants-from-seed`

`movement-sport-dance:running-and-pacing` opiera się tylko na `wikidata-hobbies`.
