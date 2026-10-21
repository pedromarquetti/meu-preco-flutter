import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config_controller.dart';
import '../features/auth/auth_session.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_dependencies.dart';
import 'router.dart';

/// Root widget: wires dependency injection, routing, theming, and
/// localizations together.
class MeuPrecoApp extends StatefulWidget {
  const MeuPrecoApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<MeuPrecoApp> createState() => _MeuPrecoAppState();
}

class _MeuPrecoAppState extends State<MeuPrecoApp> {
  late final GoRouter _router = createRouter(
    authSession: widget.dependencies.authSession,
    initialLocation: bootLocation(
      serverConfigured: widget.dependencies.configController.isConfiguredByUser,
      serverUnreachable: widget.dependencies.serverGate != null,
      authenticated: widget.dependencies.authSession.isAuthenticated,
    ),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: widget.dependencies),
        ChangeNotifierProvider<AppConfigController>.value(
          value: widget.dependencies.configController,
        ),
        ChangeNotifierProvider<AuthSession>.value(
          value: widget.dependencies.authSession,
        ),
        ChangeNotifierProvider<ThemeController>.value(
          value: widget.dependencies.themeController,
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp.router(
            title: 'Meu Preço',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeController.mode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
