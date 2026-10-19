# Tempo odkrywania, packi 17–21

Start: `pilot-proposals-v11.jsonl`, 1122 propozycje. Koniec: `pilot-proposals-v16.jsonl`, 2019 propozycji. Przyrost: 897. Żadna pozycja nie jest skillem produkcyjnym. v9, v10 i v11 nie były nadpisywane.

Polityka dalszej pracy jest w `catalog-expansion-policy.md`. 2019 nie jest maksimum.

| Pakiet | Decyzje | Nowe | Już były | Odrzucone | Bez źródła | Udział nowych | Aktywne po rundzie |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| pack-17 | 500 | 224 | 249 | 15 | 12 | 44,8% | 1346 |
| pack-18 | 500 | 200 | 273 | 15 | 12 | 40,0% | 1546 |
| pack-19 | 500 | 225 | 248 | 15 | 12 | 45,0% | 1771 |
| pack-20 | 500 | 204 | 269 | 15 | 12 | 40,8% | 1975 |
| pack-21 | 500 | 44 | 438 | 10 | 8 | 8,8% | 2019 |

## Skąd wzięły się nowe propozycje

Najwięcej nowych pozycji dały packi 17 i 19: opieka nad zwierzęciem, muzyka we dwoje i opieka nad instrumentem, rysunek z natury, konta, miasto, materiały, jedzenie jako pojedyncze techniki, ruch, pismo i kultura.

Pack-21 przyniósł mało nowości przy pełnych 500 decyzjach. To nasycenie bliskich wariantów, nie sygnał, że katalog jest skończony. Polityka każe najpierw zrobić przegląd, a dopiero potem mierzyć, czy nowe źródła znowu dają istotny przyrost.

## Źródła otwarte w tej serii

Strony otwarte 2026-10-18, bez wklejania ich tekstu do poziomów:

- https://www.rspca.org.uk/adviceandwelfare/pets/dogs/training
- https://www.pdsa.org.uk/pet-help-and-advice/looking-after-your-pet/all-pets/5-welfare-needs
- https://www.ncsc.gov.uk/collection/top-tips-for-staying-secure-online/three-random-words
- https://www.ncsc.gov.uk/guidance/setting-2-step-verification-2sv

Reszta nowych propozycji to `editorial_synthesis`. URL nie był wymyślany. Luki źródłowe z wcześniejszych pakietów, w tym interwały, podcast, nagrania terenowe, DJ i linoryt, zostają otwarte.

## Walidacja

`validate_pilot_proposals.py` na v16: 0 błędów, 0 ostrzeżeń, 2019 rekordów. Łańcuch bajtów v11–v16 się zgadza: każdy nowszy plik zaczyna się od dokładnych bajtów poprzedniego. `git diff --check` zakończył się kodem 0.

## pack-22

| Pakiet | Decyzje | Nowe | Już były | Odrzucone | Bez źródła | Udział nowych | Aktywne po rundzie |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| pack-22 | 500 | 49 | 427 | 16 | 8 | 9,8% | 2068 |

Wobec pack-21 (44 nowe, 8,8%) przyrost liczby wzrósł nieznacznie, do 49. Różnica metody jest większa niż różnica liczby: te 49 propozycji ma otwartą stronę, a poziomy są adaptacją tej strony, nie wspólnym schematem „zacznij / dokończ / zostaw”.

Strony otwarte 2026-10-18, zapisane w `review-inputs/pack-22-source-led-discovery/sources-opened.md`:

- RSPCA, kuweta i środowisko kota
- NCSC, rozpoznawanie i zgłaszanie phishingu
- National Gallery of Art, rysowanie przedmiotu
- Tate, nazwane techniki szkicu
- Rada Europy, tabela globalna CEFR
- RHS i AHDB, tekstura gleby w ręku
- ONS, wykres słupkowy
- kopia przewodnika ABRSM z 2018 roku, nie strona abrsm.org

Pack-23 nie został otwarty w tamtej rundzie. Wcześniejszych luk nie zamknięto.

## Sprint 031, pack-23 i pack-24

Data pracy: 2026-10-19. To nie były trzy godziny zegarowe. Sesja zapisała dwie partie i zatrzymała się, zamiast wymyślać poziomy dla nazw bez otwartej metody.

| Pakiet | Decyzje | Nowe | Już były | Odrzucone | Bez metody | Udział nowych | Aktywne po rundzie |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| pack-23 | 500 | 18 | 6 | 86 | 390 | 3,6% | 2086 |
| pack-24 | 143 | 7 | 15 | 50 | 71 | 4,9% | 2093 |

Łącznie w sprincie: 643 kandydatów, 25 nowych propozycji. Cel 5000 nie został osiągnięty. Wobec pack-22 (49 nowych, 9,8%) udział nowych spadł, bo większość kandydatów to nazwy z indeksu bez otwartej strony metody.

Pełny raport: `curated/sprint-031-report.md`.

## Program 032, pack-25

Data: 2026-10-19. Jedna partia po otwarciu stron metod, nie indeksu nazw.

| Pakiet | Wiersze decyzji | Nowe propozycje | Nowi unikalni kandydaci | Już byli albo warianty | Bez metody | Aktywne |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| pack-25 | 23 | 6 | 5 | 4 ściegi z pack-23 plus warianty | 2 | 2099 |

Licznik programu: 643 z sprintu 031 oraz 5 nowych unikalnych kandydatów, razem 648. Cel 20000 nie został osiągnięty. Raport: `curated/sprint-032-batch-25-report.md`. Stan: `curated/discovery-program-032-state.json`.

## Program 033, pack-26

Data: 2026-10-19. Otworzono ścieg rybi i przewodnik jajecznicy. Couching bez treści. Nowe propozycje: 2. Aktywne: 2101. Unikalni kandydaci programu: 650. Odkrywanie wstrzymane przy malejącym przyroście. Kolejka ściegów RSN i origami nie jest wyczerpana.

## Program 034, pack-27

Data: 2026-10-19. Adres `https://rsnstitchbank.org/stitch/couching` znowu zwrócił pustą treść i nie został oznaczony jako otwarty. Otwarto `https://rsnstitchbank.org/stitch/couching-stitch`. Jedna nowa propozycja, `Couch a laid thread`, w v22 (2102). Wariantów couching nie otwarto. Glosariusz origami pozostaje indeksem nazw, nie metodą. Unikalni kandydaci programu: 651. Nic nie jest produkcyjne.
