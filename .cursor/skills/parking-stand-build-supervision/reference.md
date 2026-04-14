# Referencja: architektura aplikacji stanowisk parkingowych

## Przepływ (flow)

1. **User** wczytuje kod QR z konkretnego stanowiska parkingowego → PLC otwiera wskazane miejsce.
2. **Cel aplikacji:** zanotować, gdzie jest rower — inaczej na mapie nic się nie pokaże.
3. **Lokalizacja:** opcjonalnie stacja określana przez GPS; brak GPS → wymuszenie skanu stacji. Proximity 50 m. Komunikat: „Włącz GPS lub zeskanuj kod QR ze słupka”.
4. **Mobile:** generuje kod QR (zaszyfrowany kluczem publicznym), pokazuje go do skanera, zapisuje transakcję lokalnie, sync do bazy gdy możliwe.
5. **Stacja:** czytnik QR → dane do RASP PI; RASP PI weryfikuje kod (klucz prywatny), rezerwuje stanowisko zgodnie z QR, zapisuje w lokalnej bazie (ID stanowisko + ID user + kod), sync do bazy gdy możliwe.
6. **Firebase:** aktualizacja rekordów z mobile i ze stacji.

## Wygaśnięcie kodów QR

- **Kiedy:** natychmiast po wykonaniu operacji przez RASP PI.
- Do ustalenia z productem/chatem szczegóły (np. TTL przed skanem).

## Komponenty do budowy

| Komponent | Technologie / uwagi |
|-----------|----------------------|
| Aplikacja mobilna | Flutter, Firebase SDK, GPS (geolocator), QR (generowanie + ewentualnie skan), lokalna baza, sync |
| Stacja | Czytnik QR, Raspberry Pi (walidacja klucz prywatny, PLC), lokalna baza, sync do Firebase |
| Chmura | Firebase (Firestore lub Realtime Database), reguły bezpieczeństwa, ewent. Cloud Functions |

## Integracja

- Jeden uzgodniony format payloadu w QR (np. stanowisko, user id, timestamp, podpis).
- Klucz publiczny w aplikacji — tylko generowanie/szyfrowanie.
- Klucz prywatny tylko na RASP PI — weryfikacja i rezerwacja.
