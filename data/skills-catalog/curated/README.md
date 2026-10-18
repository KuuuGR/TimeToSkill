# Roboczy rejestr propozycji po czterech pilotażach

To nie jest katalog produkcyjny i nie wchodzi do aplikacji.

## Pliki

- `pilot-proposals.jsonl` — rejestr bazowy, 71 propozycji: 11 z kuchni i finansów, 30 z ruchu, 30 z technologii i nauki. Nie nadpisywać go po cichu.
- `pilot-proposals-v2.jsonl` — ta sama liczba i te same identyfikatory. Trzy jawne poprawki pól oraz noty w `pilot-proposals-v2-notes.md`. Nadal `pilot_proposal`. Nie nadpisywać.
- `pilot-proposals-v3.jsonl` — 71 rekordów v2 bez zmian i 35 propozycji z pack-04. Razem 106. Nadal `pilot_proposal`, nie katalog produkcyjny.
- `pilot-cross-overlap.json` — wcześniejszy przegląd tylko dwóch pierwszych pilotaży. Zostaje jako ślad tamtej analizy.
- `cross-pilot-review.json` — przegląd 71 propozycji. Nic nie scalono. Nie nadpisywać.
- `cross-pilot-review-v3.json` — porównanie 35 nowych propozycji z rejestrem v2. Nic nie scalono. Plik zostaje w stanie follow-upu: `recommended_not_final`.
- `pilot-proposals-v4.jsonl` — 106 rekordów v3 i 10 propozycji pack-11. Razem 116. Nie nadpisywać.
- `pilot-proposals-v5.jsonl` — 123 propozycje. Dwie poprawki poziomów w kopii v4 i 7 nowych propozycji. Nadal `pilot_proposal`.
- `cross-pilot-review-v5.json` — dziewięć grup pack-04 zostawionych osobno, `decision_taken` true. Bez scalenia i bez zgody produkcyjnej.
- `merge-history-v5.json` — mapa odrzuceń i jednej rodziny językowej. Nic nie usunięto.
- `selection-summary-v5.md` — liczby selekcji.
- `low-confidence-v5.json` — trzy propozycje do późniejszej recenzji.
- `pilot-proposals-v6.jsonl` — poprzednia rewizja, 306 propozycji. 123 rekordy v5 bez zmian i 183 z pack-12. Nadal `pilot_proposal`.
- `pilot-proposals-v7.jsonl` — poprzednia rewizja, 538 propozycji. 306 rekordów v6 bez zmian i 232 z pack-13. Nadal `pilot_proposal`.
- `pilot-proposals-v8.jsonl` — poprzednia rewizja, 742 propozycje. 538 rekordów v7 bez zmian i 204 z pack-14. Nadal `pilot_proposal`.
- `merge-history-v8.json` — mapowania pack-14. Nic nie usunięto.
- `selection-summary-v8.md` — liczby pack-14.
- `cross-pilot-review-v8.json` — porównanie pack-14 z v7. Bez scalenia.
- `pilot-proposals-v9.jsonl` — poprzednia rewizja, 1001 propozycji. 742 rekordy v8 bez zmian i 259 z pack-15. Nadal `pilot_proposal`.
- `merge-history-v9.json` — mapowania pack-15. Nic nie usunięto.
- `selection-summary-v9.md` — liczby pack-15.
- `cross-pilot-review-v9.json` — porównanie pack-15 z v8. Bez scalenia.
- `pilot-proposals-v10.jsonl` — poprzednia rewizja, 995 propozycji. Przegląd jakości v9: poprawki i mapowania, bez statusu produkcyjnego.
- `pilot-proposals-v11.jsonl` — aktualna rewizja, 1122 propozycji. 995 rekordów v10 bez zmian i 127 z pack-16. Nadal `pilot_proposal`.
- `merge-history-v11.json` — mapowania pack-16. v10 nie było edytowane.
- `selection-summary-v11.md` — liczby pack-16.
- `coverage-report-v11.md` — które dziedziny poszerzono.
- `validation-report-v11.md` — wynik walidatora pack-16.
- `editorial-decisions-v10.jsonl` — decyzja dla każdej propozycji v9.
- `merge-history-v10.json` — mapowania scaleń. v9 nie było edytowane.
- `quality-report-v10.md` — raport jakości.
- `validation-report-v10.md` — wynik walidatora.
- `unresolved-risks-for-review.jsonl` — zbiorcza lista nierozstrzygniętych ryzyk.
- `source-gaps-non-safety-v10.md` — wyciąg luk źródłowych, które nie dotyczą bezpieczeństwa.
- `merge-history-v6.json` — mapowania odrzuceń pack-12. Nic nie usunięto.
- `merge-history-v7.json` — mapowania pack-13. Nic nie usunięto.
- `selection-summary-v7.md` — liczby pack-13.
- `cross-pilot-review-v7.json` — porównanie pack-13 z v6. Bez scalenia.
- `selection-summary-v6.md` — liczby ekspansji.
- `cross-pilot-quality-report.md` — uwagi do poziomów i emoji.
- `curated-catalog-schema.json` — opis pól.

Każdy rekord ma `proposal_id` w postaci `pilot:skill_id`, `origin_pilot`, `pilot_skill_id` i `pilot_review_status`. W pilotażach status brzmiał `accepted`. Tutaj `review_status` to `pilot_proposal`, żeby nie czytać go jako zgody na wydanie.

Pola poziomów, tagi i uwagi bezpieczeństwa wczesnych rewizji przeniesiono bez dopisywania treści. Od v6 dopisano redakcyjne `source_id` i wiersze kandydatur. Nie są one cytatem ze strony zewnętrznej.

## Powtórzenia

Przegląd trzech wcześniejszych pilotaży zostaje w `cross-pilot-review.json`. Nie ma identycznych nazw ani wspólnych `candidate_id`. Do człowieka: rodzina tańca, bieg i bieg terenowy, wędrówka i bieg terenowy, rower i rower terenowy, emoji 🪩. Pary łączone tylko klasyfikacją ESCO oraz emoji ⚖️ rekomendowano zostawić osobno.

Porównanie pack-04 z tymi 71 propozycjami jest w `cross-pilot-review-v3.json`. Nie scalono wyjaśniania z komunikacją naukową, oceny dowodów z researchem cyfrowym, mapy, kompasu i mapy cyfrowej, mówienia z innymi praktykami komunikacji ani rozmowy, tłumaczenia ustnego i pisemnego.

Starszy plik `pilot-cross-overlap.json` opisuje tylko pierwsze dwa pilotaże i nie został przepisany.

## Walidacja

Osobny skrypt, bo ten format ma `proposal_id` i status `pilot_proposal`, a walidator pilotaży sprawdza `skill_id` oraz statusy `accepted` / `unreviewed` / `rejected` / `needs_source`. Tamtego walidatora nie rozszerzano.

```bash
python3 scripts/catalog/validate_pilot_proposals.py data/skills-catalog/curated/pilot-proposals.jsonl
```

Walidator sprawdza strukturę, trzy poziomy, powiązania z bazą i rozkład emoji. Trzy poziomy i emoji nie są oceną jakości.

## Dalsza praca

Dziewięć grup pack-04 jest rozstrzygniętych w `cross-pilot-review-v5.json`. Otwarte zostają luki pack-02 oraz trzy naprawy pack-11 bez bezpiecznej metody. Do osobnego zatwierdzenia produkcyjnego nie importować v5 do kodu aplikacji i nie usuwać pilotaży.
