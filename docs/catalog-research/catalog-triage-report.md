# Raport triage kandydatur

Data: 2026-10-18. Sklasyfikowano 15264 z 15264 rekordów. Niesklasyfikowanych: 0.
To propozycja heurystyczna. Nie zatwierdza finalnych skillów i nie usuwa rekordów.

## Liczby klasyfikacji

- `strong_candidate`: 357
- `adaptable_candidate`: 248
- `occupational_or_abstract`: 11369
- `not_a_distinct_skill`: 232
- `uncertain`: 3058

Pewność: high 1159, medium 7210, low 6895.
Kandydatury z `human_review_required`: 14105.
W tej liczbie priorytetem następnego czytania są 3663 rekordów obiecujących albo niepewnych. Reszta flagi dotyczy głównie pojęć zawodowych o pewności niskiej lub średniej. Nie trzeba ich czytać pojedynczo przed próbką.

## Obiecujący materiał według źródła

Suma `strong_candidate` i `adaptable_candidate`. Liczba nie jest oceną jakości ani liczbą unikalnych skillów.

| Źródło | Obiecujące | strong | adaptable | occupational | not a skill | uncertain |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `heritage-crafts-inventory` | 252 | 252 | 0 | 0 | 35 | 0 |
| `wikidata-hobbies` | 161 | 38 | 123 | 0 | 28 | 22 |
| `onet-content-model-31.0` | 76 | 0 | 76 | 469 | 0 | 0 |
| `astronomical-league-observing-programs` | 17 | 0 | 17 | 0 | 0 | 0 |
| `ausport-fundamental-movement` | 15 | 14 | 1 | 0 | 0 | 0 |
| `esco-skills-v1.2.1` | 14 | 0 | 14 | 10900 | 157 | 2868 |
| `bbc-good-food-25-skills` | 14 | 14 | 0 | 0 | 0 | 0 |
| `purdue-owl-writing` | 12 | 12 | 0 | 0 | 0 | 0 |
| `wdsf-dancesport-disciplines` | 12 | 8 | 4 | 0 | 0 | 0 |
| `learning-scientists-six-strategies` | 6 | 0 | 6 | 0 | 0 | 0 |
| `cfpb-building-blocks-2016` | 6 | 6 | 0 | 0 | 0 | 0 |
| `olympic-education-fundamentals-2023` | 6 | 4 | 2 | 0 | 0 | 0 |
| `usgs-map-and-compass` | 5 | 4 | 1 | 0 | 0 | 0 |
| `roc-what-is-orienteering` | 5 | 5 | 0 | 0 | 0 | 0 |
| `zooniverse-project-directory` | 4 | 0 | 4 | 0 | 0 | 0 |

Źródła spoza tabeli, w tym odznaki Skautów i nagłówki OpenLearn, mają zero rekordów obiecujących: odznaki są `uncertain`, nagłówki są `not_a_distinct_skill`.
Najwięcej obiecujących rekordów dają inwentarz rzemiosł i Wikidata, potem nieduże źródła praktyczne z etapu T4S-CATALOG-002. ESCO prawie nie wchodzi do tej sumy, mimo że ma 13939 rekordów. To jest skutek reguły, nie dowód, że w ESCO nie ma praktyk. Wąski wzorzec tytułu złapał tylko dopasowania w rodzaju gry na instrumencie, tańca albo pływania.

## Grupy podobieństw

- Grupy identycznych nazw: 66.
- Grupy tego samego identyfikatora źródłowego: 0.
- Grupy rdzenia po nawiasie: 10.
- Grupy identycznego opisu: 7.
- Pary leksykalne, z których powstały składowe: 24. Porównań w blokach: 21929.
- Rekordy pominięte w porównaniu leksykalnym, bo nie miały rzadkiego tokenu: 0.
- Wszystkie grupy w `duplicate-clusters.json`: 107.
- Grupy o pewności high: 41. Grupy wymagające człowieka: 107.
- Typy grup: identical_normalized_title 66, identical_source_description 7, lexical_near_title 24, parenthetical_or_punctuation_variant 10.
- Porównania synonimów nie wykonano. Porównania semantycznego nie wykonano.
- Przykład, że bliski tytuł nie jest duplikatem: `interpret 2D plans` i `interpret 3D plans` oraz pary z „hazardous” i „non-hazardous”. Zostały w grupie leksykalnej o niskiej pewności i wymagają człowieka. Nie scalono ich.

Rekordy, grupy i umiejętności to trzy różne liczby.

- Rekordy obiecujące (`strong_candidate` + `adaptable_candidate`): 605.
- Dodatkowe kopie w grupach identycznej nazwy o pewności high, ograniczone do rekordów obiecujących: 0.
- Niezweryfikowany szacunek różnych obiecujących pozycji po odjęciu tych kopii: 605.
Tego szacunku nie traktować jako liczby skillów. Nie odejmuje grup leksykalnych, rodzin tańca ani wariantów rzemiosła o niższej pewności. Nie sprawdza, czy dwie różne nazwy są jedną praktyką.

## Co analizować najpierw

1. Rzemiosła Heritage Crafts oznaczone jako `strong_candidate`: czy nazwa naprawdę niesie trzy poziomy, czy jest zbyt wąskim wyrobem.
2. Warianty w nawiasie: czy zostawić je poza katalogiem jako uszczegółowienie.
3. Praktyki z etapu T4S-CATALOG-002: mapa, gotowanie, ruch, taniec, pisanie, finanse. To najbliższe gotowe opisy.
4. Wikidata z opisem praktyki: oddzielić sport, rzemiosło i zbyt wąskie hobby.
5. Rodziny tańca WDSF i programy Astronomical League: przepisać nazwę programu na czynność albo zostawić jako materiał, nie skill.
6. Identyczne tytuły odznak Skautów w kilku sekcjach wiekowych. Same odznaki zostają `uncertain`, dopóki nie ma wymagań.
7. Krótka lista ESCO z wzorcem praktyki osobistej (`play the piano`, taniec, pływanie, szycie ręczne).
8. Próbka `uncertain` wśród umiejętności międzysektorowych ESCO, najpierw pisanie, naprawa i gotowanie domowe, nie zarządzanie.
9. Umiejętności przenośne O*NET: które da się przepisać bez języka stanowiska pracy.
10. Nakładki już opisane w raporcie pokrycia: mapa USGS i orientacja, breaking, uderzanie i łapanie.

## Ograniczenia

- Reguły nie czytały opisów ESCO i O*NET poza polami `skillType`, `reuseLevel` i typem rekordu.
- Wysoka liczba `occupational_or_abstract` wynika głównie z tych pól, nie z recenzji każdej nazwy.
- `strong_candidate` przy rzemiośle opiera się na nazwie z inwentarza. Artykułów nie było w rekordzie.
- Heurystyka może uznać wąskie rzemiosło za obiecujące i pominąć praktykę ESCO, której tytuł nie trafił we wzorzec.
- Grupy podobieństw są propozycjami. Żadnej nie scalono.

## Następny etap do shortlisty 1001

Nie promować hurtowo pojęć zawodowych, żeby dobić liczbę. Najpierw człowiek przegląda `strong_candidate` i `adaptable_candidate`, korzystając z grup identycznych nazw i wariantów w nawiasie. Z grupy bierze jedną praktykę i zostawia pozostałe identyfikatory w pochodzeniu. Tytuły adaptowalne przepisuje na czynność, której da się bronić trzema poziomami. Dopiero potem losuje próbkę `uncertain` z ESCO międzysektorowego i z odznak, których wymagania nadal nie są w bazie. Jeśli po tej recenzji zostanie wyraźnie mniej niż 1001 praktyk, brak uzupełniać nowymi źródłami dziedzin rzadkich, a nie kolejnym zrzutem kompetencji stanowiskowych.

Szczegóły reguł: `triage-method.md`.
