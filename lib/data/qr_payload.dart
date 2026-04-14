// Format payloadu QR (mobile ↔ stacja RASP PI).
// QR ze słupka: JSON np. {"stationId": "1"}. QR z aplikacji: stationId, slot, ts, deviceId.

/// Parsuje payload ze słupka (po zeskanowaniu). Zwraca stationId lub null.
String? parseStationIdFromQr(String raw) {
  raw = raw.trim();
  // Prosty JSON: {"stationId": "1"} lub {"id": "1"}
  if (raw.startsWith('{') && raw.contains('"')) {
    try {
      final idMatch = RegExp(r'"stationId"\s*:\s*"([^"]+)"').firstMatch(raw);
      if (idMatch != null) return idMatch.group(1);
      final idMatch2 = RegExp(r'"id"\s*:\s*"([^"]+)"').firstMatch(raw);
      if (idMatch2 != null) return idMatch2.group(1);
    } catch (_) {}
  }
  // Sam numer
  if (RegExp(r'^\d+$').hasMatch(raw)) return raw;
  return null;
}
