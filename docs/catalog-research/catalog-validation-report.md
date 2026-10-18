# Raport walidacji pilotażu kuchennego

Uruchomienie 2026-10-18:

```bash
python3 scripts/catalog/validate_skill_catalog.py data/skills-catalog/pilots/kitchen-finance/approved-skill-pilot-kitchen-finance.jsonl
```

Kod wyjścia: `0`. Plik pilotażu nie był zmieniany.

## Wynik

- rekordy: 11
- błędy blokujące: 0
- ostrzeżenia: 1
- sugestie: 0

Wszystkie `source_candidate_ids` są w `candidates-raw.jsonl`. Wszystkie `source_ids` są w `sources.json`. Każdy rekord ma `review_status` `accepted` i dokładnie trzy poziomy.

## Ostrzeżenie

Kategoria `Cooking and food preparation` obejmuje 8 z 11 rekordów (73%). Pozostałe 3 są w `Personal finance and everyday life`. To jest sygnał koncentracji w tym małym pilotażu, nie powód do usuwania skillów.

## Emoji

- skille z odczytanym emoji: 11 z 11
- różne emoji: 11
- pięć najczęstszych symboli: 5 z 11 użyć (45,5%), bo każdy symbol występuje raz
- żaden symbol nie przekracza progu częstej ikony

Częstotliwość: 🔪 🍚 🥣 🍳 🫙 🍲 🥚 🧼 🧾 ⚖️ 🏦 — każdy po 1.

Powtórzenie nie zostałoby oznaczone jako błąd. Metoda liczy ciągi punktów kodowych z ustalonej listy i nie wykonuje pełnej segmentacji emoji Unicode.

## Różnica względem szablonu

`approved-skill-schema.json` jest pustym szablonem: pola przykładowe mają wartość `null`, a `source_candidate_ids`, `source_ids` i `tags` są pustymi tablicami. Pilotaż wypełnia te pola. Struktura pól jest zgodna. Pilotaż nie był przepisywany.

## Pilotaż ruchu, sportu i tańca

Uruchomienie na `data/skills-catalog/pilots/movement-sport-dance/approved-skill-pilot-movement-sport-dance.jsonl`.

Kod wyjścia: `1`. Rekordy: 30. Błędów blokujących: 9. Ostrzeżeń: 0.

Emoji: 30 skillów z symbolem, 29 różnych symboli, pięć najczęstszych to 6 z 30 użyć (20,0%).

Dziewięć błędów to `source_id` zapisane w `additional-sources.json` i celowo nie dopisane do `data/skills-catalog/research/sources.json`: `red-cross-swim-safety`, `govuk-cycle-safety`, `nps-hiking-safety`, `cross-country-ski-get-started`, `iisa-skating-safety`, `red-cross-water-safety`, `pilates-foundation-faq`. Walidator nie został zmieniony tak, aby je ukryć, a rejestr źródeł nie był uzupełniany.

## Uzupełnienie rejestru, 2026-10-18

Te siedem identyfikatorów dopisano później do `data/skills-catalog/research/sources.json` z `records_written` 0. Ponowne uruchomienie walidatora pilotażu ruchu dało kod `0`, 30 rekordów, 0 błędów. Pilotaż kuchni nadal ma kod `0` i jedno ostrzeżenie koncentracji kategorii. Wspólny rejestr `curated/pilot-proposals.jsonl` (41 rekordów) przeszedł `validate_pilot_proposals.py` z kodem `0`.

## Trzy pilotaże i rejestr 71, 2026-10-18

Po włączeniu `pilots/technology-science-niches/` walidator pilotaży zwrócił kod `0` dla kuchni (11 rekordów, 1 ostrzeżenie kategorii), ruchu (30, 0 błędów) i technologii (30, 0 błędów). `validate_pilot_proposals.py` na `curated/pilot-proposals.jsonl` zwrócił kod `0` dla 71 unikalnych propozycji i 69 emoji. Powtórzone symbole to ⚖️ i 🪩, po dwa razy. Surowe pliki `candidates-raw.jsonl`, `candidates-normalized.jsonl` i `candidate-triage.jsonl` mają te same skróty SHA-256 co przed tą integracją. Pakiet wejściowy w `skills-pilot/` nie był edytowany.
