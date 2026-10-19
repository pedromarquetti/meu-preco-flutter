import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/router.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/auth/auth_session.dart';

import 'fakes.dart';

void main() {
  Future<AuthSession> sessionFor({UserRole? role, Object? refreshError}) async {
    final repository = FakeAuthRepository(
      user: role == null
          ? null
          : User(id: 1, email: 'ada@example.com', role: role),
    );
    final session = AuthSession(
      repository: repository,
      credentialStore: InMemoryCredentialStore(),
    );
    await session.restore();
    if (role != null) {
      await session.login(email: 'ada@example.com', password: 'secret123');
      if (refreshError != null) {
        repository.refreshError = refreshError;
        await session.refreshAccessToken();
      }
    }
    return session;
  }

  group('unauthenticated', () {
    test('protected routes go to login', () async {
      final session = await sessionFor();

      expect(authRedirect(session, AppRoutes.home), AppRoutes.login);
      expect(
        authRedirect(session, AppRoutes.receiptSubmission),
        AppRoutes.login,
      );
      expect(authRedirect(session, AppRoutes.productSearch), AppRoutes.login);
      expect(authRedirect(session, AppRoutes.settings), AppRoutes.login);
      expect(authRedirect(session, AppRoutes.admin), AppRoutes.login);
    });

    test('auth routes and the server screen are allowed', () async {
      final session = await sessionFor();

      expect(authRedirect(session, AppRoutes.login), isNull);
      expect(authRedirect(session, AppRoutes.register), isNull);
      expect(authRedirect(session, AppRoutes.server), isNull);
    });
  });

  group('authenticated user', () {
    test('protected routes are allowed', () async {
      final session = await sessionFor(role: UserRole.user);

      expect(authRedirect(session, AppRoutes.home), isNull);
      expect(authRedirect(session, AppRoutes.settings), isNull);
    });

    test('auth routes redirect home', () async {
      final session = await sessionFor(role: UserRole.user);

      expect(authRedirect(session, AppRoutes.login), AppRoutes.home);
      expect(authRedirect(session, AppRoutes.register), AppRoutes.home);
    });

    test('admin routes are blocked', () async {
      final session = await sessionFor(role: UserRole.user);

      expect(authRedirect(session, AppRoutes.admin), AppRoutes.home);
    });
  });

  group('authenticated admin', () {
    test('admin routes are allowed', () async {
      final session = await sessionFor(role: UserRole.admin);

      expect(authRedirect(session, AppRoutes.admin), isNull);
      expect(authRedirect(session, AppRoutes.home), isNull);
    });
  });

  group('expired session', () {
    test('expired sessions are treated as unauthenticated', () async {
      final session = await sessionFor(
        role: UserRole.admin,
        refreshError: const UnauthorizedException(
          code: 'invalid_refresh_token',
        ),
      );

      expect(session.status, AuthStatus.expired);
      expect(authRedirect(session, AppRoutes.home), AppRoutes.login);
      expect(authRedirect(session, AppRoutes.admin), AppRoutes.login);
      expect(authRedirect(session, AppRoutes.login), isNull);
    });
  });
}
