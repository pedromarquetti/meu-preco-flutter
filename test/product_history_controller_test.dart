import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/features/products/product_history_controller.dart';

import 'fakes.dart';

void main() {
  late FakeProductRepository repository;

  setUp(() {
    repository = FakeProductRepository();
  });

  ProductHistoryController build({int productId = 7}) {
    final controller = ProductHistoryController(
      repository: repository,
      productId: productId,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('loads the product and sorts points oldest-first', () async {
    repository.historyResult = sampleHistory(
      product: sampleProduct(id: 7),
      points: [
        samplePricePoint(
          price: '6.00',
          issuedAt: DateTime.utc(2025, 3),
          loggedAt: DateTime.utc(2025, 3, 2),
        ),
        samplePricePoint(
          price: '4.00',
          issuedAt: DateTime.utc(2025, 1),
          loggedAt: DateTime.utc(2025, 1, 2),
        ),
        samplePricePoint(
          price: '5.00',
          issuedAt: DateTime.utc(2025, 2),
          loggedAt: DateTime.utc(2025, 2, 2),
        ),
      ],
    );
    final controller = build();

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
    expect(controller.product?.id, 7);
    expect(controller.points.map((point) => point.pricePerUnit?.amount), [
      '4.00',
      '5.00',
      '6.00',
    ]);
    expect(controller.aggregate.single.unit, 'kg');
    expect(repository.historyRequests.single.id, 7);
    expect(repository.historyRequests.single.from, isNull);
    expect(repository.historyRequests.single.to, isNull);
  });

  test('passes a selected range through and remembers it', () async {
    final controller = build();
    final from = DateTime(2025, 1, 1);
    final to = DateTime(2025, 6, 30);

    await controller.load(from: from, to: to);

    expect(repository.historyRequests.last.from, from);
    expect(repository.historyRequests.last.to, to);
    expect(controller.from, from);
    expect(controller.to, to);
  });

  test('rejects an inverted range without calling the API', () async {
    final controller = build();

    await controller.load(from: DateTime(2025, 6, 1), to: DateTime(2025, 1, 1));

    expect(repository.historyCalls, 0);
    expect(controller.error, isA<ValidationException>());
    expect(controller.error?.code, 'invalid_date_range');
    expect(controller.isLoading, isFalse);
  });

  test('clearRange reloads without bounds', () async {
    final controller = build();
    await controller.load(
      from: DateTime(2025, 1, 1),
      to: DateTime(2025, 6, 30),
    );
    repository.historyCalls = 0;

    await controller.clearRange();

    expect(controller.from, isNull);
    expect(controller.to, isNull);
    expect(repository.historyRequests.last.from, isNull);
    expect(repository.historyRequests.last.to, isNull);
  });

  test('surfaces failures and recovers on retry', () async {
    repository.historyError = const ServerException(message: 'boom');
    final controller = build();

    await controller.load();

    expect(controller.error, isA<ServerException>());
    expect(controller.points, isEmpty);
    expect(controller.isLoading, isFalse);

    repository.historyError = null;
    repository.historyResult = sampleHistory();
    await controller.load();

    expect(controller.error, isNull);
    expect(controller.points, isNotEmpty);
  });
}
