import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/core/storage/credential_store.dart';
import 'package:meu_preco_frontend/features/auth/auth_session.dart';

import 'fakes.dart';

void main() {
  const user = User(
    id: 1,
    name: 'Ada',
    email: 'ada@example.com',
    role: UserRole.user,
  );

  (AuthSession, FakeAuthRepository, InMemoryCredentialStore) build() {
    final repository = FakeAuthRepository(user: user);
    final store = InMemoryCredentialStore();
    final session = AuthSession(repository: repository, credentialStore: store);
    return (session, repository, store);
  }

  group('restore', () {
    test('with no stored session becomes unauthenticated', () async {
      final (session, _, _) = build();

      await session.restore();

      expect(session.status, AuthStatus.unauthenticated);
      expect(session.isAuthenticated, isFalse);
    });

    test('with a stored session becomes authenticated with its user', () async {
      final repository = FakeAuthRepository(user: user);
      final store = InMemoryCredentialStore(
        const StoredSession(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          user: user,
        ),
      );
      final session = AuthSession(
        repository: repository,
        credentialStore: store,
      );

      await session.restore();

      expect(session.status, AuthStatus.authenticated);
      expect(session.accessToken, 'access-1');
      expect(session.user, user);
    });
  });

  group('login', () {
    test('persists the token pair and current user', () async {
      final (session, _, store) = build();

      await session.login(identifier: 'ada@example.com', password: 'secret123');

      expect(session.status, AuthStatus.authenticated);
      expect(session.user, user);
      expect(session.accessToken, isNotNull);
      expect(store.session?.refreshToken, session.refreshToken);
    });

    test('surfaces backend failures without persisting a session', () async {
      final (session, repository, store) = build();
      repository.loginError = const UnauthorizedException(
        code: 'invalid_credentials',
      );

      await expectLater(
        session.login(identifier: 'ada@example.com', password: 'secret123'),
        throwsA(isA<UnauthorizedException>()),
      );

      expect(session.isAuthenticated, isFalse);
      expect(store.writeCalls, 0);
    });

    test('validates credentials before sending a request', () async {
      final (session, repository, _) = build();

      await expectLater(
        session.login(identifier: '   ', password: 'secret123'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'invalid_login',
          ),
        ),
      );
      await expectLater(
        session.login(identifier: 'ada@example.com', password: 'short'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'invalid_password',
          ),
        ),
      );
      expect(repository.loginCalls, 0);
    });

    test('accepts a display name as the identifier', () async {
      final (session, repository, _) = build();

      await session.login(identifier: 'Ada', password: 'secret123');

      expect(session.isAuthenticated, isTrue);
      expect(repository.loginCalls, 1);
    });
  });

  group('register', () {
    test(
      'creates the account and signs in with the same credentials',
      () async {
        final (session, repository, store) = build();

        final user = await session.register(
          name: 'Grace',
          email: 'grace@example.com',
          password: 'secret123',
        );

        expect(repository.registerCalls, 1);
        expect(repository.loginCalls, 1);
        expect(user.name, 'Grace');
        expect(user.email, 'grace@example.com');
        expect(session.isAuthenticated, isTrue);
        expect(store.session?.user.name, 'Grace');
      },
    );

    test(
      'validates name, email, and password before sending a request',
      () async {
        final (session, repository, _) = build();

        await expectLater(
          session.register(
            name: '   ',
            email: 'ada@example.com',
            password: 'secret123',
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.code,
              'code',
              'invalid_name',
            ),
          ),
        );
        await expectLater(
          session.register(
            name: 'Ada',
            email: 'not-an-email',
            password: 'secret123',
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.code,
              'code',
              'invalid_email',
            ),
          ),
        );
        expect(repository.registerCalls, 0);
      },
    );
  });

  group('refresh', () {
    test('rotates both tokens atomically and persists them', () async {
      final (session, repository, store) = build();
      await session.login(identifier: 'ada@example.com', password: 'secret123');
      final firstAccess = session.accessToken;
      final firstRefresh = session.refreshToken;

      final refreshed = await session.refreshAccessToken();

      expect(refreshed, isTrue);
      expect(repository.refreshCalls, 1);
      expect(session.accessToken, isNot(firstAccess));
      expect(session.refreshToken, isNot(firstRefresh));
      expect(store.session?.accessToken, session.accessToken);
      expect(store.session?.refreshToken, session.refreshToken);
    });

    test('signs out and expires the session on failure', () async {
      final (session, repository, store) = build();
      await session.login(identifier: 'ada@example.com', password: 'secret123');
      repository.refreshError = const UnauthorizedException(
        code: 'refresh_reuse_detected',
      );

      final refreshed = await session.refreshAccessToken();

      expect(refreshed, isFalse);
      expect(session.status, AuthStatus.expired);
      expect(session.user, isNull);
      expect(store.session, isNull);
    });

    test('concurrent calls share a single refresh operation', () async {
      final (session, repository, _) = build();
      await session.login(identifier: 'ada@example.com', password: 'secret123');

      final gate = Completer<void>();
      repository.refreshGate = gate;

      final first = session.refreshAccessToken();
      final second = session.refreshAccessToken();
      gate.complete();

      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(repository.refreshCalls, 1);
    });
  });

  group('validate', () {
    test('reloads the current user from the server', () async {
      final (session, repository, _) = build();
      await session.login(identifier: 'ada@example.com', password: 'secret123');
      repository.user = const User(
        id: 1,
        name: 'Ada',
        email: 'ada@example.com',
        role: UserRole.admin,
      );

      await session.validate();

      expect(session.user?.role, UserRole.admin);
      expect(session.isAdmin, isTrue);
    });

    test('expires the session when the token cannot be refreshed', () async {
      final (session, repository, _) = build();
      await session.login(identifier: 'ada@example.com', password: 'secret123');
      repository.currentUserError = const UnauthorizedException();
      repository.refreshError = const UnauthorizedException(
        code: 'invalid_refresh_token',
      );

      await session.validate();

      expect(session.status, AuthStatus.expired);
    });
  });

  test('logout clears credentials and cached state', () async {
    final (session, _, store) = build();
    await session.login(identifier: 'ada@example.com', password: 'secret123');

    await session.logout();

    expect(session.status, AuthStatus.unauthenticated);
    expect(session.user, isNull);
    expect(session.accessToken, isNull);
    expect(store.clearCalls, 1);
    expect(store.session, isNull);
  });
}
