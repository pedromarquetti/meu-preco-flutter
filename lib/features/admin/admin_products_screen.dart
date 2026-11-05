import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/models.dart';
import '../../core/ui/empty_view.dart';
import '../../core/ui/error_messages.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/loading_view.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../features/products/widgets/product_search_input.dart';
import 'data/admin_repository.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  late final AdminRepository _repository =
      context.appDependencies.adminRepository;
  List<ProductView> _results = const [];
  bool _loading = false;
  Object? _error;
  ProductView? _selected;
  final String _lastQuery = '';

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _unitController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _select(ProductView product) {
    setState(() {
      _selected = product;
      _nameController.text = product.name ?? '';
      _brandController.text = product.brand ?? '';
      _unitController.text = product.unit ?? '';
    });
  }

  Future<void> _save() async {
    final product = _selected;
    if (product == null || product.id == null) return;
    final productId = product.id!;
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final patch = ProductPatch(
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        unit: _unitController.text.trim().isEmpty
            ? null
            : _unitController.text.trim(),
      );
      await _repository.updateProduct(productId, patch);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(strings.productUpdated)));
      if (_lastQuery.isNotEmpty) {
        // Re-trigger search by updating state - the unified input manages its own
        // search, but we need to refresh results. For simplicity, just keep results.
        // The user can retype to refresh if needed.
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(localizedErrorMessage(strings, e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      children: [
        ProductSearchInput(
          onResultsChanged: (results) => setState(() => _results = results),
          onLoadingChanged: (loading) => setState(() => _loading = loading),
          onErrorChanged: (error) => setState(() => _error = error),
          padding: const EdgeInsets.all(16),
          labelText: strings.searchProductAction,
        ),
        if (_error != null)
          ErrorView(
            error: _error,
            onRetry: () {
              // The unified input manages its own search; retry is handled internally
              setState(() => _error = null);
            },
          ),
        Expanded(
          child: _results.isEmpty
              ? (_loading
                    ? const LoadingView()
                    : _lastQuery.isEmpty
                    ? const SizedBox.shrink()
                    : EmptyView(title: strings.emptyLabel))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final product = _results[index];
                    final isSelected = _selected?.id == product.id;
                    return ListTile(
                      selected: isSelected,
                      title: Text(product.name ?? '-'),
                      subtitle: Text(
                        '${product.brand ?? ''} • ${product.unit ?? ''}'.trim(),
                      ),
                      onTap: () => _select(product),
                    );
                  },
                ),
        ),
        if (_selected != null) ...[
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: strings.nameLabel),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _brandController,
                    decoration: InputDecoration(
                      labelText: strings.productBrandLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _unitController,
                    decoration: InputDecoration(
                      labelText: strings.productUnitLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving ? strings.loadingLabel : strings.saveAndContinue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
