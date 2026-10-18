# pack-11 — recenzja redakcyjna

Kopia robocza recenzji pakietu `skills-pilot/pack-11-general-practical-skills-500/`. Katalog przekazania nie był edytowany. Kanoniczne pliki są tutaj, a nie w drugim katalogu `skills-pilot/pack-11-review/`.

## Statusy

- `accept_for_pilot` — propozycja pilotażu, nie akceptacja produkcyjna. W pliku propozycji `review_status` to `accepted` w znaczeniu tego pilotażu.
- `needs_revision` — praktyka jest zbyt szeroka albo opis miesza kontekst zawodowy z praktyką domową. Poziomów nie dopisano.
- `needs_source` — opis nie wystarcza, żeby powiedzieć, czego użytkownik ma się nauczyć.
- `defer` — podobieństwo do istniejącej propozycji albo nierozstrzygnięty zakres. Nic nie scalono.
- `reject` — obowiązek zawodowy, sprzęt branżowy, porada regulowana, cecha albo wariant nazwy.

Drugi przebieg jest w `review-decisions-pack-11-v2.jsonl`. Pierwszego pliku decyzji nie nadpisano.

## Walidacja

Z katalogu repozytorium:

```bash
python3 scripts/catalog/validate_skill_catalog.py data/skills-catalog/pilots/general-practical-skills/approved-skill-pilot-pack-11.jsonl
python3 scripts/catalog/validate_pilot_proposals.py data/skills-catalog/curated/pilot-proposals-v4.jsonl
```

Wejście ma mieć tyle decyzji, ile rekordów w `candidates.jsonl`.
