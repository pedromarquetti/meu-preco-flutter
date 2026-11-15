import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/features/nfce/code_scanner.dart';
import 'package:meu_preco_frontend/features/nfce/scanner_status.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group('scannerStatusForError', () {
    test('maps a denied permission to the retryable permission state', () {
      final status = scannerStatusForError(
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );

      expect(status.availability, ScannerAvailability.permissionDenied);
      expect(status.canRetryPermission, isTrue);
      expect(status.requiresSettings, isFalse);
    });

    test('maps a missing or unsupported camera to noCamera', () {
      final status = scannerStatusForError(
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.unsupported,
          errorDetails: MobileScannerErrorDetails(
            message: 'NotFoundError: Requested device not found',
          ),
        ),
      );

      expect(status.availability, ScannerAvailability.noCamera);
      expect(status.message, contains('NotFoundError'));
    });

    test('keeps a NotReadableError detail on the generic error state', () {
      final status = scannerStatusForError(
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
          errorDetails: MobileScannerErrorDetails(
            message: 'NotReadableError: Starting video input failed',
          ),
        ),
      );

      expect(status.availability, ScannerAvailability.error);
      expect(status.message, contains('NotReadableError'));
    });

    test('falls back to the generic error state without details', () {
      final status = scannerStatusForError(
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.controllerDisposed,
        ),
      );

      expect(status.availability, ScannerAvailability.error);
      expect(status.message, isNull);
    });
  });
}
