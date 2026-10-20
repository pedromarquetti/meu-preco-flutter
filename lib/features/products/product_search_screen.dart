import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/router.dart';
import '../../core/models/models.dart';
import '../../core/ui/empty_view.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/loading_view.dart';
import '../../l10n/generated/app_localizations.dart';
import 'product_search_controller.dart';
import 'widgets/product_result_tile.dart';

/// Product catalog search with debounce, pagination, and empty/error states.
class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  late final ProductSearchController _controller;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ProductSearchController(
      repository: context.appDependencies.productsRepository,
    );
    _scrollController.addListener(_onScroll);
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

  void _open(ProductView product) {
    final id = product.id;
    if (id == null) return;
    context.push(AppRoutes.productDetailFor('$id'));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.productSearchTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: strings.productSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _controller.setQuery,
            ),
          ),
          Expanded(
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
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: results.length + (controller.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ProductResultTile(
          product: results[index],
          onTap: () => _open(results[index]),
        );
      },
    );
  }
}
