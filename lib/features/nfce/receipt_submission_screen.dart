import 'package:flutter/material.dart';

import '../../core/ui/coming_soon_view.dart';
import '../../l10n/generated/app_localizations.dart';

/// NFC-e submission flow.
class ReceiptSubmissionScreen extends StatelessWidget {
  const ReceiptSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.receiptSubmissionTitle)),
      body: const ComingSoonView(),
    );
  }
}
