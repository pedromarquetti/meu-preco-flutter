import 'dart:async';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/app/router.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/core/ui/loading_view.dart';
import 'package:meu_preco_frontend/features/admin/admin_products_screen.dart';
import 'package:meu_preco_frontend/features/products/product_detail_screen.dart';
import 'package:meu_preco_frontend/features/products/product_search_controller.dart';
import 'package:meu_preco_frontend/features/products/product_search_screen.dart';
import 'package:meu_preco_frontend/features/products/widgets/product_list.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';
import 'helpers.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

Future<void> pumpScreen(
  WidgetTester tester,
  Widget home, {
  required FakeProductRepository repository,
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final dependencies = buildTestDependencies(productsRepository: repository);
  await tester.pumpWidget(
    Provider<AppDependencies>.value(
      value: dependencies,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

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

void main() {
  group('ProductSearchScreen', () {
    testWidgets('prompts before any query', (tester) async {
      final repository = FakeProductRepository();
      await pumpScreen(
        tester,
        const ProductSearchScreen(),
        repository: repository,
      );

      expect(find.text(_strings.productSearchPrompt), findsOneWidget);
      expect(repository.searchCalls, 0);
    });

    testWidgets('debounces input and lists matching products', (tester) async {
      final repository = FakeProductRepository()
        ..searchResult = pageOf([
          sampleProduct(id: 1, name: 'Arroz Tipo 1 5kg'),
          sampleProduct(id: 2, name: 'Arroz Integral'),
        ]);
      await pumpScreen(
        tester,
        const ProductSearchScreen(),
        repository: repository,
      );

      await tester.enterText(find.byType(TextField), 'arroz');
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Arroz Tipo 1 5kg'), findsOneWidget);
      expect(find.text('Arroz Integral'), findsOneWidget);
      expect(repository.searchRequests.single.q, 'arroz');
      expect(find.byType(ProductList), findsOneWidget);
    });

    testWidgets('shows the parent-owned loading state before the first reply', (
      tester,
    ) async {
      final pending = Completer<ProductPage>();
      final repository = FakeProductRepository()
        ..searchHandler = (_, _) => pending.future;
      await pumpScreen(
        tester,
        const ProductSearchScreen(),
        repository: repository,
      );

      await tester.enterText(find.byType(TextField), 'arroz');
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.byType(ProductList), findsNothing);

      pending.complete(pageOf([sampleProduct(name: 'Arroz Tipo 1 5kg')]));
      await tester.pumpAndSettle();

      expect(find.byType(LoadingView), findsNothing);
      expect(find.byType(ProductList), findsOneWidget);
    });

    testWidgets('shows the empty state when nothing matches', (tester) async {
      final repository = FakeProductRepository()..searchResult = pageOf([]);
      await pumpScreen(
        tester,
        const ProductSearchScreen(),
        repository: repository,
      );

      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text(_strings.productSearchNoResults), findsOneWidget);
      expect(find.byType(ProductList), findsNothing);
    });

    testWidgets('shows an error and recovers on retry', (tester) async {
      final repository = FakeProductRepository()
        ..searchError = const ServerException(message: 'boom');
      await pumpScreen(
        tester,
        const ProductSearchScreen(),
        repository: repository,
      );

      await tester.enterText(find.byType(TextField), 'arroz');
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text(_strings.networkErrorMessage), findsOneWidget);
      expect(find.byType(ProductList), findsNothing);
      expect(repository.searchRequests.single.q, 'arroz');

      repository
        ..searchError = null
        ..searchResult = pageOf([sampleProduct(name: 'Arroz Tipo 1 5kg')]);
      await tester.tap(find.widgetWithText(FilledButton, _strings.retryAction));
      await tester.pumpAndSettle();

      expect(find.text('Arroz Tipo 1 5kg'), findsOneWidget);
      expect(repository.searchRequests, hasLength(2));
      expect(repository.searchRequests.last.q, 'arroz');
    });

    testWidgets('opens product detail for the clicked product', (tester) async {
      final product = sampleProduct(id: 7, name: 'Café Torrado');
      final repository = FakeProductRepository()
        ..searchResult = pageOf([product])
        ..detailResult = product
        ..historyResult = sampleHistory(product: product);

      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final dependencies = buildTestDependencies(
        productsRepository: repository,
      );
      final router = GoRouter(
        initialLocation: AppRoutes.productSearch,
        routes: [
          GoRoute(
            path: AppRoutes.productSearch,
            builder: (_, _) => const ProductSearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.productDetail,
            builder: (_, state) => ProductDetailScreen(
              productId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        Provider<AppDependencies>.value(
          value: dependencies,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'cafe');
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Café Torrado'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(repository.historyRequests.single.id, 7);
    });

    testWidgets('does not dispose an externally owned search controller', (
      tester,
    ) async {
      final repository = FakeProductRepository();
      final controller = ProductSearchController(repository: repository);
      await pumpScreen(
        tester,
        ProductSearchScreen(controller: controller),
        repository: repository,
      );

      await tester.pumpWidget(const SizedBox.shrink());

      expect(() => controller.addListener(() {}), returnsNormally);
      controller.dispose();
    });
  });

  group('ProductDetailScreen', () {
    testWidgets('renders header, chart, aggregates, and history', (
      tester,
    ) async {
      final repository = FakeProductRepository()
        ..historyResult = sampleHistory(
          points: [
            samplePricePoint(price: '4.99', loggedAt: DateTime(2025, 1, 10)),
            samplePricePoint(price: '5.49', loggedAt: DateTime(2025, 2, 10)),
          ],
        );
      await pumpScreen(
        tester,
        const ProductDetailScreen(productId: '7'),
        repository: repository,
      );

      expect(find.text('Arroz Tipo 1 5kg'), findsOneWidget);
      expect(find.text(_strings.productPriceGraphLabel), findsOneWidget);
      expect(find.text(_strings.productAggregateTitle), findsOneWidget);
      expect(find.text('kg'), findsWidgets);
      expect(find.textContaining('Mercado Central'), findsWidgets);
      expect(find.textContaining('10/01/2025'), findsOneWidget);
      expect(repository.historyRequests.single.id, 7);
    });

    testWidgets('shows a placeholder when there are too few points', (
      tester,
    ) async {
      final repository = FakeProductRepository()
        ..historyResult = sampleHistory(points: [samplePricePoint()]);
      await pumpScreen(
        tester,
        const ProductDetailScreen(productId: '7'),
        repository: repository,
      );

      expect(find.text(_strings.priceChartTooShort), findsOneWidget);
    });

    testWidgets('reports an invalid product id', (tester) async {
      final repository = FakeProductRepository();
      await pumpScreen(
        tester,
        const ProductDetailScreen(productId: 'not-a-number'),
        repository: repository,
      );

      expect(find.text(_strings.productNotFound), findsOneWidget);
      expect(repository.historyCalls, 0);
    });

    testWidgets('retries a failed history load', (tester) async {
      final repository = FakeProductRepository()
        ..historyError = const ServerException(message: 'falhou');
      await pumpScreen(
        tester,
        const ProductDetailScreen(productId: '7'),
        repository: repository,
      );

      expect(find.text(_strings.networkErrorMessage), findsWidgets);

      repository
        ..historyError = null
        ..historyResult = sampleHistory();
      await tester.tap(find.widgetWithText(FilledButton, _strings.retryAction));
      await tester.pumpAndSettle();

      expect(find.text('Arroz Tipo 1 5kg'), findsOneWidget);
      expect(find.text(_strings.networkErrorMessage), findsNothing);
    });
  });

  group('AdminProductsScreen', () {
    testWidgets('renders search input and empty state initially', (
      tester,
    ) async {
      final repository = FakeProductRepository();
      await pumpScreen(
        tester,
        const Scaffold(body: AdminProductsScreen()),
        repository: repository,
      );

      expect(find.text(_strings.searchProductAction), findsOneWidget);
    });

    testWidgets('populates editor fields when a product is selected', (
      tester,
    ) async {
      final repository = FakeProductRepository()
        ..searchResult = pageOf([
          sampleProduct(
            id: 1,
            name: 'Test Product Name',
            brand: 'Brand X',
            unit: 'Unit Y',
          ),
        ]);

      await pumpScreen(
        tester,
        const Scaffold(body: AdminProductsScreen()),
        repository: repository,
      );

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Product Name'));
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextField>(
        find.widgetWithText(TextField, _strings.nameLabel),
      );
      final brandField = tester.widget<TextField>(
        find.widgetWithText(TextField, _strings.productBrandLabel),
      );
      final unitField = tester.widget<TextField>(
        find.widgetWithText(TextField, _strings.productUnitLabel),
      );

      expect(nameField.controller?.text, 'Test Product Name');
      expect(brandField.controller?.text, 'Brand X');
      expect(unitField.controller?.text, 'Unit Y');
    });
  });
}
