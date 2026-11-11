import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_preco_frontend/core/config/app_config.dart';
import 'package:meu_preco_frontend/features/auth/auth_session.dart';
import 'package:meu_preco_frontend/features/products/data/product_repository.dart';

import 'fakes.dart';
import 'helpers.dart';

void main() {
  group('API origin changes', () {
    test('changing the server signs out and stops signing requests', () async {
      final credentials = InMemoryCredentialStore();
      final authorization = <String?>[];
      final hosts = <String>[];
      final dependencies = buildTestDependencies(
        credentialStore: credentials,
        httpClient: MockClient((request) async {
          authorization.add(request.headers['Authorization']);
          hosts.add(request.url.host);
          return http.Response('{"items":[],"page":{"total":0}}', 200);
        }),
      );
      final products = ApiProductRepository(client: dependencies.apiClient);

      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );
      await products.search(q: 'arroz');
      expect(authorization.last, 'Bearer access-1');

      await dependencies.configController.saveOrigin(
        'https://other.example.com',
      );

      expect(dependencies.authSession.status, AuthStatus.unauthenticated);
      expect(dependencies.authSession.accessToken, isNull);
      expect(dependencies.authSession.refreshToken, isNull);
      expect(credentials.session, isNull);

      await products.search(q: 'arroz');
      expect(authorization.last, isNull);
      expect(hosts.last, 'other.example.com');
    });

    test('saving the same normalized origin preserves the session', () async {
      final credentials = InMemoryCredentialStore();
      final dependencies = buildTestDependencies(credentialStore: credentials);
      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );

      await dependencies.configController.saveOrigin(
        '${AppConfig.defaults().apiOrigin}/api/v1/',
      );

      expect(dependencies.authSession.isAuthenticated, isTrue);
      expect(credentials.session, isNotNull);
    });

    test(
      'resetting to the same default origin preserves the session',
      () async {
        final credentials = InMemoryCredentialStore();
        final dependencies = buildTestDependencies(
          credentialStore: credentials,
        );
        await dependencies.authSession.login(
          identifier: 'ada@example.com',
          password: 'secret123',
        );

        await dependencies.configController.resetToDefault();

        expect(dependencies.authSession.isAuthenticated, isTrue);
        expect(credentials.session, isNotNull);
      },
    );

    test('resetting a different origin to the default signs out', () async {
      final credentials = InMemoryCredentialStore();
      final dependencies = buildTestDependencies(credentialStore: credentials);
      await dependencies.configController.saveOrigin(
        'https://other.example.com',
      );
      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );

      await dependencies.configController.resetToDefault();

      expect(dependencies.authSession.isAuthenticated, isFalse);
      expect(credentials.session, isNull);
    });

    test(
      'a cold start does not restore a session after the origin changed',
      () async {
        final store = InMemoryKeyValueStore();
        final credentials = InMemoryCredentialStore();
        final first = buildTestDependencies(
          store: store,
          credentialStore: credentials,
        );
        await first.configController.load();
        await first.authSession.login(
          identifier: 'ada@example.com',
          password: 'secret123',
        );
        expect(credentials.session, isNotNull);

        await first.configController.saveOrigin('https://other.example.com');
        expect(credentials.session, isNull);

        final restarted = buildTestDependencies(
          store: store,
          credentialStore: credentials,
        );
        await restarted.configController.load();
        await restarted.authSession.restore();

        expect(
          restarted.config.apiOrigin.toString(),
          'https://other.example.com',
        );
        expect(restarted.authSession.status, AuthStatus.unauthenticated);
        expect(restarted.authSession.accessToken, isNull);
      },
    );
  });
}
