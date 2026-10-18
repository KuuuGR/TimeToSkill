# Kontrola jakości 71 propozycji pilotażowych

Data przeglądu: 2026-10-18. Rejestr: `pilot-proposals.jsonl`. To czytanie kryteriów, nie nowa redakcja i nie zgoda produkcyjna. Żadnego rekordu nie przepisano.

## Bez istotnych problemów redakcyjnych

Poziomy idą od pierwszej wykonanej czynności, przez kontrolę albo porównanie, do samodzielniejszego użycia. Kryteria da się zaobserwować.

Kuchnia i finanse: `kitchen-finance:kitchen-knife-skills`, `cook-rice-reliably`, `basic-baking-techniques`, `pan-searing-and-browning`, `sauces-and-dressings`, `stock-and-broth-making`, `egg-preparation-techniques`, `kitchen-food-safety`, `personal-budgeting-and-saving`, `compare-financial-offers`, `understand-interest-costs`.

Ruch, poza grupami wymienionymi niżej: `balance-and-weight-transfer`, `ball-dribbling-control`, `hopping-and-rhythmic-skipping`, `jumping-and-landing`, `swimming-fundamentals`, `cycling-fundamentals`, `mountain-biking-fundamentals`, `hiking-and-trail-preparation`, `trail-running-fundamentals`, `cross-country-skiing-basics`, `roller-skating-fundamentals`, `paddling-basics`, `pilates-foundations`, `gymnastics-movement-foundations`, `sportsmanship-and-fair-play`.

Technologia i nauka: `digital-map-making`, `digital-research-and-source-evaluation`, `practical-data-analysis`, `digital-publishing-and-layout`, `graphic-design-basics`, `personal-device-setup`, `everyday-tech-troubleshooting`, `programming-fundamentals`, `open-source-contribution`, `backgammon-strategy`, `role-playing-and-collaborative-storytelling`, `science-communication`, `kite-flying`.

## Drobne sugestie

Progi liczby prób albo czasu są ramą, a nie jedyną treścią. Nie zmieniano ich automatycznie.

- `movement-sport-dance:catching-with-control`, `accurate-throwing`, `controlled-kicking`, `striking-with-control` — kolejne poziomy podnoszą ułamek udanych prób i zmieniają warunki. Ułamek jest umowny.
- `movement-sport-dance:running-and-pacing` — drabina 10, 15 i 20–30 minut. Jest też wskazówka tempa, ale czas dominuje.
- `movement-sport-dance:dance-rhythm-and-basic-steps`, `hip-hop-dance-foundations`, `contemporary-dance-foundations` — czas trwania frazy jest pojemnikiem na obserwowalny ruch.
- `technology-science-niches:sky-observation`, `wildlife-observation`, `fishkeeping-basics` — kilka sesji albo cztery tygodnie dziennika. Dziennik jest obserwowalny, sam upływ czasu nie.
- `technology-science-niches:geocaching` — poziom trzeci jest planem skrytki, nie jej legalnym założeniem.
- `kitchen-finance:cook-rice-reliably` — poziom drugi każe powtórzyć metodę, ale też nazwać wpływ płukania, proporcji i ciepła.

## Wymagają dopięcia źródeł

Poziomy są konkretniejsze niż opis kandydatury w Wikidanych. Strony użyte przy redakcji są w `pilots/technology-science-niches/additional-sources.json` jako `reference_id` i nie weszły do `source_ids` ani do rejestru centralnego.

- `technology-science-niches:sky-observation`
- `technology-science-niches:fishkeeping-basics`
- `technology-science-niches:wildlife-observation`
- `technology-science-niches:genealogy-research`
- `technology-science-niches:beginner-electronics-prototyping`
- `technology-science-niches:wikimedia-contribution`
- `technology-science-niches:growing-plants-from-seed`

`movement-sport-dance:running-and-pacing` opiera się tylko na `wikidata-hobbies`.

## Wymagają ponownego zdefiniowania poziomów

- `movement-sport-dance:running-and-pacing` — jeśli bieg ma zostać skillem, poziomy powinny rozróżniać tempo, teren i samodzielne planowanie mocniej niż sam czas trwania.
- Dziesięć propozycji tańca z grupy `review:related_practice_family:dance-styles` ma bardzo podobny szkielet: krótka fraza, wariacja, wykonanie. Style mogą zostać osobno, ale poziomy warto odróżnić treścią stylu, nie tylko nazwą.

## Możliwie nakładające się

Szczegóły i rekomendacje są w `cross-pilot-review.json`. Niczego nie scalono. Do rozstrzygnięcia przez człowieka: rodzina tańca, bieg i bieg terenowy, wędrówka i bieg terenowy, rower i rower terenowy oraz emoji 🪩 przy breakingu i disco. Pary ESCO oraz emoji ⚖️ rekomendowano zostawić osobno. Decyzji nie podjęto.

## Emoji

71 propozycji, 69 symboli. Powtórzenia: ⚖️ dwa razy, 🪩 dwa razy. Pięć najczęstszych symboli to 7 z 71 użyć, bo tylko te dwa symbole występują więcej niż raz. Koncentracji ikon w jednej kategorii nie widać poza tańcem, gdzie wiele stylów ma własne emoji, a breaking i disco dzielą 🪩. Emoji nie zmieniano.

## Decyzje i rewizja v2, 2026-10-18

Dziesięć grup z `cross-pilot-review.json` ma `decision_taken` true i decyzję pozostawienia propozycji osobno. Żadnego rekordu nie usunięto. Rodzina tańca zostaje osobno, a jej poziomy wymagają specyficzności stylu.

Nowa rewizja to `pilot-proposals-v2.jsonl`. Rejestr bazowy zostaje. Szczegóły poprawek, brak pakietu `skills-pilot/curated-review-decisions/` oraz wytyczne zakresów są w `pilot-proposals-v2-notes.md`. Kryteriów biegu nie przepisano, bo nie było ich tekstu w repozytorium.
