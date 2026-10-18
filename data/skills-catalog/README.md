# Dane katalogu 1001 Skills

Tu leżą maszynowe dane badań. Dokumenty dla człowieka są w `docs/catalog-research/`. Skrypty są w `scripts/catalog/`. Żaden z tych plików nie jest importowany do aplikacji iOS ani macOS.

Pilotaże są materiałem redakcyjnym. Nie są zatwierdzonym katalogiem produkcyjnym.

## Układ

| Katalog | Zawartość |
|---------|-----------|
| `research/` | Surowe kandydatury, normalizacja techniczna, triage, propozycje grup, rejestr źródeł |
| `review-batches/` | Pierwsza fala recenzji. Nadal kandydatury, nie skille |
| `review-inputs/movement-sport-dance/` | Pakiet przygotowany do recenzji zewnętrznej |
| `review-inputs/technology-science-niches/` | Kandydatury trzeciego pilotażu, 114 rekordów |
| `review-inputs/communication-cognition-nature/` | pack-04, 126 kandydatur do recenzji |
| `review-inputs/pack-05-music-sound-performance/` | pack-05, 146 kandydatur do recenzji |
| `review-inputs/pack-06-visual-arts-design/` | pack-06, 128 kandydatur do recenzji |
| `review-inputs/pack-07-craft-textiles-repair/` | pack-07, 128 kandydatur do recenzji |
| `review-inputs/pack-08-gardening-plant-cultivation-ecology/` | pack-08, 61 kandydatur do recenzji |
| `review-inputs/pack-09-first-aid-home-safety-preparedness/` | pack-09, 72 kandydatury do recenzji |
| `review-inputs/pack-10-pet-care-animal-welfare-training/` | pack-10, 60 kandydatur do recenzji |
| `pilots/kitchen-finance/` | Pilotaż kuchni i finansów |
| `pilots/movement-sport-dance/` | Pilotaż ruchu, sportu i tańca |
| `pilots/technology-science-niches/` | Trzeci pilotaż, kopia z `skills-pilot/` |
| `archives/` | ZIP pack-04, pack-05, pack-06, pack-07, pack-08, pack-09 i pack-10 |
| `curated/` | 1122 propozycji pilotażowych w v11, nie katalog produkcyjny |
| `pack-registry.json` | Status pakietów `pack-01`–`pack-10`. Czytelny indeks: `PACKS.md` |
| `gaps-registry.json` | Centralny indeks luk. Czytelny indeks: `GAPS.md`. Uzasadnienia zostają w raportach źródłowych |

Archiwa są w `archives/communication-cognition-nature-review.zip`, `archives/pack-04-communication-cognition-nature-review.zip`, `archives/pack-05-music-sound-performance.zip`, `archives/pack-06-visual-arts-design.zip`, `archives/pack-07-craft-textiles-repair.zip`, `archives/pack-08-gardening-plant-cultivation-ecology.zip`, `archives/pack-09-first-aid-home-safety-preparedness.zip` i `archives/pack-10-pet-care-animal-welfare-training.zip`. Kopia recenzencka pack-04 jest też w `skills-pilot/outgoing/`. Pakiet ruchu nie ma osobnego ZIP.

## Czego nie przepisywać automatycznie

Nie uruchamiaj generatorów po to, żeby „odświeżyć” te pliki. `candidates-raw.jsonl` i `candidates-normalized.jsonl` są bazą źródłową. `sources.json` jest rejestrem pochodzenia. `candidate-triage.jsonl`, `duplicate-clusters.json` i `catalog-profile.json` są wynikiem heurystyki, nie decyzją redakcyjną. Pliki JSONL pilotaży i pakietów recenzji zachowują `candidate_id` oraz `source_id`.

Skrypty generujące odmawiają części nadpisań i przyjmują `--check`, który kończy pracę przed zapisem:

```bash
python3 scripts/catalog/build_catalog_research.py --check
python3 scripts/catalog/append_catalog_002.py --check
python3 scripts/catalog/build_catalog_003.py --check
python3 scripts/catalog/build_review_batches.py --check
```

Zwykła walidacja nie pobiera źródeł z sieci:

```bash
python3 scripts/catalog/validate_skill_catalog.py data/skills-catalog/pilots/kitchen-finance/approved-skill-pilot-kitchen-finance.jsonl
python3 scripts/catalog/validate_skill_catalog.py data/skills-catalog/pilots/movement-sport-dance/approved-skill-pilot-movement-sport-dance.jsonl
python3 scripts/catalog/validate_pilot_proposals.py data/skills-catalog/curated/pilot-proposals.jsonl
```

## Cztery statusy, których nie wolno mieszać

1. Kandydatura surowa — wiersz w `research/candidates-raw.jsonl`. Normalizacja w `candidates-normalized.jsonl` jest tylko kluczem porównania, nie osobnym statusem.
2. Kandydatura przygotowana do recenzji — wiersz w `review-inputs/` albo `review-batches/`. Nadal nie jest skillem.
3. Propozycja pilotażowa — wiersz w `curated/pilot-proposals.jsonl` ze statusem `pilot_proposal`.
4. Skill zatwierdzony do produkcji — jeszcze nie istnieje. Żadna propozycja nie wchodzi do kodu aplikacji.

## Rejestr źródeł po pilotażu ruchu

18 października 2026 do `research/sources.json` dopisano 7 źródeł z `pilots/movement-sport-dance/additional-sources.json`: `red-cross-swim-safety`, `red-cross-water-safety`, `govuk-cycle-safety`, `nps-hiking-safety`, `iisa-skating-safety`, `pilates-foundation-faq`, `cross-country-ski-get-started`. Nie było kolizji identyfikatora, adresu ani tytułu z wcześniejszymi 24 źródłami. Każde ma `records_written` 0, bo nie powstały z nich nowe kandydatury. Plik `additional-sources.json` zostaje lokalnym śladem pilotażu. Rejestr centralny jest referencją.

## Status pakietów

Stan `pack-01`–`pack-10`, braki i następne działania są w `pack-registry.json`. Skrót dla człowieka jest w `PACKS.md`. Status luk jest w `gaps-registry.json`, a skrót w `GAPS.md`. Kolejny nowy zakres kandydatur to `pack-11`. Poprawka istniejącego pakietu zachowuje jego numer.

18 października 2026 dopisano 53 kandydatury pierwszej pomocy, a potem 45 kandydatur opieki nad zwierzętami. Baza surowa ma 15362 rekordy. Wcześniejsze wiersze nie zostały zmienione. Profil triage opisuje stan sprzed tych dopisków.

## Przyjmowanie pilotażu

Nowe paczki od redakcji zostawia się w `skills-pilot/` bez edycji. Zweryfikowana kopia trafia do `pilots/<slug>/`. Zasady są w `skills-pilot/README.md`. Kolejka: `review-queue.md`.

Trzeci pilotaż jest w `pilots/technology-science-niches/`. Ma 114 decyzji i 30 propozycji. Aktualna kopia przekazana przez użytkownika to `skills-pilot/skills-pilot-review-technology-science-niches 2/`; jest zgodna z wcześniejszym katalogiem bez ` 2` i z kopią roboczą poza notą w README. Pomocnicze `reference_id` nie weszły do `research/sources.json`.

## Wspólny rejestr propozycji

`curated/pilot-proposals.jsonl` ma 71 propozycji o statusie `pilot_proposal`: 11, 30 i 30. `curated/pilot-proposals-v2.jsonl` zachowuje te 71 rekordów. `curated/pilot-proposals-v3.jsonl` dokłada 35 propozycji z pack-04, razem 106, nadal `pilot_proposal`. Dziesięć grup w `curated/cross-pilot-review.json` ma decyzję zostawienia osobno. Porównanie z pack-04 jest w `curated/cross-pilot-review-v3.json` i nie scala rekordów. Szczegóły v2: `curated/pilot-proposals-v2-notes.md` i `curated/cross-pilot-quality-report.md`.

## Czwarta fala

`review-inputs/communication-cognition-nature/` ma 126 kandydatur. Recenzja jest w `pilots/communication-cognition-nature/`: 126 decyzji i 35 propozycji. To nie są skille produkcyjne. Paczka, którą dostała recenzja, zostaje w `archives/pack-04-communication-cognition-nature-review.zip`.

## Pakiet kandydatur technologii

`review-inputs/technology-science-niches/` ma 114 kandydatur z 232 rekordów dwóch pakietów technologii, nauki i nisz. Cel 120–160 nie został dociągnięty, bo reszta to ogólne czynności zawodowe, bliskie pozycje DigComp, kolekcjonowanie, rzemiosło albo sport. Nie dopisano nowych źródeł ani zmyślonych nazw. 15 opisów jest za krótkich i nie zostały uzupełnione. Luki: brak iNaturalist, brak osobnych projektów elektroniki poza odznaką i hobby electronics, programy obserwacyjne Astronomical League są w pakiecie przyrody, nie tutaj.

## Dokumentacja procesu

- metoda i raporty: `docs/catalog-research/`
- schemat zatwierdzonego skilla: `docs/catalog-research/approved-skill-schema.json`
- emoji: `docs/catalog-research/emoji-guidelines.md`
- walidator: `docs/catalog-research/catalog-validator.md`

## Nowy pakiet recenzji

1. Weź istniejące rekordy z `research/candidates-raw.jsonl` albo z pliku w `review-batches/`.
2. Skopiuj tylko potrzebne pola. Nie wymyślaj opisów i nie usuwaj `candidate_id`.
3. Zapisz pakiet w nowym katalogu `review-inputs/<nazwa>/` z listą kandydatur, indeksem źródeł i instrukcją.
4. Po recenzji złóż wynik w `pilots/<nazwa>/`: decyzje dla kandydatur osobno od propozycji skillów.
5. Nie dopisuj nowych `source_id` do `research/sources.json`, dopóki redakcja tego nie zatwierdzi. Dodatkowe źródła trzymaj obok pilotażu, tak jak `pilots/movement-sport-dance/additional-sources.json`.
6. Sprawdź `gaps-registry.json`. Nie twórz drugiego `gap_id` dla luki, którą nowy pakiet pokrywa. Status zmieniaj dopiero po sprawdzeniu wyniku. W tym samym zadaniu zaktualizuj `GAPS.md`, `pack-registry.json`, `PACKS.md` i `review-queue.md`.

Identyfikatory kandydatur i źródeł mają zostać takie, jakie są w bazie. Scalanie i odrzucanie zapisuje się jako decyzję, nie przez usuwanie wiersza z bazy.
