import '../config/app_config.dart';
import '../errors/app_exception.dart';
import 'api_client.dart';

/// Outcome of a liveness (`/healthz`) or readiness (`/readyz`) probe against a
/// candidate API origin.
class ServerHealthResult {
  const ServerHealthResult.ok({this.statusCode})
    : ok = true,
      errorCode = null,
      errorMessage = null;

  const ServerHealthResult.failed({
    this.statusCode,
    this.errorCode,
    this.errorMessage,
  }) : ok = false;

  /// Whether the origin answered with a well-formed healthy [Status] body.
  final bool ok;

  final int? statusCode;

  /// Machine-readable reason, e.g. `invalid_url`, `timeout`, `unreachable`,
  /// `unhealthy`.
  final String? errorCode;

  final String? errorMessage;
}

/// Probes whether a given API origin is a reachable, healthy Meu Preço server.
///
/// Abstracted so tests can assert the server-config flow without real
/// networking.
abstract interface class ServerHealthChecker {
  /// Liveness: `GET /healthz` — is the server process up?
  Future<ServerHealthResult> check(String rawOrigin);

  /// Readiness: `GET /readyz` — can the server serve requests (e.g. is the
  /// database reachable)? A `503` carries a `reason` in its body.
  Future<ServerHealthResult> checkReadiness(String rawOrigin);
}

/// [ServerHealthChecker] that probes through the shared [ApiClient].
///
/// Using [ApiClient.sendRaw] keeps the transport (URL joining, timeout,
/// decoding) in one place while still surfacing the response body on non-2xx
/// statuses, which `/readyz` needs for its `reason`.
class HttpServerHealthChecker implements ServerHealthChecker {
  HttpServerHealthChecker({required ApiClient apiClient, Duration? timeout})
    : _apiClient = apiClient, // ignore: prefer_initializing_formals
      _timeout = timeout ?? const Duration(seconds: 8);

  static const String livenessPath = '/healthz';
  static const String readinessPath = '/readyz';

  final ApiClient _apiClient;
  final Duration _timeout;

  @override
  Future<ServerHealthResult> check(String rawOrigin) {
    return _probe(rawOrigin, livenessPath);
  }

  @override
  Future<ServerHealthResult> checkReadiness(String rawOrigin) {
    return _probe(rawOrigin, readinessPath);
  }

  Future<ServerHealthResult> _probe(String rawOrigin, String path) async {
    // A candidate config lets the probe target an origin that has not been
    // saved yet, and applies the (shorter) health-check timeout.
    final config = AppConfig.tryFromOrigin(rawOrigin, requestTimeout: _timeout);
    if (config == null) {
      return const ServerHealthResult.failed(
        errorCode: 'invalid_url',
        errorMessage: 'The server address is not a valid http(s) origin.',
      );
    }

    try {
      final response = await _apiClient.sendRaw(
        'GET',
        path,
        useApiPrefix: false,
        config: config,
      );
      return _interpret(response);
    } on TimeoutException {
      return const ServerHealthResult.failed(
        errorCode: 'timeout',
        errorMessage: 'The server did not respond in time.',
      );
    } on NetworkException catch (error) {
      return ServerHealthResult.failed(
        errorCode: 'unreachable',
        errorMessage: error.message,
      );
    } on AppException catch (error) {
      return ServerHealthResult.failed(
        statusCode: error.statusCode,
        errorCode: 'unhealthy',
        errorMessage: error.message,
      );
    } on Object catch (error) {
      // The probe backs a user action, so it must always resolve to a result
      // (never throw) — a stray `Error` here would freeze the caller's UI.
      return ServerHealthResult.failed(
        errorCode: 'unreachable',
        errorMessage: error.toString(),
      );
    }
  }

  /// Turns a raw response into a result by parsing the `Status` schema:
  /// `{"status": "ok"}` on success, or `{"status": "unavailable",
  /// "reason": "..."}` on a failed readiness check.
  ServerHealthResult _interpret(ApiResponse response) {
    final data = response.data;
    final status = data is Map && data['status'] is String
        ? data['status'] as String
        : null;

    if (response.isSuccess && status == 'ok') {
      return ServerHealthResult.ok(statusCode: response.statusCode);
    }

    final reason = data is Map && data['reason'] is String
        ? data['reason'] as String
        : null;
    final message =
        reason ??
        (status != null
            ? 'Server status: $status'
            : 'Unexpected response from the server (HTTP ${response.statusCode}).');

    return ServerHealthResult.failed(
      statusCode: response.statusCode,
      errorCode: 'unhealthy',
      errorMessage: message,
    );
  }
}
