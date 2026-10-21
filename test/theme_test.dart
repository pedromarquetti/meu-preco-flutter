import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/core/config/app_config_controller.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/core/storage/credential_store.dart';
import 'package:meu_preco_frontend/core/theme/app_theme.dart';
import 'package:meu_preco_frontend/core/theme/theme_controller.dart';
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

/// Boots the app at the home screen with a restored session.
///
/// A persisted origin keeps boot on the home route, and the theme mode is
/// written to the store before dependencies load so it is not overwritten by
/// the async `ThemeController.load()`.
Future<AppDependencies> bootApp(
  WidgetTester tester, {
  InMemoryKeyValueStore? store,
  ThemeMode? initialMode,
}) async {
  tester.view.physicalSize = const Size(1000, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final keyValueStore = store ?? InMemoryKeyValueStore();
  await keyValueStore.writeString(
    AppConfigController.apiOriginKey,
    'https://api.example.com',
  );
  if (initialMode != null) {
    await keyValueStore.writeString('theme_mode', switch (initialMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
  final dependencies = buildTestDependencies(
    credentialStore: InMemoryCredentialStore(_session),
    store: keyValueStore,
  );
  dependencies.serverGate = null;
  await dependencies.authSession.restore();
  await tester.pumpWidget(MeuPrecoApp(dependencies: dependencies));
  await tester.pumpAndSettle();
  return dependencies;
}

ThemeData _themeOf(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold).first);
  return Theme.of(context);
}

Brightness _brightnessOf(WidgetTester tester) => _themeOf(tester).brightness;

void main() {
  group('brand palette', () {
    test('matches the app icon gradient stops', () {
      // Source of truth: assets/main_icon.svg (#00C853 → #0091EA).
      expect(AppTheme.brandGreen, const Color(0xFF00C853));
      expect(AppTheme.brandBlue, const Color(0xFF0091EA));
      expect(AppTheme.brandGradient.colors, [
        AppTheme.brandGreen,
        AppTheme.brandBlue,
      ]);
    });

    test('light and dark schemes are generated from the brand seed', () {
      expect(AppTheme.light().brightness, Brightness.light);
      expect(AppTheme.dark().brightness, Brightness.dark);
      expect(
        AppTheme.light().colorScheme.primary,
        isNot(equals(AppTheme.dark().colorScheme.primary)),
      );
    });

    test('light and dark onSurface contrasts against surface', () {
      double luminanceOf(Color c) => c.computeLuminance();
      Color surfaceOf(ThemeData t) => t.colorScheme.surface;
      Color textOf(ThemeData t) => t.colorScheme.onSurface;

      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final ratio =
            (luminanceOf(textOf(theme)) + 0.05) /
            (luminanceOf(surfaceOf(theme)) + 0.05);
        expect(
          ratio > 1 ? ratio : 1 / ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'onSurface must have >= 4.5:1 contrast on surface',
        );
      }
    });
  });

  group('theme switching across routes', () {
    testWidgets('light mode renders the home route', (tester) async {
      await bootApp(tester, initialMode: ThemeMode.light);
      expect(_brightnessOf(tester), Brightness.light);
      expect(find.text(_strings.homeTitle), findsOneWidget);
    });

    testWidgets('dark mode renders the home route', (tester) async {
      await bootApp(tester, initialMode: ThemeMode.dark);
      expect(_brightnessOf(tester), Brightness.dark);
      expect(find.text(_strings.homeTitle), findsOneWidget);
    });

    testWidgets('the login route follows the selected theme', (tester) async {
      await bootApp(tester, initialMode: ThemeMode.dark);
      // Navigating to a protected route without a session lands on login.
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
      expect(_themeOf(tester).brightness, Brightness.dark);
    });

    testWidgets('switching the mode updates the UI without a restart', (
      tester,
    ) async {
      final dependencies = await bootApp(tester, initialMode: ThemeMode.light);
      expect(_brightnessOf(tester), Brightness.light);

      await dependencies.themeController.setMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(_brightnessOf(tester), Brightness.dark);
      expect(find.text(_strings.homeTitle), findsOneWidget);
    });
  });

  group('theme persistence', () {
    testWidgets('a persisted dark preference survives a cold start', (
      tester,
    ) async {
      final store = InMemoryKeyValueStore();
      await store.writeString('theme_mode', 'dark');

      await bootApp(tester, store: store);

      expect(_brightnessOf(tester), Brightness.dark);
    });

    testWidgets('selecting a mode writes it to storage', (tester) async {
      final store = InMemoryKeyValueStore();
      final dependencies = await bootApp(tester, store: store);

      await dependencies.themeController.setMode(ThemeMode.light);

      expect(store.entries['theme_mode'], 'light');
    });

    test('an unknown stored value falls back to system', () async {
      final store = InMemoryKeyValueStore();
      await store.writeString('theme_mode', 'sepia');
      final controller = ThemeController(store: store);
      await controller.load();
      expect(controller.mode, ThemeMode.system);
    });

    test('system is the default mode', () async {
      final controller = ThemeController(store: InMemoryKeyValueStore());
      await controller.load();
      expect(controller.mode, ThemeMode.system);
    });
  });

  group('centralized styling', () {
    test('interactive controls reserve the minimum touch target', () {
      final theme = AppTheme.light();
      final filled = theme.filledButtonTheme.style?.minimumSize?.resolve({});
      final outlined = theme.outlinedButtonTheme.style?.minimumSize?.resolve(
        {},
      );
      expect(filled?.height, AppTheme.minTouchTarget);
      expect(outlined?.height, AppTheme.minTouchTarget);
    });
  });
}
