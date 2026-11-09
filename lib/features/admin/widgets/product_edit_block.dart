import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Inline, explicitly-saved editor for a product's name, brand and unit.
///
/// The widget owns its text controllers and only emits a normalized
/// [ProductPatch] when the user presses the apply action. Explicit draft values
/// ([initialName], [initialBrand], [initialUnit]) take precedence so edits
/// survive rebuilds; missing values fall back to [initialProduct] and then, for
/// the name, to [suggestedName].
class ProductEditBlock extends StatefulWidget {
  const ProductEditBlock({
    super.key,
    this.initialProduct,
    this.suggestedName,
    this.initialName,
    this.initialBrand,
    this.initialUnit,
    required this.onSave,
    this.showSuggestedName = true,
  });

  /// Existing product being edited, when one has been selected.
  final ProductView? initialProduct;

  /// Suggested name supplied by the review item/API.
  ///
  /// It is shown read-only when [showSuggestedName] is true and acts as the
  /// name fallback when neither the product nor [initialName] provides one.
  final String? suggestedName;

  /// Current draft values to preserve when the widget is rebuilt or recreated.
  final String? initialName;
  final String? initialBrand;
  final String? initialUnit;

  /// Called once, with a trimmed patch, when the user explicitly applies edits.
  final ValueChanged<ProductPatch> onSave;

  /// Whether to show the read-only suggested-name row.
  final bool showSuggestedName;

  @override
  State<ProductEditBlock> createState() => _ProductEditBlockState();
}

class _ProductEditBlockState extends State<ProductEditBlock> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _unitController = TextEditingController();
  bool _showEmptyError = false;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant ProductEditBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameProduct(oldWidget.initialProduct, widget.initialProduct) ||
        oldWidget.suggestedName != widget.suggestedName ||
        oldWidget.initialName != widget.initialName ||
        oldWidget.initialBrand != widget.initialBrand ||
        oldWidget.initialUnit != widget.initialUnit) {
      _syncControllers();
      _showEmptyError = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final product = widget.initialProduct;
    _nameController.text =
        _nonEmpty(widget.initialName) ??
        _nonEmpty(product?.name) ??
        _nonEmpty(widget.suggestedName) ??
        '';
    _brandController.text =
        _nonEmpty(widget.initialBrand) ?? _nonEmpty(product?.brand) ?? '';
    _unitController.text =
        _nonEmpty(widget.initialUnit) ?? _nonEmpty(product?.unit) ?? '';
  }

  void _useSuggestion() {
    final suggestion = _nonEmpty(widget.suggestedName);
    if (suggestion == null) return;
    _nameController.text = suggestion;
    _nameController.selection = TextSelection.collapsed(
      offset: suggestion.length,
    );
    if (_showEmptyError) {
      setState(() => _showEmptyError = false);
    }
  }

  void _apply() {
    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final unit = _unitController.text.trim();

    if (name.isEmpty && brand.isEmpty && unit.isEmpty) {
      setState(() => _showEmptyError = true);
      return;
    }

    _nameController.text = name;
    _brandController.text = brand;
    _unitController.text = unit;
    setState(() => _showEmptyError = false);
    widget.onSave(
      ProductPatch(
        name: name.isEmpty ? null : name,
        brand: brand.isEmpty ? null : brand,
        unit: unit.isEmpty ? null : unit,
      ),
    );
  }

  void _clearErrorOnEdit() {
    if (_showEmptyError) {
      setState(() => _showEmptyError = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final suggestion = _nonEmpty(widget.suggestedName);
    final messenger = ScaffoldMessenger.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showSuggestedName && suggestion != null) ...[
          Text(
            '${strings.batchAssignSuggestedName}: $suggestion',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _useSuggestion,
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: Text(strings.useSuggestionAction),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _nameController,
          onChanged: (_) => _clearErrorOnEdit(),
          decoration: InputDecoration(
            labelText: strings.nameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _brandController,
          onChanged: (_) => _clearErrorOnEdit(),
          decoration: InputDecoration(
            labelText: strings.productBrandLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _unitController,
          onChanged: (_) => _clearErrorOnEdit(),
          decoration: InputDecoration(
            labelText: strings.productUnitLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_showEmptyError) ...[
          const SizedBox(height: 8),
          Text(
            strings.productPatchEmptyError,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton.icon(
            onPressed: () => {
              _apply(),
              messenger.showSnackBar(SnackBar(content: Text(strings.success))),
            },
            icon: const Icon(Icons.check),
            label: Text(strings.applyAction),
          ),
        ),
      ],
    );
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

bool _sameProduct(ProductView? a, ProductView? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return a.id == b.id &&
      a.name == b.name &&
      a.brand == b.brand &&
      a.unit == b.unit;
}
