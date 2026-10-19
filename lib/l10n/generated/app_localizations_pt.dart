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
  String get loginDescription => 'Entre com sua conta Meu Preço.';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get confirmPasswordLabel => 'Confirmar senha';

  @override
  String get signInAction => 'Fazer login';

  @override
  String get registerTitle => 'Criar conta';

  @override
  String get registerDescription =>
      'Crie uma conta para começar a usar o Meu Preço.';

  @override
  String get createAccountAction => 'Criar conta';

  @override
  String get needAccountAction => 'Criar uma conta';

  @override
  String get alreadyHaveAccountAction => 'Já tenho uma conta';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get invalidEmailError => 'Informe um e-mail válido';

  @override
  String get weakPasswordError => 'A senha deve ter pelo menos 8 caracteres';

  @override
  String get invalidCredentialsError => 'E-mail ou senha inválidos';

  @override
  String get userExistsError => 'Este e-mail já está cadastrado';

  @override
  String get rateLimitedError =>
      'Muitas tentativas. Tente novamente em instantes';

  @override
  String get networkErrorMessage => 'Não foi possível conectar ao servidor';

  @override
  String get sessionExpiredMessage => 'Sua sessão expirou. Entre novamente.';

  @override
  String get accountSection => 'Conta';

  @override
  String get currentUserLabel => 'Usuário';

  @override
  String get roleLabel => 'Perfil';

  @override
  String get adminRoleLabel => 'Administrador';

  @override
  String get userRoleLabel => 'Usuário';

  @override
  String get notAuthenticatedLabel => 'Não autenticado';

  @override
  String get signOutSuccessMessage => 'Sessão encerrada';

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
      'Esta funcionalidade ainda não está disponível.';

  @override
  String get currentHostLabel => 'Servidor atual';

  @override
  String get apiPrefixLabel => 'Prefixo da API';

  @override
  String get notConfiguredLabel => 'Não configurado';
}
