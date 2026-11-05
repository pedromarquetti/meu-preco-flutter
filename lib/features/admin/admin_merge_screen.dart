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

// TODO: Todos here:
// 1 'From' must allow more than 1 item to be merged into the 'To' product
// 2. On merge -> list of selected items should be cleared
class _MergeProductsScreenState extends State<MergeProductsScreen> {
  ProductView? _fromProduct;
  ProductView? _toProduct;

  void _handleMerge() {
    final strings = AppLocalizations.of(context);
    if (_fromProduct == null ||
        _toProduct == null ||
        _fromProduct!.id == null ||
        _toProduct!.id == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.confirmAction),
        content: Text(strings.deleteReceiptConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              final fromId = _fromProduct!.id!;
              final toId = _toProduct!.id!;
              context.appDependencies.adminRepository
                  .mergeProducts(fromId, toId)
                  .then((result) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            (result.dupRemoved ?? false)
                                ? strings.doneAction
                                : strings.errorLabel,
                          ),
                          backgroundColor: (result.dupRemoved ?? false)
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                      setState(() {
                        _fromProduct = null;
                        _toProduct = null;
                      });
                    }
                  });
            },
            child: Text(strings.confirmAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ProductSearchBlock(
                      isMerging: true,
                      title: strings.mergeFrom,
                      onProductSelected: (product) {
                        setState(() {
                          _fromProduct = product;
                        });
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: ProductSearchBlock(
                      isMerging: true,
                      title: strings.mergeTo,
                      onProductSelected: (product) {
                        setState(() {
                          _toProduct = product;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_fromProduct != null && _toProduct != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _handleMerge,
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
