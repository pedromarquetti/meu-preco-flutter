import 'package:flutter/material.dart';

import '../../../core/models/models.dart';

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
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        title: Text(
          product.name ?? '—',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: theme.textTheme.titleSmall,
        ),
        subtitle: (product.brand != null && product.brand!.isNotEmpty)
            ? Text(product.brand!)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (product.unit != null && product.unit!.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                product.unit!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
