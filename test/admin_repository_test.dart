import 'dart:async';
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

  test(
    'search calls the admin product endpoint and decodes the page',
    () async {
      late http.Request request;
      final repository = repositoryFor((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 8,
                'name': 'Apresuntado',
                'unit': 'kg',
                'canonical_stem': 'tijolo',
              },
            ],
            'page': {'page': 1, 'limit': 20, 'total': 1, 'total_pages': 1},
          }),
          200,
        );
      });

      final result = await repository.search(
        q: 'apresuntado',
        page: 1,
        limit: 20,
      );

      expect(request.method, 'GET');
      expect(
        request.url.toString(),
        'https://api.example.com/api/v1/admin/products?q=apresuntado&page=1&limit=20',
      );
      expect(result.items.single.id, 8);
      expect(result.items.single.name, 'Apresuntado');
      expect(result.items.single.canonicalStem, 'tijolo');
      expect(result.page?.totalPages, 1);
    },
  );

  test('reviewPriceLog posts an approval decision', () async {
    late http.Request request;
    final repository = repositoryFor((incoming) async {
      request = incoming;
      return http.Response(
        jsonEncode({'id': 42, 'name': 'Arroz', 'unit': 'kg'}),
        200,
      );
    });

    final result = await repository.reviewPriceLog(
      priceLogId: 42,
      action: PriceLogReviewAction.approve,
    );

    expect(request.method, 'POST');
    expect(
      request.url.toString(),
      'https://api.example.com/api/v1/admin/products/price-logs/42/review',
    );
    expect(jsonDecode(request.body), {'action': 'approve'});
    expect(result.id, 42);
    expect(result.name, 'Arroz');
  });

  test('reviewPriceLog posts a rejection decision', () async {
    late http.Request request;
    final repository = repositoryFor((incoming) async {
      request = incoming;
      return http.Response('{}', 200);
    });

    await repository.reviewPriceLog(
      priceLogId: 7,
      action: PriceLogReviewAction.reject,
    );

    expect(jsonDecode(request.body), {'action': 'reject'});
  });

  test('findUser gets one account and caches the result', () async {
    var requests = 0;
    final repository = repositoryFor((incoming) async {
      requests++;
      expect(incoming.method, 'GET');
      expect(
        incoming.url.toString(),
        'https://api.example.com/api/v1/admin/user/7',
      );
      return http.Response(
        jsonEncode({
          'id': 7,
          'name': 'Ada',
          'email': 'ada@example.com',
          'role': 'admin',
        }),
        200,
      );
    });

    final first = await repository.findUser(7);
    final second = await repository.findUser(7);

    expect(first?.name, 'Ada');
    expect(first?.role, UserRole.admin);
    expect(second?.name, 'Ada');
    expect(requests, 1);
  });

  test('findUser returns null when the account no longer exists', () async {
    final repository = repositoryFor(
      (_) async => http.Response(
        jsonEncode({
          'error': {'code': 'not_found', 'message': 'User not found'},
        }),
        404,
      ),
    );

    expect(await repository.findUser(99), isNull);
  });

  test('findUser shares one request across concurrent lookups', () async {
    final gate = Completer<void>();
    var requests = 0;
    final repository = repositoryFor((_) async {
      requests++;
      await gate.future;
      return http.Response(
        jsonEncode({'id': 3, 'name': 'Grace', 'email': 'grace@example.com'}),
        200,
      );
    });

    final lookups = [repository.findUser(3), repository.findUser(3)];
    gate.complete();
    final users = await Future.wait(lookups);

    expect(requests, 1);
    expect(users.every((user) => user?.id == 3), isTrue);
  });

  test('findUser surfaces typed failures', () async {
    final repository = repositoryFor(
      (_) async => http.Response(
        jsonEncode({
          'error': {'code': 'internal_error', 'message': 'boom'},
        }),
        500,
      ),
    );

    await expectLater(repository.findUser(1), throwsA(isA<ApiException>()));
  });
}
