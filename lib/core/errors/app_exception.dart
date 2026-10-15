/// Base type for every failure surfaced by the app's data layer.
///
/// Keeping failures in a small type hierarchy lets the UI branch on the kind of
/// problem instead of parsing messages, while still retaining the raw
/// `code`/`message`/`status` metadata the backend reports.
abstract class AppException implements Exception {
  const AppException({
    this.message,
    this.code,
    this.statusCode,
    this.retryable = false,
    this.retryAfter,
  });

  /// Human-readable message, typically from `error.message`.
  final String? message;

  /// Machine-readable backend code, typically from `error.code`.
  final String? code;

  /// HTTP status code, when the failure originated from a response.
  final int? statusCode;

  /// Whether an immediate retry could succeed without user intervention.
  final bool retryable;

  /// Server-provided back-off (from `Retry-After`), when available.
  final Duration? retryAfter;

  @override
  String toString() =>
      '$runtimeType(status: $statusCode, code: $code, message: $message)';
}

/// The server could not be reached (DNS, TCP, TLS, or transport failure).
class NetworkException extends AppException {
  const NetworkException({super.message}) : super(retryable: true);
}

/// The request did not complete within the configured timeout.
class TimeoutException extends AppException {
  const TimeoutException({super.message})
    : super(retryable: true, statusCode: 408);
}

/// Malformed configuration or an unusable API origin.
class ConfigException extends AppException {
  const ConfigException({super.message, super.code});
}

/// Generic API failure carrying status and backend metadata.
class ApiException extends AppException {
  const ApiException({
    super.message,
    super.code,
    super.statusCode,
    super.retryable,
    super.retryAfter,
  });
}

/// 401 — missing, expired, or invalid credentials.
class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message, super.code})
    : super(statusCode: 401);
}

/// 403 — authenticated but not allowed.
class ForbiddenException extends ApiException {
  const ForbiddenException({super.message, super.code})
    : super(statusCode: 403);
}

/// 404 — resource not found.
class NotFoundException extends ApiException {
  const NotFoundException({super.message, super.code}) : super(statusCode: 404);
}

/// 409 — conflicting state (e.g. already committed).
class ConflictException extends ApiException {
  const ConflictException({super.message, super.code}) : super(statusCode: 409);
}

/// 412 — precondition failed (e.g. captcha required).
class PreconditionFailedException extends ApiException {
  const PreconditionFailedException({super.message, super.code})
    : super(statusCode: 412);
}

/// 422 — request failed validation.
class ValidationException extends ApiException {
  const ValidationException({super.message, super.code})
    : super(statusCode: 422);
}

/// 429 — rate limited.
class RateLimitedException extends ApiException {
  const RateLimitedException({super.message, super.code, super.retryAfter})
    : super(statusCode: 429, retryable: true);
}

/// 5xx — server-side failure.
class ServerException extends ApiException {
  const ServerException({super.message, super.code, super.statusCode})
    : super(retryable: true);
}
