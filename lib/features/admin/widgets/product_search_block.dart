import 'package:flutter/material.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';

import 'package:meu_preco_frontend/app/app_scope.dart';

import '../../../core/ui/empty_view.dart';
import '../../../core/ui/error_messages.dart';
import '../../../core/ui/error_view.dart';
import '../../../features/products/widgets/product_result_tile.dart';
import '../../../features/products/widgets/product_search_input.dart';

import 'package:meu_preco_frontend/features/products/product_search_controller.dart';

/// Search block widget for selecting a product.
/// Now uses the unified ProductSearchInput for the search field logic.
class ProductSearchBlock extends StatefulWidget {
  final bool isMerging;
  final ValueChanged<ProductView?> onProductSelected;
  final String? title;
  final ProductSearchController? controller;

  const ProductSearchBlock({
    super.key,
    this.isMerging = false,
    required this.onProductSelected,
    this.title,
    this.controller,
  });

  @override
  State<ProductSearchBlock> createState() => _ProductSearchBlockState();
}

class _ProductSearchBlockState extends State<ProductSearchBlock> {
  late final ProductSearchController _internalController;
  List<ProductView> _results = const [];
  bool _isLoading = false;
  Object? _error;
  ProductView? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _internalController =
        widget.controller ??
        ProductSearchController(
          repository: context.appDependencies.productsRepository,
        );

    _internalController.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    } else {
      // If controller was provided, we don't own it and shouldn't call dispose on it here?
      // Actually the input widget handles its own disposal if not passed a controller.
      // But since I am listening to it in this state, I should remove listener.
    }
    _internalController.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        _results = _internalController.results;
        _isLoading =
            _internalController.isLoading || _internalController.isLoadingMore;
        _error = _internalController.error;
      });
    }
  }

  void _handleSelection(ProductView product) {
    setState(() => _selectedProduct = product);
    widget.onProductSelected(product);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 600;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.title != null && widget.isMerging) ...[
                  Text(
                    widget.title!,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                ],
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 1,
                        child: ProductSearchInput(
                          controller: _internalController,
                          onResultsChanged: (_) {},
                          onLoadingChanged: (_) {},
                          onErrorChanged: (_) {},
                          hintText: strings.searchProductAction,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildSelectionDisplay(context),
                            if (_selectedProduct != null) ...[
                              Divider(height: 12),
                              Text(
                                strings.selected,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                            Expanded(child: _buildResultsList(context)),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  ProductSearchInput(
                    controller: _internalController,
                    onResultsChanged: (_) {},
                    onLoadingChanged: (_) {},
                    onErrorChanged: (_) {},
                    hintText: strings.searchProductAction,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSelectionDisplay(context),
                        if (_selectedProduct != null) ...[
                          Divider(height: 12),
                          Text(
                            strings.selected,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                        Expanded(child: _buildResultsList(context)),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectionDisplay(BuildContext context) {
    if (_selectedProduct == null || !mounted) return const SizedBox.shrink();
    final strings = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildProductInfo(context)),
            IconButton(
              onPressed: () => setState(() => _selectedProduct = null),
              icon: Icon(Icons.close, size: 20),
              tooltip: strings.adminClearSelection,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    final product = _selectedProduct!;
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name ?? '—',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (product.brand?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            product.brand!,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
        if (product.unit != null && product.unit!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${strings.productUnitLabel}: ${product.unit}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
      ],
    );
  }

  // TODO: refactor this, the list is all broken and will be refactored to a centralized 'product list' widget
  Widget _buildResultsList(BuildContext context) {
    final strings = AppLocalizations.of(context);

    if (_isLoading && _results.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null && _results.isEmpty) {
      return ErrorView(
        error: _error!,
        onRetry: () => setState(() => _internalController.retry()),
      );
    }

    if (_results.isEmpty) {
      return EmptyView(icon: Icons.search, title: strings.productSearchPrompt);
    }

    return ListView.builder(
      key: const Key('product_results_list'),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final product = _results[index];
        return ProductResultTile(
          key: ValueKey(product.id),
          product: product,
          onTap: () => _handleSelection(product),
        );
      },
    );
  }
}
