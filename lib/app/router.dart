import 'package:go_router/go_router.dart';

import '../features/admin/admin_screen.dart';
import '../features/auth/auth_session.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
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
  static const String register = '/register';
  static const String home = '/home';
  static const String receiptSubmission = '/receipts/new';
  static const String productSearch = '/products';
  static const String productDetail = '/products/:id';
  static const String supermarkets = '/supermarkets';
  static const String settings = '/settings';
  static const String admin = '/admin';

  /// Location for a concrete product detail page.
  static String productDetailFor(String id) => '/products/$id';

  /// Routes that require the admin role.
  static const Set<String> adminOnly = {admin};
}

/// Builds the app's [GoRouter].
///
/// The router starts on the server configuration screen so a fresh install (or
/// a deployment pointing at an unknown host) always confirms the API origin
/// before showing authenticated screens. [authSession] drives the redirect
/// guards, so reaching a protected route without a valid session is impossible
/// through navigation or a deep link.
GoRouter createRouter({required AuthSession authSession}) {
  return GoRouter(
    initialLocation: AppRoutes.server,
    refreshListenable: authSession,
    redirect: (context, state) =>
        authRedirect(authSession, state.matchedLocation),
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
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
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

/// Resolves where a given [location] should be sent for the current session.
///
/// Returns `null` to allow the navigation, or a redirect target otherwise.
String? authRedirect(AuthSession session, String location) {
  if (location == AppRoutes.server) return null;

  final isAuthRoute =
      location == AppRoutes.login || location == AppRoutes.register;
  final authenticated = session.isAuthenticated;

  if (!authenticated) {
    return isAuthRoute ? null : AppRoutes.login;
  }

  // Signed in: keep users off the login/register pages.
  if (isAuthRoute) return AppRoutes.home;

  final requiresAdmin = AppRoutes.adminOnly.any(
    (route) => location == route || location.startsWith('$route/'),
  );
  if (requiresAdmin && !session.isAdmin) return AppRoutes.home;

  return null;
}
