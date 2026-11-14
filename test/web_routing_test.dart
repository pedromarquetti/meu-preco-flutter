import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_preco_frontend/app/router.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/auth/auth_session.dart';
import 'package:meu_preco_frontend/features/nfce/nfce_entry_mode.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthSession session;
  late GoRouter router;

  setUp(() async {
    final repository = FakeAuthRepository(
      user: const User(
        id: 1,
        name: 'Ada',
        email: 'ada@example.com',
        role: UserRole.user,
      ),
    );
    session = AuthSession(
      repository: repository,
      credentialStore: InMemoryCredentialStore(),
    );
    await session.restore();
    await session.login(identifier: 'ada@example.com', password: 'secret123');
    router = createRouter(authSession: session);
  });

  tearDown(() => router.dispose());

  RouteMatchList match(String location) =>
      router.configuration.findMatch(Uri.parse(location));

  group('project Pages boot', () {
    test('an unconfigured or unreachable server opens server selection', () {
      expect(
        bootLocation(
          serverConfigured: false,
          serverUnreachable: false,
          authenticated: false,
        ),
        AppRoutes.server,
      );
      expect(
        bootLocation(
          serverConfigured: true,
          serverUnreachable: true,
          authenticated: true,
        ),
        AppRoutes.server,
      );
    });

    test(
      'a configured server opens login or home from the repository root',
      () {
        expect(
          bootLocation(
            serverConfigured: true,
            serverUnreachable: false,
            authenticated: false,
          ),
          AppRoutes.login,
        );
        expect(
          bootLocation(
            serverConfigured: true,
            serverUnreachable: false,
            authenticated: true,
          ),
          AppRoutes.home,
        );
      },
    );

    test('route constants stay app-relative for base-href hosting', () {
      const locations = <String>[
        AppRoutes.root,
        AppRoutes.server,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.home,
        AppRoutes.receiptSubmission,
        AppRoutes.receiptScanner,
        AppRoutes.productSearch,
        AppRoutes.supermarkets,
        AppRoutes.settings,
        AppRoutes.admin,
      ];

      for (final location in locations) {
        final uri = Uri.parse(location);
        expect(location, startsWith('/'));
        expect(uri.hasScheme, isFalse, reason: location);
        expect(uri.hasAuthority, isFalse, reason: location);
      }
    });
  });

  group('deep links', () {
    test('every non-parameterized route matches', () {
      const locations = <String>[
        AppRoutes.server,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.home,
        AppRoutes.receiptScanner,
        AppRoutes.productSearch,
        AppRoutes.supermarkets,
        AppRoutes.settings,
        AppRoutes.admin,
      ];

      for (final location in locations) {
        final result = match(location);
        expect(result.isError, isFalse, reason: location);
        expect(result.uri.path, location, reason: location);
      }
    });

    test('a nested product route exposes its path parameter', () {
      final result = match(AppRoutes.productDetailFor('42'));

      expect(result.isError, isFalse);
      expect(result.last.route.name, 'productDetail');
      expect(result.pathParameters['id'], '42');
    });

    test('the receipt route keeps its entry-mode query parameter', () {
      final result = match(AppRoutes.receiptSubmissionFor(NfceEntryMode.key));

      expect(result.isError, isFalse);
      expect(result.last.route.name, 'receiptSubmission');
      expect(result.uri.queryParameters['mode'], NfceEntryMode.key.name);
    });

    test('unknown locations resolve to the router error screen', () {
      final result = match('/missing/route');

      expect(result.isError, isTrue);
    });
  });
}
