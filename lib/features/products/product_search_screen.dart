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
import 'widgets/product_search_input.dart';
import 'widgets/product_list.dart';

/// Product catalog search with debounce, pagination, and empty/error states.
class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key, this.controller});

  final ProductSearchController? controller;

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  late final ProductSearchController _controller;
  final ScrollController _scrollController = ScrollController();
  List<ProductView> _results = const [];
  bool _isLoading = false;
  Object? _error;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        ProductSearchController(
          repository: context.appDependencies.productsRepository,
        );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
  }

  void _retrySearch() {
    _controller.retry();
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
          ProductSearchInput(
            controller: _controller,
            onResultsChanged: (results) {
              setState(() {
                _results = results;
                if (!_isLoading && _hasSearched == false) {
                  _hasSearched = true;
                }
              });
            },
            onLoadingChanged: (loading) => setState(() => _isLoading = loading),
            onErrorChanged: (error) {
              setState(() {
                _error = error;
                if (_hasSearched == false) _hasSearched = true;
              });
            },
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          ),
          Expanded(child: _buildResults(strings)),
        ],
      ),
    );
  }

  Widget _buildResults(AppLocalizations strings) {
    if (_isLoading && _results.isEmpty) {
      return LoadingView(message: strings.productSearchLoading);
    }
    final error = _error;
    if (error != null && _results.isEmpty) {
      return ErrorView.fromException(
        error as Exception,
        retryLabel: strings.retryAction,
        onRetry: _retrySearch,
      );
    }
    if (_results.isEmpty && !_isLoading) {
      return EmptyView(
        icon: _hasSearched ? Icons.search_off : Icons.search,
        title: _hasSearched
            ? strings.productSearchNoResults
            : strings.productSearchPrompt,
      );
    }
    if (_results.isEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        title: strings.productSearchNoResults,
      );
    }

    final results = _results;
    return ProductList(
      products: results,
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      onProductSelected: _open,
    );
  }
}
