import 'dart:async';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/config/app_config_controller.dart';
import '../core/config/config_provider.dart';
import '../core/http/api_client.dart';
import '../core/http/authenticated_client.dart';
import '../core/http/server_health_service.dart';
import '../core/storage/credential_store.dart';
import '../core/storage/key_value_store.dart';
import '../core/storage/secure_credential_store.dart';
import '../core/storage/shared_preferences_key_value_store.dart';
import '../features/auth/auth_session.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/nfce/code_scanner.dart';
import '../features/nfce/data/nfce_repository.dart';

/// Composition root for the app.
///
/// Everything the app needs — storage, configuration, HTTP, authentication,
/// and health checks — is created once here and exposed through provider
/// scopes, so tests can substitute fakes for any of them.
class AppDependencies {
  factory AppDependencies({
    required KeyValueStore store,
    required AppConfigController configController,
    required CredentialStore credentialStore,
    AuthRepository? authRepository,
    ServerHealthChecker? healthChecker,
    NfceRepository? nfceRepository,
    CodeScanner? codeScanner,
    http.Client? httpClient,
  }) {
    final rawClient = httpClient ?? http.Client();
    AppConfig currentConfig() => configController.config;

    // Unauthenticated transport for auth and operational endpoints.
    final transportApi = ApiClient(
      configProvider: currentConfig,
      httpClient: rawClient,
    );
    final authSession = AuthSession(
      repository: authRepository ?? ApiAuthRepository(client: transportApi),
      credentialStore: credentialStore,
    );

    // Authenticated transport for feature repositories: signs requests and
    // transparently recovers from an expired access token.
    final apiClient = ApiClient(
      configProvider: currentConfig,
      httpClient: AuthenticatedClient(inner: rawClient, tokens: authSession),
    );

    return AppDependencies._(
      rawClient: rawClient,
      store: store,
      configController: configController,
      credentialStore: credentialStore,
      authSession: authSession,
      apiClient: apiClient,
      nfceRepository: nfceRepository ?? ApiNfceRepository(client: apiClient),
      codeScanner: codeScanner ?? const UnavailableCodeScanner(),
      healthChecker:
          healthChecker ?? HttpServerHealthChecker(apiClient: transportApi),
    );
  }

  AppDependencies._({
    required http.Client rawClient,
    required this.store,
    required this.configController,
    required this.credentialStore,
    required this.authSession,
    required this.apiClient,
    required this.nfceRepository,
    required this.codeScanner,
    required this.healthChecker,
  }) : _rawClient = rawClient; // ignore: prefer_initializing_formals

  final http.Client _rawClient;
  final KeyValueStore store;
  final AppConfigController configController;
  final CredentialStore credentialStore;

  /// Authentication session and current user.
  final AuthSession authSession;

  /// Authenticated client used by feature repositories.
  final ApiClient apiClient;

  /// NFC-e ingestion operations.
  final NfceRepository nfceRepository;

  /// Platform seam for camera QR scanning.
  final CodeScanner codeScanner;

  final ServerHealthChecker healthChecker;

  /// The currently active configuration.
  AppConfig get config => configController.config;

  /// Live provider of the active configuration.
  ConfigProvider get configProvider =>
      () => configController.config;

  /// Builds production dependencies, loads persisted configuration, and
  /// restores any stored session.
  static Future<AppDependencies> bootstrap() async {
    final store = await SharedPreferencesKeyValueStore.create();
    final configController = AppConfigController(store: store);
    await configController.load();
    final dependencies = AppDependencies(
      store: store,
      configController: configController,
      credentialStore: SecureCredentialStore.create(),
    );
    await dependencies.authSession.restore();
    // Confirm the restored session in the background; the optimistic state is
    // enough to render and route the first frame.
    unawaited(dependencies.authSession.validate());
    return dependencies;
  }

  void dispose() {
    _rawClient.close();
    authSession.dispose();
    configController.dispose();
  }
}
