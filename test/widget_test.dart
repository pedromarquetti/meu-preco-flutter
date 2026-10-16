import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app.dart';
import 'package:meu_preco_frontend/core/http/server_health_service.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';

import 'fakes.dart';
import 'helpers.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

Future<FakeServerHealthChecker> pumpApp(
  WidgetTester tester, {
  FakeServerHealthChecker? healthChecker,
}) async {
  final health = healthChecker ?? FakeServerHealthChecker();
  final dependencies = buildTestDependencies(healthChecker: health);
  await tester.pumpWidget(MeuPrecoApp(dependencies: dependencies));
  await tester.pumpAndSettle();
  return health;
}

void main() {
  testWidgets('starts on the server configuration screen', (tester) async {
    await pumpApp(tester);

    expect(find.text(_strings.serverConfigTitle), findsOneWidget);
    expect(find.text(_strings.saveAndContinue), findsOneWidget);
    expect(find.textContaining('pushed'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('successful health check routes to login', (tester) async {
    final health = await pumpApp(tester);

    await tester.tap(
      find.widgetWithText(FilledButton, _strings.saveAndContinue),
    );
    await tester.pumpAndSettle();

    expect(health.callCount, 2);
    expect(find.text(_strings.loginTitle), findsOneWidget);
    expect(find.text(_strings.serverConfigTitle), findsNothing);
  });

  testWidgets('failed health check stays on the server screen', (tester) async {
    final health = FakeServerHealthChecker(
      result: const ServerHealthResult.failed(errorCode: 'unreachable'),
    );
    await pumpApp(tester, healthChecker: health);

    await tester.tap(
      find.widgetWithText(FilledButton, _strings.saveAndContinue),
    );
    await tester.pumpAndSettle();

    expect(find.text(_strings.serverConfigTitle), findsOneWidget);
    expect(find.text(_strings.serverConnectionFailure), findsOneWidget);
    expect(find.text(_strings.loginTitle), findsNothing);
  });

  testWidgets('invalid server address is rejected locally', (tester) async {
    final health = await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField), 'not-a-url');
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.saveAndContinue),
    );
    await tester.pump();

    expect(find.text(_strings.invalidServerUrl), findsOneWidget);
    expect(health.callCount, 0);
    expect(find.text(_strings.loginTitle), findsNothing);
  });

  testWidgets('login reaches the home screen', (tester) async {
    await pumpApp(tester);

    await tester.tap(
      find.widgetWithText(FilledButton, _strings.saveAndContinue),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, _strings.signInAction));
    await tester.pumpAndSettle();

    expect(find.text(_strings.homeTitle), findsOneWidget);
    expect(find.text(_strings.scanReceiptAction), findsOneWidget);
    expect(find.text(_strings.searchProductAction), findsOneWidget);
  });

  testWidgets('home routes to receipt and product screens', (tester) async {
    await pumpApp(tester);

    await tester.tap(
      find.widgetWithText(FilledButton, _strings.saveAndContinue),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, _strings.signInAction));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_strings.scanReceiptAction));
    await tester.pumpAndSettle();
    expect(find.text(_strings.receiptSubmissionTitle), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_strings.searchProductAction));
    await tester.pumpAndSettle();
    expect(find.text(_strings.productSearchTitle), findsOneWidget);
  });
}
