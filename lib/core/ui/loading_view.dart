import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Full-surface loading indicator with an accessible label.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final label = message ?? strings.loadingLabel;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(semanticsLabel: label),
          const SizedBox(height: 16),
          Text(
            label,
            style: textTheme.bodyLarge?.copyWith(color: color.onSurface),
          ),
        ],
      ),
    );
  }
}
