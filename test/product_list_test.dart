import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/products/widgets/product_list.dart';
import 'package:meu_preco_frontend/features/products/widgets/product_result_tile.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';

void main() {
  group('ProductList Widget Tests', () {
    final mockProducts = [
      const ProductView(
        id: 1,
        name: 'Test Product 1',
        brand: 'Brand A',
        unit: 'kg',
      ),
      const ProductView(
        id: 2,
        name: 'Test Product 2',
        brand: 'Brand B',
        unit: 'Liters',
      ),
    ];

    testWidgets('renders products with correct details and layout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProductList(
              products: mockProducts,
              onProductSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Test Product 1'), findsOneWidget);
      expect(find.text('Brand A'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));

      await tester.pump(); // Ensure layout is settled
    });

    testWidgets('exposes correct semantic labels for accessibility', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProductList(
              products: mockProducts,
              onProductSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Test Product 1 - kg'), findsOneWidget);
      expect(find.bySemanticsLabel('Test Product 2 - Liters'), findsOneWidget);
    });

    testWidgets('calls onProductSelected with correct product when tapped', (
      WidgetTester tester,
    ) async {
      ProductView? selectedProduct;
      var selectionCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProductList(
              products: mockProducts,
              onProductSelected: (product) {
                selectedProduct = product;
                selectionCount++;
              },
            ),
          ),
        ),
      );

      // Tap the first item in the list
      final finder = find.byType(ProductResultTile).first;
      await tester.tap(finder);
      await tester.pump();

      expect(selectedProduct, equals(mockProducts[0]));
      expect(selectionCount, 1);
    });

    testWidgets('uses stable product-id keys for list rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProductList(
              products: mockProducts,
              onProductSelected: (_) {},
            ),
          ),
        ),
      );

      final tiles = tester
          .widgetList<ProductResultTile>(find.byType(ProductResultTile))
          .toList();
      expect(tiles[0].key, const ValueKey('prod-1'));
      expect(tiles[1].key, const ValueKey('prod-2'));
    });

    testWidgets('falls back to a deterministic key when the id is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProductList(
              products: const [
                ProductView(name: 'Sem id', brand: 'Marca', unit: 'kg'),
              ],
              onProductSelected: (_) {},
            ),
          ),
        ),
      );

      final tile = tester.widget<ProductResultTile>(
        find.byType(ProductResultTile),
      );
      expect(tile.key, const ValueKey('prod-fallback-Sem id-Marca'));
    });

    testWidgets('renders trailingBuilder content', (WidgetTester tester) async {
      final customTrailing = const Icon(Icons.check);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProductList(
              products: mockProducts,
              onProductSelected: (_) {},
              trailingBuilder: (product) =>
                  (product == mockProducts[0]) ? customTrailing : null,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('renders loading-more footer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProductList(
              products: mockProducts,
              onProductSelected: (_) {},
              isLoadingMore: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Product 1'), findsOneWidget);
      expect(find.text('Test Product 2'), findsOneWidget);
    });

    testWidgets('handles long text without overflow', (
      WidgetTester tester,
    ) async {
      final longName =
          'This is a very long product name that should definitely exceed the width of most standard mobile screens and be truncated correctly by the UI';
      final productsWithLongNames = [
        ProductView(id: 3, name: longName, brand: 'Brand C', unit: 'pcs'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 200, // Constrain width to force overflow/truncation
              child: ProductList(
                products: productsWithLongNames,
                onProductSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('This is a very long'), findsOneWidget);
    });

    testWidgets('applies selection styling when selectedProductId matches', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProductList(
              products: mockProducts,
              onProductSelected: (_) {},
              selectedProductId: 1, // Match first product ID
            ),
          ),
        ),
      );

      final containers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(containers, hasLength(2));
      expect((containers[0].decoration! as BoxDecoration).color, isNotNull);
      expect((containers[1].decoration! as BoxDecoration).color, isNull);
    });

    testWidgets('does not dispose an externally supplied scroll controller', (
      tester,
    ) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProductList(
              products: mockProducts,
              controller: controller,
              onProductSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());

      expect(() => controller.dispose(), returnsNormally);
    });
  });
}
