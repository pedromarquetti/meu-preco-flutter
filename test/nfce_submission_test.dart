import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/nfce/code_scanner.dart';
import 'package:meu_preco_frontend/features/nfce/data/nfce_repository.dart';
import 'package:meu_preco_frontend/features/nfce/nfce_entry_mode.dart';
import 'package:meu_preco_frontend/features/nfce/receipt_submission_screen.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';
import 'helpers.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

CaptchaChallenge _challenge() => const CaptchaChallenge(
  message: 'solve it',
  challengeId: 'c1',
  imageUrl: '/api/v1/nfce/captcha/image/c1',
);

Future<void> pumpScreen(
  WidgetTester tester, {
  FakeNfceRepository? repository,
  FakeProductRepository? productsRepository,
  CodeScanner? scanner,
  NfceEntryMode mode = NfceEntryMode.scan,
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final dependencies = buildTestDependencies(
    nfceRepository: repository,
    productsRepository: productsRepository,
    codeScanner: scanner,
  );
  await tester.pumpWidget(
    Provider<AppDependencies>.value(
      value: dependencies,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReceiptSubmissionScreen(initialMode: mode),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapContinue(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, _strings.continueAction));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an access key drafts a receipt and reaches the preview', (
    tester,
  ) async {
    final repository = FakeNfceRepository();
    await pumpScreen(tester, repository: repository, mode: NfceEntryMode.key);

    await tester.enterText(find.byType(TextField), kSampleAccessKey);
    await tapContinue(tester);

    expect(find.text(_strings.previewTitle), findsOneWidget);
    expect(repository.draftRequests.single.accessKey, kSampleAccessKey);
    expect(find.text(_strings.submitDryRunAction), findsOneWidget);
    expect(find.text(_strings.submitConfirmAction), findsOneWidget);
  });

  testWidgets('a pasted QR payload drafts a receipt', (tester) async {
    final repository = FakeNfceRepository();
    await pumpScreen(tester, repository: repository);

    await tester.enterText(
      find.byType(TextField),
      'https://sefaz.example/qr?p=abc',
    );
    await tapContinue(tester);

    expect(find.text(_strings.previewTitle), findsOneWidget);
    expect(repository.draftRequests.single.qrPayload, isNotNull);
  });

  testWidgets('an invalid access key stays on the input with an error', (
    tester,
  ) async {
    final repository = FakeNfceRepository();
    await pumpScreen(tester, repository: repository, mode: NfceEntryMode.key);

    await tester.enterText(find.byType(TextField), '');
    await tapContinue(tester);

    expect(find.text(_strings.invalidAccessKeyError), findsOneWidget);
    expect(repository.draftCalls, 0);
  });

  testWidgets(
    'preview items show structured info without the raw API message',
    (tester) async {
      final repository = FakeNfceRepository();
      await pumpScreen(tester, repository: repository, mode: NfceEntryMode.key);

      await tester.enterText(find.byType(TextField), kSampleAccessKey);
      await tapContinue(tester);

      expect(find.text('Limao Tahiti'), findsOneWidget);
      expect(find.text('LIMAO TAHITI KG'), findsOneWidget);
      expect(find.text('24.90/KG'), findsOneWidget);
      expect(find.textContaining('matched commodity'), findsNothing);

      await tester.tap(find.byIcon(Icons.info_outline).first);
      await tester.pumpAndSettle();

      expect(find.text(_strings.itemApiMessageTitle), findsOneWidget);
      expect(
        find.textContaining("matched commodity 'Limao Tahiti'"),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, _strings.closeAction));
      await tester.pumpAndSettle();
      expect(find.textContaining('matched commodity'), findsNothing);
    },
  );

  testWidgets('a dry run reports the plan without leaving the preview', (
    tester,
  ) async {
    final repository = FakeNfceRepository()
      ..submitResult = const CommitResult(
        previewId: 42,
        confirmed: false,
        written: 3,
      );
    await pumpScreen(tester, repository: repository, mode: NfceEntryMode.key);

    await tester.enterText(find.byType(TextField), kSampleAccessKey);
    await tapContinue(tester);

    await tester.tap(
      find.widgetWithText(OutlinedButton, _strings.submitDryRunAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(_strings.previewTitle), findsOneWidget);
    expect(repository.submitRequests.single.confirm, isFalse);
  });

  testWidgets('a confirmed commit reaches the result stage', (tester) async {
    final repository = FakeNfceRepository();
    await pumpScreen(tester, repository: repository, mode: NfceEntryMode.key);

    await tester.enterText(find.byType(TextField), kSampleAccessKey);
    await tapContinue(tester);

    await tester.tap(
      find.widgetWithText(FilledButton, _strings.submitConfirmAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(_strings.commitResultTitle), findsOneWidget);
    expect(repository.submitRequests.single.confirm, isTrue);
  });

  testWidgets('a skipped uncertain line is sent as a resolution', (
    tester,
  ) async {
    final repository = FakeNfceRepository();
    await pumpScreen(tester, repository: repository, mode: NfceEntryMode.key);

    await tester.enterText(find.byType(TextField), kSampleAccessKey);
    await tapContinue(tester);

    await tester.tap(find.text(_strings.resolutionSkipAction));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.submitConfirmAction),
    );
    await tester.pumpAndSettle();

    final resolutions = repository.submitRequests.single.resolutions;
    expect(resolutions.single.action, ResolutionAction.skip);
  });

  testWidgets('a captcha challenge clears into the preview', (tester) async {
    final repository = FakeNfceRepository()
      ..draftOutcome = DraftCaptchaRequired(_challenge())
      ..solveOutcome = CaptchaSolved(samplePreview());
    await pumpScreen(tester, repository: repository, mode: NfceEntryMode.key);

    await tester.enterText(find.byType(TextField), kSampleAccessKey);
    await tapContinue(tester);
    expect(find.text(_strings.captchaTitle), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'AB12');
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.captchaSolveAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(_strings.previewTitle), findsOneWidget);
    expect(repository.solveRequests.single.solution, 'AB12');
  });

  testWidgets('a draft failure can be retried', (tester) async {
    final repository = FakeNfceRepository()
      ..draftError = const ServerException(
        message: 'boom',
        code: 'upstream_error',
        statusCode: 502,
      );
    await pumpScreen(tester, repository: repository, mode: NfceEntryMode.key);

    await tester.enterText(find.byType(TextField), kSampleAccessKey);
    await tapContinue(tester);
    expect(find.text(_strings.errorLabel), findsOneWidget);

    repository.draftError = null;
    await tester.tap(find.widgetWithText(FilledButton, _strings.retryAction));
    await tester.pumpAndSettle();

    expect(find.text(_strings.previewTitle), findsOneWidget);
  });

  testWidgets('deleting a committed receipt confirms and returns to input', (
    tester,
  ) async {
    final repository = FakeNfceRepository();
    await pumpScreen(tester, repository: repository, mode: NfceEntryMode.key);

    await tester.enterText(find.byType(TextField), kSampleAccessKey);
    await tapContinue(tester);
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.submitConfirmAction),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_strings.deleteReceiptAction));
    await tester.pumpAndSettle();
    expect(find.text(_strings.deleteReceiptConfirmTitle), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, _strings.deleteAction));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 1);
    expect(find.text(_strings.deleteReceiptSuccessMessage), findsOneWidget);
    expect(find.text(_strings.continueAction), findsOneWidget);
  });

  testWidgets('assigning a product to an uncertain line submits an assign '
      'resolution', (tester) async {
    final repository = FakeNfceRepository();
    final products = FakeProductRepository()
      ..searchResult = ProductPage(
        items: [sampleProduct(id: 42, name: 'Arroz Tipo 1 5kg')],
      );
    await pumpScreen(
      tester,
      repository: repository,
      productsRepository: products,
      mode: NfceEntryMode.key,
    );

    await tester.enterText(find.byType(TextField), kSampleAccessKey);
    await tapContinue(tester);
    expect(find.text('Item sem código'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(ChoiceChip, _strings.resolutionAssignAction),
    );
    await tester.pumpAndSettle();

    // The picker sheet has the title in its header and as the search field label.
    // Look for the header text specifically (titleMedium style in the sheet's title row).
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.data == _strings.productPickerTitle &&
            w.style?.fontSize == 16.0, // titleMedium font size
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Item sem código',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(products.searchRequests.single.q, 'Item sem código');

    await tester.tap(find.text('Arroz Tipo 1 5kg'));
    await tester.pumpAndSettle();
    expect(find.text('Arroz Tipo 1 5kg'), findsOneWidget);

    await tester.tap(find.text(_strings.submitConfirmAction));
    await tester.pumpAndSettle();

    final resolutions = repository.submitRequests.single.resolutions;
    expect(resolutions, hasLength(1));
    expect(resolutions.single.line, 2);
    expect(resolutions.single.action, ResolutionAction.assign);
    expect(resolutions.single.productId, 42);
  });
}
