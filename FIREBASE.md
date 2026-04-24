# Połączenie projektu z Firebase (jednorazowo)

**Projekt w repozytorium:** `mdm-sport` (zapis w `.firebaserc`).  
**Nr projektu w Google Cloud:** 435452635733 — pojawi się w wygenerowanych plikach.

W aplikacji są już: `firebase_core`, `firebase_auth`, `cloud_firestore`, plugin `google-services` w Gradle.

## 1. W [Firebase Console](https://console.firebase.google.com)

1. Otwórz **swój** projekt (tę „gotową” bazę).
2. W **Ustawienia projektu** → *Twoje aplikacje* upewnij się, że istnieją:
   - **Android** — jeśli brakuje: *Dodaj aplikację* → **package name:** **`com.floworbiter.baps`**
   - **iOS** — *Dodaj aplikację* → **Bundle ID:** `com.floworbiter.baps`
3. W **Authentication** włącz e-mail/telefon/Google/Apple zgodnie z tym, co używasz.
4. W **Firestore** (jeśli używasz) reguły muszą zezwalać na odczyt/zapis właściwy dla użytkowników (np. `request.auth.uid`).

5. **Flutter Web + logowanie telefonem:** `lib/firebase_options.dart` musi mieć sekcję `web` z prawdziwym `apiKey` (generuje `flutterfire configure --platforms=android,ios,web`). Bez tego w przeglądarce widać błąd `key=REPLACE` przy reCAPTCHA. W **Authentication → Ustawienia → Domeny autoryzowane** dodaj host, na którym hostujesz apka (dla dev zwykle jest `localhost`).

## 2. W terminalu (w katalogu repo `mdm_sport`)

1. [Firebase CLI](https://firebase.google.com/docs/cli#install_the_firebase_cli) musi być zainstalowany: `npm i -g firebase-tools`
2. Logowanie (jednorazowo):

   ```bash
   firebase login
   firebase projects:list
   ```

   W liście musi być **mdm-sport**. Jeśli `projects:list` zwraca błąd, nie przejdzie też `flutterfire`.

3. Generacja plików (ID jest już ustalone):

   ```bash
   chmod +x tool/flutterfire_connect.sh
   ./tool/flutterfire_connect.sh mdm-sport
   ```

Polecenie nadpisze: `lib/firebase_options.dart`, `android/app/google-services.json`, doda `ios/Runner/GoogleService-Info.plist`.

## 3. iOS

```bash
cd ios && pod install && cd ..
```

Dla **logowania Google** na iOS: w pliku `GoogleService-Info.plist` znajdź `REVERSED_CLIENT_ID` i w Xcode, w targecie Runner, **URL Types** dodaj tę samą wartość jako *URL Schemes* (FlutterFire opisuje to po `configure`).

Dla **Sign in with Apple**: włącz capability w Xcode (Signing & Capabilities).

## 4. Android

W konsoli **Firebase** → *Ustawienia projektu* → *Twoje aplikacje* → Android: dodaj **odcisk SHA-1** (i ewent. SHA-256) certyfikatu **debug** i **release** (`cd android && ./gradlew signingReport`).

## 5. Test

```bash
flutter run
```

Jeśli `Firebase.initializeApp` nadal zgłasza błąd, uruchom ponownie `flutterfire configure` z tym samym ID lub sprawdź, czy ID aplikacji w konsoli = dokładnie `com.floworbiter.baps` (Android i iOS).
