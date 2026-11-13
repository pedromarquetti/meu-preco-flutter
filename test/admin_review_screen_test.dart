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

ReviewItem _item(
  int id,
  String name, {
  String unit = 'kg',
  ReviewProductView? proposedProduct,
  int? resolvedBy,
  ProposalStatus proposalStatus = ProposalStatus.pending,
  ReviewAction? lastReviewAction,
}) => ReviewItem(
  priceLogId: id,
  description: name,
  suggestedStem: name,
  unit: unit,
  storeName: 'Mercado',
  totalPrice: const Decimal('10.00'),
  proposedProduct: proposedProduct,
  resolvedBy: resolvedBy,
  proposalStatus: proposalStatus,
  lastReviewAction: lastReviewAction,
);

Future<({FakeAdminRepository admin, FakeProductRepository products})>
_pumpReviewScreen(
  WidgetTester tester, {
  required List<ReviewItem> items,
  Map<int, UserView> users = const {},
  Object? findUserError,
  Completer<void>? findUserGate,
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
    ..batchAssignGate = batchAssignGate
    ..findUserError = findUserError
    ..findUserGate = findUserGate
    ..usersById.addAll(users);

  final productsRepository = FakeProductRepository();

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
  final checkboxes = find.byType(Checkbox);
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
      'merges same-name proposals deterministically without public lookups',
      (tester) async {
        final repos = await _pumpReviewScreen(
          tester,
          items: [
            _item(
              10,
              'Arroz',
              proposedProduct: const ReviewProductView(
                id: 7,
                name: 'Arroz',
                brand: 'Marca A',
                unit: 'kg',
              ),
            ),
            _item(
              20,
              'Arroz',
              proposedProduct: const ReviewProductView(
                id: 3,
                name: 'Arroz',
                brand: 'Marca B',
                unit: 'kg',
              ),
            ),
          ],
        );

        await _selectAllAndOpenEditors(tester);

        expect(repos.products.detailRequests, isEmpty);
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

    testWidgets(
      'tapping a proposed product selects it and prefills the editor',
      (tester) async {
        final repos = await _pumpReviewScreen(
          tester,
          items: [
            _item(
              10,
              'Arroz recebido',
              proposedProduct: const ReviewProductView(
                id: 7,
                name: 'Arroz 5kg',
                brand: 'Marca Boa',
                unit: 'kg',
              ),
            ),
          ],
        );

        expect(find.textContaining('Arroz 5kg'), findsOneWidget);
        expect(find.text('Marca Boa'), findsOneWidget);
        expect(find.byType(ProductEditBlock), findsNothing);

        await tester.tap(find.textContaining('Arroz 5kg'));
        await tester.pump();

        // Selection alone stays on the queue; it does not open the editor.
        expect(find.byType(ProductEditBlock), findsNothing);

        await tester.tap(
          find.widgetWithText(FilledButton, _strings.adminBatchAssign),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProductEditBlock), findsOneWidget);
        expect(_fieldText(tester, 0), 'Arroz 5kg');
        expect(_fieldText(tester, 1), 'Marca Boa');
        expect(_fieldText(tester, 2), 'kg');
        expect(repos.products.detailRequests, isEmpty);

        await _assignAll(tester);

        final assignment = repos.admin.batchAssignRequests.single.single;
        expect(assignment.action, AssignmentAction.existing);
        expect(assignment.productId, 7);
      },
    );

    testWidgets('approves a proposal without loading the public product', (
      tester,
    ) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [
          _item(
            10,
            'Arroz recebido',
            proposedProduct: const ReviewProductView(
              id: 7,
              name: 'Arroz 5kg',
              unit: 'kg',
              gtin: '7890000000000',
            ),
          ),
        ],
      );

      expect(find.text(_strings.adminProposalPending), findsOneWidget);
      expect(find.text(_strings.adminApproveAction), findsOneWidget);
      expect(repos.products.detailRequests, isEmpty);

      await tester.tap(find.text(_strings.adminApproveAction));
      await tester.pumpAndSettle();

      expect(repos.admin.reviewPriceLogRequests.single.priceLogId, 10);
      expect(
        repos.admin.reviewPriceLogRequests.single.action,
        PriceLogReviewAction.approve,
      );
      expect(repos.admin.needsReviewCalls, 2);
    });

    testWidgets('rejects a pending proposal', (tester) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [
          _item(
            11,
            'Feijão recebido',
            proposedProduct: const ReviewProductView(
              id: 8,
              name: 'Feijão',
              unit: 'kg',
            ),
          ),
        ],
      );

      await tester.tap(find.text(_strings.adminRejectAction));
      await tester.pumpAndSettle();

      expect(repos.admin.reviewPriceLogRequests.single.priceLogId, 11);
      expect(
        repos.admin.reviewPriceLogRequests.single.action,
        PriceLogReviewAction.reject,
      );
    });

    testWidgets('disables Reject but keeps Approve for a rejected proposal', (
      tester,
    ) async {
      await _pumpReviewScreen(
        tester,
        items: [
          _item(
            12,
            'Arroz recebido',
            proposedProduct: const ReviewProductView(
              id: 7,
              name: 'Arroz',
              unit: 'kg',
            ),
            proposalStatus: ProposalStatus.rejected,
            lastReviewAction: ReviewAction.reject,
          ),
        ],
      );

      final reject = tester.widget<TextButton>(
        find.widgetWithText(TextButton, _strings.adminRejectAction),
      );
      final approve = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, _strings.adminApproveAction),
      );

      expect(reject.onPressed, isNull);
      expect(approve.onPressed, isNotNull);
      expect(find.text(_strings.adminProposalRejected), findsOneWidget);
    });

    testWidgets('keeps Reject enabled for a pending proposal', (tester) async {
      await _pumpReviewScreen(
        tester,
        items: [
          _item(
            13,
            'Arroz recebido',
            proposedProduct: const ReviewProductView(
              id: 7,
              name: 'Arroz',
              unit: 'kg',
            ),
          ),
        ],
      );

      final reject = tester.widget<TextButton>(
        find.widgetWithText(TextButton, _strings.adminRejectAction),
      );
      expect(reject.onPressed, isNotNull);
    });

    testWidgets('hides review actions for unresolved rows', (tester) async {
      await _pumpReviewScreen(tester, items: [_item(14, 'Produto novo')]);

      expect(find.text(_strings.adminApproveAction), findsNothing);
      expect(find.text(_strings.adminRejectAction), findsNothing);
      expect(find.textContaining('Proposto por'), findsNothing);
    });

    testWidgets('shows the resolved proposer name', (tester) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [
          _item(
            15,
            'Arroz recebido',
            proposedProduct: const ReviewProductView(
              id: 7,
              name: 'Arroz',
              unit: 'kg',
            ),
            resolvedBy: 2,
          ),
        ],
        users: {
          2: const UserView(
            id: 2,
            name: 'Ada',
            email: 'ada@example.com',
            role: UserRole.user,
          ),
        },
      );

      await tester.pumpAndSettle();

      expect(find.text(_strings.adminProposalBy('Ada')), findsOneWidget);
      expect(repos.admin.findUserCalls, 1);
    });

    testWidgets('falls back to the user id while the lookup is pending', (
      tester,
    ) async {
      final gate = Completer<void>();
      await _pumpReviewScreen(
        tester,
        items: [
          _item(
            16,
            'Arroz recebido',
            proposedProduct: const ReviewProductView(
              id: 7,
              name: 'Arroz',
              unit: 'kg',
            ),
            resolvedBy: 2,
          ),
        ],
        users: {
          2: const UserView(
            id: 2,
            name: 'Ada',
            email: 'ada@example.com',
            role: UserRole.user,
          ),
        },
        findUserGate: gate,
      );

      expect(find.text(_strings.adminProposalByFallback(2)), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text(_strings.adminProposalBy('Ada')), findsOneWidget);
    });

    testWidgets('falls back to the user id when the lookup fails', (
      tester,
    ) async {
      await _pumpReviewScreen(
        tester,
        items: [
          _item(
            17,
            'Arroz recebido',
            proposedProduct: const ReviewProductView(
              id: 7,
              name: 'Arroz',
              unit: 'kg',
            ),
            resolvedBy: 3,
          ),
        ],
        findUserError: const NetworkException(),
      );

      await tester.pumpAndSettle();

      expect(find.text(_strings.adminProposalByFallback(3)), findsOneWidget);
    });

    testWidgets(
      'select-all includes proposals and allows individual deselect',
      (tester) async {
        await _pumpReviewScreen(
          tester,
          items: [
            _item(
              18,
              'Arroz recebido',
              proposedProduct: const ReviewProductView(
                id: 7,
                name: 'Arroz',
                unit: 'kg',
              ),
            ),
            _item(19, 'Produto novo'),
          ],
        );

        await tester.tap(find.text(_strings.adminSelectAll));
        await tester.pump();

        var checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
        expect(checkboxes.every((checkbox) => checkbox.value == true), isTrue);
        expect(find.text(_strings.adminClearSelection), findsOneWidget);

        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();

        checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
        expect(checkboxes.first.value, isFalse);
        expect(checkboxes.last.value, isTrue);
        expect(find.text(_strings.adminSelectAll), findsOneWidget);
      },
    );

    testWidgets('reloads the queue when another admin already processed it', (
      tester,
    ) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [
          _item(
            20,
            'Arroz recebido',
            proposedProduct: const ReviewProductView(
              id: 7,
              name: 'Arroz',
              unit: 'kg',
            ),
          ),
        ],
      );

      repos.admin.reviewPriceLogError = const ConflictException(
        code: 'already_processed',
      );

      await tester.tap(find.text(_strings.adminApproveAction));
      await tester.pumpAndSettle();

      expect(find.text(_strings.adminReviewAlreadyProcessed), findsOneWidget);
      expect(repos.admin.needsReviewCalls, 2);
    });

    testWidgets('updates different-name existing products individually', (
      tester,
    ) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [
          _item(
            10,
            'Arroz',
            proposedProduct: const ReviewProductView(
              id: 5,
              name: 'Arroz Antigo',
              brand: 'Marca A',
              unit: 'kg',
            ),
          ),
          _item(
            20,
            'Feijão',
            proposedProduct: const ReviewProductView(
              id: 6,
              name: 'Feijão Velho',
              brand: 'Marca B',
              unit: 'kg',
            ),
          ),
        ],
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

    testWidgets(
      'rejected proposal defaults to creating a product from the suggestion',
      (tester) async {
        final repos = await _pumpReviewScreen(
          tester,
          items: [
            _item(
              10,
              'APRESUNTADO SOFT PIG KG',
              unit: 'kg',
              proposedProduct: const ReviewProductView(
                id: 8,
                name: 'tijolo',
                brand: 'de barro',
                unit: 'un',
              ),
              proposalStatus: ProposalStatus.rejected,
              lastReviewAction: ReviewAction.reject,
            ),
          ],
        );

        await _selectAllAndOpenEditors(tester);

        expect(find.byType(ProductEditBlock), findsOneWidget);
        expect(_fieldText(tester, 0), 'APRESUNTADO SOFT PIG KG');
        expect(_fieldText(tester, 1), isEmpty);
        expect(_fieldText(tester, 2), 'kg');
        expect(find.textContaining('tijolo'), findsNothing);

        await _assignAll(tester);

        expect(repos.admin.updateProductCalls, isEmpty);
        expect(repos.admin.mergeCalls, isEmpty);
        final assignment = repos.admin.batchAssignRequests.single.single;
        expect(assignment.action, AssignmentAction.create);
        expect(assignment.productId, isNull);
        expect(assignment.name, 'APRESUNTADO SOFT PIG KG');
        expect(assignment.brand, isNull);
        expect(assignment.unit, 'kg');
        expect(repos.admin.needsReviewCalls, 2);
      },
    );

    testWidgets('reports partial failure and keeps the queue unrefreshed', (
      tester,
    ) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [
          _item(
            10,
            'Arroz',
            proposedProduct: const ReviewProductView(
              id: 7,
              name: 'Arroz',
              unit: 'kg',
            ),
          ),
          _item(
            20,
            'Arroz',
            proposedProduct: const ReviewProductView(
              id: 3,
              name: 'Arroz',
              unit: 'kg',
            ),
          ),
        ],
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
        items: [
          _item(
            10,
            'Arroz',
            proposedProduct: const ReviewProductView(
              id: 5,
              name: 'Arroz',
              unit: 'kg',
            ),
          ),
        ],
      );

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.byType(ProductEditBlock), findsNothing);

      await _selectAllAndOpenEditors(tester);

      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(ProductEditBlock), findsOneWidget);
      expect(find.text(_strings.goBack), findsOneWidget);

      await tester.tap(find.text(_strings.goBack));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.byType(ProductEditBlock), findsNothing);
    });

    testWidgets('validates required name and unit before submitting', (
      tester,
    ) async {
      final repos = await _pumpReviewScreen(
        tester,
        items: [_item(10, 'Produto Novo', unit: 'un')],
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
        items: [
          _item(
            10,
            'Arroz',
            proposedProduct: const ReviewProductView(
              id: 5,
              name: 'Arroz Antigo',
              brand: 'Marca A',
              unit: 'kg',
            ),
          ),
        ],
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
