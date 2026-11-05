import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/models/models.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../product_search_controller.dart';

/// Reusable product search input that manages its own controller
/// and exposes search results to the parent widget.
class ProductSearchInput extends StatefulWidget {
  const ProductSearchInput({
    super.key,
    required this.onResultsChanged,
    this.onLoadingChanged,
    this.onErrorChanged,
    this.onQueryChanged,
    this.debounce = const Duration(milliseconds: 350),
    this.pageSize = 20,
    this.autofocus = false,
    this.padding,
    this.labelText,
    this.hintText,
    this.controller, // Added optional controller to allow sharing search logic with parent widgets.
  });

  final ValueChanged<List<ProductView>> onResultsChanged;
  final ValueChanged<bool>? onLoadingChanged;
  final ValueChanged<Object?>? onErrorChanged;
  final ValueChanged<String>? onQueryChanged;
  final Duration debounce;
  final int pageSize;
  final bool autofocus;
  final EdgeInsetsGeometry? padding;
  final String? labelText;
  final String? hintText;
  final ProductSearchController? controller;

  @override
  State<ProductSearchInput> createState() => _ProductSearchInputState();
}

class _ProductSearchInputState extends State<ProductSearchInput> {
  late final ProductSearchController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        ProductSearchController(
          repository: context.appDependencies.productsRepository,
          debounce: widget.debounce,
          pageSize: widget.pageSize,
        );
    _controller.addListener(_onControllerChanged);

    _focusNode.addListener(_onFocusChanged);
    _searchController.addListener(_onTextChanged);

    if (widget.autofocus) {
      Future.delayed(Duration.zero, () => _focusNode.requestFocus());
    }
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // Handle focus changes if needed, currently no-op.
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
      widget.onResultsChanged(_controller.results);
      widget.onLoadingChanged?.call(
        _controller.isLoading || _controller.isLoadingMore,
      );
      widget.onErrorChanged?.call(_controller.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: widget.labelText ?? strings.productSearchTitle,
              hintText: widget.hintText ?? strings.productSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              _controller.setQuery(value);
              widget.onQueryChanged?.call(value);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
