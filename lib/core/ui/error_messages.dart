import '../../l10n/generated/app_localizations.dart';
import '../errors/app_exception.dart';

/// Maps any failure to a localized, user-facing message.
///
/// Transport, timeout, rate-limit, and server failures get dedicated copy so
/// raw exception text or backend prose never reaches the UI. Unknown failures
/// fall back to the generic error label. Backend codes that the caller knows
/// how to translate should be handled before calling this.
String localizedErrorMessage(AppLocalizations strings, Object error) {
  if (error is RateLimitedException) return strings.rateLimitedError;
  if (error is NetworkException ||
      error is TimeoutException ||
      error is ServerException) {
    return strings.networkErrorMessage;
  }
  if (error is ForbiddenException) return strings.forbiddenError;
  if (error is NotFoundException) return strings.notFoundError;
  return strings.errorLabel;
}
