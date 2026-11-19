import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_preco_frontend/core/config/app_config.dart';
import 'package:meu_preco_frontend/core/http/api_client.dart';
import 'package:meu_preco_frontend/core/http/server_health_service.dart';

void main() {
  ApiClient clientWith(MockClient mock) => ApiClient(
    configProvider: () => AppConfig.tryFromOrigin('http://localhost:8000')!,
    httpClient: mock,
  );

  HttpServerHealthChecker checkerWith(MockClient mock, {Duration? timeout}) =>
      HttpServerHealthChecker(apiClient: clientWith(mock), timeout: timeout);

  group('liveness (/healthz)', () {
    test('requests the origin root and accepts {"status":"ok"}', () async {
      late Uri requested;
      final mock = MockClient((request) async {
        requested = request.url;
        return http.Response(
          jsonEncode({'status': 'ok'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await checkerWith(mock).check('https://api.example.com');

      expect(result.ok, isTrue);
      expect(result.statusCode, 200);
      // No `/api/v1` prefix, and the candidate origin is used.
      expect(requested.toString(), 'https://api.example.com/healthz');
    });

    test('accepts a pretty-printed body (not a substring match)', () async {
      final mock = MockClient(
        (_) async => http.Response('{\n  "status": "ok"\n}\n', 200),
      );

      final result = await checkerWith(mock).check('https://api.example.com');

      expect(result.ok, isTrue);
    });

    test('rejects a 200 response that is not a Meu Preço server', () async {
      final mock = MockClient(
        (_) async => http.Response('<html>hello</html>', 200),
      );

      final result = await checkerWith(mock).check('https://api.example.com');

      expect(result.ok, isFalse);
      expect(result.errorCode, 'unhealthy');
    });

    test('rejects a body with a different status', () async {
      final mock = MockClient(
        (_) async => http.Response(jsonEncode({'status': 'unavailable'}), 200),
      );

      final result = await checkerWith(mock).check('https://api.example.com');

      expect(result.ok, isFalse);
      expect(result.errorCode, 'unhealthy');
    });
  });

  group('readiness (/readyz)', () {
    test('accepts 200 {"status":"ok"}', () async {
      late Uri requested;
      final mock = MockClient((request) async {
        requested = request.url;
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final result = await checkerWith(mock)
          .checkReadiness('https://api.example.com');

      expect(result.ok, isTrue);
      expect(requested.path, '/readyz');
    });

    test('surfaces the reason from a 503 body', () async {
      final mock = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 'unavailable',
            'reason': 'database unreachable',
          }),
          503,
        ),
      );

      final result = await checkerWith(mock)
          .checkReadiness('https://api.example.com');

      expect(result.ok, isFalse);
      expect(result.statusCode, 503);
      expect(result.errorCode, 'unhealthy');
      expect(result.errorMessage, 'database unreachable');
    });
  });

  group('scheme-less addresses', () {
    test(
      'probes https first, then http, and resolves the reachable one',
      () async {
        final requested = <Uri>[];
        final mock = MockClient((request) async {
          requested.add(request.url);
          if (request.url.scheme == 'https') {
            throw http.ClientException('connection refused');
          }
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        });

        final result = await checkerWith(mock).check('localhost:8080');

        expect(result.ok, isTrue);
        expect(requested.map((uri) => uri.toString()), [
          'https://localhost:8080/healthz',
          'http://localhost:8080/healthz',
        ]);
        expect(result.resolvedOrigin.toString(), 'http://localhost:8080');
        expect(result.attemptedOrigins, [
          'https://localhost:8080',
          'http://localhost:8080',
        ]);
      },
    );

    test('reports every attempted origin when all of them fail', () async {
      final mock = MockClient(
        (_) async => throw http.ClientException('connection refused'),
      );

      final result = await checkerWith(mock).check('localhost:8080');

      expect(result.ok, isFalse);
      expect(result.errorCode, 'unreachable');
      expect(result.resolvedOrigin, isNull);
      expect(result.attemptedOrigins, [
        'https://localhost:8080',
        'http://localhost:8080',
      ]);
    });

    test('keeps a typed scheme and never retries another one', () async {
      final requested = <Uri>[];
      final mock = MockClient((request) async {
        requested.add(request.url);
        throw http.ClientException('connection refused');
      });

      final result = await checkerWith(mock).check('http://localhost:8080');

      expect(result.ok, isFalse);
      expect(requested.map((uri) => uri.scheme), ['http']);
      expect(result.attemptedOrigins, ['http://localhost:8080']);
    });

    test('tries the fallback port first for a scheme-less host', () async {
      final requested = <Uri>[];
      final mock = MockClient((request) async {
        requested.add(request.url);
        throw http.ClientException('connection refused');
      });

      final result = await checkerWith(mock).check('localhost');

      expect(result.ok, isFalse);
      expect(requested.map((uri) => uri.toString()), [
        'http://localhost:8080/healthz',
        'https://localhost:8080/healthz',
        'http://localhost/healthz',
        'https://localhost/healthz',
      ]);
      expect(result.attemptedOrigins, [
        'http://localhost:8080',
        'https://localhost:8080',
        'http://localhost',
        'https://localhost',
      ]);
    });

    test('stops at the first reachable fallback-port candidate', () async {
      final requested = <Uri>[];
      final mock = MockClient((request) async {
        requested.add(request.url);
        if (request.url.toString() == 'http://localhost:8080/healthz') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        throw http.ClientException('connection refused');
      });

      final result = await checkerWith(mock).check('localhost');

      expect(result.ok, isTrue);
      expect(requested.map((uri) => uri.toString()), [
        'http://localhost:8080/healthz',
      ]);
      expect(result.resolvedOrigin.toString(), 'http://localhost:8080');
    });

    test('adds the fallback port when a scheme is typed without one', () async {
      final requested = <Uri>[];
      final mock = MockClient((request) async {
        requested.add(request.url);
        throw http.ClientException('connection refused');
      });

      final result = await checkerWith(mock).check('http://localhost');

      expect(result.ok, isFalse);
      expect(requested.map((uri) => uri.toString()), [
        'http://localhost/healthz',
        'http://localhost:8080/healthz',
      ]);
      expect(requested.map((uri) => uri.scheme), ['http', 'http']);
    });
  });

  group('failures', () {
    test('an invalid origin never hits the network', () async {
      var called = false;
      final mock = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });

      final result = await checkerWith(mock).check('ftp://localhost:8080');

      expect(result.errorCode, 'invalid_url');
      expect(called, isFalse);
    });

    test('an out-of-range port never hits the network', () async {
      var called = false;
      final mock = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });

      final result = await checkerWith(mock)
          .check('http://localhost:372184721897213');

      expect(result.ok, isFalse);
      expect(result.errorCode, 'invalid_url');
      expect(called, isFalse);
    });

    test('a transport failure is reported as unreachable', () async {
      final mock = MockClient(
        (_) async => throw http.ClientException('connection refused'),
      );

      final result = await checkerWith(mock).check('https://api.example.com');

      expect(result.ok, isFalse);
      expect(result.errorCode, 'unreachable');
    });

    test('a slow response is reported as a timeout', () async {
      final mock = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final result = await checkerWith(
        mock,
        timeout: const Duration(milliseconds: 20),
      ).check('https://api.example.com');

      expect(result.ok, isFalse);
      expect(result.errorCode, 'timeout');
    });
  });
}
