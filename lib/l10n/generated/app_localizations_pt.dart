// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Meu Preço';

  @override
  String get appDescription =>
      'Compare preços de produtos entre supermercados.';

  @override
  String get serverConfigTitle => 'Configurar servidor';

  @override
  String get serverConfigDescription =>
      'Informe o endereço do servidor Meu Preço que deseja utilizar.';

  @override
  String get serverAddressLabel => 'Endereço do servidor';

  @override
  String get serverAddressHint => 'https://meu-preco.exemplo.com';

  @override
  String get serverAddressHelp =>
      'Pode ser informado com ou sem o prefixo /api/v1.';

  @override
  String get testConnection => 'Testar conexão';

  @override
  String get saveAndContinue => 'Salvar e continuar';

  @override
  String get serverConnectionSuccess => 'Servidor disponível';

  @override
  String get serverConnectionFailure => 'Não foi possível conectar ao servidor';

  @override
  String get serverConnectionTimeout =>
      'O servidor demorou demais para responder';

  @override
  String get invalidServerUrl =>
      'Informe uma URL válida, começando com http:// ou https://';

  @override
  String get continueAction => 'Continuar';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginDescription =>
      'Ainda faremos o login nesta etapa. Esta tela é um marcador da Fase 1.';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get signInAction => 'Fazer login';

  @override
  String get homeTitle => 'Início';

  @override
  String get scanReceiptAction => 'Escanear NFC-e';

  @override
  String get searchProductAction => 'Buscar produto';

  @override
  String get receiptSubmissionTitle => 'Nova NFC-e';

  @override
  String get productSearchTitle => 'Produtos';

  @override
  String get productDetailTitle => 'Produto';

  @override
  String get supermarketsTitle => 'Supermercados';

  @override
  String get adminTitle => 'Administração';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsServerSection => 'Servidor';

  @override
  String get settingsResetToDefault => 'Restaurar padrão';

  @override
  String get logoutAction => 'Sair';

  @override
  String get loadingLabel => 'Carregando...';

  @override
  String get emptyLabel => 'Nada por aqui ainda';

  @override
  String get errorLabel => 'Algo deu errado';

  @override
  String get retryAction => 'Tentar novamente';

  @override
  String get comingSoonLabel => 'Em breve';

  @override
  String get notImplementedLabel =>
      'Esta funcionalidade será implementada em uma fase futura.';

  @override
  String get currentHostLabel => 'Servidor atual';

  @override
  String get apiPrefixLabel => 'Prefixo da API';

  @override
  String get notConfiguredLabel => 'Não configurado';
}
