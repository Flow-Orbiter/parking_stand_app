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
  });
}
