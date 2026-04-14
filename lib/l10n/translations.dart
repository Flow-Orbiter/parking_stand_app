/// Klucze tłumaczeń – wszystkie teksty UI w jednym miejscu.
abstract final class AppStrings {
  static const String loginEnter = 'loginEnter';
  static const String loginLanguagePl = 'loginLanguagePl';
  static const String loginLanguageEn = 'loginLanguageEn';
  static const String mapSearchHint = 'mapSearchHint';
  static const String mapGpsMessage = 'mapGpsMessage';
  static const String mapBikeBanner = 'mapBikeBanner';
  static const String mapScan = 'mapScan';
  static const String mapReceive = 'mapReceive';
  static const String mapMenu = 'mapMenu';
  static const String mapActiveReservations = 'mapActiveReservations';
  static const String qrScanVehicle = 'qrScanVehicle';
  static const String qrEnterManually = 'qrEnterManually';
  static const String qrEnterStationNumber = 'qrEnterStationNumber';
  static const String qrCancel = 'qrCancel';
  static const String qrOk = 'qrOk';
  static const String qrStationNotFound = 'qrStationNotFound';
  static const String qrShowTitle = 'qrShowTitle';
  static const String qrShowStation = 'qrShowStation';
  static const String qrShowSlotHint = 'qrShowSlotHint';
  static const String qrShowCodeAtStation = 'qrShowCodeAtStation';
  static const String qrShowAddReservation = 'qrShowAddReservation';
  static const String qrShowReservationAdded = 'qrShowReservationAdded';
  static const String qrShowNoStation = 'qrShowNoStation';
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
  AppStrings.loginEnter: 'Wejdź',
  AppStrings.loginLanguagePl: 'Polski',
  AppStrings.loginLanguageEn: 'English',
  AppStrings.mapSearchHint: 'Szukaj stacji, parkingu...',
  AppStrings.mapGpsMessage: 'Włącz GPS lub zeskanuj kod QR ze słupka',
  AppStrings.mapBikeBanner: 'Aby zobaczyć rower na mapie: włącz GPS lub zeskanuj kod QR ze słupka.',
  AppStrings.mapScan: 'Skanuj',
  AppStrings.mapReceive: 'Odbierz',
  AppStrings.mapMenu: 'Menu',
  AppStrings.mapActiveReservations: 'Aktywne rezerwacje',
  AppStrings.qrScanVehicle: 'Zeskanuj kod QR pojazdu',
  AppStrings.qrEnterManually: 'Wpisz numer ręcznie',
  AppStrings.qrEnterStationNumber: 'Wpisz numer stacji',
  AppStrings.qrCancel: 'Anuluj',
  AppStrings.qrOk: 'OK',
  AppStrings.qrStationNotFound: 'Nie znaleziono stacji o numerze: %s',
  AppStrings.qrShowTitle: 'Pokaż kod skanerowi',
  AppStrings.qrShowStation: 'Stacja',
  AppStrings.qrShowSlotHint: 'Numer stanowiska',
  AppStrings.qrShowCodeAtStation: 'Pokaż ten kod skanerowi przy stacji',
  AppStrings.qrShowAddReservation: 'Dodaj rezerwację (test)',
  AppStrings.qrShowReservationAdded: 'Rezerwacja dodana',
  AppStrings.qrShowNoStation: 'Brak stacji. Zeskanuj najpierw kod ze słupka.',
  AppStrings.reservationsTitle: 'Aktywne rezerwacje',
  AppStrings.reservationsEmpty: 'Brak aktywnych rezerwacji.',
  AppStrings.reservationsStart: 'Start',
  AppStrings.reservationsDuration: 'Czas',
  AppStrings.reservationsEnd: 'Zakończenie',
  AppStrings.reservationsNavigate: 'Nawiguj',
  AppStrings.reservationsEndButton: 'Zakończ',
  AppStrings.appTitle: 'Parking Stand',
};

final Map<String, String> _en = {
  AppStrings.loginEnter: 'Enter',
  AppStrings.loginLanguagePl: 'Polski',
  AppStrings.loginLanguageEn: 'English',
  AppStrings.mapSearchHint: 'Search for stations, parking...',
  AppStrings.mapGpsMessage: 'Turn on GPS or scan the QR code from the pole',
  AppStrings.mapBikeBanner: 'To see the bike on the map: turn on GPS or scan the QR code from the pole.',
  AppStrings.mapScan: 'Scan',
  AppStrings.mapReceive: 'Receive',
  AppStrings.mapMenu: 'Menu',
  AppStrings.mapActiveReservations: 'Active reservations',
  AppStrings.qrScanVehicle: 'Scan vehicle QR code',
  AppStrings.qrEnterManually: 'Enter number manually',
  AppStrings.qrEnterStationNumber: 'Enter station number',
  AppStrings.qrCancel: 'Cancel',
  AppStrings.qrOk: 'OK',
  AppStrings.qrStationNotFound: 'Station not found for number: %s',
  AppStrings.qrShowTitle: 'Show code to scanner',
  AppStrings.qrShowStation: 'Station',
  AppStrings.qrShowSlotHint: 'Slot number',
  AppStrings.qrShowCodeAtStation: 'Show this code to the scanner at the station',
  AppStrings.qrShowAddReservation: 'Add reservation (test)',
  AppStrings.qrShowReservationAdded: 'Reservation added',
  AppStrings.qrShowNoStation: 'No station. Scan the code from the pole first.',
  AppStrings.reservationsTitle: 'Active reservations',
  AppStrings.reservationsEmpty: 'No active reservations.',
  AppStrings.reservationsStart: 'Start',
  AppStrings.reservationsDuration: 'Duration',
  AppStrings.reservationsEnd: 'End',
  AppStrings.reservationsNavigate: 'Navigate',
  AppStrings.reservationsEndButton: 'End',
  AppStrings.appTitle: 'Parking Stand',
};

String _tr(String key, String locale) {
  final map = locale == 'en' ? _en : _pl;
  return map[key] ?? _pl[key] ?? key;
}

/// Zwraca tłumaczenie dla klucza. [locale] opcjonalny (np. 'pl', 'en').
String t(String key, [String? locale]) {
  if (locale != null) return _tr(key, locale);
  return _tr(key, AppL10n.currentLocale);
}

/// Przechowuje aktualny locale; ustawiany przez [L10nScope].
abstract final class AppL10n {
  static String _locale = 'pl';
  static String get currentLocale => _locale;
  static set currentLocale(String value) {
    _locale = value == 'en' ? 'en' : 'pl';
  }
}
