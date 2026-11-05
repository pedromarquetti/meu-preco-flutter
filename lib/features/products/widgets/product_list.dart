import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import 'product_result_tile.dart';

/// A reusable list of products that handles common presentation logic,
/// such as stable keys, click forwarding, and optional selection styling.
class ProductList extends StatelessWidget {
  const ProductList({
    super.key,
    required this.products,
    required this.onProductSelected,
    this.controller,
    this.padding,
    this.trailingBuilder,
    this.selectedProductId,
    this.onLoadMore,
    this.isLoadingMore = false,
  });

  final List<ProductView> products;
  final ValueChanged<ProductView> onProductSelected;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final Widget? Function(ProductView product)? trailingBuilder;
  final int? selectedProductId;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      padding: padding ?? EdgeInsets.zero,
      itemCount: products.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) =>
          const SizedBox(height: 8), // Standard spacing between cards
      itemBuilder: (context, index) {
        if (index == products.length && isLoadingMore) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final product = products[index];
        // Stable key logic based on ID or deterministic fallback
        final String uniqueKey = product.id != null
            ? 'prod-${product.id}'
            : 'prod-fallback-${product.name}-${product.brand}';

        return _buildProductItem(context, product, uniqueKey);
      },
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    ProductView product,
    String key,
  ) {
    final isSelected =
        selectedProductId != null && selectedProductId == product.id;

    // Wrap in AnimatedContainer to handle selection styling if needed
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
                  .withValues(alpha: 0.3)
            : null,
        borderRadius: BorderRadius.circular(
          12,
        ), // Matches radiusMedium from theme if not already handled by Card
      ),
      child: ProductResultTile(
        key: ValueKey(key),
        product: product,
        onTap: () => onProductSelected(product),
        trailing: trailingBuilder?.call(product),
      ),
    );
  }
}
