# Strefa przekazania pilotaży

Tutaj trafiają rozpakowane paczki redakcyjne. Nie jest to katalog zasobów aplikacji i nie przenosi się go do `assets/`.

## Jak przyjąć nowy pilotaż

1. Zostaw pliki w `skills-pilot/<nazwa-paczki>/` bez edycji. Nazwa może mieć przyrostek kopiowania macOS, na przykład ` 2`. Czytaj katalog wskazany przez użytkownika, nie wcześniejszą ścieżkę z instrukcji.
2. Sprawdź JSON i JSONL, unikalność `candidate_id`, trzy poziomy oraz istnienie kandydatur w `data/skills-catalog/research/candidates-raw.jsonl`.
3. Porównaj z `data/skills-catalog/pilots/<slug>/` i ze wspólnym rejestrem. Gdy treść jest nowa, skopiuj pakiet do `pilots/<slug>/`. Gdy jest ta sama, nie dopisuj drugiej kopii propozycji i nie nadpisuj nowszego README kopii roboczej. Katalogów przekazania nie usuwaj.
4. Dopisz propozycje do `data/skills-catalog/curated/pilot-proposals.jsonl` ze statusem `pilot_proposal` i `proposal_id` równym `<slug>:<skill_id>`. Ponowne dopisanie nie może dublować identyfikatorów.
5. `source_id` kandydatury zostaje. Pomocnicze `reference_id` z redakcji poziomów nie wchodzą do rejestru centralnego, dopóki nie zostaną osobno sprawdzone i nie będą cytowane jako źródło rekordu.

Paczki gotowe do wysłania na zewnątrz leżą w `skills-pilot/outgoing/`. To nie są paczki przychodzące od redakcji. Nie edytuje się ich jak przekazań użytkownika.

Recenzja pack-04 jest w `skills-pilot/skills-pilot-review-pack-04/`. Kopia robocza: `data/skills-catalog/pilots/communication-cognition-nature/`. JSON i JSONL są zgodne z przekazaniem. README kopii roboczej ma dopisaną notę. 35 propozycji weszło do `curated/pilot-proposals-v3.jsonl`.

Wcześniejsza kopia technologii: `skills-pilot/skills-pilot-review-technology-science-niches 2/`. W rejestrze pakietów jest to `pack-03`. Statusy wszystkich pakietów są w `data/skills-catalog/pack-registry.json`. Wcześniejszy katalog bez ` 2` ma te same pięć plików. Kopia robocza: `data/skills-catalog/pilots/technology-science-niches/`. Jej README ma dopisaną notę pochodzenia; JSON, JSONL i podsumowanie są zgodne z przekazaną kopią. Rejestr ma już te 30 propozycji.
