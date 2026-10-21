import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/admin/admin_users_screen.dart';
import 'package:meu_preco_frontend/features/nfce/data/nfce_repository.dart';
import 'package:meu_preco_frontend/features/nfce/nfce_entry_mode.dart';
import 'package:meu_preco_frontend/features/nfce/receipt_submission_screen.dart';
import 'package:meu_preco_frontend/features/products/product_search_screen.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';
import 'helpers.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

Future<void> pumpScreen(
  WidgetTester tester,
  Widget home, {
  FakeProductRepository? productsRepository,
  FakeNfceRepository? nfceRepository,
  AppDependencies? dependencies,
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final deps =
      dependencies ??
      buildTestDependencies(
        productsRepository: productsRepository,
        nfceRepository: nfceRepository,
      );
  await tester.pumpWidget(
    Provider<AppDependencies>.value(
      value: deps,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> searchFor(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  group('product search error recovery', () {
    final cases = <String, Object>{
      'forbidden': const ForbiddenException(message: 'sem permissao'),
      'not found': const NotFoundException(message: 'nada aqui'),
      'conflict': const ConflictException(message: 'conflito'),
      'precondition failed': const PreconditionFailedException(
        message: 'pre-condicao',
      ),
      'validation': const ValidationException(message: 'invalido'),
      'rate limited': const RateLimitedException(message: 'devagar'),
      'server error': const ServerException(
        message: 'quebrou',
        statusCode: 500,
      ),
    };

    for (final entry in cases.entries) {
      testWidgets('surfaces a ${entry.key} error and recovers on retry', (
        tester,
      ) async {
        final repository = FakeProductRepository()..searchError = entry.value;
        await pumpScreen(
          tester,
          const ProductSearchScreen(),
          productsRepository: repository,
        );

        await searchFor(tester, 'arroz');
        expect(find.text(_strings.errorLabel), findsOneWidget);

        repository
          ..searchError = null
          ..searchResult = ProductPage(
            items: [sampleProduct(name: 'Arroz Tipo 1 5kg')],
            page: const Page(total: 1, totalPages: 1),
          );
        await tester.tap(
          find.widgetWithText(FilledButton, _strings.retryAction),
        );
        await tester.pumpAndSettle();

        expect(find.text(_strings.errorLabel), findsNothing);
        expect(find.text('Arroz Tipo 1 5kg'), findsOneWidget);
      });
    }
  });

  group('NFC-e error recovery', () {
    testWidgets('an upstream failure is retryable and then previews', (
      tester,
    ) async {
      final repository = FakeNfceRepository()
        ..draftError = const ServerException(
          message: 'portal down',
          code: 'upstream_error',
        );
      await pumpScreen(
        tester,
        const ReceiptSubmissionScreen(initialMode: NfceEntryMode.key),
        nfceRepository: repository,
      );

      await tester.enterText(find.byType(TextField), kSampleAccessKey);
      await tester.tap(
        find.widgetWithText(FilledButton, _strings.continueAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(_strings.upstreamErrorMessage), findsOneWidget);

      repository.draftError = null;
      await tester.tap(find.widgetWithText(FilledButton, _strings.retryAction));
      await tester.pumpAndSettle();

      expect(find.text(_strings.previewTitle), findsOneWidget);
    });

    testWidgets('an already-committed receipt reports the typed message', (
      tester,
    ) async {
      final repository = FakeNfceRepository()
        ..draftError = const ConflictException(
          message: 'dup',
          code: 'preview_already_committed',
        );
      await pumpScreen(
        tester,
        const ReceiptSubmissionScreen(initialMode: NfceEntryMode.key),
        nfceRepository: repository,
      );

      await tester.enterText(find.byType(TextField), kSampleAccessKey);
      await tester.tap(
        find.widgetWithText(FilledButton, _strings.continueAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(_strings.alreadyCommittedError), findsOneWidget);
    });

    testWidgets('an expired preview reports the typed message', (tester) async {
      final repository = FakeNfceRepository()
        ..solveError = const ConflictException(
          message: 'expired',
          code: 'preview_expired',
        )
        ..draftOutcome = DraftCaptchaRequired(
          const CaptchaChallenge(
            message: 'solve it',
            challengeId: 'c1',
            imageUrl: '/api/v1/nfce/captcha/image/c1',
          ),
        );
      await pumpScreen(
        tester,
        const ReceiptSubmissionScreen(initialMode: NfceEntryMode.key),
        nfceRepository: repository,
      );

      await tester.enterText(find.byType(TextField), kSampleAccessKey);
      await tester.tap(
        find.widgetWithText(FilledButton, _strings.continueAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(_strings.captchaTitle), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'AB12');
      await tester.tap(
        find.widgetWithText(FilledButton, _strings.captchaSolveAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(_strings.previewExpiredError), findsOneWidget);
    });

    testWidgets('a partial commit reports the resolution totals', (
      tester,
    ) async {
      final repository = FakeNfceRepository()
        ..submitResult = const CommitResult(
          previewId: 42,
          confirmed: true,
          written: 1,
          autoSaved: 1,
          assigned: 0,
          needsReview: 1,
          skipped: 0,
          accessKey: kSampleAccessKey,
        );
      await pumpScreen(
        tester,
        const ReceiptSubmissionScreen(initialMode: NfceEntryMode.key),
        nfceRepository: repository,
      );

      await tester.enterText(find.byType(TextField), kSampleAccessKey);
      await tester.tap(
        find.widgetWithText(FilledButton, _strings.continueAction),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, _strings.submitConfirmAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(_strings.commitResultTitle), findsOneWidget);
      expect(find.text(_strings.commitNeedsReviewLabel), findsOneWidget);
    });
  });

  group('admin error recovery', () {
    testWidgets('a forbidden listing surfaces an error and retries', (
      tester,
    ) async {
      final admin = FakeAdminRepository()
        ..listUsersError = const ForbiddenException(message: 'sem permissao');
      final dependencies = buildTestDependencies(adminRepository: admin);
      await pumpScreen(
        tester,
        const AdminUsersScreen(),
        dependencies: dependencies,
      );

      expect(find.text(_strings.errorLabel), findsOneWidget);

      admin.listUsersError = null;
      await tester.tap(find.widgetWithText(FilledButton, _strings.retryAction));
      await tester.pumpAndSettle();

      expect(find.text(_strings.errorLabel), findsNothing);
      expect(admin.listUsersCalls, greaterThanOrEqualTo(2));
    });
  });
}
