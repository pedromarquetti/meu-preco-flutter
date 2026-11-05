import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_preco_frontend/core/config/app_config.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/http/api_client.dart';
import 'package:meu_preco_frontend/features/admin/data/admin_repository.dart';

void main() {
  ApiAdminRepository repositoryFor(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      configProvider: () => AppConfig.tryFromOrigin('https://api.example.com')!,
      httpClient: MockClient(handler),
    );
    return ApiAdminRepository(client: client);
  }

  test(
    'mergeProducts sends the admin merge request and decodes the result',
    () async {
      late http.Request request;
      final repository = repositoryFor((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode({
            'from_id': 10,
            'to_id': 20,
            'logs_moved': 3,
            'dup_removed': false,
          }),
          200,
        );
      });

      final result = await repository.mergeProducts(10, 20);

      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://api.example.com/api/v1/admin/products/merge',
      );
      expect(jsonDecode(request.body), {'from_id': 10, 'to_id': 20});
      expect(result.fromId, 10);
      expect(result.toId, 20);
      expect(result.logsMoved, 3);
      expect(result.dupRemoved, isFalse);
    },
  );

  test('getProduct requests the admin product detail endpoint', () async {
    late http.Request request;
    final repository = repositoryFor((incoming) async {
      request = incoming;
      return http.Response(
        jsonEncode({
          'id': 42,
          'product_key': 'arroz-tipo-1',
          'name': 'Arroz Tipo 1',
          'brand': 'Boa Mesa',
          'unit': 'kg',
        }),
        200,
      );
    });

    final result = await repository.getProduct(42);

    expect(request.method, 'GET');
    expect(
      request.url.toString(),
      'https://api.example.com/api/v1/admin/products/42',
    );
    expect(result.id, 42);
    expect(result.name, 'Arroz Tipo 1');
    expect(result.brand, 'Boa Mesa');
    expect(result.unit, 'kg');
  });

  test('getProduct maps an API error to a typed exception', () async {
    final repository = repositoryFor(
      (_) async => http.Response(
        jsonEncode({
          'error': {'code': 'product_not_found', 'message': 'missing'},
        }),
        404,
      ),
    );

    await expectLater(
      repository.getProduct(404),
      throwsA(
        isA<NotFoundException>()
            .having((error) => error.code, 'code', 'product_not_found')
            .having((error) => error.message, 'message', 'missing'),
      ),
    );
  });
}
