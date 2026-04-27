# Cache stacji (offline / online) i skanowanie QR

Dokument opisuje zachowanie zaimplementowane w aplikacji Flutter (`mdm_sport`): skąd bierze się lista stacji, jak działa zapis lokalny (Hive) oraz co dokładnie dzieje się po zeskanowaniu kodu ze słupka.

## Krótki przegląd

| Warstwa | Rola |
|--------|------|
| **`stations_repository`** | Jedna lista stacji w RAM (`kStations`), powiadomienia UI przez `stationsDataRevision`. `setStations` może też **wyczyścić** listę i Hive (pusta lista z syncu / live); `upsertStation` zapisuje Hive **po `await`**. |
| **`AppStorage` (Hive)** | Trwały cache listy stacji pod kluczem `stations` + m.in. `lastBikeStationId`, rezerwacje, język. |
| **`StationsSyncService`** | Pobranie listy z Cloud Firestore (`stations` / `Stations`), zapis cache, nasłuch na żywo. |
| **`QrScannerScreen` + `qr_payload`** | Odczyt QR słupka → `stationId` + `slot` → dopasowanie stacji → ekran parkowania / odbioru. |

---

## 1. Start aplikacji: offline najpierw, potem online

Kolejność w `main.dart`:

1. **`AppStorage.init()`** — otwarcie skrzynki Hive.
2. **`await initializeStationsFromCache()`** (w `main` po `AppStorage.init`) — jeśli w Hive jest niepusta lista `cachedStations`, jest ona parsowana do modeli `Station` i ładowana do `stations_repository` przez **`setStations(..., persistToHive: false)`** (bez ponownego zapisu tego samego do Hive).  
   Dzięki temu **mapa i wyszukiwarka mogą pokazać ostatnio zsynchronizowane stacje bez sieci** (o ile cache nie jest pusty).
3. Inicjalizacja Firebase (gdy się uda).
4. **`StationsSyncService().syncStationsFromFirestore()`** — próba pobrania świeżej listy z serwera.

Jeśli Firebase nie wystartuje, aplikacja nadal może korzystać z danych wczytanych z Hive z poprzedniej sesji.

---

## 2. Tryb online — synchronizacja z Firestore

**Serwis:** `lib/data/stations_sync_service.dart`

- Sprawdzane są kolekcje w kolejności: `stations`, potem `Stations`.
- Używany jest odczyt ze **`Source.server`** (świadome pobranie z backendu, nie tylko lokalny cache SDK).
- Dokumenty są mapowane na `Station` tylko wtedy, gdy **uda się wyciągnąć `lat` i `lng`** (różne konwencje pól: `lat`/`lng`, `GeoPoint`, `coordinates` itd.).  
  Dokument **bez współrzędnych nie trafia** do listy przy pełnym syncu — wtedy marker na mapie z tego dokumentu się nie pojawi.
- Po udanym syncu:
  - lista w pamięci jest ustawiana przez **`setStations(parsed)`**,
  - Hive jest aktualizowany: **`AppStorage.setCachedStations(...)`** (pełna lista jako mapy),
  - startuje **`startLiveStationsSync()`** — nasłuch `snapshots()` na aktywnej kolekcji; przy zmianach w Firestore lista i cache są odświeżane.

**Po zalogowaniu** (`main.dart`, `_PostAuthStationSyncLoader`) sync jest ponowiony z aktualnym użytkownikiem (token), zgodnie z regułami Firestore (`read` dla `stations` przy `request.auth != null`).

**Mapa** przy wejściu może dodatkowo wywołać `syncStationsFromFirestore()` (odświeżenie).

---

## 3. Cache offline (Hive)

**Plik:** `lib/data/local/app_storage.dart`

- Lista stacji: **`cachedStations`** / **`setCachedStations`** — lista map zgodnych z `Station.toMap()` (`id`, `name`, `address`, `city`, `lat`, `lng`).
- Zapisy cache następują m.in. gdy:
  - zakończy się **udany pełny sync** z Firestore,
  - **`upsertStation`** doda lub zaktualizuje stację (np. po **`resolveStationForQrScan`** — patrz niżej); wtedy zapisywana jest **cała bieżąca lista** w pamięci.

Dzięki temu stacja „dociągnięta” przy skanie QR trafia do Hive i **po restarcie aplikacji może być dostępna offline** (o ile była wcześniej zapisana).

---

## 4. Dopasowanie `stationId` (normalizacja)

**Plik:** `lib/data/stations_repository.dart`

- **`normalizeStationId`** — `trim()` identyfikatora.
- **`getStationById`** porównuje stacje po znormalizowanym `id`.
- W **`qr_payload`** pole `stationId` z JSON jest również normalizowane przy budowie **`PoleQrPayload`**.

To ogranicza błędy typu spacje wokół tego samego ID w QR vs w bazie.

---

## 5. Resolver przy skanie QR (gdy nie ma stacji w pamięci)

**Metoda:** `StationsSyncService.resolveStationForQrScan(rawStationId)`

Wywoływana jest **tylko wtedy**, gdy **`getStationById`** zwróci `null` (stacja nie ma wpisu w aktualnej liście w RAM).

Działanie (uproszczenie):

1. Ponowne sprawdzenie pamięci (po normalizacji ID).
2. Odświeżenie tokenu użytkownika (best effort).
3. Dla kolekcji `stations` i `Stations`:
   - odczyt dokumentu **`doc(id)`** (ścieżka = znormalizowany `stationId` z QR),
   - jeśli brak — zapytania **`where`** z polami **`stationId`**, **`id`**, **`station_id`** (limit 1 każde).
4. Odczyty używają **`GetOptions(source: Source.serverAndCache)`** — przy braku sieci możliwy jest traf z lokalnego cache Firestore (np. po wcześniejszym syncu).
5. Parsowanie dokumentu z flagą **`allowPlaceholderCoordinates: true`**:  
   jeśli w dokumencie **nie ma `lat`/`lng`**, używane są **tymczasowe współrzędne** (stała w kodzie — okolice Wrocławia), żeby można było zbudować `Station` i kontynuować flow.  
   **Zalecenie operacyjne:** uzupełnić prawdziwe współrzędne w Firestore, żeby mapa była poprawna.
6. Po sukcesie: **`upsertStation`** (RAM + zapis Hive całej listy).

**Wymagania:** zalogowany użytkownik z prawem odczytu kolekcji stacji. **Całkiem nowa** stacja bez wpisu w cache Firestore nadal wymaga połączenia z backendem; przy słabej sieci `serverAndCache` zwiększa szansę na odczyt z lokalnego cache SDK.

---

## 6. Skanowanie QR ze słupka

**Ekran:** `lib/screens/qr_scanner_screen.dart`  
**Format ładunku:** `lib/data/qr_payload.dart`

### 6.1. Co musi zawierać QR słupka

Z perspektywy aplikacji potrzebny jest **JSON** z:

- identyfikatorem stacji: **`stationId`** lub **`id`** (aliasy w kodzie),
- **`slot`** — numer stanowiska (liczba całkowita ≥ 1; obsługiwane są też literówki / aliasy pól po stronie parsowania).

Dopuszczalne formy wejścia (jak w komentarzach w `qr_payload.dart`):

- Base64 (zwykły lub po **obfuskacji** cyfr base64 — zgodnie z czytnikiem / stacją),
- surowy JSON w stringu,
- fragment w **URL** (query / path / fragment).

Po sparsowaniu powstaje **`PoleQrPayload(stationId, slot)`**.

### 6.2. Krok po kroku w UI

1. **`mobile_scanner`** dostarcza surowy tekst z kodu.
2. **`parsePoleQrPayloadFromBase64`** (nazwa historyczna — obsługuje też nie-Base64 zgodnie z logiką pliku) buduje **`PoleQrPayload`** lub zwraca `null` (wtedy skan jest ignorowany).
3. Włącza się stan **„Szukanie stacji…”** (`_resolving`), kamera jest zatrzymywana po pierwszym poprawnym payloadzie.
4. **`getStationById(pole.stationId)`** — szybka ścieżka z pamięci/cache startowego.
5. Jeśli brak — **`resolveStationForQrScan`** (sieć + Firestore).
6. Jeśli nadal brak stacji — komunikat **„Nieznana stacja w aplikacji”** i powrót z ekranu skanera.
7. Jeśli jest **`Station`** — **`pushReplacement`** do:
   - **`StationParkOpenStepScreen`** (flow „Zaparkuj”) lub
   - **`StationPickupScreen`** (flow „Odbierz”),  
   w zależności od `StationEntryFlow`, z przekazaniem **`initialSlot`** z QR.

### 6.3. QR generowany przez aplikację (czytnik stacji)

To **osobny** format: JSON z **`action`** (`open` / `close` w enumie), **`stationId`**, **`slot`**, **`ts`**, **`deviceId`** oraz kodowanie Base64 + ta sama obfuskacja co wyżej — używany na ekranach parkowania / odbioru do pokazania kodu **otwarcia** czytnikowi.  
Obecny produkt UX skupia się na kodzie **`open`**; zamknięcie rygla jest opisane jako czynność ręczna przy stacji.

### 6.4. Weryfikacja: co naprawdę jest w QR ze stacji

**Dekodowanie Base64 (macOS/Linux)** — jednoznacznie pokazuje `stationId` i `slot` zakodowane w ciągu:

```bash
printf '%s' 'WKLEJ_TUTAJ_CIĄG_Z_QR' | base64 -d
```

Wynik tekstowy musi być **identyczny** z tym, co trafia do pól w Firestore (ten sam `stationId` — bez „poprawek” przy przepisywaniu, np. **J** vs **Z**, **SFR** vs **SVR**).

**Lista kontrolna przy integracji generatora na stacji:**

- Porównać **rzeczywiste bajty JSON** wysyłane do `base64.encode` z wartością `stationId` pokazywaną w formularzu (częsty błąd: w podglądzie jedna zmienna, a do JSON idzie inna).
- Ustalić, czy w QR jest **zwykły** Base64(UTF-8 → JSON), czy najpierw Base64 a potem **obfuskacja** znaków jak w [`qr_payload.dart`](lib/data/qr_payload.dart): przy samym obfuskowanym ciągu zwykle **nie** dekoduje się go „gołym” `base64 -d` do czytelnego JSON — wtedy trzeba najpierw zastosować odwrotną obfuskację. Ciąg zaczynający się jak `eyJ…` zwykle oznacza **nieobfuskowany** Base64 JSON.
- Opcjonalnie: porównać hex skanu z oczekiwanym łańcuchem po stronie stacji.

### 6.5. Ujednolicenie z Firestore

Dokument w Firestore (`stations/{documentId}` lub pole `stationId` / `id` / `station_id`) musi używać **dokładnie** tego samego `stationId`, który wynika z dekodowania QR (patrz §6.4). Jeśli w panelu widzisz inny alias niż w wyniku `base64 -d`, popraw **dane w konsoli** albo **wygeneruj ponownie** QR z JSON-em zgodnym z bazą — aplikacja **nie** mapuje podobnych stringów na siłę.

---

## 7. Podsumowanie zależności offline / online

- **Mapa i lista stacji w aplikacji** = zawartość **`kStations`**, inicjalizowana z Hive, potem (gdy jest sieć i auth) aktualizowana z Firestore.
- **Skan QR bez wpisu w `kStations`** — resolver Firestore (`serverAndCache`) + ewentualnie wcześniejszy sync / `upsertStation`; przy pierwszym kontakcie z dokumentem zwykle potrzebna jest sieć.
- **Hive** utrwala ostatnią znaną pełną listę oraz aktualizacje po `upsertStation`, co poprawia **działanie po restarcie bez natychmiastowego syncu**.

---

## 8. Diagnostyka: „Nieznana stacja” po skanie

Sprawdź po kolei:

1. **Projekt Firebase** — `google-services.json` / `GoogleService-Info.plist` / `firebase_options.dart` muszą wskazywać ten sam projekt co dane w konsoli.
2. **Firestore, nie Realtime Database** — aplikacja nie czyta RTDB pod ścieżką stacji.
3. **Kolekcja root** — dokument ma być w **`stations/{id}`** lub **`Stations/{id}`** (wielkość litery jak wyżej), **albo** dowolny dokument w tej kolekcji z polem **`stationId`**, **`id`** lub **`station_id`** równym identyfikatorowi z QR (ten sam string co w komunikacie błędu / w zdekodowanym JSON).
4. **Typ pola** — w konsoli pole powinno być **stringiem** zgodnym z QR (nie liczba, jeśli w QR jest tekst).
5. **Podkolekcje** — jeśli stacje są np. pod `foo/bar/stations/...`, obecny resolver ich nie przeszukuje; trzeba przenieść dane do root `stations` lub uzgodnić osobną ścieżkę w kodzie.
6. **Debug** — w trybie `kDebugMode`: po udanym parsowaniu QR log **`QrScannerScreen: parsed pole stationId=… slot=…`**; przy resolverze także logi `StationsSyncService` (`get` / `where` / `no station for id="..."`).

---

## 9. Realtime Database i podkolekcje (poza plan minimum)

Integracja **Realtime Database** lub **niestandardowych ścieżek** (podkolekcje, inna nazwa kolekcji) **nie jest** w kodzie domyślnie — wymaga uzgodnionego schematu i osobnej implementacji (świadomie nie zaimplementowano bez uzgodnionej struktury danych).

---

## 10. Pliki źródłowe (odniesienia)

| Temat | Plik |
|--------|------|
| Lista w RAM, `getStationById`, `upsertStation`, cache startowy | `lib/data/stations_repository.dart` |
| Hive, `cachedStations` | `lib/data/local/app_storage.dart` |
| Sync Firestore, resolver, placeholder współrzędnych | `lib/data/stations_sync_service.dart` |
| Start: cache → Firebase → sync | `lib/main.dart` |
| Skaner, kolejność lookup → resolver | `lib/screens/qr_scanner_screen.dart` |
| Format QR słupka i aplikacji | `lib/data/qr_payload.dart` |
