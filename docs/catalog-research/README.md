# Baza kandydatur katalogu 1001 Skills

Ten katalog zbiera materiał wejściowy do przyszłego katalogu **1001 Skills** w Time4Skill. Aplikacja ma pomagać odkrywać umiejętności i ćwiczyć je w praktyce. Docelowy katalog ma mieć co najmniej 1001 jakościowo różnych skillów. Każdy zatwierdzony skill będzie miał najwyżej trzy poziomy rozwoju, odpowiadające trzem gwiazdkom.

Ten etap nie wybiera listy 1001, nie opisuje poziomów, nie tworzy wyzwań i nie zmienia aplikacji.

## Skąd są dane

Rekordy pochodzą z publicznych eksportów, zapytań i stron wymienionych w `data/skills-catalog/research/sources.json`. Skrypt `scripts/catalog/build_catalog_research.py` pobiera je ponownie, normalizuje technicznie i zapisuje dane w `data/skills-catalog/research/`. Duże pliki źródłowe zostają w pamięci podręcznej `/tmp/t4s-catalog` i nie wchodzą do repozytorium. Układ katalogów opisuje `data/skills-catalog/README.md`.

Aktualna liczba surowych kandydatur: **15362**. Przed etapem T4S-CATALOG-002 było ich 15162, przed T4S-CATALOG-016 było ich 15264, a przed T4S-CATALOG-017 było ich 15317. Szczegóły, odrzucenia i luki są w `coverage-report.md`. Profil i raport triage z 2026-10-18 opisują stan przed dopisaniem rekordów pack-09 i pack-10. Tych rekordów nie włączono do ponownego generowania całego raportu.

## Czym jest surowa kandydatura

Surowa kandydatura to jedna pozycja tak, jak wystąpiła w źródle: z oryginalną nazwą, identyfikatorem i adresem, jeśli źródło je podało. Nie jest obietnicą, że trafi do katalogu. Znacznik `consumer_relevance` jest tylko mechaniczną etykietą z reguły opisanej przy źródle.

## Kandydatura, skill i wyzwanie

- **Kandydatura** to wiersz w `candidates-raw.jsonl`. Dwie kandydatury mogą być tą samą umiejętnością albo wcale nie być umiejętnością.
- **Osobny skill** będzie decyzją późniejszej redakcji. Ten etap jej nie podejmuje i niczego nie usuwa.
- **Pojedyncze wyzwanie** to konkretne ćwiczenie albo kryterium ukończenia. Takich rekordów tu nie ma.

## Stan, ograniczenia, następne kroki

Pula jest liczna, ponieważ filar umiejętności ESCO został zapisany w całości. Większość tych pojęć jest zawodowa. Osobne pliki nie zawierają poziomów, punktacji ani widoku katalogu. `duplicate-clusters.json` zawiera propozycje grup z etapu T4S-CATALOG-003. Rekordy nie zostały scalone ani usunięte.

Następne kroki to grupowanie duplikatów z zachowaniem pochodzenia, selekcja pod katalog konsumencki i dozbieranie dziedzin, które `coverage-report.md` wskazuje jako słabo trafione skanem tytułów.

## Ponowne uruchomienie

Z katalogu repozytorium:

```bash
python3 scripts/catalog/build_catalog_research.py
```

Skrypt wymaga Pythona 3 i sieci przy braku plików w `/tmp/t4s-catalog`. Po zakończeniu sprawdza składnię JSON i JSONL, unikalność `candidate_id` oraz to, że każdy `source_id` występuje w `sources.json`. Usunięcie pamięci podręcznej wymusza ponowne pobranie. Nie edytuj tysięcy wierszy ręcznie. `build_catalog_research.py` odtwarza tylko pierwszy etap i odmawia nadpisania, gdy plik zawiera rekordy dodane później. Etap T4S-CATALOG-002 dopisuje `python3 scripts/catalog/append_catalog_002.py`. `--check` przy tych skryptach tylko sprawdza ścieżki i kończy pracę przed zapisem.

## T4S-CATALOG-003

Raporty `catalog-profile.md`, `catalog-triage-report.md` i `triage-method.md` zostają w tym katalogu. Dane `catalog-profile.json`, `candidate-triage.jsonl` i `duplicate-clusters.json` są w `data/skills-catalog/research/`. Odtworzenie: `python3 scripts/catalog/build_catalog_003.py`. Ten etap nie zatwierdza skillów. Nie zmienia `candidates-raw.jsonl` ani `sources.json`.

## T4S-CATALOG-004

Pierwsza fala recenzji jest w `data/skills-catalog/review-batches/`. Schemat docelowego skilla: `approved-skill-schema.json`. Zasady emoji: `emoji-guidelines.md`. Odtworzenie: `python3 scripts/catalog/build_review_batches.py`. Ten etap nie zatwierdza skillów i nie zmienia bazy źródłowej. Pilotaże redakcyjne leżą w `data/skills-catalog/pilots/` i nie są produkcyjnym katalogiem.
