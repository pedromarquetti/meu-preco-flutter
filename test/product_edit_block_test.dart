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
          onSave: (_) {},
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
        ProductEditBlock(suggestedName: 'Leite', onSave: (_) {}),
      );

      expect(_fieldText(tester, 0), 'Leite');
      expect(_fieldText(tester, 1), isEmpty);
      expect(_fieldText(tester, 2), isEmpty);
    });

    testWidgets('emits one normalized patch only after explicit apply', (
      tester,
    ) async {
      ProductPatch? saved;
      var calls = 0;

      await _pumpEditor(
        tester,
        ProductEditBlock(
          suggestedName: 'Sugestão',
          onSave: (patch) {
            saved = patch;
            calls++;
          },
        ),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '  Café  ');
      await tester.enterText(fields.at(1), '   ');
      await tester.enterText(fields.at(2), ' kg ');
      await tester.pump();

      expect(calls, 0);

      await tester.tap(find.widgetWithText(FilledButton, _strings.applyAction));
      await tester.pump();

      expect(calls, 1);
      expect(saved?.name, 'Café');
      expect(saved?.brand, isNull);
      expect(saved?.unit, 'kg');
      expect(saved?.toJson(), {'name': 'Café', 'unit': 'kg'});
      expect(_fieldText(tester, 0), 'Café');
      expect(_fieldText(tester, 1), isEmpty);
      expect(_fieldText(tester, 2), 'kg');
    });

    testWidgets('rejects a whitespace-only patch without emitting', (
      tester,
    ) async {
      var calls = 0;

      await _pumpEditor(
        tester,
        ProductEditBlock(
          onSave: (_) {
            calls++;
          },
        ),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '   ');
      await tester.enterText(fields.at(1), '\t');
      await tester.enterText(fields.at(2), '  ');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, _strings.applyAction));
      await tester.pump();

      expect(calls, 0);
      expect(find.text(_strings.productPatchEmptyError), findsOneWidget);
    });

    testWidgets('use suggestion updates the name without saving', (
      tester,
    ) async {
      var calls = 0;

      await _pumpEditor(
        tester,
        ProductEditBlock(
          suggestedName: 'Café',
          initialName: 'Outro nome',
          onSave: (_) {
            calls++;
          },
        ),
      );

      expect(_fieldText(tester, 0), 'Outro nome');

      await tester.tap(find.text(_strings.useSuggestionAction));
      await tester.pump();

      expect(_fieldText(tester, 0), 'Café');
      expect(calls, 0);
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
          onSave: _noopSave,
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
          onSave: _noopSave,
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
          onSave: (_) {},
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
                    onSave: (_) {},
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

void _noopSave(ProductPatch patch) {}
