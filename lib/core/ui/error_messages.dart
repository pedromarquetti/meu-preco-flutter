import '../../l10n/generated/app_localizations.dart';
import '../errors/api_error_code.dart';
import '../errors/app_exception.dart';

/// Maps any failure to a localized, user-facing message.
///
/// Backend codes win so each documented failure reads distinctly; transport,
/// timeout, rate-limit, and server failures get dedicated copy. Raw exception
/// text or backend prose never reaches the UI, and unknown failures fall back
/// to the generic error label.
String localizedErrorMessage(AppLocalizations strings, Object error) {
  if (error is AppException) {
    switch (ApiErrorCode.fromWire(error.code)) {
      case ApiErrorCode.unauthorized:
      case ApiErrorCode.invalidRefreshToken:
      case ApiErrorCode.refreshReuseDetected:
        return strings.sessionExpiredMessage;
      case ApiErrorCode.invalidCredentials:
        return strings.invalidCredentialsError;
      case ApiErrorCode.invalidName:
        return strings.invalidNameError;
      case ApiErrorCode.invalidEmail:
        return strings.invalidEmailError;
      case ApiErrorCode.invalidPassword:
        return strings.weakPasswordError;
      case ApiErrorCode.userExists:
        return strings.userExistsError;
      case ApiErrorCode.invalidRequest:
        return strings.invalidRequestError;
      case ApiErrorCode.invalidFilter:
        return strings.invalidFilterError;
      case ApiErrorCode.invalidRole:
        return strings.invalidRoleError;
      case ApiErrorCode.invalidAccessKey:
        return strings.invalidAccessKeyError;
      case ApiErrorCode.invalidQrPayload:
        return strings.invalidQrPayloadError;
      case ApiErrorCode.invalidResolution:
        return strings.invalidResolutionError;
      case ApiErrorCode.invalidAssignment:
        return strings.invalidAssignment;
      case ApiErrorCode.forbidden:
        return strings.forbiddenError;
      case ApiErrorCode.notFound:
        return strings.notFoundError;
      case ApiErrorCode.receiptNotFound:
        return strings.receiptNotFoundError;
      case ApiErrorCode.previewNotFound:
        return strings.previewNotFoundError;
      case ApiErrorCode.challengeNotFound:
        return strings.captchaNotFoundError;
      case ApiErrorCode.conflict:
        return strings.conflictError;
      case ApiErrorCode.inUse:
        return strings.inUseError;
      case ApiErrorCode.challengeUsed:
        return strings.captchaUsedError;
      case ApiErrorCode.previewAlreadyCommitted:
        return strings.alreadyCommittedError;
      case ApiErrorCode.captchaRequired:
        return strings.captchaRequiredError;
      case ApiErrorCode.captchaWrongSolution:
        return strings.captchaWrongSolutionError;
      case ApiErrorCode.challengeExpired:
        return strings.captchaExpiredError;
      case ApiErrorCode.challengeLocked:
        return strings.captchaLockedError;
      case ApiErrorCode.previewExpired:
        return strings.previewExpiredError;
      case ApiErrorCode.previewSnapshotMissing:
        return strings.previewNotFoundError;
      case ApiErrorCode.previewSnapshotUnreadable:
        return strings.previewSnapshotUnreadableError;
      case ApiErrorCode.rateLimited:
        return strings.rateLimitedError;
      case ApiErrorCode.upstreamRateLimited:
        return strings.upstreamRateLimitedError;
      case ApiErrorCode.unsupportedUf:
        return strings.unsupportedUfError;
      case ApiErrorCode.upstreamError:
        return strings.upstreamErrorMessage;
      case ApiErrorCode.internalError:
        return strings.internalServerError;
      case null:
        break;
    }
    if (error.code == 'invalid_date_range') {
      return strings.invalidDateRangeError;
    }
    // Locally-constructed exceptions may not carry a backend code.
    if (error is InvalidAssignment) return strings.invalidAssignment;
    if (error is ForbiddenException) return strings.forbiddenError;
    if (error is NotFoundException) return strings.notFoundError;
    if (error is ConflictException) return strings.conflictError;
    if (error is RateLimitedException) return strings.rateLimitedError;
    if (error is NetworkException ||
        error is TimeoutException ||
        error is ServerException) {
      return strings.networkErrorMessage;
    }
  }
  return strings.errorLabel;
}
