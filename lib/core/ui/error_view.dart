import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../errors/app_exception.dart';

/// Full-surface error state with an optional retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
  });

  /// Fallback title when no [message] is available.
  final String? title;

  /// Problem description shown to the user.
  final String? message;

  final VoidCallback? onRetry;

  final String? retryLabel;

  /// Builds a message for common [AppException]s, falling back to the raw
  /// message.
  factory ErrorView.fromException(
    Object error, {
    Key? key,
    String? title,
    VoidCallback? onRetry,
    String? retryLabel,
  }) {
    return ErrorView(
      key: key,
      title: title,
      message: describeError(error),
      onRetry: onRetry,
      retryLabel: retryLabel,
    );
  }

  /// Returns a user-facing description for an [AppException].
  static String? describeError(Object error) {
    if (error is AppException && error.message != null) return error.message;
    if (error is AppException) return error.code;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final description = message ?? strings.errorLabel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title ?? strings.errorLabel,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? strings.retryAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
