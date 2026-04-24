/// Klucze tłumaczeń – wszystkie teksty UI w jednym miejscu.
abstract final class AppStrings {
  static const String loginEnter = 'loginEnter';
  static const String loginPhoneTitle = 'loginPhoneTitle';
  static const String loginPhoneHint = 'loginPhoneHint';
  static const String loginPhoneInvalid = 'loginPhoneInvalid';
  static const String loginPhoneNoCode = 'loginPhoneNoCode';
  static const String loginPhoneSendCode = 'loginPhoneSendCode';
  static const String loginPhoneCodeHint = 'loginPhoneCodeHint';
  static const String loginPhoneVerify = 'loginPhoneVerify';
  static const String authModeLogin = 'authModeLogin';
  static const String authModeRegister = 'authModeRegister';
  static const String registerPhoneTitle = 'registerPhoneTitle';
  static const String registerPhoneLead = 'registerPhoneLead';
  static const String registerPhoneSubmit = 'registerPhoneSubmit';
  static const String profileSetupTitle = 'profileSetupTitle';
  static const String profileSetupSubtitle = 'profileSetupSubtitle';
  static const String profileSetupNameLabel = 'profileSetupNameLabel';
  static const String profileSetupNameHint = 'profileSetupNameHint';
  static const String profileSetupEmailLabel = 'profileSetupEmailLabel';
  static const String profileSetupEmailHint = 'profileSetupEmailHint';
  static const String profileSetupEmailError = 'profileSetupEmailError';
  static const String profileSetupSave = 'profileSetupSave';
  static const String profileSetupNameError = 'profileSetupNameError';
  static const String mapDrawerName = 'mapDrawerName';
  static const String loginPhoneMandatoryInfo = 'loginPhoneMandatoryInfo';
  static const String phoneRequiredTitle = 'phoneRequiredTitle';
  static const String phoneRequiredBody = 'phoneRequiredBody';
  static const String phoneRequiredSignOut = 'phoneRequiredSignOut';
  static const String phoneRequiredSubmit = 'phoneRequiredSubmit';
  static const String loginOrDivider = 'loginOrDivider';
  static const String loginWithGoogle = 'loginWithGoogle';
  static const String loginWithApple = 'loginWithApple';
  static const String loginAuxHint = 'loginAuxHint';
  static const String legalPrivacyPolicy = 'legalPrivacyPolicy';
  static const String helpPrivacySiteLabel = 'helpPrivacySiteLabel';
  static const String loginFirebaseMissing = 'loginFirebaseMissing';
  static const String loginLanguagePl = 'loginLanguagePl';
  static const String loginLanguageEn = 'loginLanguageEn';
  static const String mapSearchHint = 'mapSearchHint';
  static const String mapGpsMessage = 'mapGpsMessage';
  static const String mapPark = 'mapPark';
  static const String mapReceive = 'mapReceive';
  static const String mapMenu = 'mapMenu';
  static const String mapDrawerProfile = 'mapDrawerProfile';
  static const String mapDrawerEmail = 'mapDrawerEmail';
  static const String mapDrawerPhone = 'mapDrawerPhone';
  static const String mapDrawerFieldEmpty = 'mapDrawerFieldEmpty';
  static const String mapDrawerLanguage = 'mapDrawerLanguage';
  static const String mapDrawerHelp = 'mapDrawerHelp';
  static const String mapHelpReportTitle = 'mapHelpReportTitle';
  static const String helpReportPhone = 'helpReportPhone';
  static const String helpReportEmail = 'helpReportEmail';
  static const String mapDrawerLogout = 'mapDrawerLogout';
  static const String mapHelpLinkError = 'mapHelpLinkError';
  static const String qrScanVehicle = 'qrScanVehicle';
  static const String qrCancel = 'qrCancel';
  static const String qrOk = 'qrOk';
  static const String qrInvalidCode = 'qrInvalidCode';
  static const String qrStationNotInApp = 'qrStationNotInApp';
  static const String parkOpenPageTitle = 'parkOpenPageTitle';
  static const String parkOpenShort = 'parkOpenShort';
  static const String parkOpenNextButton = 'parkOpenNextButton';
  static const String parkClosePageTitle = 'parkClosePageTitle';
  static const String parkFlowQrOpenCaption = 'parkFlowQrOpenCaption';
  static const String parkFlowQrCloseCaption = 'parkFlowQrCloseCaption';
  static const String parkFlowCloseBeforeQr = 'parkFlowCloseBeforeQr';
  static const String parkFlowSlotHint = 'parkFlowSlotHint';
  static const String parkFlowDoneButton = 'parkFlowDoneButton';
  static const String pickupTitle = 'pickupTitle';
  static const String pickupOpenCaption = 'pickupOpenCaption';
  static const String pickupIntro = 'pickupIntro';
  static const String pickupFlowSlotHint = 'pickupFlowSlotHint';
  static const String pickupFlowDoneButton = 'pickupFlowDoneButton';
  static const String pickupLockNowButton = 'pickupLockNowButton';
  static const String pickupClosePageTitle = 'pickupClosePageTitle';
  static const String pickupCloseCaption = 'pickupCloseCaption';
  static const String pickupCloseBeforeQr = 'pickupCloseBeforeQr';
  static const String reservationsTitle = 'reservationsTitle';
  static const String reservationsEmpty = 'reservationsEmpty';
  static const String reservationsStart = 'reservationsStart';
  static const String reservationsDuration = 'reservationsDuration';
  static const String reservationsEnd = 'reservationsEnd';
  static const String reservationsNavigate = 'reservationsNavigate';
  static const String reservationsEndButton = 'reservationsEndButton';
  static const String appTitle = 'appTitle';
}

final Map<String, String> _pl = {
  AppStrings.legalPrivacyPolicy: 'Polityka prywatności',
  AppStrings.helpPrivacySiteLabel: 'sport.mdm-electronic.com',
  AppStrings.loginEnter: 'Wejdź do mapy',
  AppStrings.loginPhoneTitle: 'Numer telefonu',
  AppStrings.loginPhoneHint: '+48 000 000 000',
  AppStrings.loginPhoneInvalid: 'Podaj poprawny numer, np. +48 728 553 487',
  AppStrings.loginPhoneNoCode: 'Najpierw wyślij kod SMS',
  AppStrings.loginPhoneSendCode: 'Wyślij kod SMS',
  AppStrings.loginPhoneCodeHint: 'Kod z SMS',
  AppStrings.loginPhoneVerify: 'Zaloguj',
  AppStrings.authModeLogin: 'Logowanie',
  AppStrings.authModeRegister: 'Rejestracja',
  AppStrings.registerPhoneTitle: 'Konto — numer telefonu',
  AppStrings.registerPhoneLead:
      'Nowe konto: podaj numer i odbierz SMS z kodem. Te same kroki logują, jeśli konto już istnieje.',
  AppStrings.registerPhoneSubmit: 'Utwórz konto / Dalej',
  AppStrings.profileSetupTitle: 'Twój profil',
  AppStrings.profileSetupSubtitle:
      'Uzupełnij dane, żebyśmy mogli Cię rozpoznać przy rezerwacjach i kontakcie. E-mail jest opcjonalny (np. powiadomienia).',
  AppStrings.profileSetupNameLabel: 'Imię i nazwisko',
  AppStrings.profileSetupNameHint: 'np. Jan Kowalski',
  AppStrings.profileSetupEmailLabel: 'E-mail (opcjonalnie)',
  AppStrings.profileSetupEmailHint: 'biuro@firma.pl',
  AppStrings.profileSetupEmailError: 'Podaj poprawny adres e-mail',
  AppStrings.profileSetupSave: 'Zapisz i przejdź do mapy',
  AppStrings.profileSetupNameError: 'Wpisz imię i nazwisko',
  AppStrings.loginPhoneMandatoryInfo:
      'Aby korzystać z aplikacji, wymagany jest zweryfikowany numer telefonu. Możesz zalogować się SMS albo Google/Apple — w drugim przypadku dokończ weryfikację numeru kodem SMS.',
  AppStrings.phoneRequiredTitle: 'Zweryfikuj numer telefonu',
  AppStrings.phoneRequiredBody:
      'Dostęp do aplikacji mają tylko użytkownicy z potwierdzonym numerem. Podaj numer, odbierz SMS i wprowadź kod poniżej.',
  AppStrings.phoneRequiredSignOut: 'Wyloguj',
  AppStrings.phoneRequiredSubmit: 'Potwierdź numer',
  AppStrings.loginOrDivider: 'lub',
  AppStrings.loginWithGoogle: 'Kontynuuj z Google',
  AppStrings.loginWithApple: 'Kontynuuj z Apple',
  AppStrings.loginAuxHint: 'Logowanie Google/Apple: w Firebase Auth włącz dostawców. Apple: w Xcode dodaj Sign in with Apple.',
  AppStrings.loginFirebaseMissing:
      'Nie udało się zainicjować Firebase. Dodaj pliki z konsoli (google-services.json, GoogleService-Info.plist) i uruchom: flutterfire configure. Możesz tymczasowo wejść do mapy.',
  AppStrings.loginLanguagePl: 'Polski',
  AppStrings.loginLanguageEn: 'English',
  AppStrings.mapSearchHint: 'Szukaj stacji, parkingu...',
  AppStrings.mapGpsMessage: 'Włącz GPS lub zeskanuj kod QR ze słupka',
  AppStrings.mapPark: 'Zaparkuj',
  AppStrings.mapReceive: 'Odbierz',
  AppStrings.mapMenu: 'Menu',
  AppStrings.mapDrawerProfile: 'Twój profil',
  AppStrings.mapDrawerName: 'Imię i nazwisko',
  AppStrings.mapDrawerEmail: 'E-mail',
  AppStrings.mapDrawerPhone: 'Telefon',
  AppStrings.mapDrawerFieldEmpty: '—',
  AppStrings.mapDrawerLanguage: 'Język',
  AppStrings.mapDrawerHelp: 'Pomoc',
  AppStrings.mapHelpReportTitle: 'Zgłoś problem',
  AppStrings.helpReportPhone: '+48 607 869 986',
  AppStrings.helpReportEmail: 'biuro@mdm-electronic.com',
  AppStrings.mapDrawerLogout: 'Wyloguj',
  AppStrings.mapHelpLinkError: 'Nie udało się otworzyć linku',
  AppStrings.qrScanVehicle: 'Zeskanuj kod QR stacji',
  AppStrings.qrCancel: 'Anuluj',
  AppStrings.qrOk: 'OK',
  AppStrings.qrInvalidCode: 'Nieprawidłowy kod (wymagany Base64 z JSON)',
  AppStrings.qrStationNotInApp: 'Nieznana stacja w aplikacji: %s',
  AppStrings.parkOpenPageTitle: 'Zaparkuj',
  AppStrings.parkOpenShort: 'Ustaw rower w wyznaczonym miejscu, potem pokaż poniższy kod czytnikowi, aby otworzyć rygiel.',
  AppStrings.parkOpenNextButton: 'Dalej: kod zamknięcia',
  AppStrings.parkClosePageTitle: 'Zamknij rygiel',
  AppStrings.parkFlowQrOpenCaption: 'Kod: otwarcie',
  AppStrings.parkFlowQrCloseCaption: 'Kod: zamknięcie (natychmiast pokaż czytnikowi)',
  AppStrings.parkFlowCloseBeforeQr: 'Gdy wszystko gotowe, pokaż ten kod — zamyka rygiel natychmiast po stronie czytnika.',
  AppStrings.parkFlowSlotHint: 'Numer stanowiska (slot)',
  AppStrings.parkFlowDoneButton: 'Gotowe',
  AppStrings.pickupTitle: 'Odbierz',
  AppStrings.pickupOpenCaption: 'Kod: otwarcie stacji (pokaż czytnikowi, żeby odblokować)',
  AppStrings.pickupIntro:
      'Pokaż kod otwarcia czytnikowi, wyjmij rower. Chcesz od razu zablokować pusty slot? Użyj przycisku z kodem zamknięcia.',
  AppStrings.pickupFlowSlotHint: 'Numer stanowiska (slot)',
  AppStrings.pickupFlowDoneButton: 'Gotowe',
  AppStrings.pickupLockNowButton: 'Zamknij rygiel teraz (kod QR)',
  AppStrings.pickupClosePageTitle: 'Zamknij po odbiorze',
  AppStrings.pickupCloseCaption: 'Kod: zamknięcie',
  AppStrings.pickupCloseBeforeQr: 'Pokaż ten kod czytnikowi od razu po wyciągnięciu roweru, jeśli chcesz zablokować pusty slot.',
  AppStrings.reservationsTitle: 'Aktywne rezerwacje',
  AppStrings.reservationsEmpty: 'Brak aktywnych rezerwacji.',
  AppStrings.reservationsStart: 'Start',
  AppStrings.reservationsDuration: 'Czas',
  AppStrings.reservationsEnd: 'Zakończenie',
  AppStrings.reservationsNavigate: 'Nawiguj',
  AppStrings.reservationsEndButton: 'Zakończ',
  AppStrings.appTitle: 'mdm-sport',
};

final Map<String, String> _en = {
  AppStrings.legalPrivacyPolicy: 'Privacy policy',
  AppStrings.helpPrivacySiteLabel: 'sport.mdm-electronic.com',
  AppStrings.loginEnter: 'Open map',
  AppStrings.loginPhoneTitle: 'Phone number',
  AppStrings.loginPhoneHint: '+48 000 000 000',
  AppStrings.loginPhoneInvalid: 'Enter a valid number, e.g. +48 728 553 487',
  AppStrings.loginPhoneNoCode: 'Send the SMS code first',
  AppStrings.loginPhoneSendCode: 'Send SMS code',
  AppStrings.loginPhoneCodeHint: 'SMS code',
  AppStrings.loginPhoneVerify: 'Sign in',
  AppStrings.authModeLogin: 'Sign in',
  AppStrings.authModeRegister: 'Register',
  AppStrings.registerPhoneTitle: 'Account — phone number',
  AppStrings.registerPhoneLead:
      'New account: enter your number and receive an SMS code. The same steps sign you in if you already have an account.',
  AppStrings.registerPhoneSubmit: 'Create account / Continue',
  AppStrings.profileSetupTitle: 'Your profile',
  AppStrings.profileSetupSubtitle:
      'Add your details so we can identify you for reservations and contact. Email is optional (e.g. notifications).',
  AppStrings.profileSetupNameLabel: 'Full name',
  AppStrings.profileSetupNameHint: 'e.g. Jane Doe',
  AppStrings.profileSetupEmailLabel: 'Email (optional)',
  AppStrings.profileSetupEmailHint: 'you@example.com',
  AppStrings.profileSetupEmailError: 'Enter a valid email address',
  AppStrings.profileSetupSave: 'Save and open map',
  AppStrings.profileSetupNameError: 'Enter your name',
  AppStrings.loginPhoneMandatoryInfo:
      'A verified phone number is required to use the app. Sign in with SMS, or with Google/Apple and then complete verification with an SMS code.',
  AppStrings.phoneRequiredTitle: 'Verify your phone number',
  AppStrings.phoneRequiredBody:
      'Only users with a confirmed phone number can use the app. Enter your number, receive the SMS, and type the code below.',
  AppStrings.phoneRequiredSignOut: 'Log out',
  AppStrings.phoneRequiredSubmit: 'Confirm',
  AppStrings.loginOrDivider: 'or',
  AppStrings.loginWithGoogle: 'Continue with Google',
  AppStrings.loginWithApple: 'Continue with Apple',
  AppStrings.loginAuxHint: 'Enable Google/Apple in Firebase Auth. For Apple, add the Sign in with Apple capability in Xcode.',
  AppStrings.loginFirebaseMissing:
      'Firebase could not start. Add console files (google-services.json, GoogleService-Info.plist) and run: flutterfire configure. You can still open the map for now.',
  AppStrings.loginLanguagePl: 'Polski',
  AppStrings.loginLanguageEn: 'English',
  AppStrings.mapSearchHint: 'Search for stations, parking...',
  AppStrings.mapGpsMessage: 'Turn on GPS or scan the QR code from the pole',
  AppStrings.mapPark: 'Park',
  AppStrings.mapReceive: 'Pick up',
  AppStrings.mapMenu: 'Menu',
  AppStrings.mapDrawerProfile: 'Your profile',
  AppStrings.mapDrawerName: 'Full name',
  AppStrings.mapDrawerEmail: 'E-mail',
  AppStrings.mapDrawerPhone: 'Phone',
  AppStrings.mapDrawerFieldEmpty: '—',
  AppStrings.mapDrawerLanguage: 'Language',
  AppStrings.mapDrawerHelp: 'Help',
  AppStrings.mapHelpReportTitle: 'Report a problem',
  AppStrings.helpReportPhone: '+48 607 869 986',
  AppStrings.helpReportEmail: 'biuro@mdm-electronic.com',
  AppStrings.mapDrawerLogout: 'Log out',
  AppStrings.mapHelpLinkError: 'Could not open the link',
  AppStrings.qrScanVehicle: 'Scan the station QR code',
  AppStrings.qrCancel: 'Cancel',
  AppStrings.qrOk: 'OK',
  AppStrings.qrInvalidCode: 'Invalid code (Base64 with JSON required)',
  AppStrings.qrStationNotInApp: 'Unknown station in the app: %s',
  AppStrings.parkOpenPageTitle: 'Park',
  AppStrings.parkOpenShort: 'Place the bike in the designated area, then show the code below to the reader to open the latch.',
  AppStrings.parkOpenNextButton: 'Next: lock code',
  AppStrings.parkClosePageTitle: 'Lock latch',
  AppStrings.parkFlowQrOpenCaption: 'Code: open',
  AppStrings.parkFlowQrCloseCaption: 'Code: lock (show to the reader right away)',
  AppStrings.parkFlowCloseBeforeQr: 'When ready, show this code — it requests an immediate lock at the reader.',
  AppStrings.parkFlowSlotHint: 'Slot number',
  AppStrings.parkFlowDoneButton: 'Done',
  AppStrings.pickupTitle: 'Pick up',
  AppStrings.pickupOpenCaption: 'Code: open station (show to the reader to unlock)',
  AppStrings.pickupIntro:
      'Show the open code, remove the bike. Want to lock the empty slot right away? Use the button for the lock code.',
  AppStrings.pickupFlowSlotHint: 'Slot number',
  AppStrings.pickupFlowDoneButton: 'Done',
  AppStrings.pickupLockNowButton: 'Lock now (QR code)',
  AppStrings.pickupClosePageTitle: 'Lock after pick-up',
  AppStrings.pickupCloseCaption: 'Code: lock',
  AppStrings.pickupCloseBeforeQr: 'Show this to the reader right after removing the bike if you want to lock the empty slot immediately.',
  AppStrings.reservationsTitle: 'Active reservations',
  AppStrings.reservationsEmpty: 'No active reservations.',
  AppStrings.reservationsStart: 'Start',
  AppStrings.reservationsDuration: 'Duration',
  AppStrings.reservationsEnd: 'End',
  AppStrings.reservationsNavigate: 'Navigate',
  AppStrings.reservationsEndButton: 'End',
  AppStrings.appTitle: 'mdm-sport',
};

String _tr(String key, String locale) {
  final map = locale == 'en' ? _en : _pl;
  return map[key] ?? _pl[key] ?? key;
}

String t(String key, [String? locale]) {
  if (locale != null) return _tr(key, locale);
  return _tr(key, AppL10n.currentLocale);
}

abstract final class AppL10n {
  static String _locale = 'pl';
  static String get currentLocale => _locale;
  static set currentLocale(String value) {
    _locale = value == 'en' ? 'en' : 'pl';
  }
}
