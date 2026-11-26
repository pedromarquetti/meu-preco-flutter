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

  ApiClient clientFor(String origin, MockClient mock) {
    return ApiClient(
      configProvider: () => AppConfig.tryFromOrigin(origin)!,
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

  group('HTTPS upgrades', () {
    test(
      'upgrades a public default-port HTTP request before sending',
      () async {
        late Uri requested;
        final mock = MockClient((request) async {
          requested = request.url;
          return http.Response('{}', 200);
        });

        await clientFor('http://api.example.com', mock).get('/products');

        expect(requested.toString(), 'https://api.example.com/api/v1/products');
      },
    );

    test('keeps plain HTTP for local and private hosts', () async {
      final requested = <Uri>[];
      final mock = MockClient((request) async {
        requested.add(request.url);
        return http.Response('{}', 200);
      });

      await clientFor(
        'http://localhost',
        mock,
      ).get('/healthz', useApiPrefix: false);
      await clientFor(
        'http://192.168.1.5',
        mock,
      ).get('/healthz', useApiPrefix: false);
      await clientFor(
        'http://10.0.0.5',
        mock,
      ).get('/healthz', useApiPrefix: false);

      expect(requested.map((uri) => uri.scheme), ['http', 'http', 'http']);
    });

    test('does not upgrade a public origin with a non-default port', () async {
      late Uri requested;
      final mock = MockClient((request) async {
        requested = request.url;
        return http.Response('{}', 200);
      });

      await clientFor('http://api.example.com:8080', mock).get('/products');

      expect(requested.scheme, 'http');
      expect(requested.port, 8080);
    });

    for (final status in [301, 302, 307, 308]) {
      test(
        'follows a $status same-host HTTP to HTTPS redirect for POST',
        () async {
          final requests = <http.Request>[];
          final mock = MockClient((request) async {
            requests.add(request);
            if (requests.length == 1) {
              return http.Response(
                '',
                status,
                headers: {
                  'location': 'https://api.example.com/api/v1/auth/login',
                },
              );
            }
            return http.Response(jsonEncode({'ok': true}), 200);
          });

          final result = await clientFor('http://api.example.com:8080', mock)
              .post(
                '/auth/login',
                body: {'login': 'ada', 'password': 'secret123'},
              );

          expect(requests, hasLength(2));
          expect(requests.first.method, 'POST');
          expect(requests.first.url.scheme, 'http');
          expect(requests.last.method, 'POST');
          expect(
            requests.last.url.toString(),
            'https://api.example.com/api/v1/auth/login',
          );
          expect(jsonDecode(requests.last.body), {
            'login': 'ada',
            'password': 'secret123',
          });
          expect(result, {'ok': true});
        },
      );
    }

    test('does not follow a redirect to another host', () async {
      final requests = <http.Request>[];
      final mock = MockClient((request) async {
        requests.add(request);
        return http.Response(
          '',
          301,
          headers: {'location': 'https://evil.example.com/login'},
        );
      });

      await expectLater(
        clientFor(
          'http://api.example.com:8080',
          mock,
        ).post('/auth/login', body: {'login': 'ada'}),
        throwsA(
          isA<ApiException>()
              .having((error) => error.code, 'code', 'unexpected_redirect')
              .having((error) => error.statusCode, 'statusCode', 301),
        ),
      );
      expect(requests, hasLength(1));
    });

    test('does not follow an HTTPS to HTTP downgrade', () async {
      final requests = <http.Request>[];
      final mock = MockClient((request) async {
        requests.add(request);
        return http.Response(
          '',
          301,
          headers: {'location': 'http://api.example.com/api/v1/auth/login'},
        );
      });

      await expectLater(
        clientWith(mock).post('/auth/login', body: {'login': 'ada'}),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'unexpected_redirect',
          ),
        ),
      );
      expect(requests, hasLength(1));
    });

    test('does not replay a POST through a 303', () async {
      final requests = <http.Request>[];
      final mock = MockClient((request) async {
        requests.add(request);
        return http.Response(
          '',
          303,
          headers: {'location': 'https://api.example.com/api/v1/auth/login'},
        );
      });

      await expectLater(
        clientFor(
          'http://api.example.com:8080',
          mock,
        ).post('/auth/login', body: {'login': 'ada'}),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'unexpected_redirect',
          ),
        ),
      );
      expect(requests, hasLength(1));
    });
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
      400: isA<ValidationException>(),
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

  test('maps documented API codes to typed failures', () async {
    final cases = <({int status, String code, Matcher type})>[
      (status: 401, code: 'unauthorized', type: isA<UnauthorizedException>()),
      (
        status: 401,
        code: 'invalid_credentials',
        type: isA<UnauthorizedException>(),
      ),
      (
        status: 401,
        code: 'invalid_refresh_token',
        type: isA<UnauthorizedException>(),
      ),
      (
        status: 401,
        code: 'refresh_reuse_detected',
        type: isA<UnauthorizedException>(),
      ),
      (status: 403, code: 'forbidden', type: isA<ForbiddenException>()),
      (
        status: 403,
        code: 'registration_disabled',
        type: isA<ForbiddenException>(),
      ),
      (status: 404, code: 'not_found', type: isA<NotFoundException>()),
      (status: 404, code: 'receipt_not_found', type: isA<NotFoundException>()),
      (status: 404, code: 'preview_not_found', type: isA<NotFoundException>()),
      (
        status: 404,
        code: 'challenge_not_found',
        type: isA<NotFoundException>(),
      ),
      (status: 409, code: 'conflict', type: isA<ConflictException>()),
      (status: 409, code: 'in_use', type: isA<ConflictException>()),
      (status: 409, code: 'user_exists', type: isA<ConflictException>()),
      (status: 409, code: 'challenge_used', type: isA<ConflictException>()),
      (
        status: 409,
        code: 'preview_already_committed',
        type: isA<ConflictException>(),
      ),
      (
        status: 412,
        code: 'captcha_required',
        type: isA<PreconditionFailedException>(),
      ),
      (
        status: 412,
        code: 'captcha_wrong_solution',
        type: isA<PreconditionFailedException>(),
      ),
      (
        status: 422,
        code: 'invalid_access_key',
        type: isA<ValidationException>(),
      ),
      (status: 422, code: 'invalid_email', type: isA<ValidationException>()),
      (status: 422, code: 'invalid_name', type: isA<ValidationException>()),
      (status: 422, code: 'invalid_password', type: isA<ValidationException>()),
      (
        status: 422,
        code: 'invalid_qr_payload',
        type: isA<ValidationException>(),
      ),
      (
        status: 422,
        code: 'challenge_expired',
        type: isA<ValidationException>(),
      ),
      (status: 422, code: 'preview_expired', type: isA<ValidationException>()),
      (
        status: 422,
        code: 'preview_snapshot_missing',
        type: isA<ValidationException>(),
      ),
      (status: 400, code: 'invalid_filter', type: isA<ValidationException>()),
      (status: 400, code: 'invalid_request', type: isA<ValidationException>()),
      (
        status: 400,
        code: 'invalid_resolution',
        type: isA<ValidationException>(),
      ),
      (status: 400, code: 'invalid_role', type: isA<ValidationException>()),
      (status: 400, code: 'invalid_assignment', type: isA<InvalidAssignment>()),
      (status: 429, code: 'rate_limited', type: isA<RateLimitedException>()),
      (
        status: 429,
        code: 'challenge_locked',
        type: isA<RateLimitedException>(),
      ),
      (
        status: 429,
        code: 'upstream_rate_limited',
        type: isA<RateLimitedException>(),
      ),
      (status: 500, code: 'internal_error', type: isA<ServerException>()),
      (status: 502, code: 'upstream_error', type: isA<ServerException>()),
      (
        status: 500,
        code: 'preview_snapshot_unreadable',
        type: isA<ServerException>(),
      ),
      (status: 501, code: 'unsupported_uf', type: isA<ApiException>()),
    ];

    for (final entry in cases) {
      final mock = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': entry.code, 'message': 'backend message'},
          }),
          entry.status,
        ),
      );

      await expectLater(
        clientWith(mock).get('/anything'),
        throwsA(
          allOf(
            entry.type,
            isA<AppException>()
                .having((e) => e.code, 'code', entry.code)
                .having((e) => e.statusCode, 'statusCode', entry.status),
          ),
        ),
        reason: '${entry.code} (${entry.status})',
      );
    }
  });

  test('preserves captcha challenge details on the typed failure', () async {
    final mock = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': {
            'code': 'captcha_required',
            'message': 'solve the captcha',
            'challenge_id': 'c1',
            'image_url': '/api/v1/nfce/captcha/image/c1',
          },
        }),
        412,
      ),
    );

    await expectLater(
      clientWith(mock).get('/anything'),
      throwsA(
        isA<PreconditionFailedException>()
            .having((e) => e.details?['challenge_id'], 'challenge_id', 'c1')
            .having(
              (e) => e.details?['image_url'],
              'image_url',
              '/api/v1/nfce/captcha/image/c1',
            ),
      ),
    );
  });

  test('reads Retry-After for challenge_locked', () async {
    final mock = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': {'code': 'challenge_locked', 'message': 'locked'},
        }),
        429,
        headers: {'retry-after': '12'},
      ),
    );

    await expectLater(
      clientWith(mock).get('/anything'),
      throwsA(
        isA<RateLimitedException>().having(
          (e) => e.retryAfter,
          'retryAfter',
          const Duration(seconds: 12),
        ),
      ),
    );
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
