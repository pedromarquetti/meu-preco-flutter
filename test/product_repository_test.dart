import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_preco_frontend/core/config/app_config.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/http/api_client.dart';
import 'package:meu_preco_frontend/features/products/data/product_repository.dart';

import 'fakes.dart';

void main() {
  ApiProductRepository repositoryWith(
    Future<http.Response> Function(http.Request) handler,
  ) {
    return ApiProductRepository(
      client: ApiClient(
        configProvider: () =>
            AppConfig.tryFromOrigin('https://api.example.com')!,
        httpClient: MockClient(handler),
      ),
    );
  }

  group('search', () {
    test('sends query filters and pagination, then parses the page', () async {
      late Uri uri;
      final repository = repositoryWith((request) async {
        uri = request.url;
        return http.Response(
          jsonEncode({
            'items': [sampleProduct().toJson()],
            'page': {'page': 2, 'limit': 5, 'total': 6, 'total_pages': 2},
          }),
          200,
        );
      });

      final page = await repository.search(
        q: 'arroz',
        gtin: '789',
        unit: 'kg',
        brand: 'Boa',
        page: 2,
        limit: 5,
      );

      expect(uri.path, '/api/v1/products');
      expect(uri.queryParameters, {
        'q': 'arroz',
        'gtin': '789',
        'unit': 'kg',
        'brand': 'Boa',
        'page': '2',
        'limit': '5',
      });
      expect(page.items.single.name, 'Arroz Tipo 1 5kg');
      expect(page.page?.page, 2);
      expect(page.page?.totalPages, 2);
    });

    test('omits empty filters but always sends page and limit', () async {
      late Uri uri;
      final repository = repositoryWith((request) async {
        uri = request.url;
        return http.Response(
          jsonEncode({
            'items': <Object>[],
            'page': {'page': 1},
          }),
          200,
        );
      });

      await repository.search(q: '', gtin: null, unit: '', brand: null);

      expect(uri.queryParameters, {'page': '1', 'limit': '20'});
    });
  });

  group('detail', () {
    test('parses a single product', () async {
      late Uri uri;
      final repository = repositoryWith((request) async {
        uri = request.url;
        return http.Response(jsonEncode(sampleProduct(id: 7).toJson()), 200);
      });

      final product = await repository.detail(7);

      expect(uri.path, '/api/v1/products/7');
      expect(product.id, 7);
    });
  });

  group('history', () {
    test('formats range bounds as yyyy-MM-dd', () async {
      late Uri uri;
      final repository = repositoryWith((request) async {
        uri = request.url;
        return http.Response(jsonEncode(sampleHistory().toJson()), 200);
      });

      final history = await repository.history(
        3,
        from: DateTime(2025, 1, 5),
        to: DateTime(2025, 12, 9),
      );

      expect(uri.path, '/api/v1/products/3/history');
      expect(uri.queryParameters, {'from': '2025-01-05', 'to': '2025-12-09'});
      expect(history.points, hasLength(2));
    });

    test('omits missing range bounds', () async {
      late Uri uri;
      final repository = repositoryWith((request) async {
        uri = request.url;
        return http.Response(jsonEncode(sampleHistory().toJson()), 200);
      });

      await repository.history(3);

      expect(uri.queryParameters, isEmpty);
    });
  });

  test('rejects non-object payloads', () async {
    final repository = repositoryWith(
      (request) async => http.Response(jsonEncode(<Object>[]), 200),
    );

    expect(
      () => repository.search(q: 'x'),
      throwsA(isA<SerializationException>()),
    );
  });
}
