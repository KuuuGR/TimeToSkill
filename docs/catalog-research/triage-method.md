# Metoda triage i grupowania — T4S-CATALOG-003

Data: 2026-10-18. Skrypt: `build_catalog_003.py`.

To jest heurystyka deterministyczna. Nie jest oceną ekspercką i nie zatwierdza skillów. Żaden rekord nie został usunięty ani scalony. Nie wywołano zewnętrznego modelu.

## Klasyfikacja

Pytanie robocze: czy pozycja może być samodzielną praktyką, którą osoba niebędąca ekspertem rozwija na trzech odróżnialnych poziomach?

Reguły stosowane są w stałej kolejności. Pierwsza pasująca wygrywa. Sygnał `rule` jest w polu `signals` pośrednio przez etykiety źródła i cechy; pełna kolejność jest w skrypcie.

- Węzeł taksonomii O*NET oraz nagłówek działu OpenLearn są rozstrzygane z typu rekordu.
- Odznaki Skautów bez tekstu wymagań dostają `uncertain`, poza nazwami mundurowymi i okolicznościowymi.
- Źródła z etapu T4S-CATALOG-002 dostają `strong_candidate` tylko wtedy, gdy zapis opisuje powtarzalną praktykę. Nazwy programów, rodzin tańca, przykładów projektów i postaw dostają `adaptable_candidate`.
- Rzemiosło z nawiasem jest traktowane jako wariant. Sama nazwa rzemiosła jest `strong_candidate` ze średnią pewnością, bo artykułu nie czytano.
- Wikidata nie jest uznawana za przydatną tylko dlatego, że rekord jest na liście hobby. Pusty opis daje `uncertain`. Opis przedmiotu, zawodu albo zbioru daje `not_a_distinct_skill`.
- ESCO nie jest hurtowo odrzucane. `skillType=knowledge` oznacza pojęcie albo obszar. Wąski wzorzec tytułu, na przykład gra na instrumencie, daje `adaptable_candidate` także przy wysokim reuseLevel zawodowym. Reszta pojęć sektorowych i zawodowych dostaje `occupational_or_abstract` z niską albo średnią pewnością, bo opisu nie interpretowano zdanie po zdaniu. Pojęcia międzysektorowe i transwersalne bez takiego wzorca dostają `uncertain`.
- Wysoka pewność i brak indywidualnej recenzji dotyczy tylko reguł strukturalnych: węzeł taksonomii, nagłówek kursów, odznaka okolicznościowa, tytuł „types of” i pokrewne oraz czasownik organizacyjny przy reuseLevel sektorowym albo zawodowym, a także szczegółowe czynności O*NET już oznaczone jako pojęcie zawodowe.

`human_review_required` jest prawdziwe dla każdej pozycji obiecującej, niepewnej i dla reguł o pewności średniej albo niskiej. Fałsz nie oznacza zatwierdzenia odrzucenia. Oznacza, że ta heurystyka nie kieruje rekordu do indywidualnej lektury w następnym kroku.

## Grupowanie

Nie wykonano porównania synonimów ani porównania semantycznego.

1. Identyczna znormalizowana nazwa (`comparison_key` z pliku znormalizowanego).
2. Ten sam `source_item_id` w obrębie źródła. W tym zbiorze takich grup nie było.
3. Rdzeń tytułu po usunięciu nawiasów, jeśli powstaje więcej niż jedna nazwa.
4. Identyczny opis źródłowy o długości co najmniej 40 znaków. Niska pewność, bo ten sam akapit może opisywać różne czynności.
5. Podobieństwo leksykalne tytułu: tokeny dłuższe niż dwa znaki, bez krótkich przyimków; co najmniej dwa tokeny wspólne; Jaccard co najmniej 0,8; różnica symetryczna co najwyżej dwa tokeny. Blokowanie idzie po najrzadszym tokenie, którego częstość nie przekracza 400. Rekordy złożone wyłącznie z bardzo częstych tokenów nie wchodzą do porównań parami.

Podobieństwo nazwy nie scala rekordów. Grupy o wysokiej pewności też wymagają człowieka, gdy tytuł może być homonimem albo tą samą odznaką w innej sekcji wiekowej.

## Ograniczenia

- Wzorzec praktyki osobistej w ESCO jest krótki i celowo wąski. Pomija część prawdziwych praktyk i może złapać tytuł zawodowy o podobnych słowach.
- Opisy ESCO i O*NET nie były czytane pojedynczo.
- Brak synonimów: „throwing” i „rzut” nie zostaną połączone, podobnie jak para opisująca to samo innymi słowami.
- Jaccard nie rozumie, że dwa podobne ciągi znaków mogą być różnymi praktykami.
