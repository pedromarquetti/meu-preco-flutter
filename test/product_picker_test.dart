import 'dart:async';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/nfce/widgets/product_picker_sheet.dart';
import 'package:meu_preco_frontend/features/products/widgets/product_list.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';
import 'helpers.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

ProductPage pageOf(
  List<ProductView> items, {
  int page = 1,
  int totalPages = 1,
}) => ProductPage(
  items: items,
  page: Page(
    page: page,
    limit: 20,
    total: items.length,
    totalPages: totalPages,
  ),
);

Future<void> pumpPickerHost(
  WidgetTester tester, {
  required FakeProductRepository repository,
  required void Function(ProductView?) onResult,
}) async {
  tester.view.physicalSize = const Size(900, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final dependencies = buildTestDependencies(productsRepository: repository);
  await tester.pumpWidget(
    Provider<AppDependencies>.value(
      value: dependencies,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  onResult(
                    await showProductPickerSheet(
                      context,
                      initialQuery: 'arroz',
                    ),
                  );
                },
                child: const Text('open picker'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openPicker(WidgetTester tester) async {
  await tester.tap(find.text('open picker'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('uses the initial query and returns the selected product', (
    tester,
  ) async {
    final repository = FakeProductRepository()
      ..searchResult = pageOf([
        sampleProduct(id: 5, name: 'Café Especial', brand: 'Torrefação'),
      ]);
    ProductView? result;

    await pumpPickerHost(
      tester,
      repository: repository,
      onResult: (product) => result = product,
    );
    await openPicker(tester);

    expect(find.text('Café Especial'), findsOneWidget);
    expect(repository.searchRequests.single.q, 'arroz');

    await tester.tap(find.text('Café Especial'));
    await tester.pumpAndSettle();

    expect(result?.id, 5);
    expect(find.byType(ProductList), findsNothing);
  });

  testWidgets('retry re-runs the active picker query', (tester) async {
    final repository = FakeProductRepository()
      ..searchError = const ServerException(message: 'boom');
    ProductView? result;

    await pumpPickerHost(
      tester,
      repository: repository,
      onResult: (product) => result = product,
    );
    await openPicker(tester);

    expect(find.text(_strings.networkErrorMessage), findsOneWidget);

    repository
      ..searchError = null
      ..searchResult = pageOf([sampleProduct(id: 9, name: 'Café Retry')]);
    await tester.tap(find.widgetWithText(FilledButton, _strings.retryAction));
    await tester.pumpAndSettle();

    expect(find.text('Café Retry'), findsOneWidget);
    expect(repository.searchRequests, hasLength(2));
    expect(repository.searchRequests.last.q, 'arroz');

    await tester.tap(find.text('Café Retry'));
    await tester.pumpAndSettle();

    expect(result?.id, 9);
  });

  testWidgets('shows the loading-more footer without replacing results', (
    tester,
  ) async {
    final pending = Completer<ProductPage>();
    final firstPage = List.generate(
      20,
      (index) => sampleProduct(id: index + 1, name: 'Produto ${index + 1}'),
    );
    final repository = FakeProductRepository()
      ..searchHandler = (page, _) =>
          page == 1 ? pageOf(firstPage, totalPages: 2) : pending.future;
    ProductView? result;

    await pumpPickerHost(
      tester,
      repository: repository,
      onResult: (product) => result = product,
    );
    await openPicker(tester);

    expect(find.text('Produto 1'), findsOneWidget);

    await tester.drag(find.byType(ProductList), const Offset(0, -2000));
    await tester.pump();

    expect(repository.searchRequests, hasLength(2));
    expect(repository.searchRequests.last.page, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Produto 20'), findsOneWidget);

    pending.complete(
      pageOf(
        [sampleProduct(id: 99, name: 'Produto Extra')],
        page: 2,
        totalPages: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.drag(find.byType(ProductList), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Produto Extra'), findsOneWidget);
    expect(result, isNull);
  });
}
