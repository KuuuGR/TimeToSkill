# Raport pokrycia kandydatur

Data generacji pierwszego etapu: 2026-10-18. Liczby w sekcjach przed etapem T4S-CATALOG-002 opisują stan 15162 rekordów. Aktualna suma jest w sekcji tego etapu.

Sekcje do „Dalsza praca do 1001 skillów” włącznie opisują pierwszy etap. Zostały policzone z plików tego etapu. Nie obejmują rekordów dopisanych później.

## Liczba kandydatur

- Rekordy w `candidates-raw.jsonl`: **15162**.
- Rekordy w `candidates-normalized.jsonl`: **15162** (jeden znormalizowany rekord na każdą kandydaturę surową).
- Cel organizacyjny 3500–4000 został przekroczony, bo sam filar umiejętności ESCO ma 13939 unikalnych pojęć. Nadmiar nie jest katalogiem 1001 Skills.

## Według źródła

- `esco-skills-v1.2.1`: 13939
- `onet-content-model-31.0`: 545
- `scouts-uk-activity-badges`: 171
- `openlearn-full-catalogue`: 9
- `wikidata-hobbies`: 211
- `heritage-crafts-inventory`: 287
- `ordnance-survey-mapzone`: 0
- `astronomical-league-observing-programs`: 0

## Według typu

- aktywność: 171
- hobby: 211
- obszar wiedzy: 3259
- pojęcie zawodowe: 341
- praktyczna czynność: 328
- skill: 10755
- węzeł taksonomii: 30
- zdolność: 67

## Według języka

- en: 15162

## Według wstępnej przydatności konsumenckiej

To mechaniczny znacznik opisany w `README.md`, nie ocena redakcyjna.

- high: 647
- medium: 4418
- low: 10073
- unclear: 24

## Identyfikatory

- Z `source_item_id`: 15162.
- Bez `source_item_id`: 0.

## ESCO: typ i poziom ponownego użycia

Każdy rekord ESCO liczy się tu raz.

- skillType knowledge: 3219
- skillType missing: 5
- skillType skill/competence: 10715

- reuseLevel cross-sector: 3783
- reuseLevel missing: 5
- reuseLevel occupation-specific: 3044
- reuseLevel sector-specific: 6655
- reuseLevel transversal: 452

## Najczęstsze etykiety nadrzędne ESCO

Rekord z kilkoma etykietami nadrzędnymi wchodzi do każdej z nich. To nie jest podział rozłączny.

- advise others: 270
- installing wooden and metal components: 217
- think critically: 182
- planning events and programmes: 165
- software and applications development and analysis: 163
- complying with health and safety procedures: 148
- food processing: 144
- lead others: 143
- monitoring quality of products: 134
- mechanics and metal trades: 134
- conducting academic or market research: 133
- developing operational policies and procedures: 128
- database and network design and administration: 126
- law: 126
- maintaining operational records: 124

## Skan słów w tytułach

Jedna kandydatura może trafić do kilku obszarów. Wzorzec musi zaczynać się na granicy znaku innego niż litera lub cyfra. To nie jest taksonomia.

- Nawigacja, mapa i orientacja: 28
- Astronomia amatorska: 5
- Obserwacja przyrody: 14
- Nauka obywatelska: 0
- Majsterkowanie, elektronika, naprawa, modelarstwo: 196
- Rytm, taniec, koordynacja: 40
- Retoryka, negocjacje, słuchanie: 46
- Pamięć, rozumowanie, analiza: 14
- Gotowanie i żywność: 19
- Organizacja życia i samodzielność: 3
- Finanse osobiste: 23
- Rzemiosło: 72
- Instrumenty: 30
- Fotografia: 35
- Pisanie: 13

## Obszary nadreprezentowane

- Pojęcia zawodowe ESCO o reuseLevel sector-specific albo occupation-specific: 9699 z 13939 rekordów ESCO.
- Szczegółowe czynności zawodowe O*NET na głębokości identyfikatora 5 zostały zapisane jako pojęcia zawodowe o niskiej przydatności, ale nadal pochodzą z taksonomii pracy, nie z praktyki hobbystycznej.
- Najliczniejsza etykieta nadrzędna ESCO to „advise others” (270 powiązań).

## Obszary, które wymagają dalszego pozyskiwania

Próg raportowy: mniej niż 30 trafień skanu tytułów. To nie jest ocena, że obszar jest pusty merytorycznie.

- Nawigacja, mapa i orientacja: 28
- Astronomia amatorska: 5
- Obserwacja przyrody: 14
- Nauka obywatelska: 0
- Pamięć, rozumowanie, analiza: 14
- Gotowanie i żywność: 19
- Organizacja życia i samodzielność: 3
- Finanse osobiste: 23
- Pisanie: 13

Niezależnie od skanu, te źródła specjalistyczne nie dały listy kandydatur:

- Ordnance Survey Mapzone: HTTP 200, strona wymaga JavaScriptu, brak listy umiejętności.
- Astronomical League, indeks programów obserwacyjnych A–C: 9 odsyłaczy do programów. Nie zaimportowano ich, bo dzielą obserwację według klas obiektów.
- Zapytanie Wikidanych celowo pomija dyscypliny sportu i typy sztuki. Taniec, sporty i sztuki wizualne nie są więc pokryte przez to źródło.
- Wymagania odznak Skautów nie zostały pobrane. Żywe żądanie zwróciło HTTP 403; karty odznak w tej odpowiedzi: False. Archiwalny indeks ma same nazwy.

## Problemy dostępu

- ESCO API `/search` z `full=true` oddało rekordy tylko dla offset 0 i 100. Użyto CSV v1.2.1 (10045670 bajtów, cache).
- Scouts, żywa strona: HTTP 403. Użyto snapshotu 20260308034627.
- OpenLearn, żywy katalog: HTTP 403. Użyto snapshotu 20230314213107, starszego niż data badania.
- Szczegółowe czynności O*NET niezaimportowane: 2087.
- Ścieżki kursów OpenLearn niezaimportowane: 611.

## Ograniczenia jakości

- Większość rekordów to pojęcia klasyfikacji zawodowej. Nie są one osobnymi skillami katalogu konsumenckiego.
- `consumer_relevance` nie była recenzowana ręcznie.
- `adaptation_hint` jest wszędzie puste. Skrypt nie dopisuje pomysłów adaptacji.
- Opisy Skautów i Heritage Crafts są puste, bo nie kopiowano artykułów ani regulaminów.
- Warianty odznak według sekcji wiekowej oraz warianty rzemiosł według regionu albo materiału nadal są osobnymi wierszami.
- Deduplikacja nie została wykonana. `duplicate-clusters.json` ma pustą listę grup.

## Dalsza praca do 1001 skillów

Samych rekordów jest dość, żeby po selekcji redakcyjnej wybrać 1001 pozycji, ale obecna pula nie jest jeszcze tą listą.
Następny etap to grupowanie duplikatów bez usuwania pochodzenia, odrzucenie pojęć czysto zawodowych i uzupełnienie obszarów poniżej progu skanu.
Nie należy dobijać liczby kolejnym zrzutem kompetencji zawodowych. Brakuje praktycznych źródeł dla nawigacji, astronomii amatorskiej bez podziału na klasy obiektów, nauki obywatelskiej, tańca i sportu oraz komunikacji interpersonalnej opisanej jako ćwiczenie, a nie jako kompetencja stanowiska.
Trzy poziomy, wyzwania i interfejs katalogu nadal nie istnieją.

## Etap T4S-CATALOG-002

Stan przed tym etapem: 15162 rekordów surowych i 15162 rekordów znormalizowanych.
Nowe rekordy: 102.
Stan po tym etapie: 15264 rekordów surowych i tyle samo znormalizowanych.
To nadal są kandydatury, nie unikalne umiejętności. Deduplikacja nie została uruchomiona.
Cel roboczy 500 nowych kandydatur nie został osiągnięty. Źródła nie zawierają 500 odrębnych czynności bez dzielenia gatunków, dań, produktów, poziomów i nazw dyscyplin.

| Źródło | Nowe rekordy |
| --- | ---: |
| `astronomical-league-observing-programs` | 17 |
| `ausport-fundamental-movement` | 15 |
| `bbc-good-food-25-skills` | 14 |
| `cfpb-building-blocks-2016` | 6 |
| `learning-scientists-six-strategies` | 6 |
| `olympic-education-fundamentals-2023` | 6 |
| `purdue-owl-writing` | 12 |
| `roc-what-is-orienteering` | 5 |
| `usgs-map-and-compass` | 5 |
| `wdsf-dancesport-disciplines` | 12 |
| `zooniverse-project-directory` | 4 |

Źródła bez nowych rekordów: iNaturalist Getting Started, iNaturalist birdwatching, CFPB Financial Well-Being Resources, CFPB adult financial-education tools, Learning Scientists concrete-examples episode, PMC review. Dwa ostatnie powtarzają strategie już zapisane.

Dziedziny nowych rekordów: mapa i kompas, orientacja sportowa, astronomia amatorska, typy działań nauki obywatelskiej, strategie uczenia się, techniki gotowania, finanse osobiste, pisanie, taniec, podstawowe umiejętności ruchowe i kilka opisanych praktyk sportowych.

Akapit o brakach w sekcji „Dalsza praca” dotyczy stanu sprzed tego etapu. Nawigacja, astronomia, typy działań nauki obywatelskiej, taniec i podstawowy ruch mają już kandydatury. Nadal nie ma rozpoznawania organizmów, a większość dyscyplin sportowych pozostała tylko na liście nazw.

Możliwe nakładanie, zostawione do późniejszego porównania:
- czytanie mapy USGS i czytanie mapy orientacyjnej;
- symbole USGS i legenda mapy orientacyjnej;
- łacina, Rhythm i Smooth;
- breaking w WDSF i na liście olimpijskiej;
- sześć strategii Learning Scientists i te same nagłówki artykułu PMC;
- budżet i plan wydatków w raporcie CFPB, zapisane jako jeden rekord;
- striking i hitting, zapisane jako jeden rekord;
- bieg ASC nie został dodany, bo tytuł `running` już istnieje.

Nadal słabo reprezentowane: rozpoznawanie organizmów po wyglądzie i głosie, oszustwa finansowe, przyprawianie i organizacja stanowiska kuchennego, choreografia jako osobna praktyka oraz większość dyscyplin, których źródło podaje tylko nazwę.

Nieodczytane:
- https://www.inaturalist.org/pages/getting-started — HTTP 403, brak migawki archiwum;
- https://www.inaturalist.org/pages/birdsaroundyou — HTTP 403, brak migawki archiwum;
- https://www.consumerfinance.gov/consumer-tools/educator-tool/financial-well-being-resources/ — HTTP 403;
- https://www.consumerfinance.gov/consumer-tools/educator-tool/adult-financial-education/tools-and-resources/ — HTTP 403.
