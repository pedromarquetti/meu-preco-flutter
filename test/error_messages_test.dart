import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/core/errors/api_error_code.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/ui/error_messages.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';

void main() {
  final strings = lookupAppLocalizations(const Locale('pt'));

  test('maps documented API codes to dedicated messages', () {
    final cases = <String, String>{
      'invalid_assignment': strings.invalidAssignment,
      'invalid_request': strings.invalidRequestError,
      'invalid_filter': strings.invalidFilterError,
      'invalid_role': strings.invalidRoleError,
      'conflict': strings.conflictError,
      'in_use': strings.inUseError,
      'internal_error': strings.internalServerError,
      'upstream_rate_limited': strings.upstreamRateLimitedError,
      'preview_snapshot_unreadable': strings.previewSnapshotUnreadableError,
      'captcha_required': strings.captchaRequiredError,
      'receipt_not_found': strings.receiptNotFoundError,
      'preview_not_found': strings.previewNotFoundError,
      'challenge_not_found': strings.captchaNotFoundError,
      'unauthorized': strings.sessionExpiredMessage,
      'invalid_credentials': strings.invalidCredentialsError,
      'upstream_error': strings.upstreamErrorMessage,
    };

    for (final entry in cases.entries) {
      expect(
        localizedErrorMessage(strings, ApiException(code: entry.key)),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('every API code has a dedicated message', () {
    for (final code in ApiErrorCode.values) {
      final message = localizedErrorMessage(
        strings,
        ApiException(code: code.wire),
      );
      expect(message, isNot(strings.errorLabel), reason: code.wire);
      expect(message, isNot(strings.networkErrorMessage), reason: code.wire);
    }
  });

  test('maps the local invalid_date_range code', () {
    expect(
      localizedErrorMessage(
        strings,
        const ValidationException(code: 'invalid_date_range'),
      ),
      strings.invalidDateRangeError,
    );
  });

  test('keeps transport and unknown-code fallbacks', () {
    expect(
      localizedErrorMessage(strings, const NetworkException()),
      strings.networkErrorMessage,
    );
    expect(
      localizedErrorMessage(strings, const ServerException()),
      strings.networkErrorMessage,
    );
    expect(
      localizedErrorMessage(strings, const ApiException(code: 'unknown')),
      strings.errorLabel,
    );
  });

  test('never leaks the backend message', () {
    const backendMessage = 'raw backend prose';
    final message = localizedErrorMessage(
      strings,
      const ApiException(code: 'invalid_assignment', message: backendMessage),
    );

    expect(message, isNot(contains(backendMessage)));
  });
}
