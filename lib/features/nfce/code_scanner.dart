import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'scanner_status.dart';

/// Platform seam for reading an NFC-e QR code with a device camera.
///
/// Concrete camera implementations live behind this interface so the ingestion
/// flow can run unchanged on platforms without camera support (notably Web)
/// by falling back to pasting the QR payload or typing the access key. Camera
/// access is prepared explicitly through [prepare] so the caller can render
/// permission, hardware, and error states instead of an opaque failure.
abstract interface class CodeScanner {
  /// Whether a camera-based scanner is usable in this build/platform.
  bool get isSupported;

  /// Confirms permission and hardware before a preview is shown.
  ///
  /// Returns a ready status immediately when the permission is already granted;
  /// otherwise it triggers the OS prompt (once) and reports the resulting state.
  Future<ScannerStatus> prepare();

  /// Scans a single QR code and returns its raw payload, or `null` when the
  /// scan is cancelled or no scanner is available.
  Future<String?> scan();

  /// Live preview widget for the scanning surface.
  Widget buildPreview({required ValueChanged<String> onDetected});

  /// Opens the OS settings page for this app, used to recover from a
  /// permanently denied camera permission.
  Future<bool> openSettings();
}

/// [CodeScanner] placeholder used when no camera module is wired up.
class UnavailableCodeScanner implements CodeScanner {
  const UnavailableCodeScanner();

  @override
  bool get isSupported => false;

  @override
  Future<ScannerStatus> prepare() async =>
      const ScannerStatus(ScannerAvailability.unavailable);

  @override
  Future<String?> scan() async => null;

  @override
  Widget buildPreview({required ValueChanged<String> onDetected}) =>
      const SizedBox.shrink();

  @override
  Future<bool> openSettings() async => false;
}

/// Camera-backed scanner using `mobile_scanner` and `permission_handler`.
class CameraCodeScanner implements CodeScanner {
  CameraCodeScanner({this.permission = Permission.camera});

  /// Injected so tests can stub the permission layer.
  final Permission permission;

  @override
  bool get isSupported => true;

  @override
  Future<ScannerStatus> prepare() async {
    try {
      final status = await permission.status;
      if (_grants(status)) return const ScannerStatus.ready();
      if (status.isRestricted) {
        return const ScannerStatus(ScannerAvailability.noCamera);
      }
      if (status.isPermanentlyDenied) {
        return const ScannerStatus(ScannerAvailability.permissionDeniedForever);
      }

      final requested = await permission.request();
      if (_grants(requested)) return const ScannerStatus.ready();
      if (requested.isRestricted) {
        return const ScannerStatus(ScannerAvailability.noCamera);
      }
      if (requested.isPermanentlyDenied) {
        return const ScannerStatus(ScannerAvailability.permissionDeniedForever);
      }
      return const ScannerStatus(ScannerAvailability.permissionDenied);
    } catch (e) {
      return const ScannerStatus(ScannerAvailability.error);
    }
  }

  bool _grants(PermissionStatus status) =>
      status.isGranted || status.isLimited || status.isProvisional;

  @override
  Future<String?> scan() async => null;

  @override
  Widget buildPreview({required ValueChanged<String> onDetected}) {
    try {
      return MobileScanner(
        onDetect: (capture) {
          for (final barcode in capture.barcodes) {
            final value = barcode.rawValue;
            if (value != null && value.isNotEmpty) {
              onDetected(value);
              return;
            }
          }
        },
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  @override
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      return false;
    }
  }
}
