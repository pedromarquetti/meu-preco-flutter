import 'package:flutter/foundation.dart';

import '../storage/key_value_store.dart';
import 'app_config.dart';
import 'build_config.dart';

/// Callback invoked when the active API origin is about to change.
typedef OriginChangedCallback = Future<void> Function();

/// Holds the active [AppConfig] and persists user overrides.
///
/// The controller is the single place the rest of the app reads API
/// configuration from. Changes are applied only through explicit [saveOrigin]
/// or [resetToDefault] calls, never implicitly as a side effect.
class AppConfigController extends ChangeNotifier {
  AppConfigController({
    required KeyValueStore store,
    AppConfig? initialConfig,
    OriginChangedCallback? onOriginChanged,
  }) : _store = store, // ignore: prefer_initializing_formals
       _config = initialConfig ?? _defaultConfig() {
    _onOriginChanged = onOriginChanged;
    _configuredByUser =
        _config.apiOrigin.toString() != _defaultConfig().apiOrigin.toString();
  }

  static const String apiOriginKey = 'meu_preco.app_config.api_origin';

  final KeyValueStore _store;
  OriginChangedCallback? _onOriginChanged;
  AppConfig _config;

  bool _configuredByUser = false;

  /// Current, active configuration.
  AppConfig get config => _config;

  /// Whether the user explicitly selected this origin (as opposed to the
  /// build-mode default).
  bool get isConfiguredByUser => _configuredByUser;

  /// Binds the session boundary that runs when the active origin changes.
  ///
  /// The composition root binds this to the authentication session, so a
  /// session issued by one API can never be reused against another. The
  /// callback runs before the new origin is persisted: if clearing the old
  /// session fails, the app stays on the old origin instead of writing a new
  /// one next to stale credentials.
  void bindOriginChanged(OriginChangedCallback callback) {
    _onOriginChanged = callback;
  }

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
  ///
  /// When the normalized origin actually changes, the bound
  /// [OriginChangedCallback] runs first so the previous server's session is
  /// cleared before any request can be sent to the new origin.
  Future<void> saveOrigin(String origin) async {
    final parsed = AppConfig.tryFromOrigin(
      origin,
      apiPrefix: _config.apiPrefix,
      requestTimeout: _config.requestTimeout,
    );
    if (parsed == null) {
      throw const FormatException('Invalid API origin');
    }

    if (parsed.apiOrigin != _config.apiOrigin) {
      await _onOriginChanged?.call();
    }

    _config = parsed;
    _configuredByUser = true;
    await _store.writeString(apiOriginKey, parsed.apiOrigin.toString());
    notifyListeners();
  }

  /// Clears the user override and returns to build-mode defaults.
  ///
  /// Resetting to the same origin keeps the current session; changing the
  /// origin clears it through the bound [OriginChangedCallback].
  Future<void> resetToDefault() async {
    final next = _defaultConfig();
    if (next.apiOrigin != _config.apiOrigin) {
      await _onOriginChanged?.call();
    }
    _config = next;
    _configuredByUser = false;
    await _store.remove(apiOriginKey);
    notifyListeners();
  }
}
