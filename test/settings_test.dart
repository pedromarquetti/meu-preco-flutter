import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/config/app_config.dart';
import 'package:meu_preco_frontend/core/config/app_config_controller.dart';
import 'package:meu_preco_frontend/core/http/server_health_service.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/core/storage/credential_store.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';

import 'fakes.dart';
import 'helpers.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

const _session = StoredSession(
  accessToken: 'access-1',
  refreshToken: 'refresh-1',
  user: User(
    id: 1,
    name: 'Ada',
    email: 'user@example.com',
    role: UserRole.user,
  ),
);

/// Boots the app with a restored session and opens Settings from the home
/// screen, returning the dependencies so tests can inspect storage/config.
Future<AppDependencies> openSettings(
  WidgetTester tester, {
  FakeServerHealthChecker? healthChecker,
  InMemoryKeyValueStore? store,
}) async {
  // A tall viewport keeps the whole settings list mounted so finders can reach
  // the controls below the fold without scrolling.
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final dependencies = buildTestDependencies(
    healthChecker: healthChecker ?? FakeServerHealthChecker(),
    credentialStore: InMemoryCredentialStore(_session),
    store: store,
  );
  await dependencies.authSession.restore();
  await tester.pumpWidget(MeuPrecoApp(dependencies: dependencies));
  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(FilledButton, _strings.saveAndContinue));
  await tester.pumpAndSettle();

  await tester.tap(find.byTooltip(_strings.settingsTitle));
  await tester.pumpAndSettle();
  return dependencies;
}

void main() {
  testWidgets('shows the signed-in account and current host', (tester) async {
    await openSettings(tester);

    expect(find.text('${_strings.currentUserLabel}: Ada'), findsOneWidget);
    expect(
      find.text('${_strings.emailLabel}: user@example.com'),
      findsOneWidget,
    );
    expect(
      find.text('${_strings.roleLabel}: ${_strings.userRoleLabel}'),
      findsOneWidget,
    );
    expect(
      find.textContaining(AppConfig.defaults().apiOrigin.toString()),
      findsWidgets,
    );
  });

  testWidgets('changing the host applies and persists it', (tester) async {
    final store = InMemoryKeyValueStore();
    final dependencies = await openSettings(tester, store: store);

    await tester.enterText(
      find.byType(TextFormField),
      'https://api.example.com',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.testConnection),
    );
    await tester.pumpAndSettle();

    expect(dependencies.config.apiOrigin.toString(), 'https://api.example.com');
    expect(
      store.entries[AppConfigController.apiOriginKey],
      'https://api.example.com',
    );
  });

  testWidgets('an invalid host is rejected without saving', (tester) async {
    final store = InMemoryKeyValueStore();
    final dependencies = await openSettings(tester, store: store);
    final before = dependencies.config.apiOrigin.toString();

    await tester.enterText(find.byType(TextFormField), 'not-a-url');
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.testConnection),
    );
    await tester.pump();

    expect(find.text(_strings.invalidServerUrl), findsOneWidget);
    expect(dependencies.config.apiOrigin.toString(), before);
  });

  testWidgets('a host failing the health gate is not saved', (tester) async {
    // The checker must be healthy to boot past the server screen; it then
    // starts failing for the settings save attempt.
    final health = FakeServerHealthChecker();
    final dependencies = await openSettings(tester, healthChecker: health);
    final before = dependencies.config.apiOrigin.toString();
    health.result = const ServerHealthResult.failed(errorCode: 'unreachable');

    await tester.enterText(
      find.byType(TextFormField),
      'https://unreachable.example.com',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, _strings.testConnection),
    );
    await tester.pumpAndSettle();

    expect(find.text(_strings.serverConnectionFailure), findsOneWidget);
    expect(dependencies.config.apiOrigin.toString(), before);
  });

  testWidgets('reset restores the default and clears the override', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    final dependencies = await openSettings(tester, store: store);
    await dependencies.configController.saveOrigin('https://api.example.com');

    await tester.tap(
      find.widgetWithText(OutlinedButton, _strings.settingsResetToDefault),
    );
    await tester.pumpAndSettle();

    expect(
      dependencies.config.apiOrigin.toString(),
      AppConfig.defaults().apiOrigin.toString(),
    );
    expect(store.entries, isEmpty);
  });

  testWidgets('connectivity check reports health and readiness', (
    tester,
  ) async {
    await openSettings(tester);

    await tester.tap(
      find.widgetWithText(OutlinedButton, _strings.checkConnectivityAction),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        '${_strings.healthStatusLabel}: ${_strings.serverConnectionSuccess}',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '${_strings.readinessStatusLabel}: ${_strings.readinessHealthyLabel}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('connectivity check surfaces an unavailable server', (
    tester,
  ) async {
    final health = FakeServerHealthChecker(
      readiness: const ServerHealthResult.failed(errorCode: 'not_ready'),
    );
    await openSettings(tester, healthChecker: health);

    await tester.tap(
      find.widgetWithText(OutlinedButton, _strings.checkConnectivityAction),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining(_strings.readinessUnavailableLabel),
      findsOneWidget,
    );
  });
}
