import 'package:go_router/go_router.dart';

import '../features/admin/admin_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/nfce/receipt_submission_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/products/product_search_screen.dart';
import '../features/server/server_config_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/supermarkets/supermarkets_screen.dart';

/// Named route locations for the whole app.
abstract final class AppRoutes {
  static const String server = '/server';
  static const String login = '/login';
  static const String home = '/home';
  static const String receiptSubmission = '/receipts/new';
  static const String productSearch = '/products';
  static const String productDetail = '/products/:id';
  static const String supermarkets = '/supermarkets';
  static const String settings = '/settings';
  static const String admin = '/admin';

  /// Location for a concrete product detail page.
  static String productDetailFor(String id) => '/products/$id';
}

/// Builds the app's [GoRouter].
///
/// The router starts on the server configuration screen so a fresh install (or
/// a deployment pointing at an unknown host) always confirms the API origin
/// before showing authenticated screens.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.server,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.server,
        name: 'server',
        builder: (context, state) => const ServerConfigScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.receiptSubmission,
        name: 'receiptSubmission',
        builder: (context, state) => const ReceiptSubmissionScreen(),
      ),
      GoRoute(
        path: AppRoutes.productSearch,
        name: 'productSearch',
        builder: (context, state) => const ProductSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        name: 'productDetail',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.supermarkets,
        name: 'supermarkets',
        builder: (context, state) => const SupermarketsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        builder: (context, state) => const AdminScreen(),
      ),
    ],
  );
}
