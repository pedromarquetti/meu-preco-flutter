import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/products/product_search_controller.dart';

import 'fakes.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late FakeProductRepository repository;

  setUp(() {
    repository = FakeProductRepository();
  });

  ProductSearchController build({
    Duration debounce = Duration.zero,
    int pageSize = 5,
  }) {
    final controller = ProductSearchController(
      repository: repository,
      debounce: debounce,
      pageSize: pageSize,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  ProductPage pageOf(int page, {int items = 1, int totalPages = 1}) {
    return ProductPage(
      items: [
        for (var index = 0; index < items; index++)
          sampleProduct(id: (page - 1) * items + index + 1),
      ],
      page: Page(page: page, limit: 5, totalPages: totalPages),
    );
  }

  test('debounces rapid typing into a single request', () async {
    repository.searchResult = pageOf(1);
    final controller = build(debounce: const Duration(milliseconds: 40));

    controller.setQuery('a');
    controller.setQuery('ar');
    controller.setQuery('arr');

    expect(repository.searchCalls, 0);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(repository.searchCalls, 1);
    expect(repository.searchRequests.single.q, 'arr');
    expect(repository.searchRequests.single.page, 1);
    expect(repository.searchRequests.single.limit, 5);
    expect(controller.results, hasLength(1));
  });

  test('clearing the query drops results without a request', () async {
    repository.searchResult = pageOf(1);
    final controller = build();
    controller.setQuery('arroz');
    await settle();
    expect(controller.results, isNotEmpty);

    controller.setQuery('   ');
    await settle();

    expect(controller.query, isEmpty);
    expect(controller.results, isEmpty);
    expect(repository.searchCalls, 1);
  });

  test('loadMore appends the next page', () async {
    repository.searchHandler = (page, q) => pageOf(page, totalPages: 3);
    final controller = build();
    controller.setQuery('arroz');
    await settle();
    expect(controller.results, hasLength(1));
    expect(controller.canLoadMore, isTrue);

    await controller.loadMore();

    expect(controller.results, hasLength(2));
    expect(controller.results.last.id, 2);
    expect(controller.pageInfo?.page, 2);
    expect(repository.searchRequests.last.page, 2);
  });

  test('loadMore stops at the last page', () async {
    repository.searchHandler = (page, q) => pageOf(page, totalPages: 1);
    final controller = build();
    controller.setQuery('arroz');
    await settle();

    expect(controller.canLoadMore, isFalse);
    await controller.loadMore();

    expect(repository.searchCalls, 1);
  });

  test('a newer query discards a slower older response', () async {
    final completers = <Completer<ProductPage>>[];
    repository.searchHandler = (page, q) {
      final completer = Completer<ProductPage>();
      completers.add(completer);
      return completer.future;
    };
    final controller = build();

    controller.setQuery('a');
    await settle();
    controller.setQuery('ab');
    await settle();
    expect(completers, hasLength(2));

    completers[1].complete(pageOf(1, items: 1));
    await settle();
    completers[0].complete(
      ProductPage(
        items: [sampleProduct(id: 99)],
        page: const Page(page: 1, totalPages: 1),
      ),
    );
    await settle();

    expect(controller.results.single.id, 1);
    expect(controller.isLoading, isFalse);
  });

  test('surfaces an API error and recovers on retry', () async {
    repository.searchError = const ServerException(message: 'boom');
    final controller = build();
    controller.setQuery('arroz');
    await settle();

    expect(controller.error, isA<ServerException>());
    expect(controller.results, isEmpty);
    expect(controller.isLoading, isFalse);

    repository.searchError = null;
    repository.searchResult = pageOf(1);
    await controller.retry();

    expect(controller.error, isNull);
    expect(controller.results, hasLength(1));
  });
}
