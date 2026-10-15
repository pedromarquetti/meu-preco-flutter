import 'package:flutter/material.dart';

import '../../core/ui/coming_soon_view.dart';
import '../../l10n/generated/app_localizations.dart';

/// Product detail with price history and graph.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.productDetailTitle)),
      body: ComingSoonView(message: productId),
    );
  }
}
