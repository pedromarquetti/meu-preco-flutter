import 'package:flutter/material.dart';

import '../../core/ui/coming_soon_view.dart';
import '../../l10n/generated/app_localizations.dart';

/// Product search.
class ProductSearchScreen extends StatelessWidget {
  const ProductSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.productSearchTitle)),
      body: const ComingSoonView(),
    );
  }
}
