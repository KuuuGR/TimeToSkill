# Walidator katalogu skillów

Skrypt: `scripts/catalog/validate_skill_catalog.py`

Nie zmienia pliku wejściowego, nie scala rekordów i nie usuwa kandydatur. Działa na pilotażu i na przyszłej liście zatwierdzonych skillów.

## Uruchomienie

Z katalogu repozytorium:

```bash
python3 scripts/catalog/validate_skill_catalog.py data/skills-catalog/pilots/kitchen-finance/approved-skill-pilot-kitchen-finance.jsonl
```

Drugi i trzeci pilotaż:

```bash
python3 scripts/catalog/validate_skill_catalog.py data/skills-catalog/pilots/movement-sport-dance/approved-skill-pilot-movement-sport-dance.jsonl
python3 scripts/catalog/validate_skill_catalog.py data/skills-catalog/pilots/technology-science-niches/approved-skill-pilot-technology-science-niches.jsonl
python3 scripts/catalog/validate_skill_catalog.py data/skills-catalog/pilots/communication-cognition-nature/approved-skill-pilot-pack-04-communication-cognition-nature.jsonl
```

Wspólny rejestr propozycji ma inny schemat (`proposal_id`, status `pilot_proposal`) i idzie osobnym skryptem. Dozwolone `origin_pilot`: `kitchen-finance`, `movement-sport-dance`, `technology-science-niches`, `communication-cognition-nature`, `general-practical-skills`, `broad-practice-expansion`, `practice-expansion-13`, `practice-expansion-14`, `practice-expansion-15`, `practice-expansion-16`. Aktualny plik to `curated/pilot-proposals-v11.jsonl`.

```bash
python3 scripts/catalog/validate_pilot_proposals.py data/skills-catalog/curated/pilot-proposals-v11.jsonl
```

Baza kandydatur i rejestr źródeł są w `data/skills-catalog/research/`. Schemat zostaje w `docs/catalog-research/approved-skill-schema.json`.

Krótkie podsumowanie:

```bash
python3 scripts/catalog/validate_skill_catalog.py ŚCIEŻKA --summary
```

Inny korzeń repozytorium, gdy schemat i baza źródeł nie leżą obok skryptu:

```bash
python3 scripts/catalog/validate_skill_catalog.py ŚCIEŻKA --repo ŚCIEŻKA_REPO
```

Wejście może być JSONL (jeden obiekt w linii) albo JSON: tablica rekordów albo obiekt z listą pod kluczem `records`, `skills`, `items` albo `approved_skills`.

Kod wyjścia `0` oznacza brak błędów blokujących. Ostrzeżenia i sugestie nie zatrzymują procesu. Kod `1` oznacza błąd struktury, przez który danych nie należy użyć jako zatwierdzonego katalogu. Kod `2` oznacza, że pliku nie dało się odczytać.

## Błędy blokujące

- rekord nie jest obiektem;
- brak albo puste `skill_id`, `name`, `description`, `category`, `emoji`, `emoji_rationale`;
- powtórzony `skill_id`;
- `levels` nie ma dokładnie trzech obiektów;
- poziom nie ma niepustych pól `name`, `completion_criterion` i `can_do`;
- `safety_requirements` nie jest napisem ani `null`;
- `source_candidate_ids`, `source_ids` albo `tags` nie są tablicami napisów;
- `review_status` nie jest jedną z wartości `unreviewed`, `accepted`, `rejected`, `needs_source` z `approved-skill-schema.json`;
- `safety_notes`, jeśli jest, nie jest napisem ani `null`;
- pole `emoji` nie zawiera odczytywalnego symbolu albo zawiera zwykły tekst;
- gdy w repozytorium jest baza, `source_candidate_ids` nie wskazuje rekordu w `candidates-raw.jsonl` albo `source_ids` nie wskazuje `sources.json`.

Pusty szablon w `approved-skill-schema.json` ma wartości `null`. Walidator jest przeznaczony dla wypełnionych rekordów, nie dla tego szablonu. Pilotaż kuchenny używa tych samych pól co schemat i statusu `accepted`.

## Ostrzeżenia

Ostrzeżenie nie jest decyzją o scaleniu.

- puste `source_candidate_ids` albo `source_ids`;
- ta sama znormalizowana nazwa u więcej niż jednego skilla;
- ten sam `candidate_id` przy więcej niż jednym skillu;
- jedna kategoria obejmuje ponad połowę rekordów, gdy rekordów jest co najmniej 10;
- puste `safety_notes` albo `safety_requirements` zapisane jako pusty napis;
- w polu emoji widać więcej niż jeden ciąg symboli.

## Sugestie redakcyjne

- bardzo podobne nazwy po porównaniu tekstu (współczynnik sekwencji co najmniej 0,86 albo duży wspólny zestaw tokenów);
- krótkie albo mało konkretne `completion_criterion`.

Podobna nazwa nie jest duplikatem semantycznym. Raport tylko ustawia kolejkę dla człowieka.

## Emoji

Raport podaje liczbę skillów z odczytanym emoji, liczbę różnych symboli, częstotliwość każdego symbolu, udział pięciu najczęstszych oraz listę `skill_id`, gdy jeden symbol jest użyty co najmniej 8 razy albo, przy katalogu od 30 rekordów, obejmuje ponad 10 procent skillów.

Powtórzenie emoji nie jest błędem. Wytyczne w `emoji-guidelines.md` pozwalają na powtórzenia i nie wymagają 1001 unikalnych ikon.

Metoda nie wykonuje pełnej segmentacji emoji Unicode. Szuka punktów kodowych z ustalonej listy i łączy sąsiednie modyfikatory oraz joiner. Może rozdzielić sekwencję, której nie rozpoznaje, i może uznać symbol spoza aktualnej listy emoji. Ograniczenie jest wypisane w raporcie.

## Czego skrypt nie potwierdza

- czy opis jest merytorycznie prawdziwy;
- czy dwa skille są tym samym ćwiczeniem;
- czy emoji jest najlepszą ikoną dla praktyki;
- czy kandydatura powinna zostać zatwierdzona;
- czy deduplikacja bazy źródłowej jest rozstrzygnięta.

Przykładowy wynik pilotażu: `catalog-validation-report.md`.
