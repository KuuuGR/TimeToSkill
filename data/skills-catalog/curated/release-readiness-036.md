# T4S-CATALOG-036 — kompendium, kryształy, pasek, licznik od daty

Data: 2026-10-19. Gałąź `Time4Skill-MacOS`. Bez commitów i pushy. Magazyn użytkownika `com.etaosin.time4skill` nie był otwierany; mtime `default.store` został `1790663998`.

## Dlaczego widać około 38 umiejętności

To nie jest błąd uruchomienia macOS ani iOS. Ekran umiejętności czyta SwiftData `ExemplarySkill`, a `SkillSeeder` ładuje wyłącznie `ExemplarySkills.json` (albo `ExemplarySkills_<język>.json`). Każdy z tych plików ma `catalogVersion` 2 i 38 pozycji. To wbudowany zestaw przykładowy wydania.

Katalog pilotażowy `data/skills-catalog/curated/pilot-proposals-v22.jsonl` (2102 propozycje) nie jest podłączony do seedera. Propozycje zostają propozycjami. Nie zostały zaimportowane.

Na ekranie umiejętności jest teraz podpis, że to zestaw wbudowany, a nie lista pilotażowa.

## Ochrona danych przy aktualizacji zestawu

Wcześniej seeder kończył pracę, gdy numer wersji w pliku nie był wyższy od zapisanego w `UserDefaults`. Nowa pozycja dodana bez podbicia wersji w ogóle nie wchodziła do magazynu.

`SkillSeeder.reconcile` przy każdym starcie:

- dopisuje brakujący `catalogID`;
- odświeża tytuł, opis, obraz, kategorię i trudność istniejącego rekordu katalogowego;
- nie rusza `isObtained`, `obtainedAt`, `userRating`, `isFavorite` ani historii;
- nie przejmuje umiejętności z `isUserCreated == true`, nawet gdy tytuł się zgadza; powstaje wtedy osobny rekord katalogowy;
- nie kasuje umiejętności użytkownika ani starych rekordów, których nie ma już w pliku.

Test `testCatalogReconcileAddsRowsWithoutTouchingUserProgress` przeszedł na kopii tymczasowej, nie na magazynie użytkownika.

## Teorie

W commicie `176c08e` ekran teorii miał cztery karty z kolorową obwódką i krótkim tekstem. Te zdania (`theory_20_description`, `theory_100_description`, `theory_1000_description`, `theory_10k_description`, `theory_comparison_text`) obiecywały za dużo: 1000 godzin jako próg zawodowy, 10 000 godzin jako mistrzostwo. Późniejszy ekran skrócił to do akapitów i zabrał ramki, ale pilnował ograniczeń źródeł. Żaden z tych starych kluczy nie jest już czytany przez widok. Zostały w plikach lokalizacji jako historia, nie jako treść ekranu.

Aktualny ekran to kompendium z czterema zakładkami istniejących progów: 21, 100, 1000 i 10 000. Każda zakładka ma kryształ tego progu, nagłówek, mechanizm, ramkę przykładu, ramkę zastrzeżenia, ramkę wniosku i źródła już obecne w aplikacji. Nie dodano nowych publikacji.

| Próg | Rozdział | Źródła już zapisane w aplikacji |
| --- | --- | --- |
| 21 | Przejść przez początek. 21 godzin to kolor paska, a 20 godzin to metoda Kaufmana, nie to samo twierdzenie. | Kaufman, *The First 20 Hours* (ebook 2013, paperback 2014); joshkaufman.net; Penguin Random House |
| 100 | Próg aplikacji, nie dyplom. Obok: rozłożenie sesji i nawyk, bez linii „100 godzin = kompetencja”. | Cepeda i in., Psychological Bulletin 2006, 132(3), 354–380, 317 eksperymentów; Lally i in., European Journal of Social Psychology 2010, 40, 998–1009, model 18–254 dni |
| 1000 | Celowa praktyka i różnice między dziedzinami. Kryształ nie oznacza zawodu. | Ericsson, Krampe, Tesch-Römer, Psychological Review 1993, 100(3), 363–406; Macnamara, Hambrick, Oswald, Psychological Science 2014, 25(8), 1608–1618 (gry 26%, muzyka 21%, sport 18%, edukacja 4%, zawody poniżej 1% wariancji) |
| 10 000 | Popularna liczba, nie prawo. | Gladwell, *Outliers* (2008), jako popularyzacja; Ericsson i in. 1993; Macnamara i Maitra 2019, PMC6731745 |

W tej sesji nie otwierano ponownie tych prac. Nowe akapity powtarzają ustalenia już zapisane przy tych cytowaniach i oddzielają je od progów aplikacji. Starsze zdanie, że 1000 godzin czyni profesjonalistą, jest w ramce 1000 godzin opisane jako przesada.

Kolejka, której nie domknięto: tłumaczenia nowych rozdziałów poza polskim i angielskim są kopią angielską. Stare klucze z przesadą nadal leżą w `Localizable.strings`, tylko nie są wyświetlane.

## Zakładki

Zakładki są przewijanym rzędem wystających kart. Na każdej jest liczba godzin, jednostka i kryształ. Wybrana karta jest wyższa i ma obwódkę w kolorze progu. Na wąskim ekranie rząd się przewija, tekst zostaje przy `.subheadline`.

Na macOS, kopia diagnostyczna `com.etaosin.time4skill.visual036`, po splashu widać okno i ekran „Teorie nauki”. Zakładka 21 pokazuje niebieski kryształ, dłuższy tekst, trzy ramki i linki Kaufmana. Na pasku zakładek 100 jest bursztynowy, 1000 fioletowo-tęczowy, 10 000 czerwony. Treści zakładki 10 000 nie udało się kliknąć w tej sesji; kryształ na karcie jest widoczny. W tym zrzucie nagłówek źródeł był jeszcze po angielsku („Source links”). Potem w `pl.lproj` zmieniono go na „Źródła”, a etykiety linków autora, wydawcy, Cepedy i Lally na polskie. Tego poprawionego napisu nie sprawdzono ponownie na ekranie. iOS z tym układem nie był oglądany.

## Kryształy

Jedno mapowanie: `CrystalPalette.forHours`.

Paleta z opisu wizualnego szła w kolejności sapphire, amber, arcane, crimson. Arcane to gradient wielobarwny, crimson to czerwień. Kod wcześniej wstawił crimson na 1000–10 000 i arcane od 10 000, bo tak stały stare kolory `.danger` i `.purple`. Stąd zamiana czerwieni i tęczy.

Teraz:

- 0–21 szmaragd
- 21–100 szafir
- 100–1000 bursztyn
- 1000–10 000 arcane
- od 10 000 crimson

Ten sam wynik biorą pasek, zakładka i nagłówek rozdziału. Kryształ nagrody za zdobytą umiejętność zostaje złoty i nie koduje godzin.

## Pasek

Tor, kapsuła, obwódka i refleks są te same. Wypełnienie liczy `ProgressFill.fraction` po progach 0, 21, 100, 1000, 10 000, 100 000. Przejście progu zmienia kolor, ale nie skraca słupka i nie odwraca gradientu. Zero zostawia sam tor. Spadek wartości skraca wypełnienie.

Wcześniej słupek był liczony wewnątrz progu (`godziny / sufit progu`). Zejście z 21 do 20,9 godzin skakało z około 21% na prawie pełny pasek. Test sprawdza, że 20,9 < 21 < 22 i że skok przy 21 jest mniejszy niż 5 punktów procentowych całej skali.

Ręczne zmniejszenie godzin w opcjach umiejętności było już możliwe. Nie zmieniano reguł zdobycia: odświeżenie licznika nie rusza `Skill.hours`, `obtainedAt`, oceny ani ulubionych.

## Licznik od daty

Zwykły licznik zostaje ręczny (`kindRaw` domyślnie `manual`). Drugi rodzaj, „Dni od daty”, trzyma `anchorDay`. Przycisk „Odśwież wartość” liczy różnicę dni kalendarza od początku dnia kotwicy do początku dnia „teraz”, w podanym kalendarzu i strefie. Drugie odświeżenie o tej samej chwili nie dodaje dni drugi raz. Brak daty nic nie zmienia. Data w przyszłości daje wartość ujemną, a pasek przy wartości ≤ 0 zostaje pusty.

Pasek licznika jest tą samą kapsułą. Kolor bierze się z kolejności palety według progów tego licznika, nie z udawania, że wartość to godziny umiejętności.

Test `testCounterRefreshUsesTheDateAndLeavesSkillHistoryAlone` przeszedł: 4 dni, powtórne odświeżenie zostaje przy 4, data wcześniejsza daje −2, godziny gitary 12,5 oraz data zdobycia, ocena i ulubione zostają.

Przycisku odświeżenia nie klikano w oknie. Widać go w kodzie karty i szczegółów licznika.

## Testy

Na symulatorze iPhone 16 (`247AE2B7-CD30-451C-BAFA-EAACED4AB5DD`):

- `FavoriteMigrationTests` — po poprawce asercji liczby rekordów: sukces, w tym uzgadnianie katalogu, odświeżenie licznika, paleta i ciągłość paska.
- `CatalogQueryTests` — sukces, w tym filtry, wyszukiwanie i nowe przypisanie 5000 → arcane, 20 000 → crimson.
- `SkillTests` — sukces.

Kompilacja Debug macOS `Time4SkillMacOS`: sukces. Okno kopii `visual036` pokazało kompendium, jak wyżej. iOS z nowym ekranem nie był oglądany. TestFlight nie był w tym zadaniu powtarzany.

Ostrzeżenie skryptu `failed to write .last_marketing_version` jest wcześniejsze i nie zmienia katalogu.

## Czego nie zrobiono

- Nie zaimportowano 2102 propozycji pilotażowych.
- Nie otwierano magazynu użytkownika.
- Nie kliknięto treści zakładki 10 000 ani przycisku odświeżenia w interfejsie.
- Nie oglądano tego buildu na iOS.
- Nie tłumaczono nowych rozdziałów na pozostałe języki; mają tam tekst angielski.
- Nie wykonano commita ani pusha.

## Pliki tego zadania

- `TimeToSkill/TimeToSkill/Sources/DesignSystem/Component/CrystalProgressBar.swift`
- `TimeToSkill/TimeToSkill/Sources/Views/Components/SkillProgressView.swift`
- `TimeToSkill/TimeToSkill/Sources/Views/Components/Stats/ProgressBarCompact.swift`
- `TimeToSkill/TimeToSkill/Sources/Views/Shared/SkillSeeder.swift`
- `TimeToSkill/TimeToSkill/Sources/Models/Counter.swift`
- `TimeToSkill/TimeToSkill/Sources/Views/ManageCountersView.swift`
- `TimeToSkill/TimeToSkill/Sources/Theory/TheoryContent.swift`
- `TimeToSkill/TimeToSkill/Sources/Views/TheoryView.swift`
- `TimeToSkill/TimeToSkill/Sources/Views/ExemplarySkillsView.swift`
- `TimeToSkill/TimeToSkill/Tests/TimeToSkillTests/FavoriteMigrationTests.swift`
- `TimeToSkill/TimeToSkill/Tests/TimeToSkillTests/CatalogQueryTests.swift`
- `TimeToSkill/TimeToSkill/Resources/Localization/*/Localizable.strings` (40 plików, dopisany blok T4S-036)
- `data/skills-catalog/curated/release-readiness-036.md`
