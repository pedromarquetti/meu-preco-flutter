import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/models/models.dart';
import '../../../core/ui/empty_view.dart';
import '../../../core/ui/error_view.dart';
import '../../../core/ui/loading_view.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../products/product_search_controller.dart';
import '../../products/widgets/product_list.dart';

/// Opens a searchable product picker and resolves to the chosen product.
Future<ProductView?> showProductPickerSheet(
  BuildContext context, {
  String initialQuery = '',
}) {
  return showModalBottomSheet<ProductView>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _ProductPickerSheet(initialQuery: initialQuery),
  );
}

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({required this.initialQuery});

  final String initialQuery;

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  late final ProductSearchController _controller;
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ProductSearchController(
      repository: context.appDependencies.productsRepository,
    );
    _searchController = TextEditingController(text: widget.initialQuery);
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    _scrollController.addListener(_onScroll);
    _controller.setQuery(widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = (media.size.height - media.viewInsets.bottom - 24).clamp(
      240.0,
      media.size.height,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    strings.productPickerTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: strings.closeAction,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: strings.productPickerTitle,
                hintText: strings.productSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _controller.setQuery,
            ),
          ),
          Flexible(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _buildResults(strings),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(AppLocalizations strings) {
    final controller = _controller;
    if (controller.isLoading && controller.results.isEmpty) {
      return LoadingView(message: strings.productSearchLoading);
    }
    final error = controller.error;
    if (error != null && controller.results.isEmpty) {
      return ErrorView.fromException(
        error,
        onRetry: controller.retry,
        retryLabel: strings.retryAction,
      );
    }
    if (controller.query.isEmpty) {
      return EmptyView(icon: Icons.search, title: strings.productSearchPrompt);
    }
    if (controller.results.isEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        title: strings.productSearchNoResults,
      );
    }

    final results = controller.results;
    return ProductList(
      products: results,
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      onProductSelected: (product) => Navigator.of(context).pop(product),
      trailingBuilder: (_) => const Icon(Icons.check),
      isLoadingMore: controller.isLoadingMore,
    );
  }
}
