import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/config/app_config_controller.dart';
import 'package:meu_preco_frontend/core/http/authenticated_client.dart';
import 'package:meu_preco_frontend/core/theme/theme_controller.dart';
import 'package:meu_preco_frontend/features/auth/auth_session.dart';
import 'package:meu_preco_frontend/features/nfce/nfce_entry_mode.dart';
import 'package:meu_preco_frontend/features/nfce/receipt_submission_screen.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';
import 'helpers.dart';

AppLocalizations get _strings => lookupAppLocalizations(const Locale('pt'));

void main() {
  group('transport layer', () {
    test(
      'no Authorization header is sent once the session is logged out',
      () async {
        final credentialStore = InMemoryCredentialStore();
        final session = AuthSession(
          repository: FakeAuthRepository(),
          credentialStore: credentialStore,
        );

        final seen = <String?>[];
        final client = AuthenticatedClient(
          inner: MockClient((request) async {
            seen.add(request.headers['Authorization']);
            return http.Response('{"ok":true}', 200);
          }),
          tokens: session,
        );
        final url = Uri.parse('https://api.example.com/api/v1/products');

        await session.login(
          identifier: 'ada@example.com',
          password: 'secret123',
        );
        await client.get(url);
        expect(seen.single, 'Bearer access-1');

        await session.logout();
        await client.get(url);

        expect(seen, ['Bearer access-1', null]);
        expect(session.isAuthenticated, isFalse);
        expect(session.accessToken, isNull);
        expect(session.refreshToken, isNull);
        expect(credentialStore.clearCalls, 1);
        expect(credentialStore.session, isNull);
      },
    );

    test('a logged-out session never attempts a refresh', () async {
      final session = AuthSession(
        repository: FakeAuthRepository(),
        credentialStore: InMemoryCredentialStore(),
      );
      await session.login(identifier: 'ada@example.com', password: 'secret123');
      await session.logout();

      expect(await session.refreshAccessToken(), isFalse);
    });
  });

  group('feature repositories', () {
    test('a search after logout re-authenticates with a fresh token', () async {
      final headers = <String?>[];
      final store = InMemoryKeyValueStore();
      final configController = AppConfigController(store: store);
      await configController.load();
      final themeController = ThemeController(store: store);
      await themeController.load();
      final dependencies = AppDependencies(
        store: store,
        configController: configController,
        themeController: themeController,
        credentialStore: InMemoryCredentialStore(),
        authRepository: FakeAuthRepository(),
        httpClient: MockClient((request) async {
          headers.add(request.headers['Authorization']);
          return http.Response('{"items":[],"page":{"total":0}}', 200);
        }),
      );

      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );
      await dependencies.productsRepository.search(q: 'arroz');
      expect(headers.last, 'Bearer access-1');

      await dependencies.authSession.logout();
      await dependencies.productsRepository.search(q: 'arroz');
      expect(headers.last, isNull);

      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );
      await dependencies.productsRepository.search(q: 'arroz');
      expect(headers.last, 'Bearer access-2');
    });
  });

  group('widget flow', () {
    testWidgets('an NFC-e draft does not survive logout and re-login', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final nfceRepository = FakeNfceRepository();
      final dependencies = buildTestDependencies(
        nfceRepository: nfceRepository,
      );

      Widget app(Key key) => Provider<AppDependencies>.value(
        value: dependencies,
        child: MaterialApp(
          key: key,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ReceiptSubmissionScreen(initialMode: NfceEntryMode.key),
        ),
      );

      await tester.pumpWidget(app(const ValueKey('first')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), kSampleAccessKey);
      await tester.tap(
        find.widgetWithText(FilledButton, _strings.continueAction),
      );
      await tester.pumpAndSettle();
      expect(find.text(_strings.previewTitle), findsOneWidget);

      await dependencies.authSession.login(
        identifier: 'ada@example.com',
        password: 'secret123',
      );
      await dependencies.authSession.logout();

      await tester.pumpWidget(app(const ValueKey('second')));
      await tester.pumpAndSettle();

      expect(find.text(_strings.previewTitle), findsNothing);
      expect(find.text(_strings.continueAction), findsOneWidget);
      expect(dependencies.authSession.isAuthenticated, isFalse);
    });
  });
}
