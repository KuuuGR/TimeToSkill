# Instrukcja recenzji — ruch, sport i taniec

Data przygotowania: 2026-10-18. Ten katalog jest materiałem wejściowym. Nie zawiera zatwierdzonych skillów.

## Zawartość

Pakiet źródłowy: `data/skills-catalog/review-batches/05-ruch-sport-taniec-01.jsonl` (106 rekordów).
Do recenzji przekazano **102** kandydatur, które opisują ruch, sport, taniec albo praktykę w tych dziedzinach.
Pominięto **4** rekordów, które trafiły do pakietu przez przypadkowe słowo:

- `onet:4.A.3.a.4` — Operating Vehicles, Mechanized Devices, or Equipment. Opis dotyczy prowadzenia pojazdów i maszyn. Słowo Running oznacza tu obsługę, nie bieg.
- `wikidata:Q1313678` — ice fishing. Opis mówi o łowieniu ryb zimą. Źródło nie opisuje tego jako sportu, ruchu ani tańca.
- `wikidata:Q389525` — retrocomputing. Opis mówi o uruchamianiu starego sprzętu komputerowego. Słowo running nie oznacza biegu.
- `wikidata:Q1323158` — rock balancing. Opis mówi o układaniu skał jako instalacji. To nie jest ruch ciała, sport ani taniec.

Każdy wiersz `candidates.jsonl` zachowuje `candidate_id`, `source_id`, oryginalną nazwę, opis źródłowy, URL i wynik triage. Opisów nie uzupełniano.

## Braki danych

- Bez wystarczającego opisu źródłowego: 65 z 102. Przy tych rekordach `source_description` jest puste albo zbyt krótkie, a `description_note` mówi tylko o tym braku.
- Odznaki Skautów mają sam tytuł. Wymagań nie ma w bazie. Ten sam tytuł w kilku sekcjach wiekowych nie jest osobnym skillem, dopóki wymagania tego nie pokażą.
- Część rekordów WDSF, ASC i programów sportowych też nie ma osobnego zdania opisowego. Nie dopisywano techniki z pamięci.
- `related_unresolved_candidate_ids` pochodzi z propozycji grup. To nie jest decyzja, że rekordy są tym samym skillem. Część powiązanych identyfikatorów może leżeć poza tym plikiem.
- Triage jest heurystyką. Nie rozstrzyga, czy kandydatura wchodzi do katalogu.
- Nagłówek OpenLearn „Health, Sports & Psychology” jest nazwą działu kursów, nie opisem praktyki.

## Jak oceniać

Osobny skill ma własną, sensowną ścieżkę rozwoju. Wariant techniki, poziom trudności, konkretny układ taneczny albo sama nazwa dyscypliny nie tworzą automatycznie nowego skilla. Nie scalać też dwóch różnych umiejętności tylko dlatego, że występują w tym samym sporcie.

Zatwierdzony skill ma mieć docelowo trzy poziomy z obserwowalnymi kryteriami ukończenia i jedno tematycznie dopasowane emoji. Emoji mogą się powtarzać, ale cały katalog ma zostać wizualnie różnorodny.

Pilotaż kuchni i finansów w `data/skills-catalog/pilots/kitchen-finance/` pokazuje format decyzji, poziomy i sposób łączenia wariantów. Tamte poziomy i emoji są adaptacją redakcyjną, nie cytatem ze źródeł. Decyzje z tamtego pakietu nie są regułą bez wyjątków.

Nie tworzyć w tym katalogu rekordów `approved-skill`. Ocena, deduplikacja i trzy poziomy należą do osobnej recenzji.
