import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/models.dart';
import '../../core/ui/empty_view.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/loading_view.dart';
import '../../l10n/generated/app_localizations.dart';
import 'data/admin_repository.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  late final AdminRepository _repository =
      context.appDependencies.adminRepository;
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<ProductView> _results = const [];
  bool _loading = false;
  String? _error;
  ProductView? _selected;

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _unitController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(value);
    });
  }

  Future<void> _search(String value) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repository.searchProducts(q: value);
      setState(() {
        _results = page.items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
    if (product?.id == null) return;
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
      await _repository.updateProduct(product!.id!, patch);
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: strings.searchProductAction,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        if (_error != null)
          ErrorView(
            message: _error!,
            onRetry: () => _search(_searchController.text),
          ),
        if (_loading && _results.isEmpty) const Expanded(child: LoadingView()),
        if (!_loading && _results.isEmpty && _searchController.text.isNotEmpty)
          const Expanded(child: EmptyView(title: '')),
        Expanded(
          child: ListView.builder(
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
          const Divider(),
          Padding(
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
                  onPressed: _saving
                      ? null
                      : () => {
                          _save().then((_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(strings.productUpdated)),
                              );
                            }
                          }),
                        },
                  child: Text(
                    _saving ? strings.loadingLabel : strings.saveAndContinue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
