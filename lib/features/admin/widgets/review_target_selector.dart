import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../products/product_search_controller.dart';
import '../review_decision.dart';
import 'product_edit_block.dart';
import 'product_search_block.dart';

/// Lets the admin choose what a review row should point at.
///
/// The widget renders the current [ReviewDecision] and forwards target changes
/// to the parent. It never calls a repository directly; the existing-product
/// picker receives the same search source the parent uses.
class ReviewTargetSelector extends StatelessWidget {
  const ReviewTargetSelector({
    super.key,
    required this.item,
    required this.decision,
    required this.onTargetChanged,
    required this.searchSource,
  });

  final ReviewItem item;
  final ReviewDecision decision;
  final ValueChanged<ReviewDecision> onTargetChanged;
  final ProductSearchSource searchSource;

  String? get _suggestedName =>
      _nonEmpty(item.suggestedStem) ?? _nonEmpty(item.description);

  Future<void> _pickExisting(BuildContext context) async {
    final product = await showReviewProductPicker(
      context: context,
      source: searchSource,
    );
    if (product == null || !context.mounted) return;
    onTargetChanged(decision.useExisting(product));
  }

  void _selectTarget(ReviewTargetKind target) {
    switch (target) {
      case ReviewTargetKind.proposed:
        onTargetChanged(decision.useProposal());
      case ReviewTargetKind.create:
        onTargetChanged(decision.createNew());
      case ReviewTargetKind.existing:
        // The picker decides the actual product before the target changes.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final logId = decision.priceLogId ?? item.priceLogId;
    final proposal = decision.proposal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RadioGroup<ReviewTargetKind>(
          groupValue: decision.target,
          onChanged: (target) {
            if (target == null) return;
            if (target == ReviewTargetKind.existing) {
              _pickExisting(context);
            } else {
              _selectTarget(target);
            }
          },
          child: Column(
            children: [
              if (proposal != null)
                RadioListTile<ReviewTargetKind>(
                  key: ValueKey('review-target-proposed-$logId'),
                  value: ReviewTargetKind.proposed,
                  title: Text(strings.adminTargetProposed),
                  subtitle: Text(strings.adminTargetProposedHint),
                ),
              RadioListTile<ReviewTargetKind>(
                key: ValueKey('review-target-create-$logId'),
                value: ReviewTargetKind.create,
                title: Text(strings.adminTargetCreate),
                subtitle: Text(strings.adminTargetCreateHint),
              ),
              RadioListTile<ReviewTargetKind>(
                key: ValueKey('review-target-existing-$logId'),
                value: ReviewTargetKind.existing,
                title: Text(strings.adminTargetExisting),
                subtitle: Text(strings.adminTargetExistingHint),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        switch (decision.target) {
          ReviewTargetKind.proposed => _ProposalSummary(proposal: proposal),
          ReviewTargetKind.existing => _ExistingSummary(
            product: decision.targetProduct,
            onChange: () => _pickExisting(context),
          ),
          ReviewTargetKind.create => _CreateDraft(
            decision: decision,
            suggestedName: _suggestedName,
            onChanged: onTargetChanged,
          ),
        },
      ],
    );
  }
}

/// Opens the admin product picker in a bounded modal sheet.
///
/// [ProductSearchBlock] uses `Expanded` internally, so the sheet constrains its
/// height instead of nesting an unbounded column inside the review list.
Future<ProductView?> showReviewProductPicker({
  required BuildContext context,
  required ProductSearchSource source,
}) {
  return showModalBottomSheet<ProductView>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final strings = AppLocalizations.of(sheetContext);
      return SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.adminSelectExistingProduct,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(sheetContext)
                        .closeButtonTooltip,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ProductSearchBlock(
                key: const ValueKey('review-product-picker'),
                source: source,
                showCanonicalStem: true,
                onProductSelected: (product) {
                  if (product == null) return;
                  Navigator.of(sheetContext).pop(product);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ProposalSummary extends StatelessWidget {
  const _ProposalSummary({required this.proposal});

  final ReviewProductView? proposal;

  @override
  Widget build(BuildContext context) {
    final proposal = this.proposal;
    if (proposal == null) return const SizedBox.shrink();

    return _ProductSummary(
      name: proposal.name,
      brand: proposal.brand,
      unit: proposal.unit,
      canonicalStem: proposal.canonicalStem,
    );
  }
}

class _ExistingSummary extends StatelessWidget {
  const _ExistingSummary({required this.product, required this.onChange});

  final ProductView? product;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final product = this.product;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (product != null)
          _ProductSummary(
            name: product.name,
            brand: product.brand,
            unit: product.unit,
            canonicalStem: product.canonicalStem,
          ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: onChange,
            icon: const Icon(Icons.search),
            label: Text(
              product == null
                  ? strings.adminSelectExistingProduct
                  : strings.adminChangeProduct,
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateDraft extends StatelessWidget {
  const _CreateDraft({
    required this.decision,
    required this.suggestedName,
    required this.onChanged,
  });

  final ReviewDecision decision;
  final String? suggestedName;
  final ValueChanged<ReviewDecision> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.adminCreateProductTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ProductEditBlock(
          key: ValueKey('review-create-editor-${decision.priceLogId}'),
          suggestedName: suggestedName,
          initialName: decision.name,
          initialBrand: decision.brand,
          initialUnit: decision.unit,
          onChanged: (patch) => onChanged(
            decision.copyWith(
              name: patch.name,
              brand: patch.brand,
              unit: patch.unit,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({this.name, this.brand, this.unit, this.canonicalStem});

  final String? name;
  final String? brand;
  final String? unit;
  final String? canonicalStem;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = _nonEmpty(this.name);
    final brand = _nonEmpty(this.brand);
    final unit = _nonEmpty(this.unit);
    final stem = _nonEmpty(canonicalStem);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name ?? '—', style: theme.textTheme.titleMedium),
        if (brand != null) ...[
          const SizedBox(height: 4),
          Text(brand, style: theme.textTheme.bodyMedium),
        ],
        if (unit != null) ...[
          const SizedBox(height: 4),
          Text(
            '${strings.productUnitLabel}: $unit',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (stem != null && _identityMismatch(name, stem)) ...[
          const SizedBox(height: 8),
          _IdentityWarning(stem: stem),
        ],
      ],
    );
  }
}

class _IdentityWarning extends StatelessWidget {
  const _IdentityWarning({required this.stem});

  final String stem;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label:
          '${strings.adminIdentityMismatch(stem)}. '
          '${strings.adminIdentityMismatchHint}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.adminIdentityMismatch(stem),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.adminIdentityMismatchHint,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onErrorContainer),
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

bool _identityMismatch(String? name, String? stem) {
  if (name == null || stem == null) return false;
  return name.trim().toLowerCase() != stem.trim().toLowerCase();
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
