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
          AdminReviewScreen(),
          AdminProductsScreen(),
        ],
      ),
    );
  }
}
