import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/admin/widgets/product_edit_block.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

Future<void> _pumpEditor(WidgetTester tester, ProductEditBlock editor) async {
  tester.view.physicalSize = const Size(600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: editor,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester, int index) {
  final field = tester.widget<TextField>(find.byType(TextField).at(index));
  return field.controller?.text ?? '';
}

void main() {
  group('ProductEditBlock', () {
    testWidgets('seeds fields from the product and shows localized labels', (
      tester,
    ) async {
      const product = ProductView(
        id: 10,
        name: 'Café',
        brand: 'Marca X',
        unit: 'kg',
      );

      await _pumpEditor(
        tester,
        ProductEditBlock(
          initialProduct: product,
          suggestedName: 'Sugestão',
          onChanged: (_) {},
        ),
      );

      expect(_fieldText(tester, 0), 'Café');
      expect(_fieldText(tester, 1), 'Marca X');
      expect(_fieldText(tester, 2), 'kg');
      expect(find.text(_strings.nameLabel), findsOneWidget);
      expect(find.text(_strings.productBrandLabel), findsOneWidget);
      expect(find.text(_strings.productUnitLabel), findsOneWidget);
      expect(
        find.text('${_strings.batchAssignSuggestedName}: Sugestão'),
        findsOneWidget,
      );
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('falls back to the suggested name when no product exists', (
      tester,
    ) async {
      await _pumpEditor(
        tester,
        ProductEditBlock(suggestedName: 'Leite', onChanged: (_) {}),
      );

      expect(_fieldText(tester, 0), 'Leite');
      expect(_fieldText(tester, 1), isEmpty);
      expect(_fieldText(tester, 2), isEmpty);
    });

    testWidgets('emits a draft patch on each field change', (tester) async {
      ProductPatch? latest;
      var calls = 0;

      await _pumpEditor(
        tester,
        ProductEditBlock(
          suggestedName: 'Sugestão',
          onChanged: (patch) {
            latest = patch;
            calls++;
          },
        ),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '  Café  ');
      await tester.pump();

      expect(calls, 1);
      expect(latest?.name, '  Café  ');

      await tester.enterText(fields.at(1), 'Marca X');
      await tester.pump();

      expect(calls, 2);
      expect(latest?.name, '  Café  ');
      expect(latest?.brand, 'Marca X');

      await tester.enterText(fields.at(2), 'kg');
      await tester.pump();

      expect(calls, 3);
      expect(latest?.name, '  Café  ');
      expect(latest?.brand, 'Marca X');
      expect(latest?.unit, 'kg');

      // Edits are applied live; there is no separate apply action.
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('emits cleared optional fields as explicit empty drafts', (
      tester,
    ) async {
      ProductPatch? latest;

      await _pumpEditor(
        tester,
        ProductEditBlock(
          initialProduct: const ProductView(
            id: 10,
            name: 'Café',
            brand: 'Marca X',
            unit: 'kg',
          ),
          onChanged: (patch) => latest = patch,
        ),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '');
      await tester.enterText(fields.at(2), '');
      await tester.pump();

      expect(_fieldText(tester, 1), isEmpty);
      expect(_fieldText(tester, 2), isEmpty);
      expect(latest?.brand, isEmpty);
      expect(latest?.unit, isEmpty);
    });

    testWidgets('use suggestion applies the suggested name', (tester) async {
      ProductPatch? latest;

      await _pumpEditor(
        tester,
        ProductEditBlock(
          suggestedName: 'Café',
          initialName: 'Outro nome',
          onChanged: (patch) {
            latest = patch;
          },
        ),
      );

      expect(_fieldText(tester, 0), 'Outro nome');

      await tester.tap(find.text(_strings.useSuggestionAction));
      await tester.pump();

      expect(_fieldText(tester, 0), 'Café');
      expect(latest?.name, 'Café');
    });

    testWidgets('updates controllers when the selected product changes', (
      tester,
    ) async {
      await _pumpEditor(
        tester,
        const ProductEditBlock(
          initialProduct: ProductView(
            id: 1,
            name: 'Antigo',
            brand: 'Marca A',
            unit: 'kg',
          ),
          onChanged: _noopChanged,
        ),
      );

      expect(_fieldText(tester, 0), 'Antigo');
      expect(_fieldText(tester, 1), 'Marca A');
      expect(_fieldText(tester, 2), 'kg');

      await _pumpEditor(
        tester,
        const ProductEditBlock(
          initialProduct: ProductView(
            id: 2,
            name: 'Novo',
            brand: 'Marca B',
            unit: 'L',
          ),
          onChanged: _noopChanged,
        ),
      );

      expect(_fieldText(tester, 0), 'Novo');
      expect(_fieldText(tester, 1), 'Marca B');
      expect(_fieldText(tester, 2), 'L');
    });

    testWidgets('hides the suggested-name row when disabled', (tester) async {
      await _pumpEditor(
        tester,
        ProductEditBlock(
          suggestedName: 'Sugestão',
          showSuggestedName: false,
          onChanged: (_) {},
        ),
      );

      expect(
        find.text('${_strings.batchAssignSuggestedName}: Sugestão'),
        findsNothing,
      );
      expect(find.text(_strings.useSuggestionAction), findsNothing);
    });

    testWidgets('renders at a large text scale without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ProductEditBlock(
                    initialProduct: const ProductView(
                      id: 1,
                      name: 'Café',
                      brand: 'Marca',
                      unit: 'kg',
                    ),
                    suggestedName: 'Sugestão',
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

void _noopChanged(ProductPatch patch) {}
