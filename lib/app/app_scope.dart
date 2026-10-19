import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../core/config/app_config_controller.dart';
import '../features/auth/auth_session.dart';
import 'app_dependencies.dart';

/// Convenience accessors for the app's dependency graph.
extension AppScope on BuildContext {
  /// The composition root (non-reactive).
  AppDependencies get appDependencies => read<AppDependencies>();

  /// Reactive accessor for configuration changes.
  AppConfigController get configController => watch<AppConfigController>();

  /// The currently active configuration (rebuilds when it changes).
  AppConfig get appConfig => configController.config;

  /// Reactive accessor for authentication state.
  AuthSession get authSession => watch<AuthSession>();
}
