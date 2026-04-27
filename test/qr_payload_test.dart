import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdm_sport/data/qr_payload.dart';

void main() {
  group('obfuscate / deobfuscate', () {
    test('round-trip preserves base64 payload', () {
      const json = '{"stationId":"1","slot":2}';
      final b64 = base64.encode(utf8.encode(json));
      final obf = obfuscateBase64ForQr(b64);
      final back = deobfuscateBase64FromQr(obf);
      expect(back, b64);
      expect(utf8.decode(base64.decode(back)), json);
    });

    test('literal 0 in base64 survives (via ~)', () {
      const json = '{"stationId":"x","slot":0}';
      final b64 = base64.encode(utf8.encode(json));
      expect(b64, contains('0'));
      final obf = obfuscateBase64ForQr(b64);
      final back = deobfuscateBase64FromQr(obf);
      expect(back, b64);
    });
  });

  group('parsePoleQrPayloadFromBase64', () {
    test('legacy plain base64', () {
      final json = '{"stationId":"abc","slot":2}';
      final plain = base64.encode(utf8.encode(json));
      final p = parsePoleQrPayloadFromBase64(plain)!;
      expect(p.stationId, 'abc');
      expect(p.slot, 2);
    });

    test('stationId trimmed from JSON', () {
      final json = '{"stationId":"  st-1  ","slot":2}';
      final plain = base64.encode(utf8.encode(json));
      final p = parsePoleQrPayloadFromBase64(plain)!;
      expect(p.stationId, 'st-1');
      expect(p.slot, 2);
    });

    test('obfuscated base64', () {
      final json = '{"stationId":"st-1","slot":1}';
      final obf = encodePayloadAsBase64Qr(json);
      final p = parsePoleQrPayloadFromBase64(obf)!;
      expect(p.stationId, 'st-1');
      expect(p.slot, 1);
    });

    test('missing slot → null', () {
      final json = '{"stationId":"x"}';
      final plain = base64.encode(utf8.encode(json));
      expect(parsePoleQrPayloadFromBase64(plain), isNull);
    });

    test('id zamiast stationId', () {
      final json = '{"id":"5","slot":2}';
      final p = parsePoleQrPayloadFromBase64(base64.encode(utf8.encode(json)))!;
      expect(p.stationId, '5');
      expect(p.slot, 2);
    });

    test('stationId numeryczne w JSON (int)', () {
      final json = '{"stationId":3,"slot":1}';
      final p = parsePoleQrPayloadFromBase64(base64.encode(utf8.encode(json)))!;
      expect(p.stationId, '3');
      expect(p.slot, 1);
    });

    test('czysty JSON (bez base64) — ze słupka / nalepki', () {
      final p = parsePoleQrPayloadFromBase64('{"stationId":"1","slot":2}')!;
      expect(p.stationId, '1');
      expect(p.slot, 2);
    });

    test('ładunek z URL — query', () {
      final json = '{"stationId":"7","slot":2}';
      final b = base64.encode(utf8.encode(json));
      final url = 'https://example.com/x?d=$b';
      final p = parsePoleQrPayloadFromBase64(url)!;
      expect(p.stationId, '7');
      expect(p.slot, 2);
    });

    test('base64 ze znakami nowej linii', () {
      final json = '{"id":"2","slot":3}';
      final b = base64.encode(utf8.encode(json));
      final withNl = '${b.substring(0, 8)}\n${b.substring(8)}';
      final p = parsePoleQrPayloadFromBase64(withNl)!;
      expect(p.stationId, '2');
      expect(p.slot, 3);
    });
  });
}
