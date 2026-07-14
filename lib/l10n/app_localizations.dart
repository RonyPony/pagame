import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);
  final Locale locale;
  static const LocalizationsDelegate<AppLocalizations> delegate = _Delegate();
  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  String get appName => locale.languageCode == 'en' ? 'Pagame' : 'Págame';
}

class _Delegate extends LocalizationsDelegate<AppLocalizations> {
  const _Delegate();
  @override bool isSupported(Locale locale) => ['es', 'en'].contains(locale.languageCode);
  @override Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override bool shouldReload(_Delegate old) => false;
}
