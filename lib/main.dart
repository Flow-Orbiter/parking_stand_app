import 'dart:async';

import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mdm_sport/data/local/app_storage.dart';
import 'package:mdm_sport/debug_agent_log.dart';
import 'package:mdm_sport/firebase_options.dart';
import 'package:mdm_sport/l10n/app_localizations.dart';
import 'package:mdm_sport/l10n/translations.dart';
import 'package:mdm_sport/theme/app_theme.dart';
import 'package:mdm_sport/auth/phone_requirement.dart';
import 'package:mdm_sport/screens/login_screen.dart';
import 'package:mdm_sport/screens/phone_verification_required_screen.dart';
import 'package:mdm_sport/screens/profile_map_gate.dart';

void main() {
  // #region agent log
  PlatformDispatcher.instance.onError = (error, stack) {
    debugAgentLog('H1', 'main.dart:PlatformDispatcher.onError', error.toString(), {
      'stackLen': stack.toString().length,
    });
    return false;
  };
  // #endregion
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // #region agent log
      FlutterError.onError = (details) {
        debugAgentLog('H1', 'main.dart:FlutterError.onError', details.exceptionAsString(), {
          'hasStack': details.stack != null,
        });
        FlutterError.presentError(details);
      };
      // #endregion
      await AppStorage.init();
      var firebaseOk = false;
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseOk = true;
      } catch (e, st) {
        debugPrint('Firebase.initializeApp: $e\n$st');
      }
      runApp(MyApp(firebaseEnabled: firebaseOk));
    },
    (e, st) {
      // #region agent log
      debugAgentLog('H1', 'main.dart:runZonedGuarded', e.toString(), {
        'stackLen': st.toString().length,
      });
      // #endregion
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

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
        home: _AuthRoot(firebaseEnabled: widget.firebaseEnabled),
      ),
    );
  }
}

class _AuthRoot extends StatelessWidget {
  const _AuthRoot({required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    if (!firebaseEnabled) {
      return LoginScreen(firebaseEnabled: false);
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen(firebaseEnabled: true);
        }
        if (!hasVerifiedAppPhone(user)) {
          return const PhoneVerificationRequiredScreen();
        }
        return ProfileMapGate(user: user);
      },
    );
  }
}
