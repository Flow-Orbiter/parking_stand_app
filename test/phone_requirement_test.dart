import 'package:flutter_test/flutter_test.dart';
import 'package:mdm_sport/auth/phone_requirement.dart';

void main() {
  test('hasVerifiedAppPhone false for null', () {
    expect(hasVerifiedAppPhone(null), isFalse);
  });
}
