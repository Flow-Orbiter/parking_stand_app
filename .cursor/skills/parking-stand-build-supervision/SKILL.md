---
name: parking-stand-build-supervision
description: Nadzoruje proces budowy aplikacji stanowisk parkingowych (rower). Używać przy rozwijaniu parking_stand_app, implementacji flow QR/stacja/Firebase, integracji mobile–Raspberry Pi–chmura oraz przy code review lub planowaniu zadań w tym projekcie.
---

# Nadzór budowy aplikacji stanowisk parkingowych

Skill odnosi się do architektury: **User → Aplikacja mobilna (Flutter) → Stacja (czytnik QR, RASP PI, PLC) → Chmura Firebase**. Każda zmiana lub nowa funkcja powinna być weryfikowana pod kątem spójności z tym flow i wymaganiami poniżej.

## Kiedy stosować ten skill

- Pytania o to, jak coś ma działać (QR, lokalizacja, sync, rezerwacja).
- Implementacja nowych feature’ów w aplikacji mobilnej, na stacji lub w Firebase.
- Code review w tym repo.
- Planowanie zadań, sprintów lub dokumentacji.

## Architektura (streszczenie)

| Warstwa | Odpowiedzialność |
|--------|-------------------|
| **User** | Skanuje QR ze słupka (PLC otwiera miejsce) lub określa stację przez GPS/skan. |
| **Aplikacja mobilna** | Lokalizacja roweru (GPS lub wymuszony skan stacji), generowanie kodu QR (szyfrowanie kluczem publicznym), zapis transakcji lokalnie, sync do bazy gdy możliwe. |
| **Stacja** | Czytnik QR → dane do RASP PI; RASP PI weryfikuje kod (klucz prywatny), rezerwuje stanowisko, zapisuje lokalnie (ID stanowiska + ID user + kod), sync do bazy gdy możliwe. |
| **Firebase** | Centralna aktualizacja rekordów z mobile i ze stacji. |

**Ważne:** Aplikacja musi „zanotować gdzie jest rower” — inaczej na mapie nic się nie wyświetli. Lokalizacja: opcjonalnie GPS (proximity 50 m do stacji), fallback — wymuszenie skanu kodu QR ze słupka.

## Zasady budowy

### 1. Strumienie rozwoju

- **Mobile (Flutter)** — ten repo: `lib/`, integracja Firebase, GPS, generowanie QR, lokalna baza (np. sqflite/hive), sync.
- **Stacja (Raspberry Pi)** — osobny repozytorium/moduł: czytnik QR, walidacja kodu (klucz prywatny), rezerwacja stanowiska, PLC, lokalna baza, sync do Firebase.
- **Firebase** — reguły bezpieczeństwa, struktura kolekcji (stanowiska, użytkownicy, transakcje), ewentualne Cloud Functions.

Przy propozycjach zmian sprawdzać wpływ na **integrację** (format QR, payload, API) oraz **bezpieczeństwo** (klucze, nie eksponować klucza prywatnego po stronie aplikacji).

### 2. QR i bezpieczeństwo

- Aplikacja generuje kod QR **zaszyfrowany kluczem publicznym** (stacja ma klucz prywatny).
- RASP PI weryfikuje poprawność kodu (klucz prywatny) przed rezerwacją.
- **Wygaśnięcie kodów:** natychmiast po wykonaniu operacji przez RASP PI (brak ponownego użycia tego samego kodu).

Przy implementacji QR: ustalić jeden format payloadu (np. JSON: stanowisko, user, timestamp, podpis) i trzymać go kompatybilnie mobile ↔ stacja.

### 3. Lokalizacja i UX

- Określenie stacji: **opcjonalnie GPS** (proximity 50 m); **brak GPS** → wymuszenie skanu kodu QR ze słupka.
- Komunikat typu: „Włącz GPS lub zeskanuj kod QR ze słupka”.

### 4. Dane i synchronizacja

- **Mobile:** zapis transakcji lokalnie, potem „sync do bazy, jeśli możliwe”.
- **Stacja:** zapis w lokalnej bazie (ID stanowisko + ID user + kod), potem sync do Firebase.
- Oba strumienie prowadzą do **aktualizacji rekordów** w Firebase; uwzględnić konflikty (offline-first) i retry.

## Checklist przy implementacji / code review

Skopiuj i uzupełniaj w zależności od zakresu zmiany:

```
Architektura:
- [ ] Zmiana spójna z flow User → Mobile → Stacja → Firebase
- [ ] Brak wycieku klucza prywatnego po stronie aplikacji

QR i stacja:
- [ ] Format QR uzgodniony mobile ↔ RASP PI
- [ ] Wygaśnięcie kodu po użyciu przez RASP PI
- [ ] Rezerwacja stanowiska zgodnie z informacją z QR

Lokalizacja:
- [ ] Obsługa GPS (proximity 50 m) lub wymuszenie skanu stacji
- [ ] Aplikacja zapisuje „gdzie jest rower” (dla mapy)

Dane i sync:
- [ ] Zapis transakcji lokalnie (mobile i/lub stacja)
- [ ] Sync do Firebase gdy możliwe; obsługa offline/retry
- [ ] Aktualizacja rekordów w Firebase po obu stronach

Testy (w miarę implementacji):
- [ ] Generowanie/skanowanie QR, szyfrowanie/deszyfrowanie
- [ ] Logika GPS vs wymuszony skan (50 m, brak GPS)
- [ ] Zapis lokalny i synchronizacja z Firebase
- [ ] Wygaśnięcie kodu po operacji RASP PI
```

## Projekt (parking_stand_app)

- Aplikacja mobilna: **Flutter** (obecnie `lib/main.dart`, `pubspec.yaml`).
- Przy dodawaniu zależności: np. `firebase_core`, `firebase_firestore`/`firebase_realtime_database`, `geolocator` (GPS), `qr_flutter` / `mobile_scanner` (QR), lokalna baza — uzasadnić wybór w kontekście powyższej architektury.

## Dodatkowe materiały

- Szczegóły architektury i diagram flow: [reference.md](reference.md) (jeśli istnieje w tym skillu).
- Wymagania biznesowe i edge case’y (np. wygaśnięcie kodów) — ustalać z productem/chatem i odzwierciedlać w tym skillu lub w reference.
