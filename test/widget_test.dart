import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdm_sport/l10n/app_localizations.dart';
import 'package:mdm_sport/l10n/translations.dart';
import 'package:mdm_sport/screens/login_screen.dart';
import 'package:mdm_sport/theme/app_theme.dart';

void main() {
  testWidgets('Login without Firebase shows offline message', (WidgetTester tester) async {
    await tester.pumpWidget(
      L10nScope(
        locale: 'pl',
        onLocaleChanged: (_) {},
        child: MaterialApp(
          theme: AppTheme.light,
          home: const LoginScreen(firebaseEnabled: false),
        ),
      ),
    );
    expect(find.text(t(AppStrings.loginFirebaseMissing, 'pl')), findsOneWidget);
  });
}
