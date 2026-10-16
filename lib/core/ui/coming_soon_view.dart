import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'empty_view.dart';

/// Placeholder body for screens whose behaviour is not implemented yet.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return EmptyView(
      icon: Icons.construction_outlined,
      title: strings.comingSoonLabel,
      message: message ?? strings.notImplementedLabel,
    );
  }
}
