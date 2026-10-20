import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Compact catalog result row shared by the search screen and product picker.
class ProductResultTile extends StatelessWidget {
  const ProductResultTile({
    super.key,
    required this.product,
    required this.onTap,
    this.trailing,
  });

  final ProductView product;
  final VoidCallback onTap;

  /// Extra affordance shown before the chevron, such as a selection icon.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final details = <String>[
      if (product.brand != null && product.brand!.isNotEmpty) product.brand!,
      if (product.gtin != null && product.gtin!.isNotEmpty)
        '${strings.productGtinLabel}: ${product.gtin}',
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        title: Text(product.name ?? '—', style: theme.textTheme.titleSmall),
        subtitle: details.isEmpty ? null : Text(details.join(' • ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.unit != null && product.unit!.isNotEmpty)
              Chip(
                label: Text(product.unit!),
                visualDensity: VisualDensity.compact,
              ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
