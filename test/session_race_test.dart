import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/features/auth/auth_session.dart';
import 'package:meu_preco_frontend/core/storage/credential_store.dart';
import 'package:meu_preco_frontend/core/models/models.dart';

import 'fakes.dart';

void main() {
  group('AuthSession epoch race protection', () {
    late FakeAuthRepository fakeRepo;
    late InMemoryCredentialStore credStore;
    late AuthSession session;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      credStore = InMemoryCredentialStore();
      session = AuthSession(repository: fakeRepo, credentialStore: credStore);
    });

    test(
      'logout during in-flight refresh does not resurrect session',
      () async {
        final stored = StoredSession(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
          user: User(
            id: 1,
            name: 'Test',
            email: 't@t.com',
            role: UserRole.user,
          ),
        );
        await credStore.write(stored);
        await session.restore();
        expect(session.isAuthenticated, isTrue);

        // Start a slow refresh
        fakeRepo.refreshDelay = const Duration(milliseconds: 100);
        final refreshFuture = session.refreshAccessToken();

        // Immediately logout while refresh is in flight
        await session.logout();
        expect(session.isAuthenticated, isFalse);

        // Refresh completes - should NOT resurrect
        await refreshFuture;
        expect(session.isAuthenticated, isFalse);
        expect(session.accessToken, isNull);
      },
    );

    test('logout during validate() does not resurrect session', () async {
      final stored = StoredSession(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
        user: User(id: 1, name: 'Test', email: 't@t.com', role: UserRole.user),
      );
      await credStore.write(stored);
      await session.restore();

      // Start validate (which calls _loadCurrentUser)
      fakeRepo.currentUserDelay = const Duration(milliseconds: 100);
      final validateFuture = session.validate();

      // Logout while validate is in flight
      await session.logout();
      expect(session.isAuthenticated, isFalse);

      // validate completes - should NOT resurrect
      await validateFuture;
      expect(session.isAuthenticated, isFalse);
    });

    test('new login after logout creates new epoch', () async {
      final stored = StoredSession(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
        user: User(id: 1, name: 'Old', email: 'old@t.com', role: UserRole.user),
      );
      await credStore.write(stored);
      await session.restore();
      expect(session.user?.email, 'old@t.com');

      await session.logout();
      expect(session.isAuthenticated, isFalse);

      // New login
      final pair = AuthPair(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
        user: User(id: 2, name: 'New', email: 'new@t.com', role: UserRole.user),
      );
      fakeRepo.loginResult = pair;
      await session.login(identifier: 'new@t.com', password: 'password123');
      expect(session.user?.email, 'new@t.com');
      expect(session.accessToken, 'new-access');
    });
  });
}
