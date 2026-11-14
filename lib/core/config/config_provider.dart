import 'app_config.dart';

/// Provides the currently active [AppConfig], or `null` until the user selects
/// an API server.
///
/// Services depend on a [ConfigProvider] rather than a fixed config so runtime
/// host changes (from Settings or the server configuration screen) take effect
/// without recreating every object.
typedef ConfigProvider = AppConfig? Function();
