import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../core/models/models.dart';
import '../../core/ui/loading_view.dart';
import '../../l10n/generated/app_localizations.dart';
import 'code_scanner.dart';
import 'receipt_scanner_screen.dart';
import 'nfce_entry_mode.dart';
import 'nfce_error_messages.dart';
import 'nfce_input.dart';
import 'nfce_submission_controller.dart';
import 'widgets/product_picker_sheet.dart';

/// NFC-e ingestion flow: capture an identifier, draft the receipt, clear any
/// captcha, review the plan, then dry-run or commit it.
class ReceiptSubmissionScreen extends StatefulWidget {
  const ReceiptSubmissionScreen({
    super.key,
    this.initialMode = NfceEntryMode.scan,
  });

  /// Which capture method starts selected.
  final NfceEntryMode initialMode;

  @override
  State<ReceiptSubmissionScreen> createState() =>
      _ReceiptSubmissionScreenState();
}

class _ReceiptSubmissionScreenState extends State<ReceiptSubmissionScreen> {
  late final NfceSubmissionController _controller;
  late NfceEntryMode _mode = widget.initialMode;
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _qrController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  String? _inputError;

  CodeScanner get _scanner => context.appDependencies.codeScanner;

  @override
  void initState() {
    super.initState();
    _controller = NfceSubmissionController(
      repository: context.appDependencies.nfceRepository,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _keyController.dispose();
    _qrController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.receiptSubmissionTitle)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _buildStage(strings),
      ),
    );
  }

  Widget _buildStage(AppLocalizations strings) {
    return switch (_controller.stage) {
      NfceStage.input => _buildInput(strings),
      NfceStage.drafting => LoadingView(message: strings.draftingReceiptLabel),
      NfceStage.captcha => _buildCaptcha(strings),
      NfceStage.preview => _buildPreview(strings),
      NfceStage.committing => LoadingView(
        message: strings.submittingReceiptLabel,
      ),
      NfceStage.result => _buildResult(strings),
      NfceStage.error => _buildError(strings),
    };
  }

  // --- Input -------------------------------------------------------------

  Widget _buildInput(AppLocalizations strings) {
    final theme = Theme.of(context);
    final isScan = _mode == NfceEntryMode.scan;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<NfceEntryMode>(
                segments: [
                  ButtonSegment(
                    value: NfceEntryMode.scan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(strings.scanQrAction),
                  ),
                  ButtonSegment(
                    value: NfceEntryMode.key,
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    label: Text(strings.accessKeyLabel),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) => setState(() {
                  _mode = selection.first;
                  _inputError = null;
                }),
              ),
              const SizedBox(height: 24),
              if (isScan) ..._scanFields(strings) else ..._keyFields(strings),
              if (_inputError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _inputError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              if (_inputError != null &&
                  _mode == NfceEntryMode.scan &&
                  _controller.error?.code == 'invalid_qr_payload') ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _controller.busy ? null : _extractAccessKeyFromQr,
                  icon: const Icon(Icons.content_copy),
                  label: Text(strings.extractAccessKeyFromQrAction),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _controller.busy ? null : _submitInput,
                child: Text(strings.continueAction),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _scanFields(AppLocalizations strings) {
    final scanner = _scanner;
    return [
      if (scanner.isSupported) ...[
        OutlinedButton.icon(
          onPressed: _controller.busy ? null : _scan,
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(strings.scanWithCameraAction),
        ),
        const SizedBox(height: 12),
        Text(strings.scanQrHelp, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
      ] else ...[
        _InfoBanner(
          icon: Icons.no_photography_outlined,
          text: strings.scanQrUnavailable,
        ),
        const SizedBox(height: 16),
      ],
      TextField(
        controller: _qrController,
        enabled: !_controller.busy,
        minLines: 2,
        maxLines: 4,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: strings.qrPayloadLabel,
          hintText: strings.qrPayloadHint,
          border: const OutlineInputBorder(),
        ),
      ),
    ];
  }

  List<Widget> _keyFields(AppLocalizations strings) {
    return [
      TextField(
        controller: _keyController,
        enabled: !_controller.busy,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(44),
        ],
        decoration: InputDecoration(
          labelText: strings.accessKeyLabel,
          hintText: strings.accessKeyHint,
          helperText: strings.accessKeyHelp,
          border: const OutlineInputBorder(),
        ),
      ),
    ];
  }

  Future<void> _extractAccessKeyFromQr() async {
    final strings = AppLocalizations.of(context);
    final raw = _qrController.text;
    final cleaned = raw.replaceAll(RegExp(r'\s+'), '');
    final match = RegExp(r'(\d{44})').firstMatch(cleaned);
    if (match == null) {
      setState(() {
        _inputError = strings.extractAccessKeyFromQrNoMatchError;
      });
      return;
    }
    final key = match.group(1)!;
    await Clipboard.setData(ClipboardData(text: key));
    setState(() {
      _mode = NfceEntryMode.key;
      _inputError = null;
      _keyController.text = key;
    });
  }

  Future<void> _submitInput() async {
    final strings = AppLocalizations.of(context);
    final raw = _mode == NfceEntryMode.scan
        ? _qrController.text
        : _keyController.text;
    final input = NfceInput.tryParse(raw);
    if (input == null) {
      setState(() {
        _inputError = _mode == NfceEntryMode.scan
            ? strings.invalidQrPayloadError
            : strings.invalidAccessKeyError;
      });
      return;
    }
    if (_mode == NfceEntryMode.key && input.kind != NfceInputKind.accessKey) {
      setState(() => _inputError = strings.invalidAccessKeyError);
      return;
    }
    setState(() => _inputError = null);
    FocusScope.of(context).unfocus();
    await _controller.start(input);
    if (!mounted || _controller.stage != NfceStage.input) return;
    final error = _controller.error;
    if (error != null) {
      setState(() => _inputError = nfceErrorMessage(strings, error));
    }
  }

  Future<void> _scan() async {
    if (!_scanner.isSupported) {
      final payload = await _scanner.scan();
      if (!mounted || payload == null || payload.trim().isEmpty) return;
      _qrController.text = payload;
      final input = NfceInput.tryParse(payload);
      if (input != null) await _controller.start(input);
      return;
    }
    final payload = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()),
    );
    if (!mounted || payload == null || payload.trim().isEmpty) return;
    _qrController.text = payload;
    final input = NfceInput.tryParse(payload);
    if (input != null) await _controller.start(input);
  }

  // --- Captcha -----------------------------------------------------------

  Widget _buildCaptcha(AppLocalizations strings) {
    final theme = Theme.of(context);
    final feedback = _controller.captchaFeedback;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(strings.captchaTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(strings.captchaDescription),
              const SizedBox(height: 20),
              _buildCaptchaImage(strings),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _controller.captchaImageLoading
                      ? null
                      : _controller.refreshCaptchaImage,
                  icon: const Icon(Icons.refresh),
                  label: Text(strings.captchaReloadAction),
                ),
              ),
              const SizedBox(height: 8),
              if (feedback != null) ...[
                Text(
                  strings.captchaWrongSolutionError,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(strings.captchaAttemptsLeft(feedback.attemptsLeft)),
                const SizedBox(height: 12),
              ],
              if (_controller.error != null) ...[
                Text(
                  nfceErrorMessage(strings, _controller.error!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _captchaController,
                enabled: !_controller.busy,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _solveCaptcha(),
                decoration: InputDecoration(
                  labelText: strings.captchaSolutionLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _controller.busy ? null : _solveCaptcha,
                child: _controller.busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(strings.captchaSolveAction),
              ),
              if (_controller.error != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _controller.retryDraft,
                  child: Text(strings.startOverAction),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptchaImage(AppLocalizations strings) {
    final bytes = _controller.captchaImage;
    return Container(
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _controller.captchaImageLoading
          ? const CircularProgressIndicator()
          : bytes != null
          ? Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true)
          : Text(strings.captchaImageUnavailable),
    );
  }

  Future<void> _solveCaptcha() async {
    if (_captchaController.text.trim().isEmpty) return;
    await _controller.solveCaptcha(_captchaController.text);
  }

  // --- Preview -----------------------------------------------------------

  Widget _buildPreview(AppLocalizations strings) {
    final theme = Theme.of(context);
    final preview = _controller.preview!;
    final expired = _controller.previewExpired;
    final dryRun = _controller.dryRun;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PreviewHeader(
                strings: strings,
                preview: preview,
                expired: expired,
                expiryText: _expiryText(strings, preview.expiresAt),
              ),
              const SizedBox(height: 16),
              _TotalsCard(strings: strings, totals: preview.totals),
              const SizedBox(height: 16),
              Text(
                strings.previewItemsTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final item in preview.items)
                _PreviewItemCard(
                  strings: strings,
                  item: item,
                  resolution: _controller.resolutionFor(item.line),
                  assignedProduct: _controller.assignmentFor(item.line),
                  enabled: !_controller.busy,
                  onResolution: (action) =>
                      _controller.setResolution(item.line, action),
                  onAssign: () => _pickProduct(item),
                  onClearAssignment: () => _controller.setResolution(
                    item.line,
                    ResolutionAction.needsReview,
                  ),
                ),
              if (dryRun != null) ...[
                const SizedBox(height: 16),
                _DryRunCard(strings: strings, result: dryRun),
              ],
            ],
          ),
        ),
        _previewActions(strings, expired),
      ],
    );
  }

  Future<void> _pickProduct(PreviewItem item) async {
    final product = await showProductPickerSheet(
      context,
      initialQuery: item.description,
    );
    if (product == null || !mounted) return;
    _controller.assignProduct(item.line, product);
  }

  Widget _previewActions(AppLocalizations strings, bool expired) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: expired
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.previewExpiredError,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _controller.retryDraft,
                    child: Text(strings.startOverAction),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _controller.busy
                          ? null
                          : () => _controller.submit(confirm: false),
                      child: Text(strings.submitDryRunAction),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _controller.busy
                          ? null
                          : () => _controller.submit(confirm: true),
                      child: Text(strings.submitConfirmAction),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- Result ------------------------------------------------------------

  Widget _buildResult(AppLocalizations strings) {
    final theme = Theme.of(context);
    final result = _controller.result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                strings.commitResultTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (result.accessKey != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${strings.previewAccessKeyLabel}: ${result.accessKey}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 20),
              _CountRow(
                label: strings.commitWrittenLabel,
                value: result.written,
              ),
              _CountRow(
                label: strings.commitAutoSavedLabel,
                value: result.autoSaved,
              ),
              _CountRow(
                label: strings.commitAssignedLabel,
                value: result.assigned,
              ),
              _CountRow(
                label: strings.commitSkippedLabel,
                value: result.skipped,
              ),
              _CountRow(
                label: strings.commitNeedsReviewLabel,
                value: result.needsReview,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _controller.busy ? null : _controller.reset,
                child: Text(strings.doneAction),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _controller.busy ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline),
                label: Text(strings.deleteReceiptAction),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteReceiptConfirmTitle),
        content: Text(strings.deleteReceiptConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.deleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _controller.deleteReceipt();
    if (!mounted) return;
    if (_controller.deletion != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.deleteReceiptSuccessMessage)),
      );
    }
  }

  // --- Error -------------------------------------------------------------

  Widget _buildError(AppLocalizations strings) {
    final theme = Theme.of(context);
    final message = nfceErrorMessage(strings, _controller.error ?? '');
    final canRetry = _controller.input != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(strings.errorLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (canRetry)
              FilledButton.icon(
                onPressed: _controller.retryDraft,
                icon: const Icon(Icons.refresh),
                label: Text(strings.retryAction),
              ),
            if (canRetry) const SizedBox(height: 8),
            TextButton(
              onPressed: _controller.reset,
              child: Text(strings.startOverAction),
            ),
          ],
        ),
      ),
    );
  }

  String _expiryText(AppLocalizations strings, DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return strings.previewExpiredLabel;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final text = minutes > 0
        ? '${minutes}min ${seconds.toString().padLeft(2, '0')}s'
        : '${seconds}s';
    return strings.previewExpiresAtLabel(text);
  }
}

/// A muted informational banner.
class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.strings,
    required this.preview,
    required this.expired,
    required this.expiryText,
  });

  final AppLocalizations strings;
  final PreviewResult preview;
  final bool expired;
  final String expiryText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.previewTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('${strings.previewAccessKeyLabel}: ${preview.accessKey}'),
            const SizedBox(height: 4),
            Text(
              expiryText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: expired
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.strings, required this.totals});

  final AppLocalizations strings;
  final PlanTotals totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.previewTotalsTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _CountRow(
              label: strings.previewItemsCountLabel,
              value: totals.items,
            ),
            _CountRow(
              label: strings.previewAutoSaveLabel,
              value: totals.autoSave,
            ),
            _CountRow(
              label: strings.previewNeedsReviewLabel,
              value: totals.needsReview,
            ),
            _CountRow(
              label: strings.previewParseErrorsLabel,
              value: totals.parseErrors,
            ),
            if (totals.estimatedTotal != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.previewEstimatedTotalLabel,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      totals.estimatedTotal!.amount,
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewItemCard extends StatelessWidget {
  const _PreviewItemCard({
    required this.strings,
    required this.item,
    required this.resolution,
    required this.assignedProduct,
    required this.enabled,
    required this.onResolution,
    required this.onAssign,
    required this.onClearAssignment,
  });

  final AppLocalizations strings;
  final PreviewItem item;
  final Resolution resolution;
  final ProductView? assignedProduct;
  final bool enabled;
  final ValueChanged<ResolutionAction> onResolution;
  final VoidCallback onAssign;
  final VoidCallback onClearAssignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uncertain = item.status == PreviewItemStatus.uidUncertain;
    final title = item.productName ?? item.description;
    final subtitle = item.productName != null ? item.description : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          if (item.message != null) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () => _showApiMessage(context),
                              icon: const Icon(Icons.info_outline, size: 18),
                              tooltip: strings.itemApiMessageTitle,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            label: Text(_statusLabel(strings, item.status)),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (item.brand != null)
                            Text(item.brand!, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      strings.previewPriceLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(_priceLabel(item), style: theme.textTheme.titleSmall),
                  ],
                ),
              ],
            ),
            if (uncertain) ...[
              const SizedBox(height: 8),
              Text(strings.itemUncertainHelp, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text(strings.resolutionNeedsReviewAction),
                    selected: resolution.action == ResolutionAction.needsReview,
                    onSelected: enabled
                        ? (_) => onResolution(ResolutionAction.needsReview)
                        : null,
                  ),
                  ChoiceChip(
                    label: Text(strings.resolutionSkipAction),
                    selected: resolution.action == ResolutionAction.skip,
                    onSelected: enabled
                        ? (_) => onResolution(ResolutionAction.skip)
                        : null,
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.link, size: 18),
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        assignedProduct == null
                            ? strings.resolutionAssignAction
                            : assignedProduct!.name ??
                                  assignedProduct!.gtin ??
                                  '—',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    selected: resolution.action == ResolutionAction.assign,
                    onSelected: enabled ? (_) => onAssign() : null,
                  ),
                  if (assignedProduct != null)
                    TextButton.icon(
                      onPressed: enabled ? onClearAssignment : null,
                      icon: const Icon(Icons.link_off, size: 18),
                      label: Text(strings.clearProductAction),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Shows the unmodified server message for this line on demand.
  Future<void> _showApiMessage(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.itemApiMessageTitle),
        content: Text(item.message ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.closeAction),
          ),
        ],
      ),
    );
  }

  String _priceLabel(PreviewItem item) {
    final price = item.pricePerUnit;
    if (price == null) return '—';
    final unit = item.unit;
    if (unit == null || unit.isEmpty) return price.amount;
    return '${price.amount}/$unit';
  }
}

class _DryRunCard extends StatelessWidget {
  const _DryRunCard({required this.strings, required this.result});

  final AppLocalizations strings;
  final CommitResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.submitDryRunAction, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _CountRow(label: strings.commitWrittenLabel, value: result.written),
            _CountRow(label: strings.commitSkippedLabel, value: result.skipped),
            _CountRow(
              label: strings.commitNeedsReviewLabel,
              value: result.needsReview,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            '${value ?? 0}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(AppLocalizations strings, PreviewItemStatus status) =>
    switch (status) {
      PreviewItemStatus.gtinKnown => strings.itemStatusGtinKnown,
      PreviewItemStatus.gtinNew => strings.itemStatusGtinNew,
      PreviewItemStatus.commodityFingerprint => strings.itemStatusCommodity,
      PreviewItemStatus.uidUncertain => strings.itemStatusUncertain,
      PreviewItemStatus.parseError => strings.itemStatusParseError,
    };
