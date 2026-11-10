import 'dart:async';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
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
  FakeAdminRepository? adminRepository,
}) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final dependencies = buildTestDependencies(
    productsRepository: repository,
    adminRepository: adminRepository,
  );
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

Finder _blockField(int index) => find.descendant(
  of: find.byType(ProductSearchBlock).at(index),
  matching: find.byType(TextField),
);

Future<void> selectInBlock(
  WidgetTester tester, {
  required int block,
  required String query,
  required String productName,
}) async {
  await search(tester, _blockField(block), query);
  await tester.tap(
    find
        .descendant(
          of: find.byType(ProductSearchBlock).at(block),
          matching: find.text(productName),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> openMergeConfirmation(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, _strings.confirmAction));
  await tester.pumpAndSettle();
}

Future<void> confirmMergeDialog(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, _strings.confirmAction),
    ),
  );
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

    testWidgets('shows a loading indicator while a search is in flight', (
      tester,
    ) async {
      final pending = Completer<ProductPage>();
      final repository = FakeProductRepository()
        ..searchHandler = (_, _) => pending.future;

      await pumpAdminWidget(
        tester,
        Scaffold(
          body: SizedBox(
            height: 900,
            child: ProductSearchBlock(onProductSelected: (_) {}),
          ),
        ),
        repository: repository,
      );

      await tester.enterText(find.byType(TextField), 'cafe');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete(pageOf([sampleProduct(id: 11, name: 'Café')]));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Café'), findsOneWidget);
    });

    testWidgets('shows the empty prompt when a search returns no products', (
      tester,
    ) async {
      final repository = FakeProductRepository()
        ..searchHandler = (_, query) async =>
            pageOf([if (query == 'cafe') sampleProduct(id: 11, name: 'Café')]);

      await pumpAdminWidget(
        tester,
        Scaffold(
          body: SizedBox(
            height: 900,
            child: ProductSearchBlock(onProductSelected: (_) {}),
          ),
        ),
        repository: repository,
      );

      await search(tester, find.byType(TextField), 'cafe');
      expect(find.text('Café'), findsOneWidget);

      await search(tester, find.byType(TextField), 'inexistente');

      expect(find.text(_strings.productSearchPrompt), findsOneWidget);
    });

    testWidgets('shows a retryable error and recovers on retry', (
      tester,
    ) async {
      final repository = FakeProductRepository()
        ..searchError = const NetworkException();

      await pumpAdminWidget(
        tester,
        Scaffold(
          body: SizedBox(
            height: 900,
            child: ProductSearchBlock(onProductSelected: (_) {}),
          ),
        ),
        repository: repository,
      );

      await search(tester, find.byType(TextField), 'cafe');

      expect(find.text(_strings.retryAction), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      repository
        ..searchError = null
        ..searchResult = pageOf([sampleProduct(id: 11, name: 'Café')]);

      await tester.tap(find.text(_strings.retryAction));
      await tester.pumpAndSettle();

      expect(repository.searchCalls, 2);
      expect(find.text('Café'), findsOneWidget);
      expect(find.text(_strings.retryAction), findsNothing);
    });

    testWidgets('clears the current selection through the clear action', (
      tester,
    ) async {
      final repository = FakeProductRepository()
        ..searchResult = pageOf([sampleProduct(id: 11, name: 'Café Especial')]);
      ProductView? selected;

      await pumpAdminWidget(
        tester,
        Scaffold(
          body: SizedBox(
            height: 900,
            child: ProductSearchBlock(
              onProductSelected: (product) => selected = product,
            ),
          ),
        ),
        repository: repository,
      );

      await search(tester, find.byType(TextField), 'cafe');
      await tester.tap(find.text('Café Especial').first);
      await tester.pumpAndSettle();

      expect(selected?.id, 11);
      expect(find.text(_strings.selected), findsOneWidget);

      await tester.tap(find.byTooltip(_strings.adminClearSelection));
      await tester.pumpAndSettle();

      expect(selected, isNull);
      expect(find.text(_strings.selected), findsNothing);
    });
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

    testWidgets('disables the merge action for the same product', (
      tester,
    ) async {
      final repository = FakeProductRepository()
        ..searchResult = pageOf([sampleProduct(id: 1, name: 'Produto Único')]);
      final adminRepository = FakeAdminRepository();

      await pumpAdminWidget(
        tester,
        const MergeProductsScreen(),
        repository: repository,
        adminRepository: adminRepository,
      );

      await selectInBlock(
        tester,
        block: 0,
        query: 'produto',
        productName: 'Produto Único',
      );
      await selectInBlock(
        tester,
        block: 1,
        query: 'produto',
        productName: 'Produto Único',
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, _strings.confirmAction),
      );
      expect(button.onPressed, isNull);
      expect(adminRepository.mergeCalls, isEmpty);
    });

    testWidgets('confirms with product names before merging and resets', (
      tester,
    ) async {
      final repository = FakeProductRepository()
        ..searchHandler = (_, query) async => pageOf([
          if (query == 'origem')
            sampleProduct(id: 1, name: 'Produto Origem')
          else
            sampleProduct(id: 2, name: 'Produto Destino'),
        ]);
      final adminRepository = FakeAdminRepository()
        ..mergeResult = const MergeResult(
          fromId: 1,
          toId: 2,
          logsMoved: 3,
          dupRemoved: false,
        );

      await pumpAdminWidget(
        tester,
        const MergeProductsScreen(),
        repository: repository,
        adminRepository: adminRepository,
      );

      await selectInBlock(
        tester,
        block: 0,
        query: 'origem',
        productName: 'Produto Origem',
      );
      await selectInBlock(
        tester,
        block: 1,
        query: 'destino',
        productName: 'Produto Destino',
      );

      await openMergeConfirmation(tester);

      expect(
        find.text(
          _strings.mergeConfirmDetail('Produto Origem', 'Produto Destino'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, _strings.cancelAction),
        ),
      );
      await tester.pumpAndSettle();

      expect(adminRepository.mergeCalls, isEmpty);

      await openMergeConfirmation(tester);
      await confirmMergeDialog(tester);

      expect(adminRepository.mergeCalls, hasLength(1));
      expect(adminRepository.mergeCalls.single.fromId, 1);
      expect(adminRepository.mergeCalls.single.toId, 2);
      expect(find.textContaining(_strings.mergeSuccess), findsOneWidget);
      expect(find.textContaining('3 ${_strings.movedItems}'), findsOneWidget);
      expect(find.text(_strings.selected), findsNothing);
    });

    testWidgets('keeps selections after a failure so the merge can retry', (
      tester,
    ) async {
      final repository = FakeProductRepository()
        ..searchHandler = (_, query) async => pageOf([
          if (query == 'origem')
            sampleProduct(id: 1, name: 'Produto Origem')
          else
            sampleProduct(id: 2, name: 'Produto Destino'),
        ]);
      final adminRepository = FakeAdminRepository()
        ..mergeError = const NetworkException();

      await pumpAdminWidget(
        tester,
        const MergeProductsScreen(),
        repository: repository,
        adminRepository: adminRepository,
      );

      await selectInBlock(
        tester,
        block: 0,
        query: 'origem',
        productName: 'Produto Origem',
      );
      await selectInBlock(
        tester,
        block: 1,
        query: 'destino',
        productName: 'Produto Destino',
      );

      await openMergeConfirmation(tester);
      await confirmMergeDialog(tester);

      expect(adminRepository.mergeCalls, hasLength(1));
      expect(find.text(_strings.mergeFailed), findsOneWidget);
      expect(find.text(_strings.selected), findsNWidgets(2));

      // The failure snackbar covers the merge button until it dismisses.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      final retryButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, _strings.confirmAction),
      );
      expect(retryButton.onPressed, isNotNull);

      adminRepository.mergeError = null;
      await openMergeConfirmation(tester);
      await confirmMergeDialog(tester);

      expect(adminRepository.mergeCalls, hasLength(2));
      expect(find.textContaining(_strings.mergeSuccess), findsOneWidget);
      expect(find.text(_strings.selected), findsNothing);
    });

    testWidgets('blocks duplicate submissions while a merge is in flight', (
      tester,
    ) async {
      final repository = FakeProductRepository()
        ..searchHandler = (_, query) async => pageOf([
          if (query == 'origem')
            sampleProduct(id: 1, name: 'Produto Origem')
          else
            sampleProduct(id: 2, name: 'Produto Destino'),
        ]);
      final gate = Completer<void>();
      final adminRepository = FakeAdminRepository()..mergeGate = gate;

      await pumpAdminWidget(
        tester,
        const MergeProductsScreen(),
        repository: repository,
        adminRepository: adminRepository,
      );

      await selectInBlock(
        tester,
        block: 0,
        query: 'origem',
        productName: 'Produto Origem',
      );
      await selectInBlock(
        tester,
        block: 1,
        query: 'destino',
        productName: 'Produto Destino',
      );

      await openMergeConfirmation(tester);
      await confirmMergeDialog(tester);

      expect(adminRepository.mergeCalls, hasLength(1));
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, _strings.confirmAction),
      );
      expect(button.onPressed, isNull);

      gate.complete();
      await tester.pumpAndSettle();

      expect(adminRepository.mergeCalls, hasLength(1));
      expect(find.textContaining(_strings.mergeSuccess), findsOneWidget);
    });
  });
}
