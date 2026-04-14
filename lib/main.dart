import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:parking_stand_app/data/local/app_storage.dart';
import 'package:parking_stand_app/l10n/app_localizations.dart';
import 'package:parking_stand_app/l10n/translations.dart';
import 'package:parking_stand_app/theme/app_theme.dart';
import 'package:parking_stand_app/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _locale;

  @override
  void initState() {
    super.initState();
    _locale = AppStorage.languageCode;
  }

  void _onLocaleChanged(String code) async {
    await AppStorage.setLanguageCode(code);
    setState(() => _locale = code);
  }

  @override
  Widget build(BuildContext context) {
    AppL10n.currentLocale = _locale;
    return L10nScope(
      locale: _locale,
      onLocaleChanged: _onLocaleChanged,
      child: MaterialApp(
        title: t(AppStrings.appTitle),
        theme: AppTheme.light,
        locale: Locale(_locale),
        supportedLocales: const [Locale('pl'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const LoginScreen(),
      ),
    );
  }
}
