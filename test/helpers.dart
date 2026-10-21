import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/config/app_config_controller.dart';
import 'package:meu_preco_frontend/core/http/server_health_service.dart';
import 'package:meu_preco_frontend/core/storage/credential_store.dart';
import 'package:meu_preco_frontend/core/storage/key_value_store.dart';
import 'package:meu_preco_frontend/features/auth/data/auth_repository.dart';
import 'package:meu_preco_frontend/features/nfce/code_scanner.dart';
import 'package:meu_preco_frontend/features/nfce/data/nfce_repository.dart';
import 'package:meu_preco_frontend/features/products/data/product_repository.dart';
import 'package:meu_preco_frontend/core/theme/theme_controller.dart';

import 'fakes.dart';

/// Builds app dependencies backed by fakes so widget tests never touch real
/// storage or networking.
AppDependencies buildTestDependencies({
  ServerHealthChecker? healthChecker,
  AuthRepository? authRepository,
  CredentialStore? credentialStore,
  KeyValueStore? store,
  NfceRepository? nfceRepository,
  ProductRepository? productsRepository,
  CodeScanner? codeScanner,
}) {
  final keyValueStore = store ?? InMemoryKeyValueStore();
  final configController = AppConfigController(store: keyValueStore);
  // ignore: discarded_futures
  configController.load();
  final themeController = ThemeController(store: keyValueStore);
  // ignore: discarded_futures
  themeController.load();
  final deps = AppDependencies(
    store: keyValueStore,
    configController: configController,
    themeController: themeController,
    credentialStore: credentialStore ?? InMemoryCredentialStore(),
    authRepository: authRepository ?? FakeAuthRepository(),
    healthChecker: healthChecker ?? FakeServerHealthChecker(),
    nfceRepository: nfceRepository ?? FakeNfceRepository(),
    productsRepository: productsRepository ?? FakeProductRepository(),
    codeScanner: codeScanner ?? const UnavailableCodeScanner(),
  );
  // Ensure tests start from a predictable boot state
  deps.serverGate = null;
  return deps;
}
