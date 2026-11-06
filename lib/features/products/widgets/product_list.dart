import 'package:flutter/material.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import 'product_result_tile.dart';

/// Renders a reusable catalog result list and forwards clicks to its parent.
///
/// The parent owns search state, pagination, navigation, modal dismissal, and
/// selection meaning. This widget only supplies stable keys, optional
/// selection styling, a loading-more footer, and [ProductResultTile] rows.
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
    final strings = AppLocalizations.of(context);

    return ListView.separated(
      controller: controller,
      padding: padding ?? EdgeInsets.zero,
      itemCount: products.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == products.length && isLoadingMore) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                label: strings.loadingLabel,
                child: const CircularProgressIndicator(),
              ),
            ),
          );
        }

        final product = products[index];
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
                  .withValues(alpha: 0.3)
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
