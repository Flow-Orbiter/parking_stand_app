/// Skąd użytkownik wchodzi w [QrScannerScreen] — rozgałęzienie po skanie słupka.
enum StationEntryFlow {
  /// Zaparkuj — flow parkowania (open → close).
  park,
  /// Odbierz — flow odbioru (open, opcjonalnie close).
  pickup,
}
