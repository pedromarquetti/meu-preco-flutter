import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/loading_view.dart';
import '../../l10n/generated/app_localizations.dart';
import 'code_scanner.dart';
import 'scanner_status.dart';

/// Full-screen camera scanner for an NFC-e QR code.
///
/// Opening this screen is the moment the OS prompt may appear: it prepares the
/// camera (permission + hardware) before mounting the preview, and every
/// non-ready outcome renders a dedicated recovery path. On a successful scan it
/// pops the raw payload back to the caller.
class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  ScannerStatus? _status;
  bool _preparing = false;
  bool _handled = false;

  CodeScanner get _scanner => context.appDependencies.codeScanner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    if (_preparing || !mounted) return;
    setState(() => _preparing = true);
    final status = _scanner.isSupported
        ? await _scanner.prepare()
        : const ScannerStatus(ScannerAvailability.unavailable);
    if (!mounted) return;
    setState(() {
      _status = status;
      _preparing = false;
    });
  }

  void _onDetected(String payload) {
    if (_handled) return;
    final value = payload.trim();
    if (value.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(value);
  }

  Future<void> _openSettings() async {
    final opened = await _scanner.openSettings();
    if (!mounted) return;
    if (opened) await _prepare();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.scanReceiptTitle)),
      body: _buildBody(strings),
    );
  }

  Widget _buildBody(AppLocalizations strings) {
    if (_preparing || _status == null) {
      return LoadingView(message: strings.scannerPreparingLabel);
    }

    final status = _status!;
    if (status.isReady) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _scanner.buildPreview(onDetected: _onDetected),
          const _ScannerOverlay(),
        ],
      );
    }

    return _ScannerUnavailable(
      strings: strings,
      status: status,
      onRetry: _prepare,
      onOpenSettings: _openSettings,
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final media = MediaQuery.sizeOf(context);
    final side = media.shortestSide * 0.68;

    return IgnorePointer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              strings.scannerInstruction,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.cameraOverlay,
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: side,
              height: side,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.cameraOverlay, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _ScannerUnavailable extends StatelessWidget {
  const _ScannerUnavailable({
    required this.strings,
    required this.status,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final AppLocalizations strings;
  final ScannerStatus status;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, message) = _copy(strings);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (status.canRetryPermission)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.lock_open),
                  label: Text(strings.cameraPermissionRetryAction),
                ),
              if (status.requiresSettings) ...[
                FilledButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings),
                  label: Text(strings.openSettingsAction),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRetry,
                  child: Text(strings.cameraPermissionRetryAction),
                ),
              ],
              if (!status.canRetryPermission && !status.requiresSettings)
                OutlinedButton(
                  onPressed: onRetry,
                  child: Text(strings.retryAction),
                ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, String, String) _copy(AppLocalizations strings) {
    return switch (status.availability) {
      ScannerAvailability.unavailable => (
        Icons.no_photography_outlined,
        strings.cameraUnavailableTitle,
        strings.cameraUnsupportedMessage,
      ),
      ScannerAvailability.permissionDenied => (
        Icons.no_photography_outlined,
        strings.cameraPermissionTitle,
        strings.cameraPermissionDeniedMessage,
      ),
      ScannerAvailability.permissionDeniedForever => (
        Icons.no_photography_outlined,
        strings.cameraPermissionTitle,
        strings.cameraPermissionForeverMessage,
      ),
      ScannerAvailability.noCamera => (
        Icons.photo_camera_front_outlined,
        strings.cameraUnavailableTitle,
        strings.cameraNoCameraMessage,
      ),
      ScannerAvailability.error => (
        Icons.error_outline,
        strings.cameraUnavailableTitle,
        strings.cameraErrorMessage,
      ),
      ScannerAvailability.ready ||
      ScannerAvailability.permissionNotRequested => (
        Icons.error_outline,
        strings.cameraUnavailableTitle,
        strings.cameraErrorMessage,
      ),
    };
  }
}
