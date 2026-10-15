import 'package:flutter/foundation.dart';

import '../storage/key_value_store.dart';
import 'app_config.dart';
import 'build_config.dart';

/// Holds the active [AppConfig] and persists user overrides.
///
/// The controller is the single place the rest of the app reads API
/// configuration from. Changes are applied only through explicit [saveOrigin]
/// or [resetToDefault] calls, never implicitly as a side effect.
class AppConfigController extends ChangeNotifier {
  AppConfigController({required KeyValueStore store, AppConfig? initialConfig})
    : _store = store, // ignore: prefer_initializing_formals
      _config = initialConfig ?? _defaultConfig() {
    _configuredByUser =
        _config.apiOrigin.toString() != _defaultConfig().apiOrigin.toString();
  }

  static const String apiOriginKey = 'meu_preco.app_config.api_origin';

  final KeyValueStore _store;
  AppConfig _config;
  bool _configuredByUser = false;

  /// Current, active configuration.
  AppConfig get config => _config;

  /// Whether the user explicitly selected this origin (as opposed to the
  /// build-mode default).
  bool get isConfiguredByUser => _configuredByUser;

  static AppConfig _defaultConfig() {
    return AppConfig.tryFromOrigin(
          BuildConfig.apiOrigin,
          requestTimeout: BuildConfig.requestTimeout,
        ) ??
        AppConfig.defaults();
  }

  /// Loads a persisted origin override, if any.
  Future<void> load() async {
    final stored = await _store.readString(apiOriginKey);
    if (stored == null || stored.isEmpty) return;
    final parsed = AppConfig.tryFromOrigin(
      stored,
      apiPrefix: _config.apiPrefix,
      requestTimeout: _config.requestTimeout,
    );
    if (parsed == null) return;
    _config = parsed;
    _configuredByUser = true;
    notifyListeners();
  }

  /// Persists [origin] as the active API origin and notifies listeners.
  Future<void> saveOrigin(String origin) async {
    final parsed = AppConfig.tryFromOrigin(
      origin,
      apiPrefix: _config.apiPrefix,
      requestTimeout: _config.requestTimeout,
    );
    if (parsed == null) {
      throw const FormatException('Invalid API origin');
    }
    _config = parsed;
    _configuredByUser = true;
    await _store.writeString(apiOriginKey, parsed.apiOrigin.toString());
    notifyListeners();
  }

  /// Clears the user override and returns to build-mode defaults.
  Future<void> resetToDefault() async {
    _config = _defaultConfig();
    _configuredByUser = false;
    await _store.remove(apiOriginKey);
    notifyListeners();
  }
}
