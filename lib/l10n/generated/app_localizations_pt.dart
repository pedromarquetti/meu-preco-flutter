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
  String get mergeFrom => 'Origem';

  @override
  String get mergeTo => 'Destino';

  @override
  String get mergeProducts => 'Mesclar Produtos';

  @override
  String get merge => 'Mesclar';

  @override
  String get goBack => 'Voltar';

  @override
  String get goNext => 'Avançar';

  @override
  String get appDescription =>
      'Compare preços de produtos entre supermercados.';

  @override
  String get serverConfigTitle => 'Configurar servidor';

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
  String get loadMoreAction => 'Carregar mais';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginDescription => 'Entre com seu e-mail ou nome de usuário.';

  @override
  String get loginIdentifierLabel => 'E-mail ou nome';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get nameLabel => 'Nome';

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
  String get invalidIdentifierError => 'Informe um e-mail ou nome';

  @override
  String get invalidNameError => 'Informe um nome de até 100 caracteres';

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
  String get forbiddenError => 'Você não tem permissão para esta ação';

  @override
  String get notFoundError => 'O recurso solicitado não foi encontrado';

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
  String get homeTitle => 'Início';

  @override
  String get homeGreeting => 'Bem-vindo(a) de volta';

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
  String get productSearchHint => 'Nome, GTIN ou marca';

  @override
  String get productSearchPrompt => 'Digite para buscar produtos';

  @override
  String get productSearchNoResults => 'Nenhum produto encontrado';

  @override
  String get productSearchLoading => 'Buscando produtos';

  @override
  String get productBrandLabel => 'Marca';

  @override
  String get productGtinLabel => 'GTIN';

  @override
  String get productUnitLabel => 'Unidade';

  @override
  String get productNotFound => 'Produto não encontrado.';

  @override
  String get productHistoryTitle => 'Histórico de preços';

  @override
  String get productHistoryEmpty => 'Sem histórico de preços';

  @override
  String get productHistoryFromLabel => 'De';

  @override
  String get productHistoryToLabel => 'Até';

  @override
  String get productHistoryClearRangeAction => 'Limpar período';

  @override
  String get productSupermarketLabel => 'Mercado';

  @override
  String get productLoggedAtLabel => 'Data';

  @override
  String get productQtyLabel => 'Quantidade';

  @override
  String get productTotalPriceLabel => 'Total pago';

  @override
  String get productAggregateTitle => 'Resumo por unidade';

  @override
  String get productAggregateCountLabel => 'Registros';

  @override
  String get productUpdated => 'Produto atualizado';

  @override
  String get productAggregateMinLabel => 'Mínimo';

  @override
  String get productAggregateAvgLabel => 'Média';

  @override
  String get productAggregateMaxLabel => 'Máximo';

  @override
  String get productAggregateLastLabel => 'Último';

  @override
  String get productPriceGraphLabel => 'Evolução do preço';

  @override
  String get priceChartTooShort =>
      'Histórico curto demais para montar o gráfico.';

  @override
  String get priceChartMinLabel => 'Mínimo';

  @override
  String get priceChartMaxLabel => 'Máximo';

  @override
  String priceChartSemantics(String min, String max, String unit) {
    return 'Gráfico de preços de $min a $max por $unit.';
  }

  @override
  String get supermarketsTitle => 'Supermercados';

  @override
  String get adminTitle => 'Administração';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsServerSection => 'Servidor';

  @override
  String get themeSystemLabel => 'Sistema';

  @override
  String get themeLightLabel => 'Claro';

  @override
  String get themeDarkLabel => 'Escuro';

  @override
  String get confirmAction => 'Confirmar';

  @override
  String get connectivitySection => 'Conectividade';

  @override
  String get checkConnectivityAction => 'Verificar conexão';

  @override
  String get healthStatusLabel => 'Servidor';

  @override
  String get readinessStatusLabel => 'Prontidão';

  @override
  String get readinessHealthyLabel => 'Pronto para uso';

  @override
  String get readinessUnavailableLabel => 'Indisponível';

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
  String get scanQrAction => 'Escanear QR';

  @override
  String get scanWithCameraAction => 'Escanear com a câmera';

  @override
  String get scanQrHelp => 'Aponte a câmera para o QR Code do cupom.';

  @override
  String get scanQrUnavailable =>
      'A câmera não está disponível neste dispositivo. Cole o conteúdo do QR Code.';

  @override
  String get scanReceiptTitle => 'Escanear NFC-e';

  @override
  String get scannerPreparingLabel => 'Preparando câmera';

  @override
  String get scannerInstruction =>
      'Alinhe o QR Code da NFC-e dentro do quadrado.';

  @override
  String get cameraUnavailableTitle => 'Câmera indisponível';

  @override
  String get cameraUnsupportedMessage =>
      'A leitura com câmera não é suportada neste dispositivo ou plataforma.';

  @override
  String get cameraNoCameraMessage =>
      'Nenhuma câmera foi encontrada neste dispositivo.';

  @override
  String get cameraErrorMessage =>
      'Não foi possível abrir a câmera. Tente novamente.';

  @override
  String get cameraPermissionTitle => 'Permissão da câmera';

  @override
  String get cameraPermissionDeniedMessage =>
      'É necessário permitir o acesso à câmera para escanear o QR Code.';

  @override
  String get cameraPermissionForeverMessage =>
      'O acesso à câmera foi negado permanentemente. Abra as configurações do app para habilitá-lo.';

  @override
  String get cameraPermissionRetryAction => 'Solicitar permissão';

  @override
  String get openSettingsAction => 'Abrir configurações';

  @override
  String get accessKeyLabel => 'Chave de acesso';

  @override
  String get accessKeyHint => '44 dígitos';

  @override
  String get accessKeyHelp => 'Fica no rodapé do cupom fiscal.';

  @override
  String get qrPayloadLabel => 'Conteúdo do QR Code';

  @override
  String get qrPayloadHint => 'Cole aqui o link do QR Code do cupom';

  @override
  String get invalidAccessKeyError =>
      'Informe os 44 dígitos da chave de acesso';

  @override
  String get invalidQrPayloadError => 'Informe um QR Code válido';

  @override
  String get extractAccessKeyFromQrAction =>
      'Extrair chave de acesso do QR Code';

  @override
  String get extractAccessKeyFromQrNoMatchError =>
      'Não foi possível extrair uma chave de 44 dígitos do conteúdo do QR Code.';

  @override
  String get draftingReceiptLabel => 'Processando o cupom...';

  @override
  String get submittingReceiptLabel => 'Enviando o cupom...';

  @override
  String get captchaTitle => 'Verificação de segurança';

  @override
  String get captchaDescription =>
      'Digite os caracteres da imagem para continuar.';

  @override
  String get captchaSolutionLabel => 'Resposta';

  @override
  String get captchaSolveAction => 'Confirmar';

  @override
  String get captchaReloadAction => 'Recarregar imagem';

  @override
  String get captchaImageUnavailable => 'Não foi possível carregar a imagem.';

  @override
  String get captchaImageLabel => 'Imagem de verificação de segurança';

  @override
  String get captchaWrongSolutionError =>
      'Resposta incorreta. Tente novamente.';

  @override
  String captchaAttemptsLeft(int count) {
    return 'Tentativas restantes: $count';
  }

  @override
  String get captchaExpiredError =>
      'Este desafio expirou. Leia o cupom novamente.';

  @override
  String get captchaLockedError =>
      'Muitas respostas incorretas. Leia o cupom novamente.';

  @override
  String get captchaUsedError => 'Este desafio já foi utilizado.';

  @override
  String get captchaNotFoundError => 'Desafio não encontrado.';

  @override
  String get previewTitle => 'Confira os dados do cupom';

  @override
  String get previewAccessKeyLabel => 'Chave de acesso';

  @override
  String previewExpiresAtLabel(String time) {
    return 'Expira em $time';
  }

  @override
  String get previewExpiredLabel => 'Prévia expirada';

  @override
  String get previewItemsTitle => 'Itens';

  @override
  String get previewTotalsTitle => 'Resumo';

  @override
  String get previewItemsCountLabel => 'Itens lidos';

  @override
  String get previewAutoSaveLabel => 'Salvos automaticamente';

  @override
  String get previewNeedsReviewLabel => 'Precisam de revisão';

  @override
  String get previewParseErrorsLabel => 'Com erro de leitura';

  @override
  String get previewEstimatedTotalLabel => 'Total estimado';

  @override
  String get previewPriceLabel => 'Preço';

  @override
  String get itemStatusGtinKnown => 'Produto reconhecido';

  @override
  String get itemStatusGtinNew => 'Produto novo';

  @override
  String get itemStatusCommodity => 'Produto a granel';

  @override
  String get itemStatusUncertain => 'Código incerto';

  @override
  String get itemStatusParseError => 'Erro de leitura';

  @override
  String get itemUncertainHelp => 'Escolha como tratar este item.';

  @override
  String get itemApiMessageTitle => 'Mensagem da API';

  @override
  String get closeAction => 'Fechar';

  @override
  String get resolutionNeedsReviewAction => 'Revisar depois';

  @override
  String get resolutionSkipAction => 'Ignorar';

  @override
  String get resolutionAssignAction => 'Vincular produto';

  @override
  String get clearProductAction => 'Remover vínculo';

  @override
  String get productPickerTitle => 'Selecionar produto';

  @override
  String get submitDryRunAction => 'Simular envio';

  @override
  String get submitConfirmAction => 'Enviar cupom';

  @override
  String get commitResultTitle => 'Cupom enviado';

  @override
  String get commitWrittenLabel => 'Itens registrados';

  @override
  String get commitAutoSavedLabel => 'Salvos automaticamente';

  @override
  String get commitSkippedLabel => 'Itens ignorados';

  @override
  String get commitNeedsReviewLabel => 'Para revisão';

  @override
  String get commitAssignedLabel => 'Associados';

  @override
  String get doneAction => 'Concluir';

  @override
  String get deleteReceiptAction => 'Excluir cupom';

  @override
  String get deleteReceiptConfirmTitle => 'Excluir cupom?';

  @override
  String get deleteReceiptConfirmMessage =>
      'Os preços deste cupom serão removidos. Esta ação não pode ser desfeita.';

  @override
  String get deleteReceiptSuccessMessage => 'Cupom excluído';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get deleteAction => 'Excluir';

  @override
  String get startOverAction => 'Ler outro cupom';

  @override
  String get receiptNotFoundError => 'Cupom não encontrado.';

  @override
  String get unsupportedUfError => 'Estado (UF) não suportado.';

  @override
  String get upstreamErrorMessage =>
      'O portal da SEFAZ não respondeu. Tente novamente.';

  @override
  String get previewExpiredError =>
      'Esta prévia expirou. Leia o cupom novamente.';

  @override
  String get previewNotFoundError =>
      'Prévia não encontrada. Leia o cupom novamente.';

  @override
  String get alreadyCommittedError => 'Este cupom já foi registrado.';

  @override
  String get invalidResolutionError =>
      'Não foi possível aplicar as escolhas dos itens.';

  @override
  String get adminUsers => 'Usuários';

  @override
  String get adminReviewQueue => 'Fila de revisão';

  @override
  String get adminRole => 'Perfil';

  @override
  String get adminPromoteToAdmin => 'Tornar administrador';

  @override
  String get adminDemoteToUser => 'Rebaixar para usuário';

  @override
  String get adminConfirmRoleChange => 'Confirmar alteração de perfil?';

  @override
  String get adminCannotChangeOwnRole =>
      'Não é possível alterar o próprio perfil';

  @override
  String get adminBatchAssign => 'Atribuir em lote';

  @override
  String get batchAssignSuggestedName => 'Nome Sugerido';

  @override
  String get adminSelectAll => 'Selecionar todos';

  @override
  String get adminClearSelection => 'Limpar seleção';

  @override
  String get adminNoSelection => 'Nenhum item selecionado';

  @override
  String get adminAssigned => 'Atribuídos';

  @override
  String get adminCreated => 'Criados';

  @override
  String get themeSettingsSection => 'Tema';
}
