# Pakiety 1001 Skills

Źródło statusu pakietów: `data/skills-catalog/pack-registry.json`. Źródło statusu luk: `data/skills-catalog/gaps-registry.json`. Czytelny indeks luk: `GAPS.md`. Data wpisu: 2026-10-18.

Żaden pakiet nie jest zatwierdzony produkcyjnie. Aktualna rewizja robocza propozycji to `curated/pilot-proposals-v11.jsonl` (1122 rekordów, status `pilot_proposal`). `curated/pilot-proposals-v10.jsonl` zostaje poprzednią rewizją, 995 rekordów. Następny nowy zakres kandydatur dostaje `pack-17`. Poprawka istniejącego pakietu nie dostaje nowego numeru. Szczegółowe raporty luk zostają miejscem dowodu. Rejestr centralny trzyma status.

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
