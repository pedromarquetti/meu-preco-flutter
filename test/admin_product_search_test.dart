import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/admin/admin_merge_screen.dart';
import 'package:meu_preco_frontend/features/admin/widgets/product_search_block.dart';
import 'package:meu_preco_frontend/features/products/product_search_controller.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';
import 'helpers.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

ProductPage pageOf(List<ProductView> items, {int totalPages = 1}) =>
    ProductPage(
      items: items,
      page: Page(
        page: 1,
        limit: 20,
        total: items.length,
        totalPages: totalPages,
      ),
    );

Future<void> pumpAdminWidget(
  WidgetTester tester,
  Widget child, {
  required FakeProductRepository repository,
}) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final dependencies = buildTestDependencies(productsRepository: repository);
  await tester.pumpWidget(
    Provider<AppDependencies>.value(
      value: dependencies,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> search(WidgetTester tester, Finder field, String query) async {
  await tester.enterText(field, query);
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

void main() {
  group('ProductSearchBlock', () {
    testWidgets(
      'forwards the selected product and keeps an external controller '
      'alive',
      (tester) async {
        final repository = FakeProductRepository()
          ..searchResult = pageOf([
            sampleProduct(id: 11, name: 'Café Especial'),
          ]);
        final controller = ProductSearchController(repository: repository);
        ProductView? selected;

        await pumpAdminWidget(
          tester,
          Scaffold(
            body: SizedBox(
              height: 900,
              child: ProductSearchBlock(
                controller: controller,
                onProductSelected: (product) => selected = product,
              ),
            ),
          ),
          repository: repository,
        );

        await search(tester, find.byType(TextField), 'cafe');
        await tester.tap(find.text('Café Especial'));
        await tester.pumpAndSettle();

        expect(selected?.id, 11);
        expect(repository.searchRequests.single.q, 'cafe');

        await tester.pumpWidget(const SizedBox.shrink());

        expect(() => controller.addListener(() {}), returnsNormally);
        controller.dispose();
      },
    );
  });

  group('MergeProductsScreen', () {
    testWidgets('receives independent source and target selections', (
      tester,
    ) async {
      final repository = FakeProductRepository()
        ..searchHandler = (_, query) async => pageOf([
          if (query == 'origem')
            sampleProduct(id: 1, name: 'Produto Origem')
          else
            sampleProduct(id: 2, name: 'Produto Destino'),
        ]);

      await pumpAdminWidget(
        tester,
        const MergeProductsScreen(),
        repository: repository,
      );

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));

      await search(tester, fields.at(0), 'origem');
      await tester.tap(find.text('Produto Origem'));
      await tester.pumpAndSettle();

      await search(tester, fields.at(1), 'destino');
      await tester.tap(find.text('Produto Destino'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, _strings.confirmAction),
        findsOneWidget,
      );
      expect(repository.searchRequests, hasLength(2));
      expect(repository.searchRequests[0].q, 'origem');
      expect(repository.searchRequests[1].q, 'destino');
    });
  });
}
