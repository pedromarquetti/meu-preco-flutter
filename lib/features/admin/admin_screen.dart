import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'admin_products_screen.dart';
import 'admin_review_screen.dart';
import 'admin_users_screen.dart';

/// Admin workflows with tab navigation.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.adminTitle),
        bottom: TabBar(
          controller: _controller,
          tabAlignment: TabAlignment.center,
          isScrollable: true,
          tabs: [
            Tab(text: strings.adminUsers),
            Tab(text: strings.adminReviewQueue),
            Tab(text: strings.productSearchTitle),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: const [
          AdminUsersScreen(),
          // BUG: The review queue needs to be refactored:
          // 1. "batch assign" button shouldnt simply create products, the admin must be able to actually resolve the issue by either: merging products or editing product info on the spot
          // TODO:
          // 1. Create a Nerge Products tab -> UI should show [ ITEM 1 Block ] -> [ ITEM 2 Block]  (each block allows the user to search for products to merge - reuse the already existing product search code if possible).
          // 2. Refactor adminReviewQueue tab: make multi step batch assign: user selects products > UI below the product prompts the user to edit the product details with API suggested name > If products have the same name, the api merges them into one >  user is able to click a 'Assign' button at the bottom that actually submits to the batch-asign API endpoint
          AdminReviewScreen(),
          AdminProductsScreen(),
        ],
      ),
    );
  }
}
