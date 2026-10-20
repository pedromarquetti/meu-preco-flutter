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

  /// AppTitle
  ///
  /// In pt, this message translates to:
  /// **'Meu Preço'**
  String get appTitle;

  /// AppDescription
  ///
  /// In pt, this message translates to:
  /// **'Compare preços de produtos entre supermercados.'**
  String get appDescription;

  /// ServerConfigTitle
  ///
  /// In pt, this message translates to:
  /// **'Configurar servidor'**
  String get serverConfigTitle;

  /// ServerConfigDescription
  ///
  /// In pt, this message translates to:
  /// **'Informe o endereço do servidor Meu Preço que deseja utilizar.'**
  String get serverConfigDescription;

  /// ServerAddress
  ///
  /// In pt, this message translates to:
  /// **'Endereço do servidor'**
  String get serverAddressLabel;

  /// ServerAddressHint
  ///
  /// In pt, this message translates to:
  /// **'https://meu-preco.exemplo.com'**
  String get serverAddressHint;

  /// ServerAddressHelp
  ///
  /// In pt, this message translates to:
  /// **'Pode ser informado com ou sem o prefixo /api/v1.'**
  String get serverAddressHelp;

  /// TestConnection
  ///
  /// In pt, this message translates to:
  /// **'Testar conexão'**
  String get testConnection;

  /// SaveAndContinue
  ///
  /// In pt, this message translates to:
  /// **'Salvar e continuar'**
  String get saveAndContinue;

  /// ServerConnectionSuccess
  ///
  /// In pt, this message translates to:
  /// **'Servidor disponível'**
  String get serverConnectionSuccess;

  /// ServerConnectionFailure
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conectar ao servidor'**
  String get serverConnectionFailure;

  /// ServerConnectionTimeout
  ///
  /// In pt, this message translates to:
  /// **'O servidor demorou demais para responder'**
  String get serverConnectionTimeout;

  /// InvalidServerUrl
  ///
  /// In pt, this message translates to:
  /// **'Informe uma URL válida, começando com http:// ou https://'**
  String get invalidServerUrl;

  /// Continue
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get continueAction;

  /// LoginTitle
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginTitle;

  /// LoginDescription
  ///
  /// In pt, this message translates to:
  /// **'Entre com seu e-mail ou nome de usuário.'**
  String get loginDescription;

  /// LoginIdentifier
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou nome'**
  String get loginIdentifierLabel;

  /// Email
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get emailLabel;

  /// Name
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get nameLabel;

  /// Password
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get passwordLabel;

  /// ConfirmPassword
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get confirmPasswordLabel;

  /// SignIn
  ///
  /// In pt, this message translates to:
  /// **'Fazer login'**
  String get signInAction;

  /// RegisterTitle
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get registerTitle;

  /// RegisterDescription
  ///
  /// In pt, this message translates to:
  /// **'Crie uma conta para começar a usar o Meu Preço.'**
  String get registerDescription;

  /// CreateAccount
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get createAccountAction;

  /// NeedAccount
  ///
  /// In pt, this message translates to:
  /// **'Criar uma conta'**
  String get needAccountAction;

  /// AlreadyHaveAccount
  ///
  /// In pt, this message translates to:
  /// **'Já tenho uma conta'**
  String get alreadyHaveAccountAction;

  /// PasswordsDoNotMatch
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem'**
  String get passwordsDoNotMatch;

  /// InvalidIdentifier
  ///
  /// In pt, this message translates to:
  /// **'Informe um e-mail ou nome'**
  String get invalidIdentifierError;

  /// InvalidName
  ///
  /// In pt, this message translates to:
  /// **'Informe um nome de até 100 caracteres'**
  String get invalidNameError;

  /// InvalidEmail
  ///
  /// In pt, this message translates to:
  /// **'Informe um e-mail válido'**
  String get invalidEmailError;

  /// WeakPassword
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter pelo menos 8 caracteres'**
  String get weakPasswordError;

  /// InvalidCredentials
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou senha inválidos'**
  String get invalidCredentialsError;

  /// UserExists
  ///
  /// In pt, this message translates to:
  /// **'Este e-mail já está cadastrado'**
  String get userExistsError;

  /// RateLimited
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Tente novamente em instantes'**
  String get rateLimitedError;

  /// Network
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conectar ao servidor'**
  String get networkErrorMessage;

  /// SessionExpired
  ///
  /// In pt, this message translates to:
  /// **'Sua sessão expirou. Entre novamente.'**
  String get sessionExpiredMessage;

  /// AccountSection
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get accountSection;

  /// CurrentUser
  ///
  /// In pt, this message translates to:
  /// **'Usuário'**
  String get currentUserLabel;

  /// Role
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get roleLabel;

  /// AdminRole
  ///
  /// In pt, this message translates to:
  /// **'Administrador'**
  String get adminRoleLabel;

  /// UserRole
  ///
  /// In pt, this message translates to:
  /// **'Usuário'**
  String get userRoleLabel;

  /// NotAuthenticated
  ///
  /// In pt, this message translates to:
  /// **'Não autenticado'**
  String get notAuthenticatedLabel;

  /// SignOutSuccess
  ///
  /// In pt, this message translates to:
  /// **'Sessão encerrada'**
  String get signOutSuccessMessage;

  /// HomeTitle
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get homeTitle;

  /// HomeGreeting
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo(a) de volta'**
  String get homeGreeting;

  /// ScanReceipt
  ///
  /// In pt, this message translates to:
  /// **'Escanear NFC-e'**
  String get scanReceiptAction;

  /// SearchProduct
  ///
  /// In pt, this message translates to:
  /// **'Buscar produto'**
  String get searchProductAction;

  /// ReceiptSubmissionTitle
  ///
  /// In pt, this message translates to:
  /// **'Nova NFC-e'**
  String get receiptSubmissionTitle;

  /// ProductSearchTitle
  ///
  /// In pt, this message translates to:
  /// **'Produtos'**
  String get productSearchTitle;

  /// ProductDetailTitle
  ///
  /// In pt, this message translates to:
  /// **'Produto'**
  String get productDetailTitle;

  /// ProductSearchHint
  ///
  /// In pt, this message translates to:
  /// **'Nome, GTIN ou marca'**
  String get productSearchHint;

  /// ProductSearchPrompt
  ///
  /// In pt, this message translates to:
  /// **'Digite para buscar produtos'**
  String get productSearchPrompt;

  /// ProductSearchNoResults
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto encontrado'**
  String get productSearchNoResults;

  /// ProductSearchLoading
  ///
  /// In pt, this message translates to:
  /// **'Buscando produtos'**
  String get productSearchLoading;

  /// ProductBrand
  ///
  /// In pt, this message translates to:
  /// **'Marca'**
  String get productBrandLabel;

  /// ProductGtin
  ///
  /// In pt, this message translates to:
  /// **'GTIN'**
  String get productGtinLabel;

  /// ProductUnit
  ///
  /// In pt, this message translates to:
  /// **'Unidade'**
  String get productUnitLabel;

  /// ProductNotFound
  ///
  /// In pt, this message translates to:
  /// **'Produto não encontrado.'**
  String get productNotFound;

  /// ProductHistoryTitle
  ///
  /// In pt, this message translates to:
  /// **'Histórico de preços'**
  String get productHistoryTitle;

  /// ProductHistoryEmpty
  ///
  /// In pt, this message translates to:
  /// **'Sem histórico de preços'**
  String get productHistoryEmpty;

  /// ProductHistoryFrom
  ///
  /// In pt, this message translates to:
  /// **'De'**
  String get productHistoryFromLabel;

  /// ProductHistoryTo
  ///
  /// In pt, this message translates to:
  /// **'Até'**
  String get productHistoryToLabel;

  /// ProductHistoryClearRange
  ///
  /// In pt, this message translates to:
  /// **'Limpar período'**
  String get productHistoryClearRangeAction;

  /// ProductHistoryApplyRange
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get productHistoryApplyRangeAction;

  /// ProductSupermarket
  ///
  /// In pt, this message translates to:
  /// **'Mercado'**
  String get productSupermarketLabel;

  /// ProductLoggedAt
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get productLoggedAtLabel;

  /// ProductQty
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get productQtyLabel;

  /// ProductPricePerUnit
  ///
  /// In pt, this message translates to:
  /// **'Preço por unidade'**
  String get productPricePerUnitLabel;

  /// ProductUnitPrice
  ///
  /// In pt, this message translates to:
  /// **'Preço da unidade'**
  String get productUnitPriceLabel;

  /// ProductTotalPrice
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get productTotalPriceLabel;

  /// ProductAggregateTitle
  ///
  /// In pt, this message translates to:
  /// **'Resumo por unidade'**
  String get productAggregateTitle;

  /// ProductAggregateCount
  ///
  /// In pt, this message translates to:
  /// **'Registros'**
  String get productAggregateCountLabel;

  /// ProductUpdated
  ///
  /// In pt, this message translates to:
  /// **'Produto atualizado'**
  String get productUpdated;

  /// ProductAggregateMin
  ///
  /// In pt, this message translates to:
  /// **'Mínimo'**
  String get productAggregateMinLabel;

  /// ProductAggregateAvg
  ///
  /// In pt, this message translates to:
  /// **'Média'**
  String get productAggregateAvgLabel;

  /// ProductAggregateMax
  ///
  /// In pt, this message translates to:
  /// **'Máximo'**
  String get productAggregateMaxLabel;

  /// ProductAggregateLast
  ///
  /// In pt, this message translates to:
  /// **'Último'**
  String get productAggregateLastLabel;

  /// InvalidDateRange
  ///
  /// In pt, this message translates to:
  /// **'A data inicial deve ser anterior ou igual à final.'**
  String get invalidDateRangeError;

  /// ProductPriceGraph
  ///
  /// In pt, this message translates to:
  /// **'Evolução do preço'**
  String get productPriceGraphLabel;

  /// PriceChartTooShort
  ///
  /// In pt, this message translates to:
  /// **'Histórico curto demais para montar o gráfico.'**
  String get priceChartTooShort;

  /// PriceChartMin
  ///
  /// In pt, this message translates to:
  /// **'Mínimo'**
  String get priceChartMinLabel;

  /// PriceChartMax
  ///
  /// In pt, this message translates to:
  /// **'Máximo'**
  String get priceChartMaxLabel;

  /// No description provided for @priceChartSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Gráfico de preços de {min} a {max} por {unit}.'**
  String priceChartSemantics(String min, String max, String unit);

  /// SupermarketsTitle
  ///
  /// In pt, this message translates to:
  /// **'Supermercados'**
  String get supermarketsTitle;

  /// AdminTitle
  ///
  /// In pt, this message translates to:
  /// **'Administração'**
  String get adminTitle;

  /// SettingsTitle
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// SettingsServerSection
  ///
  /// In pt, this message translates to:
  /// **'Servidor'**
  String get settingsServerSection;

  /// ConnectivitySection
  ///
  /// In pt, this message translates to:
  /// **'Conectividade'**
  String get connectivitySection;

  /// CheckConnectivity
  ///
  /// In pt, this message translates to:
  /// **'Verificar conexão'**
  String get checkConnectivityAction;

  /// HealthStatus
  ///
  /// In pt, this message translates to:
  /// **'Servidor'**
  String get healthStatusLabel;

  /// ReadinessStatus
  ///
  /// In pt, this message translates to:
  /// **'Prontidão'**
  String get readinessStatusLabel;

  /// ReadinessHealthy
  ///
  /// In pt, this message translates to:
  /// **'Pronto para uso'**
  String get readinessHealthyLabel;

  /// ReadinessUnavailable
  ///
  /// In pt, this message translates to:
  /// **'Indisponível'**
  String get readinessUnavailableLabel;

  /// SettingsResetToDefault
  ///
  /// In pt, this message translates to:
  /// **'Restaurar padrão'**
  String get settingsResetToDefault;

  /// Logout
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get logoutAction;

  /// Loading
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get loadingLabel;

  /// Empty
  ///
  /// In pt, this message translates to:
  /// **'Nada por aqui ainda'**
  String get emptyLabel;

  /// Error
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado'**
  String get errorLabel;

  /// Retry
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retryAction;

  /// ComingSoon
  ///
  /// In pt, this message translates to:
  /// **'Em breve'**
  String get comingSoonLabel;

  /// NotImplemented
  ///
  /// In pt, this message translates to:
  /// **'Esta funcionalidade ainda não está disponível.'**
  String get notImplementedLabel;

  /// CurrentHost
  ///
  /// In pt, this message translates to:
  /// **'Servidor atual'**
  String get currentHostLabel;

  /// ApiPrefix
  ///
  /// In pt, this message translates to:
  /// **'Prefixo da API'**
  String get apiPrefixLabel;

  /// NotConfigured
  ///
  /// In pt, this message translates to:
  /// **'Não configurado'**
  String get notConfiguredLabel;

  /// ScanQr
  ///
  /// In pt, this message translates to:
  /// **'Escanear QR'**
  String get scanQrAction;

  /// PasteNfceKey
  ///
  /// In pt, this message translates to:
  /// **'Colar chave da NFC-e'**
  String get pasteNfceKeyAction;

  /// ScanWithCamera
  ///
  /// In pt, this message translates to:
  /// **'Escanear com a câmera'**
  String get scanWithCameraAction;

  /// ScanQrHelp
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmera para o QR Code do cupom.'**
  String get scanQrHelp;

  /// ScanQrUnavailable
  ///
  /// In pt, this message translates to:
  /// **'A câmera não está disponível neste dispositivo. Cole o conteúdo do QR Code.'**
  String get scanQrUnavailable;

  /// ScanReceiptTitle
  ///
  /// In pt, this message translates to:
  /// **'Escanear NFC-e'**
  String get scanReceiptTitle;

  /// ScannerPreparing
  ///
  /// In pt, this message translates to:
  /// **'Preparando câmera'**
  String get scannerPreparingLabel;

  /// ScannerInstruction
  ///
  /// In pt, this message translates to:
  /// **'Alinhe o QR Code da NFC-e dentro do quadrado.'**
  String get scannerInstruction;

  /// CameraUnavailableTitle
  ///
  /// In pt, this message translates to:
  /// **'Câmera indisponível'**
  String get cameraUnavailableTitle;

  /// CameraUnsupported
  ///
  /// In pt, this message translates to:
  /// **'A leitura com câmera não é suportada neste dispositivo ou plataforma.'**
  String get cameraUnsupportedMessage;

  /// CameraNoCamera
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma câmera foi encontrada neste dispositivo.'**
  String get cameraNoCameraMessage;

  /// Camera
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir a câmera. Tente novamente.'**
  String get cameraErrorMessage;

  /// CameraPermissionTitle
  ///
  /// In pt, this message translates to:
  /// **'Permissão da câmera'**
  String get cameraPermissionTitle;

  /// CameraPermissionDenied
  ///
  /// In pt, this message translates to:
  /// **'É necessário permitir o acesso à câmera para escanear o QR Code.'**
  String get cameraPermissionDeniedMessage;

  /// CameraPermissionForever
  ///
  /// In pt, this message translates to:
  /// **'O acesso à câmera foi negado permanentemente. Abra as configurações do app para habilitá-lo.'**
  String get cameraPermissionForeverMessage;

  /// CameraPermissionRetry
  ///
  /// In pt, this message translates to:
  /// **'Solicitar permissão'**
  String get cameraPermissionRetryAction;

  /// OpenSettings
  ///
  /// In pt, this message translates to:
  /// **'Abrir configurações'**
  String get openSettingsAction;

  /// AccessKey
  ///
  /// In pt, this message translates to:
  /// **'Chave de acesso'**
  String get accessKeyLabel;

  /// AccessKeyHint
  ///
  /// In pt, this message translates to:
  /// **'44 dígitos'**
  String get accessKeyHint;

  /// AccessKeyHelp
  ///
  /// In pt, this message translates to:
  /// **'Fica no rodapé do cupom fiscal.'**
  String get accessKeyHelp;

  /// QrPayload
  ///
  /// In pt, this message translates to:
  /// **'Conteúdo do QR Code'**
  String get qrPayloadLabel;

  /// QrPayloadHint
  ///
  /// In pt, this message translates to:
  /// **'Cole aqui o link do QR Code do cupom'**
  String get qrPayloadHint;

  /// InvalidAccessKey
  ///
  /// In pt, this message translates to:
  /// **'Informe os 44 dígitos da chave de acesso'**
  String get invalidAccessKeyError;

  /// InvalidQrPayload
  ///
  /// In pt, this message translates to:
  /// **'Informe um QR Code válido'**
  String get invalidQrPayloadError;

  /// Extract access key from QR
  ///
  /// In pt, this message translates to:
  /// **'Extrair chave de acesso do QR Code'**
  String get extractAccessKeyFromQrAction;

  /// No 44-digit key found in QR
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível extrair uma chave de 44 dígitos do conteúdo do QR Code.'**
  String get extractAccessKeyFromQrNoMatchError;

  /// DraftingReceipt
  ///
  /// In pt, this message translates to:
  /// **'Processando o cupom...'**
  String get draftingReceiptLabel;

  /// SubmittingReceipt
  ///
  /// In pt, this message translates to:
  /// **'Enviando o cupom...'**
  String get submittingReceiptLabel;

  /// CaptchaTitle
  ///
  /// In pt, this message translates to:
  /// **'Verificação de segurança'**
  String get captchaTitle;

  /// CaptchaDescription
  ///
  /// In pt, this message translates to:
  /// **'Digite os caracteres da imagem para continuar.'**
  String get captchaDescription;

  /// CaptchaSolution
  ///
  /// In pt, this message translates to:
  /// **'Resposta'**
  String get captchaSolutionLabel;

  /// CaptchaSolve
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get captchaSolveAction;

  /// CaptchaReload
  ///
  /// In pt, this message translates to:
  /// **'Recarregar imagem'**
  String get captchaReloadAction;

  /// CaptchaImageUnavailable
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a imagem.'**
  String get captchaImageUnavailable;

  /// CaptchaWrongSolution
  ///
  /// In pt, this message translates to:
  /// **'Resposta incorreta. Tente novamente.'**
  String get captchaWrongSolutionError;

  /// No description provided for @captchaAttemptsLeft.
  ///
  /// In pt, this message translates to:
  /// **'Tentativas restantes: {count}'**
  String captchaAttemptsLeft(int count);

  /// CaptchaExpired
  ///
  /// In pt, this message translates to:
  /// **'Este desafio expirou. Leia o cupom novamente.'**
  String get captchaExpiredError;

  /// CaptchaLocked
  ///
  /// In pt, this message translates to:
  /// **'Muitas respostas incorretas. Leia o cupom novamente.'**
  String get captchaLockedError;

  /// CaptchaUsed
  ///
  /// In pt, this message translates to:
  /// **'Este desafio já foi utilizado.'**
  String get captchaUsedError;

  /// CaptchaNotFound
  ///
  /// In pt, this message translates to:
  /// **'Desafio não encontrado.'**
  String get captchaNotFoundError;

  /// PreviewTitle
  ///
  /// In pt, this message translates to:
  /// **'Confira os dados do cupom'**
  String get previewTitle;

  /// PreviewAccessKey
  ///
  /// In pt, this message translates to:
  /// **'Chave de acesso'**
  String get previewAccessKeyLabel;

  /// No description provided for @previewExpiresAtLabel.
  ///
  /// In pt, this message translates to:
  /// **'Expira em {time}'**
  String previewExpiresAtLabel(String time);

  /// PreviewExpired
  ///
  /// In pt, this message translates to:
  /// **'Prévia expirada'**
  String get previewExpiredLabel;

  /// PreviewItemsTitle
  ///
  /// In pt, this message translates to:
  /// **'Itens'**
  String get previewItemsTitle;

  /// PreviewTotalsTitle
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get previewTotalsTitle;

  /// PreviewItemsCount
  ///
  /// In pt, this message translates to:
  /// **'Itens lidos'**
  String get previewItemsCountLabel;

  /// PreviewAutoSave
  ///
  /// In pt, this message translates to:
  /// **'Salvos automaticamente'**
  String get previewAutoSaveLabel;

  /// PreviewNeedsReview
  ///
  /// In pt, this message translates to:
  /// **'Precisam de revisão'**
  String get previewNeedsReviewLabel;

  /// PreviewParses
  ///
  /// In pt, this message translates to:
  /// **'Com erro de leitura'**
  String get previewParseErrorsLabel;

  /// PreviewEstimatedTotal
  ///
  /// In pt, this message translates to:
  /// **'Total estimado'**
  String get previewEstimatedTotalLabel;

  /// PreviewPrice
  ///
  /// In pt, this message translates to:
  /// **'Preço'**
  String get previewPriceLabel;

  /// ItemStatusGtinKnown
  ///
  /// In pt, this message translates to:
  /// **'Produto reconhecido'**
  String get itemStatusGtinKnown;

  /// ItemStatusGtinNew
  ///
  /// In pt, this message translates to:
  /// **'Produto novo'**
  String get itemStatusGtinNew;

  /// ItemStatusCommodity
  ///
  /// In pt, this message translates to:
  /// **'Produto a granel'**
  String get itemStatusCommodity;

  /// ItemStatusUncertain
  ///
  /// In pt, this message translates to:
  /// **'Código incerto'**
  String get itemStatusUncertain;

  /// ItemStatusParse
  ///
  /// In pt, this message translates to:
  /// **'Erro de leitura'**
  String get itemStatusParseError;

  /// ItemUncertainHelp
  ///
  /// In pt, this message translates to:
  /// **'Escolha como tratar este item.'**
  String get itemUncertainHelp;

  /// ItemApiTitle
  ///
  /// In pt, this message translates to:
  /// **'Mensagem da API'**
  String get itemApiMessageTitle;

  /// Close
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get closeAction;

  /// ResolutionNeedsReview
  ///
  /// In pt, this message translates to:
  /// **'Revisar depois'**
  String get resolutionNeedsReviewAction;

  /// ResolutionSkip
  ///
  /// In pt, this message translates to:
  /// **'Ignorar'**
  String get resolutionSkipAction;

  /// ResolutionAssign
  ///
  /// In pt, this message translates to:
  /// **'Vincular produto'**
  String get resolutionAssignAction;

  /// AssignedProduct
  ///
  /// In pt, this message translates to:
  /// **'Produto vinculado'**
  String get assignedProductLabel;

  /// ChangeProduct
  ///
  /// In pt, this message translates to:
  /// **'Trocar'**
  String get changeProductAction;

  /// ClearProduct
  ///
  /// In pt, this message translates to:
  /// **'Remover vínculo'**
  String get clearProductAction;

  /// ProductPickerTitle
  ///
  /// In pt, this message translates to:
  /// **'Selecionar produto'**
  String get productPickerTitle;

  /// SubmitDryRun
  ///
  /// In pt, this message translates to:
  /// **'Simular envio'**
  String get submitDryRunAction;

  /// SubmitConfirm
  ///
  /// In pt, this message translates to:
  /// **'Enviar cupom'**
  String get submitConfirmAction;

  /// CommitResultTitle
  ///
  /// In pt, this message translates to:
  /// **'Cupom enviado'**
  String get commitResultTitle;

  /// CommitWritten
  ///
  /// In pt, this message translates to:
  /// **'Itens registrados'**
  String get commitWrittenLabel;

  /// CommitAutoSaved
  ///
  /// In pt, this message translates to:
  /// **'Salvos automaticamente'**
  String get commitAutoSavedLabel;

  /// CommitSkipped
  ///
  /// In pt, this message translates to:
  /// **'Itens ignorados'**
  String get commitSkippedLabel;

  /// CommitNeedsReview
  ///
  /// In pt, this message translates to:
  /// **'Para revisão'**
  String get commitNeedsReviewLabel;

  /// CommitAssigned
  ///
  /// In pt, this message translates to:
  /// **'Associados'**
  String get commitAssignedLabel;

  /// Done
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get doneAction;

  /// DeleteReceipt
  ///
  /// In pt, this message translates to:
  /// **'Excluir cupom'**
  String get deleteReceiptAction;

  /// DeleteReceiptConfirmTitle
  ///
  /// In pt, this message translates to:
  /// **'Excluir cupom?'**
  String get deleteReceiptConfirmTitle;

  /// DeleteReceiptConfirm
  ///
  /// In pt, this message translates to:
  /// **'Os preços deste cupom serão removidos. Esta ação não pode ser desfeita.'**
  String get deleteReceiptConfirmMessage;

  /// DeleteReceiptSuccess
  ///
  /// In pt, this message translates to:
  /// **'Cupom excluído'**
  String get deleteReceiptSuccessMessage;

  /// Cancel
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancelAction;

  /// Delete
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get deleteAction;

  /// StartOver
  ///
  /// In pt, this message translates to:
  /// **'Ler outro cupom'**
  String get startOverAction;

  /// ReceiptNotFound
  ///
  /// In pt, this message translates to:
  /// **'Cupom não encontrado.'**
  String get receiptNotFoundError;

  /// UnsupportedUf
  ///
  /// In pt, this message translates to:
  /// **'Estado (UF) não suportado.'**
  String get unsupportedUfError;

  /// Upstream
  ///
  /// In pt, this message translates to:
  /// **'O portal da SEFAZ não respondeu. Tente novamente.'**
  String get upstreamErrorMessage;

  /// PreviewExpired
  ///
  /// In pt, this message translates to:
  /// **'Esta prévia expirou. Leia o cupom novamente.'**
  String get previewExpiredError;

  /// PreviewNotFound
  ///
  /// In pt, this message translates to:
  /// **'Prévia não encontrada. Leia o cupom novamente.'**
  String get previewNotFoundError;

  /// AlreadyCommitted
  ///
  /// In pt, this message translates to:
  /// **'Este cupom já foi registrado.'**
  String get alreadyCommittedError;

  /// InvalidResolution
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível aplicar as escolhas dos itens.'**
  String get invalidResolutionError;

  /// Admin users tab
  ///
  /// In pt, this message translates to:
  /// **'Usuários'**
  String get adminUsers;

  /// Admin review queue tab
  ///
  /// In pt, this message translates to:
  /// **'Fila de revisão'**
  String get adminReviewQueue;

  /// Admin role label
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get adminRole;

  /// Promote user to admin
  ///
  /// In pt, this message translates to:
  /// **'Tornar administrador'**
  String get adminPromoteToAdmin;

  /// Demote admin to user
  ///
  /// In pt, this message translates to:
  /// **'Rebaixar para usuário'**
  String get adminDemoteToUser;

  /// Change role action
  ///
  /// In pt, this message translates to:
  /// **'Alterar perfil'**
  String get adminChangeRole;

  /// Confirm role change dialog
  ///
  /// In pt, this message translates to:
  /// **'Confirmar alteração de perfil?'**
  String get adminConfirmRoleChange;

  /// Cannot change own role message
  ///
  /// In pt, this message translates to:
  /// **'Não é possível alterar o próprio perfil'**
  String get adminCannotChangeOwnRole;

  /// Batch assign action
  ///
  /// In pt, this message translates to:
  /// **'Atribuir em lote'**
  String get adminBatchAssign;

  /// Select all
  ///
  /// In pt, this message translates to:
  /// **'Selecionar todos'**
  String get adminSelectAll;

  /// Clear selection
  ///
  /// In pt, this message translates to:
  /// **'Limpar seleção'**
  String get adminClearSelection;

  /// Assign to existing product
  ///
  /// In pt, this message translates to:
  /// **'Atribuir a produto existente'**
  String get adminAssignToExisting;

  /// Create new product
  ///
  /// In pt, this message translates to:
  /// **'Criar novo produto'**
  String get adminCreateProduct;

  /// No items selected
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item selecionado'**
  String get adminNoSelection;

  /// Assigned count
  ///
  /// In pt, this message translates to:
  /// **'Atribuídos'**
  String get adminAssigned;

  /// Created count
  ///
  /// In pt, this message translates to:
  /// **'Criados'**
  String get adminCreated;

  /// Refresh
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get adminRefresh;

  /// User ID
  ///
  /// In pt, this message translates to:
  /// **'ID'**
  String get adminUserId;

  /// User name
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get adminUserName;

  /// User email
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get adminUserEmail;

  /// AdminCreatedAt
  ///
  /// In pt, this message translates to:
  /// **'Criado em'**
  String get adminCreatedAt;
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
