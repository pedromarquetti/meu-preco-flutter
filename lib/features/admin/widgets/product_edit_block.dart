import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Inline product editor widget for batch assign step 2.
///
/// Shows editable fields for a product with a suggested name from the API.
class ProductEditBlock extends StatefulWidget {
  final ReviewItem? initialProduct;
  final String suggestedName;
  final ValueChanged<ProductPatch?> onSave;
  final bool isMerging;

  const ProductEditBlock({
    super.key,
    this.initialProduct,
    required this.suggestedName,
    required this.onSave,
    this.isMerging = false,
  });

  @override
  State<ProductEditBlock> createState() => _ProductEditBlockState();
}

class _ProductEditBlockState extends State<ProductEditBlock> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _unitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _nameController.text = widget.initialProduct!.suggestedStem ?? '';
      _unitController.text = widget.initialProduct!.unit ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.batchAssignSuggestedName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    onChanged: (_) => widget.onSave(
                      ProductPatch(
                        name: _nameController.text,
                        brand: _brandController.text.isNotEmpty
                            ? _brandController.text
                            : null,
                        unit: _unitController.text,
                      ),
                    ),
                    decoration: InputDecoration(
                      hintText: strings.productSearchHint,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      prefixIcon: const Icon(Icons.edit, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _brandController,
                    onChanged: (_) => widget.onSave(
                      ProductPatch(
                        name: _nameController.text,
                        brand: _brandController.text.isNotEmpty
                            ? _brandController.text
                            : null,
                        unit: _unitController.text,
                      ),
                    ),
                    decoration: InputDecoration(
                      hintText: strings.productBrandLabel,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      prefixIcon: const Icon(Icons.tag, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unitController,
              onChanged: (_) => widget.onSave(
                ProductPatch(
                  name: _nameController.text,
                  brand: _brandController.text.isNotEmpty
                      ? _brandController.text
                      : null,
                  unit: _unitController.text,
                ),
              ),
              decoration: InputDecoration(
                hintText: strings.productUnitLabel,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                prefixIcon: const Icon(Icons.shopping_bag, size: 18),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
