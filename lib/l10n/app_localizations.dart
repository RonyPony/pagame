import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'US'),
    Locale('es'),
    Locale('es', 'DO')
  ];

  /// No description provided for @appName.
  ///
  /// In es_DO, this message translates to:
  /// **'Págame'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In es_DO, this message translates to:
  /// **'Las cuentas claras conservan la amistad.'**
  String get tagline;

  /// No description provided for @onboardingTitle1.
  ///
  /// In es_DO, this message translates to:
  /// **'Registra lo que prestas'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In es_DO, this message translates to:
  /// **'Guarda cada préstamo con monto, fecha y motivo.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In es_DO, this message translates to:
  /// **'Controla cada pago'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In es_DO, this message translates to:
  /// **'Registra pagos completos, parciales y cuotas pendientes.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In es_DO, this message translates to:
  /// **'Cobra sin perseguir'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In es_DO, this message translates to:
  /// **'Programa recordatorios y compártelos cuando llegue el momento.'**
  String get onboardingBody3;

  /// No description provided for @continueAction.
  ///
  /// In es_DO, this message translates to:
  /// **'Continuar'**
  String get continueAction;

  /// No description provided for @backAction.
  ///
  /// In es_DO, this message translates to:
  /// **'Atrás'**
  String get backAction;

  /// No description provided for @skipAction.
  ///
  /// In es_DO, this message translates to:
  /// **'Omitir'**
  String get skipAction;

  /// No description provided for @home.
  ///
  /// In es_DO, this message translates to:
  /// **'Inicio'**
  String get home;

  /// No description provided for @debts.
  ///
  /// In es_DO, this message translates to:
  /// **'Deudas'**
  String get debts;

  /// No description provided for @create.
  ///
  /// In es_DO, this message translates to:
  /// **'Crear'**
  String get create;

  /// No description provided for @activity.
  ///
  /// In es_DO, this message translates to:
  /// **'Actividad'**
  String get activity;

  /// No description provided for @profile.
  ///
  /// In es_DO, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @setupProfile.
  ///
  /// In es_DO, this message translates to:
  /// **'Configura tu perfil local'**
  String get setupProfile;

  /// No description provided for @firstName.
  ///
  /// In es_DO, this message translates to:
  /// **'Nombre'**
  String get firstName;

  /// No description provided for @lastNameOptional.
  ///
  /// In es_DO, this message translates to:
  /// **'Apellido (opcional)'**
  String get lastNameOptional;

  /// No description provided for @phoneOptional.
  ///
  /// In es_DO, this message translates to:
  /// **'Teléfono (opcional)'**
  String get phoneOptional;

  /// No description provided for @emailOptional.
  ///
  /// In es_DO, this message translates to:
  /// **'Correo (opcional)'**
  String get emailOptional;

  /// No description provided for @defaultCurrency.
  ///
  /// In es_DO, this message translates to:
  /// **'Moneda predeterminada'**
  String get defaultCurrency;

  /// No description provided for @save.
  ///
  /// In es_DO, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @owedToMe.
  ///
  /// In es_DO, this message translates to:
  /// **'Me deben'**
  String get owedToMe;

  /// No description provided for @iOwe.
  ///
  /// In es_DO, this message translates to:
  /// **'Yo debo'**
  String get iOwe;

  /// No description provided for @balance.
  ///
  /// In es_DO, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @emptyDebtsTitle.
  ///
  /// In es_DO, this message translates to:
  /// **'Todavía no tienes deudas registradas.'**
  String get emptyDebtsTitle;

  /// No description provided for @emptyDebtsBody.
  ///
  /// In es_DO, this message translates to:
  /// **'Cuando prestes o recibas dinero, guárdalo aquí para no depender de la memoria.'**
  String get emptyDebtsBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'US':
            return AppLocalizationsEnUs();
        }
        break;
      }
    case 'es':
      {
        switch (locale.countryCode) {
          case 'DO':
            return AppLocalizationsEsDo();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
