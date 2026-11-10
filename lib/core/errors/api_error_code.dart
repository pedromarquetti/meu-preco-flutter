/// Stable machine-readable error codes emitted by the Meu Preço API.
///
/// The backend documents these as the `error.code` enum in its OpenAPI schema.
/// Match on this enum instead of parsing `error.message`, which is prose meant
/// for humans and may change.
enum ApiErrorCode {
  captchaRequired('captcha_required'),
  captchaWrongSolution('captcha_wrong_solution'),
  challengeExpired('challenge_expired'),
  challengeLocked('challenge_locked'),
  challengeNotFound('challenge_not_found'),
  challengeUsed('challenge_used'),
  conflict('conflict'),
  forbidden('forbidden'),
  inUse('in_use'),
  internalError('internal_error'),
  invalidAccessKey('invalid_access_key'),
  invalidAssignment('invalid_assignment'),
  invalidCredentials('invalid_credentials'),
  invalidEmail('invalid_email'),
  invalidFilter('invalid_filter'),
  invalidName('invalid_name'),
  invalidPassword('invalid_password'),
  invalidQrPayload('invalid_qr_payload'),
  invalidRefreshToken('invalid_refresh_token'),
  invalidRequest('invalid_request'),
  invalidResolution('invalid_resolution'),
  invalidRole('invalid_role'),
  notFound('not_found'),
  previewAlreadyCommitted('preview_already_committed'),
  previewExpired('preview_expired'),
  previewNotFound('preview_not_found'),
  previewSnapshotMissing('preview_snapshot_missing'),
  previewSnapshotUnreadable('preview_snapshot_unreadable'),
  rateLimited('rate_limited'),
  receiptNotFound('receipt_not_found'),
  refreshReuseDetected('refresh_reuse_detected'),
  unauthorized('unauthorized'),
  unsupportedUf('unsupported_uf'),
  upstreamError('upstream_error'),
  upstreamRateLimited('upstream_rate_limited'),
  userExists('user_exists');

  const ApiErrorCode(this.wire);

  /// The value the API sends in `error.code`.
  final String wire;

  static final Map<String, ApiErrorCode> _byWire = {
    for (final code in values) code.wire: code,
  };

  /// Resolves a backend `error.code`, or `null` when it is absent or unknown.
  static ApiErrorCode? fromWire(String? wire) =>
      wire == null ? null : _byWire[wire];
}
