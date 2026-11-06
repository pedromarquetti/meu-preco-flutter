import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/features/products/product_detail_screen.dart';
import 'package:meu_preco_frontend/features/products/widgets/product_list.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/app/app.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/config/app_config_controller.dart';
import 'package:meu_preco_frontend/core/storage/credential_store.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';
import 'helpers.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

void _ignoreSelection(ProductView product) {}

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

void main() {
  testWidgets('ProductDetailScreen does not overflow at large text scale', (
    tester,
  ) async {
    final repository = FakeProductRepository()
      ..detailResult = ProductView(
        id: 1,
        name: 'Produto com nome muito longo para testar overflow',
        brand: 'Marca Longa',
        gtin: '7891234567890',
        unit: 'unidade',
      )
      ..historyResult = ProductHistory(
        product: ProductView(
          id: 1,
          name: 'Produto com nome muito longo para testar overflow',
          brand: 'Marca Longa',
        ),
        points: [
          PricePointView(
            line: 10,
            pricePerUnit: Decimal.parse('9999.99'),
            unit: 'kg',
            supermarket: SupermarketRef(
              id: 1,
              cnpj: '12345678000199',
              legalName: 'Supermercado com Nome Muito Longo Ltda',
            ),
            qty: Decimal.parse('1'),
            totalPrice: Decimal.parse('999.99'),
            loggedAt: DateTime(2025, 1, 15),
          ),
        ],
        aggregate: [],
      );

    // Pump with large text scale
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.view.platformDispatcher.textScaleFactorTestValue = 2.5;
    addTearDown(tester.view.reset);

    await pumpScreen(
      tester,
      const ProductDetailScreen(productId: '1'),
      repository: repository,
    );

    // Verify no overflow exceptions by pumping and settling
    await tester.pumpAndSettle();

    // Key elements should be present
    expect(
      find.text('Produto com nome muito longo para testar overflow'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Supermercado com Nome Muito Longo'),
      findsOneWidget,
    );
  });

  testWidgets(
    'ProductList does not overflow on a narrow screen at large text scale',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      tester.view.platformDispatcher.textScaleFactorTestValue = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: ProductList(
              products: [
                ProductView(
                  id: 1,
                  name:
                      'Produto com um nome extremamente longo para testar o '
                      'comportamento de quebra de linha',
                  brand: 'Marca com nome longo',
                  unit: 'kg',
                ),
              ],
              onProductSelected: _ignoreSelection,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('extrema'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home screen scrolls at large text scale', (tester) async {
    final credStore = InMemoryCredentialStore();
    await credStore.write(
      StoredSession(
        accessToken: 'token',
        refreshToken: 'refresh',
        user: User(id: 1, name: 'Test', email: 't@t.com', role: UserRole.user),
      ),
    );
    final keyValueStore = InMemoryKeyValueStore();
    await keyValueStore.writeString(
      AppConfigController.apiOriginKey,
      'https://api.example.com',
    );
    final deps = buildTestDependencies(
      credentialStore: credStore,
      store: keyValueStore,
    );
    deps.serverGate = null;
    await deps.authSession.restore();

    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.view.platformDispatcher.textScaleFactorTestValue = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MeuPrecoApp(dependencies: deps));
    await tester.pumpAndSettle();

    // Should render without overflow
    expect(find.text(_strings.homeTitle), findsOneWidget);
    expect(find.text(_strings.searchProductAction), findsOneWidget);
  });
}
