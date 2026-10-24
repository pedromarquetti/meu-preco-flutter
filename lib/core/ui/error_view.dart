import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'error_messages.dart';

/// Full-surface error state with an optional retry action.
///
/// Provide a pre-localized [message], or an [error] whose localized text is
/// resolved at build time. Raw exception text and backend prose are never shown.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title,
    this.message,
    this.error,
    this.onRetry,
    this.retryLabel,
  });

  /// Fallback title when no [message] is available.
  final String? title;

  /// Problem description shown to the user.
  final String? message;

  /// Failure whose localized message is used when [message] is null.
  final Object? error;

  final VoidCallback? onRetry;

  final String? retryLabel;

  /// Convenience constructor that localizes the given [error].
  const ErrorView.fromException(
    this.error, {
    super.key,
    this.title,
    this.onRetry,
    this.retryLabel,
  }) : message = null;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final resolvedTitle = title ?? strings.errorLabel;
    final resolvedDescription =
        message ??
        (error != null
            ? localizedErrorMessage(strings, error!)
            : strings.errorLabel);
    // Avoid repeating the same sentence as both heading and body.
    final description = resolvedDescription == resolvedTitle
        ? null
        : resolvedDescription;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              resolvedTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
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
