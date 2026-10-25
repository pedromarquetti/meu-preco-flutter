import 'package:flutter/material.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';

import '../../../app/app_scope.dart';
import '../../../core/models/models.dart';
import '../../../features/products/product_search_controller.dart';
import '../../../features/products/widgets/product_result_tile.dart';

/// Search block widget for selecting a product.
///
/// Supports two modes:
/// - Normal mode: single search block for general selection
/// - Merging mode: two side-by-side blocks (left = source, right = target)
class ProductSearchBlock extends StatefulWidget {
  final bool isMerging;
  final ValueChanged<ProductView?> onProductSelected;

  const ProductSearchBlock({
    super.key,
    required this.isMerging,
    required this.onProductSelected,
  });

  @override
  State<ProductSearchBlock> createState() => _ProductSearchBlockState();
}

class _ProductSearchBlockState extends State<ProductSearchBlock> {
  late final ProductSearchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProductSearchController(
      repository: context.appDependencies.productsRepository,
      pageSize: 20,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return widget.isMerging
        ? Row(
            children: [
              Expanded(
                child: _SingleSearchBlock(
                  controller: _controller,
                  title: strings.mergeFrom,
                  onProductSelected: (product) =>
                      widget.onProductSelected(product),
                ),
              ),
              Expanded(
                child: _SingleSearchBlock(
                  controller: _controller,
                  title: strings.mergeTo,
                  onProductSelected: (product) =>
                      widget.onProductSelected(product),
                ),
              ),
            ],
          )
        : _SingleSearchBlock(
            controller: _controller,
            title: strings.searchProductAction,
            onProductSelected: (product) => widget.onProductSelected(product),
          );
  }
}

class _SingleSearchBlock extends StatelessWidget {
  final ProductSearchController controller;
  final String title;
  final ValueChanged<ProductView?> onProductSelected;

  const _SingleSearchBlock({
    required this.controller,
    required this.title,
    required this.onProductSelected,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.mergeFrom,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (controller.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: controller.query),
              onChanged: controller.setQuery,
              decoration: InputDecoration(
                hintText: strings.productSearchHint,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 300, child: _buildResultsList(context)),
            if (controller.canLoadMore)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: () => controller.loadMore(),
                  icon: const Icon(Icons.add),
                  label: Text(strings.loadMoreAction),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (controller.isLoading) {
      return const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (controller.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Error: ${controller.error?.message}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (controller.results.isEmpty) {
      return Center(
        child: Text(
          strings.productSearchNoResults,
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.builder(
      itemCount: controller.results.length,
      itemBuilder: (context, index) {
        final product = controller.results[index];
        return ProductResultTile(
          product: product,
          onTap: () => onProductSelected(product),
        );
      },
    );
  }
}
