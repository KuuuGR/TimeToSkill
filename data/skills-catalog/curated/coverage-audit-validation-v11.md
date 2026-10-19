# Walidacja audytu pokrycia v11

Sprawdzenie spójności plików audytu. Propozycji nie zmieniano.

- Sklasyfikowane rekordy: 1122.
- Unikalne identyfikatory: 1122.
- Powtórzone identyfikatory: 0.
- Suma dziedzin: 1122.
- Suma poddziedzin: 1122.
- Zgodność z liczbą propozycji: True.
- Każdy rekord ma jedną dziedzinę i jedną poddziedzinę: tak.
- Pewność low: 0. Pewność medium: 254. Oznaczone w taksonomii.
- Przykłady spoza katalogu: 0.
- Skupiska w pliku: 10.
- v9, v10, v11, rejestr ryzyk i rejestr luk: skróty SHA-256 sprzed zapisu audytu porównane po zapisie. Bez zmian.
- Walidatorów katalogu nie zmieniano i nie uruchamiano ich na propozycjach, bo treść propozycji została nietknięta.
- `git diff --check` w katalogu repozytorium zakończył się kodem 0. Pięć plików audytu jest nowych i nieśledzonych, więc to polecenie ich nie skanuje. Osobne sprawdzenie tych plików nie znalazło końcowych spacji ani znaczników konfliktu.

Procenty w raporcie są zaokrąglone do jednego miejsca. Suma procentów może zejść się z 100 tylko w przybliżeniu. Liczniki są dokładne.
