import '../../core/errors/app_exception.dart';
import '../../l10n/generated/app_localizations.dart';

/// Maps a failure to a localized, user-facing authentication message.
///
/// Known backend codes win; transport and server failures fall back to a
/// connectivity message, and anything else to a generic error.
String authErrorMessage(AppLocalizations strings, Object error) {
  if (error is AppException) {
    switch (error.code) {
      case 'invalid_credentials':
        return strings.invalidCredentialsError;
      case 'invalid_login':
        return strings.invalidIdentifierError;
      case 'invalid_name':
        return strings.invalidNameError;
      case 'invalid_email':
        return strings.invalidEmailError;
      case 'invalid_password':
        return strings.weakPasswordError;
      case 'user_exists':
        return strings.userExistsError;
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
