import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/config/app_config_controller.dart';
import 'package:meu_preco_frontend/core/http/server_health_service.dart';

import 'fakes.dart';

/// Builds app dependencies backed by fakes so widget tests never touch real
/// storage or networking.
AppDependencies buildTestDependencies({ServerHealthChecker? healthChecker}) {
  final store = InMemoryKeyValueStore();
  final configController = AppConfigController(store: store);
  return AppDependencies(
    store: store,
    configController: configController,
    healthChecker: healthChecker ?? FakeServerHealthChecker(),
  );
}
