import 'package:flutter/foundation.dart';

/// Immutable runtime configuration for talking to a Meu Preço API instance.
///
/// The API origin is chosen by the user (see the server configuration screen
/// and Settings), while the `/api/v1` prefix and request timeout have sensible
/// defaults that can be overridden with `--dart-define`.
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

  /// Lowest valid TCP port (0 means "any port" and is not a usable origin).
  static const int minPort = 1;

  /// Highest valid TCP port.
  static const int maxPort = 65535;

  /// Port probed when the user does not supply one (the API's local default).
  static const int fallbackPort = 8080;

  /// Root URI of the configured Meu Preço API (scheme + host + optional port).
  ///
  /// The [path] is preserved for deployments hosted under a sub-path but any
  /// trailing slash is removed.
  final Uri apiOrigin;

  /// Version prefix applied to API operations, e.g. `/api/v1`.
  final String apiPrefix;

  /// Timeout applied to API requests.
  final Duration requestTimeout;

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

  /// Origins that should be probed for a user supplied server address.
  ///
  /// * A scheme-less address without a port (`localhost`, `api.example.com`)
  ///   is tried on the fallback port first, then on the scheme defaults, for
  ///   both schemes: `http://host:8080`, `https://host:8080`, `http://host`,
  ///   `https://host`.
  /// * A scheme-less address with an explicit port (`localhost:2138`) keeps
  ///   that port and is tried over both schemes, without a `:8080` fallback.
  /// * An explicit `http(s)://` address keeps its scheme; when it has no port
  ///   the address as typed is tried first, then the fallback-port variant.
  /// * Any other explicit scheme is returned unchanged so it fails validation
  ///   instead of being silently rewritten.
  ///
  /// Returns an empty list for input that cannot be a server address at all
  /// (empty, or containing whitespace).
  static List<String> candidateOrigins(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const <String>[];
    if (trimmed.contains(RegExp(r'\s'))) return const <String>[];

    final hasExplicitPort = _hasExplicitPort(trimmed);

    if (_hasExplicitScheme(trimmed)) {
      final scheme = trimmed.substring(0, trimmed.indexOf('://')).toLowerCase();
      if (scheme != 'http' && scheme != 'https') {
        return <String>[trimmed];
      }
      if (hasExplicitPort) return <String>[trimmed];
      final withPort = _withPort(trimmed, fallbackPort);
      if (withPort == trimmed) return <String>[trimmed];
      return <String>[trimmed, withPort];
    }

    if (hasExplicitPort) {
      return <String>['https://$trimmed', 'http://$trimmed'];
    }

    return <String>[
      _withPort('http://$trimmed', fallbackPort),
      _withPort('https://$trimmed', fallbackPort),
      'http://$trimmed',
      'https://$trimmed',
    ];
  }

  /// Whether [value] carries an explicit TCP port in its authority.
  ///
  /// Only the authority is inspected, so digits in an IP (`192.168.1.5`) or a
  /// hostname (`web2.example.com`) are never mistaken for a port.
  static bool _hasExplicitPort(String value) {
    var rest = value;
    final separator = rest.indexOf('://');
    if (separator > 0) rest = rest.substring(separator + 3);
    final authority = rest.split(RegExp(r'[/?#]')).first;
    return RegExp(r':\d+$').hasMatch(authority);
  }

  /// Returns [origin] with [port] set, preserving scheme, host and path.
  ///
  /// Returns [origin] unchanged when it has no parseable host, so malformed
  /// input is rejected by [tryParseOrigin] instead of becoming a different URL.
  static String _withPort(String origin, int port) {
    final uri = Uri.tryParse(origin);
    if (uri == null || uri.host.isEmpty) return origin;
    return uri.replace(port: port).toString();
  }

  /// Whether [value] starts with a `scheme://` prefix of any kind.
  ///
  /// Deliberately scheme-agnostic: `ftp://host` must be rejected as invalid
  /// instead of being treated as a host and prefixed with `https://`.
  static bool _hasExplicitScheme(String value) {
    final separator = value.indexOf('://');
    if (separator <= 0) return false;
    return RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*$')
        .hasMatch(value.substring(0, separator));
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
