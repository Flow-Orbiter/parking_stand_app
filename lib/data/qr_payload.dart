// Format payloadu QR (mobile ↔ stacja RASP PI).
//
// Słupek: QR = **obfuskacja** standardowego base64(UTF-8 → JSON) z polami `stationId` (lub `id`) i `slot`.
// Akceptowane też: zwykły Base64, surowy JSON, URL z `?param=` lub path/fragmentem, base64 z białymi znakami.
// Aplikacja → czytnik: base64(UTF-8 → JSON) z: `action`, `stationId`, `slot`, `ts`, `deviceId` — obfuskacja poniżej.
//
// Obfuskacja (zgodna czytnik ↔ telefon; literał `0` w base64 → `~` zanim 1..8, żeby nie kolidować z `1`→`0`):
//   1→0  2→1  3→2  4→3  5→(  6→)  7→@  8→$

import 'dart:convert';

import 'package:mdm_sport/data/stations_repository.dart';

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
  if (v == null) return null;
  if (v is int) {
    if (v < 1) return null;
    return v;
  }
  if (v is double) {
    if (v < 1 || v != v.truncateToDouble()) return null;
    return v.toInt();
  }
  if (v is String) {
    final n = int.tryParse(v.trim());
    if (n == null || n < 1) return null;
    return n;
  }
  return null;
}

/// Stacja: `stationId` (preferowane), `id` lub `station_id`; liczby w JSON (np. `1`) też.
String? _stringFromIdField(Object? v) {
  if (v == null) return null;
  if (v is String) {
    final s = v.trim();
    return s.isEmpty ? null : s;
  }
  if (v is int) return v.toString();
  if (v is double) {
    if (v != v.truncateToDouble()) return null;
    return v.toInt().toString();
  }
  return null;
}

PoleQrPayload? _polePayloadFromMap(Map<String, dynamic> m) {
  final id = _stringFromIdField(
    m['stationId'] ?? m['id'] ?? m['station_id'],
  );
  if (id == null) return null;
  // `slod` = literówka; niektóre czytniki: `stand` jako numer slotu
  final slot = _slotFromPoleJson(
    m['slot'] ?? m['slod'] ?? m['stand'] ?? m['standNumber'],
  );
  if (slot == null) return null;
  return PoleQrPayload(stationId: normalizeStationId(id), slot: slot);
}

PoleQrPayload? _polePayloadFromDecodedJson(String utf8Json) {
  try {
    final dynamic decoded = jsonDecode(utf8Json);
    if (decoded is! Map) return null;
    return _polePayloadFromMap(Map<String, dynamic>.from(decoded));
  } catch (_) {
    return null;
  }
}

PoleQrPayload? _tryParsePoleFromJsonStringCompacted(String s) {
  if (!s.contains('{')) return null;
  final c = s.replaceAll(RegExp(r'\s+'), '');
  if (!c.startsWith('{')) return null;
  return _polePayloadFromDecodedJson(c);
}

/// Pełny tekst QR, wariant bez białych znaków, fragmenty z [Uri] (path/query/fragment).
List<String> _scanPayloadCandidates(String raw) {
  final seen = <String>{};
  final out = <String>[];
  void add2(String? s) {
    if (s == null) return;
    for (final variant in {s.trim(), s.trim().replaceAll(RegExp(r'\s+'), '')}) {
      if (variant.isEmpty) continue;
      if (seen.add(variant)) out.add(variant);
    }
  }

  add2(raw);
  final t = raw.trim();
  final uri = Uri.tryParse(t);
  if (uri != null && uri.hasScheme) {
    for (final v in uri.queryParameters.values) {
      add2(v);
    }
    for (final seg in uri.pathSegments) {
      add2(seg);
    }
    if (uri.hasFragment) {
      add2(uri.fragment);
    }
    if (uri.path.isNotEmpty) {
      final p = uri.path;
      if (p.startsWith('/')) {
        add2(p.substring(1));
      } else {
        add2(p);
      }
    }
  }
  return out;
}

PoleQrPayload? _tryParsePoleFromCandidate(String candidate) {
  final t = candidate.trim();
  if (t.isEmpty) return null;
  if (t.trimLeft().startsWith('{')) {
    final fromJson = _polePayloadFromDecodedJson(t);
    if (fromJson != null) return fromJson;
  }
  final fromCompactJson = _tryParsePoleFromJsonStringCompacted(t);
  if (fromCompactJson != null) return fromCompactJson;
  final compact = t.replaceAll(RegExp(r'[\n\r\t ]'), '');
  return _parsePolePayloadFromRaw(compact, obfuscated: false) ??
      _parsePolePayloadFromRaw(compact, obfuscated: true);
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

/// Parsuje treść ze skanera: JSON (także w URL), base64, obfuskowany base64 (telefon/stacja zgodne z [deobfuscateBase64FromQr]).
PoleQrPayload? parsePoleQrPayloadFromBase64(String raw) {
  if (raw.trim().isEmpty) return null;
  for (final candidate in _scanPayloadCandidates(raw)) {
    final p = _tryParsePoleFromCandidate(candidate);
    if (p != null) return p;
  }
  return null;
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
