# Mapa Google – gdy się nie wyświetla

## Chrome (Flutter Web) – najczęstsze przyczyny

1. **Włącz Maps JavaScript API**
   - [Google Cloud Console → APIs & Services → Library](https://console.cloud.google.com/apis/library) → wyszukaj **„Maps JavaScript API”** → włącz dla tego projektu.

2. **Ograniczenia klucza API (referrers)**
   - W [Credentials](https://console.cloud.google.com/apis/credentials) kliknij swój klucz.
   - W **„Ograniczenia aplikacji”** wybierz **„Odwołujące się witryny (referrery)”**.
   - W **„Odnoszące się witryny”** dodaj m.in.:
     - `http://localhost:*`
     - `http://localhost:*/`
     - `https://localhost:*`
     - (opcjonalnie) `http://127.0.0.1:*`
   - Zapisz. Bez tego mapa na localhost może się nie załadować.

3. **Sprawdź konsolę w Chrome**
   - `flutter run -d chrome` → w przeglądarce **F12 → zakładka Console**.
   - Błąd typu **„This page can't load Google Maps correctly”** lub **„RefererNotAllowedMapError”** = problem z kluczem lub z włączonym API / referrerami.
   - Błędy CORS lub 403 od `maps.googleapis.com` też wskazują na konfigurację klucza lub API.

4. **Renderer Flutter Web**
   - Jeśli mapa dalej jest pusta, spróbuj:
     - `flutter run -d chrome --web-renderer html`
     - lub `flutter run -d chrome --web-renderer canvaskit`
   - Czasem jeden z rendererów poprawnie pokazuje mapę.

5. **Pełny restart po zmianach w GCP**
   - Po włączeniu API lub zmianie ograniczeń odczekaj 1–2 minuty, zatrzymaj aplikację i uruchom ponownie `flutter run -d chrome`.

---

## Inne platformy

- **Android:** włącz **Maps SDK for Android** w GCP; klucz w `AndroidManifest.xml` (już ustawiony).
- **iOS:** włącz **Maps SDK for iOS** w GCP; klucz w `AppDelegate.swift` (już ustawiony).

---

## Layout

Mapa jest w `LayoutBuilder` z jawnymi `width`/`height` – to pomaga na webie. Jeśli ekran nadal jest pusty, w 99% przypadków chodzi o klucz API lub włączone API / referrery w GCP.
