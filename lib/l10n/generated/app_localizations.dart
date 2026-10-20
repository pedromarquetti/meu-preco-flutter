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

  /// No description provided for @productSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome, GTIN ou marca'**
  String get productSearchHint;

  /// No description provided for @productSearchPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Digite para buscar produtos'**
  String get productSearchPrompt;

  /// No description provided for @productSearchNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto encontrado'**
  String get productSearchNoResults;

  /// No description provided for @productSearchLoading.
  ///
  /// In pt, this message translates to:
  /// **'Buscando produtos'**
  String get productSearchLoading;

  /// No description provided for @productBrandLabel.
  ///
  /// In pt, this message translates to:
  /// **'Marca'**
  String get productBrandLabel;

  /// No description provided for @productGtinLabel.
  ///
  /// In pt, this message translates to:
  /// **'GTIN'**
  String get productGtinLabel;

  /// No description provided for @productUnitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Unidade'**
  String get productUnitLabel;

  /// No description provided for @productNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Produto não encontrado.'**
  String get productNotFound;

  /// No description provided for @productHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de preços'**
  String get productHistoryTitle;

  /// No description provided for @productHistoryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sem histórico de preços'**
  String get productHistoryEmpty;

  /// No description provided for @productHistoryFromLabel.
  ///
  /// In pt, this message translates to:
  /// **'De'**
  String get productHistoryFromLabel;

  /// No description provided for @productHistoryToLabel.
  ///
  /// In pt, this message translates to:
  /// **'Até'**
  String get productHistoryToLabel;

  /// No description provided for @productHistoryClearRangeAction.
  ///
  /// In pt, this message translates to:
  /// **'Limpar período'**
  String get productHistoryClearRangeAction;

  /// No description provided for @productHistoryApplyRangeAction.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get productHistoryApplyRangeAction;

  /// No description provided for @productSupermarketLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mercado'**
  String get productSupermarketLabel;

  /// No description provided for @productLoggedAtLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get productLoggedAtLabel;

  /// No description provided for @productQtyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get productQtyLabel;

  /// No description provided for @productPricePerUnitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço por unidade'**
  String get productPricePerUnitLabel;

  /// No description provided for @productUnitPriceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço da unidade'**
  String get productUnitPriceLabel;

  /// No description provided for @productTotalPriceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get productTotalPriceLabel;

  /// No description provided for @productAggregateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo por unidade'**
  String get productAggregateTitle;

  /// No description provided for @productAggregateCountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Registros'**
  String get productAggregateCountLabel;

  /// No description provided for @productAggregateMinLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo'**
  String get productAggregateMinLabel;

  /// No description provided for @productAggregateAvgLabel.
  ///
  /// In pt, this message translates to:
  /// **'Média'**
  String get productAggregateAvgLabel;

  /// No description provided for @productAggregateMaxLabel.
  ///
  /// In pt, this message translates to:
  /// **'Máximo'**
  String get productAggregateMaxLabel;

  /// No description provided for @productAggregateLastLabel.
  ///
  /// In pt, this message translates to:
  /// **'Último'**
  String get productAggregateLastLabel;

  /// No description provided for @invalidDateRangeError.
  ///
  /// In pt, this message translates to:
  /// **'A data inicial deve ser anterior ou igual à final.'**
  String get invalidDateRangeError;

  /// No description provided for @productPriceGraphLabel.
  ///
  /// In pt, this message translates to:
  /// **'Evolução do preço'**
  String get productPriceGraphLabel;

  /// No description provided for @priceChartTooShort.
  ///
  /// In pt, this message translates to:
  /// **'Histórico curto demais para montar o gráfico.'**
  String get priceChartTooShort;

  /// No description provided for @priceChartMinLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo'**
  String get priceChartMinLabel;

  /// No description provided for @priceChartMaxLabel.
  ///
  /// In pt, this message translates to:
  /// **'Máximo'**
  String get priceChartMaxLabel;

  /// No description provided for @priceChartSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Gráfico de preços de {min} a {max} por {unit}.'**
  String priceChartSemantics(String min, String max, String unit);

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

  /// No description provided for @scanQrAction.
  ///
  /// In pt, this message translates to:
  /// **'Escanear QR'**
  String get scanQrAction;

  /// No description provided for @pasteNfceKeyAction.
  ///
  /// In pt, this message translates to:
  /// **'Colar chave da NFC-e'**
  String get pasteNfceKeyAction;

  /// No description provided for @scanWithCameraAction.
  ///
  /// In pt, this message translates to:
  /// **'Escanear com a câmera'**
  String get scanWithCameraAction;

  /// No description provided for @scanQrHelp.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmera para o QR Code do cupom.'**
  String get scanQrHelp;

  /// No description provided for @scanQrUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'A câmera não está disponível neste dispositivo. Cole o conteúdo do QR Code.'**
  String get scanQrUnavailable;

  /// No description provided for @scanReceiptTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escanear NFC-e'**
  String get scanReceiptTitle;

  /// No description provided for @scannerPreparingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preparando câmera'**
  String get scannerPreparingLabel;

  /// No description provided for @scannerInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Alinhe o QR Code da NFC-e dentro do quadrado.'**
  String get scannerInstruction;

  /// No description provided for @cameraUnavailableTitle.
  ///
  /// In pt, this message translates to:
  /// **'Câmera indisponível'**
  String get cameraUnavailableTitle;

  /// No description provided for @cameraUnsupportedMessage.
  ///
  /// In pt, this message translates to:
  /// **'A leitura com câmera não é suportada neste dispositivo ou plataforma.'**
  String get cameraUnsupportedMessage;

  /// No description provided for @cameraNoCameraMessage.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma câmera foi encontrada neste dispositivo.'**
  String get cameraNoCameraMessage;

  /// No description provided for @cameraErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir a câmera. Tente novamente.'**
  String get cameraErrorMessage;

  /// No description provided for @cameraPermissionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Permissão da câmera'**
  String get cameraPermissionTitle;

  /// No description provided for @cameraPermissionDeniedMessage.
  ///
  /// In pt, this message translates to:
  /// **'É necessário permitir o acesso à câmera para escanear o QR Code.'**
  String get cameraPermissionDeniedMessage;

  /// No description provided for @cameraPermissionForeverMessage.
  ///
  /// In pt, this message translates to:
  /// **'O acesso à câmera foi negado permanentemente. Abra as configurações do app para habilitá-lo.'**
  String get cameraPermissionForeverMessage;

  /// No description provided for @cameraPermissionRetryAction.
  ///
  /// In pt, this message translates to:
  /// **'Solicitar permissão'**
  String get cameraPermissionRetryAction;

  /// No description provided for @openSettingsAction.
  ///
  /// In pt, this message translates to:
  /// **'Abrir configurações'**
  String get openSettingsAction;

  /// No description provided for @accessKeyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Chave de acesso'**
  String get accessKeyLabel;

  /// No description provided for @accessKeyHint.
  ///
  /// In pt, this message translates to:
  /// **'44 dígitos'**
  String get accessKeyHint;

  /// No description provided for @accessKeyHelp.
  ///
  /// In pt, this message translates to:
  /// **'Fica no rodapé do cupom fiscal.'**
  String get accessKeyHelp;

  /// No description provided for @qrPayloadLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conteúdo do QR Code'**
  String get qrPayloadLabel;

  /// No description provided for @qrPayloadHint.
  ///
  /// In pt, this message translates to:
  /// **'Cole aqui o link do QR Code do cupom'**
  String get qrPayloadHint;

  /// No description provided for @invalidAccessKeyError.
  ///
  /// In pt, this message translates to:
  /// **'Informe os 44 dígitos da chave de acesso'**
  String get invalidAccessKeyError;

  /// No description provided for @invalidQrPayloadError.
  ///
  /// In pt, this message translates to:
  /// **'Informe um QR Code válido'**
  String get invalidQrPayloadError;

  /// No description provided for @extractAccessKeyFromQrAction.
  ///
  /// In pt, this message translates to:
  /// **'Extrair chave de acesso do QR Code'**
  String get extractAccessKeyFromQrAction;

  /// No description provided for @extractAccessKeyFromQrNoMatchError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível extrair uma chave de 44 dígitos do conteúdo do QR Code.'**
  String get extractAccessKeyFromQrNoMatchError;

  /// No description provided for @draftingReceiptLabel.
  ///
  /// In pt, this message translates to:
  /// **'Processando o cupom...'**
  String get draftingReceiptLabel;

  /// No description provided for @submittingReceiptLabel.
  ///
  /// In pt, this message translates to:
  /// **'Enviando o cupom...'**
  String get submittingReceiptLabel;

  /// No description provided for @captchaTitle.
  ///
  /// In pt, this message translates to:
  /// **'Verificação de segurança'**
  String get captchaTitle;

  /// No description provided for @captchaDescription.
  ///
  /// In pt, this message translates to:
  /// **'Digite os caracteres da imagem para continuar.'**
  String get captchaDescription;

  /// No description provided for @captchaSolutionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Resposta'**
  String get captchaSolutionLabel;

  /// No description provided for @captchaSolveAction.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get captchaSolveAction;

  /// No description provided for @captchaReloadAction.
  ///
  /// In pt, this message translates to:
  /// **'Recarregar imagem'**
  String get captchaReloadAction;

  /// No description provided for @captchaImageUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a imagem.'**
  String get captchaImageUnavailable;

  /// No description provided for @captchaWrongSolutionError.
  ///
  /// In pt, this message translates to:
  /// **'Resposta incorreta. Tente novamente.'**
  String get captchaWrongSolutionError;

  /// No description provided for @captchaAttemptsLeft.
  ///
  /// In pt, this message translates to:
  /// **'Tentativas restantes: {count}'**
  String captchaAttemptsLeft(int count);

  /// No description provided for @captchaExpiredError.
  ///
  /// In pt, this message translates to:
  /// **'Este desafio expirou. Leia o cupom novamente.'**
  String get captchaExpiredError;

  /// No description provided for @captchaLockedError.
  ///
  /// In pt, this message translates to:
  /// **'Muitas respostas incorretas. Leia o cupom novamente.'**
  String get captchaLockedError;

  /// No description provided for @captchaUsedError.
  ///
  /// In pt, this message translates to:
  /// **'Este desafio já foi utilizado.'**
  String get captchaUsedError;

  /// No description provided for @captchaNotFoundError.
  ///
  /// In pt, this message translates to:
  /// **'Desafio não encontrado.'**
  String get captchaNotFoundError;

  /// No description provided for @previewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confira os dados do cupom'**
  String get previewTitle;

  /// No description provided for @previewAccessKeyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Chave de acesso'**
  String get previewAccessKeyLabel;

  /// No description provided for @previewExpiresAtLabel.
  ///
  /// In pt, this message translates to:
  /// **'Expira em {time}'**
  String previewExpiresAtLabel(String time);

  /// No description provided for @previewExpiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Prévia expirada'**
  String get previewExpiredLabel;

  /// No description provided for @previewItemsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Itens'**
  String get previewItemsTitle;

  /// No description provided for @previewTotalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get previewTotalsTitle;

  /// No description provided for @previewItemsCountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Itens lidos'**
  String get previewItemsCountLabel;

  /// No description provided for @previewAutoSaveLabel.
  ///
  /// In pt, this message translates to:
  /// **'Salvos automaticamente'**
  String get previewAutoSaveLabel;

  /// No description provided for @previewNeedsReviewLabel.
  ///
  /// In pt, this message translates to:
  /// **'Precisam de revisão'**
  String get previewNeedsReviewLabel;

  /// No description provided for @previewParseErrorsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Com erro de leitura'**
  String get previewParseErrorsLabel;

  /// No description provided for @previewEstimatedTotalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Total estimado'**
  String get previewEstimatedTotalLabel;

  /// No description provided for @previewPriceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço'**
  String get previewPriceLabel;

  /// No description provided for @itemStatusGtinKnown.
  ///
  /// In pt, this message translates to:
  /// **'Produto reconhecido'**
  String get itemStatusGtinKnown;

  /// No description provided for @itemStatusGtinNew.
  ///
  /// In pt, this message translates to:
  /// **'Produto novo'**
  String get itemStatusGtinNew;

  /// No description provided for @itemStatusCommodity.
  ///
  /// In pt, this message translates to:
  /// **'Produto a granel'**
  String get itemStatusCommodity;

  /// No description provided for @itemStatusUncertain.
  ///
  /// In pt, this message translates to:
  /// **'Código incerto'**
  String get itemStatusUncertain;

  /// No description provided for @itemStatusParseError.
  ///
  /// In pt, this message translates to:
  /// **'Erro de leitura'**
  String get itemStatusParseError;

  /// No description provided for @itemUncertainHelp.
  ///
  /// In pt, this message translates to:
  /// **'Escolha como tratar este item.'**
  String get itemUncertainHelp;

  /// No description provided for @itemApiMessageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem da API'**
  String get itemApiMessageTitle;

  /// No description provided for @closeAction.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get closeAction;

  /// No description provided for @resolutionNeedsReviewAction.
  ///
  /// In pt, this message translates to:
  /// **'Revisar depois'**
  String get resolutionNeedsReviewAction;

  /// No description provided for @resolutionSkipAction.
  ///
  /// In pt, this message translates to:
  /// **'Ignorar'**
  String get resolutionSkipAction;

  /// No description provided for @resolutionAssignAction.
  ///
  /// In pt, this message translates to:
  /// **'Vincular produto'**
  String get resolutionAssignAction;

  /// No description provided for @assignedProductLabel.
  ///
  /// In pt, this message translates to:
  /// **'Produto vinculado'**
  String get assignedProductLabel;

  /// No description provided for @changeProductAction.
  ///
  /// In pt, this message translates to:
  /// **'Trocar'**
  String get changeProductAction;

  /// No description provided for @clearProductAction.
  ///
  /// In pt, this message translates to:
  /// **'Remover vínculo'**
  String get clearProductAction;

  /// No description provided for @productPickerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar produto'**
  String get productPickerTitle;

  /// No description provided for @submitDryRunAction.
  ///
  /// In pt, this message translates to:
  /// **'Simular envio'**
  String get submitDryRunAction;

  /// No description provided for @submitConfirmAction.
  ///
  /// In pt, this message translates to:
  /// **'Enviar cupom'**
  String get submitConfirmAction;

  /// No description provided for @commitResultTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cupom enviado'**
  String get commitResultTitle;

  /// No description provided for @commitWrittenLabel.
  ///
  /// In pt, this message translates to:
  /// **'Itens registrados'**
  String get commitWrittenLabel;

  /// No description provided for @commitAutoSavedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Salvos automaticamente'**
  String get commitAutoSavedLabel;

  /// No description provided for @commitSkippedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Itens ignorados'**
  String get commitSkippedLabel;

  /// No description provided for @commitNeedsReviewLabel.
  ///
  /// In pt, this message translates to:
  /// **'Para revisão'**
  String get commitNeedsReviewLabel;

  /// No description provided for @commitAssignedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Associados'**
  String get commitAssignedLabel;

  /// No description provided for @doneAction.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get doneAction;

  /// No description provided for @deleteReceiptAction.
  ///
  /// In pt, this message translates to:
  /// **'Excluir cupom'**
  String get deleteReceiptAction;

  /// No description provided for @deleteReceiptConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir cupom?'**
  String get deleteReceiptConfirmTitle;

  /// No description provided for @deleteReceiptConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Os preços deste cupom serão removidos. Esta ação não pode ser desfeita.'**
  String get deleteReceiptConfirmMessage;

  /// No description provided for @deleteReceiptSuccessMessage.
  ///
  /// In pt, this message translates to:
  /// **'Cupom excluído'**
  String get deleteReceiptSuccessMessage;

  /// No description provided for @cancelAction.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancelAction;

  /// No description provided for @deleteAction.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get deleteAction;

  /// No description provided for @startOverAction.
  ///
  /// In pt, this message translates to:
  /// **'Ler outro cupom'**
  String get startOverAction;

  /// No description provided for @receiptNotFoundError.
  ///
  /// In pt, this message translates to:
  /// **'Cupom não encontrado.'**
  String get receiptNotFoundError;

  /// No description provided for @unsupportedUfError.
  ///
  /// In pt, this message translates to:
  /// **'Estado (UF) não suportado.'**
  String get unsupportedUfError;

  /// No description provided for @upstreamErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'O portal da SEFAZ não respondeu. Tente novamente.'**
  String get upstreamErrorMessage;

  /// No description provided for @previewExpiredError.
  ///
  /// In pt, this message translates to:
  /// **'Esta prévia expirou. Leia o cupom novamente.'**
  String get previewExpiredError;

  /// No description provided for @previewNotFoundError.
  ///
  /// In pt, this message translates to:
  /// **'Prévia não encontrada. Leia o cupom novamente.'**
  String get previewNotFoundError;

  /// No description provided for @alreadyCommittedError.
  ///
  /// In pt, this message translates to:
  /// **'Este cupom já foi registrado.'**
  String get alreadyCommittedError;

  /// No description provided for @invalidResolutionError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível aplicar as escolhas dos itens.'**
  String get invalidResolutionError;
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
