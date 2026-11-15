import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/app/app_dependencies.dart';
import 'package:meu_preco_frontend/features/nfce/receipt_scanner_screen.dart';
import 'package:meu_preco_frontend/features/nfce/scanner_status.dart';
import 'package:meu_preco_frontend/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';
import 'helpers.dart';

Future<void> pumpScanner(
  WidgetTester tester, {
  required FakeCodeScanner scanner,
}) async {
  final dependencies = buildTestDependencies(codeScanner: scanner);
  await tester.pumpWidget(
    Provider<AppDependencies>.value(
      value: dependencies,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ReceiptScannerScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('replaces the preview when the camera cannot start', (
    tester,
  ) async {
    final scanner = FakeCodeScanner(isAvailable: true)
      ..previewError = const ScannerStatus(ScannerAvailability.error);

    await pumpScanner(tester, scanner: scanner);

    expect(
      find.text('Não foi possível abrir a câmera. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(scanner.previewBuilds, 1);
  });

  testWidgets('offers the permission recovery path for a denied camera', (
    tester,
  ) async {
    final scanner = FakeCodeScanner(
      isAvailable: true,
    )..previewError = const ScannerStatus(ScannerAvailability.permissionDenied);

    await pumpScanner(tester, scanner: scanner);

    expect(find.text('Permissão da câmera'), findsOneWidget);
    expect(find.text('Solicitar permissão'), findsOneWidget);
  });

  testWidgets('retries the preview after a start failure', (tester) async {
    final scanner = FakeCodeScanner(isAvailable: true)
      ..previewError = const ScannerStatus(ScannerAvailability.error);

    await pumpScanner(tester, scanner: scanner);
    expect(find.text('Tentar novamente'), findsOneWidget);

    scanner.previewError = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível abrir a câmera. Tente novamente.'),
      findsNothing,
    );
    expect(scanner.prepareCalls, 2);
    expect(scanner.previewBuilds, 2);
  });
}
