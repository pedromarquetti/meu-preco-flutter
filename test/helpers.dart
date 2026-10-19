import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/config/app_config_controller.dart';
import 'package:meu_preco_frontend/core/http/server_health_service.dart';
import 'package:meu_preco_frontend/core/storage/credential_store.dart';
import 'package:meu_preco_frontend/features/auth/data/auth_repository.dart';

import 'fakes.dart';

/// Builds app dependencies backed by fakes so widget tests never touch real
/// storage or networking.
AppDependencies buildTestDependencies({
  ServerHealthChecker? healthChecker,
  AuthRepository? authRepository,
  CredentialStore? credentialStore,
}) {
  final store = InMemoryKeyValueStore();
  final configController = AppConfigController(store: store);
  return AppDependencies(
    store: store,
    configController: configController,
    credentialStore: credentialStore ?? InMemoryCredentialStore(),
    authRepository: authRepository ?? FakeAuthRepository(),
    healthChecker: healthChecker ?? FakeServerHealthChecker(),
  );
}
