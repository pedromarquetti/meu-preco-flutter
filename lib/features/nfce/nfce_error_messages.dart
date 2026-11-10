import '../../core/ui/error_messages.dart';
import '../../l10n/generated/app_localizations.dart';

/// Maps a receipt-flow failure to a localized, user-facing message.
///
/// Every NFC-e code is part of the shared API error set, so this delegates to
/// the central mapper.
String nfceErrorMessage(AppLocalizations strings, Object error) =>
    localizedErrorMessage(strings, error);
