import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/auth/login_screen.dart';
import 'package:meu_preco_frontend/features/products/product_search_screen.dart';
import 'package:meu_preco_frontend/features/products/widgets/product_list.dart';
import 'package:meu_preco_frontend/features/products/widgets/product_result_tile.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

Future<void> pumpWidget(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final dependencies = buildTestDependencies();
  await tester.pumpWidget(
    Provider<AppDependencies>.value(
      value: dependencies,
      child: ChangeNotifierProvider.value(
        value: dependencies.authSession,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('login semantics', () {
    testWidgets('identifier and password fields expose accessible labels', (
      tester,
    ) async {
      await pumpWidget(tester, const LoginScreen());

      expect(
        find.bySemanticsLabel(_strings.loginIdentifierLabel),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(_strings.passwordLabel), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, _strings.signInAction),
        findsOneWidget,
      );
    });

    testWidgets('the primary action meets the 48px minimum touch target', (
      tester,
    ) async {
      await pumpWidget(tester, const LoginScreen());

      final button = tester.getSize(
        find.widgetWithText(FilledButton, _strings.signInAction),
      );
      expect(button.height, greaterThanOrEqualTo(48));
    });

    testWidgets('focus advances through the identifier, password, and button', (
      tester,
    ) async {
      await pumpWidget(tester, const LoginScreen());

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));

      final identifier = tester.widget<EditableText>(
        find.descendant(of: fields.first, matching: find.byType(EditableText)),
      );
      final password = tester.widget<EditableText>(
        find.descendant(of: fields.last, matching: find.byType(EditableText)),
      );

      expect(identifier.focusNode.canRequestFocus, isTrue);
      expect(password.focusNode.canRequestFocus, isTrue);
    });

    testWidgets('renders without overflow at 2.5x text scale', (tester) async {
      await pumpWidget(tester, const LoginScreen(), textScale: 2.5);

      expect(find.text(_strings.loginTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('responsive layouts', () {
    const viewports = <String, Size>{
      'phone': Size(390, 844),
      'tablet': Size(820, 1180),
      'desktop': Size(1440, 900),
    };

    for (final entry in viewports.entries) {
      testWidgets('product search lays out on a ${entry.key}', (tester) async {
        await pumpWidget(
          tester,
          const ProductSearchScreen(),
          size: entry.value,
        );

        expect(find.byType(TextField), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('product search survives 2.5x text scale on a phone', (
      tester,
    ) async {
      await pumpWidget(
        tester,
        const ProductSearchScreen(),
        size: const Size(390, 844),
        textScale: 2.5,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('product result accessibility', () {
    const products = [
      ProductView(id: 1, name: 'Arroz Tipo 1', brand: 'Marca Boa', unit: 'kg'),
    ];

    testWidgets('exposes name and unit semantics with a large touch target', (
      tester,
    ) async {
      await pumpWidget(
        tester,
        Scaffold(
          body: ProductList(products: products, onProductSelected: (_) {}),
        ),
      );

      expect(find.bySemanticsLabel('Arroz Tipo 1 - kg'), findsOneWidget);

      final tileSize = tester.getSize(find.byType(ProductResultTile));
      expect(tileSize.height, greaterThanOrEqualTo(48));
    });

    testWidgets('renders at 2.5x text scale without overflow', (tester) async {
      await pumpWidget(
        tester,
        Scaffold(
          body: ProductList(products: products, onProductSelected: (_) {}),
        ),
        textScale: 2.5,
      );

      expect(find.text('Arroz Tipo 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
