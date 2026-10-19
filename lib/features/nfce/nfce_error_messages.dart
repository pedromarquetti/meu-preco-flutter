import '../../core/errors/app_exception.dart';
import '../../l10n/generated/app_localizations.dart';

/// Maps a receipt-flow failure to a localized, user-facing message.
///
/// Known backend codes win so each recovery state (expired preview, already
/// committed, upstream failure, invalid key, rate limit) reads distinctly;
/// transport/server failures fall back to a connectivity message.
String nfceErrorMessage(AppLocalizations strings, Object error) {
  if (error is AppException) {
    switch (error.code) {
      case 'invalid_access_key':
        return strings.invalidAccessKeyError;
      case 'invalid_qr_payload':
        return strings.invalidQrPayloadError;
      case 'receipt_not_found':
        return strings.receiptNotFoundError;
      case 'unsupported_uf':
        return strings.unsupportedUfError;
      case 'upstream_error':
        return strings.upstreamErrorMessage;
      case 'preview_expired':
        return strings.previewExpiredError;
      case 'preview_not_found':
        return strings.previewNotFoundError;
      case 'preview_already_committed':
        return strings.alreadyCommittedError;
      case 'invalid_resolution':
        return strings.invalidResolutionError;
      case 'challenge_expired':
        return strings.captchaExpiredError;
      case 'challenge_locked':
        return strings.captchaLockedError;
      case 'challenge_used':
        return strings.captchaUsedError;
      case 'challenge_not_found':
        return strings.captchaNotFoundError;
    }
    if (error is RateLimitedException) return strings.rateLimitedError;
    if (error is NetworkException ||
        error is TimeoutException ||
        error is ServerException) {
      return strings.networkErrorMessage;
    }
  }
  return strings.errorLabel;
}
