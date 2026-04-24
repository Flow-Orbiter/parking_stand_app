// One-shot: `dart run tool/print_qr_samples.dart`
import 'dart:convert';

import 'package:mdm_sport/data/qr_payload.dart';

void main() {
  // QR ze słupka (skan w aplikacji) – minimalne JSON, jak w repozytorium.
  for (final id in ['1', '2']) {
    final pole = '{"stationId":"$id","slot":1}';
    final obf = encodePayloadAsBase64Qr(pole);
    // ignore: avoid_print
    print('--- QR ze słupka, stacja id=$id ---');
    // ignore: avoid_print
    print('JSON: $pole');
    // ignore: avoid_print
    print('Z obfuskacją (tak w QR):');
    // ignore: avoid_print
    print(obf);
    // ignore: avoid_print
    print('');
    final backPole = utf8.decode(
      base64.decode(deobfuscateBase64FromQr(obf)),
    );
    assert(backPole == pole, 'round-trip słupek stacja $id');
  }

  // Przykłady jak przy „Zaparkuj/Odbierz” – pełny payload, ts=1700000000, slot 1.
  const fixedTs = 1700000000;
  for (final id in ['1', '2']) {
    final json = '{"action":"close","stationId":"$id","slot":1,"ts":$fixedTs,"deviceId":"local"}';
    final obf = encodePayloadAsBase64Qr(json);
    // ignore: avoid_print
    print('--- Przykład zamknięcia po pomyślonym parku, stacja $id, slot 1, ts=$fixedTs ---');
    // ignore: avoid_print
    print('Z obfuskacją:');
    // ignore: avoid_print
    print(obf);
    // ignore: avoid_print
    print('');
    final back = utf8.decode(
      base64.decode(deobfuscateBase64FromQr(obf)),
    );
    assert(back == json, 'round-trip stacja $id');
  }
}
