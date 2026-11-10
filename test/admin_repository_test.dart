import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_preco_frontend/core/config/app_config.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/http/api_client.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
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

  test('mergeProducts surfaces typed API failures', () async {
    final repository = repositoryFor(
      (_) async => http.Response(
        jsonEncode({
          'error': {
            'code': 'merge_conflict',
            'message': 'Products cannot be merged',
          },
        }),
        409,
      ),
    );

    await expectLater(
      repository.mergeProducts(10, 20),
      throwsA(
        isA<ConflictException>()
            .having((error) => error.code, 'code', 'merge_conflict')
            .having(
              (error) => error.message,
              'message',
              'Products cannot be merged',
            ),
      ),
    );
  });

  test(
    'updateProduct sends only populated patch fields and decodes the product',
    () async {
      late http.Request request;
      final repository = repositoryFor((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode({
            'id': 42,
            'product_key': 'cafe',
            'name': 'Café Especial',
            'brand': 'Marca Boa',
            'unit': 'kg',
          }),
          200,
        );
      });

      final product = await repository.updateProduct(
        42,
        const ProductPatch(name: 'Café Especial', unit: 'kg'),
      );

      expect(request.method, 'PATCH');
      expect(
        request.url.toString(),
        'https://api.example.com/api/v1/admin/products/42',
      );
      expect(jsonDecode(request.body), {'name': 'Café Especial', 'unit': 'kg'});
      expect(product.id, 42);
      expect(product.name, 'Café Especial');
      expect(product.brand, 'Marca Boa');
      expect(product.unit, 'kg');
    },
  );

  test('updateProduct surfaces typed validation failures', () async {
    final repository = repositoryFor(
      (_) async => http.Response(
        jsonEncode({
          'error': {'code': 'invalid_product', 'message': 'Unit is required'},
        }),
        422,
      ),
    );

    await expectLater(
      repository.updateProduct(42, const ProductPatch(name: 'Café')),
      throwsA(
        isA<ValidationException>()
            .having((error) => error.code, 'code', 'invalid_product')
            .having((error) => error.message, 'message', 'Unit is required'),
      ),
    );
  });
}
