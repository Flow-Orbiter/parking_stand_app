// Format payloadu QR (mobile ↔ stacja RASP PI).
//
// Słupek: QR = **obfuskacja** standardowego base64(UTF-8 → JSON) z polami `stationId` i `slot`.
// Aplikacja → czytnik: base64(UTF-8 → JSON) z: `action`, `stationId`, `slot`, `ts`, `deviceId` — obfuskacja poniżej.
//
// Obfuskacja (zgodna czytnik ↔ telefon; literał `0` w base64 → `~` zanim 1..8, żeby nie kolidować z `1`→`0`):
//   1→0  2→1  3→2  4→3  5→(  6→)  7→@  8→$

import 'dart:convert';

/// Akcja w kodzie skanowanym przez czytnik stacji.
enum QrStationAction {
  open,
  close,
}

String _actionToJsonValue(QrStationAction a) =>
    a == QrStationAction.open ? 'open' : 'close';

/// Znak zastępczy: nie występuje w alfabecie base64; zabezpiecza prawdziwe `0` przed obfuskacją cyfr 1..8.
const _literalZeroPlaceholder = '~';

const Map<String, String> _obfuscateB64Digit = {
  '1': '0',
  '2': '1',
  '3': '2',
  '4': '3',
  '5': '(',
  '6': ')',
  '7': '@',
  '8': r'$',
};

final Map<String, String> _deobfuscateB64Char = {
  for (final e in _obfuscateB64Digit.entries) e.value: e.key,
};

/// Zwykły ciąg base64 → treść do wyświetlenia w QR (obfuskacja).
String obfuscateBase64ForQr(String standardBase64) {
  final buf = StringBuffer();
  for (var i = 0; i < standardBase64.length; i++) {
    final c = standardBase64[i];
    if (c == '0') {
      buf.write(_literalZeroPlaceholder);
    } else {
      buf.write(_obfuscateB64Digit[c] ?? c);
    }
  }
  return buf.toString();
}

/// Odczyt z QR (obfuskacja → base64 do zdekodowania `base64.decode`).
String deobfuscateBase64FromQr(String fromQr) {
  final buf = StringBuffer();
  for (var i = 0; i < fromQr.length; i++) {
    final c = fromQr[i];
    if (c == _literalZeroPlaceholder) {
      buf.write('0');
    } else {
      buf.write(_deobfuscateB64Char[c] ?? c);
    }
  }
  return buf.toString();
}

/// Normalizacja Base64 (URL-safe: `-`/`_` → `+`/`/`, dopełnienie paddingu).
String normalizeBase64ForDecode(String input) {
  var s = input.trim();
  s = s.replaceAll('-', '+').replaceAll('_', '/');
  while (s.length % 4 != 0) {
    s += '=';
  }
  return s;
}

/// Zdekodowany JSON ze słupka (base64 w QR): wymagane `stationId` i `slot` (≥ 1).
class PoleQrPayload {
  const PoleQrPayload({required this.stationId, required this.slot});

  final String stationId;
  final int slot;
}

int? _slotFromPoleJson(dynamic v) {
  final n = switch (v) {
    final int i => i,
    final String s => int.tryParse(s),
    _ => null,
  };
  if (n == null || n < 1) return null;
  return n;
}

PoleQrPayload? _polePayloadFromDecodedJson(String utf8Json) {
  try {
    final dynamic decoded = jsonDecode(utf8Json);
    if (decoded is! Map) return null;
    final m = Map<String, dynamic>.from(decoded);
    final id = m['stationId'] as String?;
    if (id == null || id.isEmpty) return null;
    final slot = _slotFromPoleJson(m['slot']);
    if (slot == null) return null;
    return PoleQrPayload(stationId: id, slot: slot);
  } catch (_) {
    return null;
  }
}

/// Parsuje treść QR: najpierw zwykły base64 (legacy), potem base64 po [deobfuscateBase64FromQr].
PoleQrPayload? _parsePolePayloadFromRaw(String raw, {required bool obfuscated}) {
  final toNormalize = obfuscated ? deobfuscateBase64FromQr(raw.trim()) : raw.trim();
  final normalized = normalizeBase64ForDecode(toNormalize);
  try {
    final bytes = base64.decode(normalized);
    return _polePayloadFromDecodedJson(utf8.decode(bytes));
  } catch (_) {
    return null;
  }
}

/// Parsuje base64 w QR słupka: JSON musi mieć `stationId` i `slot` (liczba całkowita ≥ 1).
/// Próbuje zwykłego base64, potem wersji po [deobfuscateBase64FromQr].
PoleQrPayload? parsePoleQrPayloadFromBase64(String raw) {
  if (raw.trim().isEmpty) return null;
  return _parsePolePayloadFromRaw(raw, obfuscated: false) ??
      _parsePolePayloadFromRaw(raw, obfuscated: true);
}

/// JSON do zakodowania w QR (czytnik stacji) dla akcji otwórz / zamknij.
String buildStationActionPayload({
  required String stationId,
  required int slot,
  required QrStationAction action,
  String deviceId = 'local',
}) {
  final map = {
    'action': _actionToJsonValue(action),
    'stationId': stationId,
    'slot': slot,
    'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'deviceId': deviceId,
  };
  return jsonEncode(map);
}

/// Treść do QR: base64 z JSON, potem [obfuscateBase64ForQr] (czytnik stacji: odwrotnie przed `base64.decode`).
String encodePayloadAsBase64Qr(String jsonString) {
  final b64 = base64.encode(utf8.encode(jsonString));
  return obfuscateBase64ForQr(b64);
}
