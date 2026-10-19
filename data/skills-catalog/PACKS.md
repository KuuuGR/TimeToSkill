# Pakiety 1001 Skills

Źródło statusu pakietów: `data/skills-catalog/pack-registry.json`. Źródło statusu luk: `data/skills-catalog/gaps-registry.json`. Czytelny indeks luk: `GAPS.md`. Data wpisu: 2026-10-18.

Żaden pakiet nie jest zatwierdzony produkcyjnie. Aktualna rewizja robocza propozycji to `curated/pilot-proposals-v21.jsonl` (2101 rekordów, status `pilot_proposal`). Poprzednia rewizja tej serii to `curated/pilot-proposals-v20.jsonl`, 2099 rekordów. v19 i wcześniejsze zostają nietknięte. Program 033 zapisał pack-26 i wstrzymał odkrywanie. Pack-27 nie jest otwarty. Globalnej selekcji nie wykonano. Poprawka istniejącego pakietu nie dostaje nowego numeru.

Pakiet `skills-pilot/curated-review-decisions/` nie istnieje. To miał być materiał decyzji o już istniejących propozycjach, nie nowy pakiet skillów. Jego integracji nie potwierdzono i nie odtworzono zawartości. W v2 widać trzy różnice pól wobec v1; nie przypisano ich temu brakującemu pakietowi.

| ID | Temat | Kandydatury | Ocenione | Propozycje | Status |
|----|--------|-------------|----------|------------|--------|
| pack-01 | Kuchnia, finanse i codzienność | 43 | 43 | 11 | integrated |
| pack-02 | Ruch, sport i taniec | 102 | 102 | 30 | needs_revision |
| pack-03 | Technologia, nauka i niszowe zainteresowania | 114 | 114 | 30 | needs_revision |
| pack-04 | Komunikacja, myślenie, przyroda i nawigacja | 126 | 126 | 39 | integrated |
| pack-05 | Muzyka, dźwięk, głos i sztuki performatywne | 146 | 0 | 0 | ready_for_review |
| pack-06 | Sztuki wizualne, fotografia i projektowanie | 128 | 0 | 0 | ready_for_review |
| pack-07 | Rzemiosło użytkowe, tekstylia, naprawy i odnawianie | 128 | 0 | 0 | ready_for_review |
| pack-08 | Ogrodnictwo, uprawa roślin i praktyczna ekologia | 61 | 0 | 0 | ready_for_review |
| pack-09 | Pierwsza pomoc, bezpieczeństwo domowe i przygotowanie na sytuacje awaryjne | 72 | 0 | 0 | ready_for_review |
| pack-10 | Opieka nad zwierzętami, dobrostan i trening oparty na nagradzaniu | 60 | 0 | 0 | ready_for_review |
| pack-11 | Ogólne umiejętności praktyczne | 500 | 500 | 13 | needs_revision |
| pack-12 | Szeroka ekspansja praktyk | 500 | 500 | 183 | needs_revision |
| pack-13 | Rozszerzenie pokrycia | 500 | 500 | 232 | needs_revision |
| pack-14 | Twierdzenia, ślady, doświadczenia i ustalenia | 500 | 500 | 204 | needs_revision |
| pack-15 | Triki, kody, papier i pokazy | 500 | 500 | 259 | needs_revision |
| pack-16 | Niebo, żywe rzeczy, tkanina i miasto | 500 | 500 | 127 | needs_revision |
| pack-17 | Zwierzęta, muzyka, rysunek i konta | 500 | 500 | 224 | needs_revision |
| pack-18 | Miasto, materiały, gry i dom | 500 | 500 | 200 | needs_revision |
| pack-19 | Jedzenie, ruch, pismo i kultura | 500 | 500 | 225 | needs_revision |
| pack-20 | Codzienność, rośliny, rower i woda | 500 | 500 | 204 | needs_revision |
| pack-21 | Drobne braki po 1975 | 500 | 500 | 44 | needs_revision |
| pack-22 | Odkrywanie ze źródeł | 500 | 500 | 49 | needs_revision |
| pack-23 | Ściegi, reguły szachowe i runda | 500 | 500 | 18 | needs_revision |
| pack-24 | Mycie rąk, zgięcia i kompas | 143 | 143 | 7 | needs_revision |
| pack-25 | Metody, nie indeksy | 5 | 5 | 6 | needs_revision |
| pack-26 | Ścieg rybi i jajecznica | 2 | 2 | 2 | needs_revision |

## pack-01

Kopia zintegrowana: `pilots/kitchen-finance/`. W `skills-pilot/` nie ma katalogu przekazania. Partia `review-batches/09-kuchnia-finanse-codziennosc-01.jsonl` ma 43 wiersze, tyle samo decyzji. Walidacja przechodzi. Ostrzeżenie: kategoria Cooking and food preparation obejmuje 8 z 11 propozycji.

## pack-02

Kandydatury: `review-inputs/movement-sport-dance/` (102). Decyzje i 30 propozycji: `pilots/movement-sport-dance/`. Partia `05-ruch-sport-taniec-01.jsonl` ma 106 wierszy. W `skills-pilot/` nie ma katalogu przekazania. Recenzja kandydatur jest zamknięta, a kryteria tańca oraz biegu, biegu terenowego i wędrówki wymagają odróżnienia. Propozycje zostają osobne. `movement-sport-dance:running-and-pacing` ma w źródłach tylko `wikidata-hobbies`.

## pack-03

Przekazanie wskazane przez użytkownika: `skills-pilot/skills-pilot-review-technology-science-niches 2/`. Wcześniejszy katalog bez ` 2` zostaje. Kopia zintegrowana: `pilots/technology-science-niches/`. 114 decyzji i 30 propozycji. Recenzja kandydatur nie kończy redakcji skillów. Do dalszej pracy: cztery propozycje modelarskie oraz siedem propozycji, których strony redakcyjne są tylko w `reference_id`.

## pack-04

Pakiet do recenzji: `review-inputs/communication-cognition-nature/`. Samowystarczalna paczka zewnętrzna: `archives/pack-04-communication-cognition-nature-review.zip`. Kopia do przekazania: `skills-pilot/outgoing/pack-04-communication-cognition-nature.zip`. Wcześniejszy ZIP `archives/communication-cognition-nature-review.zip` zostaje. 126 kandydatur i 126 decyzji recenzji. W rejestrze v5 jest 39 propozycji tego pochodzenia. Status `integrated`. To nie jest akceptacja produkcyjna. Kopia robocza: `pilots/communication-cognition-nature/`. Katalogi przekazania nie były edytowane. W v5 dziewięć grup zostawiono osobno. Z 30 kandydatur ze źródłem przyjęto 4, a 26 odrzucono. Decyzje: `editorial-decisions-pack-04-v5.jsonl`.

## pack-05

Pakiet do recenzji: `review-inputs/pack-05-music-sound-performance/` i ZIP `archives/pack-05-music-sound-performance.zip`. 146 kandydatur z bazy, zero decyzji, zero propozycji. To nie jest katalog skillów. Luki źródeł są w `review-inputs/pack-05-music-sound-performance/gaps.md`. Kandydatur nie zmieniano.

## pack-06

Pakiet do recenzji: `review-inputs/pack-06-visual-arts-design/` i ZIP `archives/pack-06-visual-arts-design.zip`. Ze 151 trafień tytułu wybrano 128 kandydatur. Zero decyzji i zero propozycji. To nie jest katalog skillów. Luki, w tym brak linorytu i drzeworytu oraz 33 rekordy bez opisu, są w `review-inputs/pack-06-visual-arts-design/gaps.md`.

## pack-07

Pakiet do recenzji: `review-inputs/pack-07-craft-textiles-repair/` i ZIP `archives/pack-07-craft-textiles-repair.zip`. 128 kandydatur szycia, włókna, skóry, drewna i napraw. Zero decyzji i zero propozycji. To nie jest katalog skillów.

## pack-08

Pakiet do recenzji: `review-inputs/pack-08-gardening-plant-cultivation-ecology/` i ZIP `archives/pack-08-gardening-plant-cultivation-ecology.zip`. 61 kandydatur z bazy, poniżej celu 120–160. Zero decyzji i zero propozycji. To nie jest katalog skillów. Luki są w `gaps.md` i w `gaps-registry.json`.

## pack-09

Pakiet do recenzji: `review-inputs/pack-09-first-aid-home-safety-preparedness/` i ZIP `archives/pack-09-first-aid-home-safety-preparedness.zip`. 72 kandydatury, w tym 53 dopisane ze wskazanych stron. Zero decyzji i zero propozycji. To nie jest katalog skillów. Opisy nie są instrukcjami zabiegów. Źródła pack-10 nie zamykają luk pack-09.

## pack-10

Pakiet do recenzji: `review-inputs/pack-10-pet-care-animal-welfare-training/` i ZIP `archives/pack-10-pet-care-animal-welfare-training.zip`. 60 kandydatur, w tym 45 dopisanych ze wskazanych stron. Zero decyzji i zero propozycji. To nie jest katalog skillów. Trening ma być oparty na nagradzaniu.

## pack-11

Przekazanie: `skills-pilot/pack-11-general-practical-skills-500/`. Recenzja: `pilots/general-practical-skills/`. Pierwszy przebieg zostaje w `review-decisions-pack-11.jsonl`. Drugi przebieg, `review-decisions-pack-11-v2.jsonl`: 12 przyjętych do pilota, 485 odrzuceń, 3 bez źródła. W rejestrze v5 jest 13 propozycji tego pochodzenia. Status `needs_revision` przez trzy naprawy bez bezpiecznej metody. Stron ESCO nie otwierano ponownie. To nie jest katalog produkcyjny.

## pack-12

Kandydatury: `review-inputs/pack-12-broad-practice-expansion/`. Recenzja: `pilots/broad-practice-expansion/`. 500 decyzji, 183 propozycje w rejestrze v6. Status `needs_revision` przez 17 czynności wysokiego ryzyka bez źródła. Podstawa `editorial_synthesis`: nie cytowano stron i nie wymyślono URL. To nie jest katalog produkcyjny.

## pack-13

Kandydatury: `review-inputs/pack-13-coverage-expansion/`. Recenzja: `pilots/coverage-expansion/`. 500 decyzji, 232 propozycje w rejestrze v7. 170 już reprezentowanych, 79 odrzuceń, 19 bez źródła. Status `needs_revision` przez te 19 czynności wysokiego ryzyka. Podstawa `editorial_synthesis`: nie cytowano stron i nie wymyślono URL. Luka pack-12 zostaje otwarta. To nie jest katalog produkcyjny.

## pack-14

Kandydatury: `review-inputs/pack-14-practice-expansion/`. Recenzja: `pilots/practice-expansion-14/`. 500 decyzji, 204 propozycje w rejestrze v8. 244 już reprezentowane, 34 odrzucenia, 18 bez źródła. Status `needs_revision` przez te 18 czynności wysokiego ryzyka. Podstawa `editorial_synthesis`: nie cytowano stron i nie wymyślono URL. Luki pack-12 i pack-13 zostają otwarte. To nie jest katalog produkcyjny.

## pack-15

Kandydatury: `review-inputs/pack-15-showable-skills/`. Recenzja: `pilots/showable-skills/`. 500 decyzji, 259 propozycji w rejestrze v9. 206 już reprezentowanych, 19 odrzuceń, 16 bez źródła. Status `needs_revision` przez te 16 czynności wysokiego ryzyka. Podstawa `editorial_synthesis`: nie cytowano stron i nie wymyślono URL. Luki pack-12, pack-13 i pack-14 zostają otwarte. To nie jest katalog produkcyjny.

## pack-16

Kandydatury: `review-inputs/pack-16-final-broad-discovery/`. Recenzja: `pilots/final-broad-discovery/`. 500 decyzji, 127 propozycji w rejestrze v11. 342 już reprezentowanych, 17 odrzuceń, 14 bez źródła. Podstawa `editorial_synthesis`. Wcześniejsze luki ryzyka zostają otwarte. To nie jest katalog produkcyjny.

## pack-17

Kandydatury: `review-inputs/pack-17-animals-music-drawing/`. Recenzja: `pilots/animals-music-drawing/`. 500 decyzji, 224 propozycje w v12. 249 już reprezentowanych, 15 odrzuceń, 12 bez źródła. Otwarte strony: RSPCA o treningu psa, PDSA o pięciu potrzebach, NCSC o haśle z trzech słów i o weryfikacji dwuetapowej. Reszta to `editorial_synthesis` bez wymyślonego URL. To nie jest katalog produkcyjny.

## pack-18

Kandydatury: `review-inputs/pack-18-city-craft-games/`. Recenzja: `pilots/city-craft-games/`. 500 decyzji, 200 propozycji w v13. 273 już reprezentowane, 15 odrzuceń, 12 bez źródła. Podstawa `editorial_synthesis`. To nie jest katalog produkcyjny.

## pack-19

Kandydatury: `review-inputs/pack-19-food-movement-culture/`. Recenzja: `pilots/food-movement-culture/`. 500 decyzji, 225 propozycji w v14. 248 już reprezentowanych, 15 odrzuceń, 12 bez źródła. Podstawa `editorial_synthesis`. To nie jest katalog produkcyjny.

## pack-20

Kandydatury: `review-inputs/pack-20-everyday-breadth/`. Recenzja: `pilots/everyday-breadth/`. 500 decyzji, 204 propozycje w v15. 269 już reprezentowanych, 15 odrzuceń, 12 bez źródła. Podstawa `editorial_synthesis`. To nie jest katalog produkcyjny.

## pack-21

Kandydatury: `review-inputs/pack-21-breadth-after-1975/`. Recenzja: `pilots/breadth-after-1975/`. 500 decyzji, 44 propozycje w v16. 438 już reprezentowanych, 10 odrzuceń, 8 bez źródła. Niski przyrost przy pełnych 500 decyzjach oznacza nasycenie łatwych wariantów, nie powód do obniżenia progu. Rejestr miał wtedy 2019 propozycji. To nie jest katalog produkcyjny.

## pack-22

Kandydatury: `review-inputs/pack-22-source-led-discovery/`. Recenzja: `pilots/source-led-discovery/`. 500 decyzji, 49 propozycji w v17. 427 już reprezentowanych, 16 odrzuceń, 8 bez źródła. Nowe propozycje pochodzą z 11 otwartych stron (RSPCA, NCSC, National Gallery of Art, Tate, Rada Europy, RHS, AHDB, ONS i kopia przewodnika ABRSM). Poziomy są adaptacją, nie cytatem. Rejestr miał wtedy 2068 propozycji. To nie jest katalog produkcyjny.

## pack-23

Kandydatury: `review-inputs/pack-23-stitch-chess-rounds/`. Recenzja: `pilots/stitch-chess-rounds/`. 500 decyzji, 18 propozycji w v18. 6 już reprezentowanych, 86 odrzuceń, 390 bez otwartej metody. Otwarte strony metod: Royal School of Needlework (dziewięć ściegów i ściana nazw), FIDE Laws of Chess 2023, UUA o rundach. Poziomy są adaptacją. To nie jest katalog produkcyjny.

## pack-24

Kandydatury: `review-inputs/pack-24-hands-folds-compass/`. Recenzja: `pilots/hands-folds-compass/`. 143 decyzje, bez dopychania do 500. 7 propozycji w v19. 15 już reprezentowanych, 50 odrzuceń, 71 bez otwartej metody. Otwarte strony: NHS o myciu rąk, British Origami Society o zgięciu doliny i góry oraz glosariusz, przewodnik Ordnance Survey. Rejestr miał wtedy 2093 propozycje. To nie jest katalog produkcyjny.

## pack-25

Kandydatury: `review-inputs/pack-25-methods-not-indexes/`. Recenzja: `pilots/methods-not-indexes/`. Sześć otwartych stron metod, 6 propozycji w v20. Cztery ściegi były już w kolejce pack-23 i nie weszły drugi raz do licznika unikalnych kandydatów. Nowych unikalnych kandydatów jest 5. Rejestr ma 2099 propozycji. Pack-26 nie jest otwarty. To nie jest katalog produkcyjny.

## pack-26

Kandydatury: `review-inputs/pack-26-fishbone-scramble/`. Recenzja: `pilots/fishbone-scramble/`. Dwie otwarte strony metod, 2 propozycje w v21. Couching nie zwrócił treści. Rejestr miał wtedy 2101 propozycji. To nie jest katalog produkcyjny.

## pack-27

Kandydatury: `review-inputs/pack-27-couching/`. Recenzja: `pilots/couching/`. Jedna otwarta strona metody, 1 propozycja w v22. Adres `/stitch/couching` znowu był pusty. Użyto `https://rsnstitchbank.org/stitch/couching-stitch`. Warianty couching i glosariusz origami nie dostały propozycji. Rejestr ma 2102 propozycje. Pack-28 nie jest otwarty. To nie jest katalog produkcyjny.
