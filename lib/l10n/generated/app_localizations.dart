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
  /// **'Entre com seu e-mail ou nome de usuário.'**
  String get loginDescription;

  /// No description provided for @loginIdentifierLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou nome'**
  String get loginIdentifierLabel;

  /// No description provided for @emailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get emailLabel;

  /// No description provided for @nameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get nameLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get confirmPasswordLabel;

  /// No description provided for @signInAction.
  ///
  /// In pt, this message translates to:
  /// **'Fazer login'**
  String get signInAction;

  /// No description provided for @registerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get registerTitle;

  /// No description provided for @registerDescription.
  ///
  /// In pt, this message translates to:
  /// **'Crie uma conta para começar a usar o Meu Preço.'**
  String get registerDescription;

  /// No description provided for @createAccountAction.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get createAccountAction;

  /// No description provided for @needAccountAction.
  ///
  /// In pt, this message translates to:
  /// **'Criar uma conta'**
  String get needAccountAction;

  /// No description provided for @alreadyHaveAccountAction.
  ///
  /// In pt, this message translates to:
  /// **'Já tenho uma conta'**
  String get alreadyHaveAccountAction;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem'**
  String get passwordsDoNotMatch;

  /// No description provided for @invalidIdentifierError.
  ///
  /// In pt, this message translates to:
  /// **'Informe um e-mail ou nome'**
  String get invalidIdentifierError;

  /// No description provided for @invalidNameError.
  ///
  /// In pt, this message translates to:
  /// **'Informe um nome de até 100 caracteres'**
  String get invalidNameError;

  /// No description provided for @invalidEmailError.
  ///
  /// In pt, this message translates to:
  /// **'Informe um e-mail válido'**
  String get invalidEmailError;

  /// No description provided for @weakPasswordError.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter pelo menos 8 caracteres'**
  String get weakPasswordError;

  /// No description provided for @invalidCredentialsError.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou senha inválidos'**
  String get invalidCredentialsError;

  /// No description provided for @userExistsError.
  ///
  /// In pt, this message translates to:
  /// **'Este e-mail já está cadastrado'**
  String get userExistsError;

  /// No description provided for @rateLimitedError.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Tente novamente em instantes'**
  String get rateLimitedError;

  /// No description provided for @networkErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conectar ao servidor'**
  String get networkErrorMessage;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sua sessão expirou. Entre novamente.'**
  String get sessionExpiredMessage;

  /// No description provided for @accountSection.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get accountSection;

  /// No description provided for @currentUserLabel.
  ///
  /// In pt, this message translates to:
  /// **'Usuário'**
  String get currentUserLabel;

  /// No description provided for @roleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get roleLabel;

  /// No description provided for @adminRoleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Administrador'**
  String get adminRoleLabel;

  /// No description provided for @userRoleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Usuário'**
  String get userRoleLabel;

  /// No description provided for @notAuthenticatedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Não autenticado'**
  String get notAuthenticatedLabel;

  /// No description provided for @signOutSuccessMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sessão encerrada'**
  String get signOutSuccessMessage;

  /// No description provided for @homeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get homeTitle;

  /// No description provided for @homeGreeting.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo(a) de volta'**
  String get homeGreeting;

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

  /// No description provided for @connectivitySection.
  ///
  /// In pt, this message translates to:
  /// **'Conectividade'**
  String get connectivitySection;

  /// No description provided for @checkConnectivityAction.
  ///
  /// In pt, this message translates to:
  /// **'Verificar conexão'**
  String get checkConnectivityAction;

  /// No description provided for @healthStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Servidor'**
  String get healthStatusLabel;

  /// No description provided for @readinessStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Prontidão'**
  String get readinessStatusLabel;

  /// No description provided for @readinessHealthyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pronto para uso'**
  String get readinessHealthyLabel;

  /// No description provided for @readinessUnavailableLabel.
  ///
  /// In pt, this message translates to:
  /// **'Indisponível'**
  String get readinessUnavailableLabel;

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
  /// **'Esta funcionalidade ainda não está disponível.'**
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
