import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Inline editor for a product's name, brand and unit.
///
/// The widget owns its text controllers and emits a draft [ProductPatch] on
/// every field change, so the parent always has the current values without a
/// separate apply step. Explicit draft values ([initialName], [initialBrand],
/// [initialUnit]) take precedence so edits survive rebuilds; missing values
/// fall back to [initialProduct] and then, for the name, to [suggestedName].
class ProductEditBlock extends StatefulWidget {
  const ProductEditBlock({
    super.key,
    this.initialProduct,
    this.suggestedName,
    this.initialName,
    this.initialBrand,
    this.initialUnit,
    required this.onChanged,
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

  /// Called with the current, untrimmed draft values whenever a field changes.
  ///
  /// Consumers should normalize the values (for example, trimming them) when
  /// they build API requests.
  final ValueChanged<ProductPatch> onChanged;

  /// Whether to show the read-only suggested-name row.
  final bool showSuggestedName;

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
    // A non-null draft value (including an intentionally cleared empty string)
    // wins over product/suggestion defaults, so clearing a field is preserved.
    _setTextIfChanged(
      _nameController,
      widget.initialName ??
          _nonEmpty(product?.name) ??
          _nonEmpty(widget.suggestedName) ??
          '',
    );
    _setTextIfChanged(
      _brandController,
      widget.initialBrand ?? _nonEmpty(product?.brand) ?? '',
    );
    _setTextIfChanged(
      _unitController,
      widget.initialUnit ?? _nonEmpty(product?.unit) ?? '',
    );
  }

  /// Avoids rewriting identical text, which would move the caret to the start
  /// while the user is typing and the parent rebuilds with the emitted draft.
  void _setTextIfChanged(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.text = value;
  }

  void _useSuggestion() {
    final suggestion = _nonEmpty(widget.suggestedName);
    if (suggestion == null) return;
    _nameController.text = suggestion;
    _nameController.selection = TextSelection.collapsed(
      offset: suggestion.length,
    );
    _emitPatch();
  }

  void _emitPatch() {
    widget.onChanged(
      ProductPatch(
        name: _nameController.text,
        brand: _brandController.text,
        unit: _unitController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final suggestion = _nonEmpty(widget.suggestedName);

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
          onChanged: (_) => _emitPatch(),
          decoration: InputDecoration(
            labelText: strings.nameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _brandController,
          onChanged: (_) => _emitPatch(),
          decoration: InputDecoration(
            labelText: strings.productBrandLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _unitController,
          onChanged: (_) => _emitPatch(),
          decoration: InputDecoration(
            labelText: strings.productUnitLabel,
            border: const OutlineInputBorder(),
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
