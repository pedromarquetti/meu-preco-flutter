import 'package:flutter/material.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';

import '../../app/app_scope.dart';
import '../../core/models/models.dart';
import 'widgets/product_search_block.dart';

/// Screen for merging products with side-by-side search blocks.
class MergeProductsScreen extends StatefulWidget {
  const MergeProductsScreen({super.key});

  @override
  State<MergeProductsScreen> createState() => _MergeProductsScreenState();
}

// TODO: the API will accept []int as a 'from' product, when this change is implemented, update this code
class _MergeProductsScreenState extends State<MergeProductsScreen> {
  List<ProductView> _fromProducts = const [];
  ProductView? _toProduct;
  bool _isMerging = false;
  int _searchResetKey = 0;

  bool get canMerge =>
      _fromProducts.isNotEmpty &&
      _toProduct != null &&
      _fromProducts.every((product) => product.id != null) &&
      _toProduct!.id != null &&
      _fromProducts.every((product) => product.id != _toProduct!.id);

  Future<void> _handleMerge() async {
    final strings = AppLocalizations.of(context);
    if (!canMerge) return;
    final sourceIds = _fromProducts
        .map((product) => product.id)
        .whereType<int>();
    final targetId = _toProduct?.id;
    if (sourceIds.length != _fromProducts.length || targetId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.mergeConfirmTitle),
        content: Text(
          strings.mergeConfirmDetail(
            _fromProducts.map((product) => product.name ?? '').join(', '),
            _toProduct!.name ?? '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.confirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isMerging = true);
    try {
      var logsMoved = 0;
      for (final fromId in sourceIds) {
        final result = await context.appDependencies.adminRepository
            .mergeProducts(fromId, targetId);
        logsMoved += result.logsMoved ?? 0;
      }

      if (!mounted) return;
      setState(() {
        _isMerging = false;
        _fromProducts = const [];
        _toProduct = null;
        _searchResetKey++;
      });

      var successMsg = strings.mergeSuccess;
      if (logsMoved > 0) {
        successMsg += ' ($logsMoved ${strings.movedItems})';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isMerging = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.mergeFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final blocks = [
                    Expanded(
                      child: ProductSearchBlock(
                        key: ValueKey('from-$_searchResetKey'),
                        isMerging: _isMerging,
                        allowMultipleSelection: true,
                        title: strings.mergeFrom,
                        onProductSelected: (_) {},
                        onProductsSelected: (products) {
                          setState(() => _fromProducts = products);
                        },
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: ProductSearchBlock(
                        key: ValueKey('to-$_searchResetKey'),
                        isMerging: _isMerging,
                        title: strings.mergeTo,
                        onProductSelected: (product) {
                          setState(() => _toProduct = product);
                        },
                      ),
                    ),
                  ];
                  return constraints.maxWidth > 900
                      ? Row(children: blocks)
                      : Column(children: blocks);
                },
              ),
            ),
            if (_fromProducts.isNotEmpty && _toProduct != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canMerge && !_isMerging ? _handleMerge : null,
                    icon: const Icon(Icons.merge),
                    label: Text(strings.confirmAction),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
