import '../../core/http/server_health_service.dart';
import '../../l10n/generated/app_localizations.dart';

/// User-facing message for a health probe outcome.
///
/// Shared by the server selection and settings screens so both report the same
/// failure details, including the origins that were probed.
String serverHealthMessage(
  AppLocalizations strings,
  ServerHealthResult result,
) {
  if (result.ok) return strings.serverConnectionSuccess;

  switch (result.errorCode) {
    case 'invalid_url':
      return strings.invalidServerUrl;
    case 'timeout':
      return result.attemptedOrigins.length > 1
          ? strings.serverConnectionFailureWithAttempts(
              result.attemptedOrigins.join(', '),
            )
          : strings.serverConnectionTimeout;
    default:
      return result.attemptedOrigins.isEmpty
          ? strings.serverConnectionFailure
          : strings.serverConnectionFailureWithAttempts(
              result.attemptedOrigins.join(', '),
            );
  }
}
