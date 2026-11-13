import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../l10n/generated/app_localizations.dart';

/// One row in the admin review queue.
///
/// Owns row presentation and the selection affordance only. The parent decides
/// what a selection, approval, or rejection means and owns the requests.
class ReviewQueueItemCard extends StatelessWidget {
  const ReviewQueueItemCard({
    super.key,
    required this.item,
    required this.selected,
    required this.onSelectionChanged,
    this.proposer,
    this.reviewing = false,
    this.onApprove,
    this.onReject,
  });

  final ReviewItem item;
  final bool selected;
  final ValueChanged<bool> onSelectionChanged;

  /// Account resolved from [ReviewItem.resolvedBy], when available.
  final UserView? proposer;

  /// Whether a review decision for this row is in flight.
  final bool reviewing;

  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final id = item.priceLogId;
    final selectable = id != null;
    final title = item.description ?? item.suggestedStem ?? '-';
    final proposal = item.proposedProduct;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: selectable ? () => onSelectionChanged(!selected) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                container: true,
                label: strings.adminSelectItem(title),
                child: Checkbox(
                  value: selected,
                  onChanged: selectable
                      ? (value) => onSelectionChanged(value == true)
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    if (proposal != null)
                      ..._buildProposal(context, strings, proposal)
                    else
                      ..._buildUnresolved(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProposal(
    BuildContext context,
    AppLocalizations strings,
    ReviewProductView proposal,
  ) {
    final theme = Theme.of(context);
    final brand = proposal.brand?.trim();
    final gtin = proposal.gtin?.trim();

    return [
      const SizedBox(height: 4),
      Text(
        '${proposal.name ?? '-'}'
        '${proposal.unit == null ? '' : ' • ${proposal.unit}'}',
        style: theme.textTheme.titleMedium,
      ),
      if (brand != null && brand.isNotEmpty) Text(brand),
      if (gtin != null && gtin.isNotEmpty) Text('GTIN: $gtin'),
      if (item.resolvedBy != null) ...[
        const SizedBox(height: 4),
        Text(
          proposalAuthorLabel(strings, item, proposer),
          style: theme.textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 4),
      Text(
        item.isRejected
            ? strings.adminProposalRejected
            : strings.adminProposalPending,
        style: theme.textTheme.bodySmall?.copyWith(
          color: item.isRejected ? theme.colorScheme.error : null,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: reviewing ? null : onReject,
            child: Text(strings.adminRejectAction),
          ),
          FilledButton(
            onPressed: reviewing ? null : onApprove,
            child: reviewing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(strings.adminApproveAction),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildUnresolved(BuildContext context) {
    return [
      const SizedBox(height: 2),
      Text(
        '${item.storeName ?? ''} • ${item.totalPrice ?? ''}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }
}

/// Attribution line for a proposal, preferring the resolved account name and
/// falling back to the raw user id when the lookup is pending or failed.
String proposalAuthorLabel(
  AppLocalizations strings,
  ReviewItem item,
  UserView? proposer,
) {
  final name = proposer?.name?.trim();
  final email = proposer?.email?.trim();
  if (name != null && name.isNotEmpty) {
    return strings.adminProposalBy(name);
  }
  if (email != null && email.isNotEmpty) {
    return strings.adminProposalBy(email);
  }
  return strings.adminProposalByFallback(item.resolvedBy ?? 0);
}
