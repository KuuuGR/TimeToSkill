# Technologia, nauka i niszowe zainteresowania — pakiet do recenzji

Wersja pakietu: 1. Data: 2026-10-18. Kandydatury: **114** z 232 rekordów w `review-batches/10-technologia-nauka-nisze-01.jsonl` i `11-technologia-nauka-nisze-02.jsonl`.

To kandydatury do oceny, nie zatwierdzone skille. Nie dopisano nazw ani opisów. Opisy są zgodne z `research/candidates-raw.jsonl`. 15 rekordów ma `description_sufficient` false; opisu nie uzupełniono.

## Dlaczego nie 120

Dolna granica 120–160 nie została sztucznie osiągnięta. Pominięto 118 rekordów tych dwóch plików: ogólne czynności zawodowe O*NET, bliskie sobie pozycje ramowe DigComp, etykiety kolekcjonowania, rzemiosło i sport oraz odznaki o tytułach Hobbies i Collector. Zostały w bazie i w pakietach fali.

## Luki

- Rozpoznawanie organizmów: w tych pakietach nie ma rekordów iNaturalist.
- Elektronika: są odznaka, pozycja ESCO „electronics” i hobby electronics. Nie ma osobnego źródła projektów elektronicznych.
- Programy obserwacyjne Astronomical League leżą w pakiecie przyrody, nie w tym.
- 15 opisów jest zbyt krótkich, żeby na ich podstawie pisać poziomy.

## Pliki

- `candidates.jsonl` — 114 rekordów z oryginalnym `candidate_id`, `source_id`, tytułem, opisem, URL i triage.
- `source-index.json` — skrót czterech źródeł skopiowany z rejestru centralnego.
- `manifest.json` — liczby, data, wersja i leksykograficzny zakres `candidate_id`.
- `review-instructions.md` — zasady recenzji.

Identyfikatory nie tworzą ciągu liczbowego. Zakres w manifeście to pierwszy i ostatni identyfikator po sortowaniu tekstowym.
