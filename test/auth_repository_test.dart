import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_preco_frontend/core/config/app_config.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/http/api_client.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/auth/data/auth_repository.dart';

void main() {
  ApiAuthRepository repositoryWith(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    final client = ApiClient(
      configProvider: () => AppConfig.tryFromOrigin('https://api.example.com')!,
      httpClient: MockClient(handler),
    );
    return ApiAuthRepository(client: client);
  }

  test(
    'login posts the identifier to /auth/login and decodes the pair',
    () async {
      final requests = <http.Request>[];
      final repository = repositoryWith((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'access_token': 'access-1',
            'refresh_token': 'refresh-1',
            'user': {
              'id': 1,
              'name': 'Ada',
              'email': 'ada@example.com',
              'role': 'user',
            },
          }),
          200,
        );
      });

      final pair = await repository.login(
        const LoginCredentials(login: 'Ada', password: 'secret123'),
      );

      expect(pair.accessToken, 'access-1');
      expect(pair.refreshToken, 'refresh-1');
      expect(pair.user.name, 'Ada');
      expect(pair.user.email, 'ada@example.com');

      expect(
        requests.single.url.toString(),
        'https://api.example.com/api/v1/auth/login',
      );
      expect(jsonDecode(requests.single.body), {
        'login': 'Ada',
        'password': 'secret123',
      });
    },
  );

  test('register posts name, email and password to /auth/register', () async {
    final requests = <http.Request>[];
    final repository = repositoryWith((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({
          'user': {
            'id': 9,
            'name': 'New User',
            'email': 'new@example.com',
            'role': 'user',
          },
        }),
        201,
      );
    });

    final user = await repository.register(
      const RegisterCredentials(
        name: 'New User',
        email: 'new@example.com',
        password: 'secret123',
      ),
    );

    expect(user.id, 9);
    expect(user.name, 'New User');
    expect(user.email, 'new@example.com');
    expect(user.role, UserRole.user);
    expect(jsonDecode(requests.single.body), {
      'name': 'New User',
      'email': 'new@example.com',
      'password': 'secret123',
    });
  });

  test(
    'refresh sends the refresh token and decodes the rotated pair',
    () async {
      final requests = <http.Request>[];
      final repository = repositoryWith((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'access_token': 'access-2',
            'refresh_token': 'refresh-2',
            'user': {'id': 1, 'email': 'ada@example.com', 'role': 'admin'},
          }),
          200,
        );
      });

      final pair = await repository.refresh(
        const RefreshRequest(refreshToken: 'refresh-1'),
      );

      expect(pair.accessToken, 'access-2');
      expect(pair.user.role, UserRole.admin);
      expect(jsonDecode(requests.single.body), {'refresh_token': 'refresh-1'});
    },
  );

  test('currentUser sends the bearer token and decodes the user', () async {
    final requests = <http.Request>[];
    final repository = repositoryWith((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({
          'user': {'id': 1, 'email': 'ada@example.com', 'role': 'admin'},
        }),
        200,
      );
    });

    final user = await repository.currentUser('access-1');

    expect(user.role, UserRole.admin);
    expect(requests.single.headers['Authorization'], 'Bearer access-1');
  });

  test(
    'a rejected login surfaces the backend code as a typed failure',
    () async {
      final repository = repositoryWith(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'invalid_credentials',
              'message': 'Bad credentials',
            },
          }),
          401,
        ),
      );

      await expectLater(
        repository.login(
          const LoginCredentials(
            login: 'ada@example.com',
            password: 'secret123',
          ),
        ),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.code,
            'code',
            'invalid_credentials',
          ),
        ),
      );
    },
  );
}
