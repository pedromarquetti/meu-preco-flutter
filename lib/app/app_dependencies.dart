import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/config/app_config_controller.dart';
import '../core/config/config_provider.dart';
import '../core/http/api_client.dart';
import '../core/http/server_health_service.dart';
import '../core/storage/key_value_store.dart';
import '../core/storage/shared_preferences_key_value_store.dart';

/// Composition root for the app.
///
/// Everything the app needs — storage, configuration, HTTP, and health checks
/// — is created once here and exposed through provider scopes, so tests can
/// substitute fakes for any of them.
class AppDependencies {
  factory AppDependencies({
    required KeyValueStore store,
    required AppConfigController configController,
    ServerHealthChecker? healthChecker,
    http.Client? httpClient,
  }) {
    final apiClient = ApiClient(
      configProvider: () => configController.config,
      httpClient: httpClient,
    );
    return AppDependencies._(
      store: store,
      configController: configController,
      apiClient: apiClient,
      healthChecker:
          healthChecker ?? HttpServerHealthChecker(apiClient: apiClient),
    );
  }

  AppDependencies._({
    required this.store,
    required this.configController,
    required this.apiClient,
    required this.healthChecker,
  });

  final KeyValueStore store;
  final AppConfigController configController;
  final ServerHealthChecker healthChecker;
  final ApiClient apiClient;

  /// The currently active configuration.
  AppConfig get config => configController.config;

  /// Live provider of the active configuration.
  ConfigProvider get configProvider =>
      () => configController.config;

  /// Builds production dependencies and loads any persisted configuration.
  static Future<AppDependencies> bootstrap() async {
    final store = await SharedPreferencesKeyValueStore.create();
    final configController = AppConfigController(store: store);
    await configController.load();
    return AppDependencies(store: store, configController: configController);
  }

  void dispose() {
    apiClient.dispose();
    configController.dispose();
  }
}
