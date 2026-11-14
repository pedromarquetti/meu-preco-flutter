import 'package:flutter/foundation.dart';

import '../storage/key_value_store.dart';
import 'app_config.dart';
import 'build_config.dart';

/// Callback invoked when the active API origin is about to change.
typedef OriginChangedCallback = Future<void> Function();

/// Holds the active [AppConfig] and persists the user-selected API origin.
///
/// No API origin is built into the app: [config] is `null` until the user
/// chooses a server on the server configuration screen. The choice is stored
/// and restored on later launches. Changes are applied only through explicit
/// [saveOrigin] or [clearOrigin] calls, never implicitly as a side effect.
class AppConfigController extends ChangeNotifier {
  AppConfigController({
    required KeyValueStore store,
    AppConfig? initialConfig,
    OriginChangedCallback? onOriginChanged,
  }) : _store = store, // ignore: prefer_initializing_formals
       _config = initialConfig {
    _onOriginChanged = onOriginChanged;
  }

  static const String apiOriginKey = 'meu_preco.app_config.api_origin';

  final KeyValueStore _store;
  OriginChangedCallback? _onOriginChanged;
  AppConfig? _config;

  /// Current, active configuration, or `null` when no server is configured.
  AppConfig? get config => _config;

  /// Whether the user has selected and saved an API origin.
  bool get isConfigured => _config != null;

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

  /// Loads a persisted origin override, if any.
  Future<void> load() async {
    final stored = await _store.readString(apiOriginKey);
    if (stored == null || stored.isEmpty) return;
    final parsed = _parse(stored);
    if (parsed == null) return;
    _config = parsed;
    notifyListeners();
  }

  /// Persists [origin] as the active API origin and notifies listeners.
  ///
  /// When the normalized origin actually changes and a server was already
  /// configured, the bound [OriginChangedCallback] runs first so the previous
  /// server's session is cleared before any request can be sent to the new
  /// origin.
  Future<void> saveOrigin(String origin) async {
    final parsed = _parse(origin);
    if (parsed == null) {
      throw const FormatException('Invalid API origin');
    }

    final current = _config;
    if (current != null && parsed.apiOrigin != current.apiOrigin) {
      await _onOriginChanged?.call();
    }

    _config = parsed;
    await _store.writeString(apiOriginKey, parsed.apiOrigin.toString());
    notifyListeners();
  }

  /// Forgets the selected server and returns the app to server selection.
  ///
  /// Clearing an origin signs out the current session through the bound
  /// [OriginChangedCallback] so no credential survives without a target.
  Future<void> clearOrigin() async {
    if (_config != null) {
      await _onOriginChanged?.call();
    }
    _config = null;
    await _store.remove(apiOriginKey);
    notifyListeners();
  }

  AppConfig? _parse(String origin) {
    return AppConfig.tryFromOrigin(
      origin,
      apiPrefix: _config?.apiPrefix ?? AppConfig.defaultApiPrefix,
      requestTimeout: _config?.requestTimeout ?? BuildConfig.requestTimeout,
    );
  }
}
