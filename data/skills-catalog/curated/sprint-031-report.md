# Sprint 031

Data: 2026-10-19. Czas: jedna sesja robocza, nie trzy godziny zegarowe. Środowisko nie pozwalało czekać trzech godzin, a dalsze partie bez nowych otwartych metod byłyby sztucznym zapełnianiem limitu. Cel 5000 kandydatów nie został osiągnięty.

## Liczby

| | Pack-23 | Pack-24 | Sprint |
| --- | ---: | ---: | ---: |
| Rozważeni | 500 | 143 | 643 |
| Nowe propozycje | 18 | 7 | 25 |
| Już reprezentowani | 6 | 15 | 21 |
| Odrzuceni | 86 | 50 | 136 |
| Wymagają źródła lub metody | 390 | 71 | 461 |

Aktywne propozycje: 2068 na starcie, 2093 po sprincie. Wszystkie nowe rekordy mają status `pilot_proposal`.

Udział nowych: pack-23 3,6%, pack-24 4,9%. Pack-22 miał 9,8% (49/500), pack-21 8,8% (44/500). Spadek wynika z odmowy pisania poziomów dla nazwy bez otwartej metody, nie z braku nazw.

## Partie

Pack-23 poszerzył haft (równy ścieg przed igłą, fastryga, ścieg wsteczny, łańcuszek, atłas, łodygowy, jodełka, muszka, rozcinany, pojedynczy łańcuszek), szachy (przelot, powód zakazu roszady, dotknięta figura, remis przed zegarem, jeden zapis algebraiczny) i śpiew rundy.

Pack-24 poszerzył mycie rąk według NHS, cztery zgięcia origami i dwie czynności z kompasem: korekta z legendy oraz odsunięcie metalu.

## Źródła

Otwartych i użytych w tym sprincie: 16. Lista jest w `sources-opened.md` obu partii. Nazwy ze ściany RSN i glosariusza origami widziano na otwartych indeksach, ale ich stron metod nie otwarto. Nie są zweryfikowanymi skillami.

## Ryzyka i luki

Ryzyka: nadal 186, żadne nie jest resolved. Ten sprint nie dopisał procedur. Nowe luki, obie otwarte: `gap-pack-23-stitch-methods-unopened`, `gap-pack-24-origami-methods-unopened`. Łącznie luk: 58, w tym 28 wymagających źródła. Wcześniejszych luk nie zamknięto.

## Walidacja

- `validate_pilot_proposals.py` na v19: 0 błędów, 0 ostrzeżeń, 2093 rekordy.
- Zatwierdzone pliki pack-23 (18) i pack-24 (7): 0 błędów, 0 ostrzeżeń.
- v19 zaczyna się od bajtów v18, v18 od bajtów v17.
- `git diff --check` jest w raporcie końcowym sesji.

## Dalej

Warto otwierać pojedyncze strony metod ze ściany RSN i z glosariusza origami, a nie dopisywać kolejnych nazw. Osobno: techniki kuchenne z otwartą metodą, śpiew kanonu w innym źródle niż jedna strona UUA oraz czytanie mapy poza namiar, który już jest w katalogu. Nie warto wracać do trików rąk, papierowych modeli jako wariantów ani do kolejnych języków CEFR.
