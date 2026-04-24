import 'package:flutter/services.dart';

String _extractDigits(String raw) {
  final b = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final c = raw[i];
    if (c == '+') {
      if (i != 0) continue;
      continue;
    }
    final o = c.codeUnitAt(0);
    if (o >= 0x30 && o <= 0x39) b.write(c);
  }
  return b.toString();
}

String _applyPolandHeuristics(String digits) {
  if (digits.isEmpty) return digits;

  if (digits.length == 9) {
    return '48$digits';
  }
  if (digits.length == 10 && digits.startsWith('0')) {
    return '48${digits.substring(1)}';
  }
  if (digits.length >= 12 && digits.startsWith('480')) {
    return '48${digits.substring(3)}';
  }
  if (digits.length == 11 && digits.startsWith('48')) {
    return digits;
  }
  return digits;
}

/// [raw] — tekst z pola; zwraca `+` i cyfry (E.164, max. 15 cyfr po `+`), albo samo `+` gdy brak cyfr.
String normalizePhoneInputToE164(String raw) {
  var d = _extractDigits(raw.trim());
  if (d.isEmpty) return '+';
  d = _applyPolandHeuristics(d);
  return '+$d';
}

/// Wzorzec E.164: `+` i 8–15 cyfr.
bool isValidE164(String candidate) {
  return RegExp(r'^\+\d{8,15}$').hasMatch(candidate);
}

/// Wyciąga z samej listy cyfr (bez `+`) krajowy numer do 9 cyfr (PL) pod pole z maską +48.
/// Obsługa: 48 + 9 cyfr, 9 cyfr, 0 + 9 cyfr.
String plNationalDigitsFromAllDigits(String digits) {
  if (digits.isEmpty) return '';
  if (digits.length >= 2 && digits.startsWith('48')) {
    if (digits.length == 2) return '';
    final rest = digits.length > 11 ? digits.substring(2, 11) : digits.substring(2);
    return rest.length > 9 ? rest.substring(0, 9) : rest;
  }
  if (digits.startsWith('0') && digits.length > 1) {
    final rest = digits.length > 10 ? digits.substring(1, 10) : digits.substring(1);
    return rest.length > 9 ? rest.substring(0, 9) : rest;
  }
  if (digits.length > 9) return digits.substring(0, 9);
  return digits;
}

/// Wyświetlanie: `+48 123 456 789` (9 cyfr krajowych; [national] tylko cyfry).
String formatPlE164Display(String national) {
  if (national.isEmpty) return '';
  final b = StringBuffer('+48');
  for (var i = 0; i < national.length; i++) {
    if (i == 0) {
      b.write(' ');
    } else if (i == 3 || i == 6) {
      b.write(' ');
    }
    b.write(national[i]);
  }
  return b.toString();
}

/// Wymusza format `+48 ### ### ###` przy wpisywaniu; do SMS/Firebase nadal używaj
/// [normalizePhoneInputToE164].
class PlPhoneE164InputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final d = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final national = plNationalDigitsFromAllDigits(d);
    final display = formatPlE164Display(national);
    return TextEditingValue(
      text: display,
      selection: TextSelection.collapsed(offset: display.length),
    );
  }
}
