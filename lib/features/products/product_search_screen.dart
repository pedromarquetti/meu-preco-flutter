import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/models/models.dart';
import '../../core/ui/empty_view.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/loading_view.dart';
import '../../l10n/generated/app_localizations.dart';
import 'widgets/product_search_input.dart';
import 'widgets/product_result_tile.dart';

/// Product catalog search with debounce, pagination, and empty/error states.
class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final ScrollController _scrollController = ScrollController();
  List<ProductView> _results = const [];
  bool _isLoading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
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
            onResultsChanged: (results) => setState(() => _results = results),
            onLoadingChanged: (loading) => setState(() => _isLoading = loading),
            onErrorChanged: (error) => setState(() => _error = error),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          ),
          Expanded(
            child: _buildResults(strings),
          ),
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
      );
    }
    if (_results.isEmpty && !_isLoading) {
      return EmptyView(icon: Icons.search, title: strings.productSearchPrompt);
    }
    if (_results.isEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        title: strings.productSearchNoResults,
      );
    }

    final results = _results;
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return ProductResultTile(
          product: results[index],
          onTap: () => _open(results[index]),
        );
      },
    );
  }
}
