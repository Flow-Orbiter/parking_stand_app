/// Skąd użytkownik wchodzi w [QrScannerScreen] — rozgałęzienie po skanie słupka.
enum StationEntryFlow {
  /// Zaparkuj — kod otwarcia; zamknięcie rygla ręcznie przy stacji.
  park,
  /// Odbierz — kod otwarcia; zamknięcie rygla ręcznie przy stacji.
  pickup,
}
