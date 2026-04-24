import 'package:flutter_test/flutter_test.dart';
import 'package:mdm_sport/util/phone_e164_pl.dart';

void main() {
  group('normalizePhoneInputToE164', () {
    test('zostawia pełne +48', () {
      expect(
        normalizePhoneInputToE164('+48 501 234 567'),
        '+48501234567',
      );
    });

    test('9 cyfr — uzupełnia 48', () {
      expect(normalizePhoneInputToE164('501234567'), '+48501234567');
    });

    test('krajowy z 0', () {
      expect(normalizePhoneInputToE164('0501234567'), '+48501234567');
    });

    test('wklejone 480 zamiast 48 (zbędne 0 po kodzie)', () {
      expect(
        normalizePhoneInputToE164('+480 501 234 567'),
        '+48501234567',
      );
    });
  });

  group('isValidE164', () {
    test('akceptuje typowy PL', () {
      expect(isValidE164('+48501234567'), isTrue);
    });
  });

  group('plNationalDigitsFromAllDigits / format', () {
    test('48 + 9 cyfr', () {
      expect(plNationalDigitsFromAllDigits('48501234567'), '501234567');
    });

    test('9 cyfr krajowe', () {
      expect(plNationalDigitsFromAllDigits('501234567'), '501234567');
    });

    test('0 krajowe', () {
      expect(plNationalDigitsFromAllDigits('0501234567'), '501234567');
    });

    test('tylko 48', () {
      expect(plNationalDigitsFromAllDigits('48'), isEmpty);
    });

    test('format +48 501 234 567', () {
      expect(formatPlE164Display('501234567'), '+48 501 234 567');
    });

    test('format z częściowym wejściem', () {
      expect(formatPlE164Display('5012'), '+48 501 2');
    });
  });
}
