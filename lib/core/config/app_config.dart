import 'package:flutter/foundation.dart';

/// Immutable runtime configuration for talking to a Meu Preço API instance.
///
/// The API origin is user-selectable (see the server configuration screen and
/// Settings), while the `/api/v1` prefix and request timeout have sensible
/// build-mode defaults that can be overridden with `--dart-define`.
///
/// This is the single source of truth for API configuration. Repositories and
/// services receive an [AppConfig] instead of reading environment values
/// directly, which keeps them replaceable in tests.
@immutable
class AppConfig {
  const AppConfig({
    required this.apiOrigin,
    this.apiPrefix = defaultApiPrefix,
    this.requestTimeout = defaultRequestTimeout,
  });

  /// Path prefix used by every versioned API operation.
  static const String defaultApiPrefix = '/api/v1';

  /// Default request timeout applied to API calls.
  static const Duration defaultRequestTimeout = Duration(seconds: 20);

  /// Default origin used when nothing else is configured.
  static const String defaultApiOrigin = 'http://localhost:8080';

  /// Lowest valid TCP port (0 means "any port" and is not a usable origin).
  static const int minPort = 1;

  /// Highest valid TCP port.
  static const int maxPort = 65535;

  /// Root URI of the configured Meu Preço API (scheme + host + optional port).
  ///
  /// The [path] is preserved for deployments hosted under a sub-path but any
  /// trailing slash is removed.
  final Uri apiOrigin;

  /// Version prefix applied to API operations, e.g. `/api/v1`.
  final String apiPrefix;

  /// Timeout applied to API requests.
  final Duration requestTimeout;

  /// Creates a config from the build-mode defaults.
  factory AppConfig.defaults() {
    return AppConfig(
      apiOrigin: normalizeOrigin(defaultApiOrigin),
      apiPrefix: defaultApiPrefix,
      requestTimeout: defaultRequestTimeout,
    );
  }

  /// Parses and normalizes a user supplied origin.
  ///
  /// Returns `null` when [raw] is not a usable `http(s)` origin. A trailing
  /// `/api/v1` (or the configured [apiPrefix]) is stripped so it is never
  /// duplicated in resolved URLs.
  static AppConfig? tryFromOrigin(
    String raw, {
    String apiPrefix = defaultApiPrefix,
    Duration requestTimeout = defaultRequestTimeout,
  }) {
    final origin = tryParseOrigin(raw, apiPrefix: apiPrefix);
    if (origin == null) return null;
    return AppConfig(
      apiOrigin: origin,
      apiPrefix: apiPrefix,
      requestTimeout: requestTimeout,
    );
  }

  /// Parses and normalizes an origin, returning `null` when invalid.
  static Uri? tryParseOrigin(
    String raw, {
    String apiPrefix = defaultApiPrefix,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    Uri parsed;
    try {
      parsed = Uri.parse(trimmed);
    } on FormatException {
      return null;
    }

    if (parsed.scheme != 'http' && parsed.scheme != 'https') return null;
    if (parsed.host.isEmpty) return null;

    // `Uri.parse` accepts out-of-range ports without complaint, but the
    // transport (dart:io) later rejects them with an uncaught `Error` that
    // freezes the caller. Reject them here so an invalid port is reported as a
    // plain invalid origin, on every platform.
    if (parsed.hasPort && (parsed.port < minPort || parsed.port > maxPort)) {
      return null;
    }

    var path = parsed.path;
    while (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    if (path == '/') path = '';

    final prefix = _normalizePrefix(apiPrefix);
    if (prefix.isNotEmpty) {
      // Strip a trailing API prefix, repeatedly, so a pasted
      // `.../api/v1/api/v1` never survives to be doubled by resolution.
      while (path.endsWith(prefix)) {
        path = path.substring(0, path.length - prefix.length);
      }
    }

    while (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    if (path == '/') path = '';

    // Rebuild the URI so stray query/fragment/user-info never leak into the
    // stored origin.
    return Uri(
      scheme: parsed.scheme,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
      path: path,
    );
  }

  /// Normalizes [raw] into an origin URI, falling back to the default when
  /// parsing fails.
  static Uri normalizeOrigin(String raw) {
    return tryParseOrigin(raw) ?? Uri.parse(defaultApiOrigin);
  }

  /// Resolves [path] against the API origin root (used for `/healthz` and
  /// `/readyz`).
  Uri resolveRoot(String path) => _resolve(path);

  /// Resolves [path] against the versioned API prefix.
  Uri resolveApi(String path) => _resolve(apiPrefix, path);

  Uri _resolve(String path, [String? extra]) {
    var resolved = _join(_join(apiOrigin.path, path), extra);
    if (resolved.isEmpty) resolved = '/';
    return apiOrigin.replace(path: resolved);
  }

  static String _join(String base, String? segment) {
    final left = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    if (segment == null || segment.isEmpty) return left;
    final right = segment.startsWith('/') ? segment : '/$segment';
    return '$left$right';
  }

  static String _normalizePrefix(String prefix) {
    if (prefix.isEmpty || prefix == '/') return '';
    final withLeading = prefix.startsWith('/') ? prefix : '/$prefix';
    return withLeading.endsWith('/')
        ? withLeading.substring(0, withLeading.length - 1)
        : withLeading;
  }

  AppConfig copyWith({
    Uri? apiOrigin,
    String? apiPrefix,
    Duration? requestTimeout,
  }) {
    return AppConfig(
      apiOrigin: apiOrigin ?? this.apiOrigin,
      apiPrefix: apiPrefix ?? this.apiPrefix,
      requestTimeout: requestTimeout ?? this.requestTimeout,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppConfig &&
        other.apiOrigin == apiOrigin &&
        other.apiPrefix == apiPrefix &&
        other.requestTimeout == requestTimeout;
  }

  @override
  int get hashCode => Object.hash(apiOrigin, apiPrefix, requestTimeout);

  @override
  String toString() =>
      'AppConfig(origin: $apiOrigin, prefix: $apiPrefix, timeout: $requestTimeout)';
}
