import '../../core/errors/app_exception.dart';
import '../../core/ui/error_messages.dart';
import '../../l10n/generated/app_localizations.dart';

/// Maps a failure to a localized, user-facing authentication message.
///
/// The login form accepts either an email or an account name, so the local
/// `invalid_login` code has dedicated copy. Every backend code delegates to the
/// shared mapper.
String authErrorMessage(AppLocalizations strings, Object error) {
  if (error is AppException && error.code == 'invalid_login') {
    return strings.invalidIdentifierError;
  }
  return localizedErrorMessage(strings, error);
}
