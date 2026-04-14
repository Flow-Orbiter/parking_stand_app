import 'package:flutter/material.dart';
import 'package:parking_stand_app/l10n/translations.dart' as l10n;

/// Udostępnia bieżący język i [t] w dół drzewa. Przełączenie języka przez [onLocaleChanged].
class L10nScope extends InheritedWidget {
  const L10nScope({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required super.child,
  });

  final String locale;
  final ValueChanged<String> onLocaleChanged;

  static L10nScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<L10nScope>();
    assert(scope != null, 'L10nScope not found. Wrap app with L10nScope.');
    return scope!;
  }

  String t(String key) => l10n.t(key, locale);

  @override
  bool updateShouldNotify(L10nScope oldWidget) => locale != oldWidget.locale;
}
