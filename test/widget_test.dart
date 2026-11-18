import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app.dart';
import 'package:meu_preco_frontend/app/router.dart';
import 'package:meu_preco_frontend/core/config/app_config_controller.dart';
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
  // No origin is built in, so the field starts empty and must be filled.
  await tester.enterText(find.byType(TextFormField), 'https://api.example.com');
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

  testWidgets('a Web deep link cannot skip server selection', (tester) async {
    tester.platformDispatcher.defaultRouteNameTestValue = AppRoutes.login;
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);

    await pumpApp(tester);

    expect(find.text(_strings.serverConfigTitle), findsOneWidget);
    expect(find.text(_strings.loginTitle), findsNothing);
  });

  testWidgets('a Web deep link to login works when a server is saved', (
    tester,
  ) async {
    tester.platformDispatcher.defaultRouteNameTestValue = AppRoutes.login;
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);

    final store = InMemoryKeyValueStore();
    await store.writeString(
      AppConfigController.apiOriginKey,
      'https://saved.example.com',
    );
    final dependencies = buildTestDependencies(store: store);
    await dependencies.configController.load();

    await tester.pumpWidget(MeuPrecoApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text(_strings.loginTitle), findsOneWidget);
    expect(find.text(_strings.serverConfigTitle), findsNothing);
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

  testWidgets('a scheme-less address saves the origin the probe resolved', (
    tester,
  ) async {
    final health = FakeServerHealthChecker(
      result: ServerHealthResult.ok(
        resolvedOrigin: Uri.parse('http://localhost:8080'),
        attemptedOrigins: const [
          'https://localhost:8080',
          'http://localhost:8080',
        ],
      ),
    );
    final dependencies = buildTestDependencies(healthChecker: health);
    await tester.pumpWidget(MeuPrecoApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'localhost:8080');
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.saveAndContinue),
    );
    await tester.pumpAndSettle();

    expect(dependencies.config!.apiOrigin.toString(), 'http://localhost:8080');
    expect(find.text(_strings.loginTitle), findsOneWidget);
  });

  testWidgets('a failed scheme-less probe lists every attempted origin', (
    tester,
  ) async {
    final health = FakeServerHealthChecker(
      result: const ServerHealthResult.failed(
        errorCode: 'unreachable',
        attemptedOrigins: ['https://localhost:8080', 'http://localhost:8080'],
      ),
    );
    await pumpApp(tester, healthChecker: health);

    await tester.enterText(find.byType(TextFormField), 'localhost:8080');
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.saveAndContinue),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        _strings.serverConnectionFailureWithAttempts(
          'https://localhost:8080, http://localhost:8080',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(_strings.loginTitle), findsNothing);
  });

  testWidgets('a persisted server origin skips the server selection screen', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    await store.writeString(
      AppConfigController.apiOriginKey,
      'https://saved.example.com',
    );
    final dependencies = buildTestDependencies(store: store);
    await dependencies.configController.load();

    await tester.pumpWidget(MeuPrecoApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(
      dependencies.configController.config!.apiOrigin.toString(),
      'https://saved.example.com',
    );
    expect(find.text(_strings.serverConfigTitle), findsNothing);
    expect(find.text(_strings.loginTitle), findsOneWidget);
  });

  testWidgets(
    'a saved server that fails its health check returns to the server selection screen',
    (tester) async {
      final store = InMemoryKeyValueStore();
      await store.writeString(
        AppConfigController.apiOriginKey,
        'https://saved.example.com',
      );
      final dependencies = buildTestDependencies(store: store);
      await dependencies.configController.load();
      dependencies.serverGate = const ServerHealthResult.failed(
        errorCode: 'unreachable',
      );

      await tester.pumpWidget(MeuPrecoApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      expect(find.text(_strings.serverConfigTitle), findsOneWidget);
      expect(find.text('https://saved.example.com'), findsOneWidget);
      expect(find.text(_strings.serverConnectionFailure), findsOneWidget);
    },
  );

  testWidgets('a restored session on a reachable server boots into home', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    await store.writeString(
      AppConfigController.apiOriginKey,
      'https://saved.example.com',
    );
    final dependencies = buildTestDependencies(
      store: store,
      credentialStore: InMemoryCredentialStore(
        const StoredSession(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          user: User(
            id: 1,
            name: 'Ada',
            email: 'user@example.com',
            role: UserRole.user,
          ),
        ),
      ),
    );
    await dependencies.configController.load();
    await dependencies.authSession.restore();

    await tester.pumpWidget(MeuPrecoApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text(_strings.homeTitle), findsOneWidget);
    expect(find.text(_strings.serverConfigTitle), findsNothing);
  });

  testWidgets('invalid server address is rejected locally', (tester) async {
    final health = FakeServerHealthChecker();
    await pumpApp(tester, healthChecker: health);

    await tester.enterText(find.byType(TextFormField), 'ftp://example.com');
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.saveAndContinue),
    );
    await tester.pump();

    expect(find.text(_strings.invalidServerUrl), findsOneWidget);
    expect(health.callCount, 0);
    expect(find.text(_strings.loginTitle), findsNothing);
  });

  testWidgets('server configuration remains usable with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      () => tester.platformDispatcher.clearTextScaleFactorTestValue(),
    );

    await pumpApp(tester);
    await tester.enterText(find.byType(TextFormField), 'ftp://example.com');
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.saveAndContinue),
    );
    await tester.pump();

    expect(find.text(_strings.invalidServerUrl), findsOneWidget);
    expect(find.text(_strings.saveAndContinue), findsOneWidget);
  });

  testWidgets('a restored session goes straight to home', (tester) async {
    final store = InMemoryCredentialStore(
      const StoredSession(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        user: User(
          id: 1,
          name: 'Ada',
          email: 'user@example.com',
          role: UserRole.user,
        ),
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
    expect(find.byTooltip(_strings.scanReceiptAction), findsOneWidget);
    expect(find.text(_strings.searchProductAction), findsOneWidget);
    expect(
      find.textContaining('${_strings.homeGreeting}, Ada'),
      findsOneWidget,
    );
    expect(find.text(_strings.sessionNotPersistedWarning), findsNothing);
  });

  testWidgets('a blocked credential store still signs in and warns', (
    tester,
  ) async {
    // Plain-HTTP Web has no secure context, so the browser refuses to encrypt
    // the session; the in-memory session must remain usable.
    final store = InMemoryCredentialStore()
      ..writeError = const CredentialStorageException(
        code: 'secure_context_required',
      );
    await pumpApp(tester, credentialStore: store);

    await continueFromServer(tester);
    await signIn(tester);

    expect(find.text(_strings.homeTitle), findsOneWidget);
    expect(find.text(_strings.sessionNotPersistedWarning), findsOneWidget);
    expect(store.session, isNull);
  });

  testWidgets('login accepts a display name instead of an email', (
    tester,
  ) async {
    await pumpApp(tester);

    await continueFromServer(tester);
    await signIn(tester, email: 'Ada');

    expect(find.text(_strings.homeTitle), findsOneWidget);
  });

  testWidgets('a restored session welcomes the user by name', (tester) async {
    final store = InMemoryCredentialStore(
      const StoredSession(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        user: User(
          id: 1,
          name: 'Ada Lovelace',
          email: 'user@example.com',
          role: UserRole.user,
        ),
      ),
    );
    await pumpApp(tester, credentialStore: store, restore: true);

    await continueFromServer(tester);

    expect(find.text('${_strings.homeGreeting}, Ada Lovelace'), findsOneWidget);
  });

  testWidgets('registration requires a name', (tester) async {
    await pumpApp(tester);

    await continueFromServer(tester);
    await tester.tap(find.text(_strings.needAccountAction));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(3), 'secret123');
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.createAccountAction),
    );
    await tester.pump();

    expect(find.text(_strings.invalidNameError), findsOneWidget);
    expect(find.text(_strings.homeTitle), findsNothing);
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

  testWidgets('a non-admin does not see the admin entry', (tester) async {
    await pumpApp(tester);

    await continueFromServer(tester);
    await signIn(tester);

    expect(find.byTooltip(_strings.adminTitle), findsNothing);
    expect(find.text(_strings.homeTitle), findsOneWidget);
  });

  testWidgets('an admin can reach the admin screen', (tester) async {
    final repository = FakeAuthRepository(
      user: const User(
        id: 1,
        name: 'Admin',
        email: 'admin@example.com',
        role: UserRole.admin,
      ),
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

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text(_strings.receiptSubmissionTitle), findsOneWidget);
    expect(find.text(_strings.scanQrAction), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_strings.searchProductAction));
    await tester.pumpAndSettle();
    // The search screen's AppBar title should match; the TextField also has it as label.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is AppBar &&
            w.title is Text &&
            (w.title as Text).data == _strings.productSearchTitle,
      ),
      findsOneWidget,
    );
  });

  testWidgets('registration signs the user in', (tester) async {
    await pumpApp(tester);

    await continueFromServer(tester);
    await tester.tap(find.text(_strings.needAccountAction));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'New User');
    await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(3), 'secret123');
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.createAccountAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(_strings.homeTitle), findsOneWidget);
  });
}
