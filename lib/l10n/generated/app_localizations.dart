import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meu Preço'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In pt, this message translates to:
  /// **'Compare preços de produtos entre supermercados.'**
  String get appDescription;

  /// No description provided for @serverConfigTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurar servidor'**
  String get serverConfigTitle;

  /// No description provided for @serverConfigDescription.
  ///
  /// In pt, this message translates to:
  /// **'Informe o endereço do servidor Meu Preço que deseja utilizar.'**
  String get serverConfigDescription;

  /// No description provided for @serverAddressLabel.
  ///
  /// In pt, this message translates to:
  /// **'Endereço do servidor'**
  String get serverAddressLabel;

  /// No description provided for @serverAddressHint.
  ///
  /// In pt, this message translates to:
  /// **'https://meu-preco.exemplo.com'**
  String get serverAddressHint;

  /// No description provided for @serverAddressHelp.
  ///
  /// In pt, this message translates to:
  /// **'Pode ser informado com ou sem o prefixo /api/v1.'**
  String get serverAddressHelp;

  /// No description provided for @testConnection.
  ///
  /// In pt, this message translates to:
  /// **'Testar conexão'**
  String get testConnection;

  /// No description provided for @saveAndContinue.
  ///
  /// In pt, this message translates to:
  /// **'Salvar e continuar'**
  String get saveAndContinue;

  /// No description provided for @serverConnectionSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Servidor disponível'**
  String get serverConnectionSuccess;

  /// No description provided for @serverConnectionFailure.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conectar ao servidor'**
  String get serverConnectionFailure;

  /// No description provided for @serverConnectionTimeout.
  ///
  /// In pt, this message translates to:
  /// **'O servidor demorou demais para responder'**
  String get serverConnectionTimeout;

  /// No description provided for @invalidServerUrl.
  ///
  /// In pt, this message translates to:
  /// **'Informe uma URL válida, começando com http:// ou https://'**
  String get invalidServerUrl;

  /// No description provided for @continueAction.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get continueAction;

  /// No description provided for @loginTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginTitle;

  /// No description provided for @loginDescription.
  ///
  /// In pt, this message translates to:
  /// **'Ainda faremos o login nesta etapa. Esta tela é um marcador da Fase 1.'**
  String get loginDescription;

  /// No description provided for @emailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get passwordLabel;

  /// No description provided for @signInAction.
  ///
  /// In pt, this message translates to:
  /// **'Fazer login'**
  String get signInAction;

  /// No description provided for @homeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get homeTitle;

  /// No description provided for @scanReceiptAction.
  ///
  /// In pt, this message translates to:
  /// **'Escanear NFC-e'**
  String get scanReceiptAction;

  /// No description provided for @searchProductAction.
  ///
  /// In pt, this message translates to:
  /// **'Buscar produto'**
  String get searchProductAction;

  /// No description provided for @receiptSubmissionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova NFC-e'**
  String get receiptSubmissionTitle;

  /// No description provided for @productSearchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Produtos'**
  String get productSearchTitle;

  /// No description provided for @productDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Produto'**
  String get productDetailTitle;

  /// No description provided for @supermarketsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Supermercados'**
  String get supermarketsTitle;

  /// No description provided for @adminTitle.
  ///
  /// In pt, this message translates to:
  /// **'Administração'**
  String get adminTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// No description provided for @settingsServerSection.
  ///
  /// In pt, this message translates to:
  /// **'Servidor'**
  String get settingsServerSection;

  /// No description provided for @settingsResetToDefault.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar padrão'**
  String get settingsResetToDefault;

  /// No description provided for @logoutAction.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get logoutAction;

  /// No description provided for @loadingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get loadingLabel;

  /// No description provided for @emptyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nada por aqui ainda'**
  String get emptyLabel;

  /// No description provided for @errorLabel.
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado'**
  String get errorLabel;

  /// No description provided for @retryAction.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retryAction;

  /// No description provided for @comingSoonLabel.
  ///
  /// In pt, this message translates to:
  /// **'Em breve'**
  String get comingSoonLabel;

  /// No description provided for @notImplementedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Esta funcionalidade será implementada em uma fase futura.'**
  String get notImplementedLabel;

  /// No description provided for @currentHostLabel.
  ///
  /// In pt, this message translates to:
  /// **'Servidor atual'**
  String get currentHostLabel;

  /// No description provided for @apiPrefixLabel.
  ///
  /// In pt, this message translates to:
  /// **'Prefixo da API'**
  String get apiPrefixLabel;

  /// No description provided for @notConfiguredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Não configurado'**
  String get notConfiguredLabel;
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
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
