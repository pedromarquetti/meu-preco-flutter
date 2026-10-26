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
    this.debounce = const Duration(milliseconds: 350),
    this.pageSize = 20,
    this.autofocus = false,
    this.padding,
    this.labelText,
    this.hintText,
  });

  final ValueChanged<List<ProductView>> onResultsChanged;
  final ValueChanged<bool>? onLoadingChanged;
  final ValueChanged<Object?>? onErrorChanged;
  final Duration debounce;
  final int pageSize;
  final bool autofocus;
  final EdgeInsetsGeometry? padding;
  final String? labelText;
  final String? hintText;

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
    _controller = ProductSearchController(
      repository: context.appDependencies.productsRepository,
      debounce: widget.debounce,
      pageSize: widget.pageSize,
    );
    _controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
    _searchController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onControllerChanged() {
    widget.onResultsChanged(_controller.results);
    widget.onLoadingChanged?.call(_controller.isLoading || _controller.isLoadingMore);
    widget.onErrorChanged?.call(_controller.error);
    if (mounted) {
      setState(() {});
    }
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final padding = widget.padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 8);
    final hasFocus = _focusNode.hasFocus;
    final hasText = _searchController.text.isNotEmpty;

    final labelText = widget.labelText ??
        (hasFocus || hasText ? strings.productSearchTitle : strings.productSearchTitle);
    final hintText = widget.hintText ?? strings.productSearchHint;

    return Padding(
      padding: padding,
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        autofocus: widget.autofocus,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
        ),
        onChanged: _controller.setQuery,
      ),
    );
  }
}
