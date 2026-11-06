import 'package:flutter/material.dart';

import '../../../core/models/models.dart';

/// Compact catalog result row shared by every product-result surface.
///
/// Owns row presentation only. The parent decides what a tap means through the
/// [onTap] callback and may supply an extra trailing affordance.
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

    // Create a semantic label that combines name and unit for accessibility.
    final String productName = product.name ?? '—';
    final String productUnit =
        (product.unit != null && product.unit!.isNotEmpty)
        ? '- ${product.unit}'
        : '';
    final String semanticLabel = '$productName $productUnit'.trim();

    return Semantics(
      label: semanticLabel,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName, style: theme.textTheme.titleSmall),
                      if (product.brand != null &&
                          product.brand!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.brand!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (product.unit != null && product.unit!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    product.unit!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
