import 'package:flutter/material.dart';

import '../../core/ui/coming_soon_view.dart';
import '../../l10n/generated/app_localizations.dart';

/// Admin workflows: register users and resolve `uid_uncertain`.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.adminTitle)),
      body: const ComingSoonView(),
    );
  }
}
