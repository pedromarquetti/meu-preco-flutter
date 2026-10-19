import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_preco_frontend/core/config/app_config.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/http/api_client.dart';

void main() {
  ApiClient clientWith(MockClient mock) {
    return ApiClient(
      configProvider: () => AppConfig.tryFromOrigin('https://api.example.com')!,
      httpClient: mock,
    );
  }

  test('successful GET resolves the /api/v1 path and decodes JSON', () async {
    late Uri requested;
    final mock = MockClient((request) async {
      requested = request.url;
      return http.Response(jsonEncode({'items': <dynamic>[]}), 200);
    });

    final result = await clientWith(mock).get('/products');

    expect(requested.toString(), 'https://api.example.com/api/v1/products');
    expect(result, {'items': <dynamic>[]});
  });

  test('POST encodes the body as JSON', () async {
    late String body;
    late String? contentType;
    final mock = MockClient((request) async {
      body = request.body;
      contentType = request.headers['content-type'];
      return http.Response(jsonEncode({'ok': true}), 200);
    });

    await clientWith(mock).post('/auth/login', body: {'email': 'a@b.c'});

    expect(jsonDecode(body), {'email': 'a@b.c'});
    expect(contentType, contains('application/json'));
  });

  test('injects the bearer token when available', () async {
    late String? authorization;
    final mock = MockClient((request) async {
      authorization = request.headers['authorization'];
      return http.Response('{}', 200);
    });

    // Authorization injection is now handled by AuthenticatedClient, not ApiClient.
    await clientWith(mock).get('/auth/me');
    expect(authorization, isNull);
  });

  test('does not override an explicit Authorization header', () async {
    late String? authorization;
    final mock = MockClient((request) async {
      authorization = request.headers['authorization'];
      return http.Response('{}', 200);
    });

    await clientWith(mock)
        .get('/auth/me', headers: {'Authorization': 'Bearer manual'});
    expect(authorization, 'Bearer manual');
  });

  test('maps status codes to actionable typed failures', () async {
    final cases = <int, Matcher>{
      401: isA<UnauthorizedException>(),
      403: isA<ForbiddenException>(),
      404: isA<NotFoundException>(),
      409: isA<ConflictException>(),
      412: isA<PreconditionFailedException>(),
      422: isA<ValidationException>(),
      429: isA<RateLimitedException>(),
      500: isA<ServerException>(),
    };

    for (final entry in cases.entries) {
      final mock = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': 'some_code', 'message': 'some message'},
          }),
          entry.key,
        ),
      );

      await expectLater(
        clientWith(mock).get('/anything'),
        throwsA(
          allOf(
            entry.value,
            isA<AppException>()
                .having((e) => e.code, 'code', 'some_code')
                .having((e) => e.message, 'message', 'some message')
                .having((e) => e.statusCode, 'statusCode', entry.key),
          ),
        ),
        reason: 'status ${entry.key}',
      );
    }
  });

  test('reads Retry-After into the rate-limit exception', () async {
    final mock = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': {'code': 'rate_limited', 'message': 'slow down'},
        }),
        429,
        headers: {'retry-after': '7'},
      ),
    );

    await expectLater(
      clientWith(mock).get('/anything'),
      throwsA(
        isA<RateLimitedException>().having(
          (e) => e.retryAfter,
          'retryAfter',
          const Duration(seconds: 7),
        ),
      ),
    );
  });

  test('converts a transport Error into a NetworkException', () async {
    final mock = MockClient(
      (_) async => throw ArgumentError('Invalid port 372184721897213'),
    );

    await expectLater(
      clientWith(mock).get('/anything'),
      throwsA(isA<NetworkException>()),
    );
  });

  test('converts a ClientException into a NetworkException', () async {
    final mock = MockClient((_) async => throw http.ClientException('boom'));

    await expectLater(
      clientWith(mock).get('/anything'),
      throwsA(isA<NetworkException>()),
    );
  });

  test('sendRaw returns non-2xx responses without throwing', () async {
    final mock = MockClient(
      (_) async => http.Response(jsonEncode({'status': 'unavailable'}), 503),
    );

    final response = await clientWith(mock)
        .sendRaw('GET', '/readyz', useApiPrefix: false);

    expect(response.statusCode, 503);
    expect(response.isSuccess, isFalse);
    expect(response.data, {'status': 'unavailable'});
  });
}
