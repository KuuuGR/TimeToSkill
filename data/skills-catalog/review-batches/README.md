# Pierwsza fala pakietów recenzji

Data: 2026-10-18. Kandydatury w fali: **954**.
To nie jest katalog skillów. Każdy wiersz wskazuje rekord w `data/skills-catalog/research/candidates-raw.jsonl`. Triage jest heurystyką, nie oceną jakości.
Pakiet poniżej 100 rekordów nie był dociągany innymi dziedzinami. Tyle materiału ta fala uczciwie znalazła.

## Pakiety

| Plik | Dziedzina | Rekordy |
| --- | --- | ---: |
| `01-tworczosc-sztuka-rzemioslo-01.jsonl` | Twórczość, sztuka i rzemiosło | 116 |
| `02-tworczosc-sztuka-rzemioslo-02.jsonl` | Twórczość, sztuka i rzemiosło | 115 |
| `03-tworczosc-sztuka-rzemioslo-03.jsonl` | Twórczość, sztuka i rzemiosło | 115 |
| `04-praktyka-naprawa-samodzielnosc-01.jsonl` | Umiejętności praktyczne, naprawy i samodzielność | 51 |
| `05-ruch-sport-taniec-01.jsonl` | Ruch, koordynacja, sport i taniec | 106 |
| `06-przyroda-nawigacja-obserwacja-01.jsonl` | Przyroda, nawigacja, obserwacja i astronomia | 80 |
| `07-komunikacja-pisanie-spoleczne-01.jsonl` | Komunikacja, pisanie i umiejętności społeczne | 74 |
| `08-myslenie-pamiec-uczenie-01.jsonl` | Myślenie, pamięć i strategie uczenia się | 22 |
| `09-kuchnia-finanse-codziennosc-01.jsonl` | Kuchnia, finanse osobiste i życie codzienne | 43 |
| `10-technologia-nauka-nisze-01.jsonl` | Technologia, nauka i niszowe zainteresowania | 116 |
| `11-technologia-nauka-nisze-02.jsonl` | Technologia, nauka i niszowe zainteresowania | 116 |

## Dziedziny

- Twórczość, sztuka i rzemiosło: 346
- Umiejętności praktyczne, naprawy i samodzielność: 51
- Ruch, koordynacja, sport i taniec: 106
- Przyroda, nawigacja, obserwacja i astronomia: 80
- Komunikacja, pisanie i umiejętności społeczne: 74
- Myślenie, pamięć i strategie uczenia się: 22
- Kuchnia, finanse osobiste i życie codzienne: 43
- Technologia, nauka i niszowe zainteresowania: 232

## Źródła w fali

- `heritage-crafts-inventory`: 287
- `wikidata-hobbies`: 211
- `scouts-uk-activity-badges`: 164
- `esco-skills-v1.2.1`: 104
- `onet-content-model-31.0`: 77
- `astronomical-league-observing-programs`: 17
- `ausport-fundamental-movement`: 15
- `bbc-good-food-25-skills`: 14
- `wdsf-dancesport-disciplines`: 12
- `purdue-owl-writing`: 12
- `openlearn-full-catalogue`: 9
- `olympic-education-fundamentals-2023`: 6
- `learning-scientists-six-strategies`: 6
- `cfpb-building-blocks-2016`: 6
- `roc-what-is-orienteering`: 5
- `usgs-map-and-compass`: 5
- `zooniverse-project-directory`: 4

## Klasy triage w fali

Te liczby opisują skład pakietów, nie nową ocenę.

- `strong_candidate`: 357
- `adaptable_candidate`: 244
- `uncertain`: 257
- `occupational_or_abstract`: 24
- `not_a_distinct_skill`: 72

## Dobór

- Wzięto całe źródła praktyczne z etapu T4S-CATALOG-002, cały inwentarz rzemiosł i całą listę hobby Wikidanych.
- Odznaki Skautów weszły bez tekstu wymagań. Pominięto odznaki mundurowe, urodzinowe i blanket badge, bo nazwa nie opisuje praktyki.
- Takich pominiętych odznak jest 7.
- Z ESCO wzięto próbkę co najwyżej 100 tytułów pasujących do codziennej praktyki, najwyżej 18 na dziedzinę, 3 na jedną etykietę nadrzędną i 2 na ten sam pierwszy wyraz. Pominięto czasowniki organizacyjne i tytuły „types of”.
- Z O*NET wzięto umiejętności oznaczone wcześniej jako adaptowalne oraz krótką listę czynności pracy, które mogą podsunąć praktykę codzienną. Nie wzięto obsadzania stanowisk, administracji ani nadzoru.
- Nagłówki działów OpenLearn weszły jako przykłady tematów, nie skillów.
- Jeśli rekord z fali należy do grupy podobieństwa o co najwyżej sześciu członkach, sąsiednie identyfikatory dopisano do fali. Nie scalano ich i nie usuwano z bazy.

## Braki

- Myślenie, pamięć i uczenie się ma osobny, krótki pakiet. Poza sześcioma strategiami i kilkoma łamigłówkami baza nie ma szerszego materiału. Nie dociągano go systemami LMS ani kursami.
- Rozpoznawanie organizmów po wyglądzie i głosie: brak rekordów iNaturalist. W fali są tylko pośrednie tytuły, takie jak naturalist albo gardener.
- Oszustwa finansowe: brak osobnego rekordu w dostępnym materiale CFPB.
- Przyprawianie i organizacja stanowiska kuchennego: strona BBC nie dała na nie osobnych kandydatur.
- Większość dyscyplin sportowych nie weszła do bazy, bo lista olimpijska podawała same nazwy. W fali są opisane praktyki ruchu, nie komplet sportów.
- Odznaki Skautów nie mają wymagań, więc recenzent nie dostaje kryterium ukończenia.
- Próbka ESCO nie jest przeglądem 13 939 pojęć. Duże kategorie zawodowe celowo nie wypełniają pakietów.

## Jak oceniać

Dla każdej pozycji rozstrzygnąć jedną z możliwości: odrębna praktyka, praktyka po adaptacji, przykład albo wariant, temat, narzędzie, zawód, albo brak wystarczającego źródła. Podobne brzmienie nie scala pozycji. Ogólna technika może zostać osobnym skillem, jeśli ma własną drogę rozwoju.

Pole `related_unresolved_candidate_ids` jest tylko wskazówką z `duplicate-clusters.json`. Odrębność nie została rozstrzygnięta.

Gdy `description_sufficient` jest false, oceniać wyłącznie nazwę, kategorię i pochodzenie. Nie traktować pustki jako ukrytego opisu.

Z zatwierdzonych praktyk powstanie później rekord według `approved-skill-schema.json`. Ta fala go nie wypełnia. Emoji dobiera się według `emoji-guidelines.md`.

## Pola rekordu w pakiecie

- `batch_id`, `position` — miejsce w pliku.
- `candidate_id`, `source_id` — odnośniki do bazy głównej.
- `source_title` — oryginalna nazwa.
- `source_description` — oryginalny opis albo null.
- `description_sufficient`, `description_note` — czy opisu starcza do oceny.
- `source_url`, `source_category`, `candidate_type` — pola źródłowe.
- `triage_suitability`, `triage_confidence`, `triage_reason`, `human_review_required` — wynik heurystyki.
- `review_domain` — dziedzina pakietu.
- `selection_reason` — dlaczego rekord wszedł do tej fali.
- `related_unresolved_candidate_ids` — inne kandydatury z małych grup podobieństwa.
