import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../nfce/nfce_entry_mode.dart';

/// Bottom-right button that opens receipt capture, starting on the scan tab.
class ScanSpeedDial extends StatefulWidget {
  const ScanSpeedDial({super.key});

  @override
  State<ScanSpeedDial> createState() => _ScanSpeedDialState();
}

class _ScanSpeedDialState extends State<ScanSpeedDial> {
  bool _open = false;

  void _go(NfceEntryMode mode) {
    setState(() => _open = false);
    context.push(AppRoutes.receiptSubmissionFor(mode));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'scanDial',
          tooltip: strings.scanReceiptAction,
          onPressed: () => _go(NfceEntryMode.scan),
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 150),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
