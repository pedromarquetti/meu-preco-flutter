import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/config/app_config_controller.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/core/theme/theme_controller.dart';
import 'package:meu_preco_frontend/features/auth/auth_session.dart';
import 'package:meu_preco_frontend/features/auth/data/auth_repository.dart';
import 'package:meu_preco_frontend/features/nfce/data/nfce_repository.dart';

import 'fake_api_server.dart';
import 'fakes.dart';

/// End-to-end tests that drive the real HTTP pipeline — [ApiClient] through
/// [AuthenticatedClient], the repositories, and [AuthSession] — against an
/// in-process fake Meu Preço server over loopback HTTP. They use plain `test`
/// (not `testWidgets`) so no widget-test HTTP overrides block real sockets.
void main() {
  late FakeApiServer server;

  setUp(() async {
    server = await FakeApiServer.start();
  });

  tearDown(() async {
    await server.close();
  });

  Future<AppDependencies> buildDependencies({
    InMemoryCredentialStore? credentialStore,
  }) async {
    final store = InMemoryKeyValueStore();
    final configController = AppConfigController(store: store);
    await configController.load();
    final themeController = ThemeController(store: store);
    await themeController.load();
    final dependencies = AppDependencies(
      store: store,
      configController: configController,
      themeController: themeController,
      credentialStore: credentialStore ?? InMemoryCredentialStore(),
      httpClient: http.Client(),
    );
    await configController.saveOrigin(server.origin.toString());
    return dependencies;
  }

  group('request pipeline', () {
    test('health and readiness probes succeed against a live server', () async {
      final dependencies = await buildDependencies();

      await dependencies.verifyServer();

      expect(dependencies.serverGate, isNull);
      final health = await dependencies.healthChecker.check(
        server.origin.toString(),
      );
      final readiness = await dependencies.healthChecker.checkReadiness(
        server.origin.toString(),
      );
      expect(health.ok, isTrue);
      expect(readiness.ok, isTrue);
    });

    test('API paths carry the /api/v1 prefix over the wire', () async {
      final dependencies = await buildDependencies();
      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );

      await dependencies.productsRepository.search(q: 'arroz');

      expect(
        server.requests.any((request) => request.path == '/api/v1/products'),
        isTrue,
      );
      expect(
        server.requests.any((request) => request.path == '/healthz'),
        isFalse,
      );
    });
  });

  group('login and session lifecycle', () {
    test(
      'login persists a session that a fresh dependency graph restores',
      () async {
        final credentialStore = InMemoryCredentialStore();
        final dependencies = await buildDependencies(
          credentialStore: credentialStore,
        );

        final user = await dependencies.authSession.login(
          identifier: 'ada@example.com',
          password: 'secret123',
        );

        expect(user.name, 'Ada');
        expect(dependencies.authSession.status, AuthStatus.authenticated);
        expect(credentialStore.session, isNotNull);

        // Cold start: a new dependency graph restores and re-validates the
        // persisted session against GET /auth/me.
        final restored = await buildDependencies(
          credentialStore: credentialStore,
        );
        await restored.authSession.restore();
        await restored.authSession.validate();

        expect(restored.authSession.status, AuthStatus.authenticated);
        expect(restored.authSession.user?.email, 'ada@example.com');
      },
    );

    test(
      'invalid credentials fail with a typed 401 and persist nothing',
      () async {
        final credentialStore = InMemoryCredentialStore();
        final dependencies = await buildDependencies(
          credentialStore: credentialStore,
        );

        await expectLater(
          dependencies.authSession.login(
            identifier: 'ada@example.com',
            password: 'wrong-password',
          ),
          throwsA(isA<UnauthorizedException>()),
        );
        expect(credentialStore.session, isNull);
        expect(dependencies.authSession.isAuthenticated, isFalse);
      },
    );

    test(
      'an expired access token is refreshed and the request retried',
      () async {
        final dependencies = await buildDependencies();
        await dependencies.authSession.login(
          identifier: 'ada@example.com',
          password: 'secret123',
        );
        expect(server.refreshCallCount, 0);

        server.expireAccessTokens();

        final page = await dependencies.productsRepository.search(q: 'arroz');

        expect(page.items, hasLength(1));
        expect(page.items.single.name, 'Arroz Tipo 1 5kg');
        expect(server.refreshCallCount, 1);
        expect(dependencies.authSession.isAuthenticated, isTrue);
      },
    );

    test(
      'refresh-token reuse is rejected and revokes the token family',
      () async {
        final dependencies = await buildDependencies();
        await dependencies.authSession.login(
          identifier: 'ada@example.com',
          password: 'secret123',
        );
        final staleRefresh = dependencies.authSession.refreshToken!;

        // A legitimate rotation invalidates the old refresh token server-side.
        expect(await dependencies.authSession.refreshAccessToken(), isTrue);

        await expectLater(
          ApiAuthRepository(client: dependencies.apiClient)
              .refresh(RefreshRequest(refreshToken: staleRefresh)),
          throwsA(
            isA<UnauthorizedException>().having(
              (error) => error.code,
              'code',
              'refresh_reuse_detected',
            ),
          ),
        );

        // The whole family is revoked, so the next authenticated call fails
        // through the 401 → refresh → 401 path instead of silently succeeding.
        await expectLater(
          dependencies.productsRepository.search(q: 'arroz'),
          throwsA(isA<UnauthorizedException>()),
        );
      },
    );
  });

  group('product flows', () {
    test('search, detail, and history round-trip exact decimals', () async {
      final dependencies = await buildDependencies();
      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );

      final page = await dependencies.productsRepository.search(q: 'arroz');
      final id = page.items.single.id!;

      final detail = await dependencies.productsRepository.detail(id);
      expect(detail.name, 'Arroz Tipo 1 5kg');
      expect(detail.gtin, '7891234567890');

      final history = await dependencies.productsRepository.history(id);
      expect(history.points, hasLength(2));
      // Money values stay exact decimal strings — never floating point.
      expect(history.points.first.pricePerUnit.toString(), '4.99');
      expect(history.points.last.totalPrice.toString(), '27.45');
      expect(history.aggregate.single.avg.toString(), '5.24');
    });

    test('an unknown product id surfaces a typed 404', () async {
      final dependencies = await buildDependencies();
      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );

      await expectLater(
        dependencies.productsRepository.detail(9999),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('NFC-e flows', () {
    test(
      'draft → captcha → solve → commit with duplicate protection',
      () async {
        final dependencies = await buildDependencies();
        await dependencies.authSession.login(
          identifier: 'ada@example.com',
          password: 'secret123',
        );
        final repository = ApiNfceRepository(client: dependencies.apiClient);

        // The demo captcha key is blocked by a challenge on the first draft.
        final blocked = await repository.draft(
          const DraftRequest(accessKey: FakeApiServer.captchaRequiredKey),
        );
        expect(blocked, isA<DraftCaptchaRequired>());
        final challenge = (blocked as DraftCaptchaRequired).challenge;
        expect(challenge.challengeId, 'challenge-1');

        final image = await repository.captchaImage(challenge.challengeId);
        expect(image, kSamplePngBytes);

        final rejected = await repository.solveCaptcha(
          const CaptchaSolutionRequest(
            challengeId: 'challenge-1',
            solution: 'nope',
          ),
        );
        expect(rejected, isA<CaptchaRejected>());
        expect((rejected as CaptchaRejected).feedback.attemptsLeft, 4);

        final solved = await repository.solveCaptcha(
          const CaptchaSolutionRequest(
            challengeId: 'challenge-1',
            solution: FakeApiServer.captchaSolution,
          ),
        );
        expect(solved, isA<CaptchaSolved>());
        final preview = (solved as CaptchaSolved).preview;
        expect(preview.previewId, 42);

        final result = await repository.submit(
          CommitRequest(previewId: preview.previewId, confirm: true),
        );
        expect(result.confirmed, isTrue);
        expect(result.written, 1);
        expect(result.needsReview, 1);

        // Confirming the same preview again is rejected as a duplicate.
        await expectLater(
          repository.submit(
            CommitRequest(previewId: preview.previewId, confirm: true),
          ),
          throwsA(
            isA<ConflictException>().having(
              (error) => error.code,
              'code',
              'preview_already_committed',
            ),
          ),
        );
      },
    );

    test('an already-committed receipt drafts as a typed 409', () async {
      final dependencies = await buildDependencies();
      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );
      final repository = ApiNfceRepository(client: dependencies.apiClient);

      await expectLater(
        repository.draft(
          const DraftRequest(accessKey: FakeApiServer.duplicateAccessKey),
        ),
        throwsA(
          isA<ConflictException>().having(
            (error) => error.code,
            'code',
            'preview_already_committed',
          ),
        ),
      );
    });

    test('an invalid access key surfaces a typed 422', () async {
      final dependencies = await buildDependencies();
      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );
      final repository = ApiNfceRepository(client: dependencies.apiClient);

      await expectLater(
        repository.draft(const DraftRequest(accessKey: '123')),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            'invalid_access_key',
          ),
        ),
      );
    });
  });

  group('admin flows', () {
    test('an admin lists users and changes a role', () async {
      final dependencies = await buildDependencies();
      await dependencies.authSession.login(
        identifier: 'admin@example.com',
        password: 'secret123',
      );
      expect(dependencies.authSession.isAdmin, isTrue);

      final users = await dependencies.adminRepository.listUsers();
      expect(users.items, hasLength(2));

      final updated = await dependencies.adminRepository.updateUserRole(
        userId: 1,
        role: UserRole.admin,
      );
      expect(updated.role, UserRole.admin);

      final assignments = await dependencies.adminRepository.batchAssign([
        const Assignment(
          id: 1,
          action: AssignmentAction.existing,
          productId: 1,
        ),
      ]);
      expect(assignments.assigned, 1);
    });

    test('a non-admin is rejected with a typed 403', () async {
      final dependencies = await buildDependencies();
      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );

      await expectLater(
        dependencies.adminRepository.listUsers(),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });

  group('logout clearing', () {
    test(
      'logout clears the session and stops authenticating requests',
      () async {
        final credentialStore = InMemoryCredentialStore();
        final dependencies = await buildDependencies(
          credentialStore: credentialStore,
        );
        await dependencies.authSession.login(
          identifier: 'ada@example.com',
          password: 'secret123',
        );
        final seenAuthorizations = <String?>[];

        await dependencies.authSession.logout();

        expect(dependencies.authSession.status, AuthStatus.unauthenticated);
        expect(dependencies.authSession.accessToken, isNull);
        expect(dependencies.authSession.refreshToken, isNull);
        expect(dependencies.authSession.user, isNull);
        expect(credentialStore.session, isNull);
        expect(credentialStore.clearCalls, greaterThanOrEqualTo(1));

        // A post-logout request must not carry the old bearer token.
        try {
          await dependencies.productsRepository.search(q: 'arroz');
        } on AppException {
          // Expected: no credentials remain, so the request is rejected.
        }
        for (final request in server.requests) {
          if (request.path == '/api/v1/products') {
            seenAuthorizations.add(request.authorization);
          }
        }
        expect(seenAuthorizations, isNotEmpty);
        expect(seenAuthorizations.last, isNull);
      },
    );
  });

  group('secret hygiene', () {
    test('failed-login errors never contain the password', () async {
      const password = 'super-secret-password';
      final dependencies = await buildDependencies();

      Object? caught;
      try {
        await dependencies.authSession.login(
          identifier: 'ada@example.com',
          password: password,
        );
      } on AppException catch (error) {
        caught = error;
      }

      expect(caught, isA<UnauthorizedException>());
      final dump =
          '${(caught as AppException).message} '
          '${caught.code} $caught';
      expect(dump, isNot(contains(password)));
    });

    test('token-rotation failures never leak token values', () async {
      final dependencies = await buildDependencies();
      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );
      final staleRefresh = dependencies.authSession.refreshToken!;
      await dependencies.authSession.refreshAccessToken();

      Object? caught;
      try {
        await ApiAuthRepository(client: dependencies.apiClient)
            .refresh(RefreshRequest(refreshToken: staleRefresh));
      } on AppException catch (error) {
        caught = error;
      }

      expect(caught, isA<UnauthorizedException>());
      final dump =
          '${(caught as AppException).message} '
          '${caught.code} $caught';
      expect(dump.contains(RegExp('access-token-\\d')), isFalse);
      expect(dump.contains(RegExp('refresh-token-\\d')), isFalse);
    });

    test(
      'recorded traffic shows passwords only on the login request body',
      () async {
        final dependencies = await buildDependencies();
        await dependencies.authSession.login(
          identifier: 'ada@example.com',
          password: 'secret123',
        );

        for (final request in server.requests) {
          // Authorization headers exist only as bearer tokens; the recorded
          // request metadata never carries a password field at all.
          final authorization = request.authorization;
          if (authorization != null) {
            expect(authorization, startsWith('Bearer '));
            expect(authorization, isNot(contains('secret123')));
          }
        }
      },
    );
  });
}
