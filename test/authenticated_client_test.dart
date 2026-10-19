import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_preco_frontend/core/http/authenticated_client.dart';
import 'package:meu_preco_frontend/features/auth/auth_session.dart';

import 'fakes.dart';

void main() {
  final url = Uri.parse('https://api.example.com/api/v1/products');

  test('signs the first attempt with the current access token', () async {
    final tokens = FakeAuthTokenSource(accessToken: 'access-1');
    final seen = <String?>[];
    final client = AuthenticatedClient(
      inner: MockClient((request) async {
        seen.add(request.headers['Authorization']);
        return http.Response('{"ok":true}', 200);
      }),
      tokens: tokens,
    );

    final response = await client.get(url);

    expect(response.statusCode, 200);
    expect(seen, ['Bearer access-1']);
    expect(tokens.refreshCalls, 0);
  });

  test(
    'refreshes once and replays the request with the rotated token',
    () async {
      final tokens = FakeAuthTokenSource(
        accessToken: 'access-1',
        rotatedAccessToken: 'access-2',
      );
      final seen = <String?>[];
      final client = AuthenticatedClient(
        inner: MockClient((request) async {
          seen.add(request.headers['Authorization']);
          if (seen.length == 1) return http.Response('', 401);
          return http.Response('{"ok":true}', 200);
        }),
        tokens: tokens,
      );

      final response = await client.get(url);

      expect(response.statusCode, 200);
      expect(tokens.refreshCalls, 1);
      expect(seen, ['Bearer access-1', 'Bearer access-2']);
    },
  );

  test('returns the original 401 body when refresh fails', () async {
    final tokens = FakeAuthTokenSource(
      accessToken: 'access-1',
      refreshResult: false,
    );
    final client = AuthenticatedClient(
      inner: MockClient(
        (_) async => http.Response(
          '{"error":{"code":"expired","message":"token expired"}}',
          401,
        ),
      ),
      tokens: tokens,
    );

    final response = await client.get(url);

    expect(response.statusCode, 401);
    expect(response.body, contains('token expired'));
    expect(tokens.refreshCalls, 1);
  });

  test('does not refresh a 401 from the refresh endpoint itself', () async {
    final tokens = FakeAuthTokenSource(accessToken: 'access-1');
    final client = AuthenticatedClient(
      inner: MockClient((_) async => http.Response('', 401)),
      tokens: tokens,
    );

    final response = await client.get(
      Uri.parse('https://api.example.com/api/v1/auth/refresh'),
    );

    expect(response.statusCode, 401);
    expect(tokens.refreshCalls, 0);
  });

  test('concurrent 401s share a single refresh operation', () async {
    final repository = FakeAuthRepository();
    final session = AuthSession(
      repository: repository,
      credentialStore: InMemoryCredentialStore(),
    );
    await session.login(email: 'ada@example.com', password: 'secret123');

    final gate = Completer<void>();
    repository.refreshGate = gate;

    final client = AuthenticatedClient(
      inner: MockClient((request) async {
        if (request.headers['Authorization'] == 'Bearer access-1') {
          return http.Response('', 401);
        }
        return http.Response('{"ok":true}', 200);
      }),
      tokens: session,
    );

    final futures = [client.get(url), client.get(url)];
    // Let both requests reach the shared refresh before releasing the gate.
    await Future<void>.delayed(Duration.zero);
    expect(repository.refreshCalls, 1);

    gate.complete();
    final responses = await Future.wait(futures);

    expect(responses.every((r) => r.statusCode == 200), isTrue);
    expect(repository.refreshCalls, 1);
  });

  test('reuses a token already rotated by another request', () async {
    final tokens = FakeAuthTokenSource(accessToken: 'access-1');
    final seen = <String?>[];
    final client = AuthenticatedClient(
      inner: MockClient((request) async {
        seen.add(request.headers['Authorization']);
        if (request.headers['Authorization'] == 'Bearer access-1') {
          tokens.accessToken = 'access-2';
          return http.Response('', 401);
        }
        return http.Response('{"ok":true}', 200);
      }),
      tokens: tokens,
    );

    final response = await client.get(url);

    expect(response.statusCode, 200);
    expect(tokens.refreshCalls, 0);
    expect(seen, ['Bearer access-1', 'Bearer access-2']);
  });
}
