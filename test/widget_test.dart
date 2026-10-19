import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/http/server_health_service.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/core/storage/credential_store.dart';
import 'package:meu_preco_frontend/features/auth/data/auth_repository.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';

import 'fakes.dart';
import 'helpers.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

Future<void> pumpApp(
  WidgetTester tester, {
  FakeServerHealthChecker? healthChecker,
  AuthRepository? authRepository,
  CredentialStore? credentialStore,
  bool restore = false,
}) async {
  final dependencies = buildTestDependencies(
    healthChecker: healthChecker ?? FakeServerHealthChecker(),
    authRepository: authRepository,
    credentialStore: credentialStore,
  );
  if (restore) await dependencies.authSession.restore();
  await tester.pumpWidget(MeuPrecoApp(dependencies: dependencies));
  await tester.pumpAndSettle();
}

Future<void> continueFromServer(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, _strings.saveAndContinue));
  await tester.pumpAndSettle();
}

Future<void> signIn(
  WidgetTester tester, {
  String email = 'user@example.com',
  String password = 'secret123',
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.widgetWithText(FilledButton, _strings.signInAction));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on the server configuration screen', (tester) async {
    await pumpApp(tester);

    expect(find.text(_strings.serverConfigTitle), findsOneWidget);
    expect(find.text(_strings.saveAndContinue), findsOneWidget);
  });

  testWidgets('successful health check routes to login', (tester) async {
    final health = FakeServerHealthChecker();
    await pumpApp(tester, healthChecker: health);

    await continueFromServer(tester);

    expect(health.callCount, 2);
    expect(find.text(_strings.loginTitle), findsOneWidget);
    expect(find.text(_strings.serverConfigTitle), findsNothing);
  });

  testWidgets('failed health check stays on the server screen', (tester) async {
    final health = FakeServerHealthChecker(
      result: const ServerHealthResult.failed(errorCode: 'unreachable'),
    );
    await pumpApp(tester, healthChecker: health);

    await continueFromServer(tester);

    expect(find.text(_strings.serverConfigTitle), findsOneWidget);
    expect(find.text(_strings.serverConnectionFailure), findsOneWidget);
    expect(find.text(_strings.loginTitle), findsNothing);
  });

  testWidgets('invalid server address is rejected locally', (tester) async {
    final health = FakeServerHealthChecker();
    await pumpApp(tester, healthChecker: health);

    await tester.enterText(find.byType(TextFormField), 'not-a-url');
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.saveAndContinue),
    );
    await tester.pump();

    expect(find.text(_strings.invalidServerUrl), findsOneWidget);
    expect(health.callCount, 0);
    expect(find.text(_strings.loginTitle), findsNothing);
  });

  testWidgets('a restored session goes straight to home', (tester) async {
    final store = InMemoryCredentialStore(
      const StoredSession(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        user: User(id: 1, email: 'user@example.com', role: UserRole.user),
      ),
    );
    await pumpApp(tester, credentialStore: store, restore: true);

    await continueFromServer(tester);

    expect(find.text(_strings.homeTitle), findsOneWidget);
    expect(find.text(_strings.loginTitle), findsNothing);
  });

  testWidgets('login reaches the home screen', (tester) async {
    await pumpApp(tester);

    await continueFromServer(tester);
    await signIn(tester);

    expect(find.text(_strings.homeTitle), findsOneWidget);
    expect(find.text(_strings.scanReceiptAction), findsOneWidget);
    expect(find.text(_strings.searchProductAction), findsOneWidget);
  });

  testWidgets('invalid credentials keep the user on login', (tester) async {
    final repository = FakeAuthRepository()
      ..loginError = const UnauthorizedException(code: 'invalid_credentials');
    await pumpApp(tester, authRepository: repository);

    await continueFromServer(tester);
    await signIn(tester);

    expect(find.text(_strings.loginTitle), findsOneWidget);
    expect(find.text(_strings.invalidCredentialsError), findsOneWidget);
  });

  testWidgets('logout returns to login and clears the session', (tester) async {
    await pumpApp(tester);

    await continueFromServer(tester);
    await signIn(tester);
    expect(find.text(_strings.homeTitle), findsOneWidget);

    await tester.tap(find.byTooltip(_strings.settingsTitle));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(OutlinedButton, _strings.logoutAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(_strings.loginTitle), findsOneWidget);
    expect(find.text(_strings.homeTitle), findsNothing);
  });

  testWidgets('a non-admin cannot reach the admin screen', (tester) async {
    await pumpApp(tester);

    await continueFromServer(tester);
    await signIn(tester);
    await tester.tap(find.byTooltip(_strings.adminTitle));
    await tester.pumpAndSettle();

    expect(find.text(_strings.adminTitle), findsNothing);
    expect(find.text(_strings.homeTitle), findsOneWidget);
  });

  testWidgets('an admin can reach the admin screen', (tester) async {
    final repository = FakeAuthRepository(
      user: const User(id: 1, email: 'admin@example.com', role: UserRole.admin),
    );
    await pumpApp(tester, authRepository: repository);

    await continueFromServer(tester);
    await signIn(tester, email: 'admin@example.com');
    await tester.tap(find.byTooltip(_strings.adminTitle));
    await tester.pumpAndSettle();

    expect(find.text(_strings.adminTitle), findsOneWidget);
  });

  testWidgets('home routes to receipt and product screens', (tester) async {
    await pumpApp(tester);

    await continueFromServer(tester);
    await signIn(tester);

    await tester.tap(find.text(_strings.scanReceiptAction));
    await tester.pumpAndSettle();
    expect(find.text(_strings.receiptSubmissionTitle), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_strings.searchProductAction));
    await tester.pumpAndSettle();
    expect(find.text(_strings.productSearchTitle), findsOneWidget);
  });

  testWidgets('registration signs the user in', (tester) async {
    await pumpApp(tester);

    await continueFromServer(tester);
    await tester.tap(find.text(_strings.needAccountAction));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.createAccountAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(_strings.homeTitle), findsOneWidget);
  });
}
