# T4S-CATALOG-034 — gotowość wydania

Data: 2026-10-19. Gałąź `Time4Skill-MacOS`. Bez commita i bez pusha. Propozycje pilotażowe nie są umiejętnościami produkcyjnymi.

## Co obejrzano w działającej aplikacji

Symulator iPhone 16 (`247AE2B7-CD30-451C-BAFA-EAACED4AB5DD`, iOS 18.3.1), język polski. Zrzuty są w `/tmp/t4s-034-ui/`.

- `01-skills-pl.png` — ekran Umiejętności: pole „Szukaj umiejętności”, chipy Wszystkie / Wykonane / Niewykonane / Ulubione, osobny wiersz „Sortuj”. Serca konturowe są oddzielone od menu z wielokropkiem. Polskie tytuły łamią się w dwóch liniach.
- `02-no-results.png` — zapytanie `zzzz-brak`. Komunikat „Brak umiejętności dla tych filtrów.” jest na pełnej szerokości. Widoczne „Wyczyść”.
- `03-reset.png` — po wyczyszczeniu wraca siatka i znika „Wyczyść”.
- `04-progress-zero.png` — tracker o nazwie z żółcią i łódką. Przy 0 h widać tylko ciemny tor, bez wypełnienia. Długa nazwa jest obcięta wielokropkiem w jednej linii.
- `05-crystal-favorite.png` — karta „Brzuszki – kamień milowy” ma wypełnione serce, złoty kryształ i wstążkę dwóch złotych gwiazdek oraz jednej pustej. Pozostałe karty mają puste serca i nie mają kryształu. Kryształ nie zastępuje gwiazdek.
- `06-glass-bars.png` — „Szklany pasek szafirowy” 50 h 0 m, wypełnienie niebieskie do około połowy toru; „Szklany pasek szmaragdowy” 12 h 30 m, wypełnienie zielone wyraźnie dalej. Próbka pikseli kolumny wypełnienia spada od niemal białego wierzchu do ciemnej podstawy, więc pasek nie jest płaską kapsułą jednego koloru.
- `07-relaunch-favorites.png` — po ubiciu i ponownym uruchomieniu pole szukania jest puste, chip Ulubione zostaje włączony razem z Wszystkie, widać „Wyczyść” i pusty wynik. Wszystkie oznacza status wykonania, nie wyłącza filtra ulubionych.
- `08-reset-after-relaunch.png` — „Wyczyść” przywraca siatkę i chowa się.

Nie obejrzano okna macOS. Zbudowano Debug `Time4SkillMacOS` i uruchomiono wyłącznie kopię z identyfikatorem `com.etaosin.time4skill.visual034`. Proces doszedł do pętli AppKit, powstał osobny kontener, ale nie pojawiło się okno, więc nie ma zrzutu ani drugiego rozmiaru okna. Magazyn użytkownika `~/Library/Containers/com.etaosin.time4skill/.../default.store` miał ten sam czas modyfikacji przed uruchomieniem i po nim (`1790663998`). Pliki testowego magazynu usunięto. Została tylko systemowa plista metadanych kontenera `visual034`, której system nie pozwolił skasować.

Nie przełączano systemowego ograniczenia ruchu. W kodzie animacja paska jest wyłączana, gdy środowisko zgłasza `accessibilityReduceMotion`. Klatka statyczna tego nie potwierdza.

Kolory bursztynowy, karmazynowy i fioletowy nie były na ekranie. Na ekranie widać szmaragd przy 12,5 h i szafir przy 50 h, czyli progi 0–21 h i 21–100 h.

Katalog 2102 propozycji nie jest w aplikacji. Ekran umiejętności pokazuje zasiany katalog, około 38 pozycji.

## Migracja SwiftData

Model nie ma `VersionedSchema` ani `SchemaMigrationPlan`. Aplikacja otwiera magazyn przez `.modelContainer(for:)` bez własnego adresu pliku. `isFavorite` ma domyślną wartość `false`. Seeder nie nadpisuje ulubionych, oceny, daty zdobycia ani flagi zdobycia.

`FavoriteMigrationTests` otwiera izolowany plik, nie magazyn użytkownika.

- Nowy rekord: ulubione `false`, po ponownym otwarciu zostają godziny 12,5, nazwa, data zdobycia i ocena. Ustawienie ulubionych nie zmienia godzin ani daty.
- Stary magazyn: kopia bazy symulatora sprzed kolumny ulubionych (`Tests/TimeToSkillTests/Fixtures/pre-favorite.store`, 38 rekordów, brak `ZISFAVORITE`). Bieżący model otworzył ją, wszystkie ulubione były `false`, opisy zostały, po zapisie ulubionych i ponownym otwarciu zostało 38 rekordów. Test trwał 2,776 s i przeszedł.

To jest otwarcie prawdziwego starszego pliku, nie sama kompilacja. To nie jest otwarcie jedynej bazy użytkownika na Macu. Brak jawnego planu migracji zostaje ryzykiem przy następnej zmianie schematu, która nie będzie lekkim dodaniem pola z wartością domyślną.

## Historia katalogu

Nie zmieniano v4, v5, v9 ani v10.

- v4 ma 116 wierszy, v5 ma 123. v5 nie jest dopiskiem bajtów v4. Żaden identyfikator z v4 nie zniknął. Doszło 7 identyfikatorów. Dwa wspólne rekordy różnią się tylko polami `levels` i `provenance_note`: `general-practical-skills:capture-speech-in-shorthand` oraz `general-practical-skills:compare-equipment-before-buying`. To rewizja treści, nie utrata rekordów i nie zmiana schematu.
- v9 ma 1001 wierszy, v10 ma 995. v10 nie dopisuje nic nowego. Sześć identyfikatorów jest w v9 i nie ma ich w v10–v22. `curated/merge-history-v10.json` opisuje je jako scalenia (`destructive: false`, `proposals_deleted_from_v9: 0`). v9 nie był edytowany. Cele scaleń są nadal w v22. Wiersze źródłowe zostają w plikach pack-15. To migawka redakcyjna, nie cicha utrata. Nie przywracano tych sześciu rekordów.

v22 zaczyna się bajtami v21. v21 ma 2101 wierszy, v22 ma 2102.

## Testy i budowa

Przeszły, symulator iPhone 16:

- `CatalogQueryTests` — 11 testów, w tym szukanie z ulubionymi i statusem wykonania, daty braku na końcu przy obu kierunkach, fragmenty opisu i kryterium, reset jako zapytanie domyślne, 4000 rekordów w 0,269 s.
- `FavoriteMigrationTests` — oba testy, w tym stary magazyn.
- `CatalogScreenUITests` — trzy testy po poprawce asercji. Pierwsze uruchomienie testu wznowienia padło, bo zakładało, że chip Wszystkie gaśnie po włączeniu Ulubionych. Te chipy są niezależne. Poprawiono test i uruchomiono go ponownie. Przeszedł.

`xcodebuild build` Debug, schemat `Time4SkillMacOS`, macOS: BUILD SUCCEEDED. Okna nie było.

Walidacja `pilot-proposals-v22.jsonl`: 0 błędów, 0 ostrzeżeń, 2102 rekordy, same `pilot_proposal`. Plik zatwierdzony pack-27: 0 błędów. Liczba produkcyjna: 0.

Skrypt wersji katalogu przy budowie iOS zgłosił brak prawa zapisu do `.last_marketing_version` i zaktualizował 0 plików. Wersji marketingowej nie zmieniano.

## Naprawione w tej kontroli

- Pusty wynik filtrów stał w jednej kolumnie siatki. Jest nad siatką, na pełnej szerokości. Potwierdzone zrzutem.
- „Sortuj” i „Wyczyść” były ściśnięte w poziomym pasku chipów. Mają własny wiersz. Potwierdzone zrzutem.
- Chip filtra dostaje cechę dostępności „zaznaczony”, gdy jest włączony.
- Doszedł test otwarcia magazynu sprzed kolumny ulubionych.
- W Debug, tylko z argumentem `-T4SPreviewProgress`, aplikacja dodaje dwa trackery (12,5 h i 50 h) oraz oznacza jedną zasianą umiejętność jako zdobytą i ulubioną. Wydanie Release tego kodu nie zawiera. Służy do obejrzenia paska i kryształu.

## Odkrywanie

`https://rsnstitchbank.org/stitch/couching` znowu zwróciło pustą treść. Nie oznaczono jej jako otwartej.

Otwarto `https://rsnstitchbank.org/stitch/couching-stitch` (Royal School of Needlework). Jedna nowa propozycja pilotażowa: `Couch a laid thread`, pochodzenie `practice-expansion-27`, plik v22. Wariantów bunched, Romanian i underside nie otwierano i nie dopisywano. Glosariusz origami i esej o geometrii zgięć nie są stroną metody. Nie ma z nich nowej propozycji.

Unikalni przeanalizowani kandydaci programu: 651. Luki ściegów, origami i wariantów zostają otwarte.

## Ryzyka

- Baza użytkownika na Macu nie była otwierana. Migracja jest sprawdzona na kopii bazy symulatora i na nowym pliku tymczasowym.
- Brak jawnego planu migracji SwiftData.
- Ograniczenie ruchu nie było włączone w systemie.
- Nie obejrzano macOS ani drugiego rozmiaru telefonu.
- Paski bursztynowy, karmazynowy i fioletowy nie były na ekranie.
- Aplikacja nie pokazuje 2102 propozycji. Test 4000 rekordów dotyczy funkcji filtrowania w pamięci, nie siatki SwiftUI.
- Krótki adres couching nadal jest pusty. Ściana ściegów i glosariusz origami nie są wyczerpane.
