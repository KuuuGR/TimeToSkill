# Profil bazy kandydatur

Data: 2026-10-18. Liczba rekordów: **15264**.
Liczebność źródła nie jest oceną przydatności. ESCO ma większość wierszy, ponieważ zaimportowano cały filar umiejętności.

## Według źródła

- `esco-skills-v1.2.1`: 13939
- `onet-content-model-31.0`: 545
- `heritage-crafts-inventory`: 287
- `wikidata-hobbies`: 211
- `scouts-uk-activity-badges`: 171
- `astronomical-league-observing-programs`: 17
- `ausport-fundamental-movement`: 15
- `bbc-good-food-25-skills`: 14
- `purdue-owl-writing`: 12
- `wdsf-dancesport-disciplines`: 12
- `openlearn-full-catalogue`: 9
- `learning-scientists-six-strategies`: 6
- `cfpb-building-blocks-2016`: 6
- `olympic-education-fundamentals-2023`: 6
- `usgs-map-and-compass`: 5
- `roc-what-is-orienteering`: 5
- `zooniverse-project-directory`: 4

## Według typu

- aktywność: 204
- hobby: 228
- obszar wiedzy: 3259
- pojęcie zawodowe: 341
- praktyczna czynność: 362
- skill: 10773
- węzeł taksonomii: 30
- zdolność: 67

## Według języka

- en: 15264

## Według kategorii źródłowej

Pole `source_category` jest wypełnione w każdym rekordzie, ale nie jest jedną taksonomią. W ESCO są to etykiety nadrzędne. Poniżej 15 najczęstszych wartości całego pola.

- Heritage Crafts craft inventory: 287
- hobby or subclass of hobby, excluding sports disciplines and types of art: 211
- installing wooden and metal components: 131
- food processing: 114
- mechanics and metal trades: 108
- law: 105
- medicine: 98
- management and administration: 98
- conducting academic or market research: 97
- planning events and programmes: 81
- providing medical, dental and nursing care: 81
- diagnosing health conditions: 79
- materials (glass, paper, plastic and wood): 78
- developing operational policies and procedures: 77
- directing operational activities: 76

## Pola niepełne

- Brak `source_description`: 891.
- Brak `source_category`: 0.
- Brak `source_url`: 0.
- Brak `source_title`: 0.
- `adaptation_hint` puste: 15264. To pole było puste celowo i nie jest brakiem importu.
- Mechaniczny `consumer_relevance`: high 749, medium 4418, low 10073, unclear 24. To nie jest triage.

## Powtórzenia

- Grupy o identycznej znormalizowanej nazwie: 66.
- Grupy o tym samym `source_item_id`: 0.

## Duże grupy zawodowe i abstrakcyjne

Poniższe liczniki biorą rekordy ESCO sklasyfikowane heurystycznie jako `occupational_or_abstract` i ich pierwszą etykietę nadrzędną. To nie jest lista skillów do usunięcia.

- installing wooden and metal components: 165
- software and applications development and analysis: 163
- food processing: 137
- planning events and programmes: 125
- database and network design and administration: 124
- law: 121
- medicine: 116
- directing operational activities: 114
- mechanics and metal trades: 114
- management and administration: 113

## Dziedziny: trafienia w tytule i część obiecująca

Skan tytułu jest leksykalny. Jedna pozycja może wejść do kilku dziedzin. Duża liczba trafień często pochodzi z ESCO i nie oznacza bogatego materiału konsumenckiego. Kolumna obiecujących liczy tylko `strong_candidate` i `adaptable_candidate`.

| Dziedzina | Trafienia w tytule | Z tego obiecujące |
| --- | ---: | ---: |
| Nawigacja i mapa | 13 | 6 |
| Astronomia | 5 | 4 |
| Przyroda i obserwacja | 64 | 1 |
| Nauka obywatelska | 2 | 2 |
| Gotowanie | 28 | 7 |
| Finanse osobiste | 100 | 5 |
| Pisanie | 13 | 2 |
| Taniec | 23 | 7 |
| Ruch i sport | 5 | 2 |
| Rzemiosło | 25 | 3 |
| Pamięć i uczenie się | 5 | 5 |
| Muzyka | 84 | 12 |

## Przykłady bliższe pytaniu aplikacji

- `c002:bbc-good-food-25-skills:how-to-master-basic-knife-skills` — How to master basic knife skills (bbc-good-food-25-skills, strong_candidate)
- `c002:usgs-map-and-compass:contours` — contours (usgs-map-and-compass, strong_candidate)
- `heritage-crafts:blacksmithing` — Blacksmithing (heritage-crafts-inventory, strong_candidate)
- `wikidata:Q11642` — pottery (wikidata-hobbies, strong_candidate)
- `esco:2e059433-c3a0-409a-a139-4b4e087ed366` — play the piano (esco-skills-v1.2.1, adaptable_candidate)

## Przykłady, które najpewniej nie są skillami katalogu

- `esco:0005c151-5b5a-4a66-8aac-60e734beb1ab` — manage musical staff (esco-skills-v1.2.1, occupational_or_abstract)
- `onet:1.A` — Abilities (onet-content-model-31.0, occupational_or_abstract)
- `openlearn-subject:digital-computing` — Digital & Computing (openlearn-full-catalogue, not_a_distinct_skill)
- `scouts-uk:beavers:activity-badges:40th-birthday-uniform-badge` — 40th Birthday Uniform Badge (scouts-uk-activity-badges, not_a_distinct_skill)
- `esco:49a806f0-62a4-4af0-a92e-0654528678a0` — types of cooktops (esco-skills-v1.2.1, not_a_distinct_skill)

Przykłady wybrano jako ilustrację reguł, nie jako zatwierdzoną listę.
