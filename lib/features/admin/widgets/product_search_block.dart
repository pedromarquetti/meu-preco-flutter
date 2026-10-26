import 'package:flutter/material.dart';
import 'package:meu_preco_frontend/core/ui/empty_view.dart';
import 'package:meu_preco_frontend/core/ui/error_view.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';

import '../../../core/models/models.dart';
import '../../../features/products/widgets/product_search_input.dart';
import '../../../features/products/widgets/product_result_tile.dart';

/// Search block widget for selecting a product.
/// Now uses the unified ProductSearchInput for the search field logic.
class ProductSearchBlock extends StatefulWidget {
  final bool isMerging;
  final ValueChanged<ProductView?> onProductSelected;
  final String? title;

  const ProductSearchBlock({
    super.key,
    this.isMerging = false,
    required this.onProductSelected,
    this.title,
  });

  @override
  State<ProductSearchBlock> createState() => _ProductSearchBlockState();
}

class _ProductSearchBlockState extends State<ProductSearchBlock> {
  List<ProductView> _results = const [];
  bool _isLoading = false;
  Object? _error;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final blockTitle =
        widget.title ??
        (widget.isMerging ? strings.mergeFrom : strings.searchProductAction);

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
                    blockTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ProductSearchInput(
              onResultsChanged: (results) => setState(() => _results = results),
              onLoadingChanged: (loading) =>
                  setState(() => _isLoading = loading),
              onErrorChanged: (error) => setState(() => _error = error),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            SizedBox(height: 300, child: _buildResultsList(context)),
          ],
        ),
      ),
    );
  }

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
        error: _error,
        onRetry: () {
          // The unified input manages its own search; retry is handled internally
          setState(() => _error = null);
        },
      );
    }

    if (_results.isEmpty) {
      return EmptyView(icon: Icons.search, title: strings.productSearchPrompt);
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final product = _results[index];
        return ProductResultTile(
          product: product,
          onTap: () => widget.onProductSelected(product),
        );
      },
    );
  }
}
