import 'dart:async';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/admin/admin_review_screen.dart';
import 'package:meu_preco_frontend/features/admin/widgets/product_edit_block.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';
import 'helpers.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

ReviewItem _item(int id, String name, {String unit = 'kg'}) => ReviewItem(
  priceLogId: id,
  description: name,
  suggestedStem: name,
  unit: unit,
  storeName: 'Mercado',
  totalPrice: const Decimal('10.00'),
);

Future<({FakeAdminRepository admin, FakeProductRepository products})>
_pumpReviewScreen(
  WidgetTester tester, {
  required List<ReviewItem> items,
  Map<int, ProductView> products = const {},
  Map<int, Object> productErrors = const {},
  Completer<void>? detailGate,
  Object? mergeError,
  Object? batchAssignError,
  Object? updateProductError,
  Completer<void>? batchAssignGate,
}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final adminRepository = FakeAdminRepository()
    ..needsReviewResult = ReviewQueuePage(
      items: items,
      page: const Page(total: 2, totalPages: 1),
    )
    ..mergeError = mergeError
    ..batchAssignError = batchAssignError
    ..updateProductError = updateProductError
    ..batchAssignGate = batchAssignGate;

  final productsRepository = FakeProductRepository()
    ..detailResults.addAll(products)
    ..detailErrors.addAll(productErrors)
    ..detailGate = detailGate;

  final dependencies = buildTestDependencies(
    adminRepository: adminRepository,
    productsRepository: productsRepository,
  );
  await tester.pumpWidget(
    Provider<AppDependencies>.value(
      value: dependencies,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AdminReviewScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (admin: adminRepository, products: productsRepository);
}

Future<void> _selectAllAndOpenEditors(WidgetTester tester) async {
  final checkboxes = find.byType(CheckboxListTile);
  for (var index = 0; index < checkboxes.evaluate().length; index++) {
    await tester.tap(checkboxes.at(index));
    await tester.pump();
  }
  await tester.tap(
    find.widgetWithText(FilledButton, _strings.adminBatchAssign),
  );
  await tester.pumpAndSettle();
}

Future<void> _assignAll(WidgetTester tester) async {
  await tester.tap(
    find.widgetWithText(FilledButton, _strings.adminBatchAssign),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AdminReviewScreen', () {
    testWidgets(
      'loads details and merges same-name products deterministically',
      (tester) async {
        final repos = await _pumpReviewScreen(
          tester,
          items: [_item(10, 'Arroz'), _item(20, 'Arroz')],
          products: {
            10: const ProductView(
              id: 7,
              name: 'Arroz',
              brand: 'Marca A',
              unit: 'kg',
            ),
            20: const ProductView(
              id: 3,
              name: 'Arroz',
              brand: 'Marca B',
              unit: 'kg',
            ),
          },
        );

        await _selectAllAndOpenEditors(tester);

        expect(repos.products.detailRequests, containsAll([10, 20]));
        expect(find.byType(ProductEditBlock), findsNWidgets(2));

        await _assignAll(tester);

        // The lowest product id is retained and the other one is absorbed.
        expect(repos.admin.mergeCalls, hasLength(1));
        expect(repos.admin.mergeCalls.single.fromId, 7);
        expect(repos.admin.mergeCalls.single.toId, 3);

        // Both review rows link to the retained product.
        expect(repos.admin.batchAssignCalls, 1);
        final assignments = repos.admin.batchAssignRequests.single;
        expect(assignments, hasLength(2));
        expect(
          assignments.every(
            (assignment) =>
                assignment.action == AssignmentAction.existing &&
                assignment.productId == 3,
          ),
          isTrue,
        );
        expect(repos.admin.needsReviewCalls, 2);
      },
    );

    testWidgets('updates different-name existing products individually', (
      tester,
    ) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [_item(10, 'Arroz'), _item(20, 'Feijão')],
        products: {
          10: const ProductView(
            id: 5,
            name: 'Arroz Antigo',
            brand: 'Marca A',
            unit: 'kg',
          ),
          20: const ProductView(
            id: 6,
            name: 'Feijão Velho',
            brand: 'Marca B',
            unit: 'kg',
          ),
        },
      );

      await _selectAllAndOpenEditors(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Arroz Novo');
      await tester.enterText(fields.at(3), 'Feijão Novo');
      await tester.pump();

      await _assignAll(tester);

      expect(repos.admin.mergeCalls, isEmpty);
      expect(repos.admin.updateProductCalls, hasLength(2));
      final patches = {
        for (final call in repos.admin.updateProductCalls) call.id: call.patch,
      };
      expect(patches[5]?.name, 'Arroz Novo');
      expect(patches[6]?.name, 'Feijão Novo');
      expect(
        repos.admin.batchAssignRequests.single.every(
          (assignment) => assignment.action == AssignmentAction.existing,
        ),
        isTrue,
      );
    });

    testWidgets('falls back to batch creation when no product exists', (
      tester,
    ) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [_item(10, 'Produto Novo', unit: 'un')],
        productErrors: {10: const NotFoundException()},
      );

      await _selectAllAndOpenEditors(tester);
      await _assignAll(tester);

      expect(repos.admin.mergeCalls, isEmpty);
      expect(repos.admin.updateProductCalls, isEmpty);
      final assignment = repos.admin.batchAssignRequests.single.single;
      expect(assignment.action, AssignmentAction.create);
      expect(assignment.productId, isNull);
      expect(assignment.name, 'Produto Novo');
      expect(assignment.unit, 'un');
    });

    testWidgets('reports partial failure and keeps the queue unrefreshed', (
      tester,
    ) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [_item(10, 'Arroz'), _item(20, 'Arroz')],
        products: {
          10: const ProductView(id: 7, name: 'Arroz', unit: 'kg'),
          20: const ProductView(id: 3, name: 'Arroz', unit: 'kg'),
        },
        mergeError: const NetworkException(),
      );

      await _selectAllAndOpenEditors(tester);
      await _assignAll(tester);

      expect(repos.admin.mergeCalls, hasLength(1));
      expect(repos.admin.batchAssignCalls, 1);
      expect(repos.admin.needsReviewCalls, 1);
      expect(
        find.textContaining(_strings.adminReviewPartialFailure),
        findsOneWidget,
      );
      expect(find.byType(ProductEditBlock), findsWidgets);
    });

    testWidgets('moves between selection and edit steps', (tester) async {
      await _pumpReviewScreen(
        tester,
        items: [_item(10, 'Arroz')],
        products: {10: const ProductView(id: 5, name: 'Arroz', unit: 'kg')},
      );

      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.byType(ProductEditBlock), findsNothing);

      await _selectAllAndOpenEditors(tester);

      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byType(ProductEditBlock), findsOneWidget);
      expect(find.text(_strings.goBack), findsOneWidget);

      await tester.tap(find.text(_strings.goBack));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.byType(ProductEditBlock), findsNothing);
    });

    testWidgets('shows a loading state while product details are fetched', (
      tester,
    ) async {
      final gate = Completer<void>();
      await _pumpReviewScreen(
        tester,
        items: [_item(10, 'Arroz')],
        products: {
          10: const ProductView(id: 5, name: 'Arroz Carregado', unit: 'kg'),
        },
        detailGate: gate,
      );

      final checkboxes = find.byType(CheckboxListTile);
      await tester.tap(checkboxes.first);
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, _strings.adminBatchAssign),
      );
      await tester.pump();

      expect(find.text(_strings.adminReviewLoadingDetails), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(ProductEditBlock), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(ProductEditBlock), findsOneWidget);
      expect(find.text(_strings.adminReviewLoadingDetails), findsNothing);
      expect(_fieldText(tester, 0), 'Arroz Carregado');
    });

    testWidgets('retries a failed product-detail load', (tester) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [_item(10, 'Arroz')],
        productErrors: {10: const NetworkException()},
      );

      await _selectAllAndOpenEditors(tester);

      expect(find.text(_strings.adminReviewDetailsError), findsOneWidget);
      expect(find.byType(ProductEditBlock), findsNothing);

      repos.products
        ..detailErrors.clear()
        ..detailResults[10] = const ProductView(
          id: 5,
          name: 'Arroz Recuperado',
          unit: 'kg',
        );

      await tester.tap(find.text(_strings.retryAction));
      await tester.pumpAndSettle();

      expect(find.text(_strings.adminReviewDetailsError), findsNothing);
      expect(find.byType(ProductEditBlock), findsOneWidget);
      expect(_fieldText(tester, 0), 'Arroz Recuperado');
    });

    testWidgets('validates required name and unit before submitting', (
      tester,
    ) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [_item(10, 'Produto Novo', unit: 'un')],
        productErrors: {10: const NotFoundException()},
      );

      await _selectAllAndOpenEditors(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '   ');
      await tester.enterText(fields.at(2), '   ');
      await tester.pump();

      await _assignAll(tester);

      expect(find.text(_strings.adminReviewNameRequired), findsOneWidget);
      expect(repos.admin.batchAssignCalls, 0);
      expect(repos.admin.mergeCalls, isEmpty);
      expect(repos.admin.updateProductCalls, isEmpty);

      // Let the first snackbar dismiss so the next one can be shown.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.enterText(fields.at(0), 'Produto Válido');
      await tester.pump();
      await _assignAll(tester);

      expect(find.text(_strings.adminReviewUnitRequired), findsOneWidget);
      expect(repos.admin.batchAssignCalls, 0);
      expect(repos.admin.mergeCalls, isEmpty);
      expect(repos.admin.updateProductCalls, isEmpty);
    });

    testWidgets('trims created product values before batch assignment', (
      tester,
    ) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [_item(10, 'Produto Novo', unit: 'un')],
        productErrors: {10: const NotFoundException()},
      );

      await _selectAllAndOpenEditors(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '  Produto Novo  ');
      await tester.enterText(fields.at(1), '  Marca X  ');
      await tester.enterText(fields.at(2), '  un  ');
      await tester.pump();

      await _assignAll(tester);

      final assignment = repos.admin.batchAssignRequests.single.single;
      expect(assignment.action, AssignmentAction.create);
      expect(assignment.name, 'Produto Novo');
      expect(assignment.brand, 'Marca X');
      expect(assignment.unit, 'un');
    });

    testWidgets('trims existing-product updates before patching', (
      tester,
    ) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [_item(10, 'Arroz')],
        products: {
          10: const ProductView(
            id: 5,
            name: 'Arroz Antigo',
            brand: 'Marca A',
            unit: 'kg',
          ),
        },
      );

      await _selectAllAndOpenEditors(tester);

      await tester.enterText(find.byType(TextField).at(0), '  Arroz Novo  ');
      await tester.pump();
      await _assignAll(tester);

      final patch = repos.admin.updateProductCalls.single.patch;
      expect(repos.admin.updateProductCalls.single.id, 5);
      expect(patch.name, 'Arroz Novo');
    });
  });
}

String _fieldText(WidgetTester tester, int index) {
  final field = tester.widget<TextField>(find.byType(TextField).at(index));
  return field.controller?.text ?? '';
}
